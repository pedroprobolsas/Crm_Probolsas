/*
  # Adjust RLS policies for agents table

  1. Changes
    - Fix NEW table reference issues
    - Simplify policy conditions
    - Ensure proper role-based access

  2. Security
    - Maintain secure access control
    - Allow first admin creation
    - Protect agent data integrity
*/

-- Drop existing policies
DROP POLICY IF EXISTS "Allow authenticated users to read all agents" ON agents;
DROP POLICY IF EXISTS "Allow admins to create agents" ON agents;
DROP POLICY IF EXISTS "Allow admins to update agents" ON agents;
DROP POLICY IF EXISTS "Allow admins to delete agents" ON agents;
DROP POLICY IF EXISTS "Allow authenticated users to read agents" ON agents;
DROP POLICY IF EXISTS "Allow agents to update own status" ON agents;
DROP POLICY IF EXISTS "Allow admins full access" ON agents;

-- 1. Allow read access for all authenticated users
CREATE POLICY "Allow authenticated users to read agents"
  ON agents FOR SELECT
  TO authenticated
  USING (true);

-- 2. Allow creation of first admin
CREATE POLICY "Allow first admin creation"
  ON agents FOR INSERT
  TO authenticated
  WITH CHECK (
    NOT EXISTS (SELECT 1 FROM agents)
  );

-- 3. Allow admins to create new agents
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

-- 4. Allow agents to update their own status
CREATE POLICY "Allow agents to update own status"
  ON agents FOR UPDATE
  TO authenticated
  USING (id = auth.uid());

-- 5. Allow admins to update any agent
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

-- 6. Allow admins to delete agents
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