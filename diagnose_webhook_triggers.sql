/*
  # Diagnóstico Completo de Webhooks y Triggers

  Este script realiza un diagnóstico completo de todos los webhooks y triggers
  relacionados con mensajes para identificar posibles conflictos o problemas.
*/

-- 1. Listar todos los triggers en la tabla messages
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

-- 2. Verificar todas las configuraciones de webhooks en app_settings
SELECT 
  key, 
  value, 
  description,
  updated_at
FROM 
  app_settings
WHERE 
  key LIKE '%webhook%' OR
  key LIKE '%url%'
ORDER BY
  key;

-- 3. Verificar el entorno (producción o pruebas)
SELECT 
  key, 
  value
FROM 
  app_settings
WHERE 
  key = 'is_production_environment';

-- 4. Verificar si la extensión http está instalada y disponible
SELECT 
  extname, 
  extversion
FROM 
  pg_extension
WHERE 
  extname = 'http';

-- 5. Verificar si la función http_post existe y su definición
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

-- 6. Verificar la definición de todas las funciones relacionadas con webhooks
SELECT 
  p.proname AS function_name,
  pg_get_functiondef(p.oid) AS function_definition
FROM 
  pg_proc p
JOIN 
  pg_namespace n ON p.pronamespace = n.oid
WHERE 
  (p.proname LIKE '%webhook%' OR p.proname LIKE '%notify%') AND
  n.nspname = 'public';

-- 7. Verificar mensajes recientes con asistente_ia_activado=true
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

-- 8. Verificar mensajes recientes de agentes
SELECT 
  id, 
  conversation_id, 
  content, 
  sender, 
  sender_id,
  status, 
  asistente_ia_activado, 
  created_at
FROM 
  messages
WHERE 
  sender = 'agent'
ORDER BY 
  created_at DESC
LIMIT 5;

-- 9. Verificar si hay errores en los logs (esto es informativo, los logs reales deben revisarse en la consola de Supabase)
RAISE NOTICE '
Para verificar errores en los logs:
1. Accede a la consola de Supabase
2. Ve a la sección de Logs
3. Busca mensajes de error relacionados con:
   - "Error in IA webhook function"
   - "IA webhook request failed"
   - "Error sending to webhook"
   - "Selected IA webhook URL"
';
