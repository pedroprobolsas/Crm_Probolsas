/*
  # Prueba de la Solución para el Webhook de Mensajes de Clientes

  Este script inserta un mensaje de cliente en la tabla messages y verifica
  si se envía correctamente al webhook. Debe ejecutarse después de aplicar
  la migración que soluciona el problema.
*/

-- 1. Verificar que la función notify_message_webhook existe y usa http_post
SELECT 
  p.proname AS function_name,
  pg_get_functiondef(p.oid) AS function_definition
FROM pg_proc p
JOIN pg_namespace n ON p.pronamespace = n.oid
WHERE p.proname = 'notify_message_webhook';

-- 2. Verificar que el trigger message_webhook_trigger está activo
SELECT 
  t.tgname AS trigger_name,
  CASE WHEN t.tgenabled = 'D' THEN 'DESACTIVADO' ELSE 'ACTIVADO' END AS status,
  pg_get_triggerdef(t.oid) AS trigger_definition
FROM pg_trigger t
JOIN pg_class c ON t.tgrelid = c.oid
JOIN pg_namespace n ON c.relnamespace = n.oid
WHERE t.tgname = 'message_webhook_trigger';

-- 3. Verificar las URLs de webhook en app_settings
SELECT key, value
FROM app_settings
WHERE key LIKE 'webhook_url%';

-- 4. Verificar el entorno actual
SELECT key, value
FROM app_settings
WHERE key = 'is_production_environment';

-- 5. Insertar un mensaje de prueba de cliente
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
  
  -- Insertar un mensaje de prueba
  INSERT INTO messages (
    conversation_id,
    content,
    sender,
    sender_id,
    type,
    status
  )
  VALUES (
    test_conversation_id,
    'Mensaje de prueba para webhook de cliente (después de aplicar la solución)',
    'client',
    test_client_id,
    'text',
    'sent'
  )
  RETURNING id INTO test_message_id;
  
  RAISE NOTICE 'Mensaje de prueba insertado con ID: %', test_message_id;
  RAISE NOTICE 'Verifica los logs de Supabase para ver si el mensaje fue enviado al webhook.';
END;
$$;

-- 6. Verificar los mensajes recientes
SELECT id, conversation_id, sender, sender_id, content, status, created_at
FROM messages
WHERE sender = 'client' AND status = 'sent'
ORDER BY created_at DESC
LIMIT 5;

-- 7. Instrucciones para verificar los logs
RAISE NOTICE '
Para verificar si el mensaje fue enviado correctamente al webhook:
1. Accede a la consola de Supabase
2. Ve a la sección de Logs
3. Busca mensajes relacionados con "webhook", "http_post", o "notify_message_webhook"
4. Verifica si hay mensajes de log como:
   - "Processing message: id=X, sender=client, status=sent"
   - "Selected webhook URL: Y (is_production=true/false)"
   - "Found client info: id=Z, name=N, phone=P"
   - "Final payload: {...}"
   - "Sending client message to webhook: X, URL: Y"
   - "Webhook request succeeded for message ID: X"
';
