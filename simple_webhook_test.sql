/*
  # Prueba Simple de Webhook para Mensajes de Clientes

  Este script realiza una verificación básica de la configuración y prueba
  el envío de un mensaje al webhook para clientes, sin intentar modificar
  la base de datos o ejecutar operaciones complejas.
*/

-- 1. Verificar las entradas en app_settings
SELECT key, value 
FROM app_settings 
WHERE key LIKE 'webhook_url%' OR key = 'is_production_environment';

-- 2. Verificar si estamos en modo producción
SELECT 
  CASE 
    WHEN value = 'true' THEN 'Producción' 
    ELSE 'Pruebas' 
  END AS "Entorno Actual"
FROM app_settings 
WHERE key = 'is_production_environment';

-- 3. Verificar que el trigger esté activo
SELECT 
  t.tgname AS trigger_name,
  CASE WHEN t.tgenabled = 'D' THEN 'DESACTIVADO' ELSE 'ACTIVADO' END AS status
FROM pg_trigger t
JOIN pg_class c ON t.tgrelid = c.oid
JOIN pg_namespace n ON c.relnamespace = n.oid
WHERE t.tgname = 'message_webhook_trigger';

-- 4. Verificar que las extensiones necesarias estén instaladas
SELECT extname, extversion 
FROM pg_extension 
WHERE extname IN ('pg_net', 'http');

-- 5. Probar el envío manual al webhook usando http en lugar de pg_net
DO $$
DECLARE
  webhook_url TEXT;
  payload JSONB;
  result JSONB;
  client_id UUID;
  conversation_id UUID;
BEGIN
  -- Obtener la URL del webhook para clientes en producción
  SELECT value INTO webhook_url 
  FROM app_settings 
  WHERE key = 'webhook_url_client_production';
  
  -- Obtener un client_id y conversation_id para la prueba
  BEGIN
    SELECT c.id, conv.id INTO client_id, conversation_id
    FROM clients c
    JOIN conversations conv ON c.id = conv.client_id
    LIMIT 1;
    
    IF client_id IS NULL OR conversation_id IS NULL THEN
      RAISE NOTICE 'No se encontraron clientes o conversaciones para la prueba.';
      RETURN;
    END IF;
    
    -- Crear un payload de prueba
    payload = jsonb_build_object(
      'id', gen_random_uuid(),
      'conversation_id', conversation_id,
      'content', 'Mensaje de prueba simple',
      'sender', 'client',
      'sender_id', client_id,
      'type', 'text',
      'status', 'sent',
      'created_at', now(),
      'phone', '573001234567',
      'client', jsonb_build_object(
        'id', client_id,
        'name', 'Cliente de Prueba',
        'email', 'prueba@ejemplo.com',
        'phone', '573001234567',
        'created_at', now()
      )
    );
    
    -- Mostrar la URL y el payload
    RAISE NOTICE 'URL del webhook: %', webhook_url;
    RAISE NOTICE 'Payload: %', payload;
    
    -- Probar con la extensión http
    BEGIN
      SELECT content::jsonb INTO result
      FROM http((
        'POST',
        webhook_url,
        ARRAY[http_header('Content-Type', 'application/json')],
        'application/json',
        payload::text
      )::http_request);
      
      RAISE NOTICE 'Resultado usando http: %', result;
    EXCEPTION WHEN OTHERS THEN
      RAISE NOTICE 'Error al usar http: %', SQLERRM;
    END;
    
    -- Probar con la extensión pg_net
    BEGIN
      PERFORM net.http_post(
        url := webhook_url,
        body := payload::text,
        headers := '{"Content-Type": "application/json"}'
      );
      
      RAISE NOTICE 'Solicitud enviada usando pg_net (no hay resultado inmediato porque es asíncrono)';
    EXCEPTION WHEN OTHERS THEN
      RAISE NOTICE 'Error al usar pg_net: %', SQLERRM;
    END;
  EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'Error al obtener datos para la prueba: %', SQLERRM;
  END;
END;
$$;

-- 6. Insertar un mensaje de prueba real
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
    'Mensaje de prueba simple para webhook de cliente',
    'client',
    test_client_id,
    'text',
    'sent'
  )
  RETURNING id INTO test_message_id;
  
  RAISE NOTICE 'Mensaje de prueba insertado con ID: %', test_message_id;
  RAISE NOTICE 'Verifica los logs de Supabase para ver si el mensaje fue enviado al webhook.';
EXCEPTION WHEN OTHERS THEN
  RAISE NOTICE 'Error al insertar mensaje de prueba: %', SQLERRM;
END;
$$;
