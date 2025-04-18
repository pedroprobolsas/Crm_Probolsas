-- Script mejorado para solucionar el problema del webhook de IA
-- Este script debe ejecutarse directamente en la consola SQL de Supabase

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

-- 2. Crear o reemplazar la función notify_message_webhook con logging mejorado
CREATE OR REPLACE FUNCTION notify_message_webhook()
RETURNS TRIGGER AS $$
DECLARE
  webhook_url TEXT;
  client_phone TEXT;
  client_data JSONB;
  response JSONB;
  error_message TEXT;
  log_message TEXT;
BEGIN
  -- Mejorar el logging para depuración
  log_message := format('TRIGGER EJECUTADO - ID: %s, Sender: %s, Status: %s, IA Activado: %s, IA Sent: %s', 
                        NEW.id, NEW.sender, NEW.status, NEW.asistente_ia_activado, NEW.ia_webhook_sent);
  RAISE NOTICE '%', log_message;

  -- Ignorar mensajes que ya han sido enviados al webhook
  IF NEW.ia_webhook_sent = TRUE THEN
    RAISE NOTICE 'Mensaje ya enviado al webhook de IA, ignorando: %', NEW.id;
    RETURN NEW;
  END IF;

  -- Solo procesar mensajes con asistente_ia_activado=true
  IF NEW.asistente_ia_activado IS NOT TRUE THEN
    RAISE NOTICE 'Mensaje sin asistente_ia_activado=true, ignorando: %', NEW.id;
    RETURN NEW;
  END IF;

  -- Solo procesar mensajes de clientes
  IF NEW.sender != 'client' THEN
    RAISE NOTICE 'Mensaje no es de cliente (sender=%s), ignorando: %', NEW.sender, NEW.id;
    RETURN NEW;
  END IF;

  -- Ignorar mensajes con prefijo [IA] para evitar duplicados
  IF NEW.content LIKE '[IA]%' THEN
    RAISE NOTICE 'Mensaje con prefijo [IA] detectado, ignorando: %', NEW.id;
    RETURN NEW;
  END IF;

  -- Obtener la URL del webhook de IA desde app_settings
  SELECT value INTO webhook_url
  FROM app_settings
  WHERE key = 'webhook_url_ia_production';

  IF webhook_url IS NULL THEN
    RAISE WARNING 'No se encontró la URL del webhook de IA en app_settings, usando URL de respaldo';
    webhook_url := 'https://ippwebhookn8n.probolsas.co/webhook/d2d918c0-7132-43fe-9e8c-e07b033f2e6b';
  END IF;

  -- Obtener el número de teléfono del cliente
  SELECT c.phone INTO client_phone
  FROM conversations conv
  JOIN clients c ON conv.client_id = c.id
  WHERE conv.id = NEW.conversation_id;

  -- Obtener datos completos del cliente
  SELECT row_to_json(c) INTO client_data
  FROM clients c
  JOIN conversations conv ON conv.client_id = c.id
  WHERE conv.id = NEW.conversation_id;

  -- Preparar el payload para el webhook
  DECLARE
    payload JSONB := jsonb_build_object(
      'id', NEW.id,
      'conversation_id', NEW.conversation_id,
      'content', NEW.content,
      'sender', NEW.sender,
      'sender_id', NEW.sender_id,
      'type', COALESCE(NEW.type, 'text'),
      'status', NEW.status,
      'created_at', NEW.created_at,
      'asistente_ia_activado', NEW.asistente_ia_activado,
      'phone', client_phone,
      'client', client_data,
      'source', 'trigger_sql' -- Añadir fuente para depuración
    );
  BEGIN
    -- Enviar el mensaje al webhook de IA
    RAISE NOTICE 'Enviando mensaje al webhook de IA: %', NEW.id;
    
    SELECT * FROM http((
      'POST',
      webhook_url,
      ARRAY[http_header('Content-Type', 'application/json')],
      'application/json',
      payload::text
    )) INTO response;

    -- Marcar el mensaje como enviado al webhook
    NEW.ia_webhook_sent := TRUE;

    RAISE NOTICE 'Mensaje enviado al webhook de IA: %', NEW.id;
    RETURN NEW;
  EXCEPTION
    WHEN OTHERS THEN
      GET STACKED DIAGNOSTICS error_message = MESSAGE_TEXT;
      RAISE WARNING 'Error al enviar mensaje al webhook de IA: %', error_message;
      RETURN NEW;
  END;
END;
$$ LANGUAGE plpgsql;

-- 3. Eliminar el trigger existente y crear uno nuevo que responda a INSERT y UPDATE
DROP TRIGGER IF EXISTS message_webhook_trigger ON messages;

CREATE TRIGGER message_webhook_trigger
AFTER INSERT OR UPDATE OF asistente_ia_activado ON messages
FOR EACH ROW
EXECUTE FUNCTION notify_message_webhook();

-- 4. Verificar que el trigger está activo
DO $$
DECLARE
  trigger_status TEXT;
BEGIN
  SELECT 
    CASE WHEN t.tgenabled = 'D' THEN 'DESACTIVADO' ELSE 'ACTIVADO' END INTO trigger_status
  FROM 
    pg_trigger t
  JOIN 
    pg_class c ON t.tgrelid = c.oid
  WHERE 
    c.relname = 'messages' AND
    t.tgname = 'message_webhook_trigger';
    
  IF trigger_status IS NULL THEN
    RAISE NOTICE 'No se encontró el trigger message_webhook_trigger';
  ELSE
    RAISE NOTICE 'El trigger message_webhook_trigger está %', trigger_status;
  END IF;
END;
$$;

-- 5. Crear una función para procesar mensajes pendientes
CREATE OR REPLACE FUNCTION process_pending_ia_messages()
RETURNS INTEGER AS $$
DECLARE
  webhook_url TEXT;
  client_phone TEXT;
  client_data JSONB;
  response JSONB;
  error_message TEXT;
  processed_count INTEGER := 0;
  message_record RECORD;
BEGIN
  -- Obtener la URL del webhook de IA desde app_settings
  SELECT value INTO webhook_url
  FROM app_settings
  WHERE key = 'webhook_url_ia_production';

  IF webhook_url IS NULL THEN
    RAISE WARNING 'No se encontró la URL del webhook de IA en app_settings, usando URL de respaldo';
    webhook_url := 'https://ippwebhookn8n.probolsas.co/webhook/d2d918c0-7132-43fe-9e8c-e07b033f2e6b';
  END IF;

  -- Procesar mensajes pendientes
  FOR message_record IN 
    SELECT m.* 
    FROM messages m
    WHERE 
      m.sender = 'client' AND 
      m.asistente_ia_activado = TRUE AND 
      (m.ia_webhook_sent IS NULL OR m.ia_webhook_sent = FALSE) AND
      m.created_at > NOW() - INTERVAL '7 days'
    ORDER BY m.created_at DESC
    LIMIT 50
  LOOP
    BEGIN
      -- Obtener el número de teléfono del cliente
      SELECT c.phone INTO client_phone
      FROM conversations conv
      JOIN clients c ON conv.client_id = c.id
      WHERE conv.id = message_record.conversation_id;

      -- Obtener datos completos del cliente
      SELECT row_to_json(c) INTO client_data
      FROM clients c
      JOIN conversations conv ON conv.client_id = c.id
      WHERE conv.id = message_record.conversation_id;

      -- Preparar el payload para el webhook
      DECLARE
        payload JSONB := jsonb_build_object(
          'id', message_record.id,
          'conversation_id', message_record.conversation_id,
          'content', message_record.content,
          'sender', message_record.sender,
          'sender_id', message_record.sender_id,
          'type', COALESCE(message_record.type, 'text'),
          'status', message_record.status,
          'created_at', message_record.created_at,
          'asistente_ia_activado', message_record.asistente_ia_activado,
          'phone', client_phone,
          'client', client_data,
          'source', 'batch_process' -- Añadir fuente para depuración
        );
      BEGIN
        -- Enviar el mensaje al webhook de IA
        RAISE NOTICE 'Procesando mensaje pendiente: %', message_record.id;
        
        SELECT * FROM http((
          'POST',
          webhook_url,
          ARRAY[http_header('Content-Type', 'application/json')],
          'application/json',
          payload::text
        )) INTO response;

        -- Marcar el mensaje como enviado al webhook
        UPDATE messages 
        SET ia_webhook_sent = TRUE 
        WHERE id = message_record.id;

        processed_count := processed_count + 1;
        RAISE NOTICE 'Mensaje pendiente enviado al webhook de IA: %', message_record.id;
      EXCEPTION
        WHEN OTHERS THEN
          GET STACKED DIAGNOSTICS error_message = MESSAGE_TEXT;
          RAISE WARNING 'Error al enviar mensaje pendiente al webhook de IA: %', error_message;
      END;
    EXCEPTION
      WHEN OTHERS THEN
        RAISE WARNING 'Error al procesar mensaje pendiente: %', message_record.id;
    END;
  END LOOP;

  RETURN processed_count;
END;
$$ LANGUAGE plpgsql;

-- 6. Procesar mensajes pendientes
DO $$
DECLARE
  processed_count INTEGER;
BEGIN
  SELECT process_pending_ia_messages() INTO processed_count;
  RAISE NOTICE 'Se procesaron % mensajes pendientes', processed_count;
END;
$$;

-- 7. Crear una política RLS para la tabla message_whatsapp_status
DO $$
BEGIN
  -- Verificar si la tabla existe
  IF EXISTS (
    SELECT 1
    FROM information_schema.tables
    WHERE table_name = 'message_whatsapp_status'
  ) THEN
    -- Eliminar políticas existentes
    DROP POLICY IF EXISTS "Allow inserts from system" ON message_whatsapp_status;
    
    -- Crear nueva política
    CREATE POLICY "Allow inserts from system" ON message_whatsapp_status
    FOR INSERT 
    TO authenticated, service_role
    WITH CHECK (true);
    
    RAISE NOTICE 'Política RLS creada para la tabla message_whatsapp_status';
  ELSE
    RAISE NOTICE 'La tabla message_whatsapp_status no existe, no se creó la política RLS';
  END IF;
END;
$$;

-- 8. Verificar la extensión http
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_extension
    WHERE extname = 'http'
  ) THEN
    RAISE WARNING 'La extensión http no está instalada. Intentando instalarla...';
    CREATE EXTENSION IF NOT EXISTS http;
  ELSE
    RAISE NOTICE 'La extensión http está instalada correctamente';
  END IF;
END;
$$;

-- 9. Insertar un mensaje de prueba con asistente_ia_activado=true
DO $$
DECLARE
  test_conversation_id UUID;
  test_client_id UUID;
  test_message_id UUID;
  message_record RECORD;
BEGIN
  -- Obtener un conversation_id y client_id existentes
  SELECT conv.id, conv.client_id INTO test_conversation_id, test_client_id
  FROM conversations conv
  LIMIT 1;
  
  IF test_conversation_id IS NULL THEN
    RAISE NOTICE 'No se encontraron conversaciones para la prueba.';
    RETURN;
  END IF;
  
  -- Insertar un mensaje de prueba con asistente_ia_activado=true
  INSERT INTO messages (
    conversation_id,
    content,
    sender,
    sender_id,
    type,
    status,
    asistente_ia_activado
  )
  VALUES (
    test_conversation_id,
    'VERIFICACIÓN: Mensaje de prueba para webhook de IA ' || NOW(),
    'client',
    test_client_id,
    'text',
    'sent',
    TRUE
  )
  RETURNING id INTO test_message_id;
  
  RAISE NOTICE 'Mensaje de prueba insertado con ID: %', test_message_id;
  RAISE NOTICE 'Verifica los logs de Supabase para ver si el mensaje fue enviado al webhook de IA.';
  
  -- Esperar un momento para que el trigger se ejecute
  PERFORM pg_sleep(2);
  
  -- Verificar si el mensaje fue marcado como enviado al webhook de IA
  SELECT 
    id, 
    content, 
    ia_webhook_sent
  INTO message_record
  FROM 
    messages
  WHERE 
    id = test_message_id;
    
  -- Mostrar los resultados
  RAISE NOTICE 'Mensaje ID: %, Enviado al webhook: %', 
    message_record.id, 
    message_record.ia_webhook_sent;
END;
$$;
