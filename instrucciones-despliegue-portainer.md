# Instrucciones para el Despliegue en Portainer

Este documento proporciona instrucciones detalladas para desplegar la aplicación CRM Probolsas en Portainer después de los cambios realizados.

## Pasos para el Despliegue

### 1. Asegúrate de que los cambios estén en GitHub

Antes de proceder con el despliegue en Portainer, asegúrate de que todos los cambios (Dockerfile, docker-compose.yml, scripts de verificación, etc.) se hayan subido correctamente a GitHub.

### 2. Accede a Portainer

1. Abre tu navegador y ve a `https://ippportainer.probolsas.co`
2. Inicia sesión con tus credenciales

### 3. Actualiza el Stack

1. En el menú lateral, haz clic en "Stacks"
2. Encuentra el stack `crm-probolsas`
3. Haz clic en el botón "Pull and redeploy" o similar
4. **IMPORTANTE**: Si ves una opción como "Force rebuild" o "Force recreation", asegúrate de marcarla
5. Confirma la acción y espera a que Portainer complete el proceso de despliegue

### 4. Verifica el Despliegue

Después de que Portainer haya completado el despliegue, puedes verificar el estado de la aplicación de varias maneras:

#### A. Usando la Interfaz de Portainer

1. Ve a la página del stack recién desplegado
2. Haz clic en el contenedor para ver sus detalles
3. Revisa los logs para asegurarte de que no haya errores
4. Verifica que el estado sea "Running" (en ejecución)

#### B. Usando el Script de Verificación

Hemos creado un script de verificación que te ayudará a diagnosticar problemas con el despliegue:

1. Copia el script `verificar-despliegue-portainer.sh` al servidor donde está instalado Portainer
2. Dale permisos de ejecución:
   ```bash
   chmod +x verificar-despliegue-portainer.sh
   ```
3. Ejecuta el script:
   ```bash
   ./verificar-despliegue-portainer.sh
   ```
4. El script verificará:
   - Si el contenedor está en ejecución
   - Los logs del contenedor
   - Si el servidor está respondiendo
   - Si Traefik está enrutando correctamente
   - Sugerencias para verificar si la aplicación es accesible desde Internet

#### C. Accediendo a la Aplicación

1. Abre tu navegador y ve a `https://ippcrm.probolsas.co`
2. Verifica que la aplicación se cargue correctamente y funcione como se espera

## Solución de Problemas

### El Contenedor No Inicia

Si el contenedor no inicia, verifica los logs en Portainer para identificar el error. Algunos problemas comunes incluyen:

1. **Problema con el Dockerfile**: Verifica que el Dockerfile esté correctamente configurado
2. **Problema con las dependencias**: Verifica que todas las dependencias necesarias estén instaladas
3. **Problema con los puertos**: Verifica que los puertos no estén siendo utilizados por otros servicios

### La Aplicación No Es Accesible

Si la aplicación no es accesible a través de `https://ippcrm.probolsas.co`, verifica:

1. **Traefik**: Asegúrate de que Traefik esté configurado correctamente
2. **DNS**: Comprueba que el dominio apunte a la IP correcta del servidor
3. **Firewall**: Revisa las reglas de firewall para asegurarte de que los puertos 80 y 443 estén abiertos

### Errores en los Logs

Si ves errores en los logs del contenedor, algunos problemas comunes incluyen:

1. **Archivo server.js no encontrado**: Verifica que el archivo server.js se esté copiando correctamente al contenedor
2. **Error al iniciar el servidor**: Verifica que el puerto 3000 no esté siendo utilizado por otro servicio
3. **Error de conexión a Supabase**: Verifica que las credenciales de Supabase sean correctas

## Reconstrucción Completa

Si continúas teniendo problemas, puedes intentar una reconstrucción completa:

1. En Portainer, elimina el stack `crm-probolsas`
2. Elimina las imágenes antiguas:
   ```bash
   docker rmi pedroconda/crm-probolsas:latest pedroconda/crm-probolsas:v2 pedroconda/crm-probolsas:simple
   ```
3. Vuelve a crear el stack en Portainer:
   - Usa la misma URL del repositorio
   - Usa la misma configuración que tenías antes
   - Esto forzará a Portainer a obtener la última versión del código y reconstruir la imagen desde cero

## Recursos Adicionales

- [Documentación de Portainer](https://docs.portainer.io/)
- [Documentación de Traefik](https://doc.traefik.io/traefik/)
- [Documentación de Docker](https://docs.docker.com/)
