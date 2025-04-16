# Solución para el Problema del Webhook de IA

Este documento proporciona una solución detallada para el problema donde los mensajes de clientes no están llegando al webhook de IA, aunque se están almacenando correctamente en Supabase.

## Diagnóstico del Problema

Después de analizar el código y la configuración, se identificaron las siguientes posibles causas:

1. **El campo `asistente_ia_activado` no está establecido como `true`** en los mensajes enviados por los clientes.
2. **El trigger `message_webhook_trigger` podría no estar activo** o no estar funcionando correctamente.
3. **La función `notify_message_webhook` podría tener un error** en la lógica que maneja los mensajes de clientes con asistente IA activado.
4. **Las URLs del webhook de IA podrían no estar configuradas correctamente** en la tabla `app_settings`.

## Solución Implementada

Se han creado varios scripts para diagnosticar y corregir el problema:

1. **diagnose_ia_webhook.sql**: Script SQL para diagnosticar el problema.
2. **run_ia_webhook_diagnosis.ps1**: Script PowerShell para ejecutar el diagnóstico.
3. **fix_ia_webhook.sql**: Script SQL para corregir el problema.
4. **apply_fix_ia_webhook.ps1**: Script PowerShell para aplicar la corrección.

### Correcciones Aplicadas

El script de corrección `fix_ia_webhook.sql` realiza las siguientes acciones:

1. **Actualiza el campo `asistente_ia_activado` para el mensaje específico "Prueba 1500"**:
   ```sql
   UPDATE messages
   SET asistente_ia_activado = TRUE
   WHERE content = 'Prueba 1500' AND sender = 'client' AND status = 'sent';
   ```

2. **Verifica y activa el trigger `message_webhook_trigger`** si está desactivado:
   ```sql
   ALTER TABLE messages ENABLE TRIGGER message_webhook_trigger;
   ```

3. **Recrea la función `notify_message_webhook`** con la lógica correcta para asegurar que procese correctamente los mensajes de clientes con asistente IA activado.

4. **Recrea el trigger `message_webhook_trigger`** para asegurarse de que esté usando la función actualizada:
   ```sql
   DROP TRIGGER IF EXISTS message_webhook_trigger ON messages;
   CREATE TRIGGER message_webhook_trigger
   AFTER INSERT ON messages
   FOR EACH ROW
   EXECUTE FUNCTION notify_message_webhook();
   ```

5. **Verifica e instala la extensión http** si no está disponible:
   ```sql
   CREATE EXTENSION IF NOT EXISTS http;
   ```

6. **Crea o actualiza la función `http_post`** para manejar correctamente las solicitudes HTTP:
   ```sql
   CREATE OR REPLACE FUNCTION http_post(
     url text,
     body text,
     headers jsonb DEFAULT '{}'::jsonb
   ) RETURNS jsonb AS $$
   -- Implementación de la función
   $$ LANGUAGE plpgsql;
   ```

7. **Inserta un mensaje de prueba** con `asistente_ia_activado = true` para verificar que el webhook funciona correctamente.

## Cómo Aplicar la Solución

### Método 1: Usando el Script PowerShell

1. Ejecuta el script PowerShell `apply_fix_ia_webhook.ps1`:
   ```powershell
   .\apply_fix_ia_webhook.ps1
   ```

2. Sigue las instrucciones que aparecen en la consola.

### Método 2: Aplicación Manual

1. Accede a la consola SQL de Supabase.
2. Copia y pega el contenido del archivo `fix_ia_webhook.sql`.
3. Ejecuta el script y revisa los resultados.
4. Verifica los logs de Supabase para confirmar que el webhook de IA está funcionando correctamente.

## Verificación

Para verificar que la solución ha funcionado correctamente:

1. Envía un nuevo mensaje desde la interfaz de usuario con el botón de asistente IA activado.
2. Verifica en los logs de Supabase que el mensaje se ha enviado al webhook de IA.
3. Confirma que el webhook de IA ha recibido el mensaje correctamente.

## Explicación Técnica

### Problema Original

El problema principal era que los mensajes de los clientes no estaban llegando al webhook de IA porque:

1. El campo `asistente_ia_activado` no estaba establecido como `true` en los mensajes enviados por los clientes.
2. La función `notify_message_webhook` solo enviaba mensajes al webhook de IA cuando se cumplían tres condiciones:
   - `status = 'sent'`
   - `sender = 'client'`
   - `asistente_ia_activado = true`

### Solución Técnica

La solución implementada:

1. Actualiza el campo `asistente_ia_activado` para los mensajes existentes.
2. Asegura que el trigger `message_webhook_trigger` esté activo.
3. Recrea la función `notify_message_webhook` con la lógica correcta.
4. Verifica que todas las dependencias (extensión http, función http_post) estén disponibles.

## Prevención de Problemas Futuros

Para evitar que este problema vuelva a ocurrir:

1. **Asegúrate de que el botón de asistente IA esté activado** cuando se envían mensajes que deben ser procesados por el webhook de IA.
2. **Verifica periódicamente los logs de Supabase** para detectar errores relacionados con el webhook.
3. **Implementa pruebas automatizadas** para verificar que el webhook de IA está funcionando correctamente.

## Recursos Adicionales

- [README-webhook-ia.md](README-webhook-ia.md): Documentación original sobre la implementación del webhook de IA.
- [test_ia_webhook.sql](test_ia_webhook.sql): Script SQL para probar el webhook de IA.
