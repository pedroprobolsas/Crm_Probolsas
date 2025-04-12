#!/bin/bash
#
# Script de backup automático para CRM Probolsas
# Este script realiza backups de Portainer, Traefik, código fuente y variables de entorno
# 
# Uso: ./backup.sh [directorio_destino]
# Si no se especifica un directorio de destino, se usará el directorio actual
#
# Autor: Cline
# Fecha: 11/04/2025

# Directorio donde se guardarán los backups
BACKUP_DIR="${1:-$(pwd)/backups}"
DATE=$(date +%Y%m%d)
BACKUP_LOG="$BACKUP_DIR/backup_$DATE.log"

# Función para registrar mensajes en el log
log() {
  echo "[$(date +"%Y-%m-%d %H:%M:%S")] $1" | tee -a "$BACKUP_LOG"
}

# Crear directorio de backup si no existe
mkdir -p "$BACKUP_DIR"
log "Iniciando backup en $BACKUP_DIR"

# Verificar si Docker está en ejecución
if ! docker info > /dev/null 2>&1; then
  log "ERROR: Docker no está en ejecución. Abortando."
  exit 1
fi

# Backup de Portainer
log "Realizando backup de Portainer..."
if docker volume ls | grep -q portainer_data; then
  docker run --rm -v portainer_data:/data -v "$BACKUP_DIR":/backup alpine tar -czf "/backup/portainer_data_$DATE.tar.gz" /data
  if [ $? -eq 0 ]; then
    log "Backup de Portainer completado: portainer_data_$DATE.tar.gz"
  else
    log "ERROR: Falló el backup de Portainer"
  fi
else
  log "ADVERTENCIA: No se encontró el volumen portainer_data"
fi

# Backup de Traefik
log "Realizando backup de Traefik..."
if docker volume ls | grep -q traefik-data; then
  docker run --rm -v traefik-data:/data -v "$BACKUP_DIR":/backup alpine tar -czf "/backup/traefik_data_$DATE.tar.gz" /data
  if [ $? -eq 0 ]; then
    log "Backup de Traefik completado: traefik_data_$DATE.tar.gz"
  else
    log "ERROR: Falló el backup de Traefik"
  fi
else
  log "ADVERTENCIA: No se encontró el volumen traefik-data"
fi

# Backup del código fuente
log "Realizando backup del código fuente..."
REPO_DIR="$BACKUP_DIR/repo_temp"
mkdir -p "$REPO_DIR"

if [ -d "$REPO_DIR/.git" ]; then
  # Si ya existe el repositorio, actualizarlo
  cd "$REPO_DIR"
  git pull
  if [ $? -ne 0 ]; then
    log "ERROR: Falló la actualización del repositorio"
    # Intentar clonar de nuevo
    cd ..
    rm -rf "$REPO_DIR"
    git clone https://github.com/pedroprobolsas/Crm_Probolsas.git "$REPO_DIR"
  fi
else
  # Si no existe, clonar el repositorio
  git clone https://github.com/pedroprobolsas/Crm_Probolsas.git "$REPO_DIR"
  if [ $? -ne 0 ]; then
    log "ERROR: Falló la clonación del repositorio"
  fi
fi

# Crear un bundle del repositorio
if [ -d "$REPO_DIR/.git" ]; then
  cd "$REPO_DIR"
  git bundle create "$BACKUP_DIR/crm_probolsas_$DATE.bundle" --all
  if [ $? -eq 0 ]; then
    log "Backup del código fuente completado: crm_probolsas_$DATE.bundle"
  else
    log "ERROR: Falló la creación del bundle del repositorio"
  fi
  
  # Backup de las variables de entorno
  if [ -f ".env.production" ]; then
    cp .env.production "$BACKUP_DIR/.env.production.backup_$DATE"
    log "Backup de variables de entorno completado: .env.production.backup_$DATE"
  else
    log "ADVERTENCIA: No se encontró el archivo .env.production"
  fi
else
  log "ERROR: No se pudo acceder al repositorio para el backup"
fi

# Eliminar backups antiguos (más de 30 días)
log "Eliminando backups antiguos (más de 30 días)..."
find "$BACKUP_DIR" -name "*.tar.gz" -type f -mtime +30 -delete
find "$BACKUP_DIR" -name "*.bundle" -type f -mtime +30 -delete
find "$BACKUP_DIR" -name ".env.production.backup_*" -type f -mtime +30 -delete
find "$BACKUP_DIR" -name "backup_*.log" -type f -mtime +30 -delete

# Resumen
TOTAL_SIZE=$(du -sh "$BACKUP_DIR" | cut -f1)
log "Backup completado. Tamaño total de backups: $TOTAL_SIZE"
log "Archivos de backup:"
ls -la "$BACKUP_DIR" | grep "$DATE" | tee -a "$BACKUP_LOG"

echo ""
echo "Backup completado exitosamente."
echo "Los archivos de backup se encuentran en: $BACKUP_DIR"
echo "Consulta el log para más detalles: $BACKUP_LOG"
