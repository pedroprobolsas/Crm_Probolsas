/*
  # Remove All Triggers

  1. Purpose
    - Remove ALL triggers from the messages table
    - Start with a completely clean slate
    
  2. Notes
    - This is a drastic measure to ensure no triggers are interfering with message insertion
*/

-- Drop ALL triggers on the messages table
DO $$
DECLARE
    trigger_record RECORD;
BEGIN
    FOR trigger_record IN 
        SELECT tgname 
        FROM pg_trigger 
        WHERE tgrelid = 'messages'::regclass
    LOOP
        EXECUTE 'DROP TRIGGER IF EXISTS ' || trigger_record.tgname || ' ON messages';
        RAISE NOTICE 'Dropped trigger: %', trigger_record.tgname;
    END LOOP;
END;
$$;

-- Drop ALL functions related to message triggers
DROP FUNCTION IF EXISTS notify_new_agent_sent_message();
DROP FUNCTION IF EXISTS notify_agent_message_webhook();
DROP FUNCTION IF EXISTS update_conversation_last_message();

-- Log the cleanup
DO $$
BEGIN
  RAISE NOTICE 'All triggers and related functions have been removed from the messages table';
END;
$$;

-- Create a simple view for monitoring recent messages
CREATE OR REPLACE VIEW recent_messages AS
SELECT 
  id,
  conversation_id,
  content,
  sender,
  sender_id,
  type,
  status,
  created_at
FROM messages
ORDER BY created_at DESC
LIMIT 20;

-- Grant access to the view
GRANT SELECT ON recent_messages TO authenticated;
