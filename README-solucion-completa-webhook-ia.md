# Solución Completa para el Problema del Webhook de IA

Este documento proporciona instrucciones detalladas para solucionar el problema donde los mensajes enviados desde la interfaz de usuario no llegan correctamente al webhook de IA.

## Descripción del Problema

Se identificó un problema con el webhook de IA:

1. **Mensajes insertados por SQL**: Los mensajes insertados directamente mediante SQL (como los mensajes de prueba) sí llegan correctamente al webhook de IA.

2. **Mensajes desde la interfaz de usuario**: Los mensajes enviados desde la interfaz de usuario con el botón "Asistente IA Activado" encendido no llegan correctamente al webhook de IA.

3. **Interferencia de Edge Functions**: Las Edge Functions están interfiriendo con el procesamiento de mensajes.

## Solución Implementada

La solución completa consta de varias partes:

1. **Recreación de la función `notify_message_webhook`**: Se ha recreado la función para asegurar que procese correctamente los mensajes con `asistente_ia_activado = true`.

2. **Recreación del trigger `message_webhook_trigger`**: Se ha recreado el trigger para asegurar que esté correctamente configurado y activado.

3. **Modificación de las Edge Functions**: Se han modificado las Edge Functions para que no interfieran con el procesamiento de mensajes.

4. **Creación de la tabla `message_whatsapp_status`**: Se ha creado una tabla para rastrear el estado de envío de mensajes a WhatsApp sin modificar directamente los mensajes en la tabla `messages`.

5. **Creación de la función `check_if_table_exists`**: Se ha creado una función para verificar si una tabla existe en la base de datos.

## Archivos Creados

1. **Scripts SQL**:
   - `fix_webhook_ia_completo.sql`: Script principal que corrige el webhook de IA.
   - `create_check_if_table_exists_function.sql`: Script para crear la función `check_if_table_exists`.
   - `create_message_whatsapp_status_table.sql`: Script para crear la tabla `message_whatsapp_status`.

2. **Scripts PowerShell**:
   - `apply_fix_webhook_ia_completo.ps1`: Script para ejecutar `fix_webhook_ia_completo.sql`.
   - `apply_create_message_whatsapp_status.ps1`: Script para ejecutar `create_check_if_table_exists_function.sql` y `create_message_whatsapp_status_table.sql`.

3. **Edge Functions**:
   - `messages-outgoing/index.js`: Edge Function modificada para procesar mensajes de agentes.
   - `messages-incoming/index.js`: Edge Function modificada para procesar mensajes de clientes con `asistente_ia_activado = true`.

## Pasos para Implementar la Solución

### 1. Crear la función `check_if_table_exists` y la tabla `message_whatsapp_status`

Ejecuta el script PowerShell `apply_create_message_whatsapp_status.ps1`:

```powershell
.\apply_create_message_whatsapp_status.ps1
```

Este script:
- Crea la función `check_if_table_exists` que permite verificar si una tabla existe en la base de datos.
- Crea la tabla `message_whatsapp_status` para rastrear el estado de envío de mensajes a WhatsApp.

### 2. Corregir el webhook de IA

Ejecuta el script PowerShell `apply_fix_webhook_ia_completo.ps1`:

```powershell
.\apply_fix_webhook_ia_completo.ps1
```

Este script:
- Añade el campo `ia_webhook_sent` a la tabla `messages`.
- Recrea la función `notify_message_webhook` con la lógica correcta.
- Recrea el trigger `message_webhook_trigger`.
- Verifica e instala la extensión `http` si es necesario.
- Crea o actualiza la función `http_post`.
- Inserta un mensaje de prueba con `asistente_ia_activado = true`.

### 3. Actualizar las Edge Functions

Las Edge Functions ya han sido actualizadas en los archivos:
- `supabase/functions/messages-outgoing/index.js`
- `supabase/functions/messages-incoming/index.js`

Asegúrate de que estos archivos estén correctamente desplegados en Supabase.

## Verificación de la Solución

Para verificar que la solución funciona correctamente:

1. **Verificar los logs de Supabase**:
   - Accede a la consola de Supabase.
   - Ve a la sección de Logs.
   - Busca mensajes relacionados con "IA webhook", como:
     * "Selected IA webhook URL: X (is_production=true/false)"
     * "IA webhook payload: {...}"
     * "IA webhook request succeeded for message ID: X"

2. **Enviar un mensaje de prueba**:
   - Envía un mensaje desde la interfaz de usuario con el botón de asistente IA activado.
   - Verifica en los logs de Supabase que el mensaje llegue al webhook de IA.

3. **Verificar la tabla `messages`**:
   - Verifica que el campo `ia_webhook_sent` se haya actualizado a `true` para el mensaje enviado.

## Explicación Técnica

### Problema Original

El problema principal era que las Edge Functions estaban interfiriendo con el procesamiento de mensajes y el envío al webhook de IA:

1. La Edge Function `messages-outgoing` estaba actualizando los mensajes en la base de datos, lo que podría estar causando que los mensajes se procesen incorrectamente.
2. La función `notify_message_webhook` no estaba procesando correctamente los mensajes con `asistente_ia_activado = true`.

### Solución Técnica

La solución implementada:

1. **Recreación de la función `notify_message_webhook`**:
   - Se ha recreado la función para asegurar que procese correctamente los mensajes con `asistente_ia_activado = true`.
   - Se ha añadido lógica para actualizar el campo `ia_webhook_sent` a `true` cuando un mensaje se envía correctamente al webhook de IA.

2. **Modificación de las Edge Functions**:
   - Se ha modificado la Edge Function `messages-outgoing` para que solo procese mensajes de agentes y no actualice directamente los mensajes en la tabla `messages`.
   - Se ha modificado la Edge Function `messages-incoming` para que procese mensajes de clientes con `asistente_ia_activado = true` y los envíe al webhook de IA.

3. **Creación de la tabla `message_whatsapp_status`**:
   - Se ha creado una tabla para rastrear el estado de envío de mensajes a WhatsApp sin modificar directamente los mensajes en la tabla `messages`.
   - Esto evita posibles conflictos con el procesamiento de mensajes.

## Prevención de Problemas Futuros

Para evitar que este problema vuelva a ocurrir:

1. **Mantener la separación de responsabilidades**:
   - Las Edge Functions deben tener responsabilidades claramente definidas y no interferir con el procesamiento de mensajes.
   - Los triggers de base de datos deben ser los encargados de enviar mensajes a los webhooks.

2. **Verificar periódicamente los logs de Supabase**:
   - Verificar los logs de Supabase para detectar errores relacionados con el webhook.

3. **Implementar pruebas automatizadas**:
   - Implementar pruebas automatizadas para verificar que el webhook de IA está funcionando correctamente.

4. **Documentar claramente las Edge Functions**:
   - Documentar claramente el propósito y el funcionamiento de las Edge Functions.
   - Asegurarse de que las Edge Functions no interfieran con el procesamiento de mensajes.

## Conclusión

La solución implementada corrige el problema del webhook de IA y establece una base sólida para el futuro. Al separar claramente las responsabilidades entre las Edge Functions y los triggers de base de datos, se evita que este problema vuelva a ocurrir.
