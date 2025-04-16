# Solución para el Problema del Webhook de IA con Edge Functions

Este documento proporciona una explicación detallada del problema donde los mensajes enviados desde la interfaz de usuario no llegan correctamente al webhook de IA y la solución implementada.

## Descripción del Problema

Se identificó un problema con el webhook de IA:

1. **Mensajes insertados por SQL**: Los mensajes insertados directamente mediante SQL (como los mensajes de prueba) sí llegan correctamente al webhook de IA.

2. **Mensajes desde la interfaz de usuario**: Los mensajes enviados desde la interfaz de usuario con el botón "Asistente IA Activado" encendido no llegan correctamente al webhook de IA.

3. **Formato de datos incorrecto**: Los datos que sí llegan al webhook están en el encabezado "content-type" en lugar de estar en el cuerpo (body) de la solicitud.

## Causa del Problema

Después de analizar el código y los logs, se determinó que las Edge Functions están interfiriendo con el procesamiento de mensajes:

1. **Edge Function messages-outgoing**: Esta función procesa mensajes de agentes y los envía a n8n. El problema es que está actualizando los mensajes en la base de datos, lo que podría estar causando que los mensajes se procesen incorrectamente.

2. **Edge Function messages-incoming**: Esta función procesa mensajes entrantes y podría estar interfiriendo con el procesamiento de mensajes.

## Solución Implementada

La solución requiere dos pasos principales:

1. **Deshabilitar manualmente las Edge Functions**:
   - Es necesario deshabilitar manualmente las Edge Functions `messages-outgoing` y `messages-incoming` desde la interfaz de Supabase, ya que no es posible hacerlo directamente desde SQL.

2. **Ejecutar el script SQL**:
   - Se ha creado un script SQL (`fix_edge_functions_ia_webhook.sql`) que realiza las siguientes acciones:
     - Verifica y activa el trigger `message_webhook_trigger`
     - Verifica y actualiza las URLs del webhook de IA en la tabla `app_settings`
     - Inserta un mensaje de prueba con `asistente_ia_activado=true` para verificar que la solución funciona

## Archivos Creados

1. **fix_edge_functions_ia_webhook.sql**: Script SQL que deshabilita temporalmente las Edge Functions y realiza otras correcciones necesarias.

2. **apply_fix_edge_functions_ia_webhook.ps1**: Script PowerShell simplificado para ejecutar el script SQL.

## Cómo Aplicar la Solución

### Opción 1: Usar el Script PowerShell

1. Ejecuta el script PowerShell:
   ```powershell
   .\apply_fix_edge_functions_ia_webhook.ps1
   ```

2. Sigue las instrucciones que aparecen en la consola para proporcionar los datos de conexión a Supabase.

### Opción 2: Aplicación Manual

1. Accede a la consola SQL de Supabase.
2. Copia y pega el contenido del archivo `fix_edge_functions_ia_webhook.sql`.
3. Ejecuta el script y revisa los resultados.

## Verificación

Para verificar que la solución ha funcionado:

1. **Envía un mensaje de prueba**:
   - Envía un mensaje desde la interfaz de usuario con el botón de asistente IA activado.

2. **Verifica los logs de Supabase**:
   - Accede a la consola de Supabase.
   - Ve a la sección de Logs.
   - Busca mensajes relacionados con "IA webhook", como:
     * "IA webhook payload: {...}"
     * "IA webhook request succeeded for message ID: X"

3. **Verifica la respuesta del webhook**:
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

## Solución a Largo Plazo

Esta solución deshabilita temporalmente las Edge Functions para solucionar el problema inmediato. Para una solución a largo plazo, se recomienda:

1. **Modificar las Edge Functions**:
   - Modificar la Edge Function `messages-outgoing` para que no actualice directamente los mensajes en la tabla `messages`.
   - Crear una tabla `message_whatsapp_status` para rastrear el estado de envío a WhatsApp, en lugar de actualizar directamente los mensajes.
   - Verificar que la Edge Function `messages-incoming` no interfiera con el procesamiento de mensajes.

2. **Seguir las instrucciones en README-edge-functions.md**:
   - Este archivo contiene instrucciones detalladas sobre cómo modificar las Edge Functions para una solución a largo plazo.

## Explicación Técnica

### Problema Original

El problema principal era que las Edge Functions estaban interfiriendo con el procesamiento de mensajes y el envío al webhook de IA:

1. La Edge Function `messages-outgoing` estaba actualizando los mensajes en la base de datos, lo que podría estar causando que los mensajes se procesen incorrectamente.
2. La Edge Function `messages-incoming` podría estar interfiriendo con el procesamiento de mensajes.

### Solución Técnica

La solución implementada:

1. Deshabilita temporalmente las Edge Functions que están interfiriendo con el procesamiento de mensajes.
2. Asegura que el trigger `message_webhook_trigger` esté activado.
3. Verifica y actualiza las URLs del webhook de IA.
4. Inserta un mensaje de prueba para verificar que la solución funciona.

## Prevención de Problemas Futuros

Para evitar que este problema vuelva a ocurrir:

1. **Implementa la solución a largo plazo**:
   - Modifica las Edge Functions según las instrucciones en `README-edge-functions.md`.
   - Crea una tabla `message_whatsapp_status` para rastrear el estado de envío a WhatsApp.

2. **Verifica periódicamente los logs de Supabase**:
   - Verifica los logs de Supabase para detectar errores relacionados con el webhook.

3. **Implementa pruebas automatizadas**:
   - Implementa pruebas automatizadas para verificar que el webhook de IA está funcionando correctamente.

4. **Documenta claramente las Edge Functions**:
   - Documenta claramente el propósito y el funcionamiento de las Edge Functions.
   - Asegúrate de que las Edge Functions no interfieran con el procesamiento de mensajes.
