# Script para verificar el estado del webhook de IA
# Este script ejecuta el archivo SQL verify_webhook_ia_status.sql

# Configuración
$supabaseUrl = $env:SUPABASE_URL
$supabaseKey = $env:SUPABASE_SERVICE_ROLE_KEY
$sqlFile = "verify_webhook_ia_status.sql"

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

# Verificar si el archivo SQL existe
if (-not (Test-Path $sqlFile)) {
    Write-Host "El archivo $sqlFile no existe en el directorio actual." -ForegroundColor Red
    exit 1
}

# Mostrar información
Write-Host "Verificando el estado del webhook de IA..." -ForegroundColor Cyan
Write-Host "URL de Supabase: $supabaseUrl" -ForegroundColor Cyan
Write-Host "Archivo SQL: $sqlFile" -ForegroundColor Cyan
Write-Host ""

# Ejecutar el SQL usando psql si está disponible
$psqlAvailable = $null -ne (Get-Command "psql" -ErrorAction SilentlyContinue)

if ($psqlAvailable) {
    Write-Host "Ejecutando SQL usando psql..." -ForegroundColor Cyan
    
    # Extraer el host, puerto y base de datos de la URL de Supabase
    $uri = [System.Uri]$supabaseUrl
    $host = $uri.Host
    $port = if ($uri.Port -gt 0) { $uri.Port } else { 5432 }
    $database = $uri.Segments[1].TrimEnd('/')
    
    # Ejecutar el SQL usando psql
    $env:PGPASSWORD = $supabaseKey
    psql -h $host -p $port -d $database -U "postgres" -f $sqlFile
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Verificación completada correctamente." -ForegroundColor Green
    } else {
        Write-Host "Error al ejecutar la verificación." -ForegroundColor Red
        exit 1
    }
} else {
    Write-Host "psql no está disponible. Usando API REST de Supabase..." -ForegroundColor Yellow
    
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
        Write-Host "Verificación completada correctamente." -ForegroundColor Green
        Write-Host "Respuesta:" -ForegroundColor Cyan
        $response | ConvertTo-Json -Depth 10
    } catch {
        Write-Host "Error al ejecutar la verificación:" -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Red
        exit 1
    }
}

Write-Host ""
Write-Host "Verificación completada." -ForegroundColor Green
Write-Host ""
Write-Host "Si hay algún problema con el webhook de IA, ejecuta los siguientes scripts para solucionarlo:" -ForegroundColor Cyan
Write-Host "1. apply_create_message_whatsapp_status.ps1" -ForegroundColor Cyan
Write-Host "2. apply_fix_webhook_ia_completo.ps1" -ForegroundColor Cyan
Write-Host "3. test_webhook_ia.ps1" -ForegroundColor Cyan
Write-Host ""
Write-Host "También asegúrate de que los archivos de Edge Functions estén correctamente desplegados en Supabase." -ForegroundColor Cyan
