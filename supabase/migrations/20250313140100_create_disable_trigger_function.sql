/*
  # Create Function to Disable Webhook Trigger

  1. Purpose
    - Create a SQL function that can be called from the application to disable the webhook trigger
    - This provides a way to fix the issue without requiring direct database access
    
  2. Usage
    - Call this function from the application code: await supabase.rpc('disable_webhook_trigger')
*/

-- Create a function to disable the webhook trigger
CREATE OR REPLACE FUNCTION disable_webhook_trigger()
RETURNS TEXT AS $$
DECLARE
  result TEXT;
BEGIN
  -- Check if the trigger exists
  IF EXISTS (
    SELECT 1 FROM pg_trigger 
    WHERE tgname = 'agent_message_webhook_trigger'
  ) THEN
    -- Disable the trigger
    EXECUTE 'ALTER TABLE messages DISABLE TRIGGER agent_message_webhook_trigger';
    result := 'Webhook trigger disabled successfully';
  ELSE
    result := 'Webhook trigger not found';
  END IF;
  
  RETURN result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION disable_webhook_trigger() TO authenticated;

-- Add a comment to explain the function
COMMENT ON FUNCTION disable_webhook_trigger() IS 
'Disables the webhook trigger on the messages table to fix insertion issues';
