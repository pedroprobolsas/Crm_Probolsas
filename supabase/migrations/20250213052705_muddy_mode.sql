/*
  # Add next action tracking fields to clients table

  1. Changes
    - Add next_action field to clients table
    - Add next_action_date field to clients table
    - Add last_action_date field to clients table
    - Add action_status field to clients table
    - Create indexes for efficient querying

  2. Security
    - No changes to RLS policies required
*/

-- Add next action tracking fields
ALTER TABLE clients
ADD COLUMN IF NOT EXISTS next_action TEXT,
ADD COLUMN IF NOT EXISTS next_action_date TIMESTAMPTZ,
ADD COLUMN IF NOT EXISTS last_action_date TIMESTAMPTZ,
ADD COLUMN IF NOT EXISTS action_status TEXT CHECK (action_status IN ('pending', 'completed', 'cancelled')) DEFAULT 'pending';

-- Create indexes for efficient querying
CREATE INDEX IF NOT EXISTS idx_clients_next_action_date ON clients(next_action_date);
CREATE INDEX IF NOT EXISTS idx_clients_last_action_date ON clients(last_action_date);
CREATE INDEX IF NOT EXISTS idx_clients_action_status ON clients(action_status);

-- Create function to update last action date
CREATE OR REPLACE FUNCTION update_client_last_action()
RETURNS TRIGGER AS $$
BEGIN
  NEW.last_action_date = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger to automatically update last_action_date
DROP TRIGGER IF EXISTS update_client_last_action_trigger ON clients;
CREATE TRIGGER update_client_last_action_trigger
  BEFORE UPDATE OF next_action, next_action_date, action_status ON clients
  FOR EACH ROW
  EXECUTE FUNCTION update_client_last_action();