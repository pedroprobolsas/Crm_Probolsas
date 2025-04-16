/*
  # Creación de la Tabla message_whatsapp_status

  Esta tabla se utiliza para rastrear el estado de envío a WhatsApp de los mensajes,
  evitando modificar los mensajes originales en la tabla messages.
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

-- Verificar si la función update_updated_at_column existe
DO $$
DECLARE
  func_exists BOOLEAN;
BEGIN
  SELECT EXISTS (
    SELECT 1
    FROM pg_proc p
    JOIN pg_namespace n ON p.pronamespace = n.oid
    WHERE p.proname = 'update_updated_at_column' AND n.nspname = 'public'
  ) INTO func_exists;
  
  IF NOT func_exists THEN
    -- Crear la función update_updated_at_column si no existe
    EXECUTE '
    CREATE OR REPLACE FUNCTION update_updated_at_column()
    RETURNS TRIGGER AS $$
    BEGIN
        NEW.updated_at = NOW();
        RETURN NEW;
    END;
    $$ LANGUAGE plpgsql;
    ';
    
    RAISE NOTICE 'Función update_updated_at_column creada.';
  ELSE
    RAISE NOTICE 'La función update_updated_at_column ya existe.';
  END IF;
END;
$$;

-- Crear trigger para actualizar updated_at
DO $$
DECLARE
  trigger_exists BOOLEAN;
BEGIN
  SELECT EXISTS (
    SELECT 1
    FROM pg_trigger t
    JOIN pg_class c ON t.tgrelid = c.oid
    WHERE t.tgname = 'update_message_whatsapp_status_updated_at' AND c.relname = 'message_whatsapp_status'
  ) INTO trigger_exists;
  
  IF NOT trigger_exists THEN
    -- Crear el trigger si no existe
    EXECUTE '
    CREATE TRIGGER update_message_whatsapp_status_updated_at
    BEFORE UPDATE ON message_whatsapp_status
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();
    ';
    
    RAISE NOTICE 'Trigger update_message_whatsapp_status_updated_at creado.';
  ELSE
    RAISE NOTICE 'El trigger update_message_whatsapp_status_updated_at ya existe.';
  END IF;
END;
$$;

-- Verificar si la tabla se creó correctamente
DO $$
BEGIN
  IF EXISTS (
    SELECT 1
    FROM information_schema.tables
    WHERE table_schema = 'public' AND table_name = 'message_whatsapp_status'
  ) THEN
    RAISE NOTICE 'La tabla message_whatsapp_status se ha creado correctamente.';
  ELSE
    RAISE WARNING 'Error al crear la tabla message_whatsapp_status.';
  END IF;
END;
$$;

-- Instrucciones para el uso de la tabla
DO $$
BEGIN
  RAISE NOTICE '
La tabla message_whatsapp_status se ha creado para rastrear el estado de envío a WhatsApp de los mensajes.
Esta tabla se utilizará en lugar de modificar los mensajes originales en la tabla messages.

Para usar esta tabla:
1. Actualiza la Edge Function messages-outgoing según las instrucciones en README-edge-functions.md
2. Verifica que los mensajes de agentes se procesen correctamente
3. Verifica que los mensajes de clientes con asistente_ia_activado=true lleguen al webhook de IA
';
END;
$$;
