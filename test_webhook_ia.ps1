# Script para probar el webhook de IA
# Este script inserta un mensaje de prueba con asistente_ia_activado=true

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

# SQL para insertar un mensaje de prueba
$sql = @"
DO \$\$
DECLARE
  test_conversation_id UUID;
  test_client_id UUID;
  test_message_id UUID;
BEGIN
  -- Obtener un conversation_id y client_id existentes
  SELECT conv.id, conv.client_id INTO test_conversation_id, test_client_id
  FROM conversations conv
  LIMIT 1;
  
  IF test_conversation_id IS NULL THEN
    RAISE NOTICE 'No se encontraron conversaciones para la prueba.';
    RETURN;
  END IF;
  
  -- Insertar un mensaje de prueba con asistente_ia_activado=true
  INSERT INTO messages (
    conversation_id,
    content,
    sender,
    sender_id,
    type,
    status,
    asistente_ia_activado
  )
  VALUES (
    test_conversation_id,
    'PRUEBA WEBHOOK IA: Mensaje de prueba para webhook de IA ' || NOW(),
    'client',
    test_client_id,
    'text',
    'sent',
    TRUE
  )
  RETURNING id INTO test_message_id;
  
  RAISE NOTICE 'Mensaje de prueba insertado con ID: %', test_message_id;
  RAISE NOTICE 'Verifica los logs de Supabase para ver si el mensaje fue enviado al webhook de IA.';
END;
\$\$;

-- Verificar si el mensaje fue enviado al webhook de IA
SELECT 
  id, 
  content, 
  sender, 
  status, 
  asistente_ia_activado, 
  ia_webhook_sent,
  created_at
FROM 
  messages
WHERE 
  content LIKE 'PRUEBA WEBHOOK IA: %'
ORDER BY 
  created_at DESC
LIMIT 5;
"@

# Mostrar información
Write-Host "Probando el webhook de IA..." -ForegroundColor Cyan
Write-Host "URL de Supabase: $supabaseUrl" -ForegroundColor Cyan
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
    
    # Guardar el SQL en un archivo temporal
    $tempFile = [System.IO.Path]::GetTempFileName() + ".sql"
    $sql | Out-File -FilePath $tempFile -Encoding utf8
    
    # Ejecutar el SQL usando psql
    $env:PGPASSWORD = $supabaseKey
    psql -h $host -p $port -d $database -U "postgres" -f $tempFile
    
    # Eliminar el archivo temporal
    Remove-Item -Path $tempFile
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Prueba ejecutada correctamente." -ForegroundColor Green
    } else {
        Write-Host "Error al ejecutar la prueba." -ForegroundColor Red
        exit 1
    }
} else {
    Write-Host "psql no está disponible. Usando API REST de Supabase..." -ForegroundColor Yellow
    
    $headers = @{
        "apikey" = $supabaseKey
        "Authorization" = "Bearer $supabaseKey"
        "Content-Type" = "application/json"
        "Prefer" = "params=single-object"
    }
    
    $body = @{
        "query" = $sql
    } | ConvertTo-Json
    
    try {
        $response = Invoke-RestMethod -Uri "$supabaseUrl/rest/sql" -Method Post -Headers $headers -Body $body
        Write-Host "Prueba ejecutada correctamente." -ForegroundColor Green
        Write-Host "Respuesta:" -ForegroundColor Cyan
        $response | ConvertTo-Json -Depth 10
    } catch {
        Write-Host "Error al ejecutar la prueba:" -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Red
        exit 1
    }
}

Write-Host ""
Write-Host "Prueba completada." -ForegroundColor Green
Write-Host ""
Write-Host "Pasos para verificar:" -ForegroundColor Cyan
Write-Host "1. Accede a la consola de Supabase" -ForegroundColor Cyan
Write-Host "2. Ve a la sección de Logs" -ForegroundColor Cyan
Write-Host "3. Busca mensajes relacionados con 'IA webhook', como:" -ForegroundColor Cyan
Write-Host "   - 'Selected IA webhook URL: X (is_production=true/false)'" -ForegroundColor Cyan
Write-Host "   - 'IA webhook payload: {...}'" -ForegroundColor Cyan
Write-Host "   - 'IA webhook request succeeded for message ID: X'" -ForegroundColor Cyan
Write-Host ""
Write-Host "También puedes verificar en la tabla messages si el campo ia_webhook_sent se ha actualizado a TRUE para el mensaje de prueba." -ForegroundColor Cyan
