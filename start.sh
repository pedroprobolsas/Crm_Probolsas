#!/bin/bash
# Script de inicio para el contenedor

echo "=== Iniciando servidor CRM Probolsas ==="
echo "Fecha y hora: $(date)"
echo "Directorio actual: $(pwd)"

# Verificar si el directorio dist existe
if [ ! -d "./dist" ]; then
  echo "ERROR: El directorio dist/ no existe."
  echo "Contenido del directorio actual:"
  ls -la
  echo "Asegúrate de que el directorio dist/ esté presente y contenga los archivos compilados."
  exit 1
fi

# Verificar si hay archivos en el directorio dist
if [ -z "$(ls -A ./dist)" ]; then
  echo "ERROR: El directorio dist/ está vacío."
  echo "Asegúrate de compilar la aplicación antes de iniciar el servidor."
  exit 1
fi

# Verificar si existe el archivo server.js
if [ ! -f "./server.js" ]; then
  echo "ERROR: El archivo server.js no existe."
  echo "Contenido del directorio actual:"
  ls -la
  echo "Asegúrate de que el archivo server.js esté presente."
  exit 1
fi

# Verificar si existe el archivo package.json
if [ ! -f "./package.json" ]; then
  echo "ERROR: El archivo package.json no existe."
  echo "Contenido del directorio actual:"
  ls -la
  echo "Asegúrate de que el archivo package.json esté presente."
  exit 1
fi

# Mostrar información de diagnóstico
echo "Contenido del directorio actual:"
ls -la

echo "Contenido del directorio dist:"
ls -la ./dist

echo "Verificando dependencias instaladas:"
npm list --depth=0

echo "=== Iniciando servidor... ==="
node server.js
