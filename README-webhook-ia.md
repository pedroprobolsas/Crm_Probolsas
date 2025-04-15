# Implementación de Webhook de IA para Mensajes con Asistente IA Activado

Este documento proporciona instrucciones para implementar y probar un webhook de IA que se dispara automáticamente cuando se inserta un mensaje con el botón "Asistente IA" activado.

## Descripción de la Funcionalidad

La funcionalidad implementada permite:

1. Que los usuarios activen un botón de "Asistente IA" antes de enviar un mensaje
2. Que los mensajes enviados con este botón activado se marquen con `asistente_ia_activado = true`
3. Que el backend detecte automáticamente estos mensajes y los envíe a un webhook de IA
4. Que el webhook reciba toda la información del mensaje y del cliente para proporcionar contexto completo

## Archivos Creados

1. **Migración SQL**
   - `supabase/migrations/20250416000000_add_ia_webhook_support.sql`: Migración que implementa el webhook de IA

2. **Scripts de Aplicación y Prueba**
   - `apply_ia_webhook_migration.ps1`: Script PowerShell para ayudar a aplicar la migración
   - `test_ia_webhook.sql`: Script SQL para probar el webhook de IA después de aplicar la migración

## Cambios Realizados

La migración realiza los siguientes cambios:

1. **Añade un nuevo campo a la tabla messages**
   ```sql
   ALTER TABLE messages 
   ADD COLUMN IF NOT EXISTS asistente_ia_activado BOOLEAN DEFAULT FALSE;
   ```

2. **Configura las URLs del webhook de IA en app_settings**
   ```sql
   INSERT INTO app_settings (key, value, description) VALUES
   ('webhook_url_ia_production', 'https://ippwebhookn8n.probolsas.co/webhook/d2d918c0-7132-43fe-9e8c-e07b033f2e6b', 'URL del webhook de IA en producción'),
   ('webhook_url_ia_test', 'https://ippn8n.probolsas.co/webhook-test/d2d918c0-7132-43fe-9e8c-e07b033f2e6b', 'URL del webhook de IA en entorno de pruebas')
   ON CONFLICT (key) DO UPDATE 
   SET value = EXCLUDED.value,
       description = EXCLUDED.description,
       updated_at = now();
   ```

3. **Modifica la función notify_message_webhook**
   - Mantiene la lógica existente para webhooks regulares
   - Añade nueva lógica para enviar mensajes al webhook de IA cuando:
     - `sender = 'client'`
     - `status = 'sent'`
     - `asistente_ia_activado = true`
   - Incluye todos los campos posibles del mensaje y del cliente en el payload

## Pasos para Implementar

### 1. Aplicar la Migración

Ejecuta el script PowerShell para aplicar la migración:

```powershell
.\apply_ia_webhook_migration.ps1
```

O aplica la migración directamente usando la consola SQL de Supabase o psql:

```sql
\i supabase/migrations/20250416000000_add_ia_webhook_support.sql
```

Si estás usando Supabase CLI:

```bash
supabase db execute --file supabase/migrations/20250416000000_add_ia_webhook_support.sql
```

### 2. Probar el Webhook de IA

Ejecuta el script de prueba para verificar que el webhook de IA funciona correctamente:

```sql
\i test_ia_webhook.sql
```

Este script:
- Verifica que el campo `asistente_ia_activado` existe en la tabla `messages`
- Verifica las URLs del webhook de IA en `app_settings`
- Verifica que la función `notify_message_webhook` existe y contiene la lógica para el webhook de IA
- Verifica que el trigger `message_webhook_trigger` está activo
- Inserta un mensaje de prueba con `asistente_ia_activado = true`
- Verifica los mensajes recientes con `asistente_ia_activado = true`
- Proporciona instrucciones para verificar los logs y probar manualmente con diferentes valores

### 3. Verificar los Logs

Para verificar si el mensaje fue enviado correctamente al webhook de IA:

1. Accede a la consola de Supabase
2. Ve a la sección de Logs
3. Busca mensajes relacionados con "IA webhook", como:
   - "Selected IA webhook URL: X (is_production=true/false)"
   - "IA webhook payload: {...}"
   - "IA webhook request succeeded for message ID: X"

## Implementación en el Frontend

Para el frontend, necesitarás implementar:

1. Un botón de "Asistente IA" en la interfaz de chat que el usuario pueda activar antes de enviar un mensaje
2. Lógica para incluir el campo `asistente_ia_activado` al enviar el mensaje:

```typescript
// Ejemplo de implementación en React/TypeScript
const [iaAssistantActive, setIaAssistantActive] = useState(false);

// Botón para activar/desactivar el asistente de IA
<Button 
  onClick={() => setIaAssistantActive(!iaAssistantActive)}
  variant={iaAssistantActive ? "contained" : "outlined"}
  color="primary"
>
  {iaAssistantActive ? "Asistente IA Activado" : "Activar Asistente IA"}
</Button>

// Al enviar el mensaje
const sendMessage = async (messageText: string) => {
  const messageData = {
    conversation_id: conversationId,
    content: messageText,
    sender: 'client',
    sender_id: clientId,
    type: 'text',
    status: 'sent',
    asistente_ia_activado: iaAssistantActive // true si el botón está activado
  };
  
  // Enviar a Supabase
  await supabase.from('messages').insert(messageData);
  
  // Resetear el estado del asistente IA después de enviar
  setIaAssistantActive(false);
};
```

## Comportamiento Esperado

1. **Mensajes de cliente con asistente_ia_activado=true**
   - Se envían al webhook regular de cliente
   - Se envían al webhook de IA
   - El payload incluye todos los campos del mensaje y del cliente

2. **Mensajes de cliente con asistente_ia_activado=false**
   - Se envían solo al webhook regular de cliente
   - No se envían al webhook de IA

3. **Mensajes de agente (independientemente de asistente_ia_activado)**
   - Se envían solo al webhook regular de agente
   - No se envían al webhook de IA

## Solución de Problemas

Si el webhook de IA no funciona correctamente, verifica:

1. Que el campo `asistente_ia_activado` se haya añadido correctamente a la tabla `messages`
2. Que las URLs del webhook de IA estén configuradas correctamente en `app_settings`
3. Que la función `notify_message_webhook` contenga la lógica para el webhook de IA
4. Que el trigger `message_webhook_trigger` esté activo
5. Que los logs de Supabase no muestren errores relacionados con el webhook de IA
6. Que el webhook de IA sea accesible desde Supabase
