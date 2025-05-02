#!/bin/bash
# Script para diagnosticar y resolver el problema de "Missing script: start"

echo "=== Diagnóstico del problema 'Missing script: start' ==="
echo "Fecha y hora: $(date)"
echo "Directorio actual: $(pwd)"

# Verificar si el archivo package.json existe
if [ -f "package.json" ]; then
    echo -e "\n✅ El archivo package.json SÍ existe en el directorio actual."
    
    # Verificar si el script "start" está definido en package.json
    if grep -q '"start":' package.json; then
        echo "✅ El script 'start' SÍ está definido en package.json."
        echo -e "\nDefinición del script 'start' en package.json:"
        grep -A 1 '"start":' package.json
    else
        echo "❌ El script 'start' NO está definido en package.json."
        echo -e "\nContenido de package.json:"
        cat package.json
    fi
else
    echo -e "\n❌ El archivo package.json NO existe en el directorio actual."
    echo -e "\nContenido del directorio actual:"
    ls -la
    
    # Buscar el archivo package.json en subdirectorios
    echo -e "\nBuscando package.json en subdirectorios:"
    find . -name "package.json" -type f | head -n 5
fi

# Verificar la instalación de Node.js y npm
echo -e "\n=== Información de Node.js y npm ==="
echo "Versión de Node.js: $(node --version 2>/dev/null || echo 'No instalado')"
echo "Versión de npm: $(npm --version 2>/dev/null || echo 'No instalado')"

# Verificar si el archivo server.js existe
if [ -f "server.js" ]; then
    echo -e "\n✅ El archivo server.js SÍ existe en el directorio actual."
else
    echo -e "\n❌ El archivo server.js NO existe en el directorio actual."
    echo -e "\nBuscando server.js en subdirectorios:"
    find . -name "server.js" -type f | head -n 5
fi

# Verificar si el directorio node_modules existe
if [ -d "node_modules" ]; then
    echo -e "\n✅ El directorio node_modules SÍ existe en el directorio actual."
    echo "Número de paquetes instalados: $(ls -1 node_modules | wc -l)"
else
    echo -e "\n❌ El directorio node_modules NO existe en el directorio actual."
    echo "Es posible que necesites ejecutar 'npm install' primero."
fi

echo -e "\n=== Soluciones recomendadas ==="

if [ ! -f "package.json" ]; then
    echo "1. Navega al directorio que contiene el archivo package.json:"
    find_result=$(find . -name "package.json" -type f | head -n 1)
    if [ -n "$find_result" ]; then
        package_dir=$(dirname "$find_result")
        echo "   cd $package_dir"
    else
        echo "   No se encontró ningún archivo package.json. Asegúrate de estar en el directorio correcto del proyecto."
    fi
elif [ ! -d "node_modules" ]; then
    echo "1. Instala las dependencias del proyecto:"
    echo "   npm install"
fi

echo "2. Ejecuta la aplicación directamente con Node.js en lugar de usar npm start:"
if [ -f "server.js" ]; then
    echo "   node server.js"
else
    find_server=$(find . -name "server.js" -type f | head -n 1)
    if [ -n "$find_server" ]; then
        echo "   node $find_server"
    else
        echo "   No se encontró el archivo server.js. Verifica que el archivo exista."
    fi
fi

echo "3. Si estás usando Docker/Portainer, no necesitas ejecutar 'npm start' manualmente."
echo "   El contenedor debería iniciar la aplicación automáticamente según la configuración."

echo -e "\n=== Fin del diagnóstico ==="
