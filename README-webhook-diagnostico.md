# Diagnóstico y Solución de Problemas con Webhook para Mensajes de Clientes

Este documento proporciona instrucciones para diagnosticar y solucionar problemas con el envío de mensajes de clientes al webhook.

## Problema Reportado

Los mensajes de clientes con estado `sent` se están guardando correctamente en la tabla `messages`, pero no se están enviando al webhook en producción (`https://ippwebhookn8n.probolsas.co/webhook/d2d918c0-7132-43fe-9e8c-e07b033f2e6b`).

## Scripts de Diagnóstico y Solución

Se han creado cuatro scripts para ayudar a diagnosticar y solucionar este problema:

1. **`simple_webhook_test.sql`**: Script simplificado que realiza verificaciones básicas y prueba el envío de mensajes sin operaciones complejas. **Recomendado para empezar**.
2. **`diagnose_webhook_issue.sql`**: Script completo que verifica la configuración, el trigger, la función, y proporciona varias soluciones potenciales.
3. **`check_pg_net.sql`**: Script específico para verificar si hay algún problema con la extensión `pg_net` o con la función `net.http_post`.
4. **`use_http_extension.sql`**: Script que modifica la función `notify_message_webhook` para usar la extensión `http` en lugar de `pg_net`, como una alternativa si `pg_net` no está funcionando correctamente.

## Pasos para Diagnosticar el Problema

### 1. Ejecutar el Script de Prueba Simple

Comienza con el script simplificado que es menos propenso a errores:

```sql
\i simple_webhook_test.sql
```

Este script:
- Verifica la configuración básica
- Prueba el envío manual al webhook usando tanto `http` como `pg_net`
- Inserta un mensaje de prueba real
- Muestra mensajes informativos en cada paso

Si este script identifica problemas o no resuelve el problema, continúa con los scripts más detallados.

### 2. Ejecutar el Script de Diagnóstico General

Si necesitas un diagnóstico más completo, ejecuta:

```sql
\i diagnose_webhook_issue.sql
```

Este script verificará:
- La configuración en `app_settings`
- El estado del trigger y la función
- Los mensajes recientes con `sender='client'` y `status='sent'`
- Y proporcionará varias soluciones potenciales

### 2. Verificar la Extensión pg_net

Si el diagnóstico general no resuelve el problema, ejecuta el script `check_pg_net.sql`:

```sql
\i check_pg_net.sql
```

Este script verificará:
- Si la extensión `pg_net` está instalada correctamente
- Si la función `net.http_post` existe y tiene los permisos correctos
- Probará la función `net.http_post` con un endpoint de prueba (httpbin.org)
- Probará la función `net.http_post` con la URL del webhook para clientes

### 3. Revisar los Logs

Después de ejecutar los scripts de diagnóstico, revisa los logs de Supabase para ver si hay errores relacionados con el webhook:

1. Accede a la consola de Supabase
2. Ve a la sección de Logs
3. Busca errores relacionados con "net.http_post", "pg_net", "webhook" o "notify_message_webhook"

## Soluciones Potenciales

### Solución 1: Usar la Extensión HTTP en lugar de pg_net

Si los diagnósticos indican que hay problemas con la extensión `pg_net`, puedes modificar la función para usar la extensión `http` en su lugar:

```sql
\i use_http_extension.sql
```

Este script:
1. Verifica que la extensión `http` esté instalada
2. Crea una función `http_post` que usa la extensión `http`
3. Modifica la función `notify_message_webhook` para usar `http_post` en lugar de `net.http_post`
4. Recrea el trigger e inserta un mensaje de prueba

### Solución 2: Verificar la URL del Webhook

Asegúrate de que la URL del webhook para clientes en producción sea correcta y accesible:

```sql
-- Verificar la URL actual
SELECT value FROM app_settings WHERE key = 'webhook_url_client_production';

-- Actualizar la URL si es necesario
UPDATE app_settings 
SET value = 'https://ippwebhookn8n.probolsas.co/webhook/d2d918c0-7132-43fe-9e8c-e07b033f2e6b' 
WHERE key = 'webhook_url_client_production';
```

### Solución 3: Verificar el Entorno

Asegúrate de que el sistema esté configurado para usar el entorno de producción:

```sql
-- Verificar el entorno actual
SELECT value FROM app_settings WHERE key = 'is_production_environment';

-- Cambiar a entorno de producción si es necesario
UPDATE app_settings SET value = 'true' WHERE key = 'is_production_environment';
```

### Solución 4: Recrear el Trigger

Si el trigger no está funcionando correctamente, puedes recrearlo:

```sql
-- Eliminar el trigger existente
DROP TRIGGER IF EXISTS message_webhook_trigger ON messages;

-- Crear el nuevo trigger
CREATE TRIGGER message_webhook_trigger
AFTER INSERT ON messages
FOR EACH ROW
EXECUTE FUNCTION notify_message_webhook();
```

### Solución 5: Probar con un Mensaje Manual

Puedes probar el webhook insertando un mensaje manualmente:

```sql
-- Obtener un conversation_id existente
SELECT id, client_id FROM conversations LIMIT 1;

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
  '00000000-0000-0000-0000-000000000000', -- Reemplazar con un conversation_id real
  'Mensaje de prueba para webhook de cliente',
  'client',
  '00000000-0000-0000-0000-000000000000', -- Reemplazar con un client_id real
  'text',
  'sent'
);
```

## Verificación Final

Después de aplicar alguna de las soluciones, verifica que los mensajes se estén enviando correctamente al webhook:

1. Inserta un mensaje de prueba
2. Verifica los logs para confirmar que el mensaje se envió correctamente
3. Verifica en el sistema de destino (n8n) que el mensaje se recibió correctamente

Si el problema persiste, considera:
- Verificar la configuración de red de Supabase
- Verificar si hay restricciones de firewall
- Contactar al soporte de Supabase para obtener ayuda adicional
