# Solución Completa para Webhook de IA y Duplicación de Clientes

## Resumen Ejecutivo

Se han identificado y solucionado dos problemas principales en el CRM:

1. **El webhook de IA no estaba funcionando correctamente**
2. **Se estaban duplicando clientes en el módulo de clientes y en las conversaciones**

Este documento proporciona una guía completa para implementar y verificar las soluciones.

## Problemas Identificados

### 1. Webhook de IA

Se detectó un conflicto entre múltiples mecanismos que intentaban enviar mensajes al webhook de IA:

- **Trigger SQL `notify_message_webhook`**: Configurado para enviar mensajes al webhook de IA cuando `asistente_ia_activado=true`.
- **Edge Function `messages-incoming`**: También configurada para enviar mensajes al webhook de IA.
- **Lógica en `Communications.tsx`**: Creaba un mensaje adicional como cliente con prefijo `[IA]` para activar el webhook.

### 2. Duplicación de Clientes

La duplicación de clientes estaba relacionada con:

- **Múltiples suscripciones a cambios en la tabla `messages`** en diferentes componentes
- **Creación de mensajes duplicados** cuando se activaba el asistente de IA

## Soluciones Implementadas

### Para el Webhook de IA

1. **Modificación de Edge Functions**:
   - `messages-incoming`: Ahora ignora mensajes que ya han sido procesados por el trigger SQL (`ia_webhook_sent=true`)
   - `messages-outgoing`: Ahora ignora mensajes con `asistente_ia_activado=true`

2. **Optimización del Trigger SQL**:
   - Ignorar mensajes con prefijo `[IA]` para evitar procesamiento duplicado
   - Añadir un campo `ia_webhook_sent` para rastrear mensajes enviados al webhook
   - Mejorar el manejo de errores y logging

3. **Eliminación de Código Redundante**:
   - Se eliminó el código en `Communications.tsx` que creaba un mensaje adicional como cliente

### Para la Duplicación de Clientes

1. **Registro Global de Mensajes Procesados**:
   - Se implementó un registro global (`window._processedMessageIds`) en `useMessages.ts`

2. **Eliminación de Suscripciones Redundantes**:
   - Se comentó la suscripción directa en `ChatWithIA.tsx`

3. **Mejora en la Detección de Duplicados**:
   - Se mejoró la lógica de verificación de mensajes duplicados en varios componentes

## Archivos Modificados

### TypeScript

- `src/lib/hooks/useMessages.ts`: Mejorado para evitar duplicación de mensajes
- `src/components/chat/ChatWithIA.tsx`: Eliminada suscripción redundante
- `src/pages/Communications.tsx`: Eliminado código que creaba mensajes adicionales

### Edge Functions

- `supabase/functions/messages-incoming/index.js`: Modificada para ignorar mensajes ya procesados
- `supabase/functions/messages-outgoing/index.js`: Modificada para ignorar mensajes con asistente_ia_activado=true

## Scripts Creados

### SQL

- `fix_webhook_ia_completo_final.sql`: Script SQL completo que soluciona el problema del webhook de IA
- `verify_webhook_ia_solution.sql`: Script SQL para verificar que la solución funciona correctamente

### PowerShell

- `apply_fix_webhook_ia_completo_final.ps1`: Script para aplicar la solución del webhook de IA
- `update_edge_functions_for_ia_webhook.ps1`: Script para actualizar las Edge Functions
- `verify_edge_functions_solution.ps1`: Script para verificar que las Edge Functions funcionan correctamente
- `run_verify_webhook_ia_solution.ps1`: Script para verificar la solución del webhook de IA

## Guía de Implementación

### Paso 1: Aplicar la Solución SQL

1. Ejecutar el script PowerShell `apply_fix_webhook_ia_completo_final.ps1`
   ```powershell
   .\apply_fix_webhook_ia_completo_final.ps1
   ```

2. Verificar que la solución SQL se ha aplicado correctamente
   ```powershell
   .\run_verify_webhook_ia_solution.ps1
   ```

### Paso 2: Actualizar las Edge Functions

1. Ejecutar el script PowerShell `update_edge_functions_for_ia_webhook.ps1`
   ```powershell
   .\update_edge_functions_for_ia_webhook.ps1
   ```

2. Seguir las instrucciones del script para actualizar las Edge Functions en la consola de Supabase

3. Verificar que las Edge Functions funcionan correctamente
   ```powershell
   .\verify_edge_functions_solution.ps1
   ```

### Paso 3: Verificar la Solución Completa

1. Enviar un mensaje con el asistente de IA activado desde la interfaz de usuario

2. Verificar en los logs de Supabase que:
   - El mensaje se envía correctamente al webhook de IA
   - No hay errores relacionados con las Edge Functions
   - El mensaje se marca como enviado al webhook de IA (`ia_webhook_sent=true`)

3. Verificar que no aparecen clientes duplicados en el módulo de clientes ni en las conversaciones

## Verificación de la Solución

Para verificar que las soluciones funcionan correctamente, se han creado los siguientes scripts:

- `run_verify_webhook_ia_solution.ps1`: Verifica que la solución SQL funciona correctamente
- `verify_edge_functions_solution.ps1`: Verifica que las Edge Functions funcionan correctamente

Estos scripts realizan las siguientes verificaciones:

1. Que el trigger `message_webhook_trigger` está activo
2. Que las URLs del webhook de IA están configuradas correctamente
3. Que la columna `ia_webhook_sent` existe en la tabla `messages`
4. Que un mensaje de prueba se envía correctamente al webhook de IA
5. Que las Edge Functions están activas y no interfieren con el webhook de IA

## Notas Importantes

- Las Edge Functions han sido modificadas para que no interfieran con el webhook de IA, por lo que no es necesario deshabilitarlas.
- Si se realizan cambios en las Edge Functions en el futuro, es importante mantener la lógica que evita el procesamiento duplicado de mensajes.
- El sistema ahora utiliza un enfoque más robusto para manejar las suscripciones a cambios en la base de datos, lo que debería prevenir problemas similares en el futuro.

## Documentación Adicional

Para más detalles sobre las soluciones implementadas, consulta:

- `README-resumen-soluciones-implementadas.md`: Resumen de todas las soluciones
- `README-solucion-webhook-ia-y-duplicacion.md`: Explicación detallada de las soluciones

## Soporte y Mantenimiento

Si se presentan problemas adicionales o se requieren ajustes a las soluciones implementadas, se recomienda:

1. Revisar los logs de Supabase para identificar posibles errores
2. Verificar que las Edge Functions están funcionando correctamente
3. Comprobar que el trigger SQL está activo y funcionando correctamente
4. Revisar que no hay código redundante en los componentes de React que pueda causar duplicación de mensajes
