# Script para aplicar la corrección del formato de datos del webhook de IA
# Este script ejecuta el archivo SQL fix_ia_webhook_format.sql para corregir el problema
# donde los datos del mensaje y del cliente se están enviando incorrectamente como parte
# del encabezado "content-type" en lugar de enviarse en el cuerpo (body) de la solicitud HTTP.

# Configuración
$scriptPath = $PSScriptRoot
$sqlFilePath = Join-Path -Path $scriptPath -ChildPath "fix_ia_webhook_format.sql"
$logFilePath = Join-Path -Path $scriptPath -ChildPath "fix_ia_webhook_format_log.txt"

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
        Write-Host "Aplicando corrección del formato de datos del webhook de IA..." -ForegroundColor Yellow
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
            Write-Host "Corrección aplicada exitosamente." -ForegroundColor Green
            return $true
        }
    }
    catch {
        Write-Host "Error al ejecutar el script SQL: $_" -ForegroundColor Red
        return $false
    }
}

# Función para verificar si la corrección funcionó
function Verify-Correction {
    try {
        Write-Host "Verificando si la corrección funcionó..." -ForegroundColor Yellow
        
        # Ejecutar una consulta para verificar si la función http_post existe y tiene la implementación correcta
        $env:PGPASSWORD = $env:SUPABASE_DB_PASSWORD
        $query = "SELECT pg_get_functiondef(p.oid) FROM pg_proc p JOIN pg_namespace n ON p.pronamespace = n.oid WHERE p.proname = 'http_post' AND n.nspname = 'public';"
        $result = psql -h $env:SUPABASE_DB_HOST -p $env:SUPABASE_DB_PORT -U $env:SUPABASE_DB_USER -d $env:SUPABASE_DB_NAME -c $query -t 2>&1
        
        # Verificar si la función contiene la corrección
        if ($result -match "body,") {
            Write-Host "La función http_post ha sido actualizada correctamente." -ForegroundColor Green
            return $true
        }
        else {
            Write-Host "La función http_post no parece haber sido actualizada correctamente." -ForegroundColor Red
            return $false
        }
    }
    catch {
        Write-Host "Error al verificar la corrección: $_" -ForegroundColor Red
        return $false
    }
}

# Función principal
function Main {
    # Mostrar encabezado
    Write-Host "====================================================" -ForegroundColor Cyan
    Write-Host "  CORRECCIÓN DEL FORMATO DE DATOS DEL WEBHOOK DE IA" -ForegroundColor Cyan
    Write-Host "====================================================" -ForegroundColor Cyan
    Write-Host ""
    
    # Preguntar al usuario si desea continuar
    $continue = Read-Host "Este script aplicará la corrección del formato de datos del webhook de IA. ¿Desea continuar? (S/N)"
    if ($continue -ne "S" -and $continue -ne "s") {
        Write-Host "Operación cancelada por el usuario." -ForegroundColor Yellow
        exit 0
    }
    
    # Ejecutar el script SQL
    $success = Execute-SqlScript -sqlFilePath $sqlFilePath -logFilePath $logFilePath
    
    if ($success) {
        # Verificar si la corrección funcionó
        $verified = Verify-Correction
        
        if ($verified) {
            Write-Host ""
            Write-Host "====================================================" -ForegroundColor Green
            Write-Host "  CORRECCIÓN APLICADA EXITOSAMENTE" -ForegroundColor Green
            Write-Host "====================================================" -ForegroundColor Green
            Write-Host ""
            Write-Host "La corrección del formato de datos del webhook de IA ha sido aplicada exitosamente." -ForegroundColor Green
            Write-Host ""
            Write-Host "Para verificar que el webhook de IA está funcionando correctamente:" -ForegroundColor Cyan
            Write-Host "1. Envía un mensaje desde la interfaz de usuario con el botón de asistente IA activado." -ForegroundColor Cyan
            Write-Host "2. Verifica en los logs de Supabase que el mensaje se ha enviado al webhook de IA." -ForegroundColor Cyan
            Write-Host "3. Confirma que el webhook de IA ha recibido el mensaje correctamente en el cuerpo (body) de la solicitud." -ForegroundColor Cyan
            Write-Host ""
            Write-Host "Si sigues teniendo problemas, revisa el archivo de log: $logFilePath" -ForegroundColor Cyan
        }
        else {
            Write-Host ""
            Write-Host "====================================================" -ForegroundColor Yellow
            Write-Host "  CORRECCIÓN APLICADA PERO NO VERIFICADA" -ForegroundColor Yellow
            Write-Host "====================================================" -ForegroundColor Yellow
            Write-Host ""
            Write-Host "La corrección se aplicó pero no se pudo verificar completamente." -ForegroundColor Yellow
            Write-Host "Por favor, verifica manualmente si el webhook de IA está funcionando correctamente." -ForegroundColor Yellow
            Write-Host ""
            Write-Host "Revisa el archivo de log para más detalles: $logFilePath" -ForegroundColor Cyan
        }
    }
    else {
        Write-Host ""
        Write-Host "====================================================" -ForegroundColor Red
        Write-Host "  ERROR AL APLICAR LA CORRECCIÓN" -ForegroundColor Red
        Write-Host "====================================================" -ForegroundColor Red
        Write-Host ""
        Write-Host "Hubo un error al aplicar la corrección del formato de datos del webhook de IA." -ForegroundColor Red
        Write-Host "Por favor, revisa el archivo de log para más detalles: $logFilePath" -ForegroundColor Cyan
    }
}

# Ejecutar la función principal
Main
