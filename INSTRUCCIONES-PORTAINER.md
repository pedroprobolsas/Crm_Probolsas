# Instrucciones para Desplegar en Portainer

Estas instrucciones te guiarán paso a paso para desplegar correctamente la aplicación CRM Probolsas en Portainer.

## Paso 1: Acceder a Portainer

1. Abre tu navegador y ve a `https://ippportainer.probolsas.co`
2. Inicia sesión con tus credenciales

## Paso 2: Configurar el Stack

1. En el menú lateral, haz clic en "Stacks"
2. Si ya existe un stack llamado `probolsas_crm_v2` o similar, selecciónalo
3. Si no existe, haz clic en "Add stack" para crear uno nuevo

## Paso 3: Configurar el docker-compose.yml

1. Si estás creando un nuevo stack, selecciona "Web editor" como método
2. Copia y pega el siguiente contenido en el editor:

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

3. Si estás actualizando un stack existente, reemplaza el contenido actual con el anterior

## Paso 4: Desplegar el Stack

1. Haz clic en "Deploy the stack" (si es nuevo) o "Update the stack" (si estás actualizando)
2. Espera a que Portainer despliegue el stack

## Paso 5: Verificar el Despliegue

1. Una vez desplegado, haz clic en el nombre del stack para ver los detalles
2. Verifica que el contenedor esté en estado "Running"
3. Si el contenedor está en estado "Running", la aplicación debería estar accesible en `https://ippcrm.probolsas.co`

## Solución de Problemas

### Si el Contenedor No Inicia

1. Haz clic en el nombre del contenedor para ver los logs
2. Revisa los logs para identificar el problema
3. Si ves errores relacionados con la red, verifica que la red `probolsas` exista:
   ```bash
   docker network ls | grep probolsas
   ```
4. Si la red no existe, créala:
   ```bash
   docker network create --driver overlay probolsas
   ```

### Si el Contenedor Inicia pero la Aplicación No es Accesible

1. Verifica que Traefik esté configurado correctamente
2. Verifica que el dominio `ippcrm.probolsas.co` apunte a la IP correcta del servidor
3. Verifica que el puerto 80 esté expuesto en el contenedor

## Importante: No Ejecutes npm start Manualmente

No necesitas ejecutar `npm start` manualmente. El contenedor ya tiene configurado cómo iniciar la aplicación. Si intentas ejecutar `npm start` directamente en el VPS, obtendrás el error "Missing script: start" porque estás fuera del contexto del contenedor.
