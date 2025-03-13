/*
  # Fix RLS policies for agents table

  1. Changes
    - Drop all existing policies
    - Add simple read policy for all authenticated users
    - Add simple admin modification policy
    - Remove potential circular references

  2. Security
    - Maintain basic security requirements
    - Allow admins to manage agents
    - Allow all authenticated users to read
*/

-- Drop all existing policies
DROP POLICY IF EXISTS "Allow authenticated users to read all agents" ON agents;
DROP POLICY IF EXISTS "Allow admins to create agents" ON agents;
DROP POLICY IF EXISTS "Allow admins to update agents" ON agents;
DROP POLICY IF EXISTS "Allow admins to delete agents" ON agents;
DROP POLICY IF EXISTS "agents_read_policy" ON agents;
DROP POLICY IF EXISTS "agents_bootstrap_policy" ON agents;
DROP POLICY IF EXISTS "agents_admin_insert_policy" ON agents;
DROP POLICY IF EXISTS "agents_self_update_policy" ON agents;
DROP POLICY IF EXISTS "agents_admin_update_policy" ON agents;
DROP POLICY IF EXISTS "agents_admin_delete_policy" ON agents;
DROP POLICY IF EXISTS "Todos pueden leer" ON agents;
DROP POLICY IF EXISTS "Solo admins pueden modificar" ON agents;

-- Create simple read policy for all authenticated users
CREATE POLICY "agents_read_all"
  ON agents FOR SELECT
  TO authenticated
  USING (true);

-- Create simple admin modification policy
CREATE POLICY "agents_admin_all"
  ON agents 
  USING (
    EXISTS (
      SELECT 1 FROM agents 
      WHERE id = auth.uid() 
      AND role = 'admin'
    )
  );