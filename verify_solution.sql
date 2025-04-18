-- Script para verificar que la solución se ha aplicado correctamente
-- Este script debe ejecutarse directamente en la consola SQL de Supabase

-- 1. Verificar que la columna ia_webhook_sent existe en la tabla messages
DO $$
DECLARE
  column_exists BOOLEAN;
BEGIN
  SELECT EXISTS (
    SELECT 1
    FROM information_schema.columns
    WHERE table_name = 'messages' AND column_name = 'ia_webhook_sent'
  ) INTO column_exists;
  
  IF column_exists THEN
    RAISE NOTICE 'VERIFICACIÓN EXITOSA: La columna ia_webhook_sent existe en la tabla messages';
  ELSE
    RAISE WARNING 'ERROR: La columna ia_webhook_sent NO existe en la tabla messages';
  END IF;
END;
$$;

-- 2. Verificar que el trigger message_webhook_trigger está activo
DO $$
DECLARE
  trigger_status TEXT;
BEGIN
  SELECT 
    CASE WHEN t.tgenabled = 'D' THEN 'DESACTIVADO' ELSE 'ACTIVADO' END INTO trigger_status
  FROM 
    pg_trigger t
  JOIN 
    pg_class c ON t.tgrelid = c.oid
  WHERE 
    c.relname = 'messages' AND
    t.tgname = 'message_webhook_trigger';
    
  IF trigger_status IS NULL THEN
    RAISE WARNING 'ERROR: No se encontró el trigger message_webhook_trigger';
  ELSE
    RAISE NOTICE 'VERIFICACIÓN: El trigger message_webhook_trigger está %', trigger_status;
    
    IF trigger_status = 'ACTIVADO' THEN
      RAISE NOTICE 'VERIFICACIÓN EXITOSA: El trigger message_webhook_trigger está activo';
    ELSE
      RAISE WARNING 'ERROR: El trigger message_webhook_trigger está desactivado';
    END IF;
  END IF;
END;
$$;

-- 3. Verificar que la función notify_message_webhook existe y tiene la lógica correcta
DO $$
DECLARE
  function_exists BOOLEAN;
  function_source TEXT;
  has_ia_webhook_sent_check BOOLEAN;
  has_asistente_ia_activado_check BOOLEAN;
  has_ia_prefix_check BOOLEAN;
BEGIN
  -- Verificar si la función existe
  SELECT EXISTS (
    SELECT 1
    FROM pg_proc p
    JOIN pg_namespace n ON p.pronamespace = n.oid
    WHERE p.proname = 'notify_message_webhook' AND n.nspname = 'public'
  ) INTO function_exists;
  
  IF NOT function_exists THEN
    RAISE WARNING 'ERROR: La función notify_message_webhook NO existe';
    RETURN;
  END IF;
  
  -- Obtener el código fuente de la función
  SELECT pg_get_functiondef(p.oid)
  INTO function_source
  FROM pg_proc p
  JOIN pg_namespace n ON p.pronamespace = n.oid
  WHERE p.proname = 'notify_message_webhook' AND n.nspname = 'public';
  
  -- Verificar si contiene las verificaciones clave
  has_ia_webhook_sent_check := function_source LIKE '%NEW.ia_webhook_sent = TRUE%';
  has_asistente_ia_activado_check := function_source LIKE '%NEW.asistente_ia_activado IS NOT TRUE%';
  has_ia_prefix_check := function_source LIKE '%NEW.content LIKE ''[IA]%''%';
  
  RAISE NOTICE 'VERIFICACIÓN: La función notify_message_webhook existe';
  
  IF has_ia_webhook_sent_check THEN
    RAISE NOTICE 'VERIFICACIÓN EXITOSA: La función contiene la verificación de ia_webhook_sent';
  ELSE
    RAISE WARNING 'ERROR: La función NO contiene la verificación de ia_webhook_sent';
  END IF;
  
  IF has_asistente_ia_activado_check THEN
    RAISE NOTICE 'VERIFICACIÓN EXITOSA: La función contiene la verificación de asistente_ia_activado';
  ELSE
    RAISE WARNING 'ERROR: La función NO contiene la verificación de asistente_ia_activado';
  END IF;
  
  IF has_ia_prefix_check THEN
    RAISE NOTICE 'VERIFICACIÓN EXITOSA: La función contiene la verificación de prefijo [IA]';
  ELSE
    RAISE WARNING 'ERROR: La función NO contiene la verificación de prefijo [IA]';
  END IF;
END;
$$;

-- 4. Verificar si hay mensajes duplicados en la tabla messages
DO $$
DECLARE
  duplicate_count INTEGER;
BEGIN
  WITH duplicate_messages AS (
    SELECT 
      conversation_id, 
      content, 
      created_at,
      COUNT(*) as count
    FROM 
      messages
    WHERE 
      created_at > NOW() - INTERVAL '7 days'
    GROUP BY 
      conversation_id, content, created_at
    HAVING 
      COUNT(*) > 1
  )
  SELECT COUNT(*) INTO duplicate_count FROM duplicate_messages;
  
  IF duplicate_count = 0 THEN
    RAISE NOTICE 'VERIFICACIÓN EXITOSA: No se encontraron mensajes duplicados en los últimos 7 días';
  ELSE
    RAISE WARNING 'ADVERTENCIA: Se encontraron % grupos de mensajes potencialmente duplicados en los últimos 7 días', duplicate_count;
  END IF;
END;
$$;

-- 5. Verificar si hay clientes duplicados
DO $$
DECLARE
  duplicate_count INTEGER;
BEGIN
  WITH duplicate_clients AS (
    SELECT 
      phone, 
      COUNT(*) as count
    FROM 
      clients
    WHERE 
      phone IS NOT NULL AND phone != ''
    GROUP BY 
      phone
    HAVING 
      COUNT(*) > 1
  )
  SELECT COUNT(*) INTO duplicate_count FROM duplicate_clients;
  
  IF duplicate_count = 0 THEN
    RAISE NOTICE 'VERIFICACIÓN EXITOSA: No se encontraron clientes con números de teléfono duplicados';
  ELSE
    RAISE WARNING 'ADVERTENCIA: Se encontraron % números de teléfono duplicados en la tabla clients', duplicate_count;
  END IF;
END;
$$;

-- 6. Verificar si hay mensajes recientes con asistente_ia_activado=true que no tienen ia_webhook_sent=true
DO $$
DECLARE
  unprocessed_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO unprocessed_count
  FROM messages
  WHERE 
    created_at > NOW() - INTERVAL '1 day' AND
    asistente_ia_activado = TRUE AND
    (ia_webhook_sent IS NULL OR ia_webhook_sent = FALSE);
  
  IF unprocessed_count = 0 THEN
    RAISE NOTICE 'VERIFICACIÓN EXITOSA: Todos los mensajes recientes con asistente_ia_activado=true tienen ia_webhook_sent=true';
  ELSE
    RAISE WARNING 'ADVERTENCIA: Hay % mensajes recientes con asistente_ia_activado=true que no tienen ia_webhook_sent=true', unprocessed_count;
  END IF;
END;
$$;

-- 7. Verificar si la extensión http está instalada
DO $$
DECLARE
  http_extension_exists BOOLEAN;
BEGIN
  SELECT EXISTS (
    SELECT 1
    FROM pg_extension
    WHERE extname = 'http'
  ) INTO http_extension_exists;
  
  IF http_extension_exists THEN
    RAISE NOTICE 'VERIFICACIÓN EXITOSA: La extensión http está instalada';
  ELSE
    RAISE WARNING 'ERROR: La extensión http NO está instalada. Esta es necesaria para que el webhook de IA funcione.';
  END IF;
END;
$$;

-- 8. Verificar si existe la URL del webhook de IA en app_settings
DO $$
DECLARE
  webhook_url TEXT;
BEGIN
  SELECT value INTO webhook_url
  FROM app_settings
  WHERE key = 'webhook_url_ia_production';
  
  IF webhook_url IS NOT NULL AND webhook_url != '' THEN
    RAISE NOTICE 'VERIFICACIÓN EXITOSA: La URL del webhook de IA está configurada en app_settings: %', webhook_url;
  ELSE
    RAISE WARNING 'ERROR: La URL del webhook de IA NO está configurada en app_settings';
  END IF;
END;
$$;

-- Resumen final
DO $$
BEGIN
  RAISE NOTICE '------------------------------------------------------------';
  RAISE NOTICE 'RESUMEN DE VERIFICACIÓN';
  RAISE NOTICE '------------------------------------------------------------';
  RAISE NOTICE 'Si todas las verificaciones son exitosas, la solución se ha aplicado correctamente.';
  RAISE NOTICE 'Si hay advertencias o errores, revisa las instrucciones en README-instrucciones-actualizadas.md';
  RAISE NOTICE '------------------------------------------------------------';
END;
$$;
