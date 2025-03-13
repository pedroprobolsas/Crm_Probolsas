/*
  # Test Data for Client Tracking System

  1. Purpose
    - Insert test data for client tracking and alerts
    - Cover different alert scenarios
    - Provide realistic testing data

  2. Data Scenarios
    - Clients with varying interaction gaps
    - Different alert levels
    - Multiple alert statuses
*/

-- Insert test data for client tracking
INSERT INTO client_tracking (
  client_id,
  interaction_range,
  client_count,
  percentage,
  last_interaction_date,
  days_without_interaction,
  alert_level
)
SELECT
  c.id,
  CASE
    WHEN n = 1 THEN '0-30'
    WHEN n = 2 THEN '31-60'
    WHEN n = 3 THEN '61-90'
    ELSE '90+'
  END as interaction_range,
  1 as client_count,
  25.0 as percentage,
  CASE
    WHEN n = 1 THEN NOW() - INTERVAL '15 days'
    WHEN n = 2 THEN NOW() - INTERVAL '45 days'
    WHEN n = 3 THEN NOW() - INTERVAL '75 days'
    ELSE NOW() - INTERVAL '95 days'
  END as last_interaction_date,
  CASE
    WHEN n = 1 THEN 15
    WHEN n = 2 THEN 45
    WHEN n = 3 THEN 75
    ELSE 95
  END as days_without_interaction,
  CASE
    WHEN n = 1 THEN 'normal'
    WHEN n = 2 THEN 'medium'
    WHEN n = 3 THEN 'high'
    ELSE 'critical'
  END as alert_level
FROM clients c
CROSS JOIN generate_series(1, 4) n
WHERE c.id IN (
  SELECT id FROM clients 
  ORDER BY created_at 
  LIMIT 4
)
ON CONFLICT DO NOTHING;

-- Insert test alerts
INSERT INTO client_alerts (
  client_id,
  alert_level,
  alert_status,
  message
)
SELECT
  t.client_id,
  t.alert_level,
  CASE
    WHEN t.alert_level = 'critical' THEN 'pending'
    WHEN t.alert_level = 'high' THEN 'sent'
    ELSE 'read'
  END as alert_status,
  CASE
    WHEN t.alert_level = 'critical' THEN 'Cliente sin interacción por más de 90 días'
    WHEN t.alert_level = 'high' THEN 'Cliente sin interacción por más de 60 días'
    WHEN t.alert_level = 'medium' THEN 'Cliente sin interacción por más de 30 días'
    ELSE 'Cliente activo'
  END as message
FROM client_tracking t
WHERE t.alert_level != 'normal'
ON CONFLICT DO NOTHING;

-- Update client last interaction dates to match tracking
UPDATE clients c
SET 
  last_interaction_date = t.last_interaction_date,
  updated_at = NOW()
FROM client_tracking t
WHERE c.id = t.client_id;