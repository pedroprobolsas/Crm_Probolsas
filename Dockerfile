FROM node:18-slim

WORKDIR /app

# Instalar herramientas básicas y dependencias
RUN apt-get update && \
    apt-get install -y curl procps net-tools && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Copiar solo los archivos necesarios
COPY dist/ ./dist/
COPY server.js ./
COPY package.json ./

# Instalar dependencias mínimas
RUN npm install express compression

# Exponer el puerto
EXPOSE 3000

# Comando para iniciar el servidor
CMD ["node", "server.js"]
