# Instrucciones para Depurar y Solucionar el Despliegue en Portainer

Este documento proporciona instrucciones detalladas para depurar y solucionar los problemas con el despliegue de la aplicación CRM Probolsas en Portainer.

## Cambios Realizados

Hemos realizado los siguientes cambios para facilitar la depuración:

1. **Modificado el Dockerfile**:
   - Cambiado de `node:18-alpine` a `node:18` (imagen completa)
   - Añadidas herramientas de diagnóstico (curl, procps, net-tools)
   - Añadidos comandos para verificar el contenido del directorio
   - Eliminado el CMD para definirlo en docker-compose.yml

2. **Modificado el docker-compose.yml**:
   - Cambiado el tag de la imagen a `:debug` para forzar reconstrucción
   - Añadido comando de depuración que muestra más información
   - Configurada política de reinicio para intentos limitados
   - Configurado logging para guardar logs

3. **Creado script de diagnóstico**:
   - `diagnostico-contenedor.sh` para analizar problemas con el contenedor

## Pasos para Depurar y Solucionar

### 1. Subir los Cambios al Repositorio

Primero, sube los cambios al repositorio Git:

```bash
git add Dockerfile docker-compose.yml diagnostico-contenedor.sh
git commit -m "Añadir configuración de depuración para Portainer"
git push origin main  # O la rama que estés utilizando
```

### 2. Eliminar el Stack Actual (Opcional)

Si el stack actual está en un estado inconsistente, puede ser mejor eliminarlo y recrearlo:

1. En Portainer, ve a "Stacks"
2. Encuentra el stack `probolsas_crm_v2`
3. Haz clic en "Delete this stack" o similar
4. Confirma la acción

### 3. Crear un Nuevo Stack o Actualizar el Existente

#### Si eliminaste el stack:

1. En Portainer, ve a "Stacks"
2. Haz clic en "Add stack"
3. Completa la información:
   - **Name**: `probolsas_crm_v2` (o el nombre que prefieras)
   - **Build method**: Selecciona "Git repository"
   - **Repository URL**: `https://github.com/pedroprobolsas/Crm_Probolsas.git`
   - **Repository reference**: `main` (o la rama que estés usando)
   - **Compose path**: `docker-compose.yml`
4. Haz clic en "Deploy the stack"

#### Si no eliminaste el stack:

1. En Portainer, ve a "Stacks"
2. Encuentra el stack `probolsas_crm_v2`
3. Haz clic en "Pull and redeploy" o similar
4. Asegúrate de marcar la opción "Force rebuild" si está disponible
5. Confirma la acción

### 4. Verificar los Logs

Después de desplegar el stack:

1. En Portainer, ve a la página del stack
2. Haz clic en el servicio `crm-app`
3. Ve a la pestaña "Logs"
4. Busca mensajes de error o información de diagnóstico

### 5. Ejecutar el Script de Diagnóstico

Si sigues teniendo problemas, copia el script `diagnostico-contenedor.sh` al servidor y ejecútalo:

```bash
chmod +x diagnostico-contenedor.sh
./diagnostico-contenedor.sh
```

Este script proporcionará información detallada sobre el estado del contenedor y posibles problemas.

## Problemas Comunes y Soluciones

### Problema: El Contenedor No Se Inicia

**Posibles causas y soluciones**:

1. **Falta el directorio dist/**:
   - Verifica que el directorio dist/ exista y contenga los archivos de la aplicación
   - Ejecuta `npm run build` localmente y asegúrate de que se genere el directorio dist/

2. **Falta el archivo server.js**:
   - Verifica que el archivo server.js esté presente en el repositorio
   - Asegúrate de que el archivo server.js sea correcto y utilice la sintaxis de módulos ES

3. **Problema con las variables de entorno**:
   - Verifica que el archivo .env.production contenga las variables necesarias
   - Asegúrate de que las variables de entorno sean correctas

### Problema: El Contenedor Se Inicia Pero No Responde

**Posibles causas y soluciones**:

1. **Problema con el puerto**:
   - Verifica que el puerto 3000 no esté siendo utilizado por otro servicio
   - Intenta cambiar el puerto en docker-compose.yml

2. **Problema con Traefik**:
   - Verifica que Traefik esté configurado correctamente
   - Asegúrate de que las etiquetas de Traefik en docker-compose.yml sean correctas

3. **Problema con la red**:
   - Verifica que la red probolsas exista y esté configurada correctamente
   - Asegúrate de que el contenedor esté conectado a la red probolsas

## Próximos Pasos

Si después de seguir estos pasos sigues teniendo problemas, considera:

1. **Simplificar aún más la configuración**:
   - Prueba con una imagen más simple como nginx:alpine
   - Elimina temporalmente la configuración de Traefik

2. **Verificar la configuración de Docker Swarm**:
   - Asegúrate de que Docker Swarm esté configurado correctamente
   - Verifica que el nodo donde se está desplegando el stack esté disponible

3. **Contactar a soporte**:
   - Si nada de lo anterior funciona, considera contactar a soporte técnico
