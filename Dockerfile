FROM node:18-alpine

WORKDIR /app

# Copiar solo los archivos necesarios
COPY dist/ ./dist/
COPY package.json ./
COPY server.js ./
COPY verify-server.sh ./

# Instalar solo express y compression, y herramientas de diagnóstico
RUN npm install express compression && \
    apk add --no-cache curl procps net-tools bash && \
    chmod +x verify-server.sh

EXPOSE 3000

# Comando simple y directo
CMD ["node", "server.js"]
