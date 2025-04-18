/*
  # Verificación de la Solución del Webhook de IA

  Este script verifica que la solución implementada para el webhook de IA
  está funcionando correctamente.
*/

-- 1. Verificar que el trigger message_webhook_trigger está activo
SELECT 
  t.tgname AS trigger_name,
  CASE WHEN t.tgenabled = 'D' THEN 'DESACTIVADO' ELSE 'ACTIVADO' END AS status
FROM 
  pg_trigger t
JOIN 
  pg_class c ON t.tgrelid = c.oid
WHERE 
  c.relname = 'messages' AND
  t.tgname = 'message_webhook_trigger';

-- 2. Verificar las URLs del webhook de IA en app_settings
SELECT 
  key, 
  value
FROM 
  app_settings
WHERE 
  key LIKE 'webhook_url_ia%';

-- 3. Verificar si existe la columna ia_webhook_sent en la tabla messages
SELECT 
  column_name, 
  data_type
FROM 
  information_schema.columns
WHERE 
  table_name = 'messages' AND 
  column_name = 'ia_webhook_sent';

-- 4. Verificar mensajes recientes con asistente_ia_activado=true
SELECT 
  id, 
  conversation_id, 
  content, 
  sender, 
  status, 
  asistente_ia_activado, 
  ia_webhook_sent,
  created_at
FROM 
  messages
WHERE 
  asistente_ia_activado = TRUE
ORDER BY 
  created_at DESC
LIMIT 10;

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
    'VERIFICACIÓN: Mensaje de prueba para webhook de IA ' || NOW(),
    'client',
    test_client_id,
    'text',
    'sent',
    TRUE
  )
  RETURNING id INTO test_message_id;
  
  RAISE NOTICE 'Mensaje de prueba insertado con ID: %', test_message_id;
  RAISE NOTICE 'Verifica los logs de Supabase para ver si el mensaje fue enviado al webhook de IA.';
  
  -- Esperar un momento para que el trigger se ejecute
  PERFORM pg_sleep(2);
  
  -- Verificar si el mensaje fue marcado como enviado al webhook de IA
  SELECT 
    id, 
    content, 
    ia_webhook_sent
  FROM 
    messages
  WHERE 
    id = test_message_id;
END;
$$;

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

-- 7. Verificar el estado de las Edge Functions
RAISE NOTICE '
Verifica que las Edge Functions estén deshabilitadas:
1. Accede a la consola de Supabase
2. Ve a la sección de Edge Functions
3. Verifica que las funciones "messages-outgoing" y "messages-incoming" estén deshabilitadas
';

-- 8. Resumen de la verificación
RAISE NOTICE '
Resumen de la verificación:

1. El trigger message_webhook_trigger debe estar ACTIVADO
2. Las URLs del webhook de IA deben estar configuradas correctamente
3. La columna ia_webhook_sent debe existir en la tabla messages
4. El mensaje de prueba debe tener ia_webhook_sent = TRUE
5. No debe haber errores recientes en los logs relacionados con el webhook
6. Las Edge Functions deben estar deshabilitadas
';
