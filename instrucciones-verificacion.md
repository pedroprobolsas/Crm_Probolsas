# Instrucciones para Verificar y Solucionar Problemas del Despliegue

Este documento proporciona instrucciones detalladas para verificar y solucionar problemas del despliegue de la aplicación CRM Probolsas en Portainer.

## Scripts de Verificación

Se han creado tres scripts de verificación para ayudar a diagnosticar problemas:

1. **verify-container.sh**: Verifica el estado del contenedor en Portainer
2. **verify-server.sh**: Verifica si el servidor está funcionando correctamente dentro del contenedor
3. **verify-traefik.sh**: Verifica la configuración de Traefik y su conectividad con la aplicación

### Cómo Usar los Scripts

#### 1. Verificar el Contenedor

Ejecuta el siguiente comando en el servidor host:

```bash
chmod +x verify-container.sh
./verify-container.sh
```

Este script verificará:
- Si el contenedor está en ejecución
- Los logs del contenedor
- La información del contenedor
- El uso de recursos del contenedor
- La configuración de red del contenedor

#### 2. Verificar el Servidor

Este script debe ejecutarse dentro del contenedor. Primero, obtén el ID del contenedor:

```bash
CONTAINER_ID=$(docker ps | grep crm-probolsas | awk '{print $1}')
```

Luego, ejecuta el script dentro del contenedor:

```bash
docker exec -it $CONTAINER_ID /bin/bash -c "./verify-server.sh"
```

Este script verificará:
- Si el proceso node está en ejecución
- Si el puerto 3000 está en uso
- Si el servidor responde localmente
- Si hay conectividad a Internet

#### 3. Verificar Traefik

Ejecuta el siguiente comando en el servidor host:

```bash
chmod +x verify-traefik.sh
./verify-traefik.sh
```

Este script verificará:
- Si Traefik está en ejecución
- La configuración de Traefik
- Los routers de Traefik
- La conectividad a la aplicación
- La conectividad a través de Traefik
- La resolución DNS

## Solución de Problemas Comunes

### 1. El Contenedor No Inicia

Si el contenedor no inicia, verifica los logs:

```bash
CONTAINER_ID=$(docker ps -a | grep crm-probolsas | head -1 | awk '{print $1}')
docker logs $CONTAINER_ID
```

Posibles soluciones:
- Verifica que el archivo server.js exista en el contenedor
- Verifica que las dependencias estén instaladas correctamente
- Verifica que el puerto 3000 no esté siendo utilizado por otro servicio

### 2. El Servidor No Responde

Si el servidor no responde, verifica si está en ejecución:

```bash
docker exec -it $CONTAINER_ID ps aux | grep node
```

Posibles soluciones:
- Reinicia el contenedor: `docker restart $CONTAINER_ID`
- Verifica los logs del servidor: `docker logs $CONTAINER_ID`
- Verifica que el puerto 3000 esté expuesto correctamente

### 3. Traefik No Enruta Correctamente

Si Traefik no enruta correctamente, verifica su configuración:

```bash
docker exec -it $(docker ps | grep traefik | awk '{print $1}') traefik healthcheck
```

Posibles soluciones:
- Verifica que las etiquetas de Traefik estén correctamente configuradas en docker-compose.yml
- Verifica que el dominio ippcrm.probolsas.co esté correctamente configurado en DNS
- Verifica que Traefik tenga acceso al contenedor a través de la red probolsas

## Pasos para Reconstruir la Aplicación

Si necesitas reconstruir la aplicación desde cero:

1. Elimina el stack en Portainer
2. Elimina las imágenes antiguas:
   ```bash
   docker rmi pedroconda/crm-probolsas:latest pedroconda/crm-probolsas:v2 pedroconda/crm-probolsas:simple
   ```
3. Vuelve a desplegar el stack en Portainer

## Contacto para Soporte

Si continúas teniendo problemas, contacta al equipo de soporte:

- Email: soporte@probolsas.co
- Teléfono: +123456789
