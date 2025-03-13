/*
  # Run Diagnostic Functions

  1. Purpose
    - Execute the diagnostic functions created earlier
    - Log the results for analysis
    
  2. Notes
    - This will help identify the root cause of the issue
    - Results will be logged to the Supabase logs
*/

-- Run the diagnostic functions and log the results
DO $$
DECLARE
  http_test_result TEXT;
  webhook_test_result TEXT;
  table_check_result TEXT;
  insert_test_result TEXT;
BEGIN
  -- Test HTTP extension
  SELECT test_http_extension() INTO http_test_result;
  RAISE LOG 'HTTP Extension Test: %', http_test_result;
  
  -- Test webhook connection
  SELECT test_webhook_connection() INTO webhook_test_result;
  RAISE LOG 'Webhook Connection Test: %', webhook_test_result;
  
  -- Check messages table
  SELECT check_messages_table() INTO table_check_result;
  RAISE LOG 'Messages Table Check: %', table_check_result;
  
  -- Test message insertion
  SELECT test_insert_message() INTO insert_test_result;
  RAISE LOG 'Message Insertion Test: %', insert_test_result;
  
  -- Log overall summary
  RAISE LOG 'Diagnostic Summary:';
  RAISE LOG '- HTTP Extension: %', http_test_result;
  RAISE LOG '- Webhook Connection: %', webhook_test_result;
  RAISE LOG '- Messages Table: %', table_check_result;
  RAISE LOG '- Message Insertion: %', insert_test_result;
END;
$$;

-- Create a view to see the most recent messages for debugging
CREATE OR REPLACE VIEW recent_messages AS
SELECT 
  id,
  conversation_id,
  content,
  sender,
  sender_id,
  type,
  status,
  created_at,
  updated_at
FROM messages
ORDER BY created_at DESC
LIMIT 50;

-- Grant access to the view
GRANT SELECT ON recent_messages TO authenticated;
