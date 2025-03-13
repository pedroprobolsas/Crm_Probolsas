/*
  # Sistema de Seguimiento de Clientes

  1. Nuevas Tablas
    - `client_stages`: Etapas principales del proceso
    - `client_interactions`: Registro de comunicaciones
    - `quotes`: Cotizaciones
    - `quote_items`: Detalles de productos en cotizaciones
    - `deposits`: Registro de anticipos
    - `orders`: Pedidos aprobados
    - `shipments`: Información de despachos
    - `feedback`: Seguimiento post-venta

  2. Cambios
    - Agregar campos de seguimiento a la tabla `clients`
    - Crear vistas para reportes y seguimiento

  3. Seguridad
    - Habilitar RLS en todas las tablas
    - Configurar políticas de acceso
*/

-- Crear enum para tipos de etapas
CREATE TYPE client_stage_type AS ENUM (
  'communication',
  'quotation',
  'deposit',
  'approval',
  'shipping',
  'post_sale'
);

-- Crear enum para tipos de interacción
CREATE TYPE interaction_type AS ENUM (
  'call',
  'email',
  'visit',
  'consultation'
);

-- Crear enum para estados de cotización
CREATE TYPE quote_status AS ENUM (
  'draft',
  'sent',
  'negotiation',
  'accepted',
  'rejected'
);

-- Crear enum para métodos de pago
CREATE TYPE payment_method AS ENUM (
  'transfer',
  'cash',
  'check',
  'credit_card'
);

-- Crear enum para estados de pedido
CREATE TYPE order_status AS ENUM (
  'pending',
  'in_production',
  'ready',
  'delivered',
  'cancelled'
);

-- Tabla de etapas del cliente
CREATE TABLE client_stages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  client_id UUID REFERENCES clients(id) ON DELETE CASCADE,
  stage_type client_stage_type NOT NULL,
  start_date TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  end_date TIMESTAMPTZ,
  status TEXT NOT NULL DEFAULT 'active',
  notes TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Tabla de interacciones
CREATE TABLE client_interactions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  client_id UUID REFERENCES clients(id) ON DELETE CASCADE,
  agent_id UUID REFERENCES agents(id),
  type interaction_type NOT NULL,
  date TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  notes TEXT,
  next_action TEXT,
  next_action_date TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Tabla de cotizaciones
CREATE TABLE quotes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  quote_number TEXT UNIQUE NOT NULL,
  client_id UUID REFERENCES clients(id) ON DELETE CASCADE,
  agent_id UUID REFERENCES agents(id),
  status quote_status NOT NULL DEFAULT 'draft',
  total_amount DECIMAL(12,2) NOT NULL DEFAULT 0,
  valid_until TIMESTAMPTZ,
  notes TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Tabla de items de cotización
CREATE TABLE quote_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  quote_id UUID REFERENCES quotes(id) ON DELETE CASCADE,
  product_id UUID REFERENCES products(id),
  quantity DECIMAL(10,2) NOT NULL,
  unit_price DECIMAL(10,2) NOT NULL,
  total_price DECIMAL(12,2) NOT NULL,
  notes TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Tabla de anticipos
CREATE TABLE deposits (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  client_id UUID REFERENCES clients(id) ON DELETE CASCADE,
  quote_id UUID REFERENCES quotes(id),
  amount DECIMAL(12,2) NOT NULL,
  payment_date TIMESTAMPTZ NOT NULL,
  payment_method payment_method NOT NULL,
  receipt_number TEXT,
  notes TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Tabla de pedidos
CREATE TABLE orders (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_number TEXT UNIQUE NOT NULL,
  client_id UUID REFERENCES clients(id) ON DELETE CASCADE,
  quote_id UUID REFERENCES quotes(id),
  status order_status NOT NULL DEFAULT 'pending',
  approval_date TIMESTAMPTZ,
  specifications TEXT,
  notes TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Tabla de despachos
CREATE TABLE shipments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id UUID REFERENCES orders(id) ON DELETE CASCADE,
  shipping_date TIMESTAMPTZ,
  tracking_number TEXT,
  carrier TEXT,
  status TEXT NOT NULL DEFAULT 'pending',
  delivery_notes TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Tabla de feedback post-venta
CREATE TABLE feedback (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  client_id UUID REFERENCES clients(id) ON DELETE CASCADE,
  order_id UUID REFERENCES orders(id),
  satisfaction_score INTEGER CHECK (satisfaction_score BETWEEN 1 AND 5),
  comments TEXT,
  issues TEXT,
  resolution TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Agregar campos de seguimiento a clientes
ALTER TABLE clients
ADD COLUMN IF NOT EXISTS current_stage client_stage_type,
ADD COLUMN IF NOT EXISTS stage_start_date TIMESTAMPTZ;

-- Crear vista para días en etapa
CREATE OR REPLACE VIEW client_stage_days AS
SELECT 
  id,
  current_stage,
  stage_start_date,
  EXTRACT(DAY FROM NOW() - COALESCE(stage_start_date, created_at)) as days_in_stage
FROM clients;

-- Crear índices
CREATE INDEX idx_client_stages_client ON client_stages(client_id);
CREATE INDEX idx_client_interactions_client ON client_interactions(client_id);
CREATE INDEX idx_quotes_client ON quotes(client_id);
CREATE INDEX idx_orders_client ON orders(client_id);
CREATE INDEX idx_shipments_order ON shipments(order_id);
CREATE INDEX idx_feedback_client ON feedback(client_id);

-- Vista para seguimiento de etapas
CREATE OR REPLACE VIEW client_tracking_summary AS
WITH stage_metrics AS (
  SELECT
    client_id,
    stage_type,
    AVG(EXTRACT(EPOCH FROM (COALESCE(end_date, NOW()) - start_date))/86400) as avg_days_in_stage
  FROM client_stages
  GROUP BY client_id, stage_type
)
SELECT
  c.id as client_id,
  c.name as client_name,
  c.current_stage,
  cd.days_in_stage,
  c.stage_start_date,
  json_build_object(
    'communication', cm.avg_days_in_stage,
    'quotation', qm.avg_days_in_stage,
    'deposit', dm.avg_days_in_stage,
    'approval', am.avg_days_in_stage,
    'shipping', sm.avg_days_in_stage,
    'post_sale', pm.avg_days_in_stage
  ) as stage_metrics,
  (
    SELECT json_build_object(
      'type', type,
      'date', date,
      'next_action', next_action,
      'next_action_date', next_action_date
    )
    FROM client_interactions
    WHERE client_id = c.id
    ORDER BY date DESC
    LIMIT 1
  ) as last_interaction,
  (
    SELECT COUNT(*) FROM quotes q
    WHERE q.client_id = c.id AND q.status = 'sent'
  ) as active_quotes_count
FROM clients c
LEFT JOIN client_stage_days cd ON cd.id = c.id
LEFT JOIN stage_metrics cm ON cm.client_id = c.id AND cm.stage_type = 'communication'
LEFT JOIN stage_metrics qm ON qm.client_id = c.id AND qm.stage_type = 'quotation'
LEFT JOIN stage_metrics dm ON dm.client_id = c.id AND dm.stage_type = 'deposit'
LEFT JOIN stage_metrics am ON am.client_id = c.id AND am.stage_type = 'approval'
LEFT JOIN stage_metrics sm ON sm.client_id = c.id AND sm.stage_type = 'shipping'
LEFT JOIN stage_metrics pm ON pm.client_id = c.id AND pm.stage_type = 'post_sale';

-- Habilitar RLS
ALTER TABLE client_stages ENABLE ROW LEVEL SECURITY;
ALTER TABLE client_interactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE quotes ENABLE ROW LEVEL SECURITY;
ALTER TABLE quote_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE deposits ENABLE ROW LEVEL SECURITY;
ALTER TABLE orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE shipments ENABLE ROW LEVEL SECURITY;
ALTER TABLE feedback ENABLE ROW LEVEL SECURITY;

-- Políticas RLS
CREATE POLICY "Usuarios autenticados pueden leer" ON client_stages FOR SELECT TO authenticated USING (true);
CREATE POLICY "Usuarios autenticados pueden leer" ON client_interactions FOR SELECT TO authenticated USING (true);
CREATE POLICY "Usuarios autenticados pueden leer" ON quotes FOR SELECT TO authenticated USING (true);
CREATE POLICY "Usuarios autenticados pueden leer" ON quote_items FOR SELECT TO authenticated USING (true);
CREATE POLICY "Usuarios autenticados pueden leer" ON deposits FOR SELECT TO authenticated USING (true);
CREATE POLICY "Usuarios autenticados pueden leer" ON orders FOR SELECT TO authenticated USING (true);
CREATE POLICY "Usuarios autenticados pueden leer" ON shipments FOR SELECT TO authenticated USING (true);
CREATE POLICY "Usuarios autenticados pueden leer" ON feedback FOR SELECT TO authenticated USING (true);

-- Triggers para updated_at
CREATE TRIGGER update_client_stages_updated_at
    BEFORE UPDATE ON client_stages
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_client_interactions_updated_at
    BEFORE UPDATE ON client_interactions
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_quotes_updated_at
    BEFORE UPDATE ON quotes
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_quote_items_updated_at
    BEFORE UPDATE ON quote_items
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_deposits_updated_at
    BEFORE UPDATE ON deposits
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_orders_updated_at
    BEFORE UPDATE ON orders
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_shipments_updated_at
    BEFORE UPDATE ON shipments
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_feedback_updated_at
    BEFORE UPDATE ON feedback
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();