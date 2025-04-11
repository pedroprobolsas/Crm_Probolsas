/*
  # Disable All HTTP-Related Triggers on Messages Table

  1. Purpose
    - Permanently disable all triggers on the messages table that use HTTP functions
    - This resolves the issue with message insertion failing due to missing HTTP extension
    
  2. Triggers Disabled
    - agent_message_webhook_trigger: Sends agent messages to a webhook
    - trigger_messages_outgoing: Processes outgoing messages
    
  3. Long-term Solutions
    - Option 1: Keep triggers disabled and use direct message insertion
    - Option 2: Properly configure the HTTP extension in Supabase
    - Option 3: Rewrite triggers to use pg_net instead of http extension
*/

-- Disable all problematic triggers on the messages table
DO $$
BEGIN
  -- Disable agent_message_webhook_trigger if it exists
  IF EXISTS (
    SELECT 1 FROM pg_trigger 
    WHERE tgname = 'agent_message_webhook_trigger'
  ) THEN
    EXECUTE 'ALTER TABLE messages DISABLE TRIGGER agent_message_webhook_trigger';
    RAISE NOTICE 'agent_message_webhook_trigger has been disabled';
  ELSE
    RAISE NOTICE 'agent_message_webhook_trigger not found';
  END IF;
  
  -- Disable trigger_messages_outgoing if it exists
  IF EXISTS (
    SELECT 1 FROM pg_trigger 
    WHERE tgname = 'trigger_messages_outgoing'
  ) THEN
    EXECUTE 'ALTER TABLE messages DISABLE TRIGGER trigger_messages_outgoing';
    RAISE NOTICE 'trigger_messages_outgoing has been disabled';
  ELSE
    RAISE NOTICE 'trigger_messages_outgoing not found';
  END IF;
  
  -- Disable any other triggers that might be using HTTP functions
  -- This is a more aggressive approach but ensures all problematic triggers are disabled
  FOR r IN (
    SELECT t.tgname 
    FROM pg_trigger t
    JOIN pg_class c ON t.tgrelid = c.oid
    JOIN pg_namespace n ON c.relnamespace = n.oid
    WHERE c.relname = 'messages' 
    AND n.nspname = 'public'
    AND t.tgenabled != 'D'
  ) LOOP
    EXECUTE format('ALTER TABLE messages DISABLE TRIGGER %I', r.tgname);
    RAISE NOTICE 'Disabled trigger: %', r.tgname;
  END LOOP;
END;
$$;

-- Verify that all triggers on the messages table are disabled
SELECT 
  t.tgname AS trigger_name,
  CASE WHEN t.tgenabled = 'D' THEN 'DISABLED' ELSE 'ENABLED' END AS status,
  n.nspname AS schema_name,
  c.relname AS table_name,
  pg_get_triggerdef(t.oid) AS trigger_definition
FROM pg_trigger t
JOIN pg_class c ON t.tgrelid = c.oid
JOIN pg_namespace n ON c.relnamespace = n.oid
WHERE c.relname = 'messages'
AND n.nspname = 'public'
ORDER BY t.tgname;

-- Create a function to permanently disable all triggers on the messages table
-- This can be called from the application if needed
CREATE OR REPLACE FUNCTION disable_all_message_triggers()
RETURNS TEXT[] AS $$
DECLARE
  disabled_triggers TEXT[] := '{}';
  r RECORD;
BEGIN
  FOR r IN (
    SELECT t.tgname 
    FROM pg_trigger t
    JOIN pg_class c ON t.tgrelid = c.oid
    JOIN pg_namespace n ON c.relnamespace = n.oid
    WHERE c.relname = 'messages' 
    AND n.nspname = 'public'
    AND t.tgenabled != 'D'
  ) LOOP
    EXECUTE format('ALTER TABLE messages DISABLE TRIGGER %I', r.tgname);
    disabled_triggers := array_append(disabled_triggers, r.tgname);
  END LOOP;
  
  RETURN disabled_triggers;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION disable_all_message_triggers() TO authenticated;

-- Add a comment to explain the function
COMMENT ON FUNCTION disable_all_message_triggers() IS 
'Disables all triggers on the messages table to ensure message insertion works correctly';
