/*
  # Prueba del Webhook de IA para Mensajes con Asistente IA Activado

  Este script inserta un mensaje de cliente con asistente_ia_activado=true
  y verifica si se envía correctamente al webhook de IA.
*/

-- 1. Verificar que el campo asistente_ia_activado existe en la tabla messages
SELECT 
  column_name, 
  data_type, 
  is_nullable, 
  column_default
FROM 
  information_schema.columns
WHERE 
  table_name = 'messages' AND 
  column_name = 'asistente_ia_activado';

-- 2. Verificar las URLs del webhook de IA en app_settings
SELECT key, value
FROM app_settings
WHERE key LIKE 'webhook_url_ia%';

-- 3. Verificar que la función notify_message_webhook existe y contiene la lógica para el webhook de IA
SELECT 
  p.proname AS function_name,
  pg_get_functiondef(p.oid) AS function_definition
FROM pg_proc p
JOIN pg_namespace n ON p.pronamespace = n.oid
WHERE p.proname = 'notify_message_webhook';

-- 4. Verificar que el trigger message_webhook_trigger está activo
SELECT 
  t.tgname AS trigger_name,
  CASE WHEN t.tgenabled = 'D' THEN 'DESACTIVADO' ELSE 'ACTIVADO' END AS status,
  pg_get_triggerdef(t.oid) AS trigger_definition
FROM pg_trigger t
JOIN pg_class c ON t.tgrelid = c.oid
JOIN pg_namespace n ON c.relnamespace = n.oid
WHERE t.tgname = 'message_webhook_trigger';

-- 5. Insertar un mensaje de prueba con asistente_ia_activado=true
DO $$
DECLARE
  test_conversation_id UUID;
  test_client_id UUID;
  test_message_id UUID;
BEGIN
  -- Obtener un conversation_id y client_id existentes
  SELECT conv.id, conv.client_id INTO test_conversation_id, test_client_id
  FROM conversations conv
  LIMIT 1;
  
  IF test_conversation_id IS NULL THEN
    RAISE NOTICE 'No se encontraron conversaciones para la prueba.';
    RETURN;
  END IF;
  
  -- Insertar un mensaje de prueba con asistente_ia_activado=true
  INSERT INTO messages (
    conversation_id,
    content,
    sender,
    sender_id,
    type,
    status,
    asistente_ia_activado
  )
  VALUES (
    test_conversation_id,
    'Mensaje de prueba para webhook de IA (con asistente_ia_activado=true)',
    'client',
    test_client_id,
    'text',
    'sent',
    TRUE
  )
  RETURNING id INTO test_message_id;
  
  RAISE NOTICE 'Mensaje de prueba insertado con ID: %', test_message_id;
  RAISE NOTICE 'Verifica los logs de Supabase para ver si el mensaje fue enviado al webhook de IA.';
END;
$$;

-- 6. Verificar los mensajes recientes con asistente_ia_activado=true
SELECT id, conversation_id, sender, sender_id, content, status, asistente_ia_activado, created_at
FROM messages
WHERE asistente_ia_activado = TRUE
ORDER BY created_at DESC
LIMIT 5;

-- 7. Instrucciones para verificar los logs
RAISE NOTICE '
Para verificar si el mensaje fue enviado correctamente al webhook de IA:
1. Accede a la consola de Supabase
2. Ve a la sección de Logs
3. Busca mensajes relacionados con "IA webhook", como:
   - "Selected IA webhook URL: X (is_production=true/false)"
   - "IA webhook payload: {...}"
   - "IA webhook request succeeded for message ID: X"
';

-- 8. Probar manualmente con diferentes valores
RAISE NOTICE '
Para probar manualmente con diferentes valores:

-- Mensaje de cliente con asistente_ia_activado=true (debería enviar al webhook de IA)
INSERT INTO messages (conversation_id, content, sender, sender_id, type, status, asistente_ia_activado)
SELECT id, ''Prueba con IA activado'', ''client'', client_id, ''text'', ''sent'', TRUE
FROM conversations LIMIT 1;

-- Mensaje de cliente con asistente_ia_activado=false (NO debería enviar al webhook de IA)
INSERT INTO messages (conversation_id, content, sender, sender_id, type, status, asistente_ia_activado)
SELECT id, ''Prueba con IA desactivado'', ''client'', client_id, ''text'', ''sent'', FALSE
FROM conversations LIMIT 1;

-- Mensaje de agente con asistente_ia_activado=true (NO debería enviar al webhook de IA)
INSERT INTO messages (conversation_id, content, sender, sender_id, type, status, asistente_ia_activado)
SELECT id, ''Prueba de agente con IA activado'', ''agent'', ''00000000-0000-0000-0000-000000000000'', ''text'', ''sent'', TRUE
FROM conversations LIMIT 1;
';
