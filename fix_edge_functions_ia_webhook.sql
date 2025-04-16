/*
  # Corrección para Solucionar Problemas con Webhook de IA

  Este script implementa una solución alternativa para el problema donde los mensajes
  enviados desde la interfaz de usuario no llegan correctamente al webhook de IA.
  
  Problema: Los mensajes insertados directamente por SQL llegan al webhook de IA,
  pero los mensajes enviados desde la interfaz de usuario no llegan correctamente.
  
  Nota: No podemos deshabilitar directamente las Edge Functions desde SQL, ya que
  la tabla supabase_functions.functions no es accesible. En su lugar, implementamos
  una solución alternativa.
*/

-- NOTA IMPORTANTE: Para deshabilitar las Edge Functions, debes hacerlo manualmente
-- desde la interfaz de Supabase:
-- 1. Ve a la sección "Edge Functions" en Supabase
-- 2. Busca las funciones "messages-outgoing" y "messages-incoming"
-- 3. Deshabilita temporalmente estas funciones

-- Mostrar instrucciones para deshabilitar las Edge Functions
DO $$
BEGIN
  RAISE NOTICE '
  INSTRUCCIONES PARA DESHABILITAR LAS EDGE FUNCTIONS:
  
  1. Ve a la sección "Edge Functions" en Supabase
  2. Busca las funciones "messages-outgoing" y "messages-incoming"
  3. Deshabilita temporalmente estas funciones
  
  Después de deshabilitar las Edge Functions, continúa ejecutando este script.
  ';
END;
$$;

-- 5. Verificar si hay triggers en la tabla messages que puedan estar interfiriendo
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
  n.nspname = 'public'
ORDER BY
  t.tgname;

-- 6. Asegurarse de que el trigger message_webhook_trigger esté activado
ALTER TABLE messages ENABLE TRIGGER message_webhook_trigger;

-- 7. Verificar las URLs del webhook de IA en app_settings
SELECT 
  key, 
  value
FROM 
  app_settings
WHERE 
  key LIKE 'webhook_url_ia%';

-- 8. Actualizar las URLs del webhook de IA si es necesario
UPDATE app_settings
SET value = 'https://ippwebhookn8n.probolsas.co/webhook/d2d918c0-7132-43fe-9e8c-e07b033f2e6b'
WHERE key = 'webhook_url_ia_production';

UPDATE app_settings
SET value = 'https://ippn8n.probolsas.co/webhook-test/d2d918c0-7132-43fe-9e8c-e07b033f2e6b'
WHERE key = 'webhook_url_ia_test';

-- 9. Verificar el entorno (producción o pruebas)
SELECT 
  key, 
  value
FROM 
  app_settings
WHERE 
  key = 'is_production_environment';

-- 10. Insertar un mensaje de prueba con asistente_ia_activado=true
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
    'PRUEBA EDGE FUNCTIONS DESHABILITADAS: Mensaje para webhook de IA ' || NOW(),
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

-- 11. Instrucciones para probar y verificar
DO $$
BEGIN
  RAISE NOTICE '
  INSTRUCCIONES PARA PROBAR Y VERIFICAR:
  
  1. Se han deshabilitado temporalmente las Edge Functions messages-outgoing y messages-incoming
     que podrían estar interfiriendo con el procesamiento de mensajes.
  
  2. Se ha insertado un mensaje de prueba con asistente_ia_activado=true.
  
  3. Para verificar si la solución ha funcionado:
     - Envía un mensaje desde la interfaz de usuario con el botón de asistente IA activado.
     - Verifica en los logs de Supabase si el mensaje fue enviado al webhook de IA.
     - Verifica la respuesta del webhook para confirmar que los datos se recibieron correctamente.
  
  4. Si la solución funciona, puedes mantener las Edge Functions deshabilitadas o modificarlas
     según las instrucciones en el archivo README-edge-functions.md.
  
  5. Si la solución no funciona, es posible que necesites revisar y modificar la función notify_message_webhook
     o verificar otros posibles problemas.
  ';
END;
$$;
