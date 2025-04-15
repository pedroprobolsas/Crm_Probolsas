/*
  # Implementación de configuración del Asistente IA por conversación

  1. Propósito
    - Modificar la configuración del Asistente IA para que sea por conversación en lugar de global
    - Permitir que cada conversación tenga su propio estado independiente
    - Mantener un historial de cambios para auditoría
    
  2. Características
    - Crea una nueva tabla conversation_settings para almacenar la configuración por conversación
    - Migra el estado global actual a la nueva estructura
    - Actualiza las funciones para trabajar con el ID de conversación
*/

-- 1. Crear tabla para almacenar la configuración por conversación
CREATE TABLE IF NOT EXISTS conversation_settings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  conversation_id UUID NOT NULL REFERENCES conversations(id) ON DELETE CASCADE,
  ia_assistant_enabled BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(conversation_id)
);

-- 2. Crear índice para búsquedas rápidas por conversation_id
CREATE INDEX IF NOT EXISTS idx_conversation_settings_conversation_id ON conversation_settings(conversation_id);

-- 3. Crear tabla de auditoría para cambios en la configuración por conversación
CREATE TABLE IF NOT EXISTS conversation_settings_audit (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  conversation_id UUID NOT NULL,
  old_value BOOLEAN,
  new_value BOOLEAN NOT NULL,
  changed_by TEXT NOT NULL, -- user_id o 'system' o 'n8n'
  reason TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 4. Crear función para registrar cambios en conversation_settings
CREATE OR REPLACE FUNCTION log_conversation_settings_changes()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO conversation_settings_audit (
    conversation_id, 
    old_value, 
    new_value, 
    changed_by,
    reason
  ) VALUES (
    NEW.conversation_id,
    OLD.ia_assistant_enabled,
    NEW.ia_assistant_enabled,
    COALESCE(auth.uid()::text, 'system'),
    'Actualización manual o automática'
  );
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 5. Crear trigger para la función de auditoría
DROP TRIGGER IF EXISTS conversation_settings_audit_trigger ON conversation_settings;

CREATE TRIGGER conversation_settings_audit_trigger
AFTER UPDATE ON conversation_settings
FOR EACH ROW
WHEN (OLD.ia_assistant_enabled IS DISTINCT FROM NEW.ia_assistant_enabled)
EXECUTE FUNCTION log_conversation_settings_changes();

-- 6. Crear políticas RLS para conversation_settings
ALTER TABLE conversation_settings ENABLE ROW LEVEL SECURITY;

-- Política para permitir lectura a todos los usuarios autenticados
CREATE POLICY "Allow authenticated users to read conversation_settings"
ON conversation_settings
FOR SELECT
USING (auth.role() = 'authenticated');

-- Política para permitir actualizaciones a usuarios autenticados
CREATE POLICY "Allow authenticated users to update conversation_settings"
ON conversation_settings
FOR UPDATE
USING (auth.role() = 'authenticated');

-- Política para permitir inserciones a usuarios autenticados
CREATE POLICY "Allow authenticated users to insert conversation_settings"
ON conversation_settings
FOR INSERT
WITH CHECK (auth.role() = 'authenticated');

-- 7. Crear función para obtener el estado del Asistente IA para una conversación
CREATE OR REPLACE FUNCTION get_conversation_ia_state(conversation_uuid UUID)
RETURNS JSONB AS $$
DECLARE
  current_state BOOLEAN;
  result JSONB;
BEGIN
  -- Intentar obtener el estado actual
  SELECT ia_assistant_enabled INTO current_state
  FROM conversation_settings
  WHERE conversation_id = conversation_uuid;
  
  -- Si no existe un registro para esta conversación, crear uno con el valor predeterminado (true)
  IF current_state IS NULL THEN
    INSERT INTO conversation_settings (conversation_id, ia_assistant_enabled)
    VALUES (conversation_uuid, true)
    RETURNING ia_assistant_enabled INTO current_state;
  END IF;
  
  -- Devolver resultado
  result := jsonb_build_object(
    'success', TRUE,
    'state', current_state,
    'conversation_id', conversation_uuid,
    'timestamp', now()
  );
  
  RETURN result;
EXCEPTION WHEN OTHERS THEN
  result := jsonb_build_object(
    'success', FALSE,
    'message', 'Error al consultar el estado del Asistente IA: ' || SQLERRM,
    'error', SQLERRM,
    'conversation_id', conversation_uuid
  );
  
  RETURN result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 8. Crear función para actualizar el estado del Asistente IA para una conversación
CREATE OR REPLACE FUNCTION update_conversation_ia_state(conversation_uuid UUID, new_state BOOLEAN, update_reason TEXT DEFAULT 'Actualización manual')
RETURNS JSONB AS $$
DECLARE
  result JSONB;
BEGIN
  -- Verificar si existe un registro para esta conversación
  IF NOT EXISTS (SELECT 1 FROM conversation_settings WHERE conversation_id = conversation_uuid) THEN
    -- Si no existe, crear uno
    INSERT INTO conversation_settings (conversation_id, ia_assistant_enabled)
    VALUES (conversation_uuid, new_state);
  ELSE
    -- Si existe, actualizar
    UPDATE conversation_settings
    SET ia_assistant_enabled = new_state,
        updated_at = now()
    WHERE conversation_id = conversation_uuid;
  END IF;
  
  -- Registrar en la auditoría con razón específica
  INSERT INTO conversation_settings_audit (
    conversation_id,
    old_value,
    new_value,
    changed_by,
    reason
  ) VALUES (
    conversation_uuid,
    (SELECT ia_assistant_enabled FROM conversation_settings WHERE conversation_id = conversation_uuid),
    new_state,
    COALESCE(auth.uid()::text, 'system'),
    update_reason
  );
  
  -- Devolver resultado
  result := jsonb_build_object(
    'success', TRUE,
    'message', 'Estado del Asistente IA actualizado correctamente',
    'new_state', new_state,
    'conversation_id', conversation_uuid,
    'timestamp', now()
  );
  
  RETURN result;
EXCEPTION WHEN OTHERS THEN
  result := jsonb_build_object(
    'success', FALSE,
    'message', 'Error al actualizar el estado del Asistente IA: ' || SQLERRM,
    'error', SQLERRM,
    'conversation_id', conversation_uuid
  );
  
  RETURN result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 9. Migrar el estado global actual a la nueva estructura
-- Esto inicializará todas las conversaciones existentes con el valor global actual
DO $$
DECLARE
  global_state BOOLEAN;
  conv_record RECORD;
BEGIN
  -- Obtener el estado global actual
  SELECT (value = 'true') INTO global_state
  FROM app_settings
  WHERE key = 'ia_assistant_enabled';
  
  -- Si no existe, usar true como valor predeterminado
  IF global_state IS NULL THEN
    global_state := true;
  END IF;
  
  -- Aplicar a todas las conversaciones existentes
  FOR conv_record IN SELECT id FROM conversations LOOP
    -- Verificar si ya existe un registro para esta conversación
    IF NOT EXISTS (SELECT 1 FROM conversation_settings WHERE conversation_id = conv_record.id) THEN
      -- Si no existe, crear uno con el estado global
      INSERT INTO conversation_settings (conversation_id, ia_assistant_enabled)
      VALUES (conv_record.id, global_state);
    END IF;
  END LOOP;
  
  RAISE NOTICE 'Migración completada: Se ha inicializado el estado del Asistente IA para todas las conversaciones existentes con el valor global: %', global_state;
END;
$$;

-- Log the installation
DO $$
BEGIN
  RAISE NOTICE '
  Se ha implementado la configuración del Asistente IA por conversación.
  
  Cambios clave:
  1. Se creó una nueva tabla conversation_settings para almacenar la configuración por conversación
  2. Se creó una tabla de auditoría para registrar cambios en la configuración
  3. Se implementaron políticas RLS para controlar el acceso
  4. Se crearon funciones para actualizar y consultar el estado del Asistente IA por conversación
  5. Se migró el estado global actual a la nueva estructura
  
  El estado del Asistente IA ahora es independiente para cada conversación.
  ';
END;
$$;
