 # Solución al Error "Missing script: start"

Este documento proporciona instrucciones detalladas para resolver el error "Missing script: start" que estás experimentando en el VPS.

## El Problema

El error "Missing script: start" ocurre cuando:

1. Intentas ejecutar `npm start` en un directorio donde no existe el archivo package.json
2. O el archivo package.json existe pero no tiene definido un script "start"

## Diagnóstico

He creado un script de diagnóstico que te ayudará a identificar la causa exacta del problema:

```bash
# Dar permisos de ejecución al script
chmod +x diagnostico-npm-start.sh

# Ejecutar el script
./diagnostico-npm-start.sh
```

Este script verificará:
- Si el archivo package.json existe en el directorio actual
- Si el script "start" está definido en package.json
- Si el archivo server.js existe
- Si las dependencias están instaladas (node_modules)

## Soluciones

### Solución 1: Ejecutar la Aplicación Directamente con Node.js

En lugar de usar `npm start`, puedes ejecutar la aplicación directamente con Node.js:

```bash
# Dar permisos de ejecución al script
chmod +x iniciar-app.sh

# Ejecutar el script
./iniciar-app.sh
```

Este script:
- Busca el archivo server.js si no está en el directorio actual
- Crea un directorio dist/ con un archivo index.html básico si no existe
- Instala las dependencias mínimas necesarias si no están instaladas
- Inicia la aplicación con `node server.js`

### Solución 2: Navegar al Directorio Correcto

Es posible que estés intentando ejecutar `npm start` en el directorio equivocado. Asegúrate de estar en el directorio raíz del proyecto donde se encuentra el archivo package.json:

```bash
# Buscar el archivo package.json
find / -name "package.json" 2>/dev/null | grep -v "node_modules"

# Navegar al directorio que contiene package.json
cd /ruta/al/directorio/con/package.json
```

### Solución 3: Usar Docker/Portainer (Recomendada)

La solución más robusta es usar Docker/Portainer como estaba previsto originalmente:

1. Asegúrate de que el docker-compose.yml esté configurado correctamente:
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

2. Despliega la aplicación a través de Portainer:
   - Accede a Portainer en `https://ippportainer.probolsas.co`
   - Ve a "Stacks" en el menú lateral
   - Encuentra tu stack `probolsas_crm_v2`
   - Haz clic en "Pull and redeploy"
   - Confirma la acción

3. Verifica el despliegue:
   ```bash
   chmod +x verificar-despliegue-portainer.sh
   ./verificar-despliegue-portainer.sh
   ```

## Importante: No Ejecutes npm start Manualmente

Si estás usando Docker/Portainer, **no necesitas ejecutar `npm start` manualmente**. El contenedor ya tiene configurado cómo iniciar la aplicación. Ejecutar `npm start` manualmente solo es necesario si estás desarrollando localmente o si quieres ejecutar la aplicación directamente en el VPS sin Docker.

## Verificación

Para verificar que la aplicación está funcionando correctamente:

1. Accede a la aplicación en `https://ippcrm.probolsas.co`
2. Verifica los logs del contenedor en Portainer
3. Si estás ejecutando la aplicación directamente (sin Docker), verifica que el servidor esté escuchando en el puerto 3000:
   ```bash
   netstat -tuln | grep 3000
   ```

## Contacto para Soporte

Si continúas teniendo problemas después de seguir estas instrucciones, contacta al equipo de soporte con la siguiente información:
- La salida del script de diagnóstico
- Los logs del contenedor en Portainer
- Cualquier otro mensaje de error que estés viendo
