# Script para ejecutar el diagnóstico del webhook de IA
# Este script utiliza la API de Supabase para ejecutar las consultas de diagnóstico

Write-Host "Iniciando diagnóstico del webhook de IA..." -ForegroundColor Cyan

# Verificar si el archivo de diagnóstico existe
if (-not (Test-Path "diagnose_ia_webhook.sql")) {
    Write-Host "Error: No se encontró el archivo diagnose_ia_webhook.sql" -ForegroundColor Red
    exit 1
}

# Leer el contenido del archivo SQL
$sqlContent = Get-Content -Path "diagnose_ia_webhook.sql" -Raw

# Dividir el archivo en consultas individuales
$queries = $sqlContent -split "--\s*\d+\." | Where-Object { $_ -match "\S" }

Write-Host "Se encontraron $($queries.Count) consultas de diagnóstico" -ForegroundColor Green

# Función para ejecutar una consulta SQL a través de la API de Supabase
function Execute-SupabaseQuery {
    param (
        [string]$query,
        [string]$description
    )
    
    Write-Host "`n>> Ejecutando: $description" -ForegroundColor Yellow
    
    # Guardar la consulta en un archivo temporal
    $tempFile = "temp_query.sql"
    $query | Out-File -FilePath $tempFile -Encoding utf8
    
    # Ejecutar la consulta usando el script apply_ia_webhook_migration.ps1 como referencia
    # (Asumiendo que este script tiene la lógica para conectarse a Supabase)
    try {
        if (Test-Path "apply_ia_webhook_migration.ps1") {
            # Modificar para usar el script existente para ejecutar la consulta
            Write-Host "Usando apply_ia_webhook_migration.ps1 como referencia para la conexión"
            
            # Extraer y mostrar la consulta para diagnóstico manual
            Write-Host "Consulta SQL para ejecutar manualmente:" -ForegroundColor Magenta
            Write-Host "----------------------------------------"
            Write-Host $query
            Write-Host "----------------------------------------"
            
            Write-Host "`nPor favor, ejecuta esta consulta manualmente en la consola SQL de Supabase" -ForegroundColor Cyan
            Write-Host "Presiona Enter cuando hayas completado esta consulta..." -ForegroundColor Cyan
            Read-Host
        } else {
            Write-Host "No se encontró el script apply_ia_webhook_migration.ps1" -ForegroundColor Red
            Write-Host "Por favor, ejecuta esta consulta manualmente en la consola SQL de Supabase:" -ForegroundColor Cyan
            Write-Host "----------------------------------------"
            Write-Host $query
            Write-Host "----------------------------------------"
            Write-Host "Presiona Enter cuando hayas completado esta consulta..." -ForegroundColor Cyan
            Read-Host
        }
    } catch {
        Write-Host "Error al ejecutar la consulta: $_" -ForegroundColor Red
    } finally {
        # Limpiar el archivo temporal
        if (Test-Path $tempFile) {
            Remove-Item $tempFile
        }
    }
}

# Ejecutar cada consulta de diagnóstico
$descriptions = @(
    "Verificar mensajes recientes para ver si tienen asistente_ia_activado=true",
    "Verificar las URLs del webhook de IA en app_settings",
    "Verificar si el trigger message_webhook_trigger está activo",
    "Verificar la definición de la función notify_message_webhook",
    "Verificar si la extensión http está instalada y disponible",
    "Verificar si hay errores recientes en los logs relacionados con el webhook",
    "Probar insertar un mensaje con asistente_ia_activado=true para verificar el funcionamiento",
    "Verificar si hay algún otro trigger en la tabla messages que pueda estar interfiriendo",
    "Verificar si la función http_post existe y está disponible",
    "Verificar el entorno (producción o pruebas)"
)

for ($i = 0; $i -lt [Math]::Min($queries.Count, $descriptions.Count); $i++) {
    Execute-SupabaseQuery -query $queries[$i] -description $descriptions[$i]
}

Write-Host "`nDiagnóstico completado. Revisa los resultados para identificar el problema." -ForegroundColor Green
Write-Host "Recuerda verificar los logs de Supabase para obtener más información sobre posibles errores." -ForegroundColor Yellow
