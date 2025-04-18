-- Script completo para solucionar el problema del webhook de IA
-- Este script debe ejecutarse directamente en la consola SQL de Supabase

-- 1. Verificar si existe la columna ia_webhook_sent en la tabla messages
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM information_schema.columns
    WHERE table_name = 'messages' AND column_name = 'ia_webhook_sent'
  ) THEN
    -- Añadir la columna ia_webhook_sent a la tabla messages
    ALTER TABLE messages ADD COLUMN ia_webhook_sent BOOLEAN DEFAULT FALSE;
    RAISE NOTICE 'Columna ia_webhook_sent añadida a la tabla messages';
  ELSE
    RAISE NOTICE 'La columna ia_webhook_sent ya existe en la tabla messages';
  END IF;
END;
$$;

-- 2. Crear o reemplazar la función notify_message_webhook
CREATE OR REPLACE FUNCTION notify_message_webhook()
RETURNS TRIGGER AS $$
DECLARE
  webhook_url TEXT;
  client_phone TEXT;
  client_data JSONB;
  response JSONB;
  error_message TEXT;
BEGIN
  -- Ignorar mensajes que ya han sido enviados al webhook
  IF NEW.ia_webhook_sent = TRUE THEN
    RAISE NOTICE 'Mensaje ya enviado al webhook de IA, ignorando: %', NEW.id;
    RETURN NEW;
  END IF;

  -- Solo procesar mensajes con asistente_ia_activado=true
  IF NEW.asistente_ia_activado IS NOT TRUE THEN
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
    RAISE WARNING 'No se encontró la URL del webhook de IA en app_settings';
    RETURN NEW;
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
      'client', client_data
    );
  BEGIN
    -- Enviar el mensaje al webhook de IA
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

-- 3. Crear o reemplazar el trigger message_webhook_trigger
DROP TRIGGER IF EXISTS message_webhook_trigger ON messages;
CREATE TRIGGER message_webhook_trigger
AFTER INSERT ON messages
FOR EACH ROW
EXECUTE FUNCTION notify_message_webhook();

-- 4. Verificar que el trigger está activo
SELECT 
  t.tgname AS trigger_name,
  CASE WHEN t.tgenabled = 'D' THEN 'DESACTIVADO' ELSE 'ACTIVADO' END AS status
FROM 
  pg_trigger t
JOIN 
  pg_class c ON t.tgrelid = c.oid
WHERE 
  c.relname = 'messages' AND
  t.tgname = 'message_webhook_trigger';

-- 5. Insertar un mensaje de prueba con asistente_ia_activado=true
DO $$
DECLARE
  test_conversation_id UUID;
  test_client_id UUID;
  test_message_id UUID;
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
  FROM 
    messages
  WHERE 
    id = test_message_id;
END;
$$;
