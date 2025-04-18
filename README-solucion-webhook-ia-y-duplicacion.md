# Solución para Problemas de Webhook IA y Duplicación de Clientes

Este documento explica las soluciones implementadas para resolver dos problemas principales en el CRM:

1. El webhook de IA no estaba funcionando correctamente
2. Se estaban duplicando clientes en el módulo de clientes y en las conversaciones

## 1. Solución para el Webhook de IA

### Problema Identificado
Se detectó un conflicto entre múltiples mecanismos que intentaban enviar mensajes al webhook de IA:

- **Trigger SQL `notify_message_webhook`**: Configurado para enviar mensajes al webhook de IA cuando `asistente_ia_activado=true`.
- **Edge Function `messages-incoming`**: También configurada para enviar mensajes al webhook de IA.
- **Lógica en `Communications.tsx`**: Creaba un mensaje adicional como cliente con prefijo `[IA]` para activar el webhook.

### Solución Implementada

1. **Modificar Edge Functions**: Se modificaron las Edge Functions para que no interfieran con el webhook de IA:
   - `messages-incoming`: Ahora ignora mensajes que ya han sido procesados por el trigger SQL (`ia_webhook_sent=true`)
   - `messages-outgoing`: Ahora ignora mensajes con `asistente_ia_activado=true`

2. **Optimizar el Trigger SQL**: Se modificó la función `notify_message_webhook` para:
   - Ignorar mensajes con prefijo `[IA]` para evitar procesamiento duplicado
   - Añadir un campo `ia_webhook_sent` para rastrear mensajes enviados al webhook
   - Mejorar el manejo de errores y logging

3. **Eliminar Código Redundante**: Se eliminó el código en `Communications.tsx` que creaba un mensaje adicional como cliente, ya que ahora el trigger SQL maneja correctamente los mensajes con `asistente_ia_activado=true`.

## 2. Solución para la Duplicación de Clientes

### Problema Identificado
La duplicación de clientes estaba relacionada con:

1. **Múltiples suscripciones a cambios en la tabla `messages`**:
   - En `useMessages.ts` a través de `subscribeToMessages`
   - En `ChatWithIA.tsx` directamente con `supabase.channel('messages')`
   - En `Communications.tsx` a través de `subscribeToMessages`

2. **Creación de mensajes duplicados**: Cuando se activaba el asistente de IA, se creaba un mensaje adicional como cliente, lo que podía causar la duplicación.

### Solución Implementada

1. **Registro Global de Mensajes Procesados**: Se implementó un registro global (`window._processedMessageIds`) en `useMessages.ts` para rastrear los IDs de mensajes ya procesados y evitar duplicados.

2. **Eliminación de Suscripciones Redundantes**: Se comentó la suscripción directa en `ChatWithIA.tsx` para evitar múltiples suscripciones al mismo evento.

3. **Mejora en la Detección de Duplicados**: Se mejoró la lógica de verificación de mensajes duplicados en `useMessages.ts` y `Communications.tsx`.

4. **Eliminación de Mensajes Adicionales**: Se eliminó el código que creaba mensajes adicionales para el asistente de IA en `Communications.tsx`.

## Cómo Aplicar las Soluciones

### Para el Webhook de IA

1. Ejecutar el script PowerShell `apply_fix_webhook_ia_completo_final.ps1` que aplicará los cambios SQL necesarios.
2. Ejecutar el script PowerShell `update_edge_functions_for_ia_webhook.ps1` que te guiará para actualizar las Edge Functions.

### Para la Duplicación de Clientes

Los cambios ya están aplicados en los siguientes archivos:
- `src/lib/hooks/useMessages.ts`
- `src/components/chat/ChatWithIA.tsx`
- `src/pages/Communications.tsx`

## Verificación

Para verificar que las soluciones funcionan correctamente:

1. **Webhook de IA**: Enviar un mensaje con el asistente de IA activado y verificar en los logs de Supabase que se envía correctamente al webhook de IA.

2. **Duplicación de Clientes**: Verificar que ya no aparecen clientes duplicados en el módulo de clientes ni en las conversaciones.

## Notas Adicionales

- Las Edge Functions han sido modificadas para que no interfieran con el webhook de IA, por lo que no es necesario deshabilitarlas.
- Si se realizan cambios en las Edge Functions en el futuro, es importante mantener la lógica que evita el procesamiento duplicado de mensajes.
- El sistema ahora utiliza un enfoque más robusto para manejar las suscripciones a cambios en la base de datos, lo que debería prevenir problemas similares en el futuro.
