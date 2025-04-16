# Script para aplicar la corrección del webhook de IA deshabilitando Edge Functions
# Este script proporciona instrucciones para deshabilitar manualmente las Edge Functions
# y luego ejecuta el archivo SQL fix_edge_functions_ia_webhook.sql

# Configuración
$sqlFilePath = "fix_edge_functions_ia_webhook.sql"
$logFilePath = "fix_edge_functions_ia_webhook_log.txt"

# Verificar que el archivo SQL existe
if (-not (Test-Path $sqlFilePath)) {
    Write-Host "Error: No se encontró el archivo SQL en la ruta: $sqlFilePath" -ForegroundColor Red
    exit 1
}

# Mostrar encabezado
Write-Host "====================================================" -ForegroundColor Cyan
Write-Host "  CORRECCIÓN DEL WEBHOOK DE IA - EDGE FUNCTIONS" -ForegroundColor Cyan
Write-Host "====================================================" -ForegroundColor Cyan
Write-Host ""

# Mostrar instrucciones para deshabilitar las Edge Functions
Write-Host "PASO 1: Deshabilitar las Edge Functions manualmente" -ForegroundColor Yellow
Write-Host ""
Write-Host "Para deshabilitar las Edge Functions, debes hacerlo manualmente desde la interfaz de Supabase:" -ForegroundColor White
Write-Host "1. Ve a la sección 'Edge Functions' en Supabase" -ForegroundColor White
Write-Host "2. Busca las funciones 'messages-outgoing' y 'messages-incoming'" -ForegroundColor White
Write-Host "3. Deshabilita temporalmente estas funciones" -ForegroundColor White
Write-Host ""

# Preguntar al usuario si ha deshabilitado las Edge Functions
$disabledFunctions = Read-Host "¿Has deshabilitado las Edge Functions? (S/N)"
if ($disabledFunctions -ne "S" -and $disabledFunctions -ne "s") {
    Write-Host "Por favor, deshabilita las Edge Functions antes de continuar." -ForegroundColor Yellow
    exit 0
}

# Preguntar al usuario si desea continuar con el script SQL
Write-Host ""
Write-Host "PASO 2: Ejecutar el script SQL para completar la corrección" -ForegroundColor Yellow
Write-Host ""
$continue = Read-Host "¿Deseas ejecutar el script SQL para completar la corrección? (S/N)"
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
Write-Host "Ejecutando script SQL para completar la corrección..." -ForegroundColor Yellow
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
        Write-Host "  ERROR AL APLICAR LA CORRECCIÓN" -ForegroundColor Red
        Write-Host "====================================================" -ForegroundColor Red
        Write-Host ""
        Write-Host "Se encontraron errores durante la ejecución. Revisa el archivo de log para más detalles." -ForegroundColor Red
        Write-Host "Archivo de log: $logFilePath" -ForegroundColor Cyan
    }
    else {
        Write-Host ""
        Write-Host "====================================================" -ForegroundColor Green
        Write-Host "  CORRECCIÓN APLICADA EXITOSAMENTE" -ForegroundColor Green
        Write-Host "====================================================" -ForegroundColor Green
        Write-Host ""
        Write-Host "La corrección ha sido aplicada exitosamente." -ForegroundColor Green
        Write-Host ""
        Write-Host "Para verificar si la solución ha funcionado:" -ForegroundColor Cyan
        Write-Host "1. Envía un mensaje desde la interfaz de usuario con el botón de asistente IA activado." -ForegroundColor Cyan
        Write-Host "2. Verifica en los logs de Supabase si el mensaje fue enviado al webhook de IA." -ForegroundColor Cyan
        Write-Host "3. Verifica la respuesta del webhook para confirmar que los datos se recibieron correctamente." -ForegroundColor Cyan
        Write-Host ""
        Write-Host "Si la solución funciona, puedes mantener las Edge Functions deshabilitadas o modificarlas" -ForegroundColor Cyan
        Write-Host "según las instrucciones en el archivo README-edge-functions.md." -ForegroundColor Cyan
    }
}
catch {
    Write-Host ""
    Write-Host "====================================================" -ForegroundColor Red
    Write-Host "  ERROR AL APLICAR LA CORRECCIÓN" -ForegroundColor Red
    Write-Host "====================================================" -ForegroundColor Red
    Write-Host ""
    Write-Host "Error al ejecutar el script SQL: $_" -ForegroundColor Red
    Write-Host ""
    Write-Host "Posibles causas:" -ForegroundColor Yellow
    Write-Host "1. psql no está instalado o no está en el PATH." -ForegroundColor Yellow
    Write-Host "2. Los datos de conexión a Supabase son incorrectos." -ForegroundColor Yellow
    Write-Host "3. La base de datos de Supabase no es accesible desde tu red." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Soluciones alternativas:" -ForegroundColor Cyan
    Write-Host "1. Aplica la solución manualmente siguiendo estos pasos:" -ForegroundColor Cyan
    Write-Host "   a. Deshabilita las Edge Functions 'messages-outgoing' y 'messages-incoming' desde la interfaz de Supabase" -ForegroundColor Cyan
    Write-Host "   b. Copia y pega el contenido del archivo $sqlFilePath en la consola SQL de Supabase" -ForegroundColor Cyan
    Write-Host "   c. Ejecuta el script y verifica los resultados" -ForegroundColor Cyan
}

# Limpiar la variable de entorno de la contraseña
$env:PGPASSWORD = ""
