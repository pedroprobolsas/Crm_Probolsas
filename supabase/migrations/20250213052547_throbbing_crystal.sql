/*
  # Add priority and status fields to client_interactions

  1. Changes
    - Add priority field to client_interactions table
    - Add status field to client_interactions table
    - Update validation trigger

  2. Security
    - No changes to RLS policies required
*/

-- Add priority and status fields
ALTER TABLE client_interactions
ADD COLUMN IF NOT EXISTS priority TEXT CHECK (priority IN ('low', 'medium', 'high')) DEFAULT 'medium',
ADD COLUMN IF NOT EXISTS status TEXT CHECK (status IN ('pending', 'completed', 'cancelled')) DEFAULT 'pending';

-- Create indexes for new fields
CREATE INDEX IF NOT EXISTS idx_client_interactions_priority ON client_interactions(priority);
CREATE INDEX IF NOT EXISTS idx_client_interactions_status ON client_interactions(status);

-- Update validation trigger
CREATE OR REPLACE FUNCTION validate_client_interaction()
RETURNS TRIGGER AS $$
BEGIN
  -- Validate priority
  IF NEW.priority IS NULL OR NEW.priority NOT IN ('low', 'medium', 'high') THEN
    RAISE EXCEPTION 'Invalid priority value. Must be low, medium, or high';
  END IF;

  -- Validate status
  IF NEW.status IS NULL OR NEW.status NOT IN ('pending', 'completed', 'cancelled') THEN
    RAISE EXCEPTION 'Invalid status value. Must be pending, completed, or cancelled';
  END IF;

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