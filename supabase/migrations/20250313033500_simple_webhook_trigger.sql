/*
  # Simple Webhook Trigger Implementation

  1. Purpose
    - Create a simple, reliable webhook trigger for agent messages
    - Ensure it never interferes with message insertion
    
  2. Features
    - Uses AFTER INSERT to never block message insertion
    - Only triggers for agent messages with status='sent'
    - Comprehensive error handling
    - Logs for debugging
*/

-- Create the webhook notification function
CREATE OR REPLACE FUNCTION notify_agent_message_webhook()
RETURNS TRIGGER AS $$
DECLARE
  payload JSONB;
  result JSONB;
  webhook_url TEXT := 'https://ippwebhookn8n.probolsas.co/webhook/a7c5e1b0-c8bc-4dd2-b0f0-fe263fa246cf';
  http_status INT;
BEGIN
  -- Only proceed if conditions are met
  IF (NEW.sender = 'agent' AND NEW.status = 'sent') THEN
    BEGIN
      -- Create the payload
      payload = jsonb_build_object(
        'id', NEW.id,
        'conversation_id', NEW.conversation_id,
        'content', NEW.content,
        'sender', NEW.sender,
        'sender_id', NEW.sender_id,
        'type', NEW.type,
        'status', NEW.status,
        'recipient_phone', NEW.recipient_phone,
        'message_id', NEW.message_id,
        'direction', NEW.direction,
        'metadata', NEW.metadata,
        'created_at', NEW.created_at
      );
      
      -- Log the attempt
      RAISE LOG 'Sending agent message to webhook: %', NEW.id;
      
      -- Try to send to webhook
      BEGIN
        SELECT 
          content::jsonb,
          status_code
        INTO 
          result,
          http_status
        FROM http((
          'POST',
          webhook_url,
          ARRAY[('Content-Type', 'application/json')],
          payload::text,
          5  -- timeout in seconds
        )::http_request);
        
        -- Log success
        RAISE LOG 'Successfully sent to webhook. Status: %, Message ID: %', http_status, NEW.id;
      EXCEPTION WHEN OTHERS THEN
        -- Log error but don't affect the transaction
        RAISE WARNING 'Error sending to webhook: %. Message ID % was still saved.', SQLERRM, NEW.id;
      END;
    EXCEPTION WHEN OTHERS THEN
      -- Log any other errors but don't affect the transaction
      RAISE WARNING 'Error in webhook function: %. Message ID % was still saved.', SQLERRM, NEW.id;
    END;
  END IF;
  
  -- Always return NEW to ensure the trigger doesn't interfere with the operation
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create the trigger as AFTER INSERT to ensure it doesn't block insertion
CREATE TRIGGER agent_message_webhook_trigger
AFTER INSERT ON messages
FOR EACH ROW
EXECUTE FUNCTION notify_agent_message_webhook();

-- Add a comment to explain the trigger
COMMENT ON TRIGGER agent_message_webhook_trigger ON messages IS 
'Sends agent messages with status=sent to n8n webhook. Will not block message insertion if webhook fails.';

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

-- Log the installation
DO $$
BEGIN
  RAISE NOTICE 'Simple webhook trigger installed successfully';
END;
$$;
