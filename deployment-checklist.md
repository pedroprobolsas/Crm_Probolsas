# Lista de Verificación para Despliegue

Utiliza esta lista de verificación para asegurarte de completar todos los pasos necesarios para desplegar correctamente la aplicación CRM Probolsas en Portainer.

## Preparación

- [ ] Verificar que Portainer esté instalado y funcionando
- [ ] Verificar que el dominio ippcrm.probolsas.co esté configurado en DNS y apunte al servidor
- [ ] Verificar que los puertos 80 y 443 estén abiertos en el firewall
- [ ] Verificar que Traefik esté configurado como proxy inverso (o seguir las instrucciones en `traefik-config.md`)
- [ ] Verificar que la red Docker `web` exista (o crearla con `docker network create web`)

## Configuración del Repositorio

- [ ] Asegurarse de que todos los archivos de configuración estén en el repositorio:
  - [ ] Dockerfile
  - [ ] docker-compose.yml
  - [ ] .dockerignore
  - [ ] .env.example (y crear .env.production si es necesario)
  - [ ] .github/workflows/docker-build.yml
- [ ] Hacer push de los cambios al repositorio en GitHub

## Despliegue en Portainer

- [ ] Acceder a la interfaz web de Portainer
- [ ] Crear un nuevo stack:
  - [ ] Nombre: `crm-probolsas` (o el nombre que prefieras)
  - [ ] Método de despliegue: Git Repository
  - [ ] URL del repositorio: `https://github.com/pedroprobolsas/Crm_Probolsas.git`
  - [ ] Referencia del repositorio: `main` (o la rama que desees usar)
  - [ ] Ruta del archivo compose: `docker-compose.yml`
  - [ ] Habilitar actualizaciones automáticas y webhook
- [ ] Desplegar el stack
- [ ] Verificar que el stack se haya desplegado correctamente
- [ ] Obtener la URL del webhook de Portainer

## Configuración del Webhook en GitHub

- [ ] Acceder a la configuración del repositorio en GitHub
- [ ] Crear un nuevo webhook:
  - [ ] URL del payload: [URL del webhook de Portainer]
  - [ ] Tipo de contenido: `application/json`
  - [ ] Eventos: Solo eventos de push
  - [ ] Activar el webhook
- [ ] Verificar que el webhook se haya creado correctamente

## Verificación del Despliegue

- [ ] Acceder a la aplicación en `https://ippcrm.probolsas.co`
- [ ] Verificar que la aplicación funcione correctamente
- [ ] Verificar que el certificado SSL sea válido
- [ ] Realizar un pequeño cambio en el repositorio y hacer push para probar la auto-actualización
- [ ] Verificar que el stack se actualice automáticamente

## Monitoreo y Mantenimiento

- [ ] Verificar que los health checks estén funcionando correctamente
- [ ] Configurar notificaciones en Portainer para recibir alertas sobre actualizaciones fallidas
- [ ] Establecer un proceso para revisar regularmente los logs de la aplicación
- [ ] Documentar el proceso de despliegue y actualización para referencia futura
- [ ] Establecer un proceso de backup para la configuración de Portainer y los datos de la aplicación
- [ ] Revisar el documento `monitoring.md` para configurar monitoreo avanzado si es necesario
- [ ] Configurar backups automáticos siguiendo las instrucciones en `backup-restore.md`
- [ ] Programar pruebas regulares de restauración para verificar la integridad de los backups

## Notas Adicionales

- Recuerda que cualquier cambio realizado directamente en Portainer puede ser sobrescrito en la próxima actualización automática
- Si necesitas realizar cambios en la configuración, hazlos en el repositorio y haz push para que se apliquen automáticamente
- Considera configurar un sistema de monitoreo para la aplicación y el servidor
