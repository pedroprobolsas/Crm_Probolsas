/*
  # Expand Client Information

  1. New Fields
    - Business Information
      - tax_id (NIT)
      - website
      - sector
      - subsector
      - economic_activity
      - business_group
      - segment
      - business_description

    - Key Contacts
      - general_manager_name
      - general_manager_email
      - general_manager_phone
      - general_manager_birthday
      - purchasing_manager_name
      - purchasing_manager_email
      - purchasing_manager_phone
      - purchasing_manager_birthday
      - quality_manager_name
      - quality_manager_email
      - quality_manager_phone
      - quality_manager_birthday

    - Fiscal/Legal Information
      - is_large_taxpayer
      - is_self_withholding
      - fiscal_year_end
      - collection_branch
      - trade_associations

    - Commercial Information
      - key_markets
      - key_clients
      - competitors
      - products_services
      - last_year_sales
      - last_year_ebitda
      - current_projects

    - Organizational Information
      - admin_employees_count
      - plant_employees_count
      - mission
      - vision

  2. Security
    - Enable RLS on all new fields
*/

-- Add new fields to clients table
ALTER TABLE clients ADD COLUMN IF NOT EXISTS tax_id TEXT;
ALTER TABLE clients ADD COLUMN IF NOT EXISTS website TEXT;
ALTER TABLE clients ADD COLUMN IF NOT EXISTS sector TEXT;
ALTER TABLE clients ADD COLUMN IF NOT EXISTS subsector TEXT;
ALTER TABLE clients ADD COLUMN IF NOT EXISTS economic_activity TEXT;
ALTER TABLE clients ADD COLUMN IF NOT EXISTS business_group TEXT;
ALTER TABLE clients ADD COLUMN IF NOT EXISTS segment TEXT;
ALTER TABLE clients ADD COLUMN IF NOT EXISTS business_description TEXT;

-- Key Contacts
ALTER TABLE clients ADD COLUMN IF NOT EXISTS general_manager_name TEXT;
ALTER TABLE clients ADD COLUMN IF NOT EXISTS general_manager_email TEXT;
ALTER TABLE clients ADD COLUMN IF NOT EXISTS general_manager_phone TEXT;
ALTER TABLE clients ADD COLUMN IF NOT EXISTS general_manager_birthday DATE;

ALTER TABLE clients ADD COLUMN IF NOT EXISTS purchasing_manager_name TEXT;
ALTER TABLE clients ADD COLUMN IF NOT EXISTS purchasing_manager_email TEXT;
ALTER TABLE clients ADD COLUMN IF NOT EXISTS purchasing_manager_phone TEXT;
ALTER TABLE clients ADD COLUMN IF NOT EXISTS purchasing_manager_birthday DATE;

ALTER TABLE clients ADD COLUMN IF NOT EXISTS quality_manager_name TEXT;
ALTER TABLE clients ADD COLUMN IF NOT EXISTS quality_manager_email TEXT;
ALTER TABLE clients ADD COLUMN IF NOT EXISTS quality_manager_phone TEXT;
ALTER TABLE clients ADD COLUMN IF NOT EXISTS quality_manager_birthday DATE;

-- Fiscal/Legal Information
ALTER TABLE clients ADD COLUMN IF NOT EXISTS is_large_taxpayer BOOLEAN DEFAULT false;
ALTER TABLE clients ADD COLUMN IF NOT EXISTS is_self_withholding BOOLEAN DEFAULT false;
ALTER TABLE clients ADD COLUMN IF NOT EXISTS fiscal_year_end DATE;
ALTER TABLE clients ADD COLUMN IF NOT EXISTS collection_branch TEXT;
ALTER TABLE clients ADD COLUMN IF NOT EXISTS trade_associations TEXT[];

-- Commercial Information
ALTER TABLE clients ADD COLUMN IF NOT EXISTS key_markets TEXT[];
ALTER TABLE clients ADD COLUMN IF NOT EXISTS key_clients TEXT[];
ALTER TABLE clients ADD COLUMN IF NOT EXISTS competitors TEXT[];
ALTER TABLE clients ADD COLUMN IF NOT EXISTS products_services TEXT[];
ALTER TABLE clients ADD COLUMN IF NOT EXISTS last_year_sales DECIMAL(15,2);
ALTER TABLE clients ADD COLUMN IF NOT EXISTS last_year_ebitda DECIMAL(15,2);
ALTER TABLE clients ADD COLUMN IF NOT EXISTS current_projects JSONB DEFAULT '[]'::jsonb;

-- Organizational Information
ALTER TABLE clients ADD COLUMN IF NOT EXISTS admin_employees_count INTEGER;
ALTER TABLE clients ADD COLUMN IF NOT EXISTS plant_employees_count INTEGER;
ALTER TABLE clients ADD COLUMN IF NOT EXISTS mission TEXT;
ALTER TABLE clients ADD COLUMN IF NOT EXISTS vision TEXT;

-- Create indexes for commonly searched fields
CREATE INDEX IF NOT EXISTS idx_clients_tax_id ON clients(tax_id);
CREATE INDEX IF NOT EXISTS idx_clients_sector ON clients(sector);
CREATE INDEX IF NOT EXISTS idx_clients_business_group ON clients(business_group);
CREATE INDEX IF NOT EXISTS idx_clients_segment ON clients(segment);

-- Create a view for client details
CREATE OR REPLACE VIEW client_details AS
SELECT
  c.*,
  COALESCE(c.admin_employees_count, 0) + COALESCE(c.plant_employees_count, 0) as total_employees,
  CASE
    WHEN c.last_year_sales > 0 AND c.last_year_ebitda > 0 
    THEN ROUND((c.last_year_ebitda / c.last_year_sales * 100)::numeric, 2)
    ELSE NULL
  END as ebitda_margin,
  array_length(c.key_markets, 1) as markets_count,
  array_length(c.key_clients, 1) as key_clients_count,
  array_length(c.competitors, 1) as competitors_count,
  jsonb_array_length(c.current_projects) as active_projects_count
FROM clients c;