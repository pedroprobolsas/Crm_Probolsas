#!/bin/bash

# Script para construir y subir la imagen a Docker Hub

# Asegurarse de que el script se detenga si hay algún error
set -e

echo "=== Construyendo la imagen Docker ==="
docker build -t pedroconda/crm-probolsas:latest .

echo "=== Subiendo la imagen a Docker Hub ==="
echo "Iniciando sesión en Docker Hub..."
docker login

echo "Subiendo imagen..."
docker push pedroconda/crm-probolsas:latest

echo "=== Proceso completado con éxito ==="
echo "La imagen pedroconda/crm-probolsas:latest ha sido construida y subida a Docker Hub."
echo "Ahora puedes actualizar el stack en Portainer."
