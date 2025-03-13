-- Create quotes table
CREATE TABLE IF NOT EXISTS quotes (
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
CREATE TABLE IF NOT EXISTS quote_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  quote_id UUID REFERENCES quotes(id) ON DELETE CASCADE,
  product_id UUID REFERENCES products(id),
  product_name TEXT NOT NULL,
  quantity DECIMAL(10,2) NOT NULL CHECK (quantity > 0),
  unit_price DECIMAL(10,2) NOT NULL CHECK (unit_price >= 0),
  total_price DECIMAL(12,2) NOT NULL CHECK (total_price >= 0),
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create quote history table for tracking changes
CREATE TABLE IF NOT EXISTS quote_history (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  quote_id UUID REFERENCES quotes(id) ON DELETE CASCADE,
  agent_id UUID REFERENCES agents(id),
  action TEXT NOT NULL CHECK (action IN ('created', 'updated', 'status_changed')),
  previous_status TEXT,
  new_status TEXT,
  changes JSONB,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_quotes_client ON quotes(client_id);
CREATE INDEX IF NOT EXISTS idx_quotes_agent ON quotes(agent_id);
CREATE INDEX IF NOT EXISTS idx_quotes_status ON quotes(status);
CREATE INDEX IF NOT EXISTS idx_quote_items_quote ON quote_items(quote_id);
CREATE INDEX IF NOT EXISTS idx_quote_items_product ON quote_items(product_id);
CREATE INDEX IF NOT EXISTS idx_quote_history_quote ON quote_history(quote_id);

-- Enable RLS
ALTER TABLE quotes ENABLE ROW LEVEL SECURITY;
ALTER TABLE quote_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE quote_history ENABLE ROW LEVEL SECURITY;

-- Create RLS policies
CREATE POLICY "Authenticated users can read quotes"
  ON quotes FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Agents can create quotes"
  ON quotes FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM agents
      WHERE agents.id = auth.uid()
      AND agents.status != 'inactive'
    )
  );

CREATE POLICY "Agents can update their own quotes"
  ON quotes FOR UPDATE
  TO authenticated
  USING (
    agent_id = auth.uid() AND
    status IN ('draft', 'sent')
  );

-- Quote items policies
CREATE POLICY "Authenticated users can read quote items"
  ON quote_items FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Agents can manage quote items"
  ON quote_items FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM quotes
      WHERE quotes.id = quote_items.quote_id
      AND quotes.agent_id = auth.uid()
      AND quotes.status IN ('draft', 'sent')
    )
  );

-- Quote history policies
CREATE POLICY "Authenticated users can read quote history"
  ON quote_history FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "System can create quote history"
  ON quote_history FOR INSERT
  TO authenticated
  WITH CHECK (true);

-- Create function to update quote total
CREATE OR REPLACE FUNCTION update_quote_total()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE quotes
  SET total_amount = (
    SELECT COALESCE(SUM(total_price), 0)
    FROM quote_items
    WHERE quote_id = NEW.quote_id
  ),
  updated_at = NOW()
  WHERE id = NEW.quote_id;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for quote total updates
CREATE TRIGGER update_quote_total_trigger
  AFTER INSERT OR UPDATE OR DELETE ON quote_items
  FOR EACH ROW
  EXECUTE FUNCTION update_quote_total();

-- Create function to track quote history
CREATE OR REPLACE FUNCTION track_quote_changes()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    INSERT INTO quote_history (
      quote_id,
      agent_id,
      action,
      new_status,
      changes
    ) VALUES (
      NEW.id,
      NEW.agent_id,
      'created',
      NEW.status,
      to_jsonb(NEW)
    );
  ELSIF TG_OP = 'UPDATE' THEN
    IF OLD.status != NEW.status THEN
      INSERT INTO quote_history (
        quote_id,
        agent_id,
        action,
        previous_status,
        new_status,
        changes
      ) VALUES (
        NEW.id,
        NEW.agent_id,
        'status_changed',
        OLD.status,
        NEW.status,
        jsonb_build_object(
          'changed_at', NOW(),
          'old_status', OLD.status,
          'new_status', NEW.status
        )
      );
    ELSE
      INSERT INTO quote_history (
        quote_id,
        agent_id,
        action,
        changes
      ) VALUES (
        NEW.id,
        NEW.agent_id,
        'updated',
        jsonb_build_object(
          'changed_at', NOW(),
          'changes', jsonb_strip_nulls(jsonb_build_object(
            'terms', CASE WHEN NEW.terms != OLD.terms THEN jsonb_build_object('old', OLD.terms, 'new', NEW.terms) ELSE null END,
            'notes', CASE WHEN NEW.notes != OLD.notes THEN jsonb_build_object('old', OLD.notes, 'new', NEW.notes) ELSE null END,
            'valid_until', CASE WHEN NEW.valid_until != OLD.valid_until THEN jsonb_build_object('old', OLD.valid_until, 'new', NEW.valid_until) ELSE null END,
            'total_amount', CASE WHEN NEW.total_amount != OLD.total_amount THEN jsonb_build_object('old', OLD.total_amount, 'new', NEW.total_amount) ELSE null END
          ))
        )
      );
    END IF;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for quote history
CREATE TRIGGER track_quote_changes_trigger
  AFTER INSERT OR UPDATE ON quotes
  FOR EACH ROW
  EXECUTE FUNCTION track_quote_changes();

-- Create function to validate quote status changes
CREATE OR REPLACE FUNCTION validate_quote_status_change()
RETURNS TRIGGER AS $$
BEGIN
  -- Only allow specific status transitions
  IF OLD.status = 'draft' AND NEW.status NOT IN ('sent', 'cancelled') THEN
    RAISE EXCEPTION 'Invalid status transition from draft';
  ELSIF OLD.status = 'sent' AND NEW.status NOT IN ('approved', 'rejected', 'cancelled') THEN
    RAISE EXCEPTION 'Invalid status transition from sent';
  ELSIF OLD.status IN ('approved', 'rejected', 'cancelled') THEN
    RAISE EXCEPTION 'Cannot modify a quote in final status';
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for quote status validation
CREATE TRIGGER validate_quote_status_trigger
  BEFORE UPDATE OF status ON quotes
  FOR EACH ROW
  EXECUTE FUNCTION validate_quote_status_change();

-- Create view for quote summaries
CREATE OR REPLACE VIEW quote_summaries AS
SELECT 
  q.id,
  q.quote_number,
  q.status,
  q.total_amount,
  q.valid_until,
  q.created_at,
  c.name as client_name,
  c.company as client_company,
  a.name as agent_name,
  COUNT(qi.id) as item_count,
  CASE
    WHEN q.valid_until < NOW() THEN 'expired'
    WHEN q.valid_until < NOW() + INTERVAL '7 days' THEN 'expiring_soon'
    ELSE 'valid'
  END as validity_status
FROM quotes q
JOIN clients c ON q.client_id = c.id
LEFT JOIN agents a ON q.agent_id = a.id
LEFT JOIN quote_items qi ON q.id = qi.quote_id
GROUP BY q.id, c.name, c.company, a.name;

-- Grant permissions
GRANT SELECT ON quote_summaries TO authenticated;