-- Drop existing status column if it exists
ALTER TABLE products DROP COLUMN IF EXISTS status;

-- Re-add status column with proper constraints
ALTER TABLE products 
ADD COLUMN status TEXT NOT NULL DEFAULT 'active' 
CHECK (status IN ('active', 'inactive'));

-- Create index for status column
CREATE INDEX IF NOT EXISTS idx_products_status ON products(status);

-- Update existing records to have 'active' status
UPDATE products SET status = 'active' WHERE status IS NULL;