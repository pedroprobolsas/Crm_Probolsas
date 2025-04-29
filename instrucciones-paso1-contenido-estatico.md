# Paso 1: Añadir Contenido Estático Personalizado

Ahora que hemos confirmado que el despliegue básico funciona correctamente, vamos a dar el siguiente paso: añadir contenido estático personalizado. He modificado el docker-compose.yml para añadir un volumen que sirva la carpeta `dist/` como contenido estático.

## Cambios Realizados

1. **Modificado el docker-compose.yml**:
   - Añadido un volumen para montar la carpeta `dist/` como contenido estático en Nginx
   - La configuración sigue siendo simple y directa

## Cómo Funciona Esta Solución

Esta solución funciona de la siguiente manera:

1. Seguimos usando la imagen oficial de Nginx que ya sabemos que funciona correctamente.
2. Montamos la carpeta `dist/` de tu repositorio como contenido estático en la ruta `/usr/share/nginx/html` dentro del contenedor.
3. Nginx servirá automáticamente este contenido cuando se acceda a la aplicación.

## Pasos para Implementar

### 1. Asegúrate de tener la carpeta dist/ con contenido

Antes de desplegar, necesitas tener la carpeta `dist/` con los archivos compilados de tu aplicación. Si no la tienes, puedes intentar compilar la aplicación localmente:

```bash
# En tu máquina local (no en el servidor)
npm run build -- --skipLibCheck
```

O si eso falla, puedes crear una página HTML simple para probar:

```bash
mkdir -p dist
echo '<html><body><h1>Prueba de Contenido Estático</h1><p>Esta es una prueba de servir contenido estático desde la carpeta dist/</p></body></html>' > dist/index.html
```

### 2. Sube los cambios al repositorio

```bash
git add docker-compose.yml instrucciones-paso1-contenido-estatico.md dist/
git commit -m "Paso 1: Añadir contenido estático personalizado"
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
   - Deberías ver el contenido de tu carpeta `dist/` en lugar de la página de bienvenida predeterminada de Nginx

## Interpretación de los Resultados

### Si el despliegue es exitoso

Si el despliegue es exitoso y puedes ver el contenido de tu carpeta `dist/`, esto significa que:

1. Los volúmenes están funcionando correctamente en Docker Swarm
2. Tu carpeta `dist/` contiene los archivos correctos
3. Nginx está sirviendo correctamente el contenido estático

En este caso, podemos proceder al siguiente paso: cambiar a una imagen de Node.js y servir el contenido con Express.

### Si el despliegue falla

Si el despliegue falla o no puedes ver el contenido de tu carpeta `dist/`, esto podría indicar problemas con los volúmenes:

1. **Problema con la carpeta dist/**:
   - Asegúrate de que la carpeta `dist/` exista en tu repositorio
   - Asegúrate de que la carpeta `dist/` contenga al menos un archivo index.html
   - Verifica que la carpeta `dist/` tenga los permisos correctos

2. **Problema con los volúmenes en Docker Swarm**:
   - Verifica que Docker Swarm esté configurado para soportar volúmenes
   - Intenta usar un volumen nombrado en lugar de un bind mount

## Próximos Pasos

Si este paso funciona correctamente, procederemos al Paso 2: cambiar a una imagen de Node.js y servir el contenido con Express.
