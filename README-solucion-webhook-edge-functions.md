# Solución para Problemas con Webhook de IA y Edge Functions

Este documento proporciona una solución detallada para resolver los problemas donde los mensajes de clientes no están llegando al webhook de IA, y los mensajes de agentes se están tratando incorrectamente.

## Diagnóstico del Problema

Después de analizar el código y la configuración, se identificaron las siguientes posibles causas:

1. **El campo `asistente_ia_activado` no está establecido como `true`** en los mensajes enviados por los clientes.
2. **El trigger `message_webhook_trigger` podría no estar funcionando correctamente** o estar en conflicto con otros triggers.
3. **Las Edge Functions podrían estar interfiriendo** con el envío de mensajes al webhook de IA.
4. **Las URLs del webhook de IA podrían no estar configuradas correctamente** en la tabla `app_settings`.

## Solución Implementada

Se han creado varios scripts para diagnosticar y corregir el problema:

1. **diagnose_webhook_triggers.sql**: Script SQL para diagnosticar problemas con los triggers y webhooks.
2. **run_webhook_triggers_diagnosis.ps1**: Script PowerShell para ejecutar el diagnóstico.
3. **fix_webhook_edge_functions.sql**: Script SQL para corregir los problemas identificados.
4. **apply_fix_webhook_edge_functions.ps1**: Script PowerShell para aplicar la corrección.
5. **check_edge_functions.md**: Instrucciones para verificar las Edge Functions.

### Correcciones Aplicadas

El script de corrección `fix_webhook_edge_functions.sql` realiza las siguientes acciones:

1. **Verifica y actualiza las URLs del webhook de IA en app_settings**:
   ```sql
   INSERT INTO app_settings (key, value, description) VALUES
   ('webhook_url_ia_production', 'https://ippwebhookn8n.probolsas.co/webhook/d2d918c0-7132-43fe-9e8c-e07b033f2e6b', 'URL del webhook de IA en producción'),
   ('webhook_url_ia_test', 'https://ippn8n.probolsas.co/webhook-test/d2d918c0-7132-43fe-9e8c-e07b033f2e6b', 'URL del webhook de IA en entorno de pruebas')
   ON CONFLICT (key) DO UPDATE 
   SET value = EXCLUDED.value,
       description = EXCLUDED.description,
       updated_at = now();
   ```

2. **Recrea la función `notify_message_webhook`** con la lógica correcta para asegurar que procese correctamente los mensajes de clientes con asistente IA activado.

3. **Recrea el trigger `message_webhook_trigger`** para asegurarse de que esté usando la función actualizada:
   ```sql
   DROP TRIGGER IF EXISTS message_webhook_trigger ON messages;
   CREATE TRIGGER message_webhook_trigger
   AFTER INSERT ON messages
   FOR EACH ROW
   EXECUTE FUNCTION notify_message_webhook();
   ```

4. **Verifica otros triggers que puedan estar interfiriendo** con el funcionamiento correcto del webhook.

5. **Verifica y crea la función `http_post`** si no existe, para manejar correctamente las solicitudes HTTP.

6. **Verifica e instala la extensión http** si no está disponible.

7. **Actualiza el mensaje "Prueba 1500"** para que tenga `asistente_ia_activado = true`:
   ```sql
   UPDATE messages
   SET asistente_ia_activado = TRUE
   WHERE content = 'Prueba 1500' AND sender = 'client' AND status = 'sent';
   ```

8. **Inserta un mensaje de prueba** con `asistente_ia_activado = true` para verificar que el webhook funciona correctamente.

## Verificación de Edge Functions

Además de las correcciones en la base de datos, es importante verificar las Edge Functions que podrían estar interfiriendo con el webhook de IA. El documento `check_edge_functions.md` proporciona instrucciones detalladas para:

1. **Examinar la función `messages-incoming`** para verificar si está procesando mensajes entrantes y cómo los está manejando.
2. **Examinar la función `messages-outgoing`** para verificar si está procesando mensajes salientes y cómo los está manejando.
3. **Verificar los logs de las Edge Functions** para detectar posibles errores.

## Cómo Aplicar la Solución

### Método 1: Usando los Scripts PowerShell

1. Ejecuta el script PowerShell `run_webhook_triggers_diagnosis.ps1` para diagnosticar el problema:
   ```powershell
   .\run_webhook_triggers_diagnosis.ps1
   ```

2. Sigue las instrucciones que aparecen en la consola para ejecutar el diagnóstico.

3. Ejecuta el script PowerShell `apply_fix_webhook_edge_functions.ps1` para aplicar la corrección:
   ```powershell
   .\apply_fix_webhook_edge_functions.ps1
   ```

4. Sigue las instrucciones que aparecen en la consola para aplicar la corrección.

5. Verifica las Edge Functions según las instrucciones en `check_edge_functions.md`.

### Método 2: Aplicación Manual

1. Accede a la consola SQL de Supabase.
2. Copia y pega el contenido del archivo `diagnose_webhook_triggers.sql`.
3. Ejecuta el script y revisa los resultados.
4. Copia y pega el contenido del archivo `fix_webhook_edge_functions.sql`.
5. Ejecuta el script y revisa los resultados.
6. Verifica los logs de Supabase para confirmar que el webhook de IA está funcionando correctamente.
7. Verifica las Edge Functions según las instrucciones en `check_edge_functions.md`.

## Verificación

Para verificar que la solución ha funcionado correctamente:

1. Envía un nuevo mensaje desde la interfaz de usuario con el botón de asistente IA activado.
2. Verifica en los logs de Supabase que el mensaje se ha enviado al webhook de IA.
3. Confirma que el webhook de IA ha recibido el mensaje correctamente.
4. Verifica que los mensajes de agentes se manejen correctamente y no se traten como mensajes de clientes.

## Explicación Técnica

### Problema con el Webhook de IA

El problema principal era que los mensajes de los clientes no estaban llegando al webhook de IA porque:

1. El campo `asistente_ia_activado` no estaba establecido como `true` en los mensajes enviados por los clientes.
2. La función `notify_message_webhook` solo enviaba mensajes al webhook de IA cuando se cumplían tres condiciones:
   - `status = 'sent'`
   - `sender = 'client'`
   - `asistente_ia_activado = true`

### Problema con los Mensajes de Agentes

El problema con los mensajes de agentes era que se estaban tratando incorrectamente como mensajes de clientes en algún punto del proceso. Esto podría deberse a:

1. Un error en la función `notify_message_webhook`.
2. Interferencia de las Edge Functions.

### Solución Técnica

La solución implementada:

1. Actualiza el campo `asistente_ia_activado` para los mensajes existentes.
2. Asegura que el trigger `message_webhook_trigger` esté activo y usando la función correcta.
3. Recrea la función `notify_message_webhook` con la lógica correcta para manejar tanto mensajes de clientes como de agentes.
4. Verifica que todas las dependencias (extensión http, función http_post) estén disponibles.
5. Proporciona instrucciones para verificar las Edge Functions que podrían estar interfiriendo.

## Prevención de Problemas Futuros

Para evitar que estos problemas vuelvan a ocurrir:

1. **Asegúrate de que el botón de asistente IA esté activado** cuando se envían mensajes que deben ser procesados por el webhook de IA.
2. **Verifica periódicamente los logs de Supabase** para detectar errores relacionados con el webhook.
3. **Implementa pruebas automatizadas** para verificar que el webhook de IA está funcionando correctamente.
4. **Documenta claramente la interacción entre los triggers de la base de datos y las Edge Functions** para facilitar el mantenimiento futuro.

## Recursos Adicionales

- [README-webhook-ia.md](README-webhook-ia.md): Documentación original sobre la implementación del webhook de IA.
- [test_ia_webhook.sql](test_ia_webhook.sql): Script SQL para probar el webhook de IA.
- [check_edge_functions.md](check_edge_functions.md): Instrucciones para verificar las Edge Functions.
