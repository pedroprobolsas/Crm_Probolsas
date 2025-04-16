/*
  # Creación de la Tabla message_whatsapp_status
  
  Este script SQL crea la tabla message_whatsapp_status para rastrear el estado de envío a WhatsApp
  de los mensajes, evitando modificar los mensajes originales en la tabla messages.
  
  Este script es parte de la solución para el problema del webhook de IA.
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

-- Crear la función update_updated_at_column si no existe
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_proc p
    JOIN pg_namespace n ON p.pronamespace = n.oid
    WHERE p.proname = 'update_updated_at_column' AND n.nspname = 'public'
  ) THEN
    EXECUTE '
    CREATE OR REPLACE FUNCTION update_updated_at_column()
    RETURNS TRIGGER AS $$
    BEGIN
        NEW.updated_at = NOW();
        RETURN NEW;
    END;
    $$ LANGUAGE plpgsql;
    ';
  END IF;
END $$;

-- Crear trigger para actualizar updated_at
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_trigger t
    JOIN pg_class c ON t.tgrelid = c.oid
    WHERE t.tgname = 'update_message_whatsapp_status_updated_at' AND c.relname = 'message_whatsapp_status'
  ) THEN
    EXECUTE '
    CREATE TRIGGER update_message_whatsapp_status_updated_at
    BEFORE UPDATE ON message_whatsapp_status
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();
    ';
  END IF;
END $$;

-- Verificar si la tabla se creó correctamente
SELECT 
  table_name, 
  column_name, 
  data_type
FROM 
  information_schema.columns
WHERE 
  table_schema = 'public' AND 
  table_name = 'message_whatsapp_status'
ORDER BY 
  ordinal_position;
