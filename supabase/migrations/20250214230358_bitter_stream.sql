/*
  # Client Tracking System Implementation

  1. New Tables
    - client_tracking (base table for storing tracking metrics)
    - client_alerts (for tracking alerts and notifications)

  2. Views
    - client_tracking_metrics (aggregated view of client tracking)
    - pending_alerts (filtered view for pending alerts)

  3. Functions and Triggers
    - Automatic calculation of days without interaction
    - Alert level determination
    - Alert status management
*/

-- Create base tracking table
CREATE TABLE IF NOT EXISTS client_tracking (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  client_id UUID REFERENCES clients(id) ON DELETE CASCADE,
  interaction_range TEXT NOT NULL,
  client_count INTEGER NOT NULL DEFAULT 0,
  percentage DECIMAL(5,2) NOT NULL DEFAULT 0,
  last_interaction_date TIMESTAMPTZ,
  days_without_interaction INTEGER,
  alert_level TEXT CHECK (alert_level IN ('normal', 'medium', 'high', 'critical')),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create alerts table
CREATE TABLE IF NOT EXISTS client_alerts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  client_id UUID REFERENCES clients(id) ON DELETE CASCADE,
  alert_level TEXT NOT NULL CHECK (alert_level IN ('normal', 'medium', 'high', 'critical')),
  alert_status TEXT NOT NULL CHECK (alert_status IN ('pending', 'sent', 'read')) DEFAULT 'pending',
  message TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_client_tracking_client ON client_tracking(client_id);
CREATE INDEX IF NOT EXISTS idx_client_tracking_range ON client_tracking(interaction_range);
CREATE INDEX IF NOT EXISTS idx_client_tracking_alert ON client_tracking(alert_level);
CREATE INDEX IF NOT EXISTS idx_client_alerts_status ON client_alerts(alert_status);
CREATE INDEX IF NOT EXISTS idx_client_alerts_level ON client_alerts(alert_level);

-- Function to calculate days without interaction
CREATE OR REPLACE FUNCTION calculate_days_without_interaction(last_date TIMESTAMPTZ)
RETURNS INTEGER AS $$
BEGIN
  RETURN EXTRACT(DAY FROM NOW() - last_date)::INTEGER;
END;
$$ LANGUAGE plpgsql;

-- Function to determine alert level
CREATE OR REPLACE FUNCTION determine_alert_level(days_without INTEGER)
RETURNS TEXT AS $$
BEGIN
  RETURN CASE
    WHEN days_without >= 90 THEN 'critical'
    WHEN days_without >= 60 THEN 'high'
    WHEN days_without >= 30 THEN 'medium'
    ELSE 'normal'
  END;
END;
$$ LANGUAGE plpgsql;

-- Function to update tracking metrics
CREATE OR REPLACE FUNCTION update_client_tracking()
RETURNS TRIGGER AS $$
BEGIN
  -- Update days without interaction
  NEW.days_without_interaction := calculate_days_without_interaction(NEW.last_interaction_date);
  
  -- Update alert level
  NEW.alert_level := determine_alert_level(NEW.days_without_interaction);
  
  -- Create alert if level changed to higher severity
  IF NEW.alert_level != OLD.alert_level AND 
     NEW.alert_level IN ('medium', 'high', 'critical') THEN
    INSERT INTO client_alerts (
      client_id,
      alert_level,
      message
    ) VALUES (
      NEW.client_id,
      NEW.alert_level,
      CASE NEW.alert_level
        WHEN 'critical' THEN 'Cliente sin interacción por más de 90 días'
        WHEN 'high' THEN 'Cliente sin interacción por más de 60 días'
        WHEN 'medium' THEN 'Cliente sin interacción por más de 30 días'
      END
    );
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for automatic updates
DROP TRIGGER IF EXISTS update_client_tracking_trigger ON client_tracking;
CREATE TRIGGER update_client_tracking_trigger
  BEFORE UPDATE ON client_tracking
  FOR EACH ROW
  EXECUTE FUNCTION update_client_tracking();

-- Create view for tracking metrics
CREATE OR REPLACE VIEW client_tracking_metrics AS
SELECT 
  t.*,
  c.name as client_name,
  c.company as client_company,
  c.assigned_agent_id,
  a.name as agent_name,
  a.email as agent_email
FROM client_tracking t
JOIN clients c ON t.client_id = c.id
LEFT JOIN agents a ON c.assigned_agent_id = a.id;

-- Create view for pending alerts
CREATE OR REPLACE VIEW pending_alerts AS
SELECT 
  al.*,
  c.name as client_name,
  c.company as client_company,
  c.assigned_agent_id,
  a.name as agent_name,
  a.email as agent_email,
  t.days_without_interaction
FROM client_alerts al
JOIN clients c ON al.client_id = c.id
LEFT JOIN agents a ON c.assigned_agent_id = a.id
LEFT JOIN client_tracking t ON al.client_id = t.client_id
WHERE 
  al.alert_status = 'pending'
ORDER BY 
  CASE al.alert_level
    WHEN 'critical' THEN 1
    WHEN 'high' THEN 2
    WHEN 'medium' THEN 3
    ELSE 4
  END;

-- Enable RLS
ALTER TABLE client_tracking ENABLE ROW LEVEL SECURITY;
ALTER TABLE client_alerts ENABLE ROW LEVEL SECURITY;

-- Create RLS policies
CREATE POLICY "Authenticated users can read tracking"
  ON client_tracking FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Authenticated users can read alerts"
  ON client_alerts FOR SELECT
  TO authenticated
  USING (true);

-- Grant permissions
GRANT SELECT ON client_tracking_metrics TO authenticated;
GRANT SELECT ON pending_alerts TO authenticated;