# Script para actualizar las Edge Functions en Supabase
# Este script actualiza las Edge Functions messages-outgoing y messages-incoming

# Configuración
$supabaseUrl = $env:SUPABASE_URL
$supabaseKey = $env:SUPABASE_SERVICE_ROLE_KEY

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

# Verificar si los archivos de Edge Functions existen
$edgeFunctionFiles = @(
    "supabase/functions/messages-outgoing/index.js",
    "supabase/functions/messages-incoming/index.js"
)

foreach ($edgeFunctionFile in $edgeFunctionFiles) {
    if (-not (Test-Path $edgeFunctionFile)) {
        Write-Host "El archivo $edgeFunctionFile no existe en el directorio actual." -ForegroundColor Red
        exit 1
    }
}

# Verificar si supabase CLI está instalado
$supabaseCliAvailable = $null -ne (Get-Command "supabase" -ErrorAction SilentlyContinue)

if (-not $supabaseCliAvailable) {
    Write-Host "supabase CLI no está instalado o no está disponible en el PATH." -ForegroundColor Red
    Write-Host "Por favor, instala supabase CLI antes de ejecutar este script." -ForegroundColor Red
    Write-Host "Puedes instalarlo siguiendo las instrucciones en: https://supabase.com/docs/guides/cli" -ForegroundColor Yellow
    exit 1
}

# Mostrar información
Write-Host "Actualizando las Edge Functions en Supabase..." -ForegroundColor Cyan
Write-Host "URL de Supabase: $supabaseUrl" -ForegroundColor Cyan
Write-Host ""

# Actualizar las Edge Functions
$edgeFunctions = @(
    "messages-outgoing",
    "messages-incoming"
)

foreach ($edgeFunction in $edgeFunctions) {
    Write-Host "Actualizando Edge Function $edgeFunction..." -ForegroundColor Cyan
    
    # Ejecutar el comando supabase functions deploy
    supabase functions deploy $edgeFunction
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Edge Function $edgeFunction actualizada correctamente." -ForegroundColor Green
    } else {
        Write-Host "Error al actualizar Edge Function $edgeFunction." -ForegroundColor Red
        exit 1
    }
    
    Write-Host ""
}

Write-Host "Todas las Edge Functions han sido actualizadas correctamente." -ForegroundColor Green
Write-Host ""
Write-Host "Pasos para verificar:" -ForegroundColor Cyan
Write-Host "1. Ejecuta el script verify_edge_functions.ps1 para verificar que las Edge Functions están correctamente desplegadas." -ForegroundColor Cyan
Write-Host "2. Envía un mensaje desde la interfaz de usuario con el asistente de IA activado para verificar que funciona correctamente." -ForegroundColor Cyan
Write-Host "3. Verifica los logs de Supabase para confirmar que el webhook de IA está funcionando correctamente." -ForegroundColor Cyan
