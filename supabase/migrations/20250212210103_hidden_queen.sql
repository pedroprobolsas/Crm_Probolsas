/*
  # Simplify RLS policies for agents table

  1. Changes
    - Drop all existing policies explicitly
    - Add simple read policy for all authenticated users
    - Add simple admin modification policy for all operations

  2. Security
    - All authenticated users can read agents
    - Only admins can create/update/delete agents
*/

-- Drop all existing policies explicitly
DROP POLICY IF EXISTS "Allow authenticated users to read all agents" ON agents;
DROP POLICY IF EXISTS "Allow admins to create agents" ON agents;
DROP POLICY IF EXISTS "Allow admins to update agents" ON agents;
DROP POLICY IF EXISTS "Allow admins to delete agents" ON agents;
DROP POLICY IF EXISTS "Allow agents to update own status" ON agents;
DROP POLICY IF EXISTS "Allow admins full access" ON agents;
DROP POLICY IF EXISTS "Bootstrap first admin" ON agents;
DROP POLICY IF EXISTS "agents_read_policy" ON agents;
DROP POLICY IF EXISTS "agents_bootstrap_policy" ON agents;
DROP POLICY IF EXISTS "agents_admin_insert_policy" ON agents;
DROP POLICY IF EXISTS "agents_self_update_policy" ON agents;
DROP POLICY IF EXISTS "agents_admin_update_policy" ON agents;
DROP POLICY IF EXISTS "agents_admin_delete_policy" ON agents;
DROP POLICY IF EXISTS "Todos pueden leer" ON agents;
DROP POLICY IF EXISTS "Solo admins pueden modificar" ON agents;
DROP POLICY IF EXISTS "agents_read_all" ON agents;
DROP POLICY IF EXISTS "agents_admin_all" ON agents;
DROP POLICY IF EXISTS "read_agents" ON agents;
DROP POLICY IF EXISTS "admin_manage_agents" ON agents;
DROP POLICY IF EXISTS "Agent self management" ON agents;

-- Create simple read policy for all authenticated users
CREATE POLICY "read_agents"
  ON agents FOR SELECT
  TO authenticated
  USING (true);

-- Create simple admin modification policy
CREATE POLICY "admin_manage_agents"
  ON agents FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM agents
      WHERE id = auth.uid()
      AND role = 'admin'
    )
  );