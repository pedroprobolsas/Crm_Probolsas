# Solución: Despliegue sin Docker Hub

He implementado una solución que permite desplegar la aplicación en Portainer sin necesidad de usar Docker Hub. Esta solución evita los problemas de compilación TypeScript que estabas enfrentando.

## Cambios Realizados

1. **Modificado el Dockerfile**:
   - Simplificado para usar una imagen base más ligera (`node:18-slim`)
   - Eliminada la fase de compilación que estaba fallando
   - Configurado para usar un script de inicio con diagnóstico detallado
   - Instaladas solo las dependencias necesarias para servir archivos estáticos

2. **Modificado el docker-compose.yml**:
   - Eliminada la referencia a una imagen externa de Docker Hub
   - Configurado para construir la imagen localmente

3. **Creado server.js**:
   - Servidor Express simple para servir archivos estáticos
   - Incluye verificaciones y diagnóstico

4. **Creado start.sh**:
   - Script de inicio con verificaciones detalladas
   - Proporciona información de diagnóstico si algo sale mal

## Cómo Funciona Esta Solución

Esta solución funciona de la siguiente manera:

1. En lugar de intentar compilar la aplicación dentro del contenedor (lo que fallaba debido a errores de TypeScript), asumimos que ya tienes los archivos compilados en la carpeta `dist/`.

2. El contenedor simplemente sirve estos archivos estáticos usando un servidor Express, sin intentar compilar nada.

3. Si la carpeta `dist/` no existe o está vacía, el script de inicio mostrará un error claro.

## Pasos para Implementar

### 1. Asegúrate de tener los archivos compilados

Antes de desplegar, necesitas tener los archivos compilados en la carpeta `dist/`. Si no los tienes, puedes intentar compilarlos localmente:

```bash
# En tu máquina local (no en el servidor)
npm run build -- --skipLibCheck
```

O si eso falla, puedes intentar:

```bash
# Ignorar errores de TypeScript
npx tsc --noEmit false --skipLibCheck
npx vite build
```

### 2. Sube los cambios al repositorio

```bash
git add Dockerfile docker-compose.yml server.js start.sh
git commit -m "Implementar solución de despliegue sin Docker Hub"
git push origin main
```

### 3. Actualiza el stack en Portainer

1. Accede a Portainer en `https://ippportainer.probolsas.co`
2. Ve a "Stacks" en el menú lateral
3. Encuentra tu stack `probolsas_crm_v2`
4. Haz clic en "Pull and redeploy" o similar
5. **IMPORTANTE**: Asegúrate de marcar la opción "Force rebuild" si está disponible
6. Confirma la acción

### 4. Verifica el despliegue

1. Revisa los logs en Portainer para ver si hay errores
2. Accede a la aplicación en `https://ippcrm.probolsas.co`
3. Si es necesario, ejecuta el script de diagnóstico que creamos anteriormente

## Solución de Problemas

### Si el contenedor no se inicia

Verifica los logs en Portainer. El script de inicio (`start.sh`) proporcionará información detallada sobre lo que está fallando. Los problemas más comunes son:

1. **Falta la carpeta dist/**:
   - Asegúrate de que la carpeta `dist/` exista en tu repositorio
   - Si no existe, compila la aplicación localmente y súbela al repositorio

2. **La carpeta dist/ está vacía**:
   - Compila la aplicación localmente y asegúrate de que los archivos se generen correctamente
   - Verifica que los archivos compilados estén incluidos en el repositorio

3. **Faltan dependencias**:
   - Si el servidor necesita dependencias adicionales, modifica el Dockerfile para instalarlas

### Si el contenedor se inicia pero la aplicación no funciona

1. **Verifica los logs del servidor**:
   - El servidor Express registrará información útil en los logs

2. **Verifica la configuración de Traefik**:
   - Asegúrate de que Traefik esté configurado correctamente para enrutar el tráfico al contenedor

3. **Prueba acceder directamente al puerto 3000**:
   - Si Traefik no funciona, intenta acceder directamente al puerto 3000 del servidor

## Ventajas de Esta Solución

1. **Evita problemas de compilación**: No intentamos compilar la aplicación dentro del contenedor
2. **Diagnóstico detallado**: Los scripts proporcionan información detallada si algo sale mal
3. **No requiere Docker Hub**: Todo se construye localmente en el servidor
4. **Simplicidad**: El contenedor solo tiene una responsabilidad: servir archivos estáticos
