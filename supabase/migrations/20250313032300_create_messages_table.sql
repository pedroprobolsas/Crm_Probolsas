/*
  # Create Messages Table for Chat Functionality

  1. New Table
    - messages: Stores chat messages between agents and clients
    
  2. Fields
    - Standard fields (id, created_at, updated_at)
    - conversation_id: Reference to conversations table
    - content: The message text
    - sender: Either 'agent' or 'client'
    - sender_id: ID of the sender (agent_id or client_id)
    - type: Message type ('text', 'image', 'file')
    - status: Message status ('sent', 'delivered', 'read')
    - Additional fields for metadata, files, and delivery tracking
    
  3. Security
    - Enable RLS on the table
    - Add policies for authenticated users
    
  4. Indexes
    - Added indexes for frequently queried columns
*/

-- Create Messages table
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

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_messages_conversation ON messages(conversation_id);
CREATE INDEX IF NOT EXISTS idx_messages_sender_id ON messages(sender_id);
CREATE INDEX IF NOT EXISTS idx_messages_status ON messages(status);
CREATE INDEX IF NOT EXISTS idx_messages_created_at ON messages(created_at);

-- Enable Row Level Security
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;

-- RLS Policies
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

-- Trigger for updated_at
CREATE TRIGGER update_messages_updated_at
    BEFORE UPDATE ON messages
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Function to update conversation last_message when a new message is inserted
CREATE OR REPLACE FUNCTION update_conversation_last_message()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE conversations
  SET 
    last_message = NEW.content,
    last_message_at = NEW.created_at,
    updated_at = NOW()
  WHERE id = NEW.conversation_id;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for updating conversation last_message
CREATE TRIGGER update_conversation_last_message_trigger
  AFTER INSERT ON messages
  FOR EACH ROW
  EXECUTE FUNCTION update_conversation_last_message();
