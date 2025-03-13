/*
  # Products Schema Migration with WooCommerce Integration
  
  1. Tables
    - products: Main table for product information with tiered pricing and WooCommerce fields
  
  2. Features
    - Tiered pricing (4 levels)
    - Minimum quantities for each price tier
    - Unit type selection
    - WooCommerce integration fields
    - Price range validations
  
  3. Security
    - RLS policies for authenticated access
    - Audit trail via triggers
*/

-- Drop existing table if it exists
DROP TABLE IF EXISTS products CASCADE;

-- Create products table
CREATE TABLE products (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  sku VARCHAR(100) NOT NULL,
  name VARCHAR(255) NOT NULL,
  regular_price DECIMAL(10,2) NOT NULL DEFAULT 0,
  price_2 DECIMAL(10,2) NOT NULL DEFAULT 0,
  price_3 DECIMAL(10,2) NOT NULL DEFAULT 0,
  price_4 DECIMAL(10,2) NOT NULL DEFAULT 0,
  unit_type VARCHAR(50) DEFAULT 'unidades' CHECK (
    unit_type IN (
      'unidades', 'paquetes', 'millares', 'rollos', 'kilos',
      'bolsas', 'cajas', 'metros', 'litros', 'docenas', 'otro'
    )
  ),
  custom_unit_type VARCHAR(50),
  min_quantities JSONB DEFAULT '{
    "price_2": 100,
    "price_3": 500,
    "price_4": 1000
  }'::jsonb,
  price_ranges JSONB DEFAULT '{
    "price_2": {"from": null, "to": null},
    "price_3": {"from": null, "to": null},
    "price_4": {"from": null, "to": null}
  }'::jsonb,
  show_prices JSONB DEFAULT '{
    "price_2": true,
    "price_3": true,
    "price_4": true
  }'::jsonb,
  woo_id INTEGER,
  woo_status VARCHAR(50),
  woo_last_sync TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  CONSTRAINT products_sku_key UNIQUE (sku),
  CONSTRAINT check_price_hierarchy CHECK (
    regular_price >= price_2 AND
    price_2 >= price_3 AND
    price_3 >= price_4
  )
);

-- Create indexes
CREATE INDEX idx_products_sku ON products(sku);
CREATE INDEX idx_products_woo_id ON products(woo_id);
CREATE INDEX idx_products_woo_status ON products(woo_status);

-- Enable RLS
ALTER TABLE products ENABLE ROW LEVEL SECURITY;

-- Create RLS policies
CREATE POLICY "Authenticated users can read products"
  ON products FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Authenticated users can update products"
  ON products FOR UPDATE
  TO authenticated
  USING (true);

-- Create trigger for updated_at
CREATE TRIGGER update_products_updated_at
  BEFORE UPDATE ON products
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Insert test data
INSERT INTO products (
  sku, 
  name, 
  regular_price, 
  price_2, 
  price_3, 
  price_4,
  unit_type,
  price_ranges
)
VALUES 
  (
    'BOL-001', 
    'Bolsa Standard 20x30', 
    100.00, 90.00, 80.00, 70.00,
    'bolsas',
    '{
      "price_2": {"from": 100, "to": 499},
      "price_3": {"from": 500, "to": 999},
      "price_4": {"from": 1000, "to": null}
    }'
  ),
  (
    'BOL-002', 
    'Bolsa Premium 25x35', 
    150.00, 135.00, 120.00, 105.00,
    'bolsas',
    '{
      "price_2": {"from": 100, "to": 499},
      "price_3": {"from": 500, "to": 999},
      "price_4": {"from": 1000, "to": null}
    }'
  ),
  (
    'BOL-003', 
    'Bolsa Eco 15x25', 
    80.00, 72.00, 64.00, 56.00,
    'bolsas',
    '{
      "price_2": {"from": 100, "to": 499},
      "price_3": {"from": 500, "to": 999},
      "price_4": {"from": 1000, "to": null}
    }'
  ),
  (
    'BOL-004', 
    'Bolsa Kraft 30x40', 
    200.00, 180.00, 160.00, 140.00,
    'bolsas',
    '{
      "price_2": {"from": 100, "to": 499},
      "price_3": {"from": 500, "to": 999},
      "price_4": {"from": 1000, "to": null}
    }'
  ),
  (
    'BOL-005', 
    'Bolsa Biodegradable 20x30', 
    120.00, 108.00, 96.00, 84.00,
    'bolsas',
    '{
      "price_2": {"from": 100, "to": 499},
      "price_3": {"from": 500, "to": 999},
      "price_4": {"from": 1000, "to": null}
    }'
  )
ON CONFLICT ON CONSTRAINT products_sku_key DO UPDATE SET
  name = EXCLUDED.name,
  regular_price = EXCLUDED.regular_price,
  price_2 = EXCLUDED.price_2,
  price_3 = EXCLUDED.price_3,
  price_4 = EXCLUDED.price_4,
  unit_type = EXCLUDED.unit_type,
  price_ranges = EXCLUDED.price_ranges,
  updated_at = NOW();

-- Grant permissions
GRANT SELECT, UPDATE ON products TO authenticated;