/*
  # Depuración de la Obtención de Información del Cliente

  Este script verifica si la consulta que obtiene la información del cliente
  está funcionando correctamente y si los datos del cliente existen y son accesibles.
*/

-- 1. Verificar si hay mensajes recientes de clientes con estado 'sent'
SELECT id, conversation_id, sender, sender_id, status, created_at
FROM messages
WHERE sender = 'client' AND status = 'sent'
ORDER BY created_at DESC
LIMIT 5;

-- 2. Verificar si las conversaciones tienen client_id válidos
SELECT 
  c.id AS conversation_id,
  c.client_id,
  cl.id AS client_id_from_clients,
  cl.name AS client_name,
  cl.email AS client_email,
  cl.phone AS client_phone
FROM conversations c
LEFT JOIN clients cl ON c.client_id = cl.id
ORDER BY c.updated_at DESC
LIMIT 5;

-- 3. Probar la consulta que obtiene la información del cliente
DO $$
DECLARE
  test_conversation_id UUID;
  client_record RECORD;
BEGIN
  -- Obtener un conversation_id reciente
  SELECT conversation_id INTO test_conversation_id
  FROM messages
  WHERE sender = 'client' AND status = 'sent'
  ORDER BY created_at DESC
  LIMIT 1;
  
  IF test_conversation_id IS NULL THEN
    -- Si no hay mensajes recientes de clientes, obtener cualquier conversation_id
    SELECT id INTO test_conversation_id
    FROM conversations
    ORDER BY updated_at DESC
    LIMIT 1;
  END IF;
  
  RAISE NOTICE 'Probando con conversation_id: %', test_conversation_id;
  
  -- Probar la consulta que obtiene la información del cliente
  SELECT c.* INTO client_record
  FROM conversations conv
  JOIN clients c ON conv.client_id = c.id
  WHERE conv.id = test_conversation_id;
  
  IF FOUND THEN
    RAISE NOTICE 'Información del cliente encontrada:';
    RAISE NOTICE 'ID: %', client_record.id;
    RAISE NOTICE 'Nombre: %', client_record.name;
    RAISE NOTICE 'Email: %', client_record.email;
    RAISE NOTICE 'Teléfono: %', client_record.phone;
    RAISE NOTICE 'Creado: %', client_record.created_at;
  ELSE
    RAISE WARNING 'No se encontró información del cliente para conversation_id: %', test_conversation_id;
    
    -- Verificar si la conversación existe
    DECLARE
      conversation_exists BOOLEAN;
    BEGIN
      SELECT EXISTS(SELECT 1 FROM conversations WHERE id = test_conversation_id) INTO conversation_exists;
      
      IF conversation_exists THEN
        RAISE NOTICE 'La conversación existe, pero no se pudo obtener la información del cliente.';
        
        -- Verificar si la conversación tiene un client_id
        DECLARE
          client_id UUID;
        BEGIN
          SELECT c.client_id INTO client_id
          FROM conversations c
          WHERE c.id = test_conversation_id;
          
          IF client_id IS NOT NULL THEN
            RAISE NOTICE 'La conversación tiene client_id: %', client_id;
            
            -- Verificar si el cliente existe
            DECLARE
              client_exists BOOLEAN;
            BEGIN
              SELECT EXISTS(SELECT 1 FROM clients WHERE id = client_id) INTO client_exists;
              
              IF client_exists THEN
                RAISE NOTICE 'El cliente existe, pero no se pudo obtener la información.';
              ELSE
                RAISE WARNING 'El cliente con ID % no existe en la tabla clients.', client_id;
              END IF;
            END;
          ELSE
            RAISE WARNING 'La conversación no tiene un client_id.';
          END IF;
        END;
      ELSE
        RAISE WARNING 'La conversación con ID % no existe.', test_conversation_id;
      END IF;
    END;
  END IF;
END;
$$;

-- 4. Verificar la estructura de la tabla clients
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_name = 'clients'
ORDER BY ordinal_position;

-- 5. Verificar la estructura de la tabla conversations
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_name = 'conversations'
ORDER BY ordinal_position;

-- 6. Verificar la relación entre conversations y clients
SELECT
  tc.constraint_name,
  tc.table_name,
  kcu.column_name,
  ccu.table_name AS foreign_table_name,
  ccu.column_name AS foreign_column_name
FROM
  information_schema.table_constraints AS tc
  JOIN information_schema.key_column_usage AS kcu
    ON tc.constraint_name = kcu.constraint_name
  JOIN information_schema.constraint_column_usage AS ccu
    ON ccu.constraint_name = tc.constraint_name
WHERE tc.constraint_type = 'FOREIGN KEY'
  AND tc.table_name = 'conversations'
  AND ccu.table_name = 'clients';

-- 7. Probar la construcción del payload para un mensaje de cliente
DO $$
DECLARE
  test_message_id UUID;
  test_conversation_id UUID;
  client_record RECORD;
  payload JSONB;
  client_info JSONB;
BEGIN
  -- Obtener un mensaje reciente de cliente
  SELECT id, conversation_id INTO test_message_id, test_conversation_id
  FROM messages
  WHERE sender = 'client' AND status = 'sent'
  ORDER BY created_at DESC
  LIMIT 1;
  
  IF test_message_id IS NULL THEN
    RAISE NOTICE 'No se encontraron mensajes recientes de clientes.';
    RETURN;
  END IF;
  
  RAISE NOTICE 'Probando con message_id: % y conversation_id: %', test_message_id, test_conversation_id;
  
  -- Obtener la información del cliente
  SELECT c.* INTO client_record
  FROM conversations conv
  JOIN clients c ON conv.client_id = c.id
  WHERE conv.id = test_conversation_id;
  
  IF FOUND THEN
    -- Crear el payload base
    payload = jsonb_build_object(
      'id', test_message_id,
      'conversation_id', test_conversation_id,
      'content', 'Mensaje de prueba',
      'sender', 'client',
      'sender_id', client_record.id,
      'type', 'text',
      'status', 'sent',
      'created_at', now()
    );
    
    -- Agregar información del cliente
    client_info = jsonb_build_object(
      'id', client_record.id,
      'name', client_record.name,
      'email', client_record.email,
      'phone', client_record.phone,
      'created_at', client_record.created_at
    );
    
    -- Agregar phone al payload principal y client al payload
    payload = payload || jsonb_build_object(
      'phone', client_record.phone,
      'client', client_info
    );
    
    RAISE NOTICE 'Payload construido correctamente:';
    RAISE NOTICE '%', payload;
  ELSE
    RAISE WARNING 'No se pudo construir el payload porque no se encontró información del cliente.';
  END IF;
END;
$$;

-- 8. Verificar las URLs de webhook en app_settings
SELECT key, value
FROM app_settings
WHERE key LIKE 'webhook_url%';

-- 9. Verificar el entorno actual
SELECT key, value
FROM app_settings
WHERE key = 'is_production_environment';
