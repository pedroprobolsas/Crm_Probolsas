/*
  # Prueba del Formato de Datos del Webhook de IA

  Este script prueba si la corrección del formato de datos del webhook de IA
  ha funcionado correctamente, verificando que los datos se envíen en el cuerpo (body)
  de la solicitud HTTP y no como parte del encabezado "content-type".
*/

-- 1. Verificar la definición actual de la función http_post
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

-- 2. Verificar la definición de la función notify_message_webhook
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

-- 4. Verificar las URLs del webhook de IA en app_settings
SELECT 
  key, 
  value
FROM 
  app_settings
WHERE 
  key LIKE 'webhook_url_ia%';

-- 5. Verificar el entorno (producción o pruebas)
SELECT 
  key, 
  value
FROM 
  app_settings
WHERE 
  key = 'is_production_environment';

-- 6. Insertar un mensaje de prueba con asistente_ia_activado=true
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
    'PRUEBA DE FORMATO: Mensaje para verificar el formato de datos del webhook de IA ' || NOW(),
    'client',
    test_client_id,
    'text',
    'sent',
    TRUE
  )
  RETURNING id INTO test_message_id;
  
  RAISE NOTICE 'Mensaje de prueba insertado con ID: %', test_message_id;
  RAISE NOTICE 'Verifica los logs de Supabase para ver si el mensaje fue enviado al webhook de IA con el formato correcto.';
  RAISE NOTICE 'También verifica la respuesta del webhook para confirmar que los datos se recibieron correctamente en el cuerpo (body) de la solicitud.';
END;
$$;

-- 7. Verificar los mensajes recientes con asistente_ia_activado=true
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
  asistente_ia_activado = TRUE
ORDER BY 
  created_at DESC
LIMIT 5;

-- 8. Instrucciones para verificar los logs y la respuesta del webhook
RAISE NOTICE '
Para verificar si la corrección del formato de datos del webhook de IA ha funcionado correctamente:

1. Verifica los logs de Supabase:
   - Accede a la consola de Supabase
   - Ve a la sección de Logs
   - Busca mensajes relacionados con "IA webhook", como:
     * "IA webhook payload: {...}"
     * "IA webhook request succeeded for message ID: X"

2. Verifica la respuesta del webhook:
   - Accede a la plataforma n8n o al servicio que recibe el webhook
   - Verifica que los datos se hayan recibido correctamente en el cuerpo (body) de la solicitud
   - Confirma que el formato de los datos sea similar a:
     {
       "id": "uuid-del-mensaje",
       "conversation_id": "uuid-de-la-conversacion",
       "content": "Contenido del mensaje",
       "sender": "client",
       "sender_id": "uuid-del-cliente",
       "type": "text",
       "status": "sent",
       "created_at": "fecha-y-hora",
       "asistente_ia_activado": true,
       "phone": "numero-de-telefono",
       "client": {
         "id": "uuid-del-cliente",
         "name": "Nombre del cliente",
         "phone": "numero-de-telefono",
         // ... resto de datos del cliente
       }
     }

3. Si los datos se reciben correctamente en el cuerpo (body) de la solicitud, la corrección ha funcionado.
   Si los datos siguen apareciendo en el encabezado "content-type", la corrección no ha funcionado.
';
