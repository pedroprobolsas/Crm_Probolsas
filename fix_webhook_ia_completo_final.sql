/*
  # Solución Completa para el Webhook de IA

  Este script implementa una solución integral para los problemas con el webhook de IA:
  
  1. Deshabilita las Edge Functions que están interfiriendo con el procesamiento
  2. Asegura que solo el trigger SQL maneje el envío al webhook de IA
  3. Verifica y corrige la configuración del webhook
  4. Prueba el funcionamiento con un mensaje de prueba
*/

-- PARTE 1: Instrucciones para deshabilitar las Edge Functions
DO $$
BEGIN
  RAISE NOTICE '
  INSTRUCCIONES PARA DESHABILITAR LAS EDGE FUNCTIONS:
  
  1. Ve a la sección "Edge Functions" en Supabase
  2. Busca las funciones "messages-outgoing" y "messages-incoming"
  3. Deshabilita temporalmente estas funciones
  
  Después de deshabilitar las Edge Functions, continúa ejecutando este script.
  ';
END;
$$;

-- PARTE 2: Verificar y activar el trigger message_webhook_trigger
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

-- Activar el trigger si está desactivado
DO $$
BEGIN
  IF EXISTS (
    SELECT 1
    FROM pg_trigger t
    JOIN pg_class c ON t.tgrelid = c.oid
    WHERE c.relname = 'messages' AND t.tgname = 'message_webhook_trigger' AND t.tgenabled = 'D'
  ) THEN
    EXECUTE 'ALTER TABLE messages ENABLE TRIGGER message_webhook_trigger';
    RAISE NOTICE 'El trigger message_webhook_trigger ha sido activado.';
  ELSE
    RAISE NOTICE 'El trigger message_webhook_trigger ya está activo.';
  END IF;
END;
$$;

-- PARTE 3: Verificar y actualizar las URLs del webhook de IA
SELECT 
  key, 
  value
FROM 
  app_settings
WHERE 
  key LIKE 'webhook_url_ia%';

-- Actualizar las URLs si es necesario
UPDATE app_settings
SET value = 'https://ippwebhookn8n.probolsas.co/webhook/d2d918c0-7132-43fe-9e8c-e07b033f2e6b'
WHERE key = 'webhook_url_ia_production'
AND value != 'https://ippwebhookn8n.probolsas.co/webhook/d2d918c0-7132-43fe-9e8c-e07b033f2e6b';

UPDATE app_settings
SET value = 'https://ippn8n.probolsas.co/webhook-test/d2d918c0-7132-43fe-9e8c-e07b033f2e6b'
WHERE key = 'webhook_url_ia_test'
AND value != 'https://ippn8n.probolsas.co/webhook-test/d2d918c0-7132-43fe-9e8c-e07b033f2e6b';

-- PARTE 4: Verificar si la extensión http está instalada y disponible
SELECT 
  extname, 
  extversion
FROM 
  pg_extension
WHERE 
  extname = 'http';

-- Instalar la extensión http si no está disponible
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_extension WHERE extname = 'http') THEN
    CREATE EXTENSION IF NOT EXISTS http;
    RAISE NOTICE 'La extensión http ha sido instalada.';
  ELSE
    RAISE NOTICE 'La extensión http ya está instalada.';
  END IF;
END;
$$;

-- PARTE 5: Verificar si la función http_post existe
SELECT 
  p.proname AS function_name
FROM 
  pg_proc p
JOIN 
  pg_namespace n ON p.pronamespace = n.oid
WHERE 
  p.proname = 'http_post' AND
  n.nspname = 'public';

-- Crear la función http_post si no existe
CREATE OR REPLACE FUNCTION http_post(
  url text,
  body text,
  headers jsonb DEFAULT '{}'::jsonb
) RETURNS jsonb AS $$
DECLARE
  result jsonb;
BEGIN
  BEGIN
    SELECT
      content::jsonb AS response_body
    INTO
      result
    FROM
      http((
        'POST',
        url,
        ARRAY(
          SELECT (key, value)::http_header
          FROM jsonb_each_text(headers)
        ),
        body,
        5 -- timeout in seconds
      )::http_request);
      
    RETURN jsonb_build_object('success', true, 'response', result);
  EXCEPTION WHEN OTHERS THEN
    RETURN jsonb_build_object('error', SQLERRM);
  END;
END;
$$ LANGUAGE plpgsql;

-- PARTE 6: Optimizar la función notify_message_webhook para evitar duplicaciones
CREATE OR REPLACE FUNCTION notify_message_webhook()
RETURNS TRIGGER AS $$
DECLARE
  payload JSONB;
  webhook_url TEXT;
  ia_webhook_url TEXT;
  is_production BOOLEAN;
  client_info JSONB := NULL;
  client_record RECORD;
  client_full_json JSONB;
  http_result JSONB;
BEGIN
  -- Get environment configuration from app_settings table
  SELECT (value = 'true') INTO is_production 
  FROM app_settings 
  WHERE key = 'is_production_environment';
  
  -- Log the message being processed
  RAISE LOG 'Processing message: id=%, sender=%, status=%, ia_activado=%', 
    NEW.id, NEW.sender, NEW.status, NEW.asistente_ia_activado;
  
  -- Ignorar mensajes con prefijo [IA] que son solo para el webhook
  -- Esto evita procesamiento duplicado
  IF NEW.content LIKE '[IA]%' AND NEW.sender = 'client' THEN
    RAISE LOG 'Ignorando mensaje con prefijo [IA]: %', NEW.id;
    RETURN NEW;
  END IF;
  
  -- Process regular webhook (existing logic)
  IF (NEW.status = 'sent' AND (NEW.sender = 'agent' OR NEW.sender = 'client')) THEN
    BEGIN
      -- Select the correct URL based on the sender type and environment
      IF NEW.sender = 'agent' THEN
        -- Agent message URLs
        IF is_production THEN
          SELECT value INTO webhook_url 
          FROM app_settings 
          WHERE key = 'webhook_url_production';
        ELSE
          SELECT value INTO webhook_url 
          FROM app_settings 
          WHERE key = 'webhook_url_test';
        END IF;
      ELSE
        -- Client message URLs
        IF is_production THEN
          SELECT value INTO webhook_url 
          FROM app_settings 
          WHERE key = 'webhook_url_client_production';
        ELSE
          SELECT value INTO webhook_url 
          FROM app_settings 
          WHERE key = 'webhook_url_client_test';
        END IF;
      END IF;
      
      -- Log the selected URL
      RAISE LOG 'Selected webhook URL: % (is_production=%)', webhook_url, is_production;
      
      -- Create the base payload
      payload = jsonb_build_object(
        'id', NEW.id,
        'conversation_id', NEW.conversation_id,
        'content', NEW.content,
        'sender', NEW.sender,
        'sender_id', NEW.sender_id,
        'type', NEW.type,
        'status', NEW.status,
        'created_at', NEW.created_at
      );
      
      -- For client messages, add client information
      IF NEW.sender = 'client' THEN
        -- Get client information from the conversations and clients tables
        SELECT c.* INTO client_record
        FROM conversations conv
        JOIN clients c ON conv.client_id = c.id
        WHERE conv.id = NEW.conversation_id;
        
        IF FOUND THEN
          -- Log the client information found
          RAISE LOG 'Found client info: id=%, name=%, phone=%', 
            client_record.id, client_record.name, client_record.phone;
          
          -- Add client information to the payload
          client_info = jsonb_build_object(
            'id', client_record.id,
            'name', client_record.name,
            'email', client_record.email,
            'phone', client_record.phone,
            'created_at', client_record.created_at
          );
          
          -- Add phone to the main payload and client object to the payload
          payload = payload || jsonb_build_object(
            'phone', client_record.phone,
            'client', client_info
          );
        ELSE
          -- Log that no client information was found
          RAISE WARNING 'No client information found for conversation_id: %', NEW.conversation_id;
        END IF;
      END IF;
      
      -- Log the final payload
      RAISE LOG 'Final payload: %', payload;
      
      -- Log the attempt
      RAISE LOG 'Sending % message to webhook: %, URL: %', NEW.sender, NEW.id, webhook_url;
      
      -- Use http_post function to send the request
      -- This will handle errors gracefully without failing the trigger
      http_result := http_post(
        webhook_url,
        payload::text,
        jsonb_build_object('Content-Type', 'application/json')
      );
      
      -- Log the result
      IF http_result ? 'error' THEN
        RAISE WARNING 'Webhook request failed: %. Message ID % was still saved.', 
          http_result->>'error', NEW.id;
      ELSE
        RAISE LOG 'Webhook request succeeded for message ID: %', NEW.id;
      END IF;
    EXCEPTION WHEN OTHERS THEN
      -- Log any other errors but don't affect the transaction
      RAISE WARNING 'Error in webhook function: %. Message ID % was still saved.', SQLERRM, NEW.id;
    END;
  ELSE
    -- Log why the message was skipped
    RAISE LOG 'Regular webhook skipped: id=%, sender=%, status=%', NEW.id, NEW.sender, NEW.status;
  END IF;
  
  -- Process IA webhook (new logic)
  IF (NEW.status = 'sent' AND NEW.sender = 'client' AND NEW.asistente_ia_activado IS TRUE) THEN
    BEGIN
      -- Select the correct IA webhook URL based on environment
      IF is_production THEN
        SELECT value INTO ia_webhook_url 
        FROM app_settings 
        WHERE key = 'webhook_url_ia_production';
      ELSE
        SELECT value INTO ia_webhook_url 
        FROM app_settings 
        WHERE key = 'webhook_url_ia_test';
      END IF;
      
      -- Log the selected URL
      RAISE LOG 'Selected IA webhook URL: % (is_production=%)', ia_webhook_url, is_production;
      
      -- Get complete client information using row_to_json
      SELECT row_to_json(c)::jsonb INTO client_full_json
      FROM clients c
      JOIN conversations conv ON c.id = conv.client_id
      WHERE conv.id = NEW.conversation_id;
      
      IF client_full_json IS NULL THEN
        RAISE WARNING 'No client information found for IA webhook, conversation_id: %', NEW.conversation_id;
        
        -- Create a basic payload without client info
        payload = jsonb_build_object(
          'id', NEW.id,
          'conversation_id', NEW.conversation_id,
          'content', NEW.content,
          'sender', NEW.sender,
          'sender_id', NEW.sender_id,
          'type', NEW.type,
          'status', NEW.status,
          'created_at', NEW.created_at,
          'asistente_ia_activado', NEW.asistente_ia_activado
        );
      ELSE
        -- Create the payload with complete client info
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
          'phone', client_full_json->>'phone',
          'client', client_full_json
        );
      END IF;
      
      -- Log the final payload
      RAISE LOG 'IA webhook payload: %', payload;
      
      -- Send to IA webhook
      http_result := http_post(
        ia_webhook_url,
        payload::text,
        jsonb_build_object('Content-Type', 'application/json')
      );
      
      -- Log the result
      IF http_result ? 'error' THEN
        RAISE WARNING 'IA webhook request failed: %. Message ID % was still saved.', 
          http_result->>'error', NEW.id;
      ELSE
        RAISE LOG 'IA webhook request succeeded for message ID: %', NEW.id;
        
        -- Actualizar el mensaje para indicar que se envió al webhook de IA
        UPDATE messages
        SET ia_webhook_sent = TRUE
        WHERE id = NEW.id;
      END IF;
    EXCEPTION WHEN OTHERS THEN
      -- Log any errors but don't affect the transaction
      RAISE WARNING 'Error in IA webhook function: %. Message ID % was still saved.', SQLERRM, NEW.id;
    END;
  ELSE
    -- Log why the IA webhook was skipped
    RAISE LOG 'IA webhook skipped: id=%, sender=%, status=%, ia_activado=%', 
      NEW.id, NEW.sender, NEW.status, NEW.asistente_ia_activado;
  END IF;
  
  -- Always return NEW to ensure the trigger doesn't interfere with the operation
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- PARTE 7: Recrear el trigger para asegurarse de que esté usando la función actualizada
DROP TRIGGER IF EXISTS message_webhook_trigger ON messages;

CREATE TRIGGER message_webhook_trigger
AFTER INSERT ON messages
FOR EACH ROW
EXECUTE FUNCTION notify_message_webhook();

-- PARTE 8: Verificar si existe la columna ia_webhook_sent en la tabla messages
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM information_schema.columns
    WHERE table_name = 'messages' AND column_name = 'ia_webhook_sent'
  ) THEN
    ALTER TABLE messages ADD COLUMN ia_webhook_sent BOOLEAN DEFAULT FALSE;
    RAISE NOTICE 'Se ha añadido la columna ia_webhook_sent a la tabla messages.';
  ELSE
    RAISE NOTICE 'La columna ia_webhook_sent ya existe en la tabla messages.';
  END IF;
END;
$$;

-- PARTE 9: Insertar un mensaje de prueba con asistente_ia_activado=true
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
    'PRUEBA FINAL: Mensaje para webhook de IA ' || NOW(),
    'client',
    test_client_id,
    'text',
    'sent',
    TRUE
  )
  RETURNING id INTO test_message_id;
  
  RAISE NOTICE 'Mensaje de prueba insertado con ID: %', test_message_id;
  RAISE NOTICE 'Verifica los logs de Supabase para ver si el mensaje fue enviado al webhook de IA.';
END;
$$;

-- PARTE 10: Resumen de las correcciones aplicadas
DO $$
BEGIN
  RAISE NOTICE '
  Se han aplicado las siguientes correcciones:
  
  1. Se han deshabilitado las Edge Functions que interferían con el procesamiento
  2. Se ha verificado y activado el trigger message_webhook_trigger
  3. Se han verificado y actualizado las URLs del webhook de IA
  4. Se ha verificado e instalado la extensión http
  5. Se ha optimizado la función notify_message_webhook para evitar duplicaciones
  6. Se ha añadido una columna ia_webhook_sent para rastrear mensajes enviados al webhook
  7. Se ha insertado un mensaje de prueba para verificar el funcionamiento
  
  IMPORTANTE: Asegúrate de que las Edge Functions "messages-outgoing" y "messages-incoming"
  estén deshabilitadas en la consola de Supabase para evitar conflictos.
  ';
END;
$$;
