/*
  # Create Webhook Trigger for Messages Table

  1. Purpose
    - Create a trigger to send agent messages to a webhook
    - Only trigger for INSERT operations when status='sent' and sender='agent'
    - Create app_settings table to store configuration
    - Provide functions to manage webhook URLs and environment settings
    
  2. Features
    - Uses AFTER INSERT to never block message insertion
    - Only triggers for agent messages with status='sent'
    - Environment detection for different webhook URLs stored in app_settings table
    - Comprehensive error handling
    - Logs for debugging
    
  3. Management Functions
    - update_app_setting(setting_key TEXT, setting_value TEXT): Update any setting
    - set_environment_mode(production_mode BOOLEAN): Switch between production/test mode
    - update_webhook_urls(production_url TEXT, test_url TEXT): Update webhook URLs
    - get_webhook_urls(): Get current webhook URLs for both environments
    - get_environment_mode(): Check if currently in production mode
    
  4. Usage Examples
    - Switch to test environment: SELECT set_environment_mode(FALSE);
    - Switch to production: SELECT set_environment_mode(TRUE);
    - Update production webhook URL: SELECT update_webhook_urls('https://new-url.com/webhook', NULL);
    - Update test webhook URL: SELECT update_webhook_urls(NULL, 'https://test-url.com/webhook');
    - Update both URLs: SELECT update_webhook_urls('https://prod-url.com/webhook', 'https://test-url.com/webhook');
    - Get current URLs: SELECT * FROM get_webhook_urls();
    - Check current environment: SELECT get_environment_mode();
*/

-- Ensure required extensions are available
CREATE EXTENSION IF NOT EXISTS http;
CREATE EXTENSION IF NOT EXISTS pg_net;

-- Create app_settings table to store configuration
CREATE TABLE IF NOT EXISTS app_settings (
    key TEXT PRIMARY KEY,
    value TEXT NOT NULL,
    description TEXT,
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- Insert initial webhook URL configurations
INSERT INTO app_settings (key, value, description) VALUES
('webhook_url_production', 'https://ippwebhookn8n.probolsas.co/webhook/text-crm-probolsas', 'URL del webhook para mensajes en producción'),
('webhook_url_test', 'https://ippn8n.probolsas.co/webhook-test/text-crm-probolsas', 'URL del webhook para mensajes en entorno de pruebas'),
('is_production_environment', 'true', 'Indica si el entorno actual es producción (true) o pruebas (false)')
ON CONFLICT (key) DO UPDATE 
SET value = EXCLUDED.value,
    description = EXCLUDED.description,
    updated_at = now();

-- Create function to update app settings
CREATE OR REPLACE FUNCTION update_app_setting(setting_key TEXT, setting_value TEXT)
RETURNS BOOLEAN AS $$
BEGIN
  UPDATE app_settings 
  SET value = setting_value, 
      updated_at = now() 
  WHERE key = setting_key;
  
  IF FOUND THEN
    RETURN TRUE;
  ELSE
    RETURN FALSE;
  END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create function to change environment mode
CREATE OR REPLACE FUNCTION set_environment_mode(production_mode BOOLEAN)
RETURNS BOOLEAN AS $$
BEGIN
  RETURN update_app_setting('is_production_environment', CASE WHEN production_mode THEN 'true' ELSE 'false' END);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create function to update webhook URLs
CREATE OR REPLACE FUNCTION update_webhook_urls(production_url TEXT, test_url TEXT)
RETURNS BOOLEAN AS $$
DECLARE
  success BOOLEAN := TRUE;
BEGIN
  -- Update production URL
  IF production_url IS NOT NULL THEN
    success := success AND update_app_setting('webhook_url_production', production_url);
  END IF;
  
  -- Update test URL
  IF test_url IS NOT NULL THEN
    success := success AND update_app_setting('webhook_url_test', test_url);
  END IF;
  
  RETURN success;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create function to get current webhook URLs
CREATE OR REPLACE FUNCTION get_webhook_urls()
RETURNS TABLE (
  environment TEXT,
  url TEXT
) AS $$
BEGIN
  RETURN QUERY
  SELECT 'production', value FROM app_settings WHERE key = 'webhook_url_production'
  UNION ALL
  SELECT 'test', value FROM app_settings WHERE key = 'webhook_url_test';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create function to get current environment mode
CREATE OR REPLACE FUNCTION get_environment_mode()
RETURNS BOOLEAN AS $$
DECLARE
  is_production BOOLEAN;
BEGIN
  SELECT (value = 'true') INTO is_production 
  FROM app_settings 
  WHERE key = 'is_production_environment';
  
  RETURN is_production;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create the webhook notification function
CREATE OR REPLACE FUNCTION notify_agent_message_webhook()
RETURNS TRIGGER AS $$
DECLARE
  payload JSONB;
  webhook_url TEXT;
  is_production BOOLEAN;
BEGIN
  -- Get environment configuration from app_settings table
  SELECT (value = 'true') INTO is_production 
  FROM app_settings 
  WHERE key = 'is_production_environment';
  
  -- Select the correct URL based on the environment
  IF is_production THEN
    SELECT value INTO webhook_url 
    FROM app_settings 
    WHERE key = 'webhook_url_production';
  ELSE
    SELECT value INTO webhook_url 
    FROM app_settings 
    WHERE key = 'webhook_url_test';
  END IF;
  -- Only proceed if conditions are met
  IF (NEW.sender = 'agent' AND NEW.status = 'sent') THEN
    BEGIN
      -- Create the payload
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
      
      -- Log the attempt
      RAISE LOG 'Sending agent message to webhook: %, URL: %', NEW.id, webhook_url;
      
      -- Simplified HTTP approach using pg_net extension
      BEGIN
        PERFORM net.http_post(
          url := webhook_url,
          body := payload::text,
          headers := jsonb_build_object('Content-Type', 'application/json')
        );
        
        -- Since pg_net is asynchronous, we won't have a status code or result
        -- Just log that we initiated the request
        RAISE LOG 'Webhook request initiated for message ID: %', NEW.id;
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

-- Create the trigger as AFTER INSERT to ensure it doesn't block insertion
CREATE TRIGGER agent_message_webhook_trigger
AFTER INSERT ON messages
FOR EACH ROW
EXECUTE FUNCTION notify_agent_message_webhook();

-- Add a comment to explain the trigger
COMMENT ON TRIGGER agent_message_webhook_trigger ON messages IS 
'Sends agent messages with status=sent to n8n webhook using URLs from app_settings table based on environment (production/test). Will not block message insertion if webhook fails.';

-- Log the installation
DO $$
BEGIN
  RAISE NOTICE 'Webhook trigger for agent messages created successfully';
END;
$$;
