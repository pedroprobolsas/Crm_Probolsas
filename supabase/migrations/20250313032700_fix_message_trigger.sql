/*
  # Fix Message Trigger for Webhook Notification

  1. Changes
    - Modify the existing trigger function to add better error handling
    - Ensure the trigger doesn't block message insertion even if webhook fails
    - Add logging for debugging purposes
    
  2. Notes
    - Uses TRY/CATCH to prevent webhook errors from affecting message insertion
    - Adds more detailed logging for troubleshooting
*/

-- Drop the existing trigger
DROP TRIGGER IF EXISTS messages_new_agent_sent_trigger ON messages;

-- Modify the function with better error handling
CREATE OR REPLACE FUNCTION notify_new_agent_sent_message()
RETURNS trigger AS $$
DECLARE
  payload JSONB;
  result JSONB;
  webhook_url TEXT := 'https://ippwebhookn8n.probolsas.co/webhook/a7c5e1b0-c8bc-4dd2-b0f0-fe263fa246cf';
  http_status INT;
BEGIN
  -- Only proceed if it's an INSERT operation AND meets conditions (status='sent')
  IF (TG_OP = 'INSERT' AND NEW.status = 'sent' AND NEW.sender = 'agent') THEN
    BEGIN -- Start of error handling block
      -- Create payload with relevant fields
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
      RAISE LOG 'Attempting to send message to webhook: %', payload;

      -- Try to send to the webhook with error handling
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
        RAISE LOG 'Successfully sent message to webhook. Status: %, Response: %', http_status, result;
      EXCEPTION WHEN OTHERS THEN
        -- Log webhook error but don't block the transaction
        RAISE WARNING 'Error sending to webhook: %. Message was still saved.', SQLERRM;
      END;
    EXCEPTION WHEN OTHERS THEN
      -- Log any other errors but don't block the transaction
      RAISE WARNING 'Error in webhook notification function: %. Message was still saved.', SQLERRM;
    END;
  END IF;
  
  -- Always return NEW to ensure the trigger doesn't block the insert
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create the trigger again, but make it AFTER INSERT to ensure it doesn't block insertion
CREATE TRIGGER messages_new_agent_sent_trigger
AFTER INSERT ON messages
FOR EACH ROW EXECUTE PROCEDURE notify_new_agent_sent_message();

-- Add a comment to explain the trigger
COMMENT ON TRIGGER messages_new_agent_sent_trigger ON messages IS 
'Sends a notification to n8n webhook when an agent sends a message. Will not block message insertion if webhook fails.';
