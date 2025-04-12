# Monitoreo de la Aplicación CRM Probolsas

Este documento proporciona información sobre cómo monitorear la salud y el rendimiento de la aplicación CRM Probolsas desplegada en Portainer.

## Health Checks

La aplicación y Traefik están configurados con health checks que permiten a Docker y Portainer monitorear automáticamente el estado de los contenedores.

### Health Check de la Aplicación

El health check de la aplicación utiliza el script `health-check.js` para verificar que el servidor web esté respondiendo correctamente. Este script realiza una solicitud HTTP al servidor y verifica que la respuesta tenga un código de estado 2xx.

Configuración en el Dockerfile:
```dockerfile
HEALTHCHECK --interval=30s --timeout=5s --start-period=30s --retries=3 \
  CMD node health-check.js || exit 1
```

Configuración en docker-compose.yml:
```yaml
healthcheck:
  test: ["CMD", "node", "health-check.js"]
  interval: 30s
  timeout: 5s
  retries: 3
  start_period: 30s
```

### Health Check de Traefik

Traefik está configurado con su propio health check que verifica que el servicio esté funcionando correctamente. Este health check utiliza el endpoint `/ping` de Traefik.

Configuración en docker-compose.traefik.yml:
```yaml
healthcheck:
  test: ["CMD", "wget", "--no-verbose", "--spider", "http://localhost:8080/ping"]
  interval: 30s
  timeout: 5s
  retries: 3
  start_period: 30s
```

## Monitoreo en Portainer

Portainer proporciona varias herramientas para monitorear los contenedores:

### Dashboard de Contenedores

1. Accede a la interfaz web de Portainer
2. Ve a "Containers" en el menú lateral
3. Verifica el estado de los contenedores (verde = saludable, rojo = no saludable)

### Logs de Contenedores

1. Accede a la interfaz web de Portainer
2. Ve a "Containers" en el menú lateral
3. Haz clic en el nombre del contenedor que deseas monitorear
4. Haz clic en la pestaña "Logs" para ver los logs del contenedor en tiempo real

### Estadísticas de Contenedores

1. Accede a la interfaz web de Portainer
2. Ve a "Containers" en el menú lateral
3. Haz clic en el nombre del contenedor que deseas monitorear
4. Haz clic en la pestaña "Stats" para ver las estadísticas de uso de recursos del contenedor

## Monitoreo Avanzado

Para un monitoreo más avanzado, considera implementar alguna de las siguientes soluciones:

### Prometheus y Grafana

Prometheus es un sistema de monitoreo de código abierto que puede recopilar métricas de tus contenedores y servicios. Grafana es una plataforma de visualización que puede mostrar estas métricas en dashboards personalizables.

1. Configura Prometheus para recopilar métricas de Docker y Traefik
2. Configura Grafana para visualizar estas métricas
3. Crea dashboards personalizados para monitorear la salud y el rendimiento de la aplicación

### Alertas

Configura alertas para recibir notificaciones cuando ocurran problemas:

1. En Portainer, ve a "Settings" > "Notifications"
2. Configura los canales de notificación (email, Slack, etc.)
3. Configura las reglas de alerta para recibir notificaciones cuando los contenedores no estén saludables

## Solución de Problemas

Si los health checks fallan, sigue estos pasos para solucionar el problema:

### Aplicación CRM

1. Verifica los logs de la aplicación:
   ```bash
   docker logs crm-probolsas_crm-app_1
   ```

2. Verifica que la aplicación esté escuchando en el puerto correcto:
   ```bash
   docker exec crm-probolsas_crm-app_1 netstat -tulpn | grep 3000
   ```

3. Ejecuta el health check manualmente:
   ```bash
   docker exec crm-probolsas_crm-app_1 node health-check.js
   ```

### Traefik

1. Verifica los logs de Traefik:
   ```bash
   docker logs traefik
   ```

2. Verifica que Traefik esté escuchando en los puertos correctos:
   ```bash
   docker exec traefik netstat -tulpn | grep -E '80|443'
   ```

3. Verifica que los certificados SSL se hayan generado correctamente:
   ```bash
   docker exec traefik ls -la /letsencrypt/acme.json
   ```

## Mantenimiento Preventivo

Para evitar problemas, realiza las siguientes tareas de mantenimiento preventivo:

1. Monitorea regularmente el uso de recursos (CPU, memoria, disco) de los contenedores
2. Configura alertas para recibir notificaciones cuando el uso de recursos sea alto
3. Realiza backups regulares de la configuración de Portainer y los datos de la aplicación
4. Mantén actualizada la imagen de Docker de la aplicación y Traefik
5. Revisa regularmente los logs de la aplicación y Traefik para identificar posibles problemas
