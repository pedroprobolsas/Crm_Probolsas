# Solución Completa para el Problema del Webhook de IA

Este documento proporciona una explicación detallada del problema donde los datos no se están enviando al webhook de IA en la URL `https://ippwebhookn8n.probolsas.co/webhook/d2d918c0-7132-43fe-9e8c-e07b033f2e6b` y la solución implementada.

## Descripción del Problema

El sistema no está enviando correctamente los datos al webhook de IA. Después de analizar el código y los logs, se identificaron varios problemas:

1. **Formato de Datos Incorrecto**: Los datos del mensaje y del cliente se estaban enviando incorrectamente como parte del encabezado "content-type" en lugar de enviarse en el cuerpo (body) de la solicitud HTTP.

2. **Contenido Faltante**: El contenido del mensaje no se estaba incluyendo en el payload enviado al webhook de IA.

3. **Problemas con Edge Functions**: Las Edge Functions `messages-outgoing` y `messages-incoming` podrían estar interfiriendo con el procesamiento de mensajes.

4. **Problemas con el Trigger**: El trigger `message_webhook_trigger` podría no estar activado o podría estar configurado incorrectamente.

## Solución Implementada

Se ha creado un script SQL completo (`fix_ia_webhook_completo.sql`) que aplica todas las correcciones necesarias para solucionar el problema:

1. **Corrección del Formato de Datos**:
   - Se ha corregido la función `http_post` para asegurar que maneje correctamente los encabezados y el cuerpo.
   - Se ha modificado la función `notify_message_webhook` para asegurar que llame correctamente a `http_post` con los parámetros en el orden correcto.

2. **Inclusión del Contenido del Mensaje**:
   - Se ha modificado la función `notify_message_webhook` para incluir el contenido del mensaje en el payload como `content` y también como `message` para compatibilidad.

3. **Creación de Tabla para Rastrear el Estado de Envío a WhatsApp**:
   - Se ha creado una tabla `message_whatsapp_status` para rastrear el estado de envío a WhatsApp, en lugar de actualizar directamente los mensajes.
   - Esto evita posibles conflictos con las Edge Functions.

4. **Verificación y Activación del Trigger**:
   - Se ha recreado el trigger `message_webhook_trigger` para asegurarse de que esté usando la función actualizada.

5. **Actualización de las URLs del Webhook de IA**:
   - Se han verificado y actualizado las URLs del webhook de IA en la tabla `app_settings`.

## Archivos Creados

1. **fix_ia_webhook_completo.sql**: Script SQL que aplica todas las correcciones necesarias para solucionar el problema.

2. **apply_fix_ia_webhook_completo.ps1**: Script PowerShell simplificado para ejecutar el script SQL.

## Cómo Aplicar la Solución

### Opción 1: Usar el Script PowerShell

1. Ejecuta el script PowerShell:
   ```powershell
   .\apply_fix_ia_webhook_completo.ps1
   ```

2. Sigue las instrucciones que aparecen en la consola para proporcionar los datos de conexión a Supabase.

### Opción 2: Aplicación Manual

1. Accede a la consola SQL de Supabase.
2. Copia y pega el contenido del archivo `fix_ia_webhook_completo.sql`.
3. Ejecuta el script y revisa los resultados.

## Verificación

Para verificar que la solución ha funcionado correctamente:

1. **Envía un Mensaje de Prueba**:
   - Envía un mensaje desde la interfaz de usuario con el botón de asistente IA activado.
   - O ejecuta la sección de prueba del script SQL que inserta un mensaje de prueba.

2. **Verifica los Logs de Supabase**:
   - Accede a la consola de Supabase.
   - Ve a la sección de Logs.
   - Busca mensajes relacionados con "IA webhook", como:
     * "IA webhook payload: {...}"
     * "IA webhook request succeeded for message ID: X"

3. **Verifica la Respuesta del Webhook**:
   - Accede a la plataforma n8n o al servicio que recibe el webhook.
   - Verifica que los datos se hayan recibido correctamente en el cuerpo (body) de la solicitud.
   - Confirma que el formato de los datos sea similar a:
     ```json
     {
       "id": "uuid-del-mensaje",
       "conversation_id": "uuid-de-la-conversacion",
       "content": "Contenido del mensaje",
       "sender": "client",
       "sender_id": "uuid-del-cliente",
       "type": "text",
       "status": "sent",
       "created_at": "fecha-y-hora",
       "asistente_ia_activado": true,
       "phone": "numero-de-telefono",
       "message": "Contenido del mensaje",
       "client": {
         "id": "uuid-del-cliente",
         "name": "Nombre del cliente",
         "phone": "numero-de-telefono",
         // ... resto de datos del cliente
       }
     }
     ```

## Solución de Problemas Adicionales

Si después de aplicar la solución sigues teniendo problemas, es posible que necesites revisar y modificar las Edge Functions:

### Edge Function: messages-outgoing

Esta función procesa mensajes de agentes y los envía a n8n. El problema principal es que está actualizando los mensajes en la base de datos, lo que podría estar causando que los mensajes de agentes se traten como mensajes de clientes.

Consulta el archivo `README-edge-functions.md` para obtener instrucciones detalladas sobre cómo modificar esta función.

### Edge Function: messages-incoming

Esta función procesa mensajes entrantes. Actualmente es muy simple y solo registra los mensajes recibidos, pero podría mejorarse para asegurar que no interfiera con el procesamiento de mensajes.

## Explicación Técnica

### Problema Original

El problema principal era que los datos del mensaje y del cliente se estaban enviando incorrectamente como parte del encabezado "content-type" en lugar de enviarse en el cuerpo (body) de la solicitud HTTP. Esto ocurría porque:

1. La función `http_post` podría estar implementada incorrectamente, mezclando los parámetros de encabezados y cuerpo.
2. La forma en que se llama a esta función desde `notify_message_webhook` podría estar intercambiando los parámetros.

### Solución Técnica

La solución implementada:

1. Corrige la función `http_post` para asegurar que maneje correctamente los encabezados y el cuerpo.
2. Corrige la función `notify_message_webhook` para asegurar que llame correctamente a `http_post`.
3. Incluye el contenido del mensaje en el payload como `content` y también como `message` para compatibilidad.
4. Crea una tabla `message_whatsapp_status` para rastrear el estado de envío a WhatsApp, en lugar de actualizar directamente los mensajes.
5. Recrea el trigger `message_webhook_trigger` para asegurarse de que esté usando la función actualizada.

## Prevención de Problemas Futuros

Para evitar que este problema vuelva a ocurrir:

1. **Asegúrate de que las funciones HTTP estén correctamente implementadas** y que manejen correctamente los encabezados y el cuerpo.
2. **Verifica periódicamente los logs de Supabase** para detectar errores relacionados con el webhook.
3. **Implementa pruebas automatizadas** para verificar que el webhook de IA está funcionando correctamente.
4. **Documenta claramente el orden de los parámetros** en las funciones HTTP para evitar confusiones.
5. **Revisa y actualiza las Edge Functions** según sea necesario para asegurar que no interfieran con el procesamiento de mensajes.
