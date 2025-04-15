/*
  # Implementación de configuración para el Asistente IA

  1. Propósito
    - Añadir configuración en app_settings para controlar el estado del botón de Asistente IA
    - Permitir que sistemas externos (como n8n) puedan modificar este estado
    - Implementar políticas de seguridad adecuadas
    
  2. Características
    - Añade un registro en app_settings para el estado del Asistente IA
    - Configura políticas RLS para permitir actualizaciones desde servicios externos
    - Crea una tabla de auditoría para registrar cambios en la configuración
*/

-- 1. Asegurarse de que la tabla app_settings existe
CREATE TABLE IF NOT EXISTS app_settings (
  key TEXT PRIMARY KEY,
  value TEXT NOT NULL,
  description TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 2. Añadir el registro para el estado del Asistente IA
INSERT INTO app_settings (key, value, description) VALUES
('ia_assistant_enabled', 'true', 'Estado global del botón de Asistente IA (true/false)')
ON CONFLICT (key) DO UPDATE 
SET value = EXCLUDED.value,
    description = EXCLUDED.description,
    updated_at = now();

-- 3. Crear tabla de auditoría para cambios en la configuración
CREATE TABLE IF NOT EXISTS app_settings_audit (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  key TEXT NOT NULL,
  old_value TEXT,
  new_value TEXT NOT NULL,
  changed_by TEXT NOT NULL, -- user_id o 'system' o 'n8n'
  reason TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 4. Crear función para registrar cambios en app_settings
CREATE OR REPLACE FUNCTION log_app_settings_changes()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO app_settings_audit (
    key, 
    old_value, 
    new_value, 
    changed_by,
    reason
  ) VALUES (
    NEW.key,
    OLD.value,
    NEW.value,
    COALESCE(auth.uid()::text, 'system'),
    'Actualización manual o automática'
  );
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 5. Crear trigger para la función de auditoría
DROP TRIGGER IF EXISTS app_settings_audit_trigger ON app_settings;

CREATE TRIGGER app_settings_audit_trigger
AFTER UPDATE ON app_settings
FOR EACH ROW
WHEN (OLD.value IS DISTINCT FROM NEW.value)
EXECUTE FUNCTION log_app_settings_changes();

-- 6. Crear políticas RLS para app_settings
ALTER TABLE app_settings ENABLE ROW LEVEL SECURITY;

-- Política para permitir lectura a todos los usuarios autenticados
CREATE POLICY "Allow authenticated users to read app_settings"
ON app_settings
FOR SELECT
USING (auth.role() = 'authenticated');

-- Política para permitir actualizaciones a administradores
CREATE POLICY "Allow admins to update app_settings"
ON app_settings
FOR UPDATE
USING (auth.role() = 'authenticated' AND EXISTS (
  SELECT 1 FROM agents 
  WHERE agents.id = auth.uid() 
  AND agents.role = 'admin'
));

-- Política especial para permitir actualizaciones al registro ia_assistant_enabled desde servicios externos
-- Nota: Esta política es permisiva para facilitar la integración con n8n
-- En un entorno de producción, se recomienda implementar autenticación adicional
CREATE POLICY "Allow external services to update IA settings"
ON app_settings
FOR UPDATE
USING (key = 'ia_assistant_enabled')
WITH CHECK (key = 'ia_assistant_enabled');

-- 7. Crear función para actualizar el estado del Asistente IA (para uso desde n8n)
CREATE OR REPLACE FUNCTION update_ia_assistant_state(new_state BOOLEAN, update_reason TEXT DEFAULT 'Actualización desde n8n')
RETURNS JSONB AS $$
DECLARE
  result JSONB;
BEGIN
  -- Actualizar el estado
  UPDATE app_settings
  SET value = new_state::TEXT,
      updated_at = now()
  WHERE key = 'ia_assistant_enabled';
  
  -- Registrar en la auditoría con razón específica
  INSERT INTO app_settings_audit (
    key,
    old_value,
    new_value,
    changed_by,
    reason
  ) VALUES (
    'ia_assistant_enabled',
    (SELECT value FROM app_settings WHERE key = 'ia_assistant_enabled'),
    new_state::TEXT,
    'n8n',
    update_reason
  );
  
  -- Devolver resultado
  result := jsonb_build_object(
    'success', TRUE,
    'message', 'Estado del Asistente IA actualizado correctamente',
    'new_state', new_state,
    'timestamp', now()
  );
  
  RETURN result;
EXCEPTION WHEN OTHERS THEN
  result := jsonb_build_object(
    'success', FALSE,
    'message', 'Error al actualizar el estado del Asistente IA: ' || SQLERRM,
    'error', SQLERRM
  );
  
  RETURN result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 8. Crear función para consultar el estado actual del Asistente IA (para uso desde n8n)
CREATE OR REPLACE FUNCTION get_ia_assistant_state()
RETURNS JSONB AS $$
DECLARE
  current_state TEXT;
  result JSONB;
BEGIN
  -- Obtener el estado actual
  SELECT value INTO current_state
  FROM app_settings
  WHERE key = 'ia_assistant_enabled';
  
  -- Devolver resultado
  result := jsonb_build_object(
    'success', TRUE,
    'state', current_state = 'true',
    'timestamp', now()
  );
  
  RETURN result;
EXCEPTION WHEN OTHERS THEN
  result := jsonb_build_object(
    'success', FALSE,
    'message', 'Error al consultar el estado del Asistente IA: ' || SQLERRM,
    'error', SQLERRM
  );
  
  RETURN result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Log the installation
DO $$
BEGIN
  RAISE NOTICE '
  Se ha implementado la configuración para el Asistente IA.
  
  Cambios clave:
  1. Se añadió un registro en app_settings para el estado del Asistente IA
  2. Se creó una tabla de auditoría para registrar cambios en la configuración
  3. Se implementaron políticas RLS para controlar el acceso
  4. Se crearon funciones para actualizar y consultar el estado del Asistente IA
  
  El estado del Asistente IA ahora puede ser controlado desde sistemas externos como n8n.
  ';
END;
$$;
