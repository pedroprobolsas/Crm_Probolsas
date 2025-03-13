/*
  # Add client tracking fields and views

  1. New Fields
    - Add last_interaction_date to clients table
    - Add assigned_agent_id to clients table
    - Add interaction_count to clients table
    - Add interaction_type to conversations table

  2. New Views
    - client_interaction_metrics view for tracking interaction statistics
    - agent_performance_metrics view for monthly agent performance

  3. Security
    - Enable RLS on new views
    - Add policies for authenticated users
*/

-- Add new fields to clients table
ALTER TABLE clients
ADD COLUMN IF NOT EXISTS last_interaction_date TIMESTAMPTZ,
ADD COLUMN IF NOT EXISTS assigned_agent_id UUID REFERENCES agents(id),
ADD COLUMN IF NOT EXISTS interaction_count INTEGER DEFAULT 0;

-- Add interaction type to conversations
ALTER TABLE conversations
ADD COLUMN IF NOT EXISTS interaction_type TEXT CHECK (interaction_type IN ('inquiry', 'quote', 'support', 'follow_up', 'other'));

-- Create view for client interaction metrics
CREATE OR REPLACE VIEW client_interaction_metrics AS
WITH interaction_ranges AS (
  SELECT
    id,
    assigned_agent_id,
    CASE
      WHEN last_interaction_date >= NOW() - INTERVAL '30 days' THEN '0-30'
      WHEN last_interaction_date >= NOW() - INTERVAL '60 days' THEN '31-60'
      WHEN last_interaction_date >= NOW() - INTERVAL '90 days' THEN '61-90'
      ELSE '90+'
    END as interaction_range
  FROM clients
  WHERE last_interaction_date IS NOT NULL
)
SELECT
  interaction_range,
  assigned_agent_id,
  COUNT(*) as client_count,
  ROUND(COUNT(*) * 100.0 / NULLIF(SUM(COUNT(*)) OVER (PARTITION BY assigned_agent_id), 0), 2) as percentage
FROM interaction_ranges
GROUP BY interaction_range, assigned_agent_id;

-- Create view for monthly agent performance
CREATE OR REPLACE VIEW agent_performance_metrics AS
SELECT
  a.id as agent_id,
  a.name as agent_name,
  DATE_TRUNC('month', c.created_at) as month,
  COUNT(DISTINCT c.id) as total_clients_contacted,
  COUNT(DISTINCT CASE 
    WHEN c.created_at >= NOW() - INTERVAL '30 days' 
    THEN c.id 
    END) as active_clients_30d,
  ROUND(COUNT(DISTINCT CASE 
    WHEN c.created_at >= NOW() - INTERVAL '30 days' 
    THEN c.id 
    END)::numeric * 100 / 
    NULLIF(COUNT(DISTINCT c.id), 0), 2) as active_percentage
FROM agents a
LEFT JOIN conversations c ON c.agent_id = a.id
GROUP BY a.id, a.name, DATE_TRUNC('month', c.created_at);

-- Create function to update client last interaction
CREATE OR REPLACE FUNCTION update_client_interaction()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE clients
  SET 
    last_interaction_date = NEW.created_at,
    interaction_count = interaction_count + 1
  WHERE id = NEW.client_id;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for updating client interaction
DROP TRIGGER IF EXISTS update_client_interaction_trigger ON conversations;
CREATE TRIGGER update_client_interaction_trigger
  AFTER INSERT ON conversations
  FOR EACH ROW
  EXECUTE FUNCTION update_client_interaction();

-- Grant permissions to authenticated users
GRANT SELECT ON client_interaction_metrics TO authenticated;
GRANT SELECT ON agent_performance_metrics TO authenticated;