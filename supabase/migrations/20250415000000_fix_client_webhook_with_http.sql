/*
  # Solución para el Webhook de Mensajes de Clientes usando HTTP Extension

  1. Propósito
    - Solucionar el problema donde los mensajes de clientes con estado 'sent' no están siendo enviados al webhook
    - Modificar la función notify_message_webhook para usar la extensión http en lugar de pg_net
    - Agregar más logging para identificar problemas
    
  2. Características
    - Usa la extensión http que proporciona respuestas síncronas en lugar de asíncronas
    - Incluye más logging para identificar exactamente dónde está fallando
    - Maneja los errores de forma más explícita
    - Mantiene la misma lógica para seleccionar la URL según el tipo de remitente y el entorno
*/

-- Verificar que la extensión http esté instalada
DO $$
DECLARE
  http_version TEXT;
BEGIN
  SELECT extversion INTO http_version FROM pg_extension WHERE extname = 'http';
  
  IF http_version IS NULL THEN
    RAISE EXCEPTION 'La extensión HTTP no está instalada. Por favor, instálala primero.';
  ELSE
    RAISE NOTICE 'La extensión HTTP está instalada (versión %)', http_version;
  END IF;
END;
$$;

-- Crear o actualizar la función http_post para trabajar correctamente con la extensión HTTP
CREATE OR REPLACE FUNCTION http_post(
  url TEXT,
  body TEXT,
  headers JSONB
)
RETURNS JSONB AS $$
DECLARE
  result JSONB;
BEGIN
  -- Usar la extensión http para hacer la solicitud POST
  SELECT content::jsonb INTO result
  FROM http((
    'POST',
    url,
    headers,
    'application/json',
    body
  )::http_request);
  
  RETURN result;
EXCEPTION WHEN OTHERS THEN
  -- Registrar el error pero no fallar
  RAISE WARNING 'Solicitud HTTP POST fallida: %. URL: %, Body: %', SQLERRM, url, body;
  
  -- Devolver información de error como JSON
  RETURN jsonb_build_object(
    'error', SQLERRM,
    'detail', SQLSTATE,
    'url', url
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Otorgar permiso de ejecución a usuarios autenticados
GRANT EXECUTE ON FUNCTION http_post(TEXT, TEXT, JSONB) TO authenticated;

-- Agregar un comentario para explicar la función
COMMENT ON FUNCTION http_post(TEXT, TEXT, JSONB) IS 
'Una función wrapper para solicitudes HTTP POST que maneja errores de forma elegante';

-- Modificar la función notify_message_webhook para usar http_post en lugar de net.http_post
CREATE OR REPLACE FUNCTION notify_message_webhook()
RETURNS TRIGGER AS $$
DECLARE
  payload JSONB;
  webhook_url TEXT;
  is_production BOOLEAN;
  client_info JSONB := NULL;
  client_record RECORD;
  http_result JSONB;
BEGIN
  -- Get environment configuration from app_settings table
  SELECT (value = 'true') INTO is_production 
  FROM app_settings 
  WHERE key = 'is_production_environment';
  
  -- Log the message being processed
  RAISE LOG 'Processing message: id=%, sender=%, status=%', NEW.id, NEW.sender, NEW.status;
  
  -- Only proceed if conditions are met (agent or client with status 'sent')
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
    RAISE LOG 'Message skipped: id=%, sender=%, status=%', NEW.id, NEW.sender, NEW.status;
  END IF;
  
  -- Always return NEW to ensure the trigger doesn't interfere with the operation
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Recrear el trigger para asegurarse de que esté usando la función actualizada
DROP TRIGGER IF EXISTS message_webhook_trigger ON messages;

CREATE TRIGGER message_webhook_trigger
AFTER INSERT ON messages
FOR EACH ROW
EXECUTE FUNCTION notify_message_webhook();

-- Agregar un comentario para explicar el trigger
COMMENT ON TRIGGER message_webhook_trigger ON messages IS 
'Envía mensajes con status=sent a webhooks de n8n usando URLs desde la tabla app_settings según el tipo de remitente (agent/client) y el entorno (production/test). Usa la extensión HTTP en lugar de pg_net.';

-- Log the installation
DO $$
BEGIN
  RAISE NOTICE '
  La función de webhook ha sido modificada para usar la extensión HTTP en lugar de pg_net.
  
  Cambios clave:
  1. Se creó una función http_post que usa la extensión HTTP
  2. Se modificó la función notify_message_webhook para usar http_post
  3. Se recreó el trigger message_webhook_trigger
  4. Se agregó más logging para identificar problemas
  
  Los mensajes de agentes y clientes con estado "sent" ahora serán enviados a sus respectivos webhooks usando la extensión HTTP.
  ';
END;
$$;
