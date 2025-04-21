#!/bin/bash
# Script para verificar el despliegue de CRM Probolsas en Portainer

# Colores para la salida
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}=== Verificación de Despliegue CRM Probolsas ===${NC}"
echo ""

# Verificar que el dominio sea accesible
echo -e "${YELLOW}Verificando acceso al dominio ippcrm.probolsas.co...${NC}"
if curl -s --head https://ippcrm.probolsas.co | grep "200 OK" > /dev/null; then
  echo -e "${GREEN}✓ El dominio es accesible y devuelve un código 200 OK${NC}"
else
  echo -e "${RED}✗ No se puede acceder al dominio o no devuelve un código 200 OK${NC}"
  echo "  Verifica que:"
  echo "  - El dominio esté correctamente configurado en DNS"
  echo "  - Traefik esté funcionando correctamente"
  echo "  - El contenedor de la aplicación esté en ejecución"
fi
echo ""

# Verificar que el certificado SSL sea válido
echo -e "${YELLOW}Verificando certificado SSL...${NC}"
if curl -s --head https://ippcrm.probolsas.co | grep -i "Server: traefik" > /dev/null; then
  echo -e "${GREEN}✓ El certificado SSL está configurado correctamente${NC}"
else
  echo -e "${RED}✗ El certificado SSL no está configurado correctamente${NC}"
  echo "  Verifica que:"
  echo "  - Traefik esté configurado para obtener certificados SSL"
  echo "  - El dominio esté correctamente configurado en Traefik"
fi
echo ""

# Verificar conexión con Supabase
echo -e "${YELLOW}Verificando conexión con Supabase...${NC}"
echo "Esta verificación debe realizarse manualmente:"
echo "1. Accede a la aplicación en https://ippcrm.probolsas.co"
echo "2. Intenta iniciar sesión o realizar alguna operación que requiera conexión con Supabase"
echo "3. Si la operación es exitosa, la conexión con Supabase está funcionando correctamente"
echo ""

# Verificar logs del contenedor
echo -e "${YELLOW}Verificando logs del contenedor...${NC}"
echo "Para verificar los logs del contenedor:"
echo "1. Accede a Portainer en https://ippportainer.probolsas.co"
echo "2. Ve a Stacks > crm-probolsas"
echo "3. Haz clic en el contenedor"
echo "4. Ve a la pestaña Logs"
echo "5. Verifica que no haya errores en los logs"
echo ""

echo -e "${YELLOW}=== Verificación Completa ===${NC}"
echo ""
echo "Si todas las verificaciones son exitosas, la aplicación está correctamente desplegada."
echo "Si encuentras algún problema, consulta la sección de Solución de Problemas en README-despliegue-portainer.md"
