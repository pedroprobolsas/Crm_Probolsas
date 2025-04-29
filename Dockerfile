# Etapa de construcción
FROM node:18 AS builder

WORKDIR /app

# Copiar archivos de configuración
COPY package*.json ./

# Instalar dependencias
RUN npm install

# Copiar el código fuente
COPY . .

# Compilar la aplicación (si es necesario)
# RUN npm run build

# Etapa de producción
FROM node:18-slim

WORKDIR /app

# Crear un usuario no privilegiado
RUN apt-get update && \
    apt-get install -y --no-install-recommends curl procps net-tools && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    groupadd -r nodejs && \
    useradd -r -g nodejs -s /bin/bash -d /home/nodejs nodejs && \
    mkdir -p /home/nodejs && \
    chown -R nodejs:nodejs /home/nodejs

# Copiar solo los archivos necesarios desde la etapa de construcción
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/server.js ./
COPY --from=builder /app/package.json ./

# Instalar solo las dependencias de producción
RUN npm install --production && \
    npm install @supabase/supabase-js && \
    npm cache clean --force

# Exponer el puerto
EXPOSE 3000

# Cambiar al usuario no privilegiado
USER nodejs

# Variables de entorno
ENV NODE_ENV=production
ENV PORT=3000

# Comando para iniciar el servidor
CMD ["node", "server.js"]
