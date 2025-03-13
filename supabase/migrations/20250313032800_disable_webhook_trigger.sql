/*
  # Temporarily Disable Webhook Trigger

  1. Changes
    - Drop the existing trigger
    - Create a simplified version that just logs but doesn't call the webhook
    - This is for testing if the webhook call is causing the issue
    
  2. Notes
    - This is a temporary solution for debugging
    - Once confirmed working, we can re-enable the webhook functionality
*/

-- Drop the existing trigger
DROP TRIGGER IF EXISTS messages_new_agent_sent_trigger ON messages;

-- Create a simplified function that just logs without calling the webhook
CREATE OR REPLACE FUNCTION notify_new_agent_sent_message()
RETURNS trigger AS $$
BEGIN
  -- Only proceed if it's an INSERT operation AND meets conditions (status='sent')
  IF (TG_OP = 'INSERT' AND NEW.status = 'sent' AND NEW.sender = 'agent') THEN
    -- Just log the message without calling the webhook
    RAISE LOG 'Message would be sent to webhook (webhook disabled for testing): id=%', NEW.id;
  END IF;
  
  -- Always return NEW to ensure the trigger doesn't block the insert
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create the trigger again
CREATE TRIGGER messages_new_agent_sent_trigger
AFTER INSERT ON messages
FOR EACH ROW EXECUTE PROCEDURE notify_new_agent_sent_message();

-- Add a comment to explain the trigger
COMMENT ON TRIGGER messages_new_agent_sent_trigger ON messages IS 
'TEMPORARY DEBUG VERSION - Logs when an agent sends a message but does not call webhook.';
