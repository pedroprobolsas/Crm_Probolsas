/*
  # Prueba de la configuración del Asistente IA por conversación

  Este script verifica la configuración del Asistente IA por conversación y prueba las funciones
  creadas para consultar y actualizar su estado.
*/

-- 0. Obtener una conversación de ejemplo para las pruebas
WITH sample_conversation AS (
  SELECT id FROM conversations ORDER BY created_at DESC LIMIT 1
)
SELECT id AS conversation_id FROM sample_conversation \gset

-- Mostrar el ID de conversación que se usará para las pruebas
\echo 'Usando conversación con ID: :conversation_id para las pruebas'

-- 1. Verificar que la tabla conversation_settings existe
SELECT 
  table_name, 
  column_name, 
  data_type
FROM 
  information_schema.columns
WHERE 
  table_name = 'conversation_settings'
ORDER BY 
  ordinal_position;

-- 2. Verificar que la tabla de auditoría existe
SELECT 
  table_name, 
  column_name, 
  data_type
FROM 
  information_schema.columns
WHERE 
  table_name = 'conversation_settings_audit'
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
  tablename = 'conversation_settings'
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
  (p.proname = 'get_conversation_ia_state' OR p.proname = 'update_conversation_ia_state')
ORDER BY 
  p.proname;

-- 5. Verificar si ya existe un registro para la conversación de ejemplo
SELECT 
  id, 
  conversation_id, 
  ia_assistant_enabled, 
  created_at, 
  updated_at
FROM 
  conversation_settings
WHERE 
  conversation_id = :'conversation_id';

-- 6. Probar la función get_conversation_ia_state
SELECT * FROM get_conversation_ia_state(:'conversation_id');

-- 7. Probar la función update_conversation_ia_state (desactivar)
SELECT * FROM update_conversation_ia_state(:'conversation_id', false, 'Prueba de desactivación desde test_conversation_ia_settings.sql');

-- 8. Verificar que el valor se actualizó
SELECT 
  id, 
  conversation_id, 
  ia_assistant_enabled, 
  updated_at
FROM 
  conversation_settings
WHERE 
  conversation_id = :'conversation_id';

-- 9. Probar la función update_conversation_ia_state (activar)
SELECT * FROM update_conversation_ia_state(:'conversation_id', true, 'Prueba de activación desde test_conversation_ia_settings.sql');

-- 10. Verificar que el valor se actualizó de nuevo
SELECT 
  id, 
  conversation_id, 
  ia_assistant_enabled, 
  updated_at
FROM 
  conversation_settings
WHERE 
  conversation_id = :'conversation_id';

-- 11. Verificar los registros de auditoría
SELECT 
  id,
  conversation_id,
  old_value,
  new_value,
  changed_by,
  reason,
  created_at
FROM 
  conversation_settings_audit
WHERE 
  conversation_id = :'conversation_id'
ORDER BY 
  created_at DESC
LIMIT 10;

-- 12. Probar con otra conversación (crear una nueva si es necesario)
WITH new_conversation AS (
  INSERT INTO conversations (client_id, agent_id, last_message, last_message_at)
  SELECT 
    (SELECT id FROM clients ORDER BY created_at DESC LIMIT 1),
    (SELECT id FROM agents ORDER BY created_at DESC LIMIT 1),
    'Conversación de prueba para el Asistente IA',
    now()
  RETURNING id
)
SELECT id AS new_conversation_id FROM new_conversation \gset

-- Mostrar el ID de la nueva conversación
\echo 'Nueva conversación creada con ID: :new_conversation_id'

-- 13. Probar la función get_conversation_ia_state con la nueva conversación
-- Esto debería crear automáticamente un registro en conversation_settings
SELECT * FROM get_conversation_ia_state(:'new_conversation_id');

-- 14. Verificar que se creó el registro
SELECT 
  id, 
  conversation_id, 
  ia_assistant_enabled, 
  created_at, 
  updated_at
FROM 
  conversation_settings
WHERE 
  conversation_id = :'new_conversation_id';

-- 15. Instrucciones para integración con el frontend
RAISE NOTICE '
Para integrar con el frontend, debe modificar el hook useIAAssistantState para:

1. Recibir el ID de conversación como parámetro:
   - useIAAssistantState(conversationId: string)

2. Usar las nuevas funciones:
   - get_conversation_ia_state(conversationId)
   - update_conversation_ia_state(conversationId, newState, reason)

3. Actualizar los componentes para pasar el ID de conversación al hook.

Estas modificaciones permitirán que cada conversación tenga su propio estado independiente.
';
