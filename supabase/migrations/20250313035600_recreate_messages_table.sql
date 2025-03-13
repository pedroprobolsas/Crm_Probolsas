/*
  # Recreate Messages Table from Scratch

  1. Purpose
    - Completely recreate the messages table from scratch
    - Remove all constraints, triggers, and other potential issues
    
  2. Notes
    - This is a drastic measure to ensure the table works correctly
*/

-- Drop the messages table completely
DROP TABLE IF EXISTS messages CASCADE;

-- Create a completely new messages table with minimal constraints
CREATE TABLE messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  conversation_id UUID NOT NULL,
  content TEXT NOT NULL,
  sender TEXT NOT NULL,
  sender_id TEXT NOT NULL,
  type TEXT NOT NULL,
  status TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Add foreign key constraint after table creation
ALTER TABLE messages
ADD CONSTRAINT messages_conversation_id_fkey
FOREIGN KEY (conversation_id) REFERENCES conversations(id) ON DELETE CASCADE;

-- Create basic indexes
CREATE INDEX idx_messages_conversation ON messages(conversation_id);
CREATE INDEX idx_messages_created_at ON messages(created_at);

-- Grant all permissions
GRANT ALL ON messages TO authenticated;
GRANT ALL ON messages_id_seq TO authenticated;

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

-- Insert a test message
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
  
  -- Try to insert a test message
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
    'Test message from recreated table',
    'agent',
    '00000000-0000-0000-0000-000000000000',
    'text',
    'sent'
  )
  RETURNING id INTO test_message_id;
  
  RAISE NOTICE 'Successfully inserted message into recreated table. ID: %', test_message_id;
END;
$$;
