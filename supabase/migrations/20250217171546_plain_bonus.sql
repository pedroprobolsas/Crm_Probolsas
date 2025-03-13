/*
  # Add status column to products table

  1. Changes
    - Add status column to products table with active/inactive values
    - Set default value to 'active'
    - Add check constraint to ensure valid values
    - Update existing records to have 'active' status
*/

-- Add status column with check constraint
ALTER TABLE products 
ADD COLUMN IF NOT EXISTS status TEXT NOT NULL DEFAULT 'active' 
CHECK (status IN ('active', 'inactive'));

-- Create index for status column
CREATE INDEX IF NOT EXISTS idx_products_status ON products(status);

-- Update existing records to have 'active' status
UPDATE products SET status = 'active' WHERE status IS NULL;