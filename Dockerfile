# Etapa de build
FROM node:18 AS builder

WORKDIR /app

COPY package*.json ./
RUN npm install

COPY . .

RUN npm run build

# Etapa de producción
FROM node:18-slim

WORKDIR /app

COPY --from=builder /app/dist ./dist
COPY --from=builder /app/package*.json ./
COPY health-check.js ./

RUN npm install --only=production

ENV PORT=3000

EXPOSE 3000

# Configurar health check
HEALTHCHECK --interval=30s --timeout=5s --start-period=30s --retries=3 \
  CMD node health-check.js || exit 1

CMD ["npm", "start"]
