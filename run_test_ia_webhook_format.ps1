# Script para ejecutar la prueba del formato de datos del webhook de IA
# Este script ejecuta el archivo SQL test_ia_webhook_format.sql para verificar
# si la corrección del formato de datos del webhook de IA ha funcionado correctamente.

# Configuración
$scriptPath = $PSScriptRoot
$sqlFilePath = Join-Path -Path $scriptPath -ChildPath "test_ia_webhook_format.sql"
$logFilePath = Join-Path -Path $scriptPath -ChildPath "test_ia_webhook_format_log.txt"

# Verificar que el archivo SQL existe
if (-not (Test-Path $sqlFilePath)) {
    Write-Host "Error: No se encontró el archivo SQL en la ruta: $sqlFilePath" -ForegroundColor Red
    exit 1
}

# Función para ejecutar el script SQL
function Execute-SqlScript {
    param (
        [string]$sqlFilePath,
        [string]$logFilePath
    )
    
    try {
        # Mostrar información sobre lo que se va a hacer
        Write-Host "Ejecutando prueba del formato de datos del webhook de IA..." -ForegroundColor Yellow
        Write-Host "Archivo SQL: $sqlFilePath" -ForegroundColor Cyan
        Write-Host "Log: $logFilePath" -ForegroundColor Cyan
        
        # Ejecutar el script SQL usando psql (asumiendo que está en el PATH)
        # Ajusta los parámetros de conexión según tu configuración
        $env:PGPASSWORD = $env:SUPABASE_DB_PASSWORD
        $result = psql -h $env:SUPABASE_DB_HOST -p $env:SUPABASE_DB_PORT -U $env:SUPABASE_DB_USER -d $env:SUPABASE_DB_NAME -f $sqlFilePath 2>&1
        
        # Guardar el resultado en el archivo de log
        $result | Out-File -FilePath $logFilePath -Encoding utf8
        
        # Mostrar el resultado
        Write-Host "Resultado de la ejecución:" -ForegroundColor Green
        $result | ForEach-Object { Write-Host $_ }
        
        # Verificar si hubo errores
        if ($result -match "ERROR:") {
            Write-Host "Se encontraron errores durante la ejecución. Revisa el archivo de log para más detalles." -ForegroundColor Red
            return $false
        }
        else {
            Write-Host "Prueba ejecutada exitosamente." -ForegroundColor Green
            return $true
        }
    }
    catch {
        Write-Host "Error al ejecutar el script SQL: $_" -ForegroundColor Red
        return $false
    }
}

# Función principal
function Main {
    # Mostrar encabezado
    Write-Host "====================================================" -ForegroundColor Cyan
    Write-Host "  PRUEBA DEL FORMATO DE DATOS DEL WEBHOOK DE IA" -ForegroundColor Cyan
    Write-Host "====================================================" -ForegroundColor Cyan
    Write-Host ""
    
    # Preguntar al usuario si desea continuar
    $continue = Read-Host "Este script ejecutará la prueba del formato de datos del webhook de IA. ¿Desea continuar? (S/N)"
    if ($continue -ne "S" -and $continue -ne "s") {
        Write-Host "Operación cancelada por el usuario." -ForegroundColor Yellow
        exit 0
    }
    
    # Ejecutar el script SQL
    $success = Execute-SqlScript -sqlFilePath $sqlFilePath -logFilePath $logFilePath
    
    if ($success) {
        Write-Host ""
        Write-Host "====================================================" -ForegroundColor Green
        Write-Host "  PRUEBA EJECUTADA EXITOSAMENTE" -ForegroundColor Green
        Write-Host "====================================================" -ForegroundColor Green
        Write-Host ""
        Write-Host "La prueba del formato de datos del webhook de IA ha sido ejecutada exitosamente." -ForegroundColor Green
        Write-Host ""
        Write-Host "Para verificar si la corrección del formato de datos del webhook de IA ha funcionado correctamente:" -ForegroundColor Cyan
        Write-Host "1. Verifica los logs de Supabase para ver si el mensaje fue enviado al webhook de IA." -ForegroundColor Cyan
        Write-Host "2. Verifica la respuesta del webhook para confirmar que los datos se recibieron correctamente en el cuerpo (body) de la solicitud." -ForegroundColor Cyan
        Write-Host ""
        Write-Host "Si los datos se reciben correctamente en el cuerpo (body) de la solicitud, la corrección ha funcionado." -ForegroundColor Cyan
        Write-Host "Si los datos siguen apareciendo en el encabezado 'content-type', la corrección no ha funcionado." -ForegroundColor Cyan
        Write-Host ""
        Write-Host "Revisa el archivo de log para más detalles: $logFilePath" -ForegroundColor Cyan
    }
    else {
        Write-Host ""
        Write-Host "====================================================" -ForegroundColor Red
        Write-Host "  ERROR AL EJECUTAR LA PRUEBA" -ForegroundColor Red
        Write-Host "====================================================" -ForegroundColor Red
        Write-Host ""
        Write-Host "Hubo un error al ejecutar la prueba del formato de datos del webhook de IA." -ForegroundColor Red
        Write-Host "Por favor, revisa el archivo de log para más detalles: $logFilePath" -ForegroundColor Cyan
    }
}

# Ejecutar la función principal
Main
