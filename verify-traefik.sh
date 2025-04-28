#!/bin/bash
# Script para verificar la configuración de Traefik

echo "=== Verificación de Traefik para CRM Probolsas ==="
echo "Fecha y hora: $(date)"

# Verificar si Traefik está en ejecución
echo -e "\nVerificando si Traefik está en ejecución:"
docker ps | grep traefik

# Verificar la configuración de Traefik
echo -e "\nVerificando la configuración de Traefik:"
docker exec $(docker ps | grep traefik | awk '{print $1}') traefik version 2>/dev/null || echo "No se pudo ejecutar el comando traefik version"

# Verificar los routers de Traefik
echo -e "\nVerificando los routers de Traefik:"
docker exec $(docker ps | grep traefik | awk '{print $1}') traefik healthcheck 2>/dev/null || echo "No se pudo ejecutar el comando traefik healthcheck"

# Verificar la conectividad a la aplicación
echo -e "\nVerificando la conectividad a la aplicación:"
echo "Desde el host:"
curl -v -H "Host: ippcrm.probolsas.co" http://localhost:3000 || echo "No se pudo conectar a la aplicación en el puerto 3000"

# Verificar la conectividad a través de Traefik
echo -e "\nVerificando la conectividad a través de Traefik:"
curl -v -H "Host: ippcrm.probolsas.co" http://localhost:80 || echo "No se pudo conectar a Traefik en el puerto 80"
curl -v -H "Host: ippcrm.probolsas.co" https://localhost:443 --insecure || echo "No se pudo conectar a Traefik en el puerto 443"

# Verificar la resolución DNS
echo -e "\nVerificando la resolución DNS:"
nslookup ippcrm.probolsas.co || echo "No se pudo resolver el dominio ippcrm.probolsas.co"

echo -e "\n=== Verificación Completa ==="
