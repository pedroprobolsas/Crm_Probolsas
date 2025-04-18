# Solución Actualizada para el Problema del Webhook de IA y Duplicación de Clientes

## Problema Identificado

Después de una investigación más profunda, hemos identificado un comportamiento específico en el sistema:

1. **Los mensajes enviados por clientes** (con `sender = 'client'` y `status = 'sent'`) no están llegando al webhook de IA, aunque tienen `asistente_ia_activado = true`.

2. **Los mensajes enviados por el sistema o en pruebas manuales** sí llegan al webhook correctamente.

Este comportamiento está causando:
- Falta de respuestas automáticas de la IA a mensajes de clientes
- Posible duplicación de clientes debido a procesamiento inconsistente

## Solución Mejorada

Hemos creado una solución mejorada que aborda específicamente estos problemas:

### 1. Script SQL Mejorado (`fix_webhook_ia_mejorado.sql`)

Este script incluye:

- **Logging detallado**: Para facilitar la depuración y entender exactamente qué mensajes se están procesando.
- **Verificaciones más estrictas**: Ahora verifica explícitamente `sender = 'client'` además de `asistente_ia_activado = true`.
- **Trigger para INSERT y UPDATE**: El trigger ahora se activa tanto en inserciones como en actualizaciones del campo `asistente_ia_activado`.
- **Función para procesar mensajes pendientes**: Procesa mensajes antiguos que deberían haber sido enviados al webhook pero no lo fueron.
- **Política RLS para `message_whatsapp_status`**: Soluciona problemas de permisos para esta tabla.

### 2. Edge Function Mejorada (`messages-incoming-mejorado.js`)

Esta versión mejorada incluye:

- **Logging detallado**: Para cada mensaje recibido, muestra información completa sobre por qué se procesa o ignora.
- **Verificaciones más estrictas**: Ahora verifica `sender = 'client'`, `status = 'sent'`, `asistente_ia_activado = true` y que no comience con `[IA]`.
- **Manejo de eventos UPDATE**: Ahora procesa tanto eventos INSERT como UPDATE.
- **Marcado explícito de mensajes procesados**: Actualiza `ia_webhook_sent = true` después de enviar al webhook.

## Cómo Aplicar la Solución

### Paso 1: Aplicar el Script SQL Mejorado

1. Abre la consola SQL de Supabase
2. Copia y pega el contenido del archivo `fix_webhook_ia_mejorado.sql`
3. Ejecuta el script completo

Este script:
- Añade la columna `ia_webhook_sent` si no existe
- Crea o reemplaza la función `notify_message_webhook` con verificaciones mejoradas
- Crea un nuevo trigger que responde a INSERT y UPDATE
- Procesa mensajes pendientes de los últimos 7 días
- Crea una política RLS para la tabla `message_whatsapp_status`

### Paso 2: Actualizar la Edge Function `messages-incoming`

1. Ve a la sección 'Edge Functions' en la consola de Supabase
2. Selecciona la función `messages-incoming`
3. Reemplaza el contenido del archivo `index.js` con el código del archivo `messages-incoming-mejorado.js`

### Paso 3: Verificar la Solución

1. Envía un mensaje con el asistente de IA activado desde la interfaz de usuario o desde WhatsApp
2. Verifica en los logs de Supabase que:
   - El mensaje se envía correctamente al webhook de IA
   - El mensaje se marca como enviado al webhook (`ia_webhook_sent = true`)
3. Verifica que no aparecen clientes duplicados en el módulo de clientes ni en las conversaciones

## Explicación Técnica de las Mejoras

### 1. Problema de Timing en la Asignación de `asistente_ia_activado`

Es posible que cuando un cliente envía un mensaje, el campo `asistente_ia_activado` se establezca como `true` en una actualización posterior a la inserción inicial. Por eso:

- Ahora el trigger responde tanto a INSERT como a UPDATE del campo `asistente_ia_activado`
- La Edge Function también procesa eventos UPDATE además de INSERT

### 2. Verificaciones Más Estrictas

Ahora verificamos explícitamente:
- `sender = 'client'`: Para asegurarnos de que solo procesamos mensajes de clientes
- `status = 'sent'`: Para asegurarnos de que el mensaje está en estado enviado
- `asistente_ia_activado = true`: Para asegurarnos de que el asistente de IA está activado
- `ia_webhook_sent !== true`: Para evitar envíos duplicados
- `!message.content?.startsWith('[IA]')`: Para evitar procesar respuestas de la IA

### 3. Logging Detallado

Hemos añadido logging detallado en ambos componentes:
- En el trigger SQL: Para ver exactamente qué mensajes está procesando y por qué
- En la Edge Function: Para entender por qué se ignoran ciertos mensajes

### 4. Procesamiento de Mensajes Pendientes

La función `process_pending_ia_messages()` busca mensajes de los últimos 7 días que deberían haber sido enviados al webhook pero no lo fueron, y los procesa.

## Monitoreo Continuo

Después de aplicar esta solución, es recomendable:

1. **Revisar los logs regularmente**: Para asegurarse de que los mensajes se están enviando correctamente al webhook.
2. **Verificar la tabla `messages`**: Para confirmar que los mensajes tienen `ia_webhook_sent = true` después de ser procesados.
3. **Monitorear la duplicación de clientes**: Para asegurarse de que el problema ha sido resuelto.

Si sigues teniendo problemas después de aplicar esta solución, por favor revisa los logs detallados para identificar la causa exacta.
