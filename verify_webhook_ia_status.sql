/*
  # Verificación del Estado del Webhook de IA
  
  Este script verifica el estado del webhook de IA, incluyendo:
  - La configuración del webhook
  - El estado de los mensajes enviados
  - El estado de los triggers y funciones
*/

-- 1. Verificar la configuración del webhook de IA
SELECT 
  key, 
  value, 
  updated_at
FROM 
  app_settings
WHERE 
  key LIKE 'webhook_url_ia%';

-- 2. Verificar el estado de los mensajes enviados
SELECT 
  id, 
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

-- 3. Verificar el estado del trigger message_webhook_trigger
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

-- 6. Verificar si la función http_post existe
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

-- 7. Verificar si la función check_if_table_exists existe
SELECT 
  p.proname AS function_name,
  pg_get_functiondef(p.oid) AS function_definition
FROM 
  pg_proc p
JOIN 
  pg_namespace n ON p.pronamespace = n.oid
WHERE 
  p.proname = 'check_if_table_exists' AND
  n.nspname = 'public';

-- 8. Verificar si la tabla message_whatsapp_status existe
SELECT 
  EXISTS (
    SELECT FROM information_schema.tables 
    WHERE table_schema = 'public'
    AND table_name = 'message_whatsapp_status'
  ) AS table_exists;

-- 9. Verificar el entorno (producción o pruebas)
SELECT 
  key, 
  value
FROM 
  app_settings
WHERE 
  key = 'is_production_environment';

-- 10. Resumen del estado
DO $$
DECLARE
  trigger_status TEXT;
  http_extension_exists BOOLEAN;
  http_post_function_exists BOOLEAN;
  check_if_table_exists_function_exists BOOLEAN;
  message_whatsapp_status_table_exists BOOLEAN;
  ia_webhook_url TEXT;
  is_production BOOLEAN;
BEGIN
  -- Verificar el estado del trigger
  SELECT 
    CASE WHEN t.tgenabled = 'D' THEN 'DESACTIVADO' ELSE 'ACTIVADO' END INTO trigger_status
  FROM 
    pg_trigger t
  JOIN 
    pg_class c ON t.tgrelid = c.oid
  WHERE 
    c.relname = 'messages' AND
    t.tgname = 'message_webhook_trigger';
  
  -- Verificar si la extensión http existe
  SELECT EXISTS (
    SELECT 1 FROM pg_extension WHERE extname = 'http'
  ) INTO http_extension_exists;
  
  -- Verificar si la función http_post existe
  SELECT EXISTS (
    SELECT 1 FROM pg_proc p
    JOIN pg_namespace n ON p.pronamespace = n.oid
    WHERE p.proname = 'http_post' AND n.nspname = 'public'
  ) INTO http_post_function_exists;
  
  -- Verificar si la función check_if_table_exists existe
  SELECT EXISTS (
    SELECT 1 FROM pg_proc p
    JOIN pg_namespace n ON p.pronamespace = n.oid
    WHERE p.proname = 'check_if_table_exists' AND n.nspname = 'public'
  ) INTO check_if_table_exists_function_exists;
  
  -- Verificar si la tabla message_whatsapp_status existe
  SELECT EXISTS (
    SELECT FROM information_schema.tables 
    WHERE table_schema = 'public'
    AND table_name = 'message_whatsapp_status'
  ) INTO message_whatsapp_status_table_exists;
  
  -- Obtener la URL del webhook de IA
  SELECT (value = 'true') INTO is_production 
  FROM app_settings 
  WHERE key = 'is_production_environment';
  
  IF is_production THEN
    SELECT value INTO ia_webhook_url 
    FROM app_settings 
    WHERE key = 'webhook_url_ia_production';
  ELSE
    SELECT value INTO ia_webhook_url 
    FROM app_settings 
    WHERE key = 'webhook_url_ia_test';
  END IF;
  
  -- Mostrar el resumen
  RAISE NOTICE '
  RESUMEN DEL ESTADO DEL WEBHOOK DE IA:
  
  1. Trigger message_webhook_trigger: %
  2. Extensión http: %
  3. Función http_post: %
  4. Función check_if_table_exists: %
  5. Tabla message_whatsapp_status: %
  6. URL del webhook de IA: %
  7. Entorno: %
  
  Estado general: %
  ',
  trigger_status,
  CASE WHEN http_extension_exists THEN 'INSTALADA' ELSE 'NO INSTALADA' END,
  CASE WHEN http_post_function_exists THEN 'EXISTE' ELSE 'NO EXISTE' END,
  CASE WHEN check_if_table_exists_function_exists THEN 'EXISTE' ELSE 'NO EXISTE' END,
  CASE WHEN message_whatsapp_status_table_exists THEN 'EXISTE' ELSE 'NO EXISTE' END,
  ia_webhook_url,
  CASE WHEN is_production THEN 'PRODUCCIÓN' ELSE 'PRUEBAS' END,
  CASE 
    WHEN trigger_status = 'ACTIVADO' AND 
         http_extension_exists AND 
         http_post_function_exists AND 
         ia_webhook_url IS NOT NULL
    THEN 'CORRECTO'
    ELSE 'INCORRECTO'
  END;
END;
$$;
