# Configuración de Webhook para Auto-actualización en Portainer

Este documento proporciona instrucciones detalladas para configurar el webhook de Portainer y conectarlo con GitHub para habilitar la auto-actualización del stack CRM Probolsas.

## Configuración del Webhook en Portainer

### 1. Crear el Stack en Portainer

1. Accede a la interfaz web de Portainer
2. Ve a "Stacks" en el menú lateral
3. Haz clic en "Add stack"
4. Selecciona "Git Repository" como método de despliegue
5. Ingresa la siguiente información:
   - Name: `crm-probolsas` (o el nombre que prefieras)
   - Repository URL: `https://github.com/pedroprobolsas/Crm_Probolsas.git`
   - Repository reference: `main` (o la rama que desees usar)
   - Compose path: `docker-compose.yml`
   
   ![Portainer Stack Creation](https://i.imgur.com/example1.png)

6. En la sección "Auto update", marca la casilla "Enable automatic updates"
7. Configura las opciones de actualización según tus preferencias:
   - Webhook: Marca la casilla "Webhook"
   - Redeploy: Selecciona "Always" para siempre redesplegar el stack cuando se active el webhook
   
   ![Portainer Auto Update](https://i.imgur.com/example2.png)

8. Haz clic en "Deploy the stack"

### 2. Obtener la URL del Webhook

1. Una vez creado el stack, ve a la página de detalles del stack
2. Haz clic en la pestaña "Webhooks"
3. Copia la URL del webhook que se muestra
   
   ![Portainer Webhook URL](https://i.imgur.com/example3.png)

## Configuración del Webhook en GitHub

### 1. Acceder a la Configuración del Repositorio

1. Ve a tu repositorio en GitHub: `https://github.com/pedroprobolsas/Crm_Probolsas`
2. Haz clic en "Settings" en la barra de navegación superior
3. En el menú lateral, selecciona "Webhooks"
4. Haz clic en "Add webhook"
   
   ![GitHub Webhooks](https://i.imgur.com/example4.png)

### 2. Configurar el Webhook

1. Ingresa la siguiente información:
   - Payload URL: [Pega la URL del webhook de Portainer]
   - Content type: Selecciona `application/json`
   - Secret: Deja este campo en blanco (Portainer no requiere un secreto)
   - SSL verification: Deja habilitada esta opción si tu servidor Portainer tiene SSL válido
   
   ![GitHub Webhook Configuration](https://i.imgur.com/example5.png)

2. En la sección "Which events would you like to trigger this webhook?", selecciona:
   - "Just the push event" (solo eventos de push)
   
   ![GitHub Webhook Events](https://i.imgur.com/example6.png)

3. Asegúrate de que la opción "Active" esté marcada
4. Haz clic en "Add webhook"

## Verificación de la Configuración

### 1. Probar el Webhook

1. Realiza un pequeño cambio en tu repositorio y haz push a la rama configurada
2. Ve a la página de detalles del webhook en GitHub
3. Verifica que el webhook se haya activado correctamente (debería aparecer un check verde)
   
   ![GitHub Webhook Success](https://i.imgur.com/example7.png)

### 2. Verificar la Actualización en Portainer

1. Ve a la página de detalles del stack en Portainer
2. Verifica que el stack se haya actualizado automáticamente
3. Revisa los logs para confirmar que no hubo errores durante la actualización
   
   ![Portainer Stack Update](https://i.imgur.com/example8.png)

## Solución de Problemas

### Webhook no se Activa

1. Verifica que la URL del webhook sea correcta
2. Asegúrate de que el servidor Portainer sea accesible desde Internet
3. Revisa los logs de Portainer para identificar posibles errores

### Stack no se Actualiza

1. Verifica que el webhook se esté activando correctamente en GitHub
2. Asegúrate de que Portainer tenga acceso al repositorio Git
3. Revisa los logs del stack en Portainer para identificar posibles errores durante la actualización

### Errores de Autenticación

Si tu repositorio es privado:

1. Asegúrate de haber configurado las credenciales de acceso en Portainer
2. Verifica que las credenciales tengan permisos de lectura en el repositorio

## Notas Adicionales

- El webhook de Portainer solo actualiza el stack cuando se realiza un push al repositorio
- Si realizas cambios directamente en Portainer, estos pueden ser sobrescritos en la próxima actualización automática
- Considera configurar notificaciones en Portainer para recibir alertas sobre actualizaciones fallidas
