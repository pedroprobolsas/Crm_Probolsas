#!/bin/bash
# Script para descargar y ejecutar la solución al problema "Missing script: start"

echo "=== Descargando y ejecutando la solución al problema 'Missing script: start' ==="
echo "Fecha y hora: $(date)"

# Verificar si curl está instalado
if ! command -v curl &> /dev/null; then
    echo "curl no está instalado. Intentando instalar..."
    if command -v apt-get &> /dev/null; then
        sudo apt-get update && sudo apt-get install -y curl
    elif command -v yum &> /dev/null; then
        sudo yum install -y curl
    else
        echo "No se pudo instalar curl. Por favor, instálalo manualmente."
        exit 1
    fi
fi

# Descargar los scripts de solución
echo "Descargando scripts de solución..."

# URLs de los scripts (ajusta estas URLs a donde estén alojados los scripts)
REPO_URL="https://raw.githubusercontent.com/pedroprobolsas/Crm_Probolsas/main"

# Descargar los scripts
curl -s -o diagnostico-npm-start.sh "${REPO_URL}/diagnostico-npm-start.sh"
curl -s -o iniciar-app.sh "${REPO_URL}/iniciar-app.sh"
curl -s -o solucionar-npm-start.sh "${REPO_URL}/solucionar-npm-start.sh"

# Dar permisos de ejecución a los scripts
chmod +x diagnostico-npm-start.sh iniciar-app.sh solucionar-npm-start.sh

# Ejecutar el script de solución
echo "Ejecutando el script de solución..."
./solucionar-npm-start.sh

# Si el script de solución falla, ofrecer alternativas
if [ $? -ne 0 ]; then
    echo "El script de solución falló. Intentando alternativas..."
    
    # Intentar ejecutar la aplicación directamente
    echo "Intentando ejecutar la aplicación directamente..."
    if [ -f "server.js" ]; then
        node server.js
    else
        # Buscar server.js en subdirectorios
        server_js_path=$(find . -name "server.js" -type f | head -1)
        if [ -n "$server_js_path" ]; then
            echo "Encontrado server.js en: $server_js_path"
            node "$server_js_path"
        else
            echo "No se encontró server.js. No se puede ejecutar la aplicación."
            exit 1
        fi
    fi
fi
