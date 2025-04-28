# Instrucciones para Actualizar la Imagen en Portainer

He modificado el archivo `docker-compose.yml` para resolver el problema con la imagen Docker. A continuación, te explico el cambio realizado y cómo proceder.

## Cambio Realizado

He cambiado la línea que especifica la imagen Docker:

```diff
- image: pedroconda/crm-probolsas:debug  # Cambiar tag para forzar reconstrucción
+ image: pedroconda/crm-probolsas  # Usar imagen existente sin tag específico
```

## Razón del Cambio

El problema era que Portainer estaba intentando usar la imagen `pedroconda/crm-probolsas:debug`, pero esta imagen con el tag `:debug` no existe en Docker Hub. Al eliminar el tag específico, Docker usará automáticamente la imagen con el tag `:latest` o la imagen base sin tag específico, que sí existe en Docker Hub.

## Pasos para Actualizar el Stack en Portainer

1. **Sube los cambios al repositorio Git**:
   ```bash
   git add docker-compose.yml
   git commit -m "Fix: Usar imagen sin tag específico para resolver problema de imagen no encontrada"
   git push origin main  # O la rama que estés utilizando
   ```

2. **Actualiza el stack en Portainer**:
   - Accede a Portainer en `https://ippportainer.probolsas.co`
   - Ve a "Stacks" en el menú lateral
   - Encuentra tu stack `probolsas_crm_v2`
   - Haz clic en "Pull and redeploy" o similar
   - **IMPORTANTE**: Asegúrate de marcar la opción "Force rebuild" si está disponible
   - Confirma la acción

3. **Verifica el despliegue**:
   - Después de actualizar el stack, verifica los logs en Portainer
   - Accede a la aplicación en `https://ippcrm.probolsas.co`
   - Si es necesario, ejecuta el script de diagnóstico que creamos anteriormente

## Si el Problema Persiste

Si después de estos cambios sigues teniendo problemas, considera estas opciones:

1. **Construir y subir la imagen manualmente**:
   ```bash
   # Construir la imagen localmente
   docker build -t pedroconda/crm-probolsas:latest .
   
   # Iniciar sesión en Docker Hub
   docker login
   
   # Subir la imagen
   docker push pedroconda/crm-probolsas:latest
   ```

2. **Modificar el docker-compose.yml para usar una imagen diferente**:
   ```yaml
   image: node:18  # Usar una imagen oficial de Node.js
   volumes:
     - ./dist:/app/dist
     - ./server.js:/app/server.js
     - ./package.json:/app/package.json
   ```

3. **Eliminar el stack y crearlo de nuevo**:
   - Elimina completamente el stack en Portainer
   - Crea un nuevo stack con la misma configuración
   - Esto puede ayudar a resolver problemas de caché o configuración incorrecta

## Explicación Técnica

Cuando especificas una imagen en docker-compose.yml sin un tag específico (como `pedroconda/crm-probolsas`), Docker intentará:

1. Primero, buscar la imagen localmente
2. Si no la encuentra localmente, intentará descargarla de Docker Hub con el tag `:latest`
3. Si la imagen con el tag `:latest` no existe, intentará descargar la imagen base sin tag

En tu caso, la imagen `pedroconda/crm-probolsas` existe en Docker Hub (como vimos en la búsqueda), pero la imagen con el tag específico `:debug` no existe. Al eliminar el tag específico, Docker podrá encontrar y usar la imagen correcta.
