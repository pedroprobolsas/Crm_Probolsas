-- First drop the trigger that depends on the function
DROP TRIGGER IF EXISTS validate_packaging_types_trigger ON clients;

-- Then drop the function
DROP FUNCTION IF EXISTS validate_packaging_types();

-- Create updated validation function
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
        (NEW.packaging_types->i) ? 'unit'
      ) THEN
        RAISE EXCEPTION 'Missing required fields at index %', i;
      END IF;

      -- Type validation
      IF NOT (
        jsonb_typeof(NEW.packaging_types->i->'code') = 'string' AND
        jsonb_typeof(NEW.packaging_types->i->'type') = 'string' AND
        jsonb_typeof(NEW.packaging_types->i->'monthly_volume') = 'number' AND
        jsonb_typeof(NEW.packaging_types->i->'unit') = 'string'
      ) THEN
        RAISE EXCEPTION 'Invalid field types at index %', i;
      END IF;

      -- Optional fields validation with type checking
      IF (NEW.packaging_types->i) ? 'features' AND jsonb_typeof(NEW.packaging_types->i->'features') != 'object' THEN
        RAISE EXCEPTION 'Invalid features type at index %', i;
      END IF;

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

-- Recreate trigger
CREATE TRIGGER validate_packaging_types_trigger
  BEFORE INSERT OR UPDATE OF packaging_types ON clients
  FOR EACH ROW
  EXECUTE FUNCTION validate_packaging_types();