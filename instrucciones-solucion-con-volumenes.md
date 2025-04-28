# Solución: Despliegue con Volúmenes para Docker Swarm

He implementado una solución que permite desplegar la aplicación en Portainer con Docker Swarm, evitando los problemas de construcción de imágenes y el error "invalid reference format".

## Cambios Realizados

1. **Modificado el docker-compose.yml**:
   - Eliminada la sección `build` que no es compatible con Docker Swarm
   - Configurado para usar la imagen oficial `node:18-slim`
   - Añadidos volúmenes para montar los archivos necesarios
   - Configurado un comando de inicio que instala dependencias y ejecuta el script de inicio

## Cómo Funciona Esta Solución

Esta solución funciona de la siguiente manera:

1. En lugar de construir una imagen Docker personalizada (lo que no es compatible con Docker Swarm en Portainer), usamos la imagen oficial de Node.js.

2. Montamos los archivos necesarios (dist/, server.js, package.json, start.sh, verify-server.sh) como volúmenes en el contenedor.

3. Ejecutamos un comando de inicio que:
   - Instala las dependencias necesarias (express, compression)
   - Instala herramientas de diagnóstico (curl, procps, net-tools)
   - Da permisos de ejecución a los scripts
   - Ejecuta el script de inicio (start.sh)

## Ventajas de Esta Solución

1. **Compatible con Docker Swarm**: Esta configuración es totalmente compatible con Docker Swarm, que es lo que usa Portainer.

2. **No requiere construcción de imágenes**: Evitamos los problemas de construcción de imágenes y el error "invalid reference format".

3. **Fácil de actualizar**: Para actualizar la aplicación, solo necesitas actualizar los archivos en el repositorio y volver a desplegar el stack.

4. **Diagnóstico detallado**: Los scripts de inicio y verificación proporcionan información detallada si algo sale mal.

## Pasos para Implementar

### 1. Asegúrate de tener los archivos necesarios

Antes de desplegar, necesitas tener estos archivos en tu repositorio:
- La carpeta `dist/` con los archivos compilados
- El archivo `server.js` que creamos
- El archivo `start.sh` que creamos
- El archivo `verify-server.sh` que creamos
- El archivo `package.json` (el original de tu proyecto)

### 2. Sube los cambios al repositorio

```bash
git add docker-compose.yml instrucciones-solucion-con-volumenes.md
git commit -m "Implementar solución de despliegue con volúmenes para Docker Swarm"
git push origin main
```

### 3. Actualiza el stack en Portainer

1. Accede a Portainer en `https://ippportainer.probolsas.co`
2. Ve a "Stacks" en el menú lateral
3. Encuentra tu stack `probolsas_crm_v2`
4. Haz clic en "Pull and redeploy" o similar
5. Confirma la acción

### 4. Verifica el despliegue

1. Revisa los logs en Portainer para ver si hay errores
2. Accede a la aplicación en `https://ippcrm.probolsas.co`
3. Si es necesario, ejecuta el script de diagnóstico que creamos anteriormente

## Solución de Problemas

### Si el contenedor no se inicia

Verifica los logs en Portainer. Los problemas más comunes son:

1. **Falta la carpeta dist/**:
   - Asegúrate de que la carpeta `dist/` exista en tu repositorio
   - Si no existe, compila la aplicación localmente y súbela al repositorio

2. **Problemas con los permisos**:
   - Asegúrate de que los scripts tengan permisos de ejecución en el repositorio
   - Puedes añadir `chmod +x start.sh verify-server.sh` al comando en docker-compose.yml

3. **Problemas con la red**:
   - Asegúrate de que la red `probolsas` exista en Docker Swarm
   - Puedes verificarlo con `docker network ls` en el servidor

### Si el contenedor se inicia pero la aplicación no funciona

1. **Verifica los logs del servidor**:
   - El servidor Express registrará información útil en los logs

2. **Verifica la configuración de Traefik**:
   - Asegúrate de que Traefik esté configurado correctamente para enrutar el tráfico al contenedor

3. **Prueba acceder directamente al puerto 3000**:
   - Si Traefik no funciona, intenta acceder directamente al puerto 3000 del servidor

## Conclusión

Esta solución evita los problemas de construcción de imágenes en Docker Swarm y debería resolver el error "invalid reference format" que estabas enfrentando. Al usar volúmenes y la imagen oficial de Node.js, nos aseguramos de que la configuración sea compatible con Docker Swarm y Portainer.
