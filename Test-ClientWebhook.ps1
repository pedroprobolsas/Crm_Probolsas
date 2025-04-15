# Script para probar manualmente el webhook para clientes usando PowerShell

# URL del webhook para clientes en producción
$WEBHOOK_URL = "https://ippwebhookn8n.probolsas.co/webhook/d2d918c0-7132-43fe-9e8c-e07b033f2e6b"

# Payload de prueba
$PAYLOAD = @{
  id = "00000000-0000-0000-0000-000000000001"
  conversation_id = "00000000-0000-0000-0000-000000000002"
  content = "Mensaje de prueba manual desde PowerShell"
  phone = "573001234567"
  sender = "client"
  sender_id = "00000000-0000-0000-0000-000000000003"
  type = "text"
  status = "sent"
  created_at = "2025-04-14T20:55:00.000Z"
  client = @{
    id = "00000000-0000-0000-0000-000000000003"
    name = "Cliente de Prueba"
    email = "prueba@ejemplo.com"
    phone = "573001234567"
    created_at = "2025-02-10T15:22:00Z"
  }
} | ConvertTo-Json -Depth 10

Write-Host "Probando webhook para clientes en: $WEBHOOK_URL" -ForegroundColor Yellow
Write-Host "Payload:" -ForegroundColor Yellow
Write-Host $PAYLOAD

Write-Host "Enviando solicitud..." -ForegroundColor Yellow

try {
    $Response = Invoke-RestMethod -Uri $WEBHOOK_URL -Method Post -Body $PAYLOAD -ContentType "application/json" -ErrorAction Stop
    
    Write-Host "La solicitud fue exitosa." -ForegroundColor Green
    Write-Host "Respuesta:" -ForegroundColor Yellow
    $Response | ConvertTo-Json -Depth 10
}
catch {
    $StatusCode = $_.Exception.Response.StatusCode.value__
    $StatusDescription = $_.Exception.Response.StatusDescription
    
    Write-Host "La solicitud falló con código $StatusCode: $StatusDescription" -ForegroundColor Red
    
    if ($_.Exception.Response) {
        $Reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
        $ResponseBody = $Reader.ReadToEnd()
        if ($ResponseBody) {
            Write-Host "Detalles de la respuesta:" -ForegroundColor Yellow
            Write-Host $ResponseBody
        }
    }
    else {
        Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host "Prueba completada." -ForegroundColor Yellow
