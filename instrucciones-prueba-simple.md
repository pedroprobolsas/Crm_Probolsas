# Prueba Simplificada para Diagnosticar Problemas en Portainer

He simplificado al máximo el archivo docker-compose.yml para diagnosticar los problemas que estás enfrentando con Portainer y Docker Swarm. Esta configuración mínima nos ayudará a identificar si el problema está en la configuración de Swarm, en Portainer, o en nuestra configuración específica.

## Cambios Realizados

1. **Simplificado el docker-compose.yml**:
   - Eliminadas todas las complejidades (volúmenes, comandos personalizados, etc.)
   - Cambiado a una imagen muy ligera y confiable (`nginx:alpine`)
   - Configuración mínima necesaria para un despliegue básico

## Cómo Funciona Esta Solución

Esta solución funciona de la siguiente manera:

1. Usamos una imagen oficial de Nginx que es muy ligera y confiable.
2. No usamos volúmenes, comandos personalizados, ni otras complejidades.
3. Simplemente exponemos el puerto 80 de Nginx como puerto 3000 en el host.
4. Mantenemos la configuración básica de Traefik para el enrutamiento.

## Pasos para Implementar

### 1. Sube los cambios al repositorio

```bash
git add docker-compose.yml instrucciones-prueba-simple.md
git commit -m "Simplificar docker-compose.yml para diagnóstico"
git push origin main
```

### 2. Actualiza el stack en Portainer

1. Accede a Portainer en `https://ippportainer.probolsas.co`
2. Ve a "Stacks" en el menú lateral
3. Encuentra tu stack `probolsas_crm_v2`
4. Haz clic en "Pull and redeploy" o similar
5. Confirma la acción

### 3. Verifica el despliegue

1. Revisa los logs en Portainer para ver si hay errores
2. Accede a la aplicación en `https://ippcrm.probolsas.co`
   - Deberías ver la página de bienvenida predeterminada de Nginx

## Interpretación de los Resultados

### Si el despliegue es exitoso

Si el despliegue es exitoso y puedes ver la página de bienvenida de Nginx, esto significa que:

1. Docker Swarm está configurado correctamente
2. Portainer puede desplegar stacks correctamente
3. Traefik está enrutando correctamente el tráfico
4. La red `probolsas` existe y funciona correctamente

En este caso, el problema estaba en nuestra configuración específica (volúmenes, comandos, etc.), y podemos empezar a añadir complejidad gradualmente para identificar exactamente qué parte estaba causando problemas.

### Si el despliegue falla

Si el despliegue sigue fallando, esto podría indicar problemas más fundamentales:

1. **Problema con Docker Swarm**: Verifica que Swarm esté inicializado correctamente:
   ```bash
   docker info | grep Swarm
   ```

2. **Problema con la red**: Verifica que la red `probolsas` exista:
   ```bash
   docker network ls | grep probolsas
   ```

3. **Problema con Portainer**: Verifica los logs de Portainer:
   ```bash
   docker logs $(docker ps | grep portainer | awk '{print $1}')
   ```

## Próximos Pasos

Una vez que tengamos un despliegue básico funcionando, podemos ir añadiendo complejidad gradualmente:

1. Primero, añadir volúmenes para servir contenido estático personalizado
2. Luego, cambiar a una imagen de Node.js
3. Finalmente, añadir el comando personalizado y los scripts

Este enfoque paso a paso nos ayudará a identificar exactamente qué parte de la configuración está causando problemas.
