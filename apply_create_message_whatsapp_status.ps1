# Script simplificado para crear la tabla message_whatsapp_status
# Este script ejecuta directamente el archivo SQL create_message_whatsapp_status.sql

# Configuración
$sqlFilePath = "create_message_whatsapp_status.sql"
$logFilePath = "create_message_whatsapp_status_log.txt"

# Verificar que el archivo SQL existe
if (-not (Test-Path $sqlFilePath)) {
    Write-Host "Error: No se encontró el archivo SQL en la ruta: $sqlFilePath" -ForegroundColor Red
    exit 1
}

# Mostrar encabezado
Write-Host "====================================================" -ForegroundColor Cyan
Write-Host "  CREACIÓN DE LA TABLA MESSAGE_WHATSAPP_STATUS" -ForegroundColor Cyan
Write-Host "====================================================" -ForegroundColor Cyan
Write-Host ""

# Preguntar al usuario si desea continuar
$continue = Read-Host "Este script creará la tabla message_whatsapp_status para rastrear el estado de envío a WhatsApp. ¿Desea continuar? (S/N)"
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
Write-Host "Creando la tabla message_whatsapp_status..." -ForegroundColor Yellow
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
        Write-Host "  ERROR AL CREAR LA TABLA" -ForegroundColor Red
        Write-Host "====================================================" -ForegroundColor Red
        Write-Host ""
        Write-Host "Se encontraron errores durante la creación de la tabla. Revisa el archivo de log para más detalles." -ForegroundColor Red
        Write-Host "Archivo de log: $logFilePath" -ForegroundColor Cyan
    }
    else {
        Write-Host ""
        Write-Host "====================================================" -ForegroundColor Green
        Write-Host "  TABLA CREADA EXITOSAMENTE" -ForegroundColor Green
        Write-Host "====================================================" -ForegroundColor Green
        Write-Host ""
        Write-Host "La tabla message_whatsapp_status ha sido creada exitosamente." -ForegroundColor Green
        Write-Host ""
        Write-Host "Ahora puedes desplegar las Edge Functions corregidas:" -ForegroundColor Cyan
        Write-Host "1. Ejecuta el siguiente comando para desplegar la función messages-outgoing:" -ForegroundColor Cyan
        Write-Host "   supabase functions deploy messages-outgoing" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "2. Ejecuta el siguiente comando para desplegar la función messages-incoming:" -ForegroundColor Cyan
        Write-Host "   supabase functions deploy messages-incoming" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "3. Verifica que todo funcione correctamente enviando un mensaje desde la interfaz de usuario con el botón de asistente IA activado." -ForegroundColor Cyan
    }
}
catch {
    Write-Host ""
    Write-Host "====================================================" -ForegroundColor Red
    Write-Host "  ERROR AL CREAR LA TABLA" -ForegroundColor Red
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
    Write-Host "   a. Copia y pega el contenido del archivo $sqlFilePath en la consola SQL de Supabase" -ForegroundColor Cyan
    Write-Host "   b. Ejecuta el script y verifica los resultados" -ForegroundColor Cyan
    Write-Host "   c. Despliega las Edge Functions corregidas" -ForegroundColor Cyan
}

# Limpiar la variable de entorno de la contraseña
$env:PGPASSWORD = ""
