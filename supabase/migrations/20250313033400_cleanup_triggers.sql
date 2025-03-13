/*
  # Cleanup Triggers and Functions

  1. Purpose
    - Remove all triggers and functions related to webhook notifications
    - Start with a clean slate for a new implementation
    
  2. Notes
    - This is to ensure we don't have conflicting triggers
    - Will prepare the database for a clean implementation
*/

-- Drop the existing trigger if it exists
DROP TRIGGER IF EXISTS messages_new_agent_trigger ON messages;
DROP TRIGGER IF EXISTS messages_new_agent_sent_trigger ON messages;

-- Drop the function if it exists
DROP FUNCTION IF EXISTS notify_new_agent_sent_message();

-- Drop diagnostic functions
DROP FUNCTION IF EXISTS test_http_extension();
DROP FUNCTION IF EXISTS test_webhook_connection();
DROP FUNCTION IF EXISTS check_messages_table();
DROP FUNCTION IF EXISTS test_insert_message();

-- Drop the view if it exists
DROP VIEW IF EXISTS recent_messages;

-- Log the cleanup
DO $$
BEGIN
  RAISE NOTICE 'All webhook triggers and functions have been removed';
END;
$$;
