# CRM Probolsas - Despliegue en Portainer

Este repositorio contiene la configuración necesaria para desplegar la aplicación CRM Probolsas en Portainer con auto-actualización y configuración de dominio.

## Requisitos Previos

- Portainer instalado y configurado
- Dominio ippcrm.probolsas.co configurado para apuntar al servidor
- Acceso a GitHub para configurar webhooks
- Traefik configurado como proxy inverso (opcional, se incluye configuración alternativa)

## Archivos de Configuración

- `Dockerfile`: Define cómo se construye la imagen Docker de la aplicación
- `docker-compose.yml`: Define el stack de Portainer con la configuración necesaria (asume Traefik ya configurado)
- `docker-compose.traefik.yml`: Configuración alternativa que incluye Traefik en el mismo stack
- `.dockerignore`: Define qué archivos se excluyen del contexto de construcción de Docker
- `.env.example`: Plantilla para las variables de entorno necesarias
- `.github/workflows/docker-build.yml`: Configuración de GitHub Actions para probar la construcción de la imagen

## Opciones de Despliegue

Tienes dos opciones para desplegar la aplicación:

### Opción 1: Usando Traefik Existente

Si ya tienes Traefik configurado en tu entorno, puedes usar el archivo `docker-compose.yml` para desplegar solo la aplicación.

### Opción 2: Despliegue Completo con Traefik

Si no tienes Traefik configurado, puedes usar el archivo `docker-compose.traefik.yml` para desplegar tanto la aplicación como Traefik en un solo stack.

## Pasos para el Despliegue

### 1. Preparación

1. Asegúrate de que el dominio ippcrm.probolsas.co apunte a la IP de tu servidor
2. Si vas a usar la Opción 1, verifica que Traefik esté correctamente configurado
3. Si vas a usar la Opción 2, asegúrate de que los puertos 80 y 443 estén disponibles

### 2. Desplegar el Stack en Portainer

1. Accede a la interfaz web de Portainer
2. Ve a "Stacks" y haz clic en "Add stack"
3. Selecciona "Git Repository" como método de despliegue
4. Ingresa la siguiente información:
   - Repository URL: `https://github.com/pedroprobolsas/Crm_Probolsas.git`
   - Repository reference: `main` (o la rama que desees usar)
   - Compose path: `docker-compose.yml` (o `docker-compose.traefik.yml` si eliges la Opción 2)
5. En la sección "Auto update", marca la casilla "Enable automatic updates"
6. Configura las opciones de actualización:
   - Webhook: Marca la casilla "Webhook"
   - Redeploy: Selecciona "Always"
7. Haz clic en "Deploy the stack"

### 3. Configurar el Webhook en GitHub

1. Una vez creado el stack, ve a la página de detalles del stack
2. Haz clic en la pestaña "Webhooks" y copia la URL del webhook
3. Ve a tu repositorio en GitHub: `https://github.com/pedroprobolsas/Crm_Probolsas`
4. Ve a "Settings" > "Webhooks"
5. Haz clic en "Add webhook"
6. Ingresa la siguiente información:
   - Payload URL: [URL del webhook de Portainer]
   - Content type: `application/json`
   - Secret: [Deja en blanco]
   - Selecciona "Just the push event"
7. Haz clic en "Add webhook"

Para instrucciones más detalladas sobre la configuración del webhook, consulta el archivo `portainer-webhook-setup.md`.

## Funcionamiento de la Auto-actualización

Cada vez que se realice un push al repositorio, GitHub activará el webhook de Portainer, lo que desencadenará una actualización automática del stack. Portainer realizará los siguientes pasos:

1. Extraer los cambios más recientes del repositorio
2. Reconstruir la imagen Docker si es necesario
3. Actualizar el stack con la nueva configuración

## Acceso a la Aplicación

Una vez desplegada, la aplicación estará disponible en:

```
https://ippcrm.probolsas.co
```

## Documentación Adicional

Este repositorio incluye documentación adicional para ayudarte con el despliegue:

- `deployment-checklist.md`: Lista de verificación para asegurarte de completar todos los pasos necesarios
- `traefik-config.md`: Instrucciones detalladas para configurar Traefik si decides instalarlo por separado
- `portainer-webhook-setup.md`: Guía paso a paso para configurar el webhook de Portainer y GitHub
- `monitoring.md`: Información sobre cómo monitorear la salud y el rendimiento de la aplicación
- `backup-restore.md`: Instrucciones para realizar backups y restaurar la aplicación y configuración

## Solución de Problemas

Si encuentras problemas durante el despliegue, verifica:

1. Que Traefik esté correctamente configurado y funcionando
2. Que el dominio ippcrm.probolsas.co esté correctamente configurado en DNS
3. Que los puertos necesarios (80, 443) estén abiertos en el firewall
4. Los logs de Portainer y Docker para identificar posibles errores

Para una lista completa de verificaciones, consulta el archivo `deployment-checklist.md`.
