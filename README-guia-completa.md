# Guía Completa para Solucionar el Problema del Webhook de IA

Este documento proporciona una guía completa para solucionar el problema del webhook de IA, incluyendo todos los documentos creados y cómo utilizarlos.

## Descripción del Problema

Se identificó un problema con el webhook de IA:

1. **Mensajes insertados por SQL**: Los mensajes insertados directamente mediante SQL (como los mensajes de prueba) sí llegan correctamente al webhook de IA.

2. **Mensajes desde la interfaz de usuario**: Los mensajes enviados desde la interfaz de usuario con el botón "Asistente IA Activado" encendido no llegan correctamente al webhook de IA.

3. **Interferencia de Edge Functions**: Las Edge Functions están interfiriendo con el procesamiento de mensajes.

## Documentos Creados

### Documentación

1. **README-solucion-completa-webhook-ia.md**: Documento que proporciona instrucciones detalladas para solucionar el problema del webhook de IA.
2. **README-solucion-final-actualizado.md**: Documento que proporciona un resumen de todos los archivos creados y cómo usarlos.
3. **README-edge-functions-supabase.md**: Documento que explica cómo funcionan las Edge Functions en Supabase y cómo se relacionan con el webhook de IA.
4. **README-webhook-ia-funcionamiento.md**: Documento que explica cómo funciona el webhook de IA en la aplicación.
5. **README-solucion-completa-explicacion.md**: Documento que proporciona una explicación completa de la solución.
6. **README-edge-functions-aplicacion.md**: Documento que explica cómo funcionan las Edge Functions en la aplicación.
7. **README-edge-functions-triggers.md**: Documento que explica cómo se relacionan las Edge Functions y los triggers de base de datos.
8. **README-webhook-ia-detalle.md**: Documento que proporciona una explicación detallada de cómo funciona el webhook de IA.
9. **README-guia-completa.md**: Este documento, que proporciona una guía completa para solucionar el problema del webhook de IA.

### Scripts SQL

1. **fix_webhook_ia_completo.sql**: Script principal que corrige el webhook de IA.
2. **create_check_if_table_exists_function.sql**: Script para crear la función `check_if_table_exists`.
3. **create_message_whatsapp_status_table.sql**: Script para crear la tabla `message_whatsapp_status`.
4. **verify_webhook_ia_status.sql**: Script para verificar el estado del webhook de IA.

### Scripts PowerShell

1. **apply_fix_webhook_ia_completo.ps1**: Script para ejecutar `fix_webhook_ia_completo.sql`.
2. **apply_create_message_whatsapp_status.ps1**: Script para ejecutar `create_check_if_table_exists_function.sql` y `create_message_whatsapp_status_table.sql`.
3. **update_edge_functions.ps1**: Script para actualizar las Edge Functions.
4. **verify_edge_functions.ps1**: Script para verificar si las Edge Functions están correctamente desplegadas.
5. **verify_webhook_ia_functionality.ps1**: Script para verificar si el webhook de IA está funcionando correctamente.
6. **test_webhook_ia.ps1**: Script para probar el webhook de IA.
7. **apply_complete_solution.ps1**: Script para ejecutar todos los scripts SQL y aplicar la solución completa.
8. **apply_all_with_edge_functions.ps1**: Script para ejecutar todos los scripts y aplicar la solución completa, incluyendo la actualización de las Edge Functions.
9. **apply_complete_solution_final.ps1**: Script para ejecutar todos los scripts y aplicar la solución completa, incluyendo la actualización de las Edge Functions y la verificación del webhook de IA.
10. **apply_all_solution.ps1**: Script para ejecutar todos los scripts y aplicar la solución completa, incluyendo la actualización de las Edge Functions, la verificación del webhook de IA y la actualización de la documentación.
11. **update_readme.ps1**: Script para actualizar el README-solucion-final.md con la información de los nuevos scripts.

### Edge Functions

1. **messages-outgoing/index.js**: Edge Function modificada para procesar mensajes de agentes.
2. **messages-incoming/index.js**: Edge Function modificada para procesar mensajes de clientes con `asistente_ia_activado = true`.

## Solución Implementada

La solución implementada corrige el problema del webhook de IA y establece una base sólida para el futuro:

1. **Recreación de la función `notify_message_webhook`**: Se ha recreado la función para asegurar que procese correctamente los mensajes con `asistente_ia_activado = true`.

2. **Recreación del trigger `message_webhook_trigger`**: Se ha recreado el trigger para asegurar que esté correctamente configurado y activado.

3. **Modificación de las Edge Functions**: Se han modificado las Edge Functions para que no interfieran con el procesamiento de mensajes.

4. **Creación de la tabla `message_whatsapp_status`**: Se ha creado una tabla para rastrear el estado de envío de mensajes a WhatsApp sin modificar directamente los mensajes en la tabla `messages`.

5. **Creación de la función `check_if_table_exists`**: Se ha creado una función para verificar si una tabla existe en la base de datos.

## Pasos para Implementar la Solución

### Opción 1: Solución Completa con Edge Functions, Verificación y Documentación

Ejecuta el script PowerShell `apply_all_solution.ps1`:

```powershell
.\apply_all_solution.ps1
```

Este script ejecutará todos los scripts y aplicará la solución completa, incluyendo la actualización de las Edge Functions, la verificación del webhook de IA y la actualización de la documentación.

### Opción 2: Solución Completa con Edge Functions y Verificación

Ejecuta el script PowerShell `apply_complete_solution_final.ps1`:

```powershell
.\apply_complete_solution_final.ps1
```

Este script ejecutará todos los scripts y aplicará la solución completa, incluyendo la actualización de las Edge Functions y la verificación del webhook de IA.

### Opción 3: Solución Completa con Edge Functions

Ejecuta el script PowerShell `apply_all_with_edge_functions.ps1`:

```powershell
.\apply_all_with_edge_functions.ps1
```

Este script ejecutará todos los scripts y aplicará la solución completa, incluyendo la actualización de las Edge Functions.

### Opción 4: Solución Completa sin Edge Functions

Ejecuta el script PowerShell `apply_complete_solution.ps1`:

```powershell
.\apply_complete_solution.ps1
```

Este script ejecutará todos los scripts SQL y aplicará la solución completa sin actualizar las Edge Functions.

### Opción 5: Paso a Paso

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

7. **Verificar la funcionalidad del webhook de IA**:

   ```powershell
   .\verify_webhook_ia_functionality.ps1
   ```

8. **Actualizar la documentación**:

   ```powershell
   .\update_readme.ps1
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

## Documentación Adicional

Para obtener más información sobre cómo funciona la solución, consulta los siguientes documentos:

1. **README-solucion-completa-webhook-ia.md**: Instrucciones detalladas para solucionar el problema del webhook de IA.
2. **README-solucion-final-actualizado.md**: Resumen de todos los archivos creados y cómo usarlos.
3. **README-edge-functions-supabase.md**: Explicación de cómo funcionan las Edge Functions en Supabase y cómo se relacionan con el webhook de IA.
4. **README-webhook-ia-funcionamiento.md**: Explicación de cómo funciona el webhook de IA en la aplicación.
5. **README-solucion-completa-explicacion.md**: Explicación completa de la solución.
6. **README-edge-functions-aplicacion.md**: Explicación de cómo funcionan las Edge Functions en la aplicación.
7. **README-edge-functions-triggers.md**: Explicación de cómo se relacionan las Edge Functions y los triggers de base de datos.
8. **README-webhook-ia-detalle.md**: Explicación detallada de cómo funciona el webhook de IA.

## Conclusión

La solución implementada corrige el problema del webhook de IA y establece una base sólida para el futuro. Al separar claramente las responsabilidades entre las Edge Functions y los triggers de base de datos, se evita que este problema vuelva a ocurrir.

La documentación proporcionada en este repositorio te ayudará a entender cómo funciona la solución y cómo implementarla. Si tienes alguna pregunta o problema, no dudes en consultar los documentos de referencia o contactar al equipo de desarrollo.
