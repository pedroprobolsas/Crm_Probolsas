-- Script para solucionar el problema del webhook de IA
-- Este script debe ejecutarse manualmente en la consola SQL de Supabase

-- 1. Añadir la columna ia_webhook_sent a la tabla messages si no existe
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM information_schema.columns
    WHERE table_name = 'messages' AND column_name = 'ia_webhook_sent'
  ) THEN
    ALTER TABLE messages ADD COLUMN ia_webhook_sent BOOLEAN DEFAULT FALSE;
    RAISE NOTICE 'Columna ia_webhook_sent añadida a la tabla messages';
  ELSE
    RAISE NOTICE 'La columna ia_webhook_sent ya existe en la tabla messages';
  END IF;
END;
$$;

-- 2. Crear o reemplazar la función para notificar al webhook
CREATE OR REPLACE FUNCTION notify_message_webhook()
RETURNS TRIGGER AS $$
DECLARE
  webhook_url TEXT;
  client_record RECORD;
  payload JSONB;
  response JSONB;
BEGIN
  -- Verificar si el mensaje ya ha sido enviado al webhook
  IF NEW.ia_webhook_sent = TRUE THEN
    RAISE NOTICE 'Mensaje % ya enviado al webhook, omitiendo', NEW.id;
    RETURN NEW;
  END IF;
  
  -- Verificar si el asistente de IA está activado
  IF NEW.asistente_ia_activado IS NOT TRUE THEN
    RAISE NOTICE 'Mensaje % no tiene asistente_ia_activado=true, omitiendo', NEW.id;
    RETURN NEW;
  END IF;
  
  -- Verificar si el mensaje es de un cliente
  IF NEW.sender != 'client' THEN
    RAISE NOTICE 'Mensaje % no es de un cliente (sender=%)', NEW.id, NEW.sender;
    RETURN NEW;
  END IF;
  
  -- Verificar si el mensaje está en estado enviado
  IF NEW.status != 'sent' THEN
    RAISE NOTICE 'Mensaje % no está en estado enviado (status=%)', NEW.id, NEW.status;
    RETURN NEW;
  END IF;
  
  -- Verificar si el mensaje es una respuesta de la IA
  IF NEW.content LIKE '[IA]%' THEN
    RAISE NOTICE 'Mensaje % es una respuesta de la IA, omitiendo', NEW.id;
    RETURN NEW;
  END IF;
  
  -- Obtener la URL del webhook desde la configuración
  SELECT value INTO webhook_url
  FROM app_settings
  WHERE key = 'webhook_url_ia_production';
  
  IF webhook_url IS NULL OR webhook_url = '' THEN
    RAISE WARNING 'No se encontró la URL del webhook de IA en app_settings';
    RETURN NEW;
  END IF;
  
  -- Obtener información del cliente
  SELECT * INTO client_record
  FROM clients
  WHERE id = NEW.sender_id;
  
  IF client_record.id IS NULL THEN
    RAISE WARNING 'No se encontró el cliente con ID %', NEW.sender_id;
    RETURN NEW;
  END IF;
  
  -- Construir el payload para el webhook
  payload = jsonb_build_object(
    'id', NEW.id,
    'conversation_id', NEW.conversation_id,
    'content', NEW.content,
    'sender', NEW.sender,
    'sender_id', NEW.sender_id,
    'type', NEW.type,
    'status', NEW.status,
    'created_at', NEW.created_at,
    'asistente_ia_activado', NEW.asistente_ia_activado,
    'phone', client_record.phone,
    'client', jsonb_build_object(
      'id', client_record.id,
      'name', client_record.name,
      'email', client_record.email,
      'phone', client_record.phone,
      'company', client_record.company
    ),
    'source', 'database_trigger'
  );
  
  -- Enviar al webhook usando la extensión http
  SELECT content::jsonb INTO response
  FROM http((
    'POST',
    webhook_url,
    ARRAY[http_header('Content-Type', 'application/json')],
    'application/json',
    payload::text
  )::http_request);
  
  -- Marcar el mensaje como enviado al webhook
  UPDATE messages
  SET ia_webhook_sent = TRUE
  WHERE id = NEW.id;
  
  RAISE NOTICE 'Mensaje % enviado al webhook de IA', NEW.id;
  RETURN NEW;
EXCEPTION
  WHEN OTHERS THEN
    RAISE WARNING 'Error al enviar mensaje % al webhook: %', NEW.id, SQLERRM;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 3. Crear o reemplazar el trigger para INSERT y UPDATE
DROP TRIGGER IF EXISTS message_webhook_trigger ON messages;

CREATE TRIGGER message_webhook_trigger
AFTER INSERT OR UPDATE OF asistente_ia_activado ON messages
FOR EACH ROW
EXECUTE FUNCTION notify_message_webhook();

-- 4. Crear o reemplazar la función para procesar mensajes pendientes
CREATE OR REPLACE FUNCTION process_pending_ia_messages()
RETURNS INTEGER AS $$
DECLARE
  processed_count INTEGER := 0;
  message_record RECORD;
BEGIN
  -- Buscar mensajes de los últimos 7 días que deberían haber sido enviados al webhook
  FOR message_record IN
    SELECT m.*
    FROM messages m
    WHERE 
      m.created_at > NOW() - INTERVAL '7 days' AND
      m.sender = 'client' AND
      m.status = 'sent' AND
      m.asistente_ia_activado = TRUE AND
      (m.ia_webhook_sent IS NULL OR m.ia_webhook_sent = FALSE) AND
      m.content NOT LIKE '[IA]%'
    ORDER BY m.created_at ASC
    LIMIT 100
  LOOP
    -- Actualizar el mensaje para activar el trigger
    UPDATE messages
    SET updated_at = NOW()
    WHERE id = message_record.id;
    
    processed_count := processed_count + 1;
  END LOOP;
  
  RETURN processed_count;
END;
$$ LANGUAGE plpgsql;

-- 5. Verificar si la tabla message_whatsapp_status existe y crear la política RLS
DO $$
BEGIN
  IF EXISTS (
    SELECT 1
    FROM information_schema.tables
    WHERE table_name = 'message_whatsapp_status'
  ) THEN
    -- Verificar si la política ya existe
    IF NOT EXISTS (
      SELECT 1
      FROM pg_policies
      WHERE tablename = 'message_whatsapp_status' AND policyname = 'Allow inserts from system'
    ) THEN
      -- Habilitar RLS en la tabla si no está habilitado
      ALTER TABLE message_whatsapp_status ENABLE ROW LEVEL SECURITY;
      
      -- Crear política para permitir inserciones desde el sistema
      CREATE POLICY "Allow inserts from system" ON message_whatsapp_status
        FOR INSERT
        WITH CHECK (true);
      
      RAISE NOTICE 'Política RLS creada para la tabla message_whatsapp_status';
    ELSE
      RAISE NOTICE 'La política RLS ya existe para la tabla message_whatsapp_status';
    END IF;
  ELSE
    RAISE NOTICE 'La tabla message_whatsapp_status no existe, no se puede crear la política RLS';
  END IF;
END;
$$;

-- 6. Verificar si la extensión http está instalada
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_extension
    WHERE extname = 'http'
  ) THEN
    RAISE WARNING 'La extensión http no está instalada. Esta es necesaria para que el webhook de IA funcione.';
    RAISE WARNING 'Ejecuta el siguiente comando para instalarla:';
    RAISE WARNING 'CREATE EXTENSION http;';
  ELSE
    RAISE NOTICE 'La extensión http está instalada correctamente';
  END IF;
END;
$$;

-- 7. Procesar mensajes pendientes
SELECT process_pending_ia_messages() AS mensajes_procesados;

-- 8. Mostrar resumen
DO $$
BEGIN
  RAISE NOTICE '------------------------------------------------------------';
  RAISE NOTICE 'RESUMEN DE LA APLICACIÓN DE LA SOLUCIÓN';
  RAISE NOTICE '------------------------------------------------------------';
  RAISE NOTICE '1. Se ha añadido la columna ia_webhook_sent a la tabla messages (si no existía)';
  RAISE NOTICE '2. Se ha creado o reemplazado la función notify_message_webhook';
  RAISE NOTICE '3. Se ha creado o reemplazado el trigger message_webhook_trigger';
  RAISE NOTICE '4. Se ha creado o reemplazado la función process_pending_ia_messages';
  RAISE NOTICE '5. Se ha verificado la política RLS para message_whatsapp_status';
  RAISE NOTICE '6. Se ha verificado la instalación de la extensión http';
  RAISE NOTICE '7. Se han procesado los mensajes pendientes';
  RAISE NOTICE '------------------------------------------------------------';
  RAISE NOTICE 'La solución ha sido aplicada correctamente.';
  RAISE NOTICE 'Para verificar que funciona, envía un mensaje con el asistente de IA activado';
  RAISE NOTICE 'y verifica que aparece en los logs de Supabase.';
  RAISE NOTICE '------------------------------------------------------------';
END;
$$;
