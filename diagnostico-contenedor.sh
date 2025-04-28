#!/bin/bash
# Script para diagnosticar problemas con el contenedor de CRM Probolsas

echo "=== Diagnóstico del Contenedor CRM Probolsas ==="
echo "Fecha y hora: $(date)"

# Colores para la salida
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Verificar si Docker está en ejecución
echo -e "\n${YELLOW}Verificando si Docker está en ejecución:${NC}"
if systemctl is-active --quiet docker; then
    echo -e "${GREEN}✓ Docker está en ejecución${NC}"
else
    echo -e "${RED}✗ Docker no está en ejecución${NC}"
    echo -e "Intenta iniciar Docker con: ${YELLOW}systemctl start docker${NC}"
    exit 1
fi

# Verificar si hay contenedores relacionados con crm-probolsas
echo -e "\n${YELLOW}Buscando contenedores relacionados con crm-probolsas:${NC}"
CONTAINERS=$(docker ps -a | grep -i probolsas)
if [ -n "$CONTAINERS" ]; then
    echo -e "${GREEN}Se encontraron contenedores:${NC}"
    echo "$CONTAINERS"
    
    # Obtener el ID del último contenedor
    CONTAINER_ID=$(echo "$CONTAINERS" | head -1 | awk '{print $1}')
    echo -e "\n${YELLOW}Analizando el contenedor $CONTAINER_ID:${NC}"
    
    # Verificar el estado del contenedor
    STATUS=$(docker inspect --format='{{.State.Status}}' $CONTAINER_ID)
    echo -e "Estado: ${YELLOW}$STATUS${NC}"
    
    # Si el contenedor está detenido, verificar por qué
    if [ "$STATUS" != "running" ]; then
        echo -e "\n${YELLOW}El contenedor no está en ejecución. Verificando la razón:${NC}"
        EXIT_CODE=$(docker inspect --format='{{.State.ExitCode}}' $CONTAINER_ID)
        echo -e "Código de salida: ${RED}$EXIT_CODE${NC}"
        
        # Mostrar los logs del contenedor
        echo -e "\n${YELLOW}Últimas líneas de log del contenedor:${NC}"
        docker logs --tail 50 $CONTAINER_ID
        
        # Verificar si hay errores específicos
        if docker logs $CONTAINER_ID 2>&1 | grep -i "error"; then
            echo -e "\n${RED}Se encontraron errores en los logs${NC}"
        fi
        
        # Verificar si el contenedor se reinició muchas veces
        RESTARTS=$(docker inspect --format='{{.RestartCount}}' $CONTAINER_ID 2>/dev/null || echo "N/A")
        echo -e "\nNúmero de reinicios: ${YELLOW}$RESTARTS${NC}"
    else
        # Si el contenedor está en ejecución, verificar los procesos
        echo -e "\n${YELLOW}Procesos en ejecución dentro del contenedor:${NC}"
        docker exec -it $CONTAINER_ID ps aux || echo -e "${RED}No se pudo ejecutar ps dentro del contenedor${NC}"
        
        # Verificar los puertos en uso
        echo -e "\n${YELLOW}Puertos en uso dentro del contenedor:${NC}"
        docker exec -it $CONTAINER_ID netstat -tuln || echo -e "${RED}No se pudo ejecutar netstat dentro del contenedor${NC}"
        
        # Verificar si el servidor está respondiendo
        echo -e "\n${YELLOW}Verificando si el servidor responde dentro del contenedor:${NC}"
        docker exec -it $CONTAINER_ID curl -s http://localhost:3000 > /dev/null
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}✓ El servidor está respondiendo en el puerto 3000${NC}"
        else
            echo -e "${RED}✗ El servidor no está respondiendo en el puerto 3000${NC}"
        fi
    fi
else
    echo -e "${RED}No se encontraron contenedores relacionados con crm-probolsas${NC}"
fi

# Verificar la red probolsas
echo -e "\n${YELLOW}Verificando la red probolsas:${NC}"
if docker network ls | grep -q probolsas; then
    echo -e "${GREEN}✓ La red probolsas existe${NC}"
    
    # Verificar los contenedores conectados a la red
    echo -e "\n${YELLOW}Contenedores conectados a la red probolsas:${NC}"
    docker network inspect probolsas -f '{{range .Containers}}{{.Name}} {{end}}' | tr ' ' '\n' | grep .
else
    echo -e "${RED}✗ La red probolsas no existe${NC}"
fi

# Verificar el stack en Portainer
echo -e "\n${YELLOW}Para verificar el stack en Portainer:${NC}"
echo -e "1. Accede a Portainer en https://ippportainer.probolsas.co"
echo -e "2. Ve a Stacks > probolsas_crm_v2"
echo -e "3. Verifica el estado del stack y los logs"

# Verificar Traefik
echo -e "\n${YELLOW}Verificando Traefik:${NC}"
TRAEFIK_CONTAINER=$(docker ps | grep traefik | awk '{print $1}')
if [ -n "$TRAEFIK_CONTAINER" ]; then
    echo -e "${GREEN}✓ Traefik está en ejecución${NC}"
    
    # Verificar la configuración de Traefik
    echo -e "\n${YELLOW}Verificando la configuración de Traefik para ippcrm.probolsas.co:${NC}"
    docker exec -it $TRAEFIK_CONTAINER traefik version 2>/dev/null || echo -e "${RED}No se pudo ejecutar traefik version${NC}"
else
    echo -e "${RED}✗ Traefik no está en ejecución${NC}"
fi

# Recomendaciones
echo -e "\n${YELLOW}Recomendaciones:${NC}"
echo -e "1. Verifica que el archivo dist/ exista y contenga los archivos de la aplicación"
echo -e "2. Asegúrate de que el archivo server.js esté presente y sea correcto"
echo -e "3. Verifica que las variables de entorno en .env.production sean correctas"
echo -e "4. Intenta reconstruir la imagen con: docker-compose build --no-cache"
echo -e "5. Reinicia el stack en Portainer"

echo -e "\n${YELLOW}=== Diagnóstico Completo ===${NC}"
