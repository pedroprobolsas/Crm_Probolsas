#!/bin/bash
# Script para verificar el estado del despliegue en Portainer

# Colores para la salida
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== Verificación del Despliegue en Portainer ===${NC}"
echo "Fecha y hora: $(date)"

# Verificar si Docker está instalado
if ! command -v docker &> /dev/null; then
    echo -e "${RED}Docker no está instalado. Por favor, instala Docker primero.${NC}"
    exit 1
fi

# Verificar si hay contenedores relacionados con crm-probolsas
echo -e "\n${YELLOW}Buscando contenedores relacionados con crm-probolsas...${NC}"
containers=$(docker ps -a | grep -i probolsas)
if [ -n "$containers" ]; then
    echo -e "${GREEN}✓ Se encontraron contenedores relacionados con crm-probolsas${NC}"
    echo "$containers"
    
    # Obtener el ID del contenedor en ejecución
    running_container=$(docker ps | grep -i probolsas | awk '{print $1}')
    if [ -n "$running_container" ]; then
        echo -e "\n${GREEN}✓ El contenedor está en ejecución con ID: ${running_container}${NC}"
        
        # Verificar los logs del contenedor
        echo -e "\n${YELLOW}Últimas 10 líneas de logs del contenedor:${NC}"
        docker logs --tail 10 $running_container
        
        # Verificar si el puerto 80 está expuesto
        echo -e "\n${YELLOW}Verificando si el puerto 80 está expuesto...${NC}"
        port_exposed=$(docker port $running_container | grep 80)
        if [ -n "$port_exposed" ]; then
            echo -e "${GREEN}✓ El puerto 80 está expuesto: ${port_exposed}${NC}"
        else
            echo -e "${RED}✗ El puerto 80 no está expuesto${NC}"
        fi
        
        # Verificar si el contenedor responde
        echo -e "\n${YELLOW}Verificando si el contenedor responde...${NC}"
        if docker exec -it $running_container curl -s http://localhost:80 > /dev/null 2>&1; then
            echo -e "${GREEN}✓ El contenedor responde en el puerto 80${NC}"
        else
            echo -e "${RED}✗ El contenedor no responde en el puerto 80${NC}"
            echo -e "${YELLOW}Esto puede deberse a que el servidor web dentro del contenedor no está escuchando en el puerto 80${NC}"
        fi
    else
        # Obtener el ID del último contenedor detenido
        stopped_container=$(echo "$containers" | head -1 | awk '{print $1}')
        echo -e "\n${RED}✗ No hay contenedores en ejecución${NC}"
        echo -e "${YELLOW}El último contenedor (${stopped_container}) está detenido${NC}"
        
        # Verificar los logs del contenedor detenido
        echo -e "\n${YELLOW}Últimas 10 líneas de logs del contenedor detenido:${NC}"
        docker logs --tail 10 $stopped_container
        
        # Verificar el estado del contenedor
        echo -e "\n${YELLOW}Estado del contenedor:${NC}"
        docker inspect --format='{{.State.Status}}' $stopped_container
        
        # Verificar el código de salida
        exit_code=$(docker inspect --format='{{.State.ExitCode}}' $stopped_container)
        echo -e "Código de salida: ${exit_code}"
        
        # Sugerir reiniciar el contenedor
        echo -e "\n${YELLOW}Sugerencia: Intenta reiniciar el contenedor${NC}"
        echo -e "docker restart $stopped_container"
    fi
else
    echo -e "${RED}✗ No se encontraron contenedores relacionados con crm-probolsas${NC}"
    
    # Verificar si el stack existe en Portainer
    echo -e "\n${YELLOW}No se encontraron contenedores. Verifica en Portainer:${NC}"
    echo -e "1. Accede a Portainer en https://ippportainer.probolsas.co"
    echo -e "2. Ve a 'Stacks' en el menú lateral"
    echo -e "3. Verifica si existe un stack llamado 'probolsas_crm_v2' o similar"
    echo -e "4. Si existe, haz clic en él y verifica su estado"
    echo -e "5. Si no existe, crea uno nuevo siguiendo las instrucciones en INSTRUCCIONES-PORTAINER.md"
fi

# Verificar la red probolsas
echo -e "\n${YELLOW}Verificando la red probolsas...${NC}"
if docker network ls | grep -q probolsas; then
    echo -e "${GREEN}✓ La red probolsas existe${NC}"
    
    # Verificar los contenedores conectados a la red
    echo -e "\n${YELLOW}Contenedores conectados a la red probolsas:${NC}"
    docker network inspect probolsas -f '{{range .Containers}}{{.Name}} {{end}}' | tr ' ' '\n' | grep .
else
    echo -e "${RED}✗ La red probolsas no existe${NC}"
    echo -e "${YELLOW}Sugerencia: Crea la red probolsas${NC}"
    echo -e "docker network create --driver overlay probolsas"
fi

# Verificar Traefik
echo -e "\n${YELLOW}Verificando Traefik...${NC}"
traefik_container=$(docker ps | grep traefik | awk '{print $1}')
if [ -n "$traefik_container" ]; then
    echo -e "${GREEN}✓ Traefik está en ejecución con ID: ${traefik_container}${NC}"
    
    # Verificar los logs de Traefik
    echo -e "\n${YELLOW}Últimas 5 líneas de logs de Traefik:${NC}"
    docker logs --tail 5 $traefik_container
else
    echo -e "${RED}✗ Traefik no está en ejecución${NC}"
    echo -e "${YELLOW}Sugerencia: Verifica el estado de Traefik en Portainer${NC}"
fi

# Verificar acceso a la aplicación
echo -e "\n${YELLOW}Verificando acceso a la aplicación...${NC}"
echo -e "La aplicación debería estar accesible en: ${BLUE}https://ippcrm.probolsas.co${NC}"
echo -e "Intenta acceder a esta URL desde tu navegador"

# Resumen y recomendaciones
echo -e "\n${BLUE}=== Resumen y Recomendaciones ===${NC}"
if [ -n "$running_container" ]; then
    echo -e "${GREEN}✓ El contenedor está en ejecución${NC}"
    echo -e "${YELLOW}Si la aplicación no es accesible en https://ippcrm.probolsas.co, verifica:${NC}"
    echo -e "1. La configuración de Traefik"
    echo -e "2. La configuración DNS del dominio ippcrm.probolsas.co"
    echo -e "3. Los firewalls y reglas de seguridad del servidor"
else
    echo -e "${RED}✗ El contenedor no está en ejecución${NC}"
    echo -e "${YELLOW}Recomendaciones:${NC}"
    echo -e "1. Revisa los logs del contenedor para identificar el problema"
    echo -e "2. Verifica la configuración en docker-compose.yml"
    echo -e "3. Asegúrate de que la red probolsas exista"
    echo -e "4. Intenta redesplegarlo en Portainer"
fi

echo -e "\n${YELLOW}IMPORTANTE: No ejecutes 'npm start' manualmente${NC}"
echo -e "El contenedor ya tiene configurado cómo iniciar la aplicación"
echo -e "Si intentas ejecutar 'npm start' directamente en el VPS, obtendrás el error 'Missing script: start'"
echo -e "porque estás fuera del contexto del contenedor"

echo -e "\n${BLUE}=== Fin de la Verificación ===${NC}"
