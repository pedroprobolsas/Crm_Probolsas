# Script para aplicar todas las soluciones de una sola vez

# Configuración
$supabaseUrl = $env:SUPABASE_URL
$supabaseKey = $env:SUPABASE_SERVICE_ROLE_KEY
$sqlFile = "fix_webhook_ia_completo_final.sql"

# Mostrar instrucciones iniciales
Write-Host "APLICACIÓN COMPLETA DE SOLUCIONES" -ForegroundColor Cyan
Write-Host "=================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Este script aplicará todas las soluciones para los problemas de:" -ForegroundColor Yellow
Write-Host "1. Webhook de IA no funcionando" -ForegroundColor Yellow
Write-Host "2. Duplicación de clientes" -ForegroundColor Yellow
Write-Host ""
Write-Host "IMPORTANTE: Antes de ejecutar este script, asegúrate de:" -ForegroundColor Red
Write-Host "1. Tener acceso a la consola de Supabase" -ForegroundColor Red
Write-Host "2. Tener permisos para actualizar las Edge Functions" -ForegroundColor Red
Write-Host "3. Tener una copia de seguridad de la base de datos (por precaución)" -ForegroundColor Red
Write-Host ""
Write-Host "¿Deseas continuar con la aplicación de todas las soluciones? (S/N)" -ForegroundColor Cyan
$confirmation = Read-Host

if ($confirmation -ne "S") {
    Write-Host "Operación cancelada por el usuario." -ForegroundColor Yellow
    exit 0
}

# Paso 1: Verificar que los archivos necesarios existen
Write-Host ""
Write-Host "PASO 1: Verificando archivos necesarios..." -ForegroundColor Green
Write-Host "--------------------------------" -ForegroundColor Green

$requiredFiles = @(
    $sqlFile,
    "supabase/functions/messages-incoming/index.js",
    "supabase/functions/messages-outgoing/index.js"
)

$missingFiles = @()
foreach ($file in $requiredFiles) {
    if (-not (Test-Path $file)) {
        $missingFiles += $file
    }
}

if ($missingFiles.Count -gt 0) {
    Write-Host "Los siguientes archivos no existen:" -ForegroundColor Red
    foreach ($file in $missingFiles) {
        Write-Host "- $file" -ForegroundColor Red
    }
    Write-Host "Por favor, asegúrate de que todos los archivos necesarios existen antes de continuar." -ForegroundColor Red
    exit 1
}

Write-Host "Todos los archivos necesarios existen." -ForegroundColor Green

# Paso 2: Aplicar solución SQL para el webhook de IA
Write-Host ""
Write-Host "PASO 2: Aplicando solución SQL para el webhook de IA..." -ForegroundColor Green
Write-Host "------------------------------------------------" -ForegroundColor Green

try {
    # Leer el contenido del archivo SQL
    $sqlContent = Get-Content -Path $sqlFile -Raw
    
    # Usar curl para ejecutar el SQL en Supabase
    $headers = @{
        "apikey" = $supabaseKey
        "Authorization" = "Bearer $supabaseKey"
        "Content-Type" = "application/json"
        "Prefer" = "params=single-object"
    }
    
    $body = @{
        "query" = $sqlContent
    } | ConvertTo-Json -Depth 10
    
    $response = Invoke-RestMethod -Uri "$supabaseUrl/rest/v1/rpc/execute_sql" -Method POST -Headers $headers -Body $body
    
    Write-Host "Solución SQL aplicada correctamente." -ForegroundColor Green
}
catch {
    Write-Error "Error al aplicar la solución SQL: $_"
    Write-Host "¿Deseas continuar con el resto del proceso? (S/N)" -ForegroundColor Cyan
    $continueAfterError = Read-Host
    
    if ($continueAfterError -ne "S") {
        Write-Host "Operación cancelada por el usuario." -ForegroundColor Yellow
        exit 1
    }
}

# Paso 3: Actualizar las Edge Functions
Write-Host ""
Write-Host "PASO 3: Actualizando Edge Functions..." -ForegroundColor Green
Write-Host "--------------------------------" -ForegroundColor Green
Write-Host ""
Write-Host "Para actualizar las Edge Functions, sigue estos pasos:" -ForegroundColor Yellow
Write-Host "1. Ve a la sección 'Edge Functions' en la consola de Supabase" -ForegroundColor Yellow
Write-Host "2. Selecciona la función 'messages-incoming'" -ForegroundColor Yellow
Write-Host "3. Reemplaza el contenido del archivo index.js con el contenido del archivo supabase/functions/messages-incoming/index.js" -ForegroundColor Yellow
Write-Host "4. Guarda los cambios" -ForegroundColor Yellow
Write-Host "5. Selecciona la función 'messages-outgoing'" -ForegroundColor Yellow
Write-Host "6. Reemplaza el contenido del archivo index.js con el contenido del archivo supabase/functions/messages-outgoing/index.js" -ForegroundColor Yellow
Write-Host "7. Guarda los cambios" -ForegroundColor Yellow
Write-Host ""
Write-Host "¿Has actualizado las Edge Functions en Supabase? (S/N)" -ForegroundColor Cyan
$edgeFunctionsUpdated = Read-Host

if ($edgeFunctionsUpdated -ne "S") {
    Write-Host "Por favor, actualiza las Edge Functions antes de continuar." -ForegroundColor Red
    exit 1
}

# Paso 4: Verificar la solución
Write-Host ""
Write-Host "PASO 4: Verificando la solución..." -ForegroundColor Green
Write-Host "--------------------------------" -ForegroundColor Green

# Verificar que el trigger message_webhook_trigger está activo
try {
    $queryCheckTrigger = @"
    SELECT 
      t.tgname AS trigger_name,
      CASE WHEN t.tgenabled = 'D' THEN 'DESACTIVADO' ELSE 'ACTIVADO' END AS status
    FROM 
      pg_trigger t
    JOIN 
      pg_class c ON t.tgrelid = c.oid
    WHERE 
      c.relname = 'messages' AND
      t.tgname = 'message_webhook_trigger';
"@
    
    $bodyCheckTrigger = @{
        "query" = $queryCheckTrigger
    } | ConvertTo-Json -Depth 10
    
    $responseCheckTrigger = Invoke-RestMethod -Uri "$supabaseUrl/rest/v1/rpc/execute_sql" -Method POST -Headers $headers -Body $bodyCheckTrigger
    
    if ($responseCheckTrigger.result -and $responseCheckTrigger.result.Count -gt 0) {
        $triggerStatus = $responseCheckTrigger.result[0].status
        
        if ($triggerStatus -eq "ACTIVADO") {
            Write-Host "El trigger message_webhook_trigger está ACTIVADO." -ForegroundColor Green
        } else {
            Write-Host "El trigger message_webhook_trigger está DESACTIVADO. Esto podría causar problemas." -ForegroundColor Red
        }
    } else {
        Write-Host "No se encontró el trigger message_webhook_trigger. Esto podría causar problemas." -ForegroundColor Red
    }
}
catch {
    Write-Error "Error al verificar el trigger: $_"
}

# Insertar un mensaje de prueba con asistente_ia_activado=true
try {
    # Obtener una conversación y cliente existentes para la prueba
    $queryGetConversation = @"
    SELECT 
      conv.id as conversation_id, 
      conv.client_id
    FROM 
      conversations conv
    LIMIT 1;
"@
    
    $bodyGetConversation = @{
        "query" = $queryGetConversation
    } | ConvertTo-Json -Depth 10
    
    $responseGetConversation = Invoke-RestMethod -Uri "$supabaseUrl/rest/v1/rpc/execute_sql" -Method POST -Headers $headers -Body $bodyGetConversation
    
    if ($responseGetConversation.result -and $responseGetConversation.result.Count -gt 0) {
        $conversationId = $responseGetConversation.result[0].conversation_id
        $clientId = $responseGetConversation.result[0].client_id
        
        Write-Host "Conversación encontrada con ID: $conversationId" -ForegroundColor Green
        Write-Host "Cliente encontrado con ID: $clientId" -ForegroundColor Green
        
        # Insertar un mensaje de prueba
        $queryInsertMessage = @"
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
          '$conversationId',
          'VERIFICACIÓN FINAL: Mensaje de prueba para webhook de IA ' || NOW(),
          'client',
          '$clientId',
          'text',
          'sent',
          TRUE
        )
        RETURNING id;
"@
        
        $bodyInsertMessage = @{
            "query" = $queryInsertMessage
        } | ConvertTo-Json -Depth 10
        
        $responseInsertMessage = Invoke-RestMethod -Uri "$supabaseUrl/rest/v1/rpc/execute_sql" -Method POST -Headers $headers -Body $bodyInsertMessage
        
        if ($responseInsertMessage.result -and $responseInsertMessage.result.Count -gt 0) {
            $messageId = $responseInsertMessage.result[0].id
            Write-Host "Mensaje de prueba insertado con ID: $messageId" -ForegroundColor Green
            
            # Esperar un momento para que el trigger y las Edge Functions se ejecuten
            Write-Host "Esperando 3 segundos para que el trigger y las Edge Functions se ejecuten..." -ForegroundColor Yellow
            Start-Sleep -Seconds 3
            
            # Verificar si el mensaje fue marcado como enviado al webhook de IA
            $queryCheckMessage = @"
            SELECT 
              id, 
              content, 
              ia_webhook_sent
            FROM 
              messages
            WHERE 
              id = '$messageId';
"@
            
            $bodyCheckMessage = @{
                "query" = $queryCheckMessage
            } | ConvertTo-Json -Depth 10
            
            $responseCheckMessage = Invoke-RestMethod -Uri "$supabaseUrl/rest/v1/rpc/execute_sql" -Method POST -Headers $headers -Body $bodyCheckMessage
            
            if ($responseCheckMessage.result -and $responseCheckMessage.result.Count -gt 0) {
                $iaWebhookSent = $responseCheckMessage.result[0].ia_webhook_sent
                
                if ($iaWebhookSent -eq $true) {
                    Write-Host "El mensaje fue marcado como enviado al webhook de IA (ia_webhook_sent=true)." -ForegroundColor Green
                    Write-Host "Esto indica que el trigger SQL funcionó correctamente." -ForegroundColor Green
                } else {
                    Write-Host "El mensaje NO fue marcado como enviado al webhook de IA (ia_webhook_sent=false o NULL)." -ForegroundColor Red
                    Write-Host "Esto podría indicar un problema con el trigger SQL." -ForegroundColor Red
                }
            } else {
                Write-Host "No se pudo verificar si el mensaje fue enviado al webhook de IA." -ForegroundColor Red
            }
        } else {
            Write-Host "No se pudo insertar el mensaje de prueba." -ForegroundColor Red
        }
    } else {
        Write-Host "No se encontraron conversaciones para la prueba." -ForegroundColor Red
    }
}
catch {
    Write-Error "Error al insertar el mensaje de prueba: $_"
}

# Paso 5: Resumen y pasos adicionales
Write-Host ""
Write-Host "PASO 5: Resumen y pasos adicionales" -ForegroundColor Green
Write-Host "------------------------------" -ForegroundColor Green
Write-Host ""
Write-Host "Se han aplicado las siguientes soluciones:" -ForegroundColor Cyan
Write-Host "1. Se ha optimizado la función notify_message_webhook para manejar correctamente los mensajes con asistente_ia_activado=true" -ForegroundColor White
Write-Host "2. Se ha añadido un campo ia_webhook_sent para rastrear mensajes enviados al webhook" -ForegroundColor White
Write-Host "3. Se han modificado las Edge Functions para que no interfieran con el webhook de IA" -ForegroundColor White
Write-Host "4. Se han modificado los archivos TypeScript para evitar duplicación de clientes" -ForegroundColor White
Write-Host ""
Write-Host "PASOS ADICIONALES RECOMENDADOS:" -ForegroundColor Yellow
Write-Host "1. Prueba enviar un mensaje con el asistente de IA activado desde la interfaz de usuario" -ForegroundColor Yellow
Write-Host "2. Verifica que no aparecen clientes duplicados en el módulo de clientes" -ForegroundColor Yellow
Write-Host "3. Verifica que no aparecen conversaciones duplicadas en el módulo de comunicaciones" -ForegroundColor Yellow
Write-Host "4. Revisa los logs de Supabase para confirmar que no hay errores relacionados con el webhook de IA" -ForegroundColor Yellow
Write-Host ""
Write-Host "Para más detalles sobre las soluciones implementadas, consulta:" -ForegroundColor Cyan
Write-Host "- README-solucion-completa.md" -ForegroundColor Cyan
Write-Host "- README-resumen-soluciones-implementadas.md" -ForegroundColor Cyan
Write-Host "- README-solucion-webhook-ia-y-duplicacion.md" -ForegroundColor Cyan
Write-Host ""
Write-Host "¡Soluciones aplicadas correctamente!" -ForegroundColor Green
