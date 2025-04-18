# Script para verificar que las Edge Functions modificadas están funcionando correctamente

# Configuración
$supabaseUrl = $env:SUPABASE_URL
$supabaseKey = $env:SUPABASE_SERVICE_ROLE_KEY

# Mostrar instrucciones iniciales
Write-Host "VERIFICACIÓN DE EDGE FUNCTIONS PARA WEBHOOK DE IA" -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Este script verificará que las Edge Functions modificadas están funcionando correctamente" -ForegroundColor Yellow
Write-Host "y no interfieren con el webhook de IA." -ForegroundColor Yellow
Write-Host ""
Write-Host "La verificación incluye:" -ForegroundColor Yellow
Write-Host "1. Comprobar que las Edge Functions están activas" -ForegroundColor Yellow
Write-Host "2. Verificar que no hay errores en los logs relacionados con las Edge Functions" -ForegroundColor Yellow
Write-Host "3. Probar el envío de mensajes con el asistente de IA activado" -ForegroundColor Yellow
Write-Host ""
Write-Host "IMPORTANTE: Antes de ejecutar este script, asegúrate de:" -ForegroundColor Red
Write-Host "1. Haber actualizado las Edge Functions con el script update_edge_functions_for_ia_webhook.ps1" -ForegroundColor Red
Write-Host "2. Tener acceso a la consola de Supabase para verificar los logs" -ForegroundColor Red
Write-Host ""
Write-Host "¿Deseas continuar con la verificación? (S/N)" -ForegroundColor Cyan
$confirmation = Read-Host

if ($confirmation -ne "S") {
    Write-Host "Operación cancelada por el usuario." -ForegroundColor Yellow
    exit 0
}

# Paso 1: Verificar que las Edge Functions están activas
Write-Host ""
Write-Host "PASO 1: Verificando que las Edge Functions están activas..." -ForegroundColor Green
Write-Host "------------------------------------------------" -ForegroundColor Green
Write-Host ""
Write-Host "Por favor, sigue estos pasos:" -ForegroundColor Yellow
Write-Host "1. Ve a la sección 'Edge Functions' en la consola de Supabase" -ForegroundColor Yellow
Write-Host "2. Verifica que las funciones 'messages-incoming' y 'messages-outgoing' están activas" -ForegroundColor Yellow
Write-Host "3. Verifica que no hay errores en los logs de las Edge Functions" -ForegroundColor Yellow
Write-Host ""
Write-Host "¿Has verificado que las Edge Functions están activas y sin errores? (S/N)" -ForegroundColor Cyan
$edgeFunctionsActive = Read-Host

if ($edgeFunctionsActive -ne "S") {
    Write-Host "Por favor, verifica las Edge Functions antes de continuar." -ForegroundColor Red
    exit 1
}

# Paso 2: Verificar la configuración del webhook de IA
Write-Host ""
Write-Host "PASO 2: Verificando la configuración del webhook de IA..." -ForegroundColor Green
Write-Host "------------------------------------------------" -ForegroundColor Green

try {
    # Verificar que existe la tabla app_settings y que tiene la configuración del webhook de IA
    $headers = @{
        "apikey" = $supabaseKey
        "Authorization" = "Bearer $supabaseKey"
        "Content-Type" = "application/json"
        "Prefer" = "params=single-object"
    }
    
    $query = @"
    SELECT 
      key, 
      value
    FROM 
      app_settings
    WHERE 
      key LIKE 'webhook_url_ia%';
"@
    
    $body = @{
        "query" = $query
    } | ConvertTo-Json -Depth 10
    
    $response = Invoke-RestMethod -Uri "$supabaseUrl/rest/v1/rpc/execute_sql" -Method POST -Headers $headers -Body $body
    
    if ($response.result -and $response.result.Count -gt 0) {
        Write-Host "Configuración del webhook de IA encontrada:" -ForegroundColor Green
        Write-Host $response.result -ForegroundColor White
    } else {
        Write-Host "No se encontró configuración del webhook de IA. Esto podría causar problemas." -ForegroundColor Red
    }
}
catch {
    Write-Error "Error al verificar la configuración del webhook de IA: $_"
    Write-Host "Continuando con el resto del proceso..." -ForegroundColor Yellow
}

# Paso 3: Insertar un mensaje de prueba con asistente_ia_activado=true
Write-Host ""
Write-Host "PASO 3: Insertando un mensaje de prueba con asistente_ia_activado=true..." -ForegroundColor Green
Write-Host "--------------------------------------------------------" -ForegroundColor Green

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
          'VERIFICACIÓN: Mensaje de prueba para webhook de IA ' || NOW(),
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

# Paso 4: Resumen y pasos adicionales
Write-Host ""
Write-Host "PASO 4: Resumen y pasos adicionales" -ForegroundColor Green
Write-Host "------------------------------" -ForegroundColor Green
Write-Host ""
Write-Host "VERIFICACIÓN COMPLETADA" -ForegroundColor Cyan
Write-Host ""
Write-Host "Para confirmar que todo está funcionando correctamente:" -ForegroundColor Yellow
Write-Host "1. Verifica en los logs de Supabase que no hay errores relacionados con las Edge Functions" -ForegroundColor Yellow
Write-Host "2. Verifica que el mensaje de prueba fue enviado correctamente al webhook de IA" -ForegroundColor Yellow
Write-Host "3. Prueba enviar un mensaje con el asistente de IA activado desde la interfaz de usuario" -ForegroundColor Yellow
Write-Host "4. Verifica que no aparecen clientes duplicados en el módulo de clientes" -ForegroundColor Yellow
Write-Host ""
Write-Host "Si todas estas verificaciones son exitosas, la solución está funcionando correctamente." -ForegroundColor Green
Write-Host ""
Write-Host "Para más detalles sobre las soluciones implementadas, consulta:" -ForegroundColor Cyan
Write-Host "- README-resumen-soluciones-implementadas.md" -ForegroundColor Cyan
Write-Host "- README-solucion-webhook-ia-y-duplicacion.md" -ForegroundColor Cyan
