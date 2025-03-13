/*
  # Fix agents table RLS policies

  1. Changes
    - Drop all existing policies explicitly
    - Add simplified read policy for all authenticated users
    - Add bootstrap policy for first admin
    - Add admin management policy for subsequent changes

  2. Security
    - All authenticated users can read agents
    - First admin can be created when no admin exists
    - Only admins can manage other agents after initial setup
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
DROP POLICY IF EXISTS "read_agents" ON agents;
DROP POLICY IF EXISTS "admin_manage_agents" ON agents;

-- Create read policy for all authenticated users
CREATE POLICY "agents_read_all"
  ON agents FOR SELECT
  TO authenticated
  USING (true);

-- Create bootstrap policy for first admin
CREATE POLICY "agents_bootstrap_admin"
  ON agents FOR INSERT
  TO authenticated
  WITH CHECK (
    NOT EXISTS (SELECT 1 FROM agents WHERE role = 'admin')
    AND role = 'admin'
  );

-- Create admin management policy
CREATE POLICY "agents_admin_all"
  ON agents FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM agents
      WHERE id = auth.uid()
      AND role = 'admin'
    )
  );