# Solución Completa para el Problema del Webhook de IA con Edge Functions

Este documento proporciona una explicación detallada de la solución completa implementada para resolver el problema donde los mensajes enviados desde la interfaz de usuario no llegan correctamente al webhook de IA.

## Descripción del Problema

Se identificaron varios problemas con el webhook de IA:

1. **Mensajes insertados por SQL**: Los mensajes insertados directamente mediante SQL (como los mensajes de prueba) sí llegan correctamente al webhook de IA.

2. **Mensajes desde la interfaz de usuario**: Los mensajes enviados desde la interfaz de usuario con el botón "Asistente IA Activado" encendido no llegan correctamente al webhook de IA.

3. **Formato de datos incorrecto**: Los datos que sí llegan al webhook están en el encabezado "content-type" en lugar de estar en el cuerpo (body) de la solicitud.

## Causa del Problema

Después de analizar el código y los logs, se determinó que las Edge Functions están interfiriendo con el procesamiento de mensajes:

1. **Edge Function messages-outgoing**: Esta función procesa mensajes de agentes y los envía a n8n. El problema es que está actualizando los mensajes en la base de datos, lo que podría estar causando que los mensajes se procesen incorrectamente.

2. **Edge Function messages-incoming**: Esta función procesa mensajes entrantes y podría estar interfiriendo con el procesamiento de mensajes.

## Solución Implementada

Se ha implementado una solución completa que incluye:

1. **Creación de una tabla separada para rastrear el estado de envío a WhatsApp**:
   - Se ha creado la tabla `message_whatsapp_status` para rastrear el estado de envío a WhatsApp, en lugar de actualizar directamente los mensajes en la tabla `messages`.
   - Esto evita posibles conflictos con el procesamiento de mensajes.

2. **Modificación de la Edge Function messages-outgoing**:
   - Se ha modificado la función para que use la tabla `message_whatsapp_status` en lugar de actualizar directamente los mensajes.
   - Esto evita que los mensajes de agentes se traten incorrectamente como mensajes de clientes.

3. **Modificación de la Edge Function messages-incoming**:
   - Se ha simplificado la función para que solo registre los mensajes recibidos sin interferir con el procesamiento.
   - Se han mejorado los encabezados CORS para permitir solicitudes desde cualquier origen.

## Archivos Creados

1. **create_message_whatsapp_status.sql**: Script SQL para crear la tabla `message_whatsapp_status`.

2. **supabase/functions/messages-outgoing/index.js**: Versión corregida de la Edge Function `messages-outgoing`.

3. **supabase/functions/messages-incoming/index.js**: Versión corregida de la Edge Function `messages-incoming`.

4. **apply_complete_edge_functions_fix.ps1**: Script PowerShell para guiar al usuario a través del proceso de implementación de la solución completa.

## Cómo Aplicar la Solución

### Opción 1: Usar el Script PowerShell

1. Ejecuta el script PowerShell:
   ```powershell
   .\apply_complete_edge_functions_fix.ps1
   ```

2. Sigue las instrucciones que aparecen en la consola para:
   - Proporcionar los datos de conexión a Supabase
   - Crear la tabla `message_whatsapp_status`
   - Desplegar las Edge Functions corregidas
   - Verificar que todo funcione correctamente

### Opción 2: Aplicación Manual

1. **Crear la tabla message_whatsapp_status**:
   - Ejecuta el script SQL `create_message_whatsapp_status.sql` en la consola SQL de Supabase.

2. **Desplegar las Edge Functions corregidas**:
   - Asegúrate de que los archivos `supabase/functions/messages-outgoing/index.js` y `supabase/functions/messages-incoming/index.js` existan y contengan el código corregido.
   - Ejecuta los siguientes comandos en tu terminal:
     ```bash
     supabase functions deploy messages-outgoing
     supabase functions deploy messages-incoming
     ```

3. **Verificar que todo funcione correctamente**:
   - Envía un mensaje desde la interfaz de usuario con el botón de asistente IA activado.
   - Verifica en los logs de Supabase si el mensaje fue enviado al webhook de IA.
   - Verifica la respuesta del webhook para confirmar que los datos se recibieron correctamente.

## Verificación

Para verificar que la solución ha funcionado correctamente:

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

## Explicación Técnica

### Problema Original

El problema principal era que las Edge Functions estaban interfiriendo con el procesamiento de mensajes y el envío al webhook de IA:

1. La Edge Function `messages-outgoing` estaba actualizando los mensajes en la base de datos, lo que podría estar causando que los mensajes se procesen incorrectamente.
2. La Edge Function `messages-incoming` podría estar interfiriendo con el procesamiento de mensajes.

### Solución Técnica

La solución implementada:

1. **Tabla message_whatsapp_status**:
   - Crea una tabla separada para rastrear el estado de envío a WhatsApp.
   - Incluye campos para el ID del mensaje, el estado de envío, la fecha de envío, el estado de entrega y mensajes de error.
   - Tiene un índice para búsquedas rápidas por message_id.
   - Incluye un trigger para actualizar automáticamente el campo updated_at.

2. **Edge Function messages-outgoing**:
   - Modifica la función para que use la tabla `message_whatsapp_status` en lugar de actualizar directamente los mensajes.
   - Mantiene la funcionalidad original de enviar mensajes a n8n.
   - Mejora el manejo de errores para que un fallo en el registro del estado no interrumpa el flujo principal.

3. **Edge Function messages-incoming**:
   - Simplifica la función para que solo registre los mensajes recibidos sin interferir con el procesamiento.
   - Mejora los encabezados CORS para permitir solicitudes desde cualquier origen.
   - Mejora el manejo de errores y la respuesta de la función.

## Prevención de Problemas Futuros

Para evitar que este problema vuelva a ocurrir:

1. **Mantén separadas las preocupaciones**:
   - Usa tablas separadas para rastrear el estado de diferentes procesos.
   - Evita actualizar directamente los mensajes en la tabla `messages` después de que han sido insertados.

2. **Verifica periódicamente los logs de Supabase**:
   - Verifica los logs de Supabase para detectar errores relacionados con el webhook.
   - Presta especial atención a los mensajes relacionados con "IA webhook".

3. **Implementa pruebas automatizadas**:
   - Implementa pruebas automatizadas para verificar que el webhook de IA está funcionando correctamente.
   - Incluye pruebas para verificar que los mensajes de agentes y clientes se procesan correctamente.

4. **Documenta claramente las Edge Functions**:
   - Documenta claramente el propósito y el funcionamiento de las Edge Functions.
   - Incluye comentarios en el código para explicar las partes críticas.
   - Asegúrate de que las Edge Functions no interfieran con el procesamiento de mensajes.
