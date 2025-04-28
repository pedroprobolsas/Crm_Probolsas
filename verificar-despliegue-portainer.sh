#!/bin/bash
# Script para verificar el estado del despliegue en Portainer

echo "=== Verificación del Despliegue en Portainer para CRM Probolsas ==="
echo "Fecha y hora: $(date)"

# Colores para la salida
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Verificar si el contenedor está en ejecución
echo -e "\n${YELLOW}Verificando si el contenedor está en ejecución:${NC}"
CONTAINER_ID=$(docker ps | grep crm-probolsas | awk '{print $1}')
if [ -n "$CONTAINER_ID" ]; then
    echo -e "${GREEN}✓ El contenedor está en ejecución con ID: $CONTAINER_ID${NC}"
else
    echo -e "${RED}✗ No se encontró el contenedor en ejecución${NC}"
    
    # Buscar contenedores detenidos
    echo -e "\n${YELLOW}Buscando contenedores detenidos:${NC}"
    STOPPED_CONTAINERS=$(docker ps -a | grep crm-probolsas)
    if [ -n "$STOPPED_CONTAINERS" ]; then
        echo -e "${RED}Se encontraron contenedores detenidos:${NC}"
        echo "$STOPPED_CONTAINERS"
        
        # Verificar los logs del último contenedor detenido
        STOPPED_CONTAINER=$(echo "$STOPPED_CONTAINERS" | head -1 | awk '{print $1}')
        echo -e "\n${YELLOW}Logs del último contenedor detenido:${NC}"
        docker logs --tail 50 $STOPPED_CONTAINER
    else
        echo -e "${RED}No se encontraron contenedores (ni en ejecución ni detenidos)${NC}"
    fi
    
    echo -e "\n${RED}El despliegue parece haber fallado. Verifica la configuración en Portainer.${NC}"
    exit 1
fi

# Verificar los logs del contenedor
echo -e "\n${YELLOW}Verificando los logs del contenedor (últimas 20 líneas):${NC}"
docker logs --tail 20 $CONTAINER_ID

# Verificar si el servidor está respondiendo
echo -e "\n${YELLOW}Verificando si el servidor está respondiendo:${NC}"
if docker exec -it $CONTAINER_ID curl -s http://localhost:3000 > /dev/null; then
    echo -e "${GREEN}✓ El servidor está respondiendo en el puerto 3000${NC}"
else
    echo -e "${RED}✗ El servidor no está respondiendo en el puerto 3000${NC}"
    echo -e "\n${YELLOW}Verificando procesos en el contenedor:${NC}"
    docker exec -it $CONTAINER_ID ps aux
    echo -e "\n${YELLOW}Verificando puertos en uso en el contenedor:${NC}"
    docker exec -it $CONTAINER_ID netstat -tuln
    echo -e "\n${RED}El servidor no está respondiendo. Verifica los logs para más detalles.${NC}"
fi

# Verificar si Traefik está enrutando correctamente
echo -e "\n${YELLOW}Verificando si Traefik está enrutando correctamente:${NC}"
if curl -s -o /dev/null -w "%{http_code}" -H "Host: ippcrm.probolsas.co" http://localhost:80 | grep -q "200\|301\|302"; then
    echo -e "${GREEN}✓ Traefik está enrutando correctamente en el puerto 80${NC}"
else
    echo -e "${RED}✗ Traefik no está enrutando correctamente en el puerto 80${NC}"
    echo -e "\n${YELLOW}Verificando si Traefik está en ejecución:${NC}"
    docker ps | grep traefik
    echo -e "\n${YELLOW}Verificando la configuración de Traefik:${NC}"
    TRAEFIK_CONTAINER=$(docker ps | grep traefik | awk '{print $1}')
    if [ -n "$TRAEFIK_CONTAINER" ]; then
        docker exec -it $TRAEFIK_CONTAINER traefik version 2>/dev/null || echo "No se pudo ejecutar el comando traefik version"
    else
        echo -e "${RED}No se encontró el contenedor de Traefik en ejecución${NC}"
    fi
    echo -e "\n${RED}Traefik no está enrutando correctamente. Verifica la configuración de Traefik.${NC}"
fi

# Verificar si la aplicación es accesible desde Internet
echo -e "\n${YELLOW}Verificando si la aplicación es accesible desde Internet:${NC}"
echo -e "${YELLOW}Intenta acceder a https://ippcrm.probolsas.co en tu navegador${NC}"
echo -e "${YELLOW}Si la aplicación no es accesible, verifica:${NC}"
echo -e "  - La configuración de DNS para ippcrm.probolsas.co"
echo -e "  - La configuración de Traefik"
echo -e "  - Las reglas de firewall del servidor"

echo -e "\n${YELLOW}=== Verificación Completa ===${NC}"
echo ""
echo "Si todas las verificaciones son exitosas, la aplicación está correctamente desplegada."
echo "Si encuentras algún problema, consulta la sección de Solución de Problemas en instrucciones-verificacion.md"
