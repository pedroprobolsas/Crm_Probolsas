/*
  # Solución Completa para el Problema del Webhook de IA
  
  Este script SQL contiene todos los pasos necesarios para implementar la solución completa
  para el problema del webhook de IA. Ejecuta este script en la consola SQL de Supabase.
  
  Después de ejecutar este script, necesitarás desplegar las Edge Functions corregidas
  usando los comandos:
  - supabase functions deploy messages-outgoing
  - supabase functions deploy messages-incoming
  
  Los archivos de las Edge Functions corregidas están en:
  - supabase/functions/messages-outgoing/index.js
  - supabase/functions/messages-incoming/index.js
*/

-- Paso 1: Crear la tabla message_whatsapp_status para rastrear el estado de envío a WhatsApp
CREATE TABLE IF NOT EXISTS message_whatsapp_status (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  message_id UUID REFERENCES messages(id) ON DELETE CASCADE,
  sent_to_whatsapp BOOLEAN DEFAULT FALSE,
  sent_at TIMESTAMPTZ,
  delivery_status TEXT,
  error_message TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Paso 2: Crear índice para búsquedas rápidas por message_id
CREATE INDEX IF NOT EXISTS idx_message_whatsapp_status_message_id ON message_whatsapp_status(message_id);

-- Paso 3: Verificar si la función update_updated_at_column existe y crearla si no existe
DO $$
DECLARE
  func_exists BOOLEAN;
BEGIN
  SELECT EXISTS (
    SELECT 1
    FROM pg_proc p
    JOIN pg_namespace n ON p.pronamespace = n.oid
    WHERE p.proname = 'update_updated_at_column' AND n.nspname = 'public'
  ) INTO func_exists;
  
  IF NOT func_exists THEN
    -- Crear la función update_updated_at_column si no existe
    EXECUTE '
    CREATE OR REPLACE FUNCTION update_updated_at_column()
    RETURNS TRIGGER AS $$
    BEGIN
        NEW.updated_at = NOW();
        RETURN NEW;
    END;
    $$ LANGUAGE plpgsql;
    ';
    
    RAISE NOTICE 'Función update_updated_at_column creada.';
  ELSE
    RAISE NOTICE 'La función update_updated_at_column ya existe.';
  END IF;
END;
$$;

-- Paso 4: Crear trigger para actualizar updated_at
DO $$
DECLARE
  trigger_exists BOOLEAN;
BEGIN
  SELECT EXISTS (
    SELECT 1
    FROM pg_trigger t
    JOIN pg_class c ON t.tgrelid = c.oid
    WHERE t.tgname = 'update_message_whatsapp_status_updated_at' AND c.relname = 'message_whatsapp_status'
  ) INTO trigger_exists;
  
  IF NOT trigger_exists THEN
    -- Crear el trigger si no existe
    EXECUTE '
    CREATE TRIGGER update_message_whatsapp_status_updated_at
    BEFORE UPDATE ON message_whatsapp_status
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();
    ';
    
    RAISE NOTICE 'Trigger update_message_whatsapp_status_updated_at creado.';
  ELSE
    RAISE NOTICE 'El trigger update_message_whatsapp_status_updated_at ya existe.';
  END IF;
END;
$$;

-- Paso 5: Verificar si la extensión http está instalada y disponible
SELECT 
  extname, 
  extversion
FROM 
  pg_extension
WHERE 
  extname = 'http';

-- Paso 6: Instalar la extensión http si no está disponible
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_extension WHERE extname = 'http') THEN
    CREATE EXTENSION IF NOT EXISTS http;
    RAISE NOTICE 'La extensión http ha sido instalada.';
  ELSE
    RAISE NOTICE 'La extensión http ya está instalada.';
  END IF;
END;
$$;

-- Paso 7: Crear una función http_post segura para evitar errores de sintaxis
CREATE OR REPLACE FUNCTION http_post(
  url text,
  body text,
  headers jsonb DEFAULT '{}'::jsonb
) RETURNS jsonb AS $$
DECLARE
  result jsonb;
BEGIN
  -- Asegurarse de que los parámetros estén en el orden correcto
  -- y que el cuerpo se envíe como cuerpo y no como encabezado
  BEGIN
    SELECT
      content::jsonb AS response_body
    INTO
      result
    FROM
      http((
        'POST',
        url,
        ARRAY(
          SELECT (key, value)::http_header
          FROM jsonb_each_text(headers)
        ),
        body,
        5 -- timeout in seconds
      )::http_request);
      
    RETURN jsonb_build_object('success', true, 'response', result);
  EXCEPTION WHEN OTHERS THEN
    RETURN jsonb_build_object('error', SQLERRM);
  END;
END;
$$ LANGUAGE plpgsql;

-- Paso 8: Verificar las URLs del webhook de IA en app_settings
SELECT 
  key, 
  value
FROM 
  app_settings
WHERE 
  key LIKE 'webhook_url_ia%';

-- Paso 9: Actualizar las URLs del webhook de IA si es necesario
UPDATE app_settings
SET value = 'https://ippwebhookn8n.probolsas.co/webhook/d2d918c0-7132-43fe-9e8c-e07b033f2e6b'
WHERE key = 'webhook_url_ia_production';

UPDATE app_settings
SET value = 'https://ippn8n.probolsas.co/webhook-test/d2d918c0-7132-43fe-9e8c-e07b033f2e6b'
WHERE key = 'webhook_url_ia_test';

-- Paso 10: Modificar la función notify_message_webhook para incluir el contenido en el payload y corregir el formato
CREATE OR REPLACE FUNCTION notify_message_webhook()
RETURNS TRIGGER AS $$
DECLARE
  payload JSONB;
  webhook_url TEXT;
  ia_webhook_url TEXT;
  is_production BOOLEAN;
  client_info JSONB := NULL;
  client_record RECORD;
  client_full_json JSONB;
  http_result JSONB;
BEGIN
  -- Get environment configuration from app_settings table
  SELECT (value = 'true') INTO is_production 
  FROM app_settings 
  WHERE key = 'is_production_environment';
  
  -- Log the message being processed
  RAISE LOG 'Processing message: id=%, sender=%, status=%, ia_activado=%', 
    NEW.id, NEW.sender, NEW.status, NEW.asistente_ia_activado;
  
  -- Process regular webhook (existing logic)
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
        'created_at', NEW.created_at,
        'message', NEW.content  -- Añadir el contenido como 'message' para compatibilidad
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
      
      -- Use http_post function to send the request
      -- This will handle errors gracefully without failing the trigger
      http_result := http_post(
        webhook_url,
        payload::text,
        jsonb_build_object('Content-Type', 'application/json')
      );
      
      -- Log the result
      IF http_result ? 'error' THEN
        RAISE WARNING 'Webhook request failed: %. Message ID % was still saved.', 
          http_result->>'error', NEW.id;
      ELSE
        RAISE LOG 'Webhook request succeeded for message ID: %', NEW.id;
      END IF;
    EXCEPTION WHEN OTHERS THEN
      -- Log any other errors but don't affect the transaction
      RAISE WARNING 'Error in webhook function: %. Message ID % was still saved.', SQLERRM, NEW.id;
    END;
  ELSE
    -- Log why the message was skipped
    RAISE LOG 'Regular webhook skipped: id=%, sender=%, status=%', NEW.id, NEW.sender, NEW.status;
  END IF;
  
  -- Process IA webhook (new logic)
  IF (NEW.status = 'sent' AND NEW.sender = 'client' AND NEW.asistente_ia_activado IS TRUE) THEN
    BEGIN
      -- Select the correct IA webhook URL based on environment
      IF is_production THEN
        SELECT value INTO ia_webhook_url 
        FROM app_settings 
        WHERE key = 'webhook_url_ia_production';
      ELSE
        SELECT value INTO ia_webhook_url 
        FROM app_settings 
        WHERE key = 'webhook_url_ia_test';
      END IF;
      
      -- Log the selected URL
      RAISE LOG 'Selected IA webhook URL: % (is_production=%)', ia_webhook_url, is_production;
      
      -- Get complete client information using row_to_json
      SELECT row_to_json(c)::jsonb INTO client_full_json
      FROM clients c
      JOIN conversations conv ON c.id = conv.client_id
      WHERE conv.id = NEW.conversation_id;
      
      IF client_full_json IS NULL THEN
        RAISE WARNING 'No client information found for IA webhook, conversation_id: %', NEW.conversation_id;
        
        -- Create a basic payload without client info
        payload = jsonb_build_object(
          'id', NEW.id,
          'conversation_id', NEW.conversation_id,
          'content', NEW.content,
          'sender', NEW.sender,
          'sender_id', NEW.sender_id,
          'type', NEW.type,
          'status', NEW.status,
          'created_at', NEW.created_at,
          'asistente_ia_activado', NEW.asistente_ia_activado,
          'message', NEW.content  -- Añadir el contenido como 'message' para compatibilidad
        );
      ELSE
        -- Create the payload with complete client info
        payload = jsonb_build_object(
          'id', NEW.id,
          'conversation_id', NEW.conversation_id,
          'content', NEW.content,
          'sender', NEW.sender,
          'sender_id', NEW.sender_id,
          'type', NEW.type,
          'status', NEW.status,
          'created_at', NEW.created_at,
          'asistente_ia_activado', NEW.asistente_ia_activado,
          'phone', client_full_json->>'phone',
          'client', client_full_json,
          'message', NEW.content  -- Añadir el contenido como 'message' para compatibilidad
        );
      END IF;
      
      -- Log the final payload
      RAISE LOG 'IA webhook payload: %', payload;
      
      -- CORRECCIÓN: Asegurarse de que los parámetros estén en el orden correcto
      -- Orden correcto: (url, body, headers)
      http_result := http_post(
        ia_webhook_url,
        payload::text,  -- Este es el cuerpo (body) de la solicitud
        jsonb_build_object('Content-Type', 'application/json')  -- Estos son los encabezados (headers)
      );
      
      -- Log the result
      IF http_result ? 'error' THEN
        RAISE WARNING 'IA webhook request failed: %. Message ID % was still saved.', 
          http_result->>'error', NEW.id;
      ELSE
        RAISE LOG 'IA webhook request succeeded for message ID: %', NEW.id;
      END IF;
    EXCEPTION WHEN OTHERS THEN
      -- Log any errors but don't affect the transaction
      RAISE WARNING 'Error in IA webhook function: %. Message ID % was still saved.', SQLERRM, NEW.id;
    END;
  ELSE
    -- Log why the IA webhook was skipped
    RAISE LOG 'IA webhook skipped: id=%, sender=%, status=%, ia_activado=%', 
      NEW.id, NEW.sender, NEW.status, NEW.asistente_ia_activado;
  END IF;
  
  -- Always return NEW to ensure the trigger doesn't interfere with the operation
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Paso 11: Verificar si el trigger message_webhook_trigger está activo
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

-- Paso 12: Recrear el trigger para asegurarse de que esté usando la función actualizada
DROP TRIGGER IF EXISTS message_webhook_trigger ON messages;

CREATE TRIGGER message_webhook_trigger
AFTER INSERT ON messages
FOR EACH ROW
EXECUTE FUNCTION notify_message_webhook();

-- Paso 13: Verificar si hay mensajes de agentes que se están tratando como mensajes de clientes
-- Esto es solo para diagnóstico, no modifica nada
SELECT 
  id, 
  content, 
  sender, 
  sender_id,
  status, 
  created_at
FROM 
  messages
WHERE 
  sender = 'client' AND
  (
    -- Intentar convertir sender_id a UUID solo si tiene formato de UUID
    (sender_id ~ '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$' AND sender_id::uuid IN (SELECT id FROM agents))
    OR
    -- O verificar si sender_id está en la tabla agents como texto (para casos donde no es un UUID válido)
    sender_id IN (SELECT id::text FROM agents)
  )
ORDER BY 
  created_at DESC
LIMIT 10;

-- Paso 14: Insertar un mensaje de prueba con asistente_ia_activado=true
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
    'SOLUCIÓN COMPLETA: Mensaje de prueba para webhook de IA ' || NOW(),
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

-- Paso 15: Verificar los mensajes recientes con asistente_ia_activado=true
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

-- Paso 16: Resumen de las correcciones aplicadas
DO $$
BEGIN
  RAISE NOTICE '
  Se han aplicado las siguientes correcciones para solucionar el problema del webhook de IA:
  
  1. Se ha creado la tabla message_whatsapp_status para rastrear el estado de envío a WhatsApp
  2. Se ha verificado e instalado la extensión http
  3. Se ha creado una función http_post segura para evitar errores de sintaxis
  4. Se han verificado y actualizado las URLs del webhook de IA
  5. Se ha modificado la función notify_message_webhook para incluir el contenido en el payload y corregir el formato
  6. Se ha recreado el trigger message_webhook_trigger
  7. Se ha insertado un mensaje de prueba con asistente_ia_activado=true
  
  Ahora los datos deberían enviarse correctamente al webhook de IA en la URL:
  https://ippwebhookn8n.probolsas.co/webhook/d2d918c0-7132-43fe-9e8c-e07b033f2e6b
  
  IMPORTANTE: Para completar la solución, necesitas desplegar las Edge Functions corregidas:
  1. supabase functions deploy messages-outgoing
  2. supabase functions deploy messages-incoming
  
  Los archivos de las Edge Functions corregidas están en:
  - supabase/functions/messages-outgoing/index.js
  - supabase/functions/messages-incoming/index.js
  ';
END;
$$;
