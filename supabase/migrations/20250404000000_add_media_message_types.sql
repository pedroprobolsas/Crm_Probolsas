/*
  # Add Media Message Types

  1. Purpose
    - Add support for audio and pdf message types
    - Update the type column to support the new message types
    - Add a check constraint to ensure valid message types
    
  2. Notes
    - This migration adds support for multimedia messages in the chat system
    - The existing message types are: 'text', 'image', 'file'
    - The new message types are: 'audio', 'pdf'
*/

-- First, drop any existing check constraint on the type column
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM pg_constraint 
    WHERE conname = 'messages_type_check' 
    AND conrelid = 'messages'::regclass
  ) THEN
    EXECUTE 'ALTER TABLE messages DROP CONSTRAINT messages_type_check';
  END IF;
END
$$;

-- Add a new check constraint with the updated message types
ALTER TABLE messages
ADD CONSTRAINT messages_type_check
CHECK (type IN ('text', 'image', 'file', 'audio', 'pdf'));

-- Add a comment to explain the message types
COMMENT ON COLUMN messages.type IS 'Message type: text, image, file, audio, pdf';

-- Create an index on the type column for faster filtering
CREATE INDEX IF NOT EXISTS idx_messages_type ON messages(type);

-- Log the migration
DO $$
BEGIN
  RAISE NOTICE 'Added support for audio and pdf message types';
END;
$$;
