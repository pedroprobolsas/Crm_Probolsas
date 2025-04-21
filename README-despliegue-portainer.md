# Guía de Despliegue en Portainer para CRM Probolsas

Esta guía proporciona instrucciones paso a paso para desplegar la aplicación CRM Probolsas en un VPS utilizando Portainer y Traefik.

## Requisitos Previos

- Portainer instalado y accesible en `https://ippportainer.probolsas.co`
- Traefik configurado como proxy inverso
- Red Docker `probolsas` creada
- Dominio `ippcrm.probolsas.co` configurado en DNS y apuntando al servidor

## Pasos para el Despliegue

### 1. Acceder a Portainer

1. Abre tu navegador y ve a `https://ippportainer.probolsas.co`
2. Inicia sesión con tus credenciales

### 2. Crear un Nuevo Stack

1. En el menú lateral, haz clic en "Stacks"
2. Haz clic en el botón "Add stack"
3. Completa la información:
   - **Name**: `crm-probolsas` (o el nombre que prefieras)
   - **Build method**: Selecciona "Git repository"
   - **Repository URL**: `https://github.com/pedroprobolsas/Crm_Probolsas.git`
   - **Repository reference**: `main` (o la rama que estés usando)
   - **Compose path**: `docker-compose.yml`

### 3. Configurar Actualizaciones Automáticas (Opcional)

1. En la sección "Auto update", marca la casilla "Enable automatic updates"
2. Selecciona "Webhook" para habilitar actualizaciones mediante webhook
3. Configura la frecuencia de actualización según tus preferencias

### 4. Configurar Variables de Entorno

Las variables de entorno ya están configuradas en el archivo `.env.production`, pero si necesitas añadir o modificar alguna:

1. En la sección "Environment variables", haz clic en "Add environment variable"
2. Añade las variables de entorno necesarias

### 5. Desplegar el Stack

1. Haz clic en el botón "Deploy the stack"
2. Espera a que Portainer clone el repositorio y despliegue los contenedores

### 6. Verificar el Despliegue

1. En Portainer, ve a la página del stack recién creado
2. Verifica que el estado sea "Running" (en ejecución)
3. Revisa los logs para asegurarte de que no haya errores
4. Accede a la aplicación en `https://ippcrm.probolsas.co`
5. Verifica que la aplicación se cargue correctamente y funcione como se espera

## Solución de Problemas

### El Contenedor no se Inicia

1. Revisa los logs en Portainer para identificar el error
2. Verifica que las variables de entorno estén correctamente configuradas
3. Asegúrate de que los puertos no estén siendo utilizados por otros servicios

### La Aplicación no es Accesible

1. Verifica que Traefik esté configurado correctamente
2. Comprueba que el dominio apunte a la IP correcta del servidor
3. Revisa las reglas de firewall para asegurarte de que los puertos 80 y 443 estén abiertos

### Errores de Conexión con Supabase

1. Verifica que las credenciales de Supabase sean correctas
2. Comprueba que la aplicación pueda conectarse a Supabase desde el servidor

## Mantenimiento

### Actualizaciones

Para actualizar la aplicación, simplemente haz push de los cambios al repositorio Git. Si has configurado el webhook, Portainer actualizará automáticamente el stack.

### Monitoreo

1. En Portainer, ve a la página del contenedor
2. Revisa la pestaña "Stats" para monitorear el uso de recursos
3. Configura alertas si es necesario

### Backups

Sigue las instrucciones en el archivo `backup-restore.md` para configurar backups periódicos de:
- Configuración de Portainer
- Datos de la aplicación
- Configuración de Traefik

## Notas Adicionales

- La aplicación utiliza un health check para monitorear su estado
- El contenedor se reiniciará automáticamente si el health check falla
- Los logs de la aplicación se pueden ver en Portainer
