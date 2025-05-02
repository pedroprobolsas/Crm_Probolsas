#!/bin/bash
# Script para construir y subir la imagen Docker corregida

# Colores para la salida
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== Construyendo y subiendo imagen Docker corregida ===${NC}"
echo "Fecha y hora: $(date)"

# Verificar si Docker está instalado
if ! command -v docker &> /dev/null; then
    echo -e "${RED}Docker no está instalado. Por favor, instala Docker primero.${NC}"
    exit 1
fi

# Verificar si el usuario está autenticado en Docker Hub
echo -e "\n${YELLOW}Verificando autenticación en Docker Hub...${NC}"
if ! docker info | grep -q "Username"; then
    echo -e "${YELLOW}No estás autenticado en Docker Hub. Iniciando sesión...${NC}"
    echo -e "${YELLOW}Por favor, ingresa tus credenciales de Docker Hub:${NC}"
    docker login
    
    if [ $? -ne 0 ]; then
        echo -e "${RED}Error al iniciar sesión en Docker Hub. Abortando.${NC}"
        exit 1
    fi
fi

# Construir la imagen Docker
echo -e "\n${YELLOW}Construyendo la imagen Docker...${NC}"
docker build -t pedroconda/crm-probolsas:fixed -f Dockerfile.fixed .

if [ $? -ne 0 ]; then
    echo -e "${RED}Error al construir la imagen Docker. Abortando.${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Imagen Docker construida correctamente${NC}"

# Subir la imagen a Docker Hub
echo -e "\n${YELLOW}Subiendo la imagen a Docker Hub...${NC}"
docker push pedroconda/crm-probolsas:fixed

if [ $? -ne 0 ]; then
    echo -e "${RED}Error al subir la imagen a Docker Hub. Abortando.${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Imagen Docker subida correctamente a Docker Hub${NC}"

# Instrucciones para actualizar el stack en Portainer
echo -e "\n${BLUE}=== Instrucciones para actualizar el stack en Portainer ===${NC}"
echo -e "1. Accede a Portainer en ${YELLOW}https://ippportainer.probolsas.co${NC}"
echo -e "2. Ve a ${YELLOW}Stacks${NC} en el menú lateral"
echo -e "3. Encuentra tu stack (probablemente ${YELLOW}probolsas_crm_v2${NC})"
echo -e "4. Haz clic en el stack para ver sus detalles"
echo -e "5. Busca la opción ${YELLOW}Editor${NC} o similar que te permita editar la configuración del stack"
echo -e "6. Cambia la línea de la imagen de:"
echo -e "   ${RED}image: pedroconda/crm-probolsas:latest${NC}"
echo -e "   a:"
echo -e "   ${GREEN}image: pedroconda/crm-probolsas:fixed${NC}"
echo -e "7. Haz clic en ${YELLOW}Update the stack${NC} o similar para aplicar los cambios"

echo -e "\n${BLUE}=== Fin del proceso ===${NC}"
