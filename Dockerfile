FROM node:18-slim

WORKDIR /app

# Copiar solo los archivos necesarios
COPY dist/ ./dist/
COPY package.json ./
COPY server.js ./
COPY start.sh ./
COPY verify-server.sh ./

# Instalar solo las dependencias necesarias para el servidor
RUN npm install express compression && \
    apt-get update && \
    apt-get install -y curl procps net-tools && \
    chmod +x start.sh && \
    chmod +x verify-server.sh

EXPOSE 3000

# Usar el script de inicio para más diagnóstico
CMD ["./start.sh"]
