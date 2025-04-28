#!/bin/bash
# Script de inicio para la aplicación CRM Probolsas

echo "Iniciando servidor CRM Probolsas..."
echo "Fecha y hora: $(date)"
echo "Directorio actual: $(pwd)"
echo "Contenido del directorio:"
ls -la

echo "Verificando existencia de server.js:"
if [ -f "server.js" ]; then
    echo "server.js encontrado, iniciando aplicación..."
    node server.js
else
    echo "ERROR: server.js no encontrado!"
    echo "Contenido del directorio:"
    ls -la
    exit 1
fi
