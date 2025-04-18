-- Script para verificar que la solución mejorada se ha aplicado correctamente
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

-- 2. Verificar que el trigger message_webhook_trigger está activo y responde a INSERT y UPDATE
DO $$
DECLARE
  trigger_exists BOOLEAN;
  trigger_status TEXT;
  trigger_events TEXT;
BEGIN
  -- Verificar si el trigger existe y está activo
  SELECT 
    EXISTS(
      SELECT 1
      FROM pg_trigger t
      JOIN pg_class c ON t.tgrelid = c.oid
      WHERE c.relname = 'messages' AND t.tgname = 'message_webhook_trigger'
    ),
    CASE WHEN t.tgenabled = 'D' THEN 'DESACTIVADO' ELSE 'ACTIVADO' END
  INTO 
    trigger_exists,
    trigger_status
  FROM 
    pg_trigger t
  JOIN 
    pg_class c ON t.tgrelid = c.oid
  WHERE 
    c.relname = 'messages' AND
    t.tgname = 'message_webhook_trigger';
    
  IF NOT trigger_exists THEN
    RAISE WARNING 'ERROR: No se encontró el trigger message_webhook_trigger';
    RETURN;
  END IF;
  
  IF trigger_status = 'ACTIVADO' THEN
    RAISE NOTICE 'VERIFICACIÓN EXITOSA: El trigger message_webhook_trigger está activo';
  ELSE
    RAISE WARNING 'ERROR: El trigger message_webhook_trigger está desactivado';
  END IF;
  
  -- Verificar los eventos que activan el trigger
  SELECT 
    CASE 
      WHEN t.tgtype & 2 > 0 AND t.tgtype & 16 > 0 THEN 'INSERT y UPDATE'
      WHEN t.tgtype & 2 > 0 THEN 'INSERT solamente'
      WHEN t.tgtype & 16 > 0 THEN 'UPDATE solamente'
      ELSE 'Otro evento'
    END
  INTO trigger_events
  FROM 
    pg_trigger t
  JOIN 
    pg_class c ON t.tgrelid = c.oid
  WHERE 
    c.relname = 'messages' AND
    t.tgname = 'message_webhook_trigger';
  
  IF trigger_events = 'INSERT y UPDATE' THEN
    RAISE NOTICE 'VERIFICACIÓN EXITOSA: El trigger responde a eventos INSERT y UPDATE';
  ELSE
    RAISE WARNING 'ERROR: El trigger responde a %s, debería responder a INSERT y UPDATE', trigger_events;
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
  has_sender_client_check BOOLEAN;
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
  has_sender_client_check := function_source LIKE '%NEW.sender != ''client''%';
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
  
  IF has_sender_client_check THEN
    RAISE NOTICE 'VERIFICACIÓN EXITOSA: La función contiene la verificación de sender = client';
  ELSE
    RAISE WARNING 'ERROR: La función NO contiene la verificación de sender = client';
  END IF;
  
  IF has_ia_prefix_check THEN
    RAISE NOTICE 'VERIFICACIÓN EXITOSA: La función contiene la verificación de prefijo [IA]';
  ELSE
    RAISE WARNING 'ERROR: La función NO contiene la verificación de prefijo [IA]';
  END IF;
END;
$$;

-- 4. Verificar que la función process_pending_ia_messages existe
DO $$
DECLARE
  function_exists BOOLEAN;
BEGIN
  SELECT EXISTS (
    SELECT 1
    FROM pg_proc p
    JOIN pg_namespace n ON p.pronamespace = n.oid
    WHERE p.proname = 'process_pending_ia_messages' AND n.nspname = 'public'
  ) INTO function_exists;
  
  IF function_exists THEN
    RAISE NOTICE 'VERIFICACIÓN EXITOSA: La función process_pending_ia_messages existe';
  ELSE
    RAISE WARNING 'ERROR: La función process_pending_ia_messages NO existe';
  END IF;
END;
$$;

-- 5. Verificar si hay mensajes recientes con asistente_ia_activado=true que no tienen ia_webhook_sent=true
DO $$
DECLARE
  unprocessed_count INTEGER;
  msg RECORD;
BEGIN
  SELECT COUNT(*) INTO unprocessed_count
  FROM messages
  WHERE 
    created_at > NOW() - INTERVAL '1 day' AND
    sender = 'client' AND
    status = 'sent' AND
    asistente_ia_activado = TRUE AND
    (ia_webhook_sent IS NULL OR ia_webhook_sent = FALSE) AND
    content NOT LIKE '[IA]%';
  
  IF unprocessed_count = 0 THEN
    RAISE NOTICE 'VERIFICACIÓN EXITOSA: No hay mensajes recientes de clientes con asistente_ia_activado=true que no tengan ia_webhook_sent=true';
  ELSE
    RAISE WARNING 'ADVERTENCIA: Hay % mensajes recientes de clientes con asistente_ia_activado=true que no tienen ia_webhook_sent=true', unprocessed_count;
    
    -- Mostrar algunos ejemplos de estos mensajes
    RAISE NOTICE 'Ejemplos de mensajes no procesados:';
    FOR msg IN (
      SELECT id, conversation_id, content, created_at
      FROM messages
      WHERE 
        created_at > NOW() - INTERVAL '1 day' AND
        sender = 'client' AND
        status = 'sent' AND
        asistente_ia_activado = TRUE AND
        (ia_webhook_sent IS NULL OR ia_webhook_sent = FALSE) AND
        content NOT LIKE '[IA]%'
      ORDER BY created_at DESC
      LIMIT 5
    ) LOOP
      RAISE NOTICE 'ID: %, Conversación: %, Contenido: %, Creado: %', 
        msg.id, msg.conversation_id, msg.content, msg.created_at;
    END LOOP;
  END IF;
END;
$$;

-- 6. Verificar si la política RLS para message_whatsapp_status existe
DO $$
DECLARE
  policy_exists BOOLEAN;
BEGIN
  IF EXISTS (
    SELECT 1
    FROM information_schema.tables
    WHERE table_name = 'message_whatsapp_status'
  ) THEN
    SELECT EXISTS (
      SELECT 1
      FROM pg_policies
      WHERE tablename = 'message_whatsapp_status' AND policyname = 'Allow inserts from system'
    ) INTO policy_exists;
    
    IF policy_exists THEN
      RAISE NOTICE 'VERIFICACIÓN EXITOSA: La política RLS "Allow inserts from system" existe para la tabla message_whatsapp_status';
    ELSE
      RAISE WARNING 'ERROR: La política RLS "Allow inserts from system" NO existe para la tabla message_whatsapp_status';
    END IF;
  ELSE
    RAISE NOTICE 'La tabla message_whatsapp_status no existe, no se puede verificar la política RLS';
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

-- 9. Verificar si hay mensajes recientes que han sido enviados al webhook de IA
DO $$
DECLARE
  processed_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO processed_count
  FROM messages
  WHERE 
    created_at > NOW() - INTERVAL '1 day' AND
    sender = 'client' AND
    asistente_ia_activado = TRUE AND
    ia_webhook_sent = TRUE;
  
  IF processed_count > 0 THEN
    RAISE NOTICE 'VERIFICACIÓN EXITOSA: Hay % mensajes recientes que han sido enviados al webhook de IA', processed_count;
  ELSE
    RAISE WARNING 'ADVERTENCIA: No hay mensajes recientes que hayan sido enviados al webhook de IA';
  END IF;
END;
$$;

-- 10. Verificar si hay clientes duplicados
DO $$
DECLARE
  duplicate_count INTEGER;
  dup RECORD;
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
    
    -- Mostrar algunos ejemplos de clientes duplicados
    RAISE NOTICE 'Ejemplos de clientes duplicados:';
    FOR dup IN (
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
      ORDER BY count DESC
      LIMIT 5
    ) LOOP
      RAISE NOTICE 'Teléfono: %, Cantidad: %', dup.phone, dup.count;
    END LOOP;
  END IF;
END;
$$;

-- Resumen final
DO $$
BEGIN
  RAISE NOTICE '------------------------------------------------------------';
  RAISE NOTICE 'RESUMEN DE VERIFICACIÓN DE LA SOLUCIÓN MEJORADA';
  RAISE NOTICE '------------------------------------------------------------';
  RAISE NOTICE 'Si todas las verificaciones son exitosas, la solución se ha aplicado correctamente.';
  RAISE NOTICE 'Si hay advertencias o errores, revisa las instrucciones en README-solucion-webhook-ia-actualizada.md';
  RAISE NOTICE '------------------------------------------------------------';
END;
$$;

-- Insertar un mensaje de prueba con asistente_ia_activado=true para verificar la solución
DO $$
DECLARE
  test_conversation_id UUID;
  test_client_id UUID;
  test_message_id UUID;
  message_record RECORD;
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
    'VERIFICACIÓN FINAL: Mensaje de prueba para webhook de IA ' || NOW(),
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
  INTO message_record
  FROM 
    messages
  WHERE 
    id = test_message_id;
    
  -- Mostrar los resultados
  RAISE NOTICE 'Mensaje ID: %, Enviado al webhook: %', 
    message_record.id, 
    message_record.ia_webhook_sent;
    
  IF message_record.ia_webhook_sent = TRUE THEN
    RAISE NOTICE 'VERIFICACIÓN FINAL EXITOSA: El mensaje de prueba fue enviado al webhook de IA';
  ELSE
    RAISE WARNING 'ERROR EN VERIFICACIÓN FINAL: El mensaje de prueba NO fue enviado al webhook de IA';
  END IF;
END;
$$;
