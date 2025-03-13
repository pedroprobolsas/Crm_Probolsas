/*
  # Add test data for client tracking

  1. Test Data
    - Add sample agents with different roles and statuses
    - Add sample clients with varying interaction dates
    - Add sample conversations to generate tracking metrics

  2. Data Distribution
    - Clients with interactions in last 30 days: ~40%
    - Clients with interactions 31-60 days ago: ~30%
    - Clients with interactions 61-90 days ago: ~20%
    - Clients with no interactions for 90+ days: ~10%

  3. Agent Performance
    - Some agents with high activity (>70% active clients)
    - Some agents with medium activity (40-70% active clients)
    - Some agents with low activity (<40% active clients)
*/

-- Insert test agents
INSERT INTO agents (id, name, email, whatsapp_number, role, status, last_active)
VALUES
  ('11111111-1111-1111-1111-111111111111'::UUID, 'Ana Martínez', 'ana.martinez@probolsas.com', '+525551234567', 'admin', 'online', NOW()),
  ('22222222-2222-2222-2222-222222222222'::UUID, 'Carlos López', 'carlos.lopez@probolsas.com', '+525551234568', 'agent', 'online', NOW()),
  ('33333333-3333-3333-3333-333333333333'::UUID, 'Diana Torres', 'diana.torres@probolsas.com', '+525551234569', 'agent', 'busy', NOW()),
  ('44444444-4444-4444-4444-444444444444'::UUID, 'Eduardo Ruiz', 'eduardo.ruiz@probolsas.com', '+525551234570', 'agent', 'offline', NOW())
ON CONFLICT (email) DO NOTHING;

-- Insert test clients with varying interaction dates
INSERT INTO clients (id, name, email, phone, company, status, last_interaction_date, assigned_agent_id, interaction_count)
SELECT
  gen_random_uuid(),
  'Cliente ' || n,
  'cliente' || n || '@ejemplo.com',
  '+52555' || LPAD(n::text, 7, '0'),
  'Empresa ' || n,
  CASE 
    WHEN n % 4 = 0 THEN 'active'
    WHEN n % 4 = 1 THEN 'inactive'
    WHEN n % 4 = 2 THEN 'at_risk'
    ELSE 'active'
  END,
  CASE
    WHEN n % 10 < 4 THEN NOW() - (n % 30 || ' days')::interval -- Last 30 days
    WHEN n % 10 < 7 THEN NOW() - (30 + (n % 30) || ' days')::interval -- 31-60 days
    WHEN n % 10 < 9 THEN NOW() - (60 + (n % 30) || ' days')::interval -- 61-90 days
    ELSE NOW() - (90 + (n % 30) || ' days')::interval -- 90+ days
  END,
  CASE
    WHEN n % 4 = 0 THEN '11111111-1111-1111-1111-111111111111'::UUID
    WHEN n % 4 = 1 THEN '22222222-2222-2222-2222-222222222222'::UUID
    WHEN n % 4 = 2 THEN '33333333-3333-3333-3333-333333333333'::UUID
    ELSE '44444444-4444-4444-4444-444444444444'::UUID
  END,
  floor(random() * 20)::int
FROM generate_series(1, 100) n
ON CONFLICT DO NOTHING;

-- Insert test conversations with varying dates and types
INSERT INTO conversations (id, client_id, agent_id, whatsapp_chat_id, last_message, last_message_at, created_at, interaction_type)
SELECT
  gen_random_uuid(),
  c.id,
  c.assigned_agent_id,
  'chat_' || n,
  CASE 
    WHEN n % 4 = 0 THEN '¿Podrían enviarme una cotización?'
    WHEN n % 4 = 1 THEN 'Gracias por la información'
    WHEN n % 4 = 2 THEN 'Necesito hacer un pedido'
    ELSE 'Tengo una consulta sobre el producto'
  END,
  c.last_interaction_date,
  c.last_interaction_date,
  CASE
    WHEN n % 5 = 0 THEN 'inquiry'
    WHEN n % 5 = 1 THEN 'quote'
    WHEN n % 5 = 2 THEN 'support'
    WHEN n % 5 = 3 THEN 'follow_up'
    ELSE 'other'
  END
FROM clients c
CROSS JOIN generate_series(1, 3) n
ON CONFLICT DO NOTHING;