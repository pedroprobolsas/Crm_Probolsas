/*
  # Check HTTP Extension and Create Test Function

  1. Purpose
    - Verify if the http extension is installed and working correctly
    - Create a test function to check if http calls can be made
    
  2. Notes
    - This is for debugging purposes
    - Will help determine if the http extension is the cause of the issue
*/

-- Check if http extension exists and create it if not
CREATE EXTENSION IF NOT EXISTS http;

-- Create a test function to verify http functionality
CREATE OR REPLACE FUNCTION test_http_extension()
RETURNS TEXT AS $$
DECLARE
  result TEXT;
  http_status INT;
BEGIN
  BEGIN
    SELECT 
      content::text,
      status_code
    INTO 
      result,
      http_status
    FROM http((
      'GET',
      'https://httpbin.org/get',
      NULL,
      NULL,
      5  -- timeout in seconds
    )::http_request);
    
    RETURN 'HTTP extension is working. Status: ' || http_status || ', Response length: ' || length(result);
  EXCEPTION WHEN OTHERS THEN
    RETURN 'Error testing HTTP extension: ' || SQLERRM;
  END;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create a function to check if the webhook URL is reachable
CREATE OR REPLACE FUNCTION test_webhook_connection()
RETURNS TEXT AS $$
DECLARE
  result TEXT;
  http_status INT;
  webhook_url TEXT := 'https://ippwebhookn8n.probolsas.co/webhook/a7c5e1b0-c8bc-4dd2-b0f0-fe263fa246cf';
BEGIN
  BEGIN
    SELECT 
      content::text,
      status_code
    INTO 
      result,
      http_status
    FROM http((
      'GET',
      webhook_url,
      NULL,
      NULL,
      5  -- timeout in seconds
    )::http_request);
    
    RETURN 'Webhook is reachable. Status: ' || http_status || ', Response length: ' || length(result);
  EXCEPTION WHEN OTHERS THEN
    RETURN 'Error connecting to webhook: ' || SQLERRM;
  END;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create a function to check if the messages table exists and has the right structure
CREATE OR REPLACE FUNCTION check_messages_table()
RETURNS TEXT AS $$
DECLARE
  table_exists BOOLEAN;
  column_count INT;
BEGIN
  -- Check if table exists
  SELECT EXISTS (
    SELECT FROM information_schema.tables 
    WHERE table_schema = 'public' 
    AND table_name = 'messages'
  ) INTO table_exists;
  
  IF NOT table_exists THEN
    RETURN 'Messages table does not exist';
  END IF;
  
  -- Check column count
  SELECT COUNT(*) 
  FROM information_schema.columns 
  WHERE table_schema = 'public' 
  AND table_name = 'messages'
  INTO column_count;
  
  RETURN 'Messages table exists with ' || column_count || ' columns';
END;
$$ LANGUAGE plpgsql;

-- Create a function to test message insertion directly
CREATE OR REPLACE FUNCTION test_insert_message()
RETURNS TEXT AS $$
DECLARE
  new_id UUID;
  conversation_exists BOOLEAN;
BEGIN
  -- Check if any conversation exists
  SELECT EXISTS (
    SELECT FROM conversations LIMIT 1
  ) INTO conversation_exists;
  
  IF NOT conversation_exists THEN
    RETURN 'No conversations exist to test with';
  END IF;
  
  -- Try to insert a test message
  BEGIN
    INSERT INTO messages (
      conversation_id,
      content,
      sender,
      sender_id,
      type,
      status
    )
    SELECT
      id,
      'Test message from diagnostic function',
      'agent',
      agent_id,
      'text',
      'sent'
    FROM conversations
    LIMIT 1
    RETURNING id INTO new_id;
    
    RETURN 'Successfully inserted test message with ID: ' || new_id;
  EXCEPTION WHEN OTHERS THEN
    RETURN 'Error inserting test message: ' || SQLERRM;
  END;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
