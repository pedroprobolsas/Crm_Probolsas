/*
  # Diagnóstico y Solución de Problemas con Webhook para Mensajes de Clientes

  Este script ayuda a diagnosticar y solucionar problemas con el envío de mensajes
  de clientes al webhook. Incluye:
  
  1. Verificación de la configuración en app_settings
  2. Verificación del trigger y la función
  3. Pruebas de envío de mensajes
  4. Verificación de permisos y extensiones
  5. Soluciones potenciales
*/

-- 1. Verificar las entradas en app_settings
SELECT key, value, updated_at 
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
  CASE WHEN t.tgenabled = 'D' THEN 'DESACTIVADO' ELSE 'ACTIVADO' END AS status,
  pg_get_triggerdef(t.oid) AS trigger_definition
FROM pg_trigger t
JOIN pg_class c ON t.tgrelid = c.oid
JOIN pg_namespace n ON c.relnamespace = n.oid
WHERE t.tgname = 'message_webhook_trigger';

-- 4. Verificar que la función notify_message_webhook exista
SELECT 
  p.proname AS function_name,
  pg_get_function_result(p.oid) AS result_type,
  pg_get_functiondef(p.oid) AS function_definition
FROM pg_proc p
JOIN pg_namespace n ON p.pronamespace = n.oid
WHERE p.proname = 'notify_message_webhook';

-- 5. Verificar que la extensión pg_net esté instalada y disponible
SELECT extname, extversion 
FROM pg_extension 
WHERE extname = 'pg_net';

-- 6. Verificar permisos de la función notify_message_webhook
SELECT 
  n.nspname AS schema_name,
  p.proname AS function_name,
  pg_get_userbyid(p.proowner) AS function_owner,
  CASE WHEN p.prosecdef THEN 'SECURITY DEFINER' ELSE 'SECURITY INVOKER' END AS security
FROM pg_proc p
JOIN pg_namespace n ON p.pronamespace = n.oid
WHERE p.proname = 'notify_message_webhook';

-- 7. Verificar mensajes recientes con sender='client' y status='sent'
SELECT id, conversation_id, sender, sender_id, status, created_at
FROM messages
WHERE sender = 'client' AND status = 'sent'
ORDER BY created_at DESC
LIMIT 10;

-- 8. Solución 1: Asegurarse de que la URL del webhook sea accesible
-- Probar manualmente la URL con una herramienta como curl o Postman

-- 9. Solución 2: Activar logging detallado para depurar
-- Nota: Para activar logging detallado, ejecuta estos comandos manualmente
-- reemplazando 'nombre_de_tu_base_de_datos' con el nombre real de tu base de datos
/*
ALTER DATABASE nombre_de_tu_base_de_datos SET log_min_messages = 'debug';
ALTER DATABASE nombre_de_tu_base_de_datos SET log_statement = 'all';
*/

-- En su lugar, podemos usar RAISE NOTICE para mostrar información
RAISE NOTICE '
Para activar logging detallado:
1. Ejecuta los siguientes comandos reemplazando "nombre_de_tu_base_de_datos" con el nombre real de tu base de datos:
   ALTER DATABASE nombre_de_tu_base_de_datos SET log_min_messages = "debug";
   ALTER DATABASE nombre_de_tu_base_de_datos SET log_statement = "all";
2. Reinicia la conexión a la base de datos para que los cambios surtan efecto
';

-- 10. Solución 3: Probar el envío manual al webhook
DO $$
DECLARE
  webhook_url TEXT;
  payload JSONB;
  client_id UUID;
  conversation_id UUID;
BEGIN
  -- Obtener la URL del webhook para clientes en producción
  SELECT value INTO webhook_url 
  FROM app_settings 
  WHERE key = 'webhook_url_client_production';
  
  -- Obtener un client_id y conversation_id para la prueba
  SELECT c.id, conv.id INTO client_id, conversation_id
  FROM clients c
  JOIN conversations conv ON c.id = conv.client_id
  LIMIT 1;
  
  -- Crear un payload de prueba
  payload = jsonb_build_object(
    'id', gen_random_uuid(),
    'conversation_id', conversation_id,
    'content', 'Mensaje de prueba manual',
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
  
  -- Enviar el payload al webhook
  PERFORM net.http_post(
    url := webhook_url,
    body := payload::text,
    headers := jsonb_build_object('Content-Type', 'application/json')
  );
  
  RAISE NOTICE 'Enviado payload de prueba al webhook: %', webhook_url;
  RAISE NOTICE 'Payload: %', payload;
END;
$$;

-- 11. Solución 4: Recrear el trigger
DROP TRIGGER IF EXISTS message_webhook_trigger ON messages;

CREATE TRIGGER message_webhook_trigger
AFTER INSERT ON messages
FOR EACH ROW
EXECUTE FUNCTION notify_message_webhook();

-- 12. Solución 5: Verificar si hay errores en los logs
-- Revisar los logs de Supabase para ver si hay errores relacionados con el webhook

-- 13. Solución 6: Modificar la función para incluir más logging
CREATE OR REPLACE FUNCTION notify_message_webhook()
RETURNS TRIGGER AS $$
DECLARE
  payload JSONB;
  webhook_url TEXT;
  is_production BOOLEAN;
  client_info JSONB := NULL;
  client_record RECORD;
BEGIN
  -- Get environment configuration from app_settings table
  SELECT (value = 'true') INTO is_production 
  FROM app_settings 
  WHERE key = 'is_production_environment';
  
  -- Log the message being processed
  RAISE LOG 'Processing message: id=%, sender=%, status=%', NEW.id, NEW.sender, NEW.status;
  
  -- Only proceed if conditions are met (agent or client with status 'sent')
  IF (NEW.status = 'sent' AND (NEW.sender = 'agent' OR NEW.sender = 'client')) THEN
    BEGIN
      -- Select the correct URL based on the sender type and environment
      IF NEW.sender = 'agent' THEN
        -- Agent message URLs
        IF is_production THEN
          SELECT value INTO webhook_url 
          FROM app_settings 
          WHERE key = 'webhook_url_production';
        ELSE
          SELECT value INTO webhook_url 
          FROM app_settings 
          WHERE key = 'webhook_url_test';
        END IF;
      ELSE
        -- Client message URLs
        IF is_production THEN
          SELECT value INTO webhook_url 
          FROM app_settings 
          WHERE key = 'webhook_url_client_production';
        ELSE
          SELECT value INTO webhook_url 
          FROM app_settings 
          WHERE key = 'webhook_url_client_test';
        END IF;
      END IF;
      
      -- Log the selected URL
      RAISE LOG 'Selected webhook URL: % (is_production=%)', webhook_url, is_production;
      
      -- Create the base payload
      payload = jsonb_build_object(
        'id', NEW.id,
        'conversation_id', NEW.conversation_id,
        'content', NEW.content,
        'sender', NEW.sender,
        'sender_id', NEW.sender_id,
        'type', NEW.type,
        'status', NEW.status,
        'created_at', NEW.created_at
      );
      
      -- For client messages, add client information
      IF NEW.sender = 'client' THEN
        -- Get client information from the conversations and clients tables
        SELECT c.* INTO client_record
        FROM conversations conv
        JOIN clients c ON conv.client_id = c.id
        WHERE conv.id = NEW.conversation_id;
        
        IF FOUND THEN
          -- Log the client information found
          RAISE LOG 'Found client info: id=%, name=%, phone=%', 
            client_record.id, client_record.name, client_record.phone;
          
          -- Add client information to the payload
          client_info = jsonb_build_object(
            'id', client_record.id,
            'name', client_record.name,
            'email', client_record.email,
            'phone', client_record.phone,
            'created_at', client_record.created_at
          );
          
          -- Add phone to the main payload and client object to the payload
          payload = payload || jsonb_build_object(
            'phone', client_record.phone,
            'client', client_info
          );
        ELSE
          -- Log that no client information was found
          RAISE WARNING 'No client information found for conversation_id: %', NEW.conversation_id;
        END IF;
      END IF;
      
      -- Log the final payload
      RAISE LOG 'Final payload: %', payload;
      
      -- Log the attempt
      RAISE LOG 'Sending % message to webhook: %, URL: %', NEW.sender, NEW.id, webhook_url;
      
      -- Use pg_net to send the request
      BEGIN
        PERFORM net.http_post(
          url := webhook_url,
          body := payload::text,
          headers := jsonb_build_object('Content-Type', 'application/json')
        );
        
        -- Log that we initiated the request
        RAISE LOG 'Webhook request initiated for % message ID: %', NEW.sender, NEW.id;
      EXCEPTION WHEN OTHERS THEN
        -- Log error but don't affect the transaction
        RAISE WARNING 'Error sending to webhook: %. Message ID % was still saved.', SQLERRM, NEW.id;
      END;
    EXCEPTION WHEN OTHERS THEN
      -- Log any other errors but don't affect the transaction
      RAISE WARNING 'Error in webhook function: %. Message ID % was still saved.', SQLERRM, NEW.id;
    END;
  ELSE
    -- Log why the message was skipped
    RAISE LOG 'Message skipped: id=%, sender=%, status=%', NEW.id, NEW.sender, NEW.status;
  END IF;
  
  -- Always return NEW to ensure the trigger doesn't interfere with the operation
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 14. Solución 7: Insertar un mensaje de prueba
INSERT INTO messages (
  conversation_id,
  content,
  sender,
  sender_id,
  type,
  status
)
SELECT 
  id AS conversation_id,
  'Mensaje de prueba para webhook de cliente',
  'client',
  client_id,
  'text',
  'sent'
FROM conversations
LIMIT 1;
