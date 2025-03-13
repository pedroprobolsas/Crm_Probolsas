/*
  # Bootstrap admin policies for agents table

  1. Changes
    - Implement bootstrap policy for first admin
    - Ensure secure admin creation flow
    - Maintain data integrity

  2. Security
    - Allow first admin creation only when table is empty
    - Require admin role for first user
    - Maintain existing security policies
*/

-- Drop existing policies
DROP POLICY IF EXISTS "Allow authenticated users to read all agents" ON agents;
DROP POLICY IF EXISTS "Allow admins to create agents" ON agents;
DROP POLICY IF EXISTS "Allow admins to update agents" ON agents;
DROP POLICY IF EXISTS "Allow admins to delete agents" ON agents;
DROP POLICY IF EXISTS "Allow authenticated users to read agents" ON agents;
DROP POLICY IF EXISTS "Allow agents to update own status" ON agents;
DROP POLICY IF EXISTS "Allow admins full access" ON agents;
DROP POLICY IF EXISTS "Allow first admin creation" ON agents;

-- 1. Bootstrap policy: Allow creation of first admin
CREATE POLICY "Bootstrap first admin"
  ON agents FOR INSERT
  TO authenticated
  WITH CHECK (
    NOT EXISTS (SELECT 1 FROM agents) -- Only if table is empty
    AND role = 'admin'                -- Must be admin
  );

-- 2. Read access for all authenticated users
CREATE POLICY "Read agents"
  ON agents FOR SELECT
  TO authenticated
  USING (true);

-- 3. Admin management policies
CREATE POLICY "Admin manage agents"
  ON agents FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM agents
      WHERE agents.id = auth.uid()
      AND agents.role = 'admin'
    )
  );

-- 4. Self-management policy for agents
CREATE POLICY "Agent self management"
  ON agents FOR UPDATE
  TO authenticated
  USING (id = auth.uid())
  WITH CHECK (
    id = auth.uid()
    AND role IS NULL      -- Cannot change role
    AND email IS NULL     -- Cannot change email
    AND name IS NULL      -- Cannot change name
  );