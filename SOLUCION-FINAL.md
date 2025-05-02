# Solución Final para Desplegar CRM Probolsas en VPS

## El Problema

El error "Missing script: start" ocurre porque estás intentando ejecutar `npm start` directamente en el VPS, fuera del contexto del contenedor Docker. Este comando no es necesario cuando usas Docker/Portainer.

## La Solución Rápida

### Paso 1: Verifica el Estado Actual

Ejecuta este script para verificar el estado actual del despliegue:

```bash
# Dar permisos de ejecución al script
chmod +x verificar-portainer.sh

# Ejecutar el script
./verificar-portainer.sh
```

Este script te mostrará:
- Si hay contenedores relacionados con crm-probolsas
- Si los contenedores están en ejecución
- Si la red probolsas existe
- Si Traefik está configurado correctamente

### Paso 2: Configura el Stack en Portainer

1. Accede a Portainer en `https://ippportainer.probolsas.co`
2. Ve a "Stacks" en el menú lateral
3. Si ya existe un stack llamado `probolsas_crm_v2` o similar, selecciónalo
4. Si no existe, haz clic en "Add stack" para crear uno nuevo
5. Usa el siguiente contenido para el docker-compose.yml:

```yaml
version: '3.8'

services:
  crm-app:
    # Usar una imagen preexistente de Docker Hub
    image: pedroconda/crm-probolsas:latest
    # Sin configs, sin volumes, sin build
    networks:
      - probolsas
    deploy:
      labels:
        - "traefik.enable=true"
        - "traefik.http.routers.crm.rule=Host(`ippcrm.probolsas.co`)"
        - "traefik.http.routers.crm.entrypoints=websecure"
        - "traefik.http.routers.crm.tls.certresolver=letsencrypt"
        - "traefik.http.services.crm.loadbalancer.server.port=80"
      restart_policy:
        condition: on-failure
        delay: 5s
        max_attempts: 3
        window: 120s

networks:
  probolsas:
    external: true
```

6. Haz clic en "Deploy the stack" (si es nuevo) o "Update the stack" (si estás actualizando)

### Paso 3: Verifica el Despliegue

1. Una vez desplegado, haz clic en el nombre del stack para ver los detalles
2. Verifica que el contenedor esté en estado "Running"
3. Si el contenedor está en estado "Running", la aplicación debería estar accesible en `https://ippcrm.probolsas.co`

## Solución de Problemas Comunes

### Si la Red Probolsas No Existe

```bash
# Crear la red probolsas
docker network create --driver overlay probolsas
```

### Si el Contenedor No Inicia

1. Verifica los logs del contenedor en Portainer
2. Asegúrate de que la red probolsas exista
3. Intenta reiniciar el contenedor:
   ```bash
   docker restart ID_DEL_CONTENEDOR
   ```

### Si el Contenedor Inicia pero la Aplicación No es Accesible

1. Verifica que Traefik esté en ejecución
2. Verifica que el dominio `ippcrm.probolsas.co` apunte a la IP correcta del servidor
3. Verifica que el puerto 80 esté expuesto en el contenedor

## IMPORTANTE: No Ejecutes npm start Manualmente

No necesitas ejecutar `npm start` manualmente. El contenedor ya tiene configurado cómo iniciar la aplicación. Si intentas ejecutar `npm start` directamente en el VPS, obtendrás el error "Missing script: start" porque estás fuera del contexto del contenedor.

## Documentación Adicional

Para instrucciones más detalladas, consulta:

- [Instrucciones para Desplegar en Portainer](INSTRUCCIONES-PORTAINER.md)
- [Solución usando Docker Hub](instrucciones-solucion-dockerhub.md)
