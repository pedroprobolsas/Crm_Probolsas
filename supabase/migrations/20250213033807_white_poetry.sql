/*
  # Add Packaging Types to Clients Table

  1. Changes
    - Add packaging_types column to clients table as JSONB array
    - Add trigger-based validation for packaging types structure
    - Add index for better query performance
    - Create new view for client details with packaging information

  2. Notes
    - Uses trigger-based validation for data integrity
    - Each packaging type must have: type, monthly_volume, and unit
    - Updates client_details view to include packaging metrics
*/

-- Add packaging_types column to clients table
ALTER TABLE clients 
ADD COLUMN IF NOT EXISTS packaging_types JSONB DEFAULT '[]'::jsonb;

-- Create function to validate packaging types structure
CREATE OR REPLACE FUNCTION validate_packaging_types()
RETURNS TRIGGER AS $$
BEGIN
  -- Check if it's an array
  IF jsonb_typeof(NEW.packaging_types) != 'array' THEN
    RAISE EXCEPTION 'packaging_types must be an array';
  END IF;

  -- Check each element's structure
  IF jsonb_array_length(NEW.packaging_types) > 0 THEN
    FOR i IN 0..jsonb_array_length(NEW.packaging_types) - 1 LOOP
      IF NOT (
        (NEW.packaging_types->i) ? 'type' AND
        (NEW.packaging_types->i) ? 'monthly_volume' AND
        (NEW.packaging_types->i) ? 'unit' AND
        jsonb_typeof(NEW.packaging_types->i->'monthly_volume') = 'number' AND
        jsonb_typeof(NEW.packaging_types->i->'type') = 'string' AND
        jsonb_typeof(NEW.packaging_types->i->'unit') = 'string'
      ) THEN
        RAISE EXCEPTION 'Invalid packaging type structure at index %', i;
      END IF;
    END LOOP;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for validation
DROP TRIGGER IF EXISTS validate_packaging_types_trigger ON clients;
CREATE TRIGGER validate_packaging_types_trigger
  BEFORE INSERT OR UPDATE OF packaging_types ON clients
  FOR EACH ROW
  EXECUTE FUNCTION validate_packaging_types();

-- Add index for better query performance
CREATE INDEX IF NOT EXISTS idx_clients_packaging_types ON clients USING gin (packaging_types);

-- Drop existing view
DROP VIEW IF EXISTS client_details;

-- Create new view with packaging information
CREATE VIEW client_details AS
SELECT
  c.*,
  COALESCE(c.admin_employees_count, 0) + COALESCE(c.plant_employees_count, 0) as total_employee_count,
  CASE
    WHEN c.last_year_sales > 0 AND c.last_year_ebitda > 0 
    THEN ROUND((c.last_year_ebitda / c.last_year_sales * 100)::numeric, 2)
    ELSE NULL
  END as ebitda_margin,
  array_length(c.key_markets, 1) as markets_count,
  array_length(c.key_clients, 1) as key_clients_count,
  array_length(c.competitors, 1) as competitors_count,
  jsonb_array_length(c.current_projects) as active_projects_count,
  jsonb_array_length(c.packaging_types) as packaging_types_count,
  (
    SELECT COALESCE(SUM((value->>'monthly_volume')::numeric), 0)
    FROM jsonb_array_elements(c.packaging_types)
  ) as total_monthly_volume
FROM clients c;