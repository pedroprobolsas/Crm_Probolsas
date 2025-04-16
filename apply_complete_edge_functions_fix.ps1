# Script para implementar la solución completa para el problema del webhook de IA
# Este script crea la tabla message_whatsapp_status y despliega las Edge Functions corregidas

# Configuración
$createTableSqlPath = "create_message_whatsapp_status.sql"
$messagesOutgoingPath = "supabase/functions/messages-outgoing/index.js"
$messagesIncomingPath = "supabase/functions/messages-incoming/index.js"
$logFilePath = "complete_edge_functions_fix_log.txt"

# Verificar que los archivos existen
if (-not (Test-Path $createTableSqlPath)) {
    Write-Host "Error: No se encontró el archivo SQL en la ruta: $createTableSqlPath" -ForegroundColor Red
    exit 1
}
if (-not (Test-Path $messagesOutgoingPath)) {
    Write-Host "Error: No se encontró el archivo de la Edge Function en la ruta: $messagesOutgoingPath" -ForegroundColor Red
    exit 1
}
if (-not (Test-Path $messagesIncomingPath)) {
    Write-Host "Error: No se encontró el archivo de la Edge Function en la ruta: $messagesIncomingPath" -ForegroundColor Red
    exit 1
}

# Mostrar encabezado
Write-Host "====================================================" -ForegroundColor Cyan
Write-Host "  SOLUCIÓN COMPLETA PARA EL PROBLEMA DEL WEBHOOK DE IA" -ForegroundColor Cyan
Write-Host "====================================================" -ForegroundColor Cyan
Write-Host ""

# Preguntar al usuario si desea continuar
$continue = Read-Host "Este script implementará la solución completa para el problema del webhook de IA. ¿Desea continuar? (S/N)"
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

# Paso 1: Crear la tabla message_whatsapp_status
Write-Host ""
Write-Host "PASO 1: Creando la tabla message_whatsapp_status..." -ForegroundColor Yellow
try {
    $result = psql -h $host -p $port -U $user -d $database -f $createTableSqlPath 2>&1
    
    # Guardar el resultado en el archivo de log
    $result | Out-File -FilePath $logFilePath -Encoding utf8
    
    # Mostrar el resultado
    Write-Host ""
    Write-Host "Resultado de la creación de la tabla:" -ForegroundColor Green
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
        exit 1
    }
    else {
        Write-Host ""
        Write-Host "Tabla message_whatsapp_status creada exitosamente." -ForegroundColor Green
    }
}
catch {
    Write-Host ""
    Write-Host "====================================================" -ForegroundColor Red
    Write-Host "  ERROR AL CREAR LA TABLA" -ForegroundColor Red
    Write-Host "====================================================" -ForegroundColor Red
    Write-Host ""
    Write-Host "Error al ejecutar el script SQL: $_" -ForegroundColor Red
    exit 1
}

# Paso 2: Desplegar las Edge Functions corregidas
Write-Host ""
Write-Host "PASO 2: Desplegando las Edge Functions corregidas..." -ForegroundColor Yellow
Write-Host ""
Write-Host "Para desplegar las Edge Functions, necesitas ejecutar los siguientes comandos en tu terminal:" -ForegroundColor Cyan
Write-Host ""
Write-Host "1. Desplegar la función messages-outgoing:" -ForegroundColor White
Write-Host "   supabase functions deploy messages-outgoing" -ForegroundColor Yellow
Write-Host ""
Write-Host "2. Desplegar la función messages-incoming:" -ForegroundColor White
Write-Host "   supabase functions deploy messages-incoming" -ForegroundColor Yellow
Write-Host ""

# Preguntar al usuario si ha desplegado las Edge Functions
$deployed = Read-Host "¿Has desplegado las Edge Functions? (S/N)"
if ($deployed -ne "S" -and $deployed -ne "s") {
    Write-Host "Por favor, despliega las Edge Functions antes de continuar." -ForegroundColor Yellow
    exit 0
}

# Paso 3: Verificar que todo funcione correctamente
Write-Host ""
Write-Host "PASO 3: Verificando que todo funcione correctamente..." -ForegroundColor Yellow
Write-Host ""
Write-Host "Para verificar que la solución ha funcionado correctamente:" -ForegroundColor Cyan
Write-Host "1. Envía un mensaje desde la interfaz de usuario con el botón de asistente IA activado." -ForegroundColor Cyan
Write-Host "2. Verifica en los logs de Supabase si el mensaje fue enviado al webhook de IA." -ForegroundColor Cyan
Write-Host "3. Verifica la respuesta del webhook para confirmar que los datos se recibieron correctamente." -ForegroundColor Cyan
Write-Host ""

# Preguntar al usuario si ha verificado que todo funcione correctamente
$verified = Read-Host "¿Has verificado que todo funcione correctamente? (S/N)"
if ($verified -eq "S" -or $verified -eq "s") {
    Write-Host ""
    Write-Host "====================================================" -ForegroundColor Green
    Write-Host "  SOLUCIÓN COMPLETA APLICADA EXITOSAMENTE" -ForegroundColor Green
    Write-Host "====================================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "La solución completa para el problema del webhook de IA ha sido aplicada exitosamente." -ForegroundColor Green
    Write-Host ""
    Write-Host "Resumen de los cambios realizados:" -ForegroundColor Cyan
    Write-Host "1. Se ha creado la tabla message_whatsapp_status para rastrear el estado de envío a WhatsApp." -ForegroundColor Cyan
    Write-Host "2. Se han desplegado las Edge Functions corregidas:" -ForegroundColor Cyan
    Write-Host "   - messages-outgoing: Ahora usa la tabla message_whatsapp_status en lugar de actualizar directamente los mensajes." -ForegroundColor Cyan
    Write-Host "   - messages-incoming: Ahora solo registra los mensajes recibidos sin interferir con el procesamiento." -ForegroundColor Cyan
    Write-Host "3. Se ha verificado que todo funcione correctamente." -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Si en el futuro necesitas hacer más cambios, consulta el archivo README-edge-functions.md para obtener instrucciones detalladas." -ForegroundColor Cyan
}
else {
    Write-Host ""
    Write-Host "====================================================" -ForegroundColor Yellow
    Write-Host "  SOLUCIÓN APLICADA PARCIALMENTE" -ForegroundColor Yellow
    Write-Host "====================================================" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "La solución ha sido aplicada parcialmente. Por favor, verifica que todo funcione correctamente." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Si encuentras algún problema, consulta el archivo README-edge-functions.md para obtener instrucciones detalladas." -ForegroundColor Cyan
}

# Limpiar la variable de entorno de la contraseña
$env:PGPASSWORD = ""
