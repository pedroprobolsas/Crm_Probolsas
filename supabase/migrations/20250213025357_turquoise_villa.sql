/*
  # Client Timeline and Documents

  1. New Tables
    - client_documents: Store document attachments
    - stage_history: Track stage changes

  2. Views
    - client_timeline: Unified view of all client events

  3. Security
    - RLS policies for new tables
*/

-- Create table for document attachments
CREATE TABLE IF NOT EXISTS client_documents (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  client_id UUID REFERENCES clients(id) ON DELETE CASCADE,
  interaction_id UUID REFERENCES client_interactions(id) ON DELETE SET NULL,
  name TEXT NOT NULL,
  url TEXT NOT NULL,
  type TEXT NOT NULL,
  size INTEGER,
  uploaded_at TIMESTAMPTZ DEFAULT NOW(),
  uploaded_by UUID REFERENCES agents(id),
  notes TEXT
);

-- Create table for stage history
CREATE TABLE IF NOT EXISTS stage_history (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  client_id UUID REFERENCES clients(id) ON DELETE CASCADE,
  previous_stage client_stage_type,
  new_stage client_stage_type NOT NULL,
  changed_at TIMESTAMPTZ DEFAULT NOW(),
  changed_by UUID REFERENCES agents(id),
  notes TEXT
);

-- Create view for client timeline
CREATE OR REPLACE VIEW client_timeline AS
WITH all_events AS (
  -- Interactions
  SELECT
    ci.client_id,
    ci.date as event_date,
    'interaction' as event_type,
    ci.type as interaction_type,
    ci.notes as description,
    a.name as agent_name,
    json_build_object(
      'type', ci.type,
      'next_action', ci.next_action,
      'next_action_date', ci.next_action_date
    ) as details
  FROM client_interactions ci
  LEFT JOIN agents a ON a.id = ci.agent_id

  UNION ALL

  -- Stage changes
  SELECT
    sh.client_id,
    sh.changed_at as event_date,
    'stage_change' as event_type,
    NULL as interaction_type,
    sh.notes as description,
    a.name as agent_name,
    json_build_object(
      'previous_stage', sh.previous_stage,
      'new_stage', sh.new_stage
    ) as details
  FROM stage_history sh
  LEFT JOIN agents a ON a.id = sh.changed_by

  UNION ALL

  -- Documents
  SELECT
    cd.client_id,
    cd.uploaded_at as event_date,
    'document' as event_type,
    NULL as interaction_type,
    cd.notes as description,
    a.name as agent_name,
    json_build_object(
      'name', cd.name,
      'url', cd.url,
      'type', cd.type,
      'size', cd.size
    ) as details
  FROM client_documents cd
  LEFT JOIN agents a ON a.id = cd.uploaded_by
)
SELECT
  client_id,
  event_date,
  event_type,
  interaction_type,
  description,
  agent_name,
  details
FROM all_events
ORDER BY event_date DESC;

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_client_documents_client ON client_documents(client_id);
CREATE INDEX IF NOT EXISTS idx_stage_history_client ON stage_history(client_id);

-- Enable RLS
ALTER TABLE client_documents ENABLE ROW LEVEL SECURITY;
ALTER TABLE stage_history ENABLE ROW LEVEL SECURITY;

-- RLS policies
CREATE POLICY "Usuarios autenticados pueden leer documentos" 
  ON client_documents FOR SELECT TO authenticated 
  USING (true);

CREATE POLICY "Usuarios autenticados pueden leer historial" 
  ON stage_history FOR SELECT TO authenticated 
  USING (true);

-- Function to update client stage
CREATE OR REPLACE FUNCTION update_client_stage(
  p_client_id UUID,
  p_new_stage client_stage_type,
  p_agent_id UUID,
  p_notes TEXT DEFAULT NULL
)
RETURNS void AS $$
DECLARE
  v_current_stage client_stage_type;
BEGIN
  -- Get current stage
  SELECT current_stage INTO v_current_stage
  FROM clients
  WHERE id = p_client_id;

  -- Record change in history
  INSERT INTO stage_history (
    client_id,
    previous_stage,
    new_stage,
    changed_by,
    notes
  ) VALUES (
    p_client_id,
    v_current_stage,
    p_new_stage,
    p_agent_id,
    p_notes
  );

  -- Update client stage
  UPDATE clients
  SET 
    current_stage = p_new_stage,
    stage_start_date = NOW(),
    updated_at = NOW()
  WHERE id = p_client_id;
END;
$$ LANGUAGE plpgsql;