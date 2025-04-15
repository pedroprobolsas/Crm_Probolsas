/*
  # Prueba de la configuración del Asistente IA

  Este script verifica la configuración del Asistente IA y prueba las funciones
  creadas para consultar y actualizar su estado.
*/

-- 1. Verificar que el registro existe en app_settings
SELECT 
  key, 
  value, 
  description, 
  created_at, 
  updated_at
FROM 
  app_settings
WHERE 
  key = 'ia_assistant_enabled';

-- 2. Verificar que la tabla de auditoría existe
SELECT 
  table_name, 
  column_name, 
  data_type
FROM 
  information_schema.columns
WHERE 
  table_name = 'app_settings_audit'
ORDER BY 
  ordinal_position;

-- 3. Verificar que las políticas RLS están configuradas correctamente
SELECT 
  schemaname, 
  tablename, 
  policyname, 
  permissive, 
  roles, 
  cmd, 
  qual, 
  with_check
FROM 
  pg_policies
WHERE 
  tablename = 'app_settings'
ORDER BY 
  policyname;

-- 4. Verificar que las funciones existen
SELECT 
  p.proname AS function_name,
  pg_get_function_result(p.oid) AS result_type,
  pg_get_function_arguments(p.oid) AS arguments
FROM 
  pg_proc p
JOIN 
  pg_namespace n ON p.pronamespace = n.oid
WHERE 
  n.nspname = 'public' AND
  (p.proname = 'get_ia_assistant_state' OR p.proname = 'update_ia_assistant_state')
ORDER BY 
  p.proname;

-- 5. Probar la función get_ia_assistant_state
SELECT * FROM get_ia_assistant_state();

-- 6. Probar la función update_ia_assistant_state (desactivar)
SELECT * FROM update_ia_assistant_state(false, 'Prueba de desactivación desde test_ia_assistant_setting.sql');

-- 7. Verificar que el valor se actualizó
SELECT 
  key, 
  value, 
  updated_at
FROM 
  app_settings
WHERE 
  key = 'ia_assistant_enabled';

-- 8. Probar la función update_ia_assistant_state (activar)
SELECT * FROM update_ia_assistant_state(true, 'Prueba de activación desde test_ia_assistant_setting.sql');

-- 9. Verificar que el valor se actualizó de nuevo
SELECT 
  key, 
  value, 
  updated_at
FROM 
  app_settings
WHERE 
  key = 'ia_assistant_enabled';

-- 10. Verificar los registros de auditoría
SELECT 
  id,
  key,
  old_value,
  new_value,
  changed_by,
  reason,
  created_at
FROM 
  app_settings_audit
WHERE 
  key = 'ia_assistant_enabled'
ORDER BY 
  created_at DESC
LIMIT 10;

-- 11. Instrucciones para integración con n8n
RAISE NOTICE '
Para integrar con n8n, puede usar las siguientes funciones:

1. Consultar el estado actual del Asistente IA:
   - Función: get_ia_assistant_state()
   - Ejemplo: SELECT * FROM get_ia_assistant_state();
   - Retorna: {"success": true, "state": true/false, "timestamp": "2025-04-17T09:00:00Z"}

2. Actualizar el estado del Asistente IA:
   - Función: update_ia_assistant_state(new_state BOOLEAN, update_reason TEXT)
   - Ejemplo: SELECT * FROM update_ia_assistant_state(false, "Desactivado por inactividad");
   - Retorna: {"success": true, "message": "Estado del Asistente IA actualizado correctamente", "new_state": false, "timestamp": "2025-04-17T09:00:00Z"}

Estas funciones pueden ser llamadas desde n8n usando la acción "Execute Query" del nodo de Supabase.
';
