/*
  # Actualización del Webhook para Mensajes de Clientes y Agentes

  1. Propósito
    - Modificar la función de webhook existente para procesar tanto mensajes de agentes como de clientes
    - Agregar nuevas entradas en app_settings para las URLs de webhook para clientes
    - Actualizar el trigger para usar la función modificada
    
  2. Características
    - Detecta automáticamente si el mensaje viene de un agente o un cliente
    - Usa URLs diferentes según el tipo de remitente y el entorno (producción/pruebas)
    - Para mensajes de clientes, incluye información adicional del cliente en el payload
    - Mantiene el manejo de errores y logging existente
    
  3. Funciones de Gestión Actualizadas
    - update_webhook_urls: Actualizada para manejar las nuevas URLs
    - get_webhook_urls: Actualizada para devolver las URLs para ambos tipos de remitentes
*/

-- Insertar las nuevas URLs para mensajes de clientes
INSERT INTO app_settings (key, value, description) VALUES
('webhook_url_client_production', 'https://ippwebhookn8n.probolsas.co/webhook/d2d918c0-7132-43fe-9e8c-e07b033f2e6b', 'URL del webhook para mensajes de clientes en producción'),
('webhook_url_client_test', 'https://ippn8n.probolsas.co/webhook-test/d2d918c0-7132-43fe-9e8c-e07b033f2e6b', 'URL del webhook para mensajes de clientes en entorno de pruebas')
ON CONFLICT (key) DO UPDATE 
SET value = EXCLUDED.value,
    description = EXCLUDED.description,
    updated_at = now();

-- Renombrar y modificar la función para procesar mensajes de agentes y clientes
CREATE OR REPLACE FUNCTION notify_message_webhook()
RETURNS TRIGGER AS $$
DECLARE
  payload JSONB;
  webhook_url TEXT;
  is_production BOOLEAN;
  client_info JSONB := NULL;
  client_record RECORD;
BEGIN
  -- Get environment configuration from app_settings table
  SELECT (value = 'true') INTO is_production 
  FROM app_settings 
  WHERE key = 'is_production_environment';
  
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
        END IF;
      END IF;
      
      -- Log the attempt
      RAISE LOG 'Sending % message to webhook: %, URL: %', NEW.sender, NEW.id, webhook_url;
      
      -- Use pg_net to send the request
      BEGIN
        PERFORM net.http_post(
          url := webhook_url,
          body := payload::text,
          headers := jsonb_build_object('Content-Type', 'application/json')
        );
        
        -- Log that we initiated the request
        RAISE LOG 'Webhook request initiated for % message ID: %', NEW.sender, NEW.id;
      EXCEPTION WHEN OTHERS THEN
        -- Log error but don't affect the transaction
        RAISE WARNING 'Error sending to webhook: %. Message ID % was still saved.', SQLERRM, NEW.id;
      END;
    EXCEPTION WHEN OTHERS THEN
      -- Log any other errors but don't affect the transaction
      RAISE WARNING 'Error in webhook function: %. Message ID % was still saved.', SQLERRM, NEW.id;
    END;
  END IF;
  
  -- Always return NEW to ensure the trigger doesn't interfere with the operation
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Eliminar el trigger existente
DROP TRIGGER IF EXISTS agent_message_webhook_trigger ON messages;

-- Crear el nuevo trigger con el nombre actualizado
CREATE TRIGGER message_webhook_trigger
AFTER INSERT ON messages
FOR EACH ROW
EXECUTE FUNCTION notify_message_webhook();

-- Agregar un comentario para explicar el trigger
COMMENT ON TRIGGER message_webhook_trigger ON messages IS 
'Envía mensajes con status=sent a webhooks de n8n usando URLs desde la tabla app_settings según el tipo de remitente (agent/client) y el entorno (production/test). No bloqueará la inserción de mensajes si el webhook falla.';

-- Actualizar la función para actualizar URLs de webhook
CREATE OR REPLACE FUNCTION update_webhook_urls(
  agent_production_url TEXT DEFAULT NULL,
  agent_test_url TEXT DEFAULT NULL,
  client_production_url TEXT DEFAULT NULL,
  client_test_url TEXT DEFAULT NULL
)
RETURNS BOOLEAN AS $$
DECLARE
  success BOOLEAN := TRUE;
BEGIN
  -- Update agent production URL
  IF agent_production_url IS NOT NULL THEN
    success := success AND update_app_setting('webhook_url_production', agent_production_url);
  END IF;
  
  -- Update agent test URL
  IF agent_test_url IS NOT NULL THEN
    success := success AND update_app_setting('webhook_url_test', agent_test_url);
  END IF;
  
  -- Update client production URL
  IF client_production_url IS NOT NULL THEN
    success := success AND update_app_setting('webhook_url_client_production', client_production_url);
  END IF;
  
  -- Update client test URL
  IF client_test_url IS NOT NULL THEN
    success := success AND update_app_setting('webhook_url_client_test', client_test_url);
  END IF;
  
  RETURN success;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Eliminar la función existente antes de recrearla con un tipo de retorno diferente
DROP FUNCTION IF EXISTS get_webhook_urls();

-- Actualizar la función para obtener URLs de webhook
CREATE FUNCTION get_webhook_urls()
RETURNS TABLE (
  sender_type TEXT,
  environment TEXT,
  url TEXT
) AS $$
BEGIN
  RETURN QUERY
  SELECT 'agent', 'production', value FROM app_settings WHERE key = 'webhook_url_production'
  UNION ALL
  SELECT 'agent', 'test', value FROM app_settings WHERE key = 'webhook_url_test'
  UNION ALL
  SELECT 'client', 'production', value FROM app_settings WHERE key = 'webhook_url_client_production'
  UNION ALL
  SELECT 'client', 'test', value FROM app_settings WHERE key = 'webhook_url_client_test';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Log the installation
DO $$
BEGIN
  RAISE NOTICE '
  La función de webhook ha sido actualizada para procesar mensajes de agentes y clientes.
  
  Cambios clave:
  1. Se agregaron nuevas entradas en app_settings para las URLs de webhook para clientes
  2. Se renombró la función de notify_agent_message_webhook a notify_message_webhook
  3. Se modificó la función para procesar mensajes de agentes y clientes
  4. Se actualizó el trigger para usar la función renombrada
  5. Se actualizaron las funciones de gestión para manejar las nuevas URLs
  
  Los mensajes de agentes y clientes con estado "sent" ahora serán enviados a sus respectivos webhooks.
  ';
END;
$$;
