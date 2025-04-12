#!/bin/bash
#
# Script de restauración para CRM Probolsas
# Este script restaura backups de Portainer, Traefik, código fuente y variables de entorno
# 
# Uso: ./restore.sh [directorio_backup] [fecha_backup]
# Ejemplo: ./restore.sh ./backups 20250411
#
# Autor: Cline
# Fecha: 11/04/2025

# Verificar argumentos
if [ "$#" -lt 2 ]; then
  echo "Uso: $0 [directorio_backup] [fecha_backup]"
  echo "Ejemplo: $0 ./backups 20250411"
  exit 1
fi

BACKUP_DIR="$1"
DATE="$2"
RESTORE_LOG="$BACKUP_DIR/restore_$DATE.log"

# Función para registrar mensajes en el log
log() {
  echo "[$(date +"%Y-%m-%d %H:%M:%S")] $1" | tee -a "$RESTORE_LOG"
}

# Verificar si el directorio de backup existe
if [ ! -d "$BACKUP_DIR" ]; then
  echo "ERROR: El directorio de backup $BACKUP_DIR no existe."
  exit 1
fi

# Verificar si Docker está en ejecución
if ! docker info > /dev/null 2>&1; then
  echo "ERROR: Docker no está en ejecución. Abortando."
  exit 1
fi

# Iniciar log
log "Iniciando restauración desde $BACKUP_DIR con fecha $DATE"

# Función para confirmar acciones
confirm() {
  read -p "$1 [s/N]: " response
  case "$response" in
    [sS][iI]|[sS]) 
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

# Restaurar Portainer
PORTAINER_BACKUP="$BACKUP_DIR/portainer_data_$DATE.tar.gz"
if [ -f "$PORTAINER_BACKUP" ]; then
  if confirm "¿Deseas restaurar la configuración de Portainer?"; then
    log "Restaurando Portainer desde $PORTAINER_BACKUP"
    
    # Verificar si el contenedor de Portainer está en ejecución
    if docker ps | grep -q portainer; then
      log "Deteniendo contenedor de Portainer..."
      docker stop portainer
    fi
    
    # Eliminar volumen existente si existe
    if docker volume ls | grep -q portainer_data; then
      if confirm "ADVERTENCIA: Se eliminará el volumen portainer_data existente. ¿Continuar?"; then
        docker volume rm portainer_data
        docker volume create portainer_data
      else
        log "Restauración de Portainer cancelada por el usuario"
        exit 1
      fi
    else
      docker volume create portainer_data
    fi
    
    # Restaurar desde backup
    docker run --rm -v portainer_data:/data -v "$BACKUP_DIR":/backup alpine sh -c "cd /data && tar -xzf /backup/portainer_data_$DATE.tar.gz --strip 1"
    if [ $? -eq 0 ]; then
      log "Restauración de Portainer completada exitosamente"
    else
      log "ERROR: Falló la restauración de Portainer"
    fi
    
    # Iniciar Portainer si estaba en ejecución
    if docker ps -a | grep -q portainer; then
      log "Iniciando contenedor de Portainer..."
      docker start portainer
    fi
  else
    log "Restauración de Portainer omitida por el usuario"
  fi
else
  log "ADVERTENCIA: No se encontró el archivo de backup de Portainer $PORTAINER_BACKUP"
fi

# Restaurar Traefik
TRAEFIK_BACKUP="$BACKUP_DIR/traefik_data_$DATE.tar.gz"
if [ -f "$TRAEFIK_BACKUP" ]; then
  if confirm "¿Deseas restaurar la configuración de Traefik?"; then
    log "Restaurando Traefik desde $TRAEFIK_BACKUP"
    
    # Verificar si el contenedor de Traefik está en ejecución
    if docker ps | grep -q traefik; then
      log "Deteniendo contenedor de Traefik..."
      docker stop traefik
    fi
    
    # Eliminar volumen existente si existe
    if docker volume ls | grep -q traefik-data; then
      if confirm "ADVERTENCIA: Se eliminará el volumen traefik-data existente. ¿Continuar?"; then
        docker volume rm traefik-data
        docker volume create traefik-data
      else
        log "Restauración de Traefik cancelada por el usuario"
        exit 1
      fi
    else
      docker volume create traefik-data
    fi
    
    # Restaurar desde backup
    docker run --rm -v traefik-data:/data -v "$BACKUP_DIR":/backup alpine sh -c "cd /data && tar -xzf /backup/traefik_data_$DATE.tar.gz --strip 1"
    if [ $? -eq 0 ]; then
      log "Restauración de Traefik completada exitosamente"
    else
      log "ERROR: Falló la restauración de Traefik"
    fi
    
    # Iniciar Traefik si estaba en ejecución
    if docker ps -a | grep -q traefik; then
      log "Iniciando contenedor de Traefik..."
      docker start traefik
    fi
  else
    log "Restauración de Traefik omitida por el usuario"
  fi
else
  log "ADVERTENCIA: No se encontró el archivo de backup de Traefik $TRAEFIK_BACKUP"
fi

# Restaurar código fuente
REPO_BACKUP="$BACKUP_DIR/crm_probolsas_$DATE.bundle"
if [ -f "$REPO_BACKUP" ]; then
  if confirm "¿Deseas restaurar el código fuente?"; then
    log "Restaurando código fuente desde $REPO_BACKUP"
    
    # Crear directorio temporal para la restauración
    RESTORE_DIR="$BACKUP_DIR/restore_repo_$DATE"
    mkdir -p "$RESTORE_DIR"
    
    # Clonar desde el bundle
    cd "$RESTORE_DIR"
    git clone "$REPO_BACKUP" .
    if [ $? -eq 0 ]; then
      log "Restauración del código fuente completada exitosamente en $RESTORE_DIR"
      
      # Restaurar variables de entorno
      ENV_BACKUP="$BACKUP_DIR/.env.production.backup_$DATE"
      if [ -f "$ENV_BACKUP" ]; then
        cp "$ENV_BACKUP" "$RESTORE_DIR/.env.production"
        log "Variables de entorno restauradas desde $ENV_BACKUP"
      else
        log "ADVERTENCIA: No se encontró el archivo de backup de variables de entorno $ENV_BACKUP"
      fi
      
      # Preguntar si desea desplegar el stack restaurado
      if confirm "¿Deseas desplegar el stack restaurado en Portainer?"; then
        log "Para desplegar el stack restaurado, sigue estos pasos:"
        log "1. Accede a la interfaz web de Portainer"
        log "2. Ve a 'Stacks' y haz clic en 'Add stack'"
        log "3. Selecciona 'Upload' como método de despliegue"
        log "4. Sube el archivo docker-compose.yml desde $RESTORE_DIR"
        log "5. Configura las opciones según sea necesario"
        log "6. Haz clic en 'Deploy the stack'"
        
        echo ""
        echo "Para desplegar el stack restaurado, sigue estos pasos:"
        echo "1. Accede a la interfaz web de Portainer"
        echo "2. Ve a 'Stacks' y haz clic en 'Add stack'"
        echo "3. Selecciona 'Upload' como método de despliegue"
        echo "4. Sube el archivo docker-compose.yml desde $RESTORE_DIR"
        echo "5. Configura las opciones según sea necesario"
        echo "6. Haz clic en 'Deploy the stack'"
      fi
    else
      log "ERROR: Falló la restauración del código fuente"
    fi
  else
    log "Restauración del código fuente omitida por el usuario"
  fi
else
  log "ADVERTENCIA: No se encontró el archivo de backup del código fuente $REPO_BACKUP"
fi

# Resumen
log "Restauración completada"
echo ""
echo "Restauración completada."
echo "Consulta el log para más detalles: $RESTORE_LOG"
