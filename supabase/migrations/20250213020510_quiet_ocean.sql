/*
  # Add description and brand fields to clients

  1. Changes
    - Add `description` column (text, not null) to clients table
    - Add `brand` column (text, not null) to clients table
    - Create index on brand column for improved search performance
    - Set default values for existing records

  2. Notes
    - Using DO block for safe updates
    - Adding columns with defaults to handle existing records
*/

-- Add new columns with defaults
DO $$ 
BEGIN
  -- Add description column if it doesn't exist
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'clients' AND column_name = 'description'
  ) THEN
    ALTER TABLE clients ADD COLUMN description TEXT NOT NULL DEFAULT '';
  END IF;

  -- Add brand column if it doesn't exist
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'clients' AND column_name = 'brand'
  ) THEN
    ALTER TABLE clients ADD COLUMN brand TEXT NOT NULL DEFAULT '';
  END IF;
END $$;

-- Create index for brand search if it doesn't exist
CREATE INDEX IF NOT EXISTS idx_clients_brand ON clients(brand);

-- Update existing records with default values based on company name
UPDATE clients 
SET 
  description = CASE 
    WHEN description = '' THEN 'Cliente de ' || COALESCE(company, 'Sin empresa')
    ELSE description
  END,
  brand = CASE 
    WHEN brand = '' THEN COALESCE(company, 'Sin marca')
    ELSE brand
  END
WHERE description = '' OR brand = '';