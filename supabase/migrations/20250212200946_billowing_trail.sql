/*
  # Create agents table and security policies

  1. New Tables
    - `agents`
      - `id` (uuid, primary key)
      - `created_at` (timestamp)
      - `updated_at` (timestamp)
      - `name` (text)
      - `email` (text, unique)
      - `whatsapp_number` (text)
      - `role` (text)
      - `status` (text)
      - `avatar` (text)
      - `active_chats` (integer)
      - `satisfaction_score` (numeric)
      - `last_active` (timestamp)

  2. Security
    - Enable RLS on `agents` table
    - Add policies for authenticated users to:
      - Read all agents
      - Create new agents (admin only)
      - Update agent status and metrics
      - Delete agents (admin only)
*/

-- Create agents table
CREATE TABLE IF NOT EXISTS agents (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  name TEXT NOT NULL,
  email TEXT UNIQUE NOT NULL,
  whatsapp_number TEXT UNIQUE,
  role TEXT DEFAULT 'agent' CHECK (role IN ('admin', 'agent')),
  status TEXT DEFAULT 'offline' CHECK (status IN ('online', 'busy', 'offline')),
  avatar TEXT,
  active_chats INTEGER DEFAULT 0,
  satisfaction_score NUMERIC(3,2) DEFAULT 5.00,
  last_active TIMESTAMPTZ DEFAULT NOW()
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_agents_email ON agents(email);
CREATE INDEX IF NOT EXISTS idx_agents_status ON agents(status);
CREATE INDEX IF NOT EXISTS idx_agents_role ON agents(role);

-- Enable RLS
ALTER TABLE agents ENABLE ROW LEVEL SECURITY;

-- Create RLS policies
CREATE POLICY "Allow authenticated users to read all agents"
  ON agents FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Allow admins to create agents"
  ON agents FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM agents
      WHERE agents.id = auth.uid()
      AND agents.role = 'admin'
    )
  );

CREATE POLICY "Allow admins to update agents"
  ON agents FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM agents
      WHERE agents.id = auth.uid()
      AND agents.role = 'admin'
    )
  );

CREATE POLICY "Allow admins to delete agents"
  ON agents FOR DELETE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM agents
      WHERE agents.id = auth.uid()
      AND agents.role = 'admin'
    )
  );

-- Create trigger for updated_at
CREATE TRIGGER update_agents_updated_at
    BEFORE UPDATE ON agents
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();