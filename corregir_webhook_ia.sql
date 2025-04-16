/*
  # Corrección del Webhook de IA
  
  Este script SQL corrige la función notify_message_webhook para asegurar que
  el contenido del mensaje se incluya correctamente en el payload enviado al webhook de IA.
  
  Este script es parte de la solución para el problema del webhook de IA.
*/

-- Paso 1: Verificar las URLs del webhook de IA en app_settings
SELECT 
  key, 
  value
FROM 
  app_settings
WHERE 
  key LIKE 'webhook_url_ia%';

-- Paso 2: Actualizar las URLs del webhook de IA si es necesario
UPDATE app_settings
SET value = 'https://ippwebhookn8n.probolsas.co/webhook/d2d918c0-7132-43fe-9e8c-e07b033f2e6b'
WHERE key = 'webhook_url_ia_production';

UPDATE app_settings
SET value = 'https://ippn8n.probolsas.co/webhook-test/d2d918c0-7132-43fe-9e8c-e07b033f2e6b'
WHERE key = 'webhook_url_ia_test';

-- Paso 3: Crear una función http_post segura para evitar errores de sintaxis
CREATE OR REPLACE FUNCTION http_post(
  url text,
  body text,
  headers jsonb DEFAULT '{}'::jsonb
) RETURNS jsonb AS $$
DECLARE
  result jsonb;
BEGIN
  -- Asegurarse de que los parámetros estén en el orden correcto
  -- y que el cuerpo se envíe como cuerpo y no como encabezado
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

-- Paso 4: Modificar la función notify_message_webhook para incluir el contenido en el payload
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
        'created_at', NEW.created_at,
        'message', NEW.content  -- Añadir el contenido como 'message' para compatibilidad
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
          'asistente_ia_activado', NEW.asistente_ia_activado,
          'message', NEW.content  -- Añadir el contenido como 'message' para compatibilidad
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
          'client', client_full_json,
          'message', NEW.content  -- Añadir el contenido como 'message' para compatibilidad
        );
      END IF;
      
      -- Log the final payload
      RAISE LOG 'IA webhook payload: %', payload;
      
      -- CORRECCIÓN: Asegurarse de que los parámetros estén en el orden correcto
      -- Orden correcto: (url, body, headers)
      http_result := http_post(
        ia_webhook_url,
        payload::text,  -- Este es el cuerpo (body) de la solicitud
        jsonb_build_object('Content-Type', 'application/json')  -- Estos son los encabezados (headers)
      );
      
      -- Log the result
      IF http_result ? 'error' THEN
        RAISE WARNING 'IA webhook request failed: %. Message ID % was still saved.', 
          http_result->>'error', NEW.id;
      ELSE
        RAISE LOG 'IA webhook request succeeded for message ID: %', NEW.id;
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

-- Paso 5: Recrear el trigger para asegurarse de que esté usando la función actualizada
DROP TRIGGER IF EXISTS message_webhook_trigger ON messages;

CREATE TRIGGER message_webhook_trigger
AFTER INSERT ON messages
FOR EACH ROW
EXECUTE FUNCTION notify_message_webhook();

-- Paso 6: Insertar un mensaje de prueba con asistente_ia_activado=true
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
    'CORRECCIÓN WEBHOOK IA: Mensaje de prueba para webhook de IA ' || NOW(),
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

-- Paso 7: Verificar los mensajes recientes con asistente_ia_activado=true
SELECT 
  id, 
  conversation_id, 
  content, 
  sender, 
  status, 
  asistente_ia_activado, 
  created_at
FROM 
  messages
WHERE 
  asistente_ia_activado = TRUE
ORDER BY 
  created_at DESC
LIMIT 5;
