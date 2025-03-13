/*
  # Fix Status Constraint

  1. Purpose
    - Fix the constraint on the status column in the messages table
    - Ensure it accepts 'sent' as a valid value
    
  2. Notes
    - The current constraint seems to be causing issues with message insertion
*/

-- Drop the existing check constraint on the status column
DO $$
DECLARE
  constraint_name TEXT;
BEGIN
  SELECT conname INTO constraint_name
  FROM pg_constraint 
  WHERE conrelid = 'messages'::regclass 
  AND conname LIKE '%status%';
  
  IF constraint_name IS NOT NULL THEN
    EXECUTE 'ALTER TABLE messages DROP CONSTRAINT ' || constraint_name;
    RAISE NOTICE 'Dropped constraint: %', constraint_name;
  ELSE
    RAISE NOTICE 'No constraint found on status column';
  END IF;
END;
$$;

-- Add a new check constraint that allows 'sent' as a valid value
ALTER TABLE messages 
ADD CONSTRAINT messages_status_check 
CHECK (status IN ('sending', 'sent', 'delivered', 'read'));

-- Update the default value for the status column
ALTER TABLE messages 
ALTER COLUMN status SET DEFAULT 'sent';

-- Test inserting a message with status='sent'
DO $$
DECLARE
  test_conversation_id UUID;
  test_message_id UUID;
BEGIN
  -- Get a conversation ID to use for testing
  SELECT id INTO test_conversation_id FROM conversations LIMIT 1;
  
  IF test_conversation_id IS NULL THEN
    RAISE NOTICE 'No conversations found for testing';
    RETURN;
  END IF;
  
  -- Try to insert a test message with status='sent'
  INSERT INTO messages (
    conversation_id,
    content,
    sender,
    sender_id,
    type,
    status
  )
  VALUES (
    test_conversation_id,
    'Test message with status=sent',
    'agent',
    '00000000-0000-0000-0000-000000000000',
    'text',
    'sent'
  )
  RETURNING id INTO test_message_id;
  
  RAISE NOTICE 'Successfully inserted message with status=sent. ID: %', test_message_id;
  
  -- Delete the test message
  DELETE FROM messages WHERE id = test_message_id;
END;
$$;
