# Script para aplicar la solución completa al problema del webhook de IA
# Este script ejecuta todos los scripts SQL y aplica la solución completa

# Configuración
$supabaseUrl = $env:SUPABASE_URL
$supabaseKey = $env:SUPABASE_SERVICE_ROLE_KEY
$sqlFiles = @(
    "create_check_if_table_exists_function.sql",
    "create_message_whatsapp_status_table.sql",
    "fix_webhook_ia_completo.sql"
)

# Verificar si las variables de entorno están configuradas
if (-not $supabaseUrl -or -not $supabaseKey) {
    Write-Host "Las variables de entorno SUPABASE_URL y SUPABASE_SERVICE_ROLE_KEY no están configuradas." -ForegroundColor Red
    Write-Host "Por favor, configúralas antes de ejecutar este script." -ForegroundColor Red
    Write-Host ""
    Write-Host "Puedes configurarlas temporalmente con los siguientes comandos:" -ForegroundColor Yellow
    Write-Host '$env:SUPABASE_URL = "tu-url-de-supabase"' -ForegroundColor Yellow
    Write-Host '$env:SUPABASE_SERVICE_ROLE_KEY = "tu-service-role-key"' -ForegroundColor Yellow
    Write-Host ""
    
    # Solicitar al usuario que ingrese las credenciales
    $supabaseUrl = Read-Host "Ingresa la URL de Supabase"
    $supabaseKey = Read-Host "Ingresa la Service Role Key de Supabase"
    
    if (-not $supabaseUrl -or -not $supabaseKey) {
        Write-Host "No se proporcionaron credenciales válidas. Saliendo..." -ForegroundColor Red
        exit 1
    }
    
    # Configurar temporalmente las variables de entorno
    $env:SUPABASE_URL = $supabaseUrl
    $env:SUPABASE_SERVICE_ROLE_KEY = $supabaseKey
}

# Verificar si los archivos SQL existen
foreach ($sqlFile in $sqlFiles) {
    if (-not (Test-Path $sqlFile)) {
        Write-Host "El archivo $sqlFile no existe en el directorio actual." -ForegroundColor Red
        exit 1
    }
}

# Verificar si los archivos de Edge Functions existen
$edgeFunctionFiles = @(
    "supabase/functions/messages-outgoing/index.js",
    "supabase/functions/messages-incoming/index.js"
)

foreach ($edgeFunctionFile in $edgeFunctionFiles) {
    if (-not (Test-Path $edgeFunctionFile)) {
        Write-Host "El archivo $edgeFunctionFile no existe. Asegúrate de que los archivos de Edge Functions estén en la ubicación correcta." -ForegroundColor Red
        exit 1
    }
}

# Mostrar información
Write-Host "Aplicando la solución completa al problema del webhook de IA..." -ForegroundColor Cyan
Write-Host "URL de Supabase: $supabaseUrl" -ForegroundColor Cyan
Write-Host "Archivos SQL: $($sqlFiles -join ', ')" -ForegroundColor Cyan
Write-Host "Archivos de Edge Functions: $($edgeFunctionFiles -join ', ')" -ForegroundColor Cyan
Write-Host ""

# Ejecutar los SQL usando psql si está disponible
$psqlAvailable = $null -ne (Get-Command "psql" -ErrorAction SilentlyContinue)

if ($psqlAvailable) {
    Write-Host "Ejecutando SQL usando psql..." -ForegroundColor Cyan
    
    # Extraer el host, puerto y base de datos de la URL de Supabase
    $uri = [System.Uri]$supabaseUrl
    $host = $uri.Host
    $port = if ($uri.Port -gt 0) { $uri.Port } else { 5432 }
    $database = $uri.Segments[1].TrimEnd('/')
    
    # Ejecutar cada archivo SQL usando psql
    foreach ($sqlFile in $sqlFiles) {
        Write-Host "Ejecutando $sqlFile..." -ForegroundColor Cyan
        $env:PGPASSWORD = $supabaseKey
        psql -h $host -p $port -d $database -U "postgres" -f $sqlFile
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "$sqlFile ejecutado correctamente." -ForegroundColor Green
        } else {
            Write-Host "Error al ejecutar $sqlFile." -ForegroundColor Red
            exit 1
        }
    }
} else {
    Write-Host "psql no está disponible. Usando API REST de Supabase..." -ForegroundColor Yellow
    
    # Ejecutar cada archivo SQL usando la API REST de Supabase
    foreach ($sqlFile in $sqlFiles) {
        Write-Host "Ejecutando $sqlFile..." -ForegroundColor Cyan
        
        # Leer el contenido del archivo SQL
        $sqlContent = Get-Content -Path $sqlFile -Raw
        
        $headers = @{
            "apikey" = $supabaseKey
            "Authorization" = "Bearer $supabaseKey"
            "Content-Type" = "application/json"
            "Prefer" = "params=single-object"
        }
        
        $body = @{
            "query" = $sqlContent
        } | ConvertTo-Json
        
        try {
            $response = Invoke-RestMethod -Uri "$supabaseUrl/rest/sql" -Method Post -Headers $headers -Body $body
            Write-Host "$sqlFile ejecutado correctamente." -ForegroundColor Green
        } catch {
            Write-Host "Error al ejecutar $sqlFile:" -ForegroundColor Red
            Write-Host $_.Exception.Message -ForegroundColor Red
            exit 1
        }
    }
}

Write-Host ""
Write-Host "Solución aplicada correctamente." -ForegroundColor Green
Write-Host ""
Write-Host "IMPORTANTE: Asegúrate de que los archivos de Edge Functions estén correctamente desplegados en Supabase." -ForegroundColor Yellow
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
