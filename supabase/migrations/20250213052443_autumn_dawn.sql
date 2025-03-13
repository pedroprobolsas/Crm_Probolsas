/*
  # Add attachments column to client_interactions table

  1. Changes
    - Add JSONB attachments column to client_interactions table
    - Update validation trigger to handle attachments

  2. Security
    - No changes to RLS policies required
*/

-- Add attachments column to client_interactions table
ALTER TABLE client_interactions
ADD COLUMN IF NOT EXISTS attachments JSONB DEFAULT '[]'::jsonb;

-- Create index for attachments
CREATE INDEX IF NOT EXISTS idx_client_interactions_attachments 
ON client_interactions USING gin (attachments);

-- Update validation trigger
CREATE OR REPLACE FUNCTION validate_client_interaction()
RETURNS TRIGGER AS $$
BEGIN
  -- Validate attachments structure
  IF NEW.attachments IS NOT NULL THEN
    IF jsonb_typeof(NEW.attachments) != 'array' THEN
      RAISE EXCEPTION 'attachments must be an array';
    END IF;

    -- Validate each attachment
    FOR i IN 0..jsonb_array_length(NEW.attachments) - 1 LOOP
      IF NOT (
        (NEW.attachments->i) ? 'name' AND
        (NEW.attachments->i) ? 'url' AND
        (NEW.attachments->i) ? 'type' AND
        jsonb_typeof(NEW.attachments->i->'name') = 'string' AND
        jsonb_typeof(NEW.attachments->i->'url') = 'string' AND
        jsonb_typeof(NEW.attachments->i->'type') = 'string'
      ) THEN
        RAISE EXCEPTION 'Invalid attachment structure at index %', i;
      END IF;
    END LOOP;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create or replace trigger
DROP TRIGGER IF EXISTS validate_client_interaction_trigger ON client_interactions;
CREATE TRIGGER validate_client_interaction_trigger
  BEFORE INSERT OR UPDATE ON client_interactions
  FOR EACH ROW
  EXECUTE FUNCTION validate_client_interaction();