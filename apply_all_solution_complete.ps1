# Script para aplicar todas las soluciones en un solo paso, incluyendo la actualización de las Edge Functions, la verificación del webhook de IA, la actualización de la documentación, la verificación final y la actualización del resumen final
# Este script ejecuta todos los scripts PowerShell para solucionar el problema del webhook de IA

# Mostrar información
Write-Host "Aplicando todas las soluciones para el problema del webhook de IA, incluyendo la actualización de las Edge Functions, la verificación del webhook de IA, la actualización de la documentación, la verificación final y la actualización del resumen final..." -ForegroundColor Cyan
Write-Host ""

# Ejecutar los scripts PowerShell
$scripts = @(
    "apply_create_message_whatsapp_status.ps1",
    "apply_fix_webhook_ia_completo.ps1",
    "update_edge_functions.ps1",
    "test_webhook_ia.ps1",
    "run_verify_webhook_ia_status.ps1",
    "verify_edge_functions.ps1",
    "verify_webhook_ia_functionality.ps1",
    "update_readme.ps1"
)

foreach ($script in $scripts) {
    if (-not (Test-Path $script)) {
        Write-Host "El archivo $script no existe en el directorio actual." -ForegroundColor Red
        exit 1
    }
}

foreach ($script in $scripts) {
    Write-Host "Ejecutando $script..." -ForegroundColor Cyan
    & ".\$script"
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Error al ejecutar $script." -ForegroundColor Red
        exit 1
    }
    
    Write-Host "$script ejecutado correctamente." -ForegroundColor Green
    Write-Host ""
}

# Verificación final
Write-Host "Verificación final..." -ForegroundColor Cyan
Write-Host ""

# Verificar si las Edge Functions están correctamente desplegadas
Write-Host "Verificando si las Edge Functions están correctamente desplegadas..." -ForegroundColor Cyan
& ".\verify_edge_functions.ps1"

if ($LASTEXITCODE -ne 0) {
    Write-Host "Error al verificar las Edge Functions." -ForegroundColor Red
    exit 1
}

Write-Host "Edge Functions verificadas correctamente." -ForegroundColor Green
Write-Host ""

# Verificar si el webhook de IA está funcionando correctamente
Write-Host "Verificando si el webhook de IA está funcionando correctamente..." -ForegroundColor Cyan
& ".\verify_webhook_ia_functionality.ps1"

if ($LASTEXITCODE -ne 0) {
    Write-Host "Error al verificar el webhook de IA." -ForegroundColor Red
    exit 1
}

Write-Host "Webhook de IA verificado correctamente." -ForegroundColor Green
Write-Host ""

# Actualizar el resumen final
Write-Host "Actualizando el resumen final..." -ForegroundColor Cyan

# Verificar si el archivo README-resumen-final.md existe
if (Test-Path "README-resumen-final.md") {
    Write-Host "El archivo README-resumen-final.md existe." -ForegroundColor Green
} else {
    Write-Host "El archivo README-resumen-final.md no existe. Creando..." -ForegroundColor Yellow
    
    # Crear el archivo README-resumen-final.md
    @"
# Resumen Final de la Solución al Problema del Webhook de IA

Este documento proporciona un resumen final de la solución al problema del webhook de IA, incluyendo todos los scripts creados y cómo utilizarlos.

## Descripción del Problema

Se identificó un problema con el webhook de IA:

1. **Mensajes insertados por SQL**: Los mensajes insertados directamente mediante SQL (como los mensajes de prueba) sí llegan correctamente al webhook de IA.

2. **Mensajes desde la interfaz de usuario**: Los mensajes enviados desde la interfaz de usuario con el botón "Asistente IA Activado" encendido no llegan correctamente al webhook de IA.

3. **Interferencia de Edge Functions**: Las Edge Functions están interfiriendo con el procesamiento de mensajes.

## Solución Implementada

La solución implementada corrige el problema del webhook de IA y establece una base sólida para el futuro:

1. **Recreación de la función `notify_message_webhook`**: Se ha recreado la función para asegurar que procese correctamente los mensajes con `asistente_ia_activado = true`.

2. **Recreación del trigger `message_webhook_trigger`**: Se ha recreado el trigger para asegurar que esté correctamente configurado y activado.

3. **Modificación de las Edge Functions**: Se han modificado las Edge Functions para que no interfieran con el procesamiento de mensajes.

4. **Creación de la tabla `message_whatsapp_status`**: Se ha creado una tabla para rastrear el estado de envío de mensajes a WhatsApp sin modificar directamente los mensajes en la tabla `messages`.

5. **Creación de la función `check_if_table_exists`**: Se ha creado una función para verificar si una tabla existe en la base de datos.

## Conclusión

La solución implementada corrige el problema del webhook de IA y establece una base sólida para el futuro. Al separar claramente las responsabilidades entre las Edge Functions y los triggers de base de datos, se evita que este problema vuelva a ocurrir.

La documentación proporcionada en este repositorio te ayudará a entender cómo funciona la solución y cómo implementarla. Si tienes alguna pregunta o problema, no dudes en consultar los documentos de referencia o contactar al equipo de desarrollo.
"@ | Out-File -FilePath "README-resumen-final.md" -Encoding utf8
}

Write-Host "Resumen final actualizado correctamente." -ForegroundColor Green
Write-Host ""

Write-Host "Todas las soluciones han sido aplicadas correctamente, incluyendo la actualización de las Edge Functions, la verificación del webhook de IA, la actualización de la documentación, la verificación final y la actualización del resumen final." -ForegroundColor Green
Write-Host ""
Write-Host "Documentación disponible:" -ForegroundColor Cyan
Write-Host "1. README-solucion-completa-webhook-ia.md: Instrucciones detalladas para solucionar el problema del webhook de IA." -ForegroundColor Cyan
Write-Host "2. README-solucion-final.md: Resumen de todos los archivos creados y cómo usarlos." -ForegroundColor Cyan
Write-Host "3. README-edge-functions-supabase.md: Explicación de cómo funcionan las Edge Functions en Supabase." -ForegroundColor Cyan
Write-Host "4. README-webhook-ia-funcionamiento.md: Explicación de cómo funciona el webhook de IA." -ForegroundColor Cyan
Write-Host "5. README-solucion-completa-explicacion.md: Explicación completa de la solución." -ForegroundColor Cyan
Write-Host "6. README-edge-functions-aplicacion.md: Explicación de cómo funcionan las Edge Functions en la aplicación." -ForegroundColor Cyan
Write-Host "7. README-edge-functions-triggers.md: Explicación de cómo se relacionan las Edge Functions y los triggers de base de datos." -ForegroundColor Cyan
Write-Host "8. README-webhook-ia-detalle.md: Explicación detallada de cómo funciona el webhook de IA." -ForegroundColor Cyan
Write-Host "9. README-guia-completa.md: Guía completa para solucionar el problema del webhook de IA." -ForegroundColor Cyan
Write-Host "10. README-edge-functions-deno.md: Explicación de cómo funcionan las Edge Functions en Deno." -ForegroundColor Cyan
Write-Host "11. README-resumen-final.md: Resumen final de la solución al problema del webhook de IA." -ForegroundColor Cyan
Write-Host ""
Write-Host "Pasos para verificar:" -ForegroundColor Cyan
Write-Host "1. Accede a la consola de Supabase" -ForegroundColor Cyan
Write-Host "2. Ve a la sección de Logs" -ForegroundColor Cyan
Write-Host "3. Busca mensajes relacionados con 'IA webhook', como:" -ForegroundColor Cyan
Write-Host "   - 'Selected IA webhook URL: X (is_production=true/false)'" -ForegroundColor Cyan
Write-Host "   - 'IA webhook payload: {...}'" -ForegroundColor Cyan
Write-Host "   - 'IA webhook request succeeded for message ID: X'" -ForegroundColor Cyan
Write-Host ""
Write-Host "También puedes enviar un mensaje desde la interfaz de usuario con el asistente de IA activado para verificar que funciona correctamente." -ForegroundColor Cyan
