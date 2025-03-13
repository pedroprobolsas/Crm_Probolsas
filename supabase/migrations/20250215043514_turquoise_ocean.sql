-- Add deactivation fields to agents table
ALTER TABLE agents
ADD COLUMN IF NOT EXISTS deactivation_reason TEXT,
ADD COLUMN IF NOT EXISTS deactivation_date TIMESTAMPTZ;

-- Create clients_agents table for tracking assignments
CREATE TABLE IF NOT EXISTS clients_agents (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  client_id UUID REFERENCES clients(id) ON DELETE CASCADE,
  agent_id UUID REFERENCES agents(id) ON DELETE SET NULL,
  assigned_at TIMESTAMPTZ DEFAULT NOW(),
  active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Add indexes
CREATE INDEX IF NOT EXISTS idx_clients_agents_client ON clients_agents(client_id);
CREATE INDEX IF NOT EXISTS idx_clients_agents_agent ON clients_agents(agent_id);
CREATE INDEX IF NOT EXISTS idx_clients_agents_active ON clients_agents(active);

-- Add RLS policies
ALTER TABLE clients_agents ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Authenticated users can read assignments"
  ON clients_agents FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Authenticated users can manage assignments"
  ON clients_agents FOR ALL
  TO authenticated
  USING (true);

-- Create function to update assignment history
CREATE OR REPLACE FUNCTION update_client_assignment()
RETURNS TRIGGER AS $$
BEGIN
  -- Mark previous assignment as inactive
  UPDATE clients_agents
  SET active = false, updated_at = NOW()
  WHERE client_id = NEW.client_id AND id != NEW.id AND active = true;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for assignment updates
CREATE TRIGGER update_client_assignment_trigger
  AFTER INSERT ON clients_agents
  FOR EACH ROW
  EXECUTE FUNCTION update_client_assignment();

-- Create function to get assigned clients
CREATE OR REPLACE FUNCTION get_assigned_clients(p_agent_id UUID)
RETURNS TABLE (
  client_id UUID,
  client_name TEXT,
  company TEXT,
  status TEXT,
  stage TEXT,
  last_interaction TIMESTAMPTZ
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    c.id,
    c.name,
    c.company,
    c.status,
    c.current_stage::TEXT,
    c.last_interaction_date
  FROM clients c
  JOIN clients_agents ca ON c.id = ca.client_id
  WHERE ca.agent_id = p_agent_id AND ca.active = true;
END;
$$ LANGUAGE plpgsql;

-- Create function to reassign clients
CREATE OR REPLACE FUNCTION reassign_clients(
  p_old_agent_id UUID,
  p_assignments JSONB
)
RETURNS void AS $$
DECLARE
  client_id UUID;
  new_agent_id UUID;
BEGIN
  FOR client_id, new_agent_id IN 
    SELECT 
      (jsonb_each_text(p_assignments)).key::UUID,
      (jsonb_each_text(p_assignments)).value::UUID
  LOOP
    -- Insert new assignment
    INSERT INTO clients_agents (client_id, agent_id)
    VALUES (client_id, new_agent_id);
    
    -- Update client's assigned agent
    UPDATE clients
    SET 
      assigned_agent_id = new_agent_id,
      updated_at = NOW()
    WHERE id = client_id;
  END LOOP;
END;
$$ LANGUAGE plpgsql;