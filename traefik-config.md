# Configuración de Traefik para CRM Probolsas

Este documento proporciona instrucciones para configurar Traefik como proxy inverso para la aplicación CRM Probolsas. Si ya tienes Traefik configurado en tu entorno Portainer, puedes omitir esta configuración.

## Configuración de Traefik en Portainer

Si no tienes Traefik configurado, puedes crear un nuevo stack en Portainer con la siguiente configuración:

```yaml
version: '3.8'

services:
  traefik:
    image: traefik:v2.10
    container_name: traefik
    restart: always
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro
      - traefik-data:/letsencrypt
    command:
      - "--api.insecure=false"
      - "--providers.docker=true"
      - "--providers.docker.exposedbydefault=false"
      - "--entrypoints.web.address=:80"
      - "--entrypoints.web.http.redirections.entryPoint.to=websecure"
      - "--entrypoints.web.http.redirections.entryPoint.scheme=https"
      - "--entrypoints.websecure.address=:443"
      - "--certificatesresolvers.letsencrypt.acme.httpchallenge=true"
      - "--certificatesresolvers.letsencrypt.acme.httpchallenge.entrypoint=web"
      - "--certificatesresolvers.letsencrypt.acme.email=tu@email.com"  # Cambia esto por tu email
      - "--certificatesresolvers.letsencrypt.acme.storage=/letsencrypt/acme.json"
    networks:
      - web
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.traefik-dashboard.rule=Host(`traefik.tudominio.com`)"  # Cambia esto por tu dominio para el dashboard
      - "traefik.http.routers.traefik-dashboard.service=api@internal"
      - "traefik.http.routers.traefik-dashboard.entrypoints=websecure"
      - "traefik.http.routers.traefik-dashboard.tls=true"
      - "traefik.http.routers.traefik-dashboard.tls.certresolver=letsencrypt"
      - "traefik.http.routers.traefik-dashboard.middlewares=traefik-auth"
      - "traefik.http.middlewares.traefik-auth.basicauth.users=admin:$$apr1$$xyz123$$hashed_password"  # Genera esto con htpasswd

networks:
  web:
    external: true

volumes:
  traefik-data:
```

## Pasos para la Configuración

1. **Crear la Red Docker**:
   ```bash
   docker network create web
   ```

2. **Generar Credenciales para el Dashboard** (opcional):
   ```bash
   htpasswd -nb admin tu_contraseña_segura
   ```
   Reemplaza el resultado en la configuración de `traefik.http.middlewares.traefik-auth.basicauth.users`.

3. **Personalizar la Configuración**:
   - Cambia `tu@email.com` por tu dirección de correo electrónico para las notificaciones de Let's Encrypt
   - Cambia `traefik.tudominio.com` por el dominio que deseas usar para el dashboard de Traefik
   - Actualiza las credenciales de autenticación básica

4. **Desplegar el Stack**:
   - Crea un nuevo stack en Portainer
   - Nombra el stack como "traefik"
   - Pega la configuración YAML
   - Haz clic en "Deploy the stack"

## Verificación

Una vez desplegado, verifica que Traefik esté funcionando correctamente:

1. Accede al dashboard de Traefik en `https://traefik.tudominio.com` (si configuraste el acceso al dashboard)
2. Verifica que los certificados SSL se estén generando correctamente
3. Comprueba que los puertos 80 y 443 estén abiertos y accesibles

## Integración con CRM Probolsas

Una vez que Traefik esté configurado, el stack de CRM Probolsas se integrará automáticamente con Traefik a través de las etiquetas (labels) definidas en el archivo `docker-compose.yml`.

## Solución de Problemas

Si encuentras problemas con la configuración de Traefik:

1. Verifica los logs de Traefik para identificar errores:
   ```bash
   docker logs traefik
   ```

2. Asegúrate de que los puertos 80 y 443 no estén siendo utilizados por otros servicios

3. Verifica que el dominio ippcrm.probolsas.co esté correctamente configurado en DNS y apunte a la IP de tu servidor
