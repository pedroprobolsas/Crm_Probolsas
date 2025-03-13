-- Drop existing view if it exists
DROP VIEW IF EXISTS quote_summaries;

-- Create quote_summaries view
CREATE OR REPLACE VIEW quote_summaries AS
SELECT 
  q.id,
  q.quote_number,
  q.client_id,
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