#!/bin/bash
# Script para verificar si la solución ha sido implementada correctamente

# Colores para la salida
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== Verificación de la Solución al Error 'Missing script: start' ===${NC}"
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
    
    # Verificar si hay contenedores en ejecución
    running_containers=$(docker ps | grep -i probolsas)
    if [ -n "$running_containers" ]; then
        echo -e "\n${GREEN}✓ Hay contenedores en ejecución${NC}"
        echo "$running_containers"
        
        # Obtener el ID del contenedor en ejecución
        container_id=$(echo "$running_containers" | head -1 | awk '{print $1}')
        
        # Verificar los logs del contenedor
        echo -e "\n${YELLOW}Verificando los logs del contenedor...${NC}"
        logs=$(docker logs --tail 20 $container_id)
        
        # Verificar si hay errores de "Missing script: start" en los logs
        if echo "$logs" | grep -q "Missing script: \"start\""; then
            echo -e "${RED}✗ El contenedor sigue mostrando el error 'Missing script: start'${NC}"
            echo -e "${YELLOW}La solución no ha sido implementada correctamente${NC}"
            
            # Verificar la imagen que está usando el contenedor
            image=$(docker inspect --format='{{.Config.Image}}' $container_id)
            echo -e "\n${YELLOW}El contenedor está usando la imagen: ${image}${NC}"
            
            if [ "$image" = "pedroconda/crm-probolsas:fixed" ]; then
                echo -e "${YELLOW}El contenedor está usando la imagen corregida, pero sigue fallando${NC}"
                echo -e "${YELLOW}Verifica que el Dockerfile.fixed esté correctamente configurado${NC}"
            else
                echo -e "${YELLOW}El contenedor NO está usando la imagen corregida${NC}"
                echo -e "${YELLOW}Debes actualizar el stack en Portainer para usar la imagen 'pedroconda/crm-probolsas:fixed'${NC}"
            fi
            
            # Verificar el comando que está usando el contenedor
            cmd=$(docker inspect --format='{{.Config.Cmd}}' $container_id)
            echo -e "\n${YELLOW}El contenedor está usando el comando: ${cmd}${NC}"
            
            if echo "$cmd" | grep -q "node server.js"; then
                echo -e "${YELLOW}El contenedor está usando el comando correcto, pero sigue fallando${NC}"
                echo -e "${YELLOW}Verifica que el archivo server.js exista dentro del contenedor${NC}"
                
                # Verificar si el archivo server.js existe dentro del contenedor
                if docker exec $container_id ls -la | grep -q "server.js"; then
                    echo -e "${GREEN}✓ El archivo server.js existe dentro del contenedor${NC}"
                else
                    echo -e "${RED}✗ El archivo server.js NO existe dentro del contenedor${NC}"
                    echo -e "${YELLOW}Debes asegurarte de que el archivo server.js esté incluido en la imagen${NC}"
                fi
            else
                echo -e "${YELLOW}El contenedor NO está usando el comando correcto${NC}"
                echo -e "${YELLOW}Debes actualizar el stack en Portainer para usar el comando 'node server.js'${NC}"
            fi
        else
            echo -e "${GREEN}✓ No se encontraron errores de 'Missing script: start' en los logs${NC}"
            echo -e "${GREEN}✓ La solución ha sido implementada correctamente${NC}"
            
            # Verificar si el contenedor está respondiendo
            echo -e "\n${YELLOW}Verificando si el contenedor está respondiendo...${NC}"
            if docker exec -it $container_id curl -s http://localhost:80 > /dev/null 2>&1; then
                echo -e "${GREEN}✓ El contenedor está respondiendo en el puerto 80${NC}"
                echo -e "${GREEN}✓ La aplicación debería estar accesible en https://ippcrm.probolsas.co${NC}"
            else
                echo -e "${RED}✗ El contenedor no está respondiendo en el puerto 80${NC}"
                echo -e "${YELLOW}Verifica que la aplicación esté escuchando en el puerto correcto${NC}"
            fi
        fi
    else
        echo -e "\n${RED}✗ No hay contenedores en ejecución${NC}"
        
        # Obtener el ID del último contenedor detenido
        container_id=$(echo "$containers" | head -1 | awk '{print $1}')
        
        # Verificar los logs del contenedor detenido
        echo -e "\n${YELLOW}Verificando los logs del último contenedor detenido...${NC}"
        logs=$(docker logs --tail 20 $container_id)
        
        # Verificar si hay errores de "Missing script: start" en los logs
        if echo "$logs" | grep -q "Missing script: \"start\""; then
            echo -e "${RED}✗ El contenedor muestra el error 'Missing script: start'${NC}"
            echo -e "${YELLOW}La solución no ha sido implementada correctamente${NC}"
            
            # Verificar la imagen que está usando el contenedor
            image=$(docker inspect --format='{{.Config.Image}}' $container_id)
            echo -e "\n${YELLOW}El contenedor está usando la imagen: ${image}${NC}"
            
            if [ "$image" = "pedroconda/crm-probolsas:fixed" ]; then
                echo -e "${YELLOW}El contenedor está usando la imagen corregida, pero sigue fallando${NC}"
                echo -e "${YELLOW}Verifica que el Dockerfile.fixed esté correctamente configurado${NC}"
            else
                echo -e "${YELLOW}El contenedor NO está usando la imagen corregida${NC}"
                echo -e "${YELLOW}Debes actualizar el stack en Portainer para usar la imagen 'pedroconda/crm-probolsas:fixed'${NC}"
            fi
        else
            echo -e "${YELLOW}No se encontraron errores de 'Missing script: start' en los logs, pero el contenedor está detenido${NC}"
            echo -e "${YELLOW}Verifica si hay otros errores en los logs${NC}"
            echo -e "\n${YELLOW}Últimas 20 líneas de logs:${NC}"
            echo "$logs"
        fi
        
        # Sugerir reiniciar el contenedor
        echo -e "\n${YELLOW}Sugerencia: Intenta reiniciar el contenedor${NC}"
        echo -e "docker restart $container_id"
    fi
else
    echo -e "${RED}✗ No se encontraron contenedores relacionados con crm-probolsas${NC}"
    echo -e "${YELLOW}Verifica que el stack esté desplegado en Portainer${NC}"
fi

# Verificar la red probolsas
echo -e "\n${YELLOW}Verificando la red probolsas...${NC}"
if docker network ls | grep -q probolsas; then
    echo -e "${GREEN}✓ La red probolsas existe${NC}"
else
    echo -e "${RED}✗ La red probolsas no existe${NC}"
    echo -e "${YELLOW}Debes crear la red probolsas:${NC}"
    echo -e "docker network create --driver overlay probolsas"
fi

# Verificar Traefik
echo -e "\n${YELLOW}Verificando Traefik...${NC}"
traefik_container=$(docker ps | grep traefik | awk '{print $1}')
if [ -n "$traefik_container" ]; then
    echo -e "${GREEN}✓ Traefik está en ejecución con ID: ${traefik_container}${NC}"
else
    echo -e "${RED}✗ Traefik no está en ejecución${NC}"
    echo -e "${YELLOW}Verifica que Traefik esté desplegado correctamente${NC}"
fi

# Resumen y recomendaciones
echo -e "\n${BLUE}=== Resumen y Recomendaciones ===${NC}"
if [ -n "$running_containers" ]; then
    echo -e "${GREEN}✓ Hay contenedores en ejecución${NC}"
    echo -e "${YELLOW}Si la aplicación no es accesible en https://ippcrm.probolsas.co, verifica:${NC}"
    echo -e "1. La configuración de Traefik"
    echo -e "2. La configuración DNS del dominio ippcrm.probolsas.co"
    echo -e "3. Los firewalls y reglas de seguridad del servidor"
else
    echo -e "${RED}✗ No hay contenedores en ejecución${NC}"
    echo -e "${YELLOW}Recomendaciones:${NC}"
    echo -e "1. Verifica que la solución haya sido implementada correctamente"
    echo -e "2. Actualiza el stack en Portainer para usar la imagen 'pedroconda/crm-probolsas:fixed'"
    echo -e "3. O añade la línea 'command: node server.js' en la configuración del stack"
    echo -e "4. Asegúrate de que la red probolsas exista"
    echo -e "5. Verifica que Traefik esté desplegado correctamente"
fi

echo -e "\n${BLUE}=== Fin de la Verificación ===${NC}"
