/*
  # Diagnóstico del Webhook de IA para Mensajes con Asistente IA Activado

  Este script realiza un diagnóstico completo del sistema de webhook de IA
  para identificar por qué los mensajes de clientes no están llegando al webhook.
*/

-- 1. Verificar mensajes recientes para ver si tienen asistente_ia_activado=true
SELECT 
  id, 
  conversation_id, 
  content, 
  sender, 
  status, 
  asistente_ia_activado, 
  created_at
FROM 
  messages
WHERE 
  sender = 'client' AND 
  status = 'sent'
ORDER BY 
  created_at DESC
LIMIT 10;

-- 2. Verificar las URLs del webhook de IA en app_settings
SELECT 
  key, 
  value, 
  updated_at
FROM 
  app_settings
WHERE 
  key LIKE 'webhook_url_ia%';

-- 3. Verificar si el trigger message_webhook_trigger está activo
SELECT 
  t.tgname AS trigger_name,
  CASE WHEN t.tgenabled = 'D' THEN 'DESACTIVADO' ELSE 'ACTIVADO' END AS status,
  pg_get_triggerdef(t.oid) AS trigger_definition
FROM 
  pg_trigger t
JOIN 
  pg_class c ON t.tgrelid = c.oid
JOIN 
  pg_namespace n ON c.relnamespace = n.oid
WHERE 
  c.relname = 'messages' AND
  t.tgname = 'message_webhook_trigger';

-- 4. Verificar la definición de la función notify_message_webhook
SELECT 
  p.proname AS function_name,
  pg_get_functiondef(p.oid) AS function_definition
FROM 
  pg_proc p
JOIN 
  pg_namespace n ON p.pronamespace = n.oid
WHERE 
  p.proname = 'notify_message_webhook' AND
  n.nspname = 'public';

-- 5. Verificar si la extensión http está instalada y disponible
SELECT 
  extname, 
  extversion, 
  extcondition
FROM 
  pg_extension
WHERE 
  extname = 'http';

-- 6. Verificar si hay errores recientes en los logs relacionados con el webhook
-- (Esta consulta es informativa, los logs reales deben revisarse en la consola de Supabase)
RAISE NOTICE '
Para verificar errores en los logs:
1. Accede a la consola de Supabase
2. Ve a la sección de Logs
3. Busca mensajes de error relacionados con:
   - "Error in IA webhook function"
   - "IA webhook request failed"
   - "Error sending to webhook"
';

-- 7. Probar insertar un mensaje con asistente_ia_activado=true para verificar el funcionamiento
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
    'DIAGNÓSTICO: Mensaje de prueba para webhook de IA ' || NOW(),
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

-- 8. Verificar si hay algún otro trigger en la tabla messages que pueda estar interfiriendo
SELECT 
  t.tgname AS trigger_name,
  CASE WHEN t.tgenabled = 'D' THEN 'DESACTIVADO' ELSE 'ACTIVADO' END AS status,
  pg_get_triggerdef(t.oid) AS trigger_definition
FROM 
  pg_trigger t
JOIN 
  pg_class c ON t.tgrelid = c.oid
JOIN 
  pg_namespace n ON c.relnamespace = n.oid
WHERE 
  c.relname = 'messages' AND
  n.nspname = 'public';

-- 9. Verificar si la función http_post existe y está disponible
SELECT 
  p.proname AS function_name,
  pg_get_functiondef(p.oid) AS function_definition
FROM 
  pg_proc p
JOIN 
  pg_namespace n ON p.pronamespace = n.oid
WHERE 
  p.proname = 'http_post' AND
  n.nspname = 'public';

-- 10. Verificar el entorno (producción o pruebas)
SELECT 
  key, 
  value
FROM 
  app_settings
WHERE 
  key = 'is_production_environment';
