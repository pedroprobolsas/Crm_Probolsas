#!/bin/bash
# Script completo para solucionar el problema "Missing script: start"

# Colores para la salida
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== Solucionador Completo para 'Missing script: start' ===${NC}"
echo "Fecha y hora: $(date)"
echo "Directorio actual: $(pwd)"

# Función para verificar si un comando existe
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Verificar si Node.js y npm están instalados
echo -e "\n${YELLOW}Verificando Node.js y npm...${NC}"
if command_exists node && command_exists npm; then
    node_version=$(node --version)
    npm_version=$(npm --version)
    echo -e "${GREEN}✓ Node.js ${node_version} y npm ${npm_version} están instalados${NC}"
else
    echo -e "${RED}✗ Node.js y/o npm no están instalados${NC}"
    echo -e "${YELLOW}Intentando instalar Node.js y npm...${NC}"
    
    if command_exists apt-get; then
        echo "Detectado sistema basado en Debian/Ubuntu"
        sudo apt-get update
        sudo apt-get install -y nodejs npm
    elif command_exists yum; then
        echo "Detectado sistema basado en RHEL/CentOS"
        sudo yum install -y nodejs npm
    else
        echo -e "${RED}No se pudo determinar el gestor de paquetes. Por favor, instala Node.js y npm manualmente.${NC}"
        exit 1
    fi
    
    if command_exists node && command_exists npm; then
        node_version=$(node --version)
        npm_version=$(npm --version)
        echo -e "${GREEN}✓ Node.js ${node_version} y npm ${npm_version} instalados correctamente${NC}"
    else
        echo -e "${RED}✗ No se pudo instalar Node.js y npm. Por favor, instálalos manualmente.${NC}"
        exit 1
    fi
fi

# Verificar si Docker está instalado
echo -e "\n${YELLOW}Verificando Docker...${NC}"
if command_exists docker; then
    docker_version=$(docker --version)
    echo -e "${GREEN}✓ Docker está instalado: ${docker_version}${NC}"
    
    # Verificar si hay contenedores relacionados con crm-probolsas
    echo -e "\n${YELLOW}Buscando contenedores relacionados con crm-probolsas...${NC}"
    containers=$(docker ps -a | grep -i probolsas)
    if [ -n "$containers" ]; then
        echo -e "${GREEN}✓ Se encontraron contenedores relacionados con crm-probolsas${NC}"
        echo "$containers"
        
        echo -e "\n${YELLOW}¿Estás intentando ejecutar la aplicación dentro de Docker o directamente en el VPS?${NC}"
        echo -e "1) Dentro de Docker (recomendado)"
        echo -e "2) Directamente en el VPS"
        read -p "Selecciona una opción (1/2): " docker_option
        
        if [ "$docker_option" = "1" ]; then
            echo -e "\n${YELLOW}Recomendación: No necesitas ejecutar 'npm start' manualmente si estás usando Docker.${NC}"
            echo -e "El contenedor ya tiene configurado cómo iniciar la aplicación."
            echo -e "\n${YELLOW}¿Quieres reiniciar el contenedor?${NC}"
            read -p "Reiniciar el contenedor (s/n): " restart_option
            
            if [ "$restart_option" = "s" ] || [ "$restart_option" = "S" ]; then
                container_id=$(echo "$containers" | head -1 | awk '{print $1}')
                echo -e "${YELLOW}Reiniciando el contenedor ${container_id}...${NC}"
                docker restart "$container_id"
                echo -e "${GREEN}✓ Contenedor reiniciado${NC}"
            fi
            
            echo -e "\n${YELLOW}Para verificar el estado del contenedor, ejecuta:${NC}"
            echo -e "docker logs \$(docker ps | grep -i probolsas | awk '{print \$1}')"
            
            exit 0
        fi
    else
        echo -e "${YELLOW}No se encontraron contenedores relacionados con crm-probolsas${NC}"
    fi
else
    echo -e "${YELLOW}Docker no está instalado. Continuando con la solución para ejecución directa...${NC}"
fi

# Verificar si el archivo package.json existe
echo -e "\n${YELLOW}Verificando package.json...${NC}"
if [ -f "package.json" ]; then
    echo -e "${GREEN}✓ El archivo package.json existe en el directorio actual${NC}"
    
    # Verificar si el script "start" está definido
    if grep -q '"start":' package.json; then
        echo -e "${GREEN}✓ El script 'start' está definido en package.json${NC}"
        start_script=$(grep -A 1 '"start":' package.json | tail -1 | tr -d ' ",')
        echo -e "Script start: ${BLUE}${start_script}${NC}"
    else
        echo -e "${RED}✗ El script 'start' no está definido en package.json${NC}"
        echo -e "${YELLOW}Añadiendo script 'start' a package.json...${NC}"
        
        # Crear una copia de seguridad de package.json
        cp package.json package.json.bak
        
        # Añadir el script "start" a package.json
        sed -i '/"scripts": {/a \    "start": "node server.js",' package.json
        
        echo -e "${GREEN}✓ Script 'start' añadido a package.json${NC}"
    fi
else
    echo -e "${RED}✗ El archivo package.json no existe en el directorio actual${NC}"
    
    # Buscar package.json en subdirectorios
    echo -e "${YELLOW}Buscando package.json en subdirectorios...${NC}"
    package_json_path=$(find . -name "package.json" -type f | grep -v "node_modules" | head -1)
    
    if [ -n "$package_json_path" ]; then
        package_dir=$(dirname "$package_json_path")
        echo -e "${GREEN}✓ Encontrado en: ${package_dir}${NC}"
        echo -e "${YELLOW}Cambiando al directorio: ${package_dir}${NC}"
        cd "$package_dir" || exit 1
        
        # Verificar si el script "start" está definido
        if grep -q '"start":' package.json; then
            echo -e "${GREEN}✓ El script 'start' está definido en package.json${NC}"
            start_script=$(grep -A 1 '"start":' package.json | tail -1 | tr -d ' ",')
            echo -e "Script start: ${BLUE}${start_script}${NC}"
        else
            echo -e "${RED}✗ El script 'start' no está definido en package.json${NC}"
            echo -e "${YELLOW}Añadiendo script 'start' a package.json...${NC}"
            
            # Crear una copia de seguridad de package.json
            cp package.json package.json.bak
            
            # Añadir el script "start" a package.json
            sed -i '/"scripts": {/a \    "start": "node server.js",' package.json
            
            echo -e "${GREEN}✓ Script 'start' añadido a package.json${NC}"
        fi
    else
        echo -e "${RED}✗ No se encontró package.json en ningún subdirectorio${NC}"
        
        # Crear un package.json básico
        echo -e "${YELLOW}Creando un package.json básico...${NC}"
        cat > package.json << 'EOL'
{
  "name": "crm-probolsas",
  "version": "1.0.0",
  "description": "CRM Probolsas",
  "main": "server.js",
  "scripts": {
    "start": "node server.js"
  },
  "dependencies": {
    "express": "^4.18.2",
    "compression": "^1.7.4",
    "dotenv": "^16.5.0"
  }
}
EOL
        echo -e "${GREEN}✓ package.json básico creado${NC}"
    fi
fi

# Verificar si el archivo server.js existe
echo -e "\n${YELLOW}Verificando server.js...${NC}"
if [ -f "server.js" ]; then
    echo -e "${GREEN}✓ El archivo server.js existe en el directorio actual${NC}"
else
    echo -e "${RED}✗ El archivo server.js no existe en el directorio actual${NC}"
    
    # Buscar server.js en subdirectorios
    echo -e "${YELLOW}Buscando server.js en subdirectorios...${NC}"
    server_js_path=$(find . -name "server.js" -type f | head -1)
    
    if [ -n "$server_js_path" ]; then
        server_dir=$(dirname "$server_js_path")
        echo -e "${GREEN}✓ Encontrado en: ${server_dir}${NC}"
        
        if [ "$server_dir" != "." ]; then
            echo -e "${YELLOW}Copiando server.js al directorio actual...${NC}"
            cp "$server_js_path" ./
            echo -e "${GREEN}✓ server.js copiado al directorio actual${NC}"
        fi
    else
        echo -e "${RED}✗ No se encontró server.js en ningún subdirectorio${NC}"
        
        # Crear un server.js básico
        echo -e "${YELLOW}Creando un server.js básico...${NC}"
        cat > server.js << 'EOL'
const express = require('express');
const compression = require('compression');
const path = require('path');
const fs = require('fs');

// Configuración de la aplicación
const app = express();
const PORT = process.env.PORT || 3000;

// Middleware para compresión
app.use(compression());

// Verificar si el directorio dist existe
const distPath = path.join(__dirname, 'dist');
if (!fs.existsSync(distPath)) {
  // Si no existe, crear un archivo index.html básico para que la aplicación funcione
  console.warn('ADVERTENCIA: El directorio dist/ no existe. Creando un archivo index.html básico...');
  
  try {
    fs.mkdirSync(distPath, { recursive: true });
    
    const htmlContent = `
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
            .success { background-color: #d4edda; color: #155724; padding: 15px; border-radius: 4px; margin-bottom: 20px; }
            .warning { background-color: #fff3cd; color: #856404; padding: 15px; border-radius: 4px; margin-bottom: 20px; }
        </style>
    </head>
    <body>
        <div class="container">
            <h1>CRM Probolsas</h1>
            
            <div class="success">
                ¡El servidor Express está funcionando correctamente!
            </div>
            
            <div class="warning">
                No se encontró el directorio dist/ con los archivos compilados de la aplicación.
                Por favor, compila la aplicación y vuelve a desplegar el stack.
            </div>
            
            <p>Esta es una página de respaldo generada por el servidor.</p>
            <p>Fecha y hora del servidor: ${new Date().toISOString()}</p>
        </div>
    </body>
    </html>
    `;
    
    fs.writeFileSync(path.join(distPath, 'index.html'), htmlContent);
    console.log('Archivo index.html básico creado correctamente');
  } catch (error) {
    console.error('Error al crear el archivo index.html básico:', error.message);
    process.exit(1);
  }
}

// Servir archivos estáticos desde la carpeta dist
app.use(express.static(distPath));

// Endpoint simple para verificar el estado del servidor
app.get('/health', (req, res) => {
  res.status(200).json({ 
    status: 'ok', 
    timestamp: new Date().toISOString() 
  });
});

// Manejar todas las rutas para SPA (Single Page Application)
app.get('*', (req, res) => {
  res.sendFile(path.join(distPath, 'index.html'));
});

// Iniciar el servidor
const server = app.listen(PORT, () => {
  console.log(`
========================================
  CRM Probolsas - Servidor Iniciado
========================================
- Puerto: ${PORT}
- Fecha y hora: ${new Date().toISOString()}
- Directorio estático: ${distPath}
========================================
  `);
});

// Manejar señales de terminación
process.on('SIGTERM', () => {
  console.log('Recibida señal SIGTERM, cerrando servidor...');
  server.close(() => {
    console.log('Servidor cerrado correctamente');
    process.exit(0);
  });
});

process.on('SIGINT', () => {
  console.log('Recibida señal SIGINT, cerrando servidor...');
  server.close(() => {
    console.log('Servidor cerrado correctamente');
    process.exit(0);
  });
});
EOL
        echo -e "${GREEN}✓ server.js básico creado${NC}"
    fi
fi

# Verificar si el directorio dist existe
echo -e "\n${YELLOW}Verificando directorio dist/...${NC}"
if [ -d "dist" ]; then
    echo -e "${GREEN}✓ El directorio dist/ existe${NC}"
    
    # Verificar si hay archivos en el directorio dist
    dist_files=$(ls -A dist | wc -l)
    if [ "$dist_files" -gt 0 ]; then
        echo -e "${GREEN}✓ El directorio dist/ contiene ${dist_files} archivos${NC}"
    else
        echo -e "${YELLOW}⚠️ El directorio dist/ está vacío${NC}"
        
        # Crear un archivo index.html básico
        echo -e "${YELLOW}Creando un archivo index.html básico...${NC}"
        mkdir -p dist
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
        echo -e "${GREEN}✓ Archivo index.html básico creado${NC}"
    fi
else
    echo -e "${YELLOW}⚠️ El directorio dist/ no existe${NC}"
    
    # Crear el directorio dist y un archivo index.html básico
    echo -e "${YELLOW}Creando el directorio dist/ y un archivo index.html básico...${NC}"
    mkdir -p dist
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
    echo -e "${GREEN}✓ Directorio dist/ y archivo index.html básico creados${NC}"
fi

# Verificar si las dependencias están instaladas
echo -e "\n${YELLOW}Verificando dependencias...${NC}"
if [ -d "node_modules" ]; then
    echo -e "${GREEN}✓ El directorio node_modules/ existe${NC}"
    node_modules_count=$(ls -1 node_modules | wc -l)
    echo -e "Número de paquetes instalados: ${node_modules_count}"
else
    echo -e "${YELLOW}⚠️ El directorio node_modules/ no existe${NC}"
    echo -e "${YELLOW}Instalando dependencias mínimas necesarias...${NC}"
    npm install --only=production express compression dotenv
    echo -e "${GREEN}✓ Dependencias mínimas instaladas${NC}"
fi

# Preguntar al usuario cómo quiere ejecutar la aplicación
echo -e "\n${YELLOW}¿Cómo quieres ejecutar la aplicación?${NC}"
echo -e "1) Con npm start"
echo -e "2) Directamente con node server.js"
read -p "Selecciona una opción (1/2): " run_option

if [ "$run_option" = "1" ]; then
    echo -e "\n${YELLOW}Ejecutando la aplicación con npm start...${NC}"
    echo -e "${BLUE}========================================${NC}"
    npm start
else
    echo -e "\n${YELLOW}Ejecutando la aplicación directamente con node server.js...${NC}"
    echo -e "${BLUE}========================================${NC}"
    node server.js
fi
