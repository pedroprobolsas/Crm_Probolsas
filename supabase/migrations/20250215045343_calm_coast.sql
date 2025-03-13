-- Create function to deactivate agent and reassign clients
CREATE OR REPLACE FUNCTION deactivate_agent(
  p_agent_id UUID,
  p_reason TEXT,
  p_effective_date TIMESTAMPTZ,
  p_reassignments JSONB
)
RETURNS void AS $$
BEGIN
  -- Start transaction
  BEGIN
    -- Update agent status
    UPDATE agents
    SET 
      status = 'inactive',
      deactivation_reason = p_reason,
      deactivation_date = p_effective_date,
      updated_at = NOW()
    WHERE id = p_agent_id;

    -- Reassign clients
    PERFORM reassign_clients(p_agent_id, p_reassignments);

    -- Create audit log entry
    INSERT INTO agent_status_history (
      agent_id,
      previous_status,
      new_status,
      change_reason,
      effective_date,
      reassignment_data
    ) VALUES (
      p_agent_id,
      'active',
      'inactive',
      p_reason,
      p_effective_date,
      p_reassignments
    );
  END;
END;
$$ LANGUAGE plpgsql;

-- Create agent status history table
CREATE TABLE IF NOT EXISTS agent_status_history (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  agent_id UUID REFERENCES agents(id) ON DELETE CASCADE,
  previous_status TEXT NOT NULL,
  new_status TEXT NOT NULL,
  change_reason TEXT,
  effective_date TIMESTAMPTZ,
  reassignment_data JSONB,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Add indexes
CREATE INDEX IF NOT EXISTS idx_agent_status_history_agent ON agent_status_history(agent_id);
CREATE INDEX IF NOT EXISTS idx_agent_status_history_date ON agent_status_history(effective_date);

-- Enable RLS
ALTER TABLE agent_status_history ENABLE ROW LEVEL SECURITY;

-- Add RLS policies
CREATE POLICY "Authenticated users can read status history"
  ON agent_status_history FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Authenticated users can insert status history"
  ON agent_status_history FOR INSERT
  TO authenticated
  WITH CHECK (true);