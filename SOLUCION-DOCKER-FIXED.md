# Solución al Error "Missing script: start" en Docker

## El Problema

El error "Missing script: start" ocurre porque la imagen Docker actual (`pedroconda/crm-probolsas:latest`) está configurada para ejecutar `npm start` al iniciarse, pero el package.json dentro de la imagen no tiene definido el script "start".

## La Solución

La solución consiste en crear una nueva imagen Docker que extienda la imagen actual pero cambie el comando de inicio para usar `node server.js` directamente en lugar de `npm start`.

## Opción 1: Construir y Subir una Nueva Imagen (Recomendado)

### Paso 1: Construir y Subir la Imagen Corregida

Ejecuta el script `build-and-push-fixed.sh` para construir y subir la imagen corregida a Docker Hub:

```bash
# Dar permisos de ejecución al script
chmod +x build-and-push-fixed.sh

# Ejecutar el script
./build-and-push-fixed.sh
```

Este script:
1. Construye una nueva imagen Docker basada en `pedroconda/crm-probolsas:latest` pero con el comando de inicio cambiado
2. Sube la nueva imagen a Docker Hub como `pedroconda/crm-probolsas:fixed`

### Paso 2: Actualizar el Stack en Portainer

1. Accede a Portainer en `https://ippportainer.probolsas.co`
2. Ve a "Stacks" en el menú lateral
3. Encuentra tu stack (probablemente `probolsas_crm_v2`)
4. Haz clic en el stack para ver sus detalles
5. Busca la opción "Editor" o similar que te permita editar la configuración del stack
6. Reemplaza el contenido actual con el contenido del archivo `docker-compose.fixed.yml`
7. Haz clic en "Update the stack" o similar para aplicar los cambios

## Opción 2: Modificar el Stack Directamente en Portainer

Si no puedes o no quieres construir y subir una nueva imagen, puedes modificar el stack directamente en Portainer:

1. Accede a Portainer en `https://ippportainer.probolsas.co`
2. Ve a "Stacks" en el menú lateral
3. Encuentra tu stack (probablemente `probolsas_crm_v2`)
4. Haz clic en el stack para ver sus detalles
5. Busca la opción "Editor" o similar que te permita editar la configuración del stack
6. Añade la línea `command: node server.js` debajo de la línea `image: pedroconda/crm-probolsas:latest`:

```yaml
services:
  crm-app:
    image: pedroconda/crm-probolsas:latest
    command: node server.js  # Añade esta línea
    networks:
      - probolsas
    # ... resto de la configuración
```

7. Haz clic en "Update the stack" o similar para aplicar los cambios

## Verificación

Una vez actualizado el stack, verifica que el contenedor esté en ejecución:

```bash
docker ps | grep probolsas
```

Si el contenedor está en ejecución, la aplicación debería estar accesible en `https://ippcrm.probolsas.co`.

## Explicación Técnica

El problema ocurre porque el Dockerfile original de la imagen `pedroconda/crm-probolsas:latest` probablemente usa `npm start` como comando de inicio, pero el package.json dentro de la imagen no tiene definido el script "start".

La solución consiste en sobrescribir el comando de inicio para usar `node server.js` directamente, que es lo que normalmente haría el script "start" si estuviera definido.

## Archivos Creados

1. `Dockerfile.fixed` - Dockerfile para crear la imagen corregida
2. `build-and-push-fixed.sh` - Script para construir y subir la imagen corregida
3. `docker-compose.fixed.yml` - Archivo docker-compose.yml actualizado para usar la imagen corregida
