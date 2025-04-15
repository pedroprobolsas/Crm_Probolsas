#!/bin/bash
# Script para probar manualmente el webhook para clientes usando curl

# Colores para la salida
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# URL del webhook para clientes en producción
WEBHOOK_URL="https://ippwebhookn8n.probolsas.co/webhook/d2d918c0-7132-43fe-9e8c-e07b033f2e6b"

# Payload de prueba
PAYLOAD='{
  "id": "00000000-0000-0000-0000-000000000001",
  "conversation_id": "00000000-0000-0000-0000-000000000002",
  "content": "Mensaje de prueba manual",
  "phone": "573001234567",
  "sender": "client",
  "sender_id": "00000000-0000-0000-0000-000000000003",
  "type": "text",
  "status": "sent",
  "created_at": "2025-04-14T20:55:00.000Z",
  "client": {
    "id": "00000000-0000-0000-0000-000000000003",
    "name": "Cliente de Prueba",
    "email": "prueba@ejemplo.com",
    "phone": "573001234567",
    "created_at": "2025-02-10T15:22:00Z"
  }
}'

echo -e "${YELLOW}Probando webhook para clientes en: ${WEBHOOK_URL}${NC}"
echo -e "${YELLOW}Payload:${NC}"
echo $PAYLOAD | jq '.'

echo -e "${YELLOW}Enviando solicitud...${NC}"

# Enviar la solicitud con curl y guardar la respuesta
RESPONSE=$(curl -s -w "\n%{http_code}" -X POST -H "Content-Type: application/json" -d "$PAYLOAD" $WEBHOOK_URL)

# Extraer el código de estado HTTP
HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | sed '$ d')

echo -e "${YELLOW}Código de respuesta: ${NC}$HTTP_CODE"
echo -e "${YELLOW}Respuesta:${NC}"
echo $BODY | jq '.' 2>/dev/null || echo $BODY

# Verificar el código de respuesta
if [[ $HTTP_CODE -ge 200 && $HTTP_CODE -lt 300 ]]; then
  echo -e "${GREEN}La solicitud fue exitosa.${NC}"
else
  echo -e "${RED}La solicitud falló con código $HTTP_CODE.${NC}"
fi

echo -e "${YELLOW}Prueba completada.${NC}"
