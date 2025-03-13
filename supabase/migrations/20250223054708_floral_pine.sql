-- Drop existing view if it exists
DROP VIEW IF EXISTS quote_summaries;

-- Add terms and notes to quotes table if they don't exist
ALTER TABLE quotes 
ADD COLUMN IF NOT EXISTS terms TEXT,
ADD COLUMN IF NOT EXISTS notes TEXT;

-- Add product_name to quote_items if it doesn't exist
ALTER TABLE quote_items 
ADD COLUMN IF NOT EXISTS product_name TEXT NOT NULL DEFAULT 'Producto sin nombre';

-- Create quote_summaries view with proper item aggregation
CREATE OR REPLACE VIEW quote_summaries AS
WITH quote_items_json AS (
  SELECT 
    quote_id,
    json_agg(
      json_build_object(
        'id', id,
        'product_id', product_id,
        'product_name', product_name,
        'quantity', quantity,
        'unit_price', unit_price,
        'total_price', total_price,
        'notes', notes
      )
    ) as items,
    COUNT(*) as item_count
  FROM quote_items
  GROUP BY quote_id
)
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
  COALESCE(qi.items, '[]'::json) as items,
  COALESCE(qi.item_count, 0) as item_count,
  CASE
    WHEN q.valid_until < NOW() THEN 'expired'
    WHEN q.valid_until < NOW() + INTERVAL '7 days' THEN 'expiring_soon'
    ELSE 'valid'
  END as validity_status
FROM quotes q
JOIN clients c ON q.client_id = c.id
LEFT JOIN agents a ON q.agent_id = a.id
LEFT JOIN quote_items_json qi ON q.id = qi.quote_id;

-- Grant permissions
GRANT SELECT ON quote_summaries TO authenticated;