/*
  # Product Configuration Schema

  1. New Tables
    - `product_settings`: Stores WooCommerce and sync configuration
    - `sync_logs`: Tracks synchronization history
    - `price_changes`: Tracks price update history

  2. Security
    - Enable RLS on all tables
    - Add policies for authenticated users
*/

-- Create product_settings table
CREATE TABLE IF NOT EXISTS product_settings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  setting_type VARCHAR(50) NOT NULL,
  setting_key VARCHAR(100) NOT NULL,
  setting_value TEXT,
  is_encrypted BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(setting_type, setting_key)
);

-- Create sync_logs table
CREATE TABLE IF NOT EXISTS sync_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  sync_type VARCHAR(50),
  status VARCHAR(20),
  start_time TIMESTAMPTZ DEFAULT NOW(),
  end_time TIMESTAMPTZ,
  records_processed INTEGER,
  errors TEXT[],
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create price_changes table
CREATE TABLE IF NOT EXISTS price_changes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  product_id UUID NOT NULL,
  sku VARCHAR(100) NOT NULL,
  field_name VARCHAR(50) NOT NULL,
  old_value DECIMAL(10,2),
  new_value DECIMAL(10,2),
  changed_by UUID REFERENCES auth.users(id),
  changed_at TIMESTAMPTZ DEFAULT NOW(),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_product_settings_type_key ON product_settings(setting_type, setting_key);
CREATE INDEX IF NOT EXISTS idx_sync_logs_created ON sync_logs(created_at);
CREATE INDEX IF NOT EXISTS idx_price_changes_product ON price_changes(product_id);
CREATE INDEX IF NOT EXISTS idx_price_changes_sku ON price_changes(sku);
CREATE INDEX IF NOT EXISTS idx_price_changes_changed_at ON price_changes(changed_at);

-- Enable RLS
ALTER TABLE product_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE sync_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE price_changes ENABLE ROW LEVEL SECURITY;

-- Create RLS policies
CREATE POLICY "Authenticated users can read product settings"
  ON product_settings FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Authenticated users can update product settings"
  ON product_settings FOR UPDATE
  TO authenticated
  USING (true);

CREATE POLICY "Authenticated users can read sync logs"
  ON sync_logs FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Authenticated users can insert sync logs"
  ON sync_logs FOR INSERT
  TO authenticated
  WITH CHECK (true);

CREATE POLICY "Authenticated users can read price changes"
  ON price_changes FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Authenticated users can insert price changes"
  ON price_changes FOR INSERT
  TO authenticated
  WITH CHECK (true);

-- Create function to update updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create triggers
CREATE TRIGGER update_product_settings_updated_at
  BEFORE UPDATE ON product_settings
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Insert initial settings
INSERT INTO product_settings (setting_type, setting_key, setting_value, is_encrypted) VALUES
  ('woocommerce', 'api_url', 'https://empaques.probolsas.com', false),
  ('woocommerce', 'consumer_key', '', true),
  ('woocommerce', 'consumer_secret', '', true),
  ('sync', 'interval_minutes', '60', false),
  ('sync', 'last_sync', '', false)
ON CONFLICT (setting_type, setting_key) DO NOTHING;

-- Grant permissions
GRANT SELECT, INSERT, UPDATE ON product_settings TO authenticated;
GRANT SELECT, INSERT ON sync_logs TO authenticated;
GRANT SELECT, INSERT ON price_changes TO authenticated;