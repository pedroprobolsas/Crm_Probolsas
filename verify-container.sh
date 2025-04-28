#!/bin/bash
# Script para verificar el estado del contenedor en Portainer

echo "=== Verificación del Contenedor CRM Probolsas ==="
echo "Fecha y hora: $(date)"

# Verificar si el contenedor está en ejecución
echo -e "\nVerificando si el contenedor está en ejecución:"
docker ps | grep crm-probolsas

# Verificar los logs del contenedor
echo -e "\nVerificando los logs del contenedor (últimas 50 líneas):"
CONTAINER_ID=$(docker ps | grep crm-probolsas | awk '{print $1}')
if [ -n "$CONTAINER_ID" ]; then
    docker logs --tail 50 $CONTAINER_ID
else
    echo "No se encontró el contenedor en ejecución"
    
    # Buscar contenedores detenidos
    echo -e "\nBuscando contenedores detenidos:"
    docker ps -a | grep crm-probolsas
    
    # Verificar los logs del último contenedor detenido
    STOPPED_CONTAINER=$(docker ps -a | grep crm-probolsas | head -1 | awk '{print $1}')
    if [ -n "$STOPPED_CONTAINER" ]; then
        echo -e "\nLogs del último contenedor detenido:"
        docker logs --tail 50 $STOPPED_CONTAINER
    fi
fi

# Verificar la información del contenedor
echo -e "\nVerificando la información del contenedor:"
if [ -n "$CONTAINER_ID" ]; then
    docker inspect $CONTAINER_ID
else
    echo "No se encontró el contenedor en ejecución"
fi

# Verificar el uso de recursos del contenedor
echo -e "\nVerificando el uso de recursos del contenedor:"
if [ -n "$CONTAINER_ID" ]; then
    docker stats --no-stream $CONTAINER_ID
else
    echo "No se encontró el contenedor en ejecución"
fi

# Verificar la red del contenedor
echo -e "\nVerificando la red del contenedor:"
if [ -n "$CONTAINER_ID" ]; then
    docker network inspect probolsas
else
    echo "No se encontró el contenedor en ejecución"
fi

echo -e "\n=== Verificación Completa ==="
