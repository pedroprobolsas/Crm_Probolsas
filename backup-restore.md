# Backup y Restauración

Este documento proporciona instrucciones para realizar backups y restaurar la aplicación CRM Probolsas y la configuración de Portainer.

## Backup de Portainer

### Backup de la Configuración de Portainer

Portainer almacena su configuración en un volumen de Docker. Para realizar un backup de esta configuración:

1. Identifica el volumen de Portainer:
   ```bash
   docker volume ls | grep portainer
   ```

2. Crea un backup del volumen:
   ```bash
   docker run --rm -v portainer_data:/data -v $(pwd):/backup alpine tar -czf /backup/portainer_data_$(date +%Y%m%d).tar.gz /data
   ```

   Esto creará un archivo tar.gz con la fecha actual en el directorio actual.

### Backup de los Stacks de Portainer

Los stacks de Portainer se pueden exportar desde la interfaz web:

1. Accede a la interfaz web de Portainer
2. Ve a "Stacks" en el menú lateral
3. Selecciona el stack "crm-probolsas"
4. Haz clic en "Export stack" para descargar un archivo YAML con la configuración del stack

## Backup de Traefik

### Backup de los Certificados SSL

Si estás utilizando Traefik para gestionar los certificados SSL, es importante hacer un backup de estos:

1. Identifica el volumen de Traefik:
   ```bash
   docker volume ls | grep traefik
   ```

2. Crea un backup del volumen:
   ```bash
   docker run --rm -v traefik-data:/data -v $(pwd):/backup alpine tar -czf /backup/traefik_data_$(date +%Y%m%d).tar.gz /data
   ```

## Backup de la Aplicación

La aplicación CRM Probolsas es stateless (sin estado), lo que significa que no almacena datos localmente. Todos los datos se almacenan en Supabase. Sin embargo, es importante hacer un backup de:

1. El código fuente y la configuración de Docker:
   ```bash
   git clone https://github.com/pedroprobolsas/Crm_Probolsas.git
   cd Crm_Probolsas
   git bundle create crm_probolsas_$(date +%Y%m%d).bundle --all
   ```

2. Las variables de entorno:
   ```bash
   cp .env.production .env.production.backup_$(date +%Y%m%d)
   ```

## Backup de Supabase

Los datos de la aplicación se almacenan en Supabase. Para hacer un backup de estos datos:

1. Accede al panel de control de Supabase: https://app.supabase.io
2. Selecciona tu proyecto
3. Ve a "Database" > "Backups"
4. Haz clic en "Create backup" para crear un backup manual
5. Descarga el backup una vez completado

## Scripts de Backup y Restauración

Este repositorio incluye scripts para automatizar el proceso de backup y restauración:

### Script de Backup (backup.sh)

El script `backup.sh` realiza backups automáticos de:
- Configuración de Portainer
- Configuración de Traefik (certificados SSL)
- Código fuente del repositorio
- Variables de entorno

**Uso:**
```bash
# Hacer el script ejecutable (solo la primera vez)
chmod +x backup.sh

# Ejecutar el script (los backups se guardarán en ./backups por defecto)
./backup.sh

# O especificar un directorio personalizado
./backup.sh /path/to/backup/directory
```

**Programación con cron:**
```bash
# Editar crontab
crontab -e

# Añadir esta línea para ejecutar el script todos los días a las 2 AM
0 2 * * * /path/to/backup.sh >> /path/to/backup.log 2>&1
```

### Script de Restauración (restore.sh)

El script `restore.sh` permite restaurar desde los backups creados por `backup.sh`:

**Uso:**
```bash
# Hacer el script ejecutable (solo la primera vez)
chmod +x restore.sh

# Ejecutar el script especificando el directorio de backup y la fecha
./restore.sh ./backups 20250411
```

El script te guiará a través del proceso de restauración, permitiéndote elegir qué componentes restaurar:
- Configuración de Portainer
- Configuración de Traefik
- Código fuente y variables de entorno

## Restauración

### Restaurar la Configuración de Portainer

1. Detén el contenedor de Portainer:
   ```bash
   docker stop portainer
   ```

2. Elimina el volumen de Portainer (¡cuidado, esto eliminará toda la configuración actual!):
   ```bash
   docker volume rm portainer_data
   ```

3. Crea un nuevo volumen:
   ```bash
   docker volume create portainer_data
   ```

4. Restaura el backup:
   ```bash
   docker run --rm -v portainer_data:/data -v $(pwd):/backup alpine sh -c "cd /data && tar -xzf /backup/portainer_data_YYYYMMDD.tar.gz --strip 1"
   ```

   Reemplaza `YYYYMMDD` con la fecha del backup que deseas restaurar.

5. Inicia Portainer:
   ```bash
   docker start portainer
   ```

### Restaurar Traefik

1. Detén el contenedor de Traefik:
   ```bash
   docker stop traefik
   ```

2. Elimina el volumen de Traefik:
   ```bash
   docker volume rm traefik-data
   ```

3. Crea un nuevo volumen:
   ```bash
   docker volume create traefik-data
   ```

4. Restaura el backup:
   ```bash
   docker run --rm -v traefik-data:/data -v $(pwd):/backup alpine sh -c "cd /data && tar -xzf /backup/traefik_data_YYYYMMDD.tar.gz --strip 1"
   ```

   Reemplaza `YYYYMMDD` con la fecha del backup que deseas restaurar.

5. Inicia Traefik:
   ```bash
   docker start traefik
   ```

### Restaurar la Aplicación

1. Clona el repositorio:
   ```bash
   git clone https://github.com/pedroprobolsas/Crm_Probolsas.git
   cd Crm_Probolsas
   ```

2. Restaura las variables de entorno:
   ```bash
   cp /path/to/backup/.env.production.backup_YYYYMMDD .env.production
   ```

   Reemplaza `YYYYMMDD` con la fecha del backup que deseas restaurar.

3. Despliega el stack en Portainer siguiendo las instrucciones en el archivo README.md

### Restaurar Supabase

Para restaurar los datos de Supabase:

1. Accede al panel de control de Supabase: https://app.supabase.io
2. Selecciona tu proyecto
3. Ve a "Database" > "Backups"
4. Selecciona el backup que deseas restaurar
5. Haz clic en "Restore" y sigue las instrucciones

## Pruebas de Restauración

Es importante probar regularmente el proceso de restauración para asegurarte de que los backups son válidos y que puedes restaurar el sistema en caso de fallo. Se recomienda realizar pruebas de restauración al menos una vez al mes.

## Notas Adicionales

- Almacena los backups en múltiples ubicaciones (local, nube, etc.)
- Documenta el proceso de restauración y asegúrate de que varias personas tengan acceso a esta documentación
- Considera implementar una solución de monitoreo que alerte si los backups fallan
- Revisa regularmente los logs de los backups para asegurarte de que se están realizando correctamente
