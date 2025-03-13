/*
  # Final Webhook Trigger Fix

  1. Changes
    - Create a robust version of the webhook trigger
    - Ensure it never blocks message insertion
    - Add comprehensive error handling
    - Fix the return value to ensure messages are saved
    
  2. Notes
    - This is the final fix based on diagnostic results
    - Uses AFTER INSERT to ensure it doesn't interfere with message insertion
    - Returns NEW to ensure the message is saved regardless of webhook status
*/

-- Drop the existing trigger
DROP TRIGGER IF EXISTS messages_new_agent_sent_trigger ON messages;

-- Create a robust version of the function
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
      RAISE LOG 'Attempting to send message to webhook: %', NEW.id;

      -- Try to send to the webhook with error handling
      BEGIN
        PERFORM pg_notify('webhook_notification', payload::text);
        
        -- Only try HTTP call if extension is available
        IF EXISTS (
          SELECT 1 FROM pg_extension WHERE extname = 'http'
        ) THEN
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
            RAISE LOG 'Successfully sent message to webhook. Status: %, Message ID: %', http_status, NEW.id;
          EXCEPTION WHEN OTHERS THEN
            -- Log webhook error but don't block the transaction
            RAISE WARNING 'Error sending to webhook: %. Message ID % was still saved.', SQLERRM, NEW.id;
          END;
        ELSE
          RAISE LOG 'HTTP extension not available. Using notification channel only for message ID: %', NEW.id;
        END IF;
      EXCEPTION WHEN OTHERS THEN
        -- Log webhook error but don't block the transaction
        RAISE WARNING 'Error in webhook notification: %. Message ID % was still saved.', SQLERRM, NEW.id;
      END;
    EXCEPTION WHEN OTHERS THEN
      -- Log any other errors but don't block the transaction
      RAISE WARNING 'Error in webhook notification function: %. Message ID % was still saved.', SQLERRM, NEW.id;
    END;
  END IF;
  
  -- Always return NEW to ensure the trigger doesn't block the insert
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create the trigger as AFTER INSERT to ensure it doesn't block insertion
CREATE TRIGGER messages_new_agent_sent_trigger
AFTER INSERT ON messages
FOR EACH ROW EXECUTE PROCEDURE notify_new_agent_sent_message();

-- Add a comment to explain the trigger
COMMENT ON TRIGGER messages_new_agent_sent_trigger ON messages IS 
'Sends a notification to n8n webhook when an agent sends a message. Will not block message insertion if webhook fails.';

-- Create a notification channel for webhook events
DO $$
BEGIN
  PERFORM pg_notify('webhook_setup', 'Webhook notification channel initialized');
  RAISE LOG 'Webhook notification channel initialized';
END;
$$;
