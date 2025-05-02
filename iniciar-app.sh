#!/bin/bash
# Script para iniciar la aplicación directamente con Node.js

echo "=== Iniciando la aplicación CRM Probolsas ==="
echo "Fecha y hora: $(date)"
echo "Directorio actual: $(pwd)"

# Verificar si el archivo server.js existe
if [ ! -f "server.js" ]; then
    echo "❌ ERROR: El archivo server.js no existe en el directorio actual."
    
    # Buscar el archivo server.js en subdirectorios
    echo -e "\nBuscando server.js en subdirectorios:"
    server_path=$(find . -name "server.js" -type f | head -n 1)
    
    if [ -n "$server_path" ]; then
        echo "✅ Encontrado en: $server_path"
        echo "Cambiando al directorio: $(dirname "$server_path")"
        cd "$(dirname "$server_path")" || exit 1
    else
        echo "❌ No se encontró el archivo server.js en ningún subdirectorio."
        echo "Verifica que el archivo exista y que estés en el directorio correcto."
        exit 1
    fi
fi

# Verificar si el directorio dist existe
if [ ! -d "dist" ]; then
    echo "⚠️ ADVERTENCIA: El directorio dist/ no existe."
    echo "La aplicación podría no funcionar correctamente sin los archivos estáticos."
    
    # Crear el directorio dist si no existe
    echo "Creando el directorio dist/..."
    mkdir -p dist
    
    # Crear un archivo index.html básico
    echo "Creando un archivo index.html básico..."
    cat > dist/index.html << 'EOL'
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>CRM Probolsas</title>
    <style>
        body { font-family: Arial, sans-serif; line-height: 1.6; margin: 0; padding: 20px; color: #333; }
        .container { max-width: 800px; margin: 0 auto; background-color: white; padding: 30px; border-radius: 8px; box-shadow: 0 2px 10px rgba(0, 0, 0, 0.1); }
        h1 { color: #0066cc; margin-top: 0; border-bottom: 2px solid #eee; padding-bottom: 10px; }
        .warning { background-color: #fff3cd; color: #856404; padding: 15px; border-radius: 4px; margin-bottom: 20px; }
    </style>
</head>
<body>
    <div class="container">
        <h1>CRM Probolsas</h1>
        <div class="warning">
            Esta es una página de respaldo generada automáticamente.
            La aplicación está en ejecución, pero no se encontraron los archivos compilados.
        </div>
        <p>Fecha y hora del servidor: <span id="datetime"></span></p>
        <script>
            document.getElementById('datetime').textContent = new Date().toLocaleString();
        </script>
    </div>
</body>
</html>
EOL
fi

# Verificar si las dependencias están instaladas
if [ ! -d "node_modules" ]; then
    echo "⚠️ ADVERTENCIA: El directorio node_modules/ no existe."
    echo "Instalando dependencias mínimas necesarias..."
    npm install --only=production express compression dotenv
fi

# Iniciar la aplicación
echo -e "\n=== Iniciando el servidor... ==="
echo "Ejecutando: node server.js"
echo "Presiona Ctrl+C para detener el servidor"
echo -e "===================================\n"

# Ejecutar el servidor
node server.js
