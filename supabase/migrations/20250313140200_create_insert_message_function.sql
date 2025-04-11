/*
  # Create Function to Insert Messages Directly

  1. Purpose
    - Create a SQL function that can be called from the application to insert messages directly
    - This provides a fallback method if the regular insert fails due to trigger issues
    
  2. Usage
    - Call this function from the application code: 
      await supabase.rpc('insert_message', {
        p_conversation_id: conversationId,
        p_content: 'Message content',
        p_sender: 'agent',
        p_sender_id: userId,
        p_type: 'text',
        p_status: 'sent'
      })
*/

-- Create a function to insert messages directly
CREATE OR REPLACE FUNCTION insert_message(
  p_conversation_id UUID,
  p_content TEXT,
  p_sender TEXT,
  p_sender_id TEXT,
  p_type TEXT,
  p_status TEXT
)
RETURNS JSONB AS $$
DECLARE
  new_message_id UUID;
  result JSONB;
BEGIN
  -- Insert the message directly
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
  RETURNING id INTO new_message_id;
  
  -- Return the result
  SELECT jsonb_build_object(
    'id', id,
    'conversation_id', conversation_id,
    'content', content,
    'sender', sender,
    'sender_id', sender_id,
    'type', type,
    'status', status,
    'created_at', created_at
  ) INTO result
  FROM messages
  WHERE id = new_message_id;
  
  RETURN result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION insert_message(UUID, TEXT, TEXT, TEXT, TEXT, TEXT) TO authenticated;

-- Add a comment to explain the function
COMMENT ON FUNCTION insert_message(UUID, TEXT, TEXT, TEXT, TEXT, TEXT) IS 
'Inserts a message directly into the messages table, bypassing any triggers that might cause issues';
