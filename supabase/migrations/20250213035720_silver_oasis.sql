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
      -- Basic required fields
      IF NOT (
        (NEW.packaging_types->i) ? 'code' AND
        (NEW.packaging_types->i) ? 'type' AND
        (NEW.packaging_types->i) ? 'monthly_volume' AND
        (NEW.packaging_types->i) ? 'unit' AND
        (NEW.packaging_types->i) ? 'features'
      ) THEN
        RAISE EXCEPTION 'Missing required fields at index %', i;
      END IF;

      -- Type validation
      IF NOT (
        jsonb_typeof(NEW.packaging_types->i->'code') = 'string' AND
        jsonb_typeof(NEW.packaging_types->i->'type') = 'string' AND
        jsonb_typeof(NEW.packaging_types->i->'monthly_volume') = 'number' AND
        jsonb_typeof(NEW.packaging_types->i->'unit') = 'string' AND
        jsonb_typeof(NEW.packaging_types->i->'features') = 'object'
      ) THEN
        RAISE EXCEPTION 'Invalid field types at index %', i;
      END IF;

      -- Optional fields validation
      IF (NEW.packaging_types->i) ? 'material' AND jsonb_typeof(NEW.packaging_types->i->'material') != 'string' THEN
        RAISE EXCEPTION 'Invalid material type at index %', i;
      END IF;

      IF (NEW.packaging_types->i) ? 'thickness' AND jsonb_typeof(NEW.packaging_types->i->'thickness') != 'string' THEN
        RAISE EXCEPTION 'Invalid thickness type at index %', i;
      END IF;

      IF (NEW.packaging_types->i) ? 'width' AND jsonb_typeof(NEW.packaging_types->i->'width') != 'number' THEN
        RAISE EXCEPTION 'Invalid width type at index %', i;
      END IF;

      IF (NEW.packaging_types->i) ? 'processes' AND jsonb_typeof(NEW.packaging_types->i->'processes') != 'array' THEN
        RAISE EXCEPTION 'Invalid processes type at index %', i;
      END IF;

      IF (NEW.packaging_types->i) ? 'certifications' AND jsonb_typeof(NEW.packaging_types->i->'certifications') != 'array' THEN
        RAISE EXCEPTION 'Invalid certifications type at index %', i;
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

-- Update view to include packaging information
CREATE OR REPLACE VIEW client_details AS
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