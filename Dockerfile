FROM node:18

WORKDIR /app

# Copiar solo los archivos necesarios
COPY dist/ ./dist/
COPY package.json ./
COPY server.js ./
COPY verify-server.sh ./

# Instalar dependencias y herramientas de diagnóstico
RUN npm install express compression && \
    apt-get update && \
    apt-get install -y curl procps net-tools && \
    chmod +x verify-server.sh && \
    echo "Instalación completada"

# Verificar contenido del directorio
RUN ls -la && \
    echo "Contenido de dist:" && \
    ls -la dist/ || echo "Directorio dist vacío o no existe"

EXPOSE 3000

# No definimos CMD aquí, lo definimos en docker-compose.yml
