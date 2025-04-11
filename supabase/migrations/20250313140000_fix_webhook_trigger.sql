/*
  # Fix Webhook Trigger Issue

  1. Purpose
    - Fix the issue with the webhook trigger that's preventing messages from being inserted
    - Temporarily disable the trigger to allow messages to be inserted properly
    
  2. Notes
    - This is a temporary fix until the webhook functionality can be properly implemented
    - The trigger will be re-enabled once the http extension issues are resolved
*/

-- Disable the trigger that's causing the issue
ALTER TABLE messages DISABLE TRIGGER agent_message_webhook_trigger;

-- Log the change
DO $$
BEGIN
  RAISE NOTICE 'Webhook trigger for agent messages has been temporarily disabled';
END;
$$;
