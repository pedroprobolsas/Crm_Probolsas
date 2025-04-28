#!/bin/bash
# Script para verificar si el servidor está funcionando correctamente

echo "=== Verificación del Servidor CRM Probolsas ==="
echo "Fecha y hora: $(date)"
echo "Directorio actual: $(pwd)"
echo "Contenido del directorio:"
ls -la

echo -e "\nVerificando si el proceso node está en ejecución:"
ps aux | grep node

echo -e "\nVerificando si el puerto 3000 está en uso:"
netstat -tuln | grep 3000

echo -e "\nVerificando si el servidor responde localmente:"
curl -v http://localhost:3000

echo -e "\nVerificando conexión a Internet:"
curl -v https://google.com

echo -e "\n=== Verificación Completa ==="
