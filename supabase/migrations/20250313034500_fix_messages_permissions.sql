/*
  # Fix Messages Table Permissions

  1. Purpose
    - Ensure proper permissions are set on the messages table
    - Grant all necessary permissions to authenticated users
    
  2. Notes
    - This is to fix any permission issues that might be preventing message insertion
*/

-- Grant all permissions on messages table to authenticated users
GRANT ALL ON messages TO authenticated;

-- Grant usage on the sequence if it exists
DO $$
DECLARE
  seq_name TEXT;
BEGIN
  SELECT pg_get_serial_sequence('messages', 'id') INTO seq_name;
  IF seq_name IS NOT NULL THEN
    EXECUTE 'GRANT USAGE, SELECT ON SEQUENCE ' || seq_name || ' TO authenticated';
  END IF;
END;
$$;

-- Ensure RLS is enabled but not blocking inserts
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;

-- Drop existing policies to recreate them
DROP POLICY IF EXISTS "Allow authenticated users to read all messages" ON messages;
DROP POLICY IF EXISTS "Allow authenticated users to insert messages" ON messages;
DROP POLICY IF EXISTS "Allow authenticated users to update messages" ON messages;

-- Create permissive policies
CREATE POLICY "Allow authenticated users to read all messages"
  ON messages FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Allow authenticated users to insert messages"
  ON messages FOR INSERT
  TO authenticated
  WITH CHECK (true);

CREATE POLICY "Allow authenticated users to update messages"
  ON messages FOR UPDATE
  TO authenticated
  USING (true);

-- Create a test function to directly insert a message using SQL
CREATE OR REPLACE FUNCTION test_direct_message_insert()
RETURNS TEXT AS $$
DECLARE
  test_conversation_id UUID;
  test_message_id UUID;
BEGIN
  -- Get a conversation ID to use for testing
  SELECT id INTO test_conversation_id FROM conversations LIMIT 1;
  
  IF test_conversation_id IS NULL THEN
    RETURN 'No conversations found for testing';
  END IF;
  
  -- Try to insert a test message directly with SQL
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
    'Test message from direct SQL insert',
    'agent',
    '00000000-0000-0000-0000-000000000000',
    'text',
    'sent'
  )
  RETURNING id INTO test_message_id;
  
  -- Delete the test message
  DELETE FROM messages WHERE id = test_message_id;
  
  RETURN 'Direct SQL message insertion test successful. ID: ' || test_message_id;
EXCEPTION WHEN OTHERS THEN
  RETURN 'Error in direct SQL message insertion: ' || SQLERRM;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Run the test and log the result
DO $$
DECLARE
  test_result TEXT;
BEGIN
  SELECT test_direct_message_insert() INTO test_result;
  RAISE NOTICE 'Direct SQL message insertion test: %', test_result;
END;
$$;
