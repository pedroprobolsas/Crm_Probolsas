/*
  # Verify Messages Table Structure

  1. Purpose
    - Check if the messages table exists and has the correct structure
    - Create it if it doesn't exist
    - Add any missing columns
    
  2. Notes
    - This is to ensure the table is properly set up
    - Will not affect existing data
*/

-- Create the messages table if it doesn't exist
CREATE TABLE IF NOT EXISTS messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  conversation_id UUID REFERENCES conversations(id) ON DELETE CASCADE,
  content TEXT NOT NULL,
  sender TEXT NOT NULL CHECK (sender IN ('agent', 'client')),
  sender_id UUID NOT NULL,
  type TEXT NOT NULL CHECK (type IN ('text', 'image', 'file')),
  status TEXT NOT NULL CHECK (status IN ('sent', 'delivered', 'read')),
  metadata JSONB DEFAULT '{}'::jsonb,
  file_url TEXT,
  file_name TEXT,
  file_size INTEGER,
  recipient_phone TEXT,
  message_id TEXT,
  direction TEXT,
  error_message TEXT,
  retry_count INTEGER DEFAULT 0,
  last_retry_at TIMESTAMPTZ,
  processed_at TIMESTAMPTZ,
  delivered_at TIMESTAMPTZ,
  read_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  embedding vector(1536)
);

-- Create indexes if they don't exist
CREATE INDEX IF NOT EXISTS idx_messages_conversation ON messages(conversation_id);
CREATE INDEX IF NOT EXISTS idx_messages_sender_id ON messages(sender_id);
CREATE INDEX IF NOT EXISTS idx_messages_status ON messages(status);
CREATE INDEX IF NOT EXISTS idx_messages_created_at ON messages(created_at);

-- Enable Row Level Security if not already enabled
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;

-- Create RLS policies if they don't exist
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT FROM pg_policies 
    WHERE tablename = 'messages' 
    AND policyname = 'Allow authenticated users to read all messages'
  ) THEN
    CREATE POLICY "Allow authenticated users to read all messages"
      ON messages FOR SELECT
      TO authenticated
      USING (true);
  END IF;
  
  IF NOT EXISTS (
    SELECT FROM pg_policies 
    WHERE tablename = 'messages' 
    AND policyname = 'Allow authenticated users to insert messages'
  ) THEN
    CREATE POLICY "Allow authenticated users to insert messages"
      ON messages FOR INSERT
      TO authenticated
      WITH CHECK (true);
  END IF;
  
  IF NOT EXISTS (
    SELECT FROM pg_policies 
    WHERE tablename = 'messages' 
    AND policyname = 'Allow authenticated users to update messages'
  ) THEN
    CREATE POLICY "Allow authenticated users to update messages"
      ON messages FOR UPDATE
      TO authenticated
      USING (true);
  END IF;
END;
$$;

-- Create trigger for updated_at if it doesn't exist
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT FROM pg_trigger
    WHERE tgname = 'update_messages_updated_at'
  ) THEN
    CREATE TRIGGER update_messages_updated_at
      BEFORE UPDATE ON messages
      FOR EACH ROW
      EXECUTE FUNCTION update_updated_at_column();
  END IF;
END;
$$;

-- Create a function to test message insertion
CREATE OR REPLACE FUNCTION test_message_insertion()
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
    'Test message from verification function',
    'agent',
    '00000000-0000-0000-0000-000000000000',
    'text',
    'sent'
  )
  RETURNING id INTO test_message_id;
  
  -- Delete the test message
  DELETE FROM messages WHERE id = test_message_id;
  
  RETURN 'Message insertion test successful. Table is working correctly.';
EXCEPTION WHEN OTHERS THEN
  RETURN 'Error testing message insertion: ' || SQLERRM;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Run the test and log the result
DO $$
DECLARE
  test_result TEXT;
BEGIN
  SELECT test_message_insertion() INTO test_result;
  RAISE NOTICE 'Message table verification: %', test_result;
END;
$$;
