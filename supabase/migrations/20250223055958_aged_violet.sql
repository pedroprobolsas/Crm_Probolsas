-- Drop existing views and tables
DROP VIEW IF EXISTS quote_summaries;
DROP MATERIALIZED VIEW IF EXISTS quote_items_aggregated;
DROP TABLE IF EXISTS quote_items CASCADE;
DROP TABLE IF EXISTS quotes CASCADE;

-- Create quotes table
CREATE TABLE quotes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  quote_number TEXT UNIQUE NOT NULL,
  client_id UUID REFERENCES clients(id) ON DELETE CASCADE,
  agent_id UUID REFERENCES agents(id),
  status TEXT NOT NULL CHECK (status IN ('draft', 'sent', 'approved', 'rejected')),
  total_amount DECIMAL(12,2) NOT NULL DEFAULT 0,
  valid_until TIMESTAMPTZ NOT NULL,
  terms TEXT,
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create quote items table
CREATE TABLE quote_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  quote_id UUID REFERENCES quotes(id) ON DELETE CASCADE,
  product_id UUID REFERENCES products(id),
  product_name TEXT NOT NULL,
  quantity DECIMAL(10,2) NOT NULL CHECK (quantity > 0),
  unit_price DECIMAL(10,2) NOT NULL CHECK (unit_price >= 0),
  total_price DECIMAL(12,2) GENERATED ALWAYS AS (quantity * unit_price) STORED,
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create indexes
CREATE INDEX idx_quotes_client ON quotes(client_id);
CREATE INDEX idx_quotes_agent ON quotes(agent_id);
CREATE INDEX idx_quotes_status ON quotes(status);
CREATE INDEX idx_quote_items_quote ON quote_items(quote_id);
CREATE INDEX idx_quote_items_product ON quote_items(product_id);

-- Enable RLS
ALTER TABLE quotes ENABLE ROW LEVEL SECURITY;
ALTER TABLE quote_items ENABLE ROW LEVEL SECURITY;

-- Create RLS policies
CREATE POLICY "Authenticated users can read quotes"
  ON quotes FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Agents can create quotes"
  ON quotes FOR INSERT
  TO authenticated
  WITH CHECK (true);

CREATE POLICY "Agents can update their own quotes"
  ON quotes FOR UPDATE
  TO authenticated
  USING (
    agent_id = auth.uid() OR
    EXISTS (
      SELECT 1 FROM agents
      WHERE agents.id = auth.uid()
      AND agents.role = 'admin'
    )
  );

-- Quote items policies
CREATE POLICY "Authenticated users can read quote items"
  ON quote_items FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Agents can manage quote items"
  ON quote_items FOR ALL
  TO authenticated
  USING (true);

-- Create function to update quote total
CREATE OR REPLACE FUNCTION update_quote_total()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'DELETE' THEN
    UPDATE quotes
    SET 
      total_amount = (
        SELECT COALESCE(SUM(total_price), 0)
        FROM quote_items
        WHERE quote_id = OLD.quote_id
      ),
      updated_at = NOW()
    WHERE id = OLD.quote_id;
    RETURN OLD;
  ELSE
    UPDATE quotes
    SET 
      total_amount = (
        SELECT COALESCE(SUM(total_price), 0)
        FROM quote_items
        WHERE quote_id = NEW.quote_id
      ),
      updated_at = NOW()
    WHERE id = NEW.quote_id;
    RETURN NEW;
  END IF;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for quote total updates
CREATE TRIGGER update_quote_total_trigger
  AFTER INSERT OR UPDATE OR DELETE ON quote_items
  FOR EACH ROW
  EXECUTE FUNCTION update_quote_total();

-- Create quote_summaries view
CREATE VIEW quote_summaries AS
SELECT 
  q.id,
  q.quote_number,
  q.client_id,
  q.status,
  q.total_amount,
  q.valid_until,
  q.terms,
  q.notes,
  q.created_at,
  c.name as client_name,
  c.company as client_company,
  a.name as agent_name,
  COALESCE(
    (
      SELECT json_agg(
        json_build_object(
          'id', qi.id,
          'product_id', qi.product_id,
          'product_name', qi.product_name,
          'quantity', qi.quantity,
          'unit_price', qi.unit_price,
          'total_price', qi.total_price,
          'notes', qi.notes
        )
      )
      FROM quote_items qi
      WHERE qi.quote_id = q.id
    ),
    '[]'::json
  ) as items,
  (
    SELECT COUNT(*)
    FROM quote_items qi
    WHERE qi.quote_id = q.id
  ) as item_count,
  CASE
    WHEN q.valid_until < NOW() THEN 'expired'
    WHEN q.valid_until < NOW() + INTERVAL '7 days' THEN 'expiring_soon'
    ELSE 'valid'
  END as validity_status
FROM quotes q
JOIN clients c ON q.client_id = c.id
LEFT JOIN agents a ON q.agent_id = a.id;

-- Grant permissions
GRANT SELECT ON quote_summaries TO authenticated;