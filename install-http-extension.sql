/*
  # Install and Configure HTTP Extension for Supabase

  1. Purpose
    - Properly install and configure the HTTP extension in Supabase
    - Fix the webhook triggers that are failing due to missing HTTP functions
    
  2. Steps
    - Install the HTTP extension if not already installed
    - Create wrapper functions for HTTP operations
    - Re-enable the triggers that were disabled
    
  3. Notes
    - This script requires superuser privileges to run
    - It should be executed by a Supabase administrator
    - After running this script, the webhook triggers should work correctly
*/

-- Check if the HTTP extension is already installed
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM pg_extension WHERE extname = 'http'
  ) THEN
    RAISE NOTICE 'HTTP extension is already installed';
  ELSE
    RAISE NOTICE 'HTTP extension is not installed. Attempting to install...';
    -- This requires superuser privileges
    CREATE EXTENSION http;
    RAISE NOTICE 'HTTP extension installed successfully';
  END IF;
END;
$$;

-- Check if the pg_net extension is already installed
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM pg_extension WHERE extname = 'pg_net'
  ) THEN
    RAISE NOTICE 'pg_net extension is already installed';
  ELSE
    RAISE NOTICE 'pg_net extension is not installed. Attempting to install...';
    -- This requires superuser privileges
    CREATE EXTENSION pg_net;
    RAISE NOTICE 'pg_net extension installed successfully';
  END IF;
END;
$$;

-- Create wrapper functions for HTTP operations
-- These functions provide a consistent interface regardless of which extension is used

-- HTTP POST function that works with both http and pg_net extensions
CREATE OR REPLACE FUNCTION http_post(
  url TEXT,
  body TEXT DEFAULT NULL,
  headers JSONB DEFAULT '{}'::jsonb
)
RETURNS JSONB AS $$
DECLARE
  result JSONB;
BEGIN
  -- Check if the http extension is available
  IF EXISTS (
    SELECT 1 FROM pg_proc 
    WHERE proname = 'http' 
    AND pronargs = 3
    AND proargtypes::text LIKE '%text%text%jsonb%'
  ) THEN
    -- Use the http extension
    SELECT content::jsonb INTO result
    FROM http((
      'POST',
      url,
      headers,
      'application/json',
      body
    )::http_request);
    
    RETURN result;
  -- Check if pg_net is available
  ELSIF EXISTS (
    SELECT 1 FROM pg_proc 
    WHERE proname = 'http_post' 
    AND pronsp = (SELECT oid FROM pg_namespace WHERE nspname = 'net')
  ) THEN
    -- Use pg_net extension
    RETURN jsonb_build_object(
      'request_id', net.http_post(
        url := url,
        body := body,
        headers := headers
      )
    );
  ELSE
    -- Neither extension is properly available
    RAISE EXCEPTION 'Neither http nor pg_net extension is properly configured';
  END IF;
EXCEPTION WHEN OTHERS THEN
  -- Log the error and return it as part of the result
  RETURN jsonb_build_object(
    'error', SQLERRM,
    'detail', SQLSTATE
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION http_post(TEXT, TEXT, JSONB) TO authenticated;

-- Add a comment to explain the function
COMMENT ON FUNCTION http_post(TEXT, TEXT, JSONB) IS 
'A wrapper function that provides HTTP POST functionality using either the http or pg_net extension';

-- Re-enable the triggers that were disabled
DO $$
BEGIN
  -- Re-enable agent_message_webhook_trigger if it exists
  IF EXISTS (
    SELECT 1 FROM pg_trigger 
    WHERE tgname = 'agent_message_webhook_trigger'
  ) THEN
    EXECUTE 'ALTER TABLE messages ENABLE TRIGGER agent_message_webhook_trigger';
    RAISE NOTICE 'agent_message_webhook_trigger has been re-enabled';
  END IF;
  
  -- Re-enable trigger_messages_outgoing if it exists
  IF EXISTS (
    SELECT 1 FROM pg_trigger 
    WHERE tgname = 'trigger_messages_outgoing'
  ) THEN
    EXECUTE 'ALTER TABLE messages ENABLE TRIGGER trigger_messages_outgoing';
    RAISE NOTICE 'trigger_messages_outgoing has been re-enabled';
  END IF;
END;
$$;

-- Verify that the triggers are enabled
SELECT 
  t.tgname AS trigger_name,
  CASE WHEN t.tgenabled = 'D' THEN 'DISABLED' ELSE 'ENABLED' END AS status,
  n.nspname AS schema_name,
  c.relname AS table_name
FROM pg_trigger t
JOIN pg_class c ON t.tgrelid = c.oid
JOIN pg_namespace n ON c.relnamespace = n.oid
WHERE c.relname = 'messages'
AND n.nspname = 'public'
ORDER BY t.tgname;

-- Test the HTTP POST function
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
