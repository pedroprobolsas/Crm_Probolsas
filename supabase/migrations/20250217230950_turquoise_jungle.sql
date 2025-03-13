-- First drop the trigger that depends on the function
DROP TRIGGER IF EXISTS validate_packaging_types_trigger ON clients;

-- Then drop the function
DROP FUNCTION IF EXISTS validate_packaging_types();

-- Create updated validation function with more flexible validation
CREATE OR REPLACE FUNCTION validate_packaging_types()
RETURNS TRIGGER AS $$
BEGIN
  -- Handle null or empty array case
  IF NEW.packaging_types IS NULL THEN
    NEW.packaging_types := '[]'::jsonb;
  END IF;

  -- Check if it's an array
  IF jsonb_typeof(NEW.packaging_types) != 'array' THEN
    RAISE EXCEPTION 'packaging_types must be an array';
  END IF;

  -- If array is empty, that's valid
  IF jsonb_array_length(NEW.packaging_types) = 0 THEN
    RETURN NEW;
  END IF;

  -- Check each element's structure
  FOR i IN 0..jsonb_array_length(NEW.packaging_types) - 1 LOOP
    -- Basic required fields with default values
    IF NOT (NEW.packaging_types->i) ? 'code' THEN
      NEW.packaging_types = jsonb_set(
        NEW.packaging_types,
        ARRAY[i::text, 'code'],
        '"UNKNOWN"'::jsonb
      );
    END IF;

    IF NOT (NEW.packaging_types->i) ? 'type' THEN
      NEW.packaging_types = jsonb_set(
        NEW.packaging_types,
        ARRAY[i::text, 'type'],
        '"Sin especificar"'::jsonb
      );
    END IF;

    IF NOT (NEW.packaging_types->i) ? 'monthly_volume' THEN
      NEW.packaging_types = jsonb_set(
        NEW.packaging_types,
        ARRAY[i::text, 'monthly_volume'],
        '0'::jsonb
      );
    END IF;

    IF NOT (NEW.packaging_types->i) ? 'unit' THEN
      NEW.packaging_types = jsonb_set(
        NEW.packaging_types,
        ARRAY[i::text, 'unit'],
        '"unidades"'::jsonb
      );
    END IF;

    -- Validate types for required fields
    IF jsonb_typeof(NEW.packaging_types->i->'code') != 'string' OR
       jsonb_typeof(NEW.packaging_types->i->'type') != 'string' OR
       jsonb_typeof(NEW.packaging_types->i->'monthly_volume') != 'number' OR
       jsonb_typeof(NEW.packaging_types->i->'unit') != 'string' THEN
      RAISE EXCEPTION 'Invalid field types at index %', i;
    END IF;

    -- Optional fields validation with type checking and default values
    IF (NEW.packaging_types->i) ? 'features' AND jsonb_typeof(NEW.packaging_types->i->'features') != 'object' THEN
      NEW.packaging_types = jsonb_set(
        NEW.packaging_types,
        ARRAY[i::text, 'features'],
        '{}'::jsonb
      );
    END IF;

    IF (NEW.packaging_types->i) ? 'material' AND jsonb_typeof(NEW.packaging_types->i->'material') != 'string' THEN
      NEW.packaging_types = jsonb_set(
        NEW.packaging_types,
        ARRAY[i::text, 'material'],
        'null'::jsonb
      );
    END IF;

    IF (NEW.packaging_types->i) ? 'thickness' AND jsonb_typeof(NEW.packaging_types->i->'thickness') != 'string' THEN
      NEW.packaging_types = jsonb_set(
        NEW.packaging_types,
        ARRAY[i::text, 'thickness'],
        'null'::jsonb
      );
    END IF;

    IF (NEW.packaging_types->i) ? 'width' AND jsonb_typeof(NEW.packaging_types->i->'width') != 'number' THEN
      NEW.packaging_types = jsonb_set(
        NEW.packaging_types,
        ARRAY[i::text, 'width'],
        'null'::jsonb
      );
    END IF;

    IF (NEW.packaging_types->i) ? 'processes' AND jsonb_typeof(NEW.packaging_types->i->'processes') != 'array' THEN
      NEW.packaging_types = jsonb_set(
        NEW.packaging_types,
        ARRAY[i::text, 'processes'],
        '[]'::jsonb
      );
    END IF;

    IF (NEW.packaging_types->i) ? 'certifications' AND jsonb_typeof(NEW.packaging_types->i->'certifications') != 'array' THEN
      NEW.packaging_types = jsonb_set(
        NEW.packaging_types,
        ARRAY[i::text, 'certifications'],
        '[]'::jsonb
      );
    END IF;
  END LOOP;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Recreate trigger
CREATE TRIGGER validate_packaging_types_trigger
  BEFORE INSERT OR UPDATE OF packaging_types ON clients
  FOR EACH ROW
  EXECUTE FUNCTION validate_packaging_types();