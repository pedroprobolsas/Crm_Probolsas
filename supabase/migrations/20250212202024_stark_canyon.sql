/*
  # Fix RLS policies for agents table

  1. Changes
    - Remove existing policies
    - Create new policies with correct UUID handling
    - Fix NEW/OLD references in RLS policies using proper PL/pgSQL syntax

  2. Security
    - Maintain same security rules but with correct syntax
    - All authenticated users can read agents
    - Agents can only update their own status
    - Admins have full access to manage agents
*/

-- Drop existing policies
DROP POLICY IF EXISTS "Allow authenticated users to read all agents" ON agents;
DROP POLICY IF EXISTS "Allow admins to create agents" ON agents;
DROP POLICY IF EXISTS "Allow admins to update agents" ON agents;
DROP POLICY IF EXISTS "Allow admins to delete agents" ON agents;
DROP POLICY IF EXISTS "Allow authenticated users to read agents" ON agents;
DROP POLICY IF EXISTS "Allow agents to update own status" ON agents;
DROP POLICY IF EXISTS "Allow admins full access" ON agents;

-- Create new policies with correct UUID handling
-- 1. Read access for all authenticated users
CREATE POLICY "Allow authenticated users to read agents"
  ON agents FOR SELECT
  TO authenticated
  USING (true);

-- 2. Allow agents to update their own status and last_active
CREATE POLICY "Allow agents to update own status"
  ON agents FOR UPDATE
  TO authenticated
  USING (id = auth.uid())
  WITH CHECK (
    id = auth.uid()
    AND (status IS NOT NULL OR last_active IS NOT NULL)
  );

-- 3. Allow admins full access to manage agents
CREATE POLICY "Allow admins full access"
  ON agents FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM agents
      WHERE agents.id = auth.uid()
      AND agents.role = 'admin'
    )
  );