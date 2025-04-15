# Actualización del Webhook para Mensajes de Clientes y Agentes

Este documento describe los cambios realizados para modificar la función de webhook existente para que procese tanto mensajes de agentes como de clientes.

## Cambios Realizados

1. Se agregaron nuevas entradas en la tabla `app_settings` para las URLs de webhook para clientes:
   - `webhook_url_client_production`: URL para mensajes de clientes en producción
   - `webhook_url_client_test`: URL para mensajes de clientes en entorno de pruebas

2. Se renombró la función `notify_agent_message_webhook` a `notify_message_webhook` y se modificó para:
   - Procesar mensajes tanto de agentes como de clientes con estado `sent`
   - Seleccionar la URL correcta según el tipo de remitente y el entorno
   - Para mensajes de clientes, incluir información adicional del cliente en el payload

3. Se actualizó el trigger para usar la función renombrada:
   - Se eliminó el trigger existente `agent_message_webhook_trigger`
   - Se creó un nuevo trigger `message_webhook_trigger`

4. Se actualizaron las funciones de gestión para manejar las nuevas URLs:
   - `update_webhook_urls`: Actualizada para manejar las URLs de clientes
   - `get_webhook_urls`: Actualizada para devolver las URLs para ambos tipos de remitentes

## Archivos Creados

1. `update_webhook_for_client_messages.sql`: Archivo SQL independiente con todos los cambios
2. `supabase/migrations/20250414000000_update_webhook_for_client_messages.sql`: Migración de Supabase con los mismos cambios

## Cómo Aplicar los Cambios

### Opción 1: Usando la Migración de Supabase

Si estás usando Supabase CLI para gestionar las migraciones:

```bash
supabase db push
```

O si prefieres aplicar solo esta migración específica:

```bash
supabase db execute --file supabase/migrations/20250414000000_update_webhook_for_client_messages.sql
```

### Opción 2: Aplicación Directa

Si prefieres aplicar los cambios directamente:

1. Conéctate a la base de datos de Supabase usando la consola SQL o psql
2. Ejecuta el contenido del archivo `update_webhook_for_client_messages.sql`

### Posibles Errores y Soluciones

#### Error al cambiar el tipo de retorno de una función existente

Si encuentras un error como este:

```
ERROR: 42P13: cannot change return type of existing function
DETAIL: Row type defined by OUT parameters is different.
HINT: Use DROP FUNCTION get_webhook_urls() first.
```

La solución ya está incluida en los scripts actualizados, que eliminan la función antes de recrearla:

```sql
-- Eliminar la función existente antes de recrearla con un tipo de retorno diferente
DROP FUNCTION IF EXISTS get_webhook_urls();

-- Actualizar la función para obtener URLs de webhook
CREATE FUNCTION get_webhook_urls()
RETURNS TABLE (
  sender_type TEXT,
  environment TEXT,
  url TEXT
) AS $$
...
```

## Cómo Probar los Cambios

### 1. Verificar las Entradas en app_settings

```sql
SELECT * FROM app_settings WHERE key LIKE 'webhook_url%';
```

Deberías ver 4 entradas:
- `webhook_url_production`
- `webhook_url_test`
- `webhook_url_client_production`
- `webhook_url_client_test`

### 2. Verificar la Función y el Trigger

```sql
-- Verificar la función
SELECT pg_get_functiondef('notify_message_webhook'::regproc);

-- Verificar el trigger
SELECT 
  t.tgname AS trigger_name,
  CASE WHEN t.tgenabled = 'D' THEN 'DISABLED' ELSE 'ENABLED' END AS status,
  n.nspname AS schema_name,
  c.relname AS table_name,
  pg_get_triggerdef(t.oid) AS trigger_definition
FROM pg_trigger t
JOIN pg_class c ON t.tgrelid = c.oid
JOIN pg_namespace n ON c.relnamespace = n.oid
WHERE t.tgname = 'message_webhook_trigger';
```

### 3. Probar con Mensajes de Prueba

#### Mensaje de Agente

```sql
-- Obtener un conversation_id existente
SELECT id FROM conversations LIMIT 1;

-- Insertar un mensaje de prueba de agente
INSERT INTO messages (
  conversation_id,
  content,
  sender,
  sender_id,
  type,
  status
)
VALUES (
  '00000000-0000-0000-0000-000000000000', -- Reemplazar con un conversation_id real
  'Mensaje de prueba desde un agente',
  'agent',
  '00000000-0000-0000-0000-000000000000', -- Reemplazar con un agent_id real
  'text',
  'sent'
);
```

#### Mensaje de Cliente

```sql
-- Obtener un conversation_id existente
SELECT id FROM conversations LIMIT 1;

-- Insertar un mensaje de prueba de cliente
INSERT INTO messages (
  conversation_id,
  content,
  sender,
  sender_id,
  type,
  status
)
VALUES (
  '00000000-0000-0000-0000-000000000000', -- Reemplazar con un conversation_id real
  'Mensaje de prueba desde un cliente',
  'client',
  '00000000-0000-0000-0000-000000000000', -- Reemplazar con un client_id real
  'text',
  'sent'
);
```

### 4. Verificar los Logs

Revisa los logs de Supabase para verificar que los mensajes se están enviando correctamente a los webhooks:

```sql
SELECT * FROM pg_catalog.pg_stat_activity WHERE application_name = 'postgres';
```

O revisa los logs del servidor de Supabase.

## Gestión de URLs de Webhook

### Obtener las URLs Actuales

```sql
SELECT * FROM get_webhook_urls();
```

### Actualizar las URLs

```sql
-- Actualizar la URL de producción para agentes
SELECT update_webhook_urls(
  agent_production_url := 'https://nueva-url-produccion-agentes.com/webhook',
  agent_test_url := NULL,
  client_production_url := NULL,
  client_test_url := NULL
);

-- Actualizar la URL de pruebas para clientes
SELECT update_webhook_urls(
  agent_production_url := NULL,
  agent_test_url := NULL,
  client_production_url := NULL,
  client_test_url := 'https://nueva-url-pruebas-clientes.com/webhook'
);

-- Actualizar todas las URLs
SELECT update_webhook_urls(
  agent_production_url := 'https://url-produccion-agentes.com/webhook',
  agent_test_url := 'https://url-pruebas-agentes.com/webhook',
  client_production_url := 'https://url-produccion-clientes.com/webhook',
  client_test_url := 'https://url-pruebas-clientes.com/webhook'
);
```

### Cambiar el Entorno

```sql
-- Cambiar a entorno de producción
SELECT set_environment_mode(TRUE);

-- Cambiar a entorno de pruebas
SELECT set_environment_mode(FALSE);

-- Verificar el entorno actual
SELECT get_environment_mode();
```
