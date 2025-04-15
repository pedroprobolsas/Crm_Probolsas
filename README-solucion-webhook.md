# Solución para el Problema del Webhook de Mensajes de Clientes

Este documento proporciona instrucciones para solucionar el problema donde los mensajes de clientes con estado `sent` no están siendo enviados al webhook, mientras que los mensajes de agentes sí funcionan correctamente.

## Archivos de Solución

Se han creado los siguientes archivos para diagnosticar y solucionar el problema:

1. **Scripts de Diagnóstico y Solución**
   - `debug_client_info.sql`: Script que verifica si la consulta que obtiene la información del cliente está funcionando correctamente.
   - `use_http_extension_fixed.sql`: Script que modifica la función `notify_message_webhook` para usar la extensión `http` en lugar de `pg_net`.
   - `supabase/migrations/20250415000000_fix_client_webhook_with_http.sql`: Migración de Supabase que implementa la solución con la extensión HTTP.

2. **Scripts de Prueba**
   - `test_client_webhook.sh`: Script bash para probar manualmente el webhook para clientes en Linux/Mac.
   - `Test-ClientWebhook.ps1`: Script PowerShell para probar manualmente el webhook para clientes en Windows.
   - `test_fix_client_webhook.sql`: Script SQL para probar si la solución funciona después de aplicar la migración.

3. **Scripts de Aplicación**
   - `apply_fix_client_webhook.ps1`: Script PowerShell para ayudar a aplicar la migración que soluciona el problema.

## Pasos para Solucionar el Problema

### 1. Probar Manualmente el Webhook para Clientes

Primero, verifica si la URL del webhook para clientes es accesible y responde correctamente:

**En Linux/Mac:**
```bash
./test_client_webhook.sh
```

**En Windows:**
```powershell
# Ejecutar el script PowerShell
.\Test-ClientWebhook.ps1
```

O manualmente:
```powershell
$WEBHOOK_URL = "https://ippwebhookn8n.probolsas.co/webhook/d2d918c0-7132-43fe-9e8c-e07b033f2e6b"
$PAYLOAD = @{
  id = "00000000-0000-0000-0000-000000000001"
  conversation_id = "00000000-0000-0000-0000-000000000002"
  content = "Mensaje de prueba manual"
  phone = "573001234567"
  sender = "client"
  sender_id = "00000000-0000-0000-0000-000000000003"
  type = "text"
  status = "sent"
  created_at = "2025-04-14T20:55:00.000Z"
  client = @{
    id = "00000000-0000-0000-0000-000000000003"
    name = "Cliente de Prueba"
    email = "prueba@ejemplo.com"
    phone = "573001234567"
    created_at = "2025-02-10T15:22:00Z"
  }
} | ConvertTo-Json -Depth 10

Invoke-RestMethod -Uri $WEBHOOK_URL -Method Post -Body $PAYLOAD -ContentType "application/json"
```

Si la URL responde correctamente, el problema podría estar en la función que envía los mensajes al webhook.

### 2. Ejecutar el Script de Depuración

Ejecuta el script de depuración para verificar si hay problemas con la obtención de información del cliente:

```sql
\i debug_client_info.sql
```

Este script verificará:
- Si hay mensajes recientes de clientes con estado 'sent'
- Si las conversaciones tienen client_id válidos
- Si la consulta que obtiene la información del cliente funciona correctamente
- La estructura de las tablas clients y conversations
- La relación entre conversations y clients
- La construcción del payload para un mensaje de cliente
- Las URLs de webhook en app_settings
- El entorno actual

Revisa los resultados para identificar posibles problemas.

### 2. Implementar la Solución con HTTP Extension

Si el script de depuración no identifica problemas específicos, o si quieres probar directamente la solución alternativa, ejecuta:

```sql
\i use_http_extension_fixed.sql
```

Este script:
1. Verifica que la extensión `http` esté instalada
2. Crea una función `http_post` que usa la extensión `http`
3. Modifica la función `notify_message_webhook` para usar `http_post` en lugar de `net.http_post`
4. Recrea el trigger e inserta un mensaje de prueba

La principal ventaja de esta solución es que:
- Proporciona respuestas síncronas en lugar de asíncronas
- Incluye más logging para identificar exactamente dónde está fallando
- Maneja los errores de forma más explícita

### 3. Verificar los Logs

Después de implementar la solución, verifica los logs de Supabase para ver si hay información adicional sobre el problema:

1. Accede a la consola de Supabase
2. Ve a la sección de Logs
3. Busca mensajes relacionados con "webhook", "http_post", o "notify_message_webhook"

### 4. Probar con un Mensaje de Cliente

Inserta un mensaje de prueba para verificar si la solución funciona:

```sql
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
```

## Explicación Técnica del Problema

El problema podría estar relacionado con uno o más de los siguientes factores:

1. **Manejo asíncrono de pg_net**: La extensión `pg_net` realiza solicitudes HTTP de forma asíncrona, lo que significa que no espera una respuesta. Esto puede hacer que sea difícil detectar errores.

2. **Problemas con la obtención de información del cliente**: Si hay un problema al obtener la información del cliente para el `conversation_id` dado, el payload podría no incluir la información necesaria.

3. **Diferencias en el manejo de URLs**: Podría haber diferencias en cómo se manejan las URLs para clientes vs. agentes.

La solución implementada aborda estos problemas al:
- Usar la extensión `http` que proporciona respuestas síncronas
- Agregar más logging para identificar problemas con la obtención de información del cliente
- Manejar los errores de forma más explícita

## Solución a Largo Plazo

Si la solución implementada resuelve el problema, considera:

1. Mantener la implementación con la extensión `http` como solución permanente
2. Agregar más logging y manejo de errores en otras partes del sistema
3. Implementar pruebas automatizadas para verificar que los webhooks funcionen correctamente
