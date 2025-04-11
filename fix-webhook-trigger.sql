/*
  # Fix Webhook Trigger for Agent Messages

  1. Purpose
    - Re-enable the webhook trigger for agent messages
    - Ensure the HTTP extension is used correctly
    - Maintain chat functionality while enabling webhook notifications
    
  2. Steps
    - Verify HTTP extension is installed and available
    - Create or update the http_post function to work correctly
    - Fix the notify_agent_message_webhook function
    - Re-enable the agent_message_webhook_trigger
    
  3. Notes
    - This script assumes the HTTP extension is already installed (version 1.6)
    - The trigger will be modified to handle errors gracefully without blocking message insertion
*/

-- Step 1: Verify HTTP extension is installed and available
DO $$
DECLARE
  http_version TEXT;
BEGIN
  SELECT extversion INTO http_version FROM pg_extension WHERE extname = 'http';
  
  IF http_version IS NULL THEN
    RAISE EXCEPTION 'HTTP extension is not installed. Please install it first.';
  ELSE
    RAISE NOTICE 'HTTP extension is installed (version %)', http_version;
  END IF;
END;
$$;

-- Step 2: Create or update the http_post function to work correctly with the installed HTTP extension
CREATE OR REPLACE FUNCTION http_post(
  url TEXT,
  body TEXT,
  headers JSONB
)
RETURNS JSONB AS $$
DECLARE
  result JSONB;
BEGIN
  -- Use the http extension to make the POST request
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
  -- Log the error but don't fail
  RAISE WARNING 'HTTP POST request failed: %. URL: %, Body: %', SQLERRM, url, body;
  
  -- Return error information as JSON
  RETURN jsonb_build_object(
    'error', SQLERRM,
    'detail', SQLSTATE,
    'url', url
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION http_post(TEXT, TEXT, JSONB) TO authenticated;

-- Add a comment to explain the function
COMMENT ON FUNCTION http_post(TEXT, TEXT, JSONB) IS 
'A wrapper function for HTTP POST requests that handles errors gracefully';

-- Step 3: Fix the notify_agent_message_webhook function to use the http_post function correctly
-- and to handle errors gracefully without blocking message insertion
CREATE OR REPLACE FUNCTION notify_agent_message_webhook()
RETURNS TRIGGER AS $$
DECLARE
  payload JSONB;
  webhook_url TEXT;
  is_production BOOLEAN;
  http_result JSONB;
BEGIN
  -- Only proceed if conditions are met
  IF (NEW.sender = 'agent' AND NEW.status = 'sent') THEN
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
      
      -- Use the http_post function to send the request
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
  END IF;
  
  -- Always return NEW to ensure the trigger doesn't interfere with the operation
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Step 4: Re-enable the agent_message_webhook_trigger
DO $$
BEGIN
  -- Check if the trigger exists
  IF EXISTS (
    SELECT 1 FROM pg_trigger 
    WHERE tgname = 'agent_message_webhook_trigger'
  ) THEN
    -- Re-enable the trigger
    EXECUTE 'ALTER TABLE messages ENABLE TRIGGER agent_message_webhook_trigger';
    RAISE NOTICE 'agent_message_webhook_trigger has been re-enabled';
  ELSE
    -- Create the trigger if it doesn't exist
    EXECUTE '
      CREATE TRIGGER agent_message_webhook_trigger
      AFTER INSERT ON messages
      FOR EACH ROW
      EXECUTE FUNCTION notify_agent_message_webhook()
    ';
    RAISE NOTICE 'agent_message_webhook_trigger has been created';
  END IF;
END;
$$;

-- Step 5: Verify that the trigger is enabled
SELECT 
  t.tgname AS trigger_name,
  CASE WHEN t.tgenabled = 'D' THEN 'DISABLED' ELSE 'ENABLED' END AS status,
  n.nspname AS schema_name,
  c.relname AS table_name,
  pg_get_triggerdef(t.oid) AS trigger_definition
FROM pg_trigger t
JOIN pg_class c ON t.tgrelid = c.oid
JOIN pg_namespace n ON c.relnamespace = n.oid
WHERE t.tgname = 'agent_message_webhook_trigger';

-- Step 6: Test the http_post function
DO $$
BEGIN
  RAISE NOTICE 'Testing HTTP POST function...';
  PERFORM http_post(
    'https://httpbin.org/post',
    '{"test": "data"}',
    '{"Content-Type": "application/json"}'::jsonb
  );
  RAISE NOTICE 'HTTP POST function test completed';
END;
$$;

-- Step 7: Add a note about the changes
DO $$
BEGIN
  RAISE NOTICE '
  The webhook trigger has been fixed and re-enabled.
  
  Key changes:
  1. Created a robust http_post function that handles errors gracefully
  2. Updated the notify_agent_message_webhook function to use the http_post function correctly
  3. Re-enabled the agent_message_webhook_trigger
  
  Messages will now be sent to the webhook while maintaining chat functionality.
  ';
END;
$$;
