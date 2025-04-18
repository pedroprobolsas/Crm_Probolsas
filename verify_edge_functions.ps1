# Script para verificar si las Edge Functions están correctamente desplegadas en Supabase
# Este script verifica si las Edge Functions messages-outgoing y messages-incoming están desplegadas

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

# Mostrar información
Write-Host "Verificando si las Edge Functions están correctamente desplegadas en Supabase..." -ForegroundColor Cyan
Write-Host "URL de Supabase: $supabaseUrl" -ForegroundColor Cyan
Write-Host ""

# Verificar las Edge Functions
$headers = @{
    "apikey" = $supabaseKey
    "Authorization" = "Bearer $supabaseKey"
    "Content-Type" = "application/json"
}

try {
    # Obtener la lista de Edge Functions
    $response = Invoke-RestMethod -Uri "$supabaseUrl/functions/v1" -Method Get -Headers $headers
    
    # Verificar si las Edge Functions messages-outgoing y messages-incoming están desplegadas
    $messagesOutgoing = $response | Where-Object { $_.name -eq "messages-outgoing" }
    $messagesIncoming = $response | Where-Object { $_.name -eq "messages-incoming" }
    
    if ($messagesOutgoing) {
        Write-Host "Edge Function messages-outgoing está desplegada." -ForegroundColor Green
        Write-Host "ID: $($messagesOutgoing.id)" -ForegroundColor Green
        Write-Host "Estado: $($messagesOutgoing.status)" -ForegroundColor Green
        Write-Host "Última actualización: $($messagesOutgoing.updated_at)" -ForegroundColor Green
    } else {
        Write-Host "Edge Function messages-outgoing NO está desplegada." -ForegroundColor Red
    }
    
    Write-Host ""
    
    if ($messagesIncoming) {
        Write-Host "Edge Function messages-incoming está desplegada." -ForegroundColor Green
        Write-Host "ID: $($messagesIncoming.id)" -ForegroundColor Green
        Write-Host "Estado: $($messagesIncoming.status)" -ForegroundColor Green
        Write-Host "Última actualización: $($messagesIncoming.updated_at)" -ForegroundColor Green
    } else {
        Write-Host "Edge Function messages-incoming NO está desplegada." -ForegroundColor Red
    }
    
    Write-Host ""
    
    # Verificar si los archivos de Edge Functions existen localmente
    $edgeFunctionFiles = @(
        "supabase/functions/messages-outgoing/index.js",
        "supabase/functions/messages-incoming/index.js"
    )
    
    foreach ($edgeFunctionFile in $edgeFunctionFiles) {
        if (Test-Path $edgeFunctionFile) {
            Write-Host "Archivo $edgeFunctionFile existe localmente." -ForegroundColor Green
        } else {
            Write-Host "Archivo $edgeFunctionFile NO existe localmente." -ForegroundColor Red
        }
    }
    
    Write-Host ""
    
    # Resumen
    if ($messagesOutgoing -and $messagesIncoming) {
        Write-Host "Las Edge Functions messages-outgoing y messages-incoming están correctamente desplegadas en Supabase." -ForegroundColor Green
    } else {
        Write-Host "Algunas Edge Functions no están desplegadas en Supabase." -ForegroundColor Red
        
        Write-Host ""
        Write-Host "Instrucciones para desplegar las Edge Functions:" -ForegroundColor Yellow
        Write-Host "1. Asegúrate de que los archivos de Edge Functions existan localmente." -ForegroundColor Yellow
        Write-Host "2. Usa el comando 'supabase functions deploy' para desplegar las Edge Functions." -ForegroundColor Yellow
        Write-Host "   Ejemplo: supabase functions deploy messages-outgoing" -ForegroundColor Yellow
        Write-Host "   Ejemplo: supabase functions deploy messages-incoming" -ForegroundColor Yellow
    }
} catch {
    Write-Host "Error al verificar las Edge Functions:" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    
    Write-Host ""
    Write-Host "No se pudo verificar si las Edge Functions están desplegadas en Supabase." -ForegroundColor Red
    Write-Host "Por favor, verifica manualmente en la consola de Supabase." -ForegroundColor Red
}

Write-Host ""
Write-Host "Verificación completada." -ForegroundColor Green
