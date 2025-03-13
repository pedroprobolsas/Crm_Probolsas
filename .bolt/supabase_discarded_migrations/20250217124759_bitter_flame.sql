-- Add stock column to products table
ALTER TABLE products
ADD COLUMN IF NOT EXISTS stock INTEGER NOT NULL DEFAULT 0;

-- Create index for stock queries
CREATE INDEX IF NOT EXISTS idx_products_stock ON products(stock);

-- Update existing products with random stock values for testing
UPDATE products
SET stock = floor(random() * 100)::integer
WHERE stock = 0;