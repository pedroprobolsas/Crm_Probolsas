# Script simplificado para probar la corrección del formato de datos del webhook de IA
# Este script ejecuta directamente el archivo SQL test_ia_webhook_format.sql

# Configuración
$sqlFilePath = "test_ia_webhook_format.sql"
$logFilePath = "test_ia_webhook_format_log.txt"

# Verificar que el archivo SQL existe
if (-not (Test-Path $sqlFilePath)) {
    Write-Host "Error: No se encontró el archivo SQL en la ruta: $sqlFilePath" -ForegroundColor Red
    exit 1
}

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

# Solicitar datos de conexión a Supabase
Write-Host ""
Write-Host "Por favor, proporciona los siguientes datos para conectarte a Supabase:" -ForegroundColor Yellow
$host = Read-Host "Host de Supabase (ej. db.abcdefghijkl.supabase.co)"
$port = Read-Host "Puerto de Supabase (ej. 5432)"
if ([string]::IsNullOrWhiteSpace($port)) { $port = "5432" }
$user = Read-Host "Usuario de Supabase (ej. postgres)"
if ([string]::IsNullOrWhiteSpace($user)) { $user = "postgres" }
$password = Read-Host "Contraseña de Supabase"
$database = Read-Host "Nombre de la base de datos (ej. postgres)"
if ([string]::IsNullOrWhiteSpace($database)) { $database = "postgres" }

# Configurar variables de entorno
$env:PGPASSWORD = $password

# Mostrar información sobre lo que se va a hacer
Write-Host ""
Write-Host "Ejecutando prueba del formato de datos del webhook de IA..." -ForegroundColor Yellow
Write-Host "Archivo SQL: $sqlFilePath" -ForegroundColor Cyan
Write-Host "Log: $logFilePath" -ForegroundColor Cyan

# Ejecutar el script SQL
try {
    $result = psql -h $host -p $port -U $user -d $database -f $sqlFilePath 2>&1
    
    # Guardar el resultado en el archivo de log
    $result | Out-File -FilePath $logFilePath -Encoding utf8
    
    # Mostrar el resultado
    Write-Host ""
    Write-Host "Resultado de la ejecución:" -ForegroundColor Green
    $result | ForEach-Object { Write-Host $_ }
    
    # Verificar si hubo errores
    if ($result -match "ERROR:") {
        Write-Host ""
        Write-Host "====================================================" -ForegroundColor Red
        Write-Host "  ERROR AL EJECUTAR LA PRUEBA" -ForegroundColor Red
        Write-Host "====================================================" -ForegroundColor Red
        Write-Host ""
        Write-Host "Se encontraron errores durante la ejecución. Revisa el archivo de log para más detalles." -ForegroundColor Red
        Write-Host "Archivo de log: $logFilePath" -ForegroundColor Cyan
    }
    else {
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
    }
}
catch {
    Write-Host ""
    Write-Host "====================================================" -ForegroundColor Red
    Write-Host "  ERROR AL EJECUTAR LA PRUEBA" -ForegroundColor Red
    Write-Host "====================================================" -ForegroundColor Red
    Write-Host ""
    Write-Host "Error al ejecutar el script SQL: $_" -ForegroundColor Red
    Write-Host ""
    Write-Host "Posibles causas:" -ForegroundColor Yellow
    Write-Host "1. psql no está instalado o no está en el PATH." -ForegroundColor Yellow
    Write-Host "2. Los datos de conexión a Supabase son incorrectos." -ForegroundColor Yellow
    Write-Host "3. La base de datos de Supabase no es accesible desde tu red." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Soluciones:" -ForegroundColor Cyan
    Write-Host "1. Instala PostgreSQL o asegúrate de que psql esté en el PATH." -ForegroundColor Cyan
    Write-Host "2. Verifica los datos de conexión a Supabase." -ForegroundColor Cyan
    Write-Host "3. Verifica que la base de datos de Supabase sea accesible desde tu red." -ForegroundColor Cyan
}

# Limpiar la variable de entorno de la contraseña
$env:PGPASSWORD = ""
