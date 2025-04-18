# Solución Final para el Problema del Webhook de IA

Este documento proporciona un resumen de todos los archivos creados para solucionar el problema del webhook de IA y cómo usarlos.

## Descripción del Problema

Se identificó un problema con el webhook de IA:

1. **Mensajes insertados por SQL**: Los mensajes insertados directamente mediante SQL (como los mensajes de prueba) sí llegan correctamente al webhook de IA.

2. **Mensajes desde la interfaz de usuario**: Los mensajes enviados desde la interfaz de usuario con el botón "Asistente IA Activado" encendido no llegan correctamente al webhook de IA.

3. **Interferencia de Edge Functions**: Las Edge Functions están interfiriendo con el procesamiento de mensajes.

## Archivos Creados

### Scripts SQL

1. **fix_webhook_ia_completo.sql**: Script principal que corrige el webhook de IA.
   - Añade el campo `ia_webhook_sent` a la tabla `messages`.
   - Recrea la función `notify_message_webhook` con la lógica correcta.
   - Recrea el trigger `message_webhook_trigger`.
   - Verifica e instala la extensión `http` si es necesario.
   - Crea o actualiza la función `http_post`.
   - Inserta un mensaje de prueba con `asistente_ia_activado = true`.

2. **create_check_if_table_exists_function.sql**: Script para crear la función `check_if_table_exists`.
   - Crea una función que permite verificar si una tabla existe en la base de datos.
   - Esta función es utilizada por las Edge Functions para verificar si la tabla `message_whatsapp_status` existe.

3. **create_message_whatsapp_status_table.sql**: Script para crear la tabla `message_whatsapp_status`.
   - Crea una tabla para rastrear el estado de envío de mensajes a WhatsApp sin modificar directamente los mensajes en la tabla `messages`.
   - Crea un índice para búsquedas rápidas por `message_id`.
   - Crea un trigger para actualizar el campo `updated_at`.

4. **verify_webhook_ia_status.sql**: Script para verificar el estado del webhook de IA.
   - Verifica la configuración del webhook.
   - Verifica el estado de los mensajes enviados.
   - Verifica el estado de los triggers y funciones.
   - Proporciona un resumen del estado general.

### Scripts PowerShell

1. **apply_fix_webhook_ia_completo.ps1**: Script para ejecutar `fix_webhook_ia_completo.sql`.
   - Verifica si las variables de entorno están configuradas.
   - Ejecuta el SQL usando psql o la API REST de Supabase.
   - Proporciona instrucciones para verificar que el webhook de IA está funcionando correctamente.

2. **apply_create_message_whatsapp_status.ps1**: Script para ejecutar `create_check_if_table_exists_function.sql` y `create_message_whatsapp_status_table.sql`.
   - Verifica si las variables de entorno están configuradas.
   - Ejecuta los SQL usando psql o la API REST de Supabase.
   - Proporciona instrucciones para los siguientes pasos.

3. **apply_complete_solution.ps1**: Script para ejecutar todos los scripts SQL y aplicar la solución completa.
   - Verifica si las variables de entorno están configuradas.
   - Verifica si los archivos SQL existen.
   - Verifica si los archivos de Edge Functions existen.
   - Ejecuta los SQL usando psql o la API REST de Supabase.
   - Proporciona instrucciones para verificar que el webhook de IA está funcionando correctamente.

4. **test_webhook_ia.ps1**: Script para probar el webhook de IA.
   - Inserta un mensaje de prueba con `asistente_ia_activado = true`.
   - Verifica si el mensaje fue enviado al webhook de IA.
   - Proporciona instrucciones para verificar los logs de Supabase.

5. **run_verify_webhook_ia_status.ps1**: Script para ejecutar `verify_webhook_ia_status.sql`.
   - Verifica si las variables de entorno están configuradas.
   - Ejecuta el SQL usando psql o la API REST de Supabase.
   - Proporciona instrucciones para solucionar problemas si los hay.

6. **verify_edge_functions.ps1**: Script para verificar si las Edge Functions están correctamente desplegadas en Supabase.
   - Verifica si las Edge Functions `messages-outgoing` y `messages-incoming` están desplegadas.
   - Verifica si los archivos de Edge Functions existen localmente.
   - Proporciona instrucciones para desplegar las Edge Functions si no están desplegadas.

7. **update_edge_functions.ps1**: Script para actualizar las Edge Functions en Supabase.
   - Verifica si los archivos de Edge Functions existen localmente.
   - Verifica si supabase CLI está instalado.
   - Actualiza las Edge Functions `messages-outgoing` y `messages-incoming`.
   - Proporciona instrucciones para verificar que las Edge Functions están correctamente desplegadas.

8. **apply_all.ps1**: Script para ejecutar todos los scripts PowerShell para solucionar el problema del webhook de IA.
   - Ejecuta los scripts `apply_create_message_whatsapp_status.ps1`, `apply_fix_webhook_ia_completo.ps1`, `test_webhook_ia.ps1` y `run_verify_webhook_ia_status.ps1`.
   - Proporciona instrucciones para verificar que el webhook de IA está funcionando correctamente.

9. **apply_complete_solution_with_edge_functions.ps1**: Script para ejecutar todos los scripts PowerShell para solucionar el problema del webhook de IA, incluyendo la actualización de las Edge Functions.
   - Ejecuta los scripts `apply_create_message_whatsapp_status.ps1`, `apply_fix_webhook_ia_completo.ps1`, `update_edge_functions.ps1`, `test_webhook_ia.ps1`, `run_verify_webhook_ia_status.ps1` y `verify_edge_functions.ps1`.
   - Proporciona instrucciones para verificar que el webhook de IA está funcionando correctamente.

### Edge Functions

1. **messages-outgoing/index.js**: Edge Function modificada para procesar mensajes de agentes.
   - Solo procesa mensajes de agentes y no actualiza directamente los mensajes en la tabla `messages`.
   - Utiliza la tabla `message_whatsapp_status` para rastrear el estado de envío de mensajes a WhatsApp.

2. **messages-incoming/index.js**: Edge Function modificada para procesar mensajes de clientes con `asistente_ia_activado = true`.
   - Procesa mensajes de clientes con `asistente_ia_activado = true` y los envía al webhook de IA.
   - Actualiza el campo `ia_webhook_sent` a `true` cuando un mensaje se envía correctamente al webhook de IA.

### Documentación

1. **README-solucion-completa-webhook-ia.md**: Documento que proporciona instrucciones detalladas para solucionar el problema del webhook de IA.
   - Describe el problema.
   - Explica la solución implementada.
   - Proporciona instrucciones para implementar la solución.
   - Proporciona instrucciones para verificar que la solución funciona correctamente.

2. **README-solucion-final-actualizado.md**: Este documento, que proporciona un resumen de todos los archivos creados y cómo usarlos.

## Pasos para Implementar la Solución

### Opción 1: Solución Completa con Edge Functions

Ejecuta el script PowerShell `apply_complete_solution_with_edge_functions.ps1`:

```powershell
.\apply_complete_solution_with_edge_functions.ps1
```

Este script ejecutará todos los scripts SQL, actualizará las Edge Functions y aplicará la solución completa.

### Opción 2: Solución Completa sin Edge Functions

Ejecuta el script PowerShell `apply_complete_solution.ps1`:

```powershell
.\apply_complete_solution.ps1
```

Este script ejecutará todos los scripts SQL y aplicará la solución completa sin actualizar las Edge Functions.

### Opción 3: Paso a Paso

1. **Crear la función `check_if_table_exists` y la tabla `message_whatsapp_status`**:

   ```powershell
   .\apply_create_message_whatsapp_status.ps1
   ```

2. **Corregir el webhook de IA**:

   ```powershell
   .\apply_fix_webhook_ia_completo.ps1
   ```

3. **Actualizar las Edge Functions**:

   ```powershell
   .\update_edge_functions.ps1
   ```

4. **Probar el webhook de IA**:

   ```powershell
   .\test_webhook_ia.ps1
   ```

5. **Verificar el estado del webhook de IA**:

   ```powershell
   .\run_verify_webhook_ia_status.ps1
   ```

6. **Verificar las Edge Functions**:

   ```powershell
   .\verify_edge_functions.ps1
   ```

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

4. **Verificar las Edge Functions**:
   - Ejecuta el script `verify_edge_functions.ps1` para verificar que las Edge Functions están correctamente desplegadas.
   - Verifica los logs de las Edge Functions para detectar errores.

## Solución de Problemas

Si la solución no funciona correctamente, verifica lo siguiente:

1. **Verificar el estado del webhook de IA**:

   ```powershell
   .\run_verify_webhook_ia_status.ps1
   ```

   Este script verificará el estado del webhook de IA y proporcionará instrucciones para solucionar problemas si los hay.

2. **Verificar las Edge Functions**:

   ```powershell
   .\verify_edge_functions.ps1
   ```

   Este script verificará si las Edge Functions están correctamente desplegadas y proporcionará instrucciones para desplegarlas si no lo están.

3. **Verificar la configuración del webhook de IA**:
   - Verifica que las URLs del webhook de IA estén correctamente configuradas en la tabla `app_settings`.
   - Verifica que el entorno (producción o pruebas) esté correctamente configurado.

4. **Verificar el trigger `message_webhook_trigger`**:
   - Verifica que el trigger esté activado.
   - Verifica que la función `notify_message_webhook` esté correctamente definida.

## Conclusión

La solución implementada corrige el problema del webhook de IA y establece una base sólida para el futuro. Al separar claramente las responsabilidades entre las Edge Functions y los triggers de base de datos, se evita que este problema vuelva a ocurrir.
