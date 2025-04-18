/*
  # Creación de la tabla message_whatsapp_status
  
  Esta tabla permite rastrear el estado de envío de mensajes a WhatsApp
  sin modificar directamente los mensajes en la tabla messages.
*/

-- Crear tabla para rastrear el estado de envío a WhatsApp
CREATE TABLE IF NOT EXISTS message_whatsapp_status (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  message_id UUID REFERENCES messages(id) ON DELETE CASCADE,
  sent_to_whatsapp BOOLEAN DEFAULT FALSE,
  sent_at TIMESTAMPTZ,
  delivery_status TEXT,
  error_message TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Crear índice para búsquedas rápidas por message_id
CREATE INDEX IF NOT EXISTS idx_message_whatsapp_status_message_id ON message_whatsapp_status(message_id);

-- Crear función para actualizar el campo updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
   NEW.updated_at = NOW();
   RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Crear trigger para actualizar el campo updated_at
CREATE TRIGGER update_message_whatsapp_status_updated_at
  BEFORE UPDATE ON message_whatsapp_status
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Comentario para explicar la tabla
COMMENT ON TABLE message_whatsapp_status IS 
'Tabla para rastrear el estado de envío de mensajes a WhatsApp sin modificar directamente los mensajes en la tabla messages.';

-- Comentarios para explicar los campos
COMMENT ON COLUMN message_whatsapp_status.id IS 'Identificador único del registro';
COMMENT ON COLUMN message_whatsapp_status.message_id IS 'Referencia al mensaje en la tabla messages';
COMMENT ON COLUMN message_whatsapp_status.sent_to_whatsapp IS 'Indica si el mensaje fue enviado a WhatsApp';
COMMENT ON COLUMN message_whatsapp_status.sent_at IS 'Fecha y hora en que se envió el mensaje a WhatsApp';
COMMENT ON COLUMN message_whatsapp_status.delivery_status IS 'Estado de entrega del mensaje en WhatsApp';
COMMENT ON COLUMN message_whatsapp_status.error_message IS 'Mensaje de error en caso de que haya fallado el envío';
COMMENT ON COLUMN message_whatsapp_status.created_at IS 'Fecha y hora de creación del registro';
COMMENT ON COLUMN message_whatsapp_status.updated_at IS 'Fecha y hora de la última actualización del registro';

-- Conceder permisos para que la tabla pueda ser accedida por las Edge Functions
GRANT SELECT, INSERT, UPDATE ON message_whatsapp_status TO authenticated;
GRANT SELECT, INSERT, UPDATE ON message_whatsapp_status TO service_role;
