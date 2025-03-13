/*
  # Create Insert Message RPC Function

  1. Purpose
    - Create a stored procedure to insert messages directly via SQL
    - Bypass any potential issues with the Supabase client
    
  2. Notes
    - This is a direct SQL approach to inserting messages
*/

-- Create a function to insert a message directly via SQL
CREATE OR REPLACE FUNCTION insert_test_message(
  p_conversation_id UUID,
  p_content TEXT,
  p_sender TEXT,
  p_sender_id TEXT,
  p_type TEXT,
  p_status TEXT
)
RETURNS JSONB AS $$
DECLARE
  new_id UUID;
  result JSONB;
BEGIN
  -- Insert the message
  INSERT INTO messages (
    conversation_id,
    content,
    sender,
    sender_id,
    type,
    status
  )
  VALUES (
    p_conversation_id,
    p_content,
    p_sender,
    p_sender_id,
    p_type,
    p_status
  )
  RETURNING id INTO new_id;
  
  -- Get the inserted message
  SELECT jsonb_build_object(
    'id', m.id,
    'conversation_id', m.conversation_id,
    'content', m.content,
    'sender', m.sender,
    'sender_id', m.sender_id,
    'type', m.type,
    'status', m.status,
    'created_at', m.created_at,
    'updated_at', m.updated_at
  ) INTO result
  FROM messages m
  WHERE m.id = new_id;
  
  -- Return the result
  RETURN result;
EXCEPTION WHEN OTHERS THEN
  RAISE EXCEPTION 'Error inserting message: %', SQLERRM;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION insert_test_message TO authenticated;

-- Test the function
DO $$
DECLARE
  test_conversation_id UUID;
  test_result JSONB;
BEGIN
  -- Get a conversation ID to use for testing
  SELECT id INTO test_conversation_id FROM conversations LIMIT 1;
  
  IF test_conversation_id IS NULL THEN
    RAISE NOTICE 'No conversations found for testing';
    RETURN;
  END IF;
  
  -- Test the function
  SELECT insert_test_message(
    test_conversation_id,
    'Test message from RPC function',
    'agent',
    '00000000-0000-0000-0000-000000000000',
    'text',
    'sent'
  ) INTO test_result;
  
  RAISE NOTICE 'RPC function test result: %', test_result;
  
  -- Delete the test message
  DELETE FROM messages WHERE id = (test_result->>'id')::UUID;
END;
$$;
