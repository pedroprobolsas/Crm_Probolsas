# Cómo Ejecutar el Script de Diagnóstico

Este documento proporciona instrucciones paso a paso para transferir y ejecutar el script `diagnostico-contenedor.sh` en el servidor donde está instalado Portainer.

## Opción 1: Transferir el Script Usando SCP

Si tienes acceso SSH al servidor, puedes usar SCP para transferir el script:

1. **Abre una terminal en tu computadora local**

2. **Navega al directorio donde está el script**:
   ```bash
   cd c:/Proyectos/Crm_Probolsas
   ```

3. **Transfiere el script al servidor**:
   ```bash
   scp diagnostico-contenedor.sh usuario@ip-del-servidor:/ruta/destino/
   ```
   Reemplaza:
   - `usuario` con tu nombre de usuario en el servidor
   - `ip-del-servidor` con la dirección IP del servidor
   - `/ruta/destino/` con la ruta donde quieres guardar el script (por ejemplo, `/home/usuario/`)

4. **Conéctate al servidor por SSH**:
   ```bash
   ssh usuario@ip-del-servidor
   ```

5. **Navega al directorio donde guardaste el script**:
   ```bash
   cd /ruta/destino/
   ```

6. **Dale permisos de ejecución al script**:
   ```bash
   chmod +x diagnostico-contenedor.sh
   ```

7. **Ejecuta el script**:
   ```bash
   ./diagnostico-contenedor.sh
   ```

## Opción 2: Crear el Script Directamente en el Servidor

Si ya estás conectado al servidor por SSH, puedes crear el script directamente:

1. **Conéctate al servidor por SSH** (si aún no lo has hecho):
   ```bash
   ssh usuario@ip-del-servidor
   ```

2. **Crea un nuevo archivo**:
   ```bash
   nano diagnostico-contenedor.sh
   ```

3. **Copia y pega el contenido del script**:
   - Copia todo el contenido del archivo `diagnostico-contenedor.sh`
   - Pégalo en el editor nano
   - Guarda el archivo con Ctrl+O, luego Enter
   - Sal del editor con Ctrl+X

4. **Dale permisos de ejecución al script**:
   ```bash
   chmod +x diagnostico-contenedor.sh
   ```

5. **Ejecuta el script**:
   ```bash
   ./diagnostico-contenedor.sh
   ```

## Opción 3: Usar la Consola de Portainer

Si no tienes acceso SSH pero tienes acceso a la consola de Portainer:

1. **Accede a Portainer** en `https://ippportainer.probolsas.co`

2. **Ve a "Containers"** en el menú lateral

3. **Encuentra el contenedor del agente de Portainer** (normalmente llamado `portainer_agent`)

4. **Haz clic en el contenedor** para ver sus detalles

5. **Ve a la pestaña "Console"** o "Exec Console"

6. **Selecciona `/bin/bash` como shell** (si está disponible)

7. **Haz clic en "Connect"** o "Execute"

8. **En la consola, crea el script**:
   ```bash
   cat > diagnostico-contenedor.sh << 'EOF'
   #!/bin/bash
   # Script para diagnosticar problemas con el contenedor de CRM Probolsas

   echo "=== Diagnóstico del Contenedor CRM Probolsas ==="
   echo "Fecha y hora: $(date)"

   # Colores para la salida
   GREEN='\033[0;32m'
   RED='\033[0;31m'
   YELLOW='\033[1;33m'
   NC='\033[0m' # No Color

   # Verificar si Docker está en ejecución
   echo -e "\n${YELLOW}Verificando si Docker está en ejecución:${NC}"
   if systemctl is-active --quiet docker; then
       echo -e "${GREEN}✓ Docker está en ejecución${NC}"
   else
       echo -e "${RED}✗ Docker no está en ejecución${NC}"
       echo -e "Intenta iniciar Docker con: ${YELLOW}systemctl start docker${NC}"
       exit 1
   fi

   # Verificar si hay contenedores relacionados con crm-probolsas
   echo -e "\n${YELLOW}Buscando contenedores relacionados con crm-probolsas:${NC}"
   CONTAINERS=$(docker ps -a | grep -i probolsas)
   if [ -n "$CONTAINERS" ]; then
       echo -e "${GREEN}Se encontraron contenedores:${NC}"
       echo "$CONTAINERS"
       
       # Obtener el ID del último contenedor
       CONTAINER_ID=$(echo "$CONTAINERS" | head -1 | awk '{print $1}')
       echo -e "\n${YELLOW}Analizando el contenedor $CONTAINER_ID:${NC}"
       
       # Verificar el estado del contenedor
       STATUS=$(docker inspect --format='{{.State.Status}}' $CONTAINER_ID)
       echo -e "Estado: ${YELLOW}$STATUS${NC}"
       
       # Si el contenedor está detenido, verificar por qué
       if [ "$STATUS" != "running" ]; then
           echo -e "\n${YELLOW}El contenedor no está en ejecución. Verificando la razón:${NC}"
           EXIT_CODE=$(docker inspect --format='{{.State.ExitCode}}' $CONTAINER_ID)
           echo -e "Código de salida: ${RED}$EXIT_CODE${NC}"
           
           # Mostrar los logs del contenedor
           echo -e "\n${YELLOW}Últimas líneas de log del contenedor:${NC}"
           docker logs --tail 50 $CONTAINER_ID
           
           # Verificar si hay errores específicos
           if docker logs $CONTAINER_ID 2>&1 | grep -i "error"; then
               echo -e "\n${RED}Se encontraron errores en los logs${NC}"
           fi
           
           # Verificar si el contenedor se reinició muchas veces
           RESTARTS=$(docker inspect --format='{{.RestartCount}}' $CONTAINER_ID 2>/dev/null || echo "N/A")
           echo -e "\nNúmero de reinicios: ${YELLOW}$RESTARTS${NC}"
       else
           # Si el contenedor está en ejecución, verificar los procesos
           echo -e "\n${YELLOW}Procesos en ejecución dentro del contenedor:${NC}"
           docker exec -it $CONTAINER_ID ps aux || echo -e "${RED}No se pudo ejecutar ps dentro del contenedor${NC}"
           
           # Verificar los puertos en uso
           echo -e "\n${YELLOW}Puertos en uso dentro del contenedor:${NC}"
           docker exec -it $CONTAINER_ID netstat -tuln || echo -e "${RED}No se pudo ejecutar netstat dentro del contenedor${NC}"
           
           # Verificar si el servidor está respondiendo
           echo -e "\n${YELLOW}Verificando si el servidor responde dentro del contenedor:${NC}"
           docker exec -it $CONTAINER_ID curl -s http://localhost:3000 > /dev/null
           if [ $? -eq 0 ]; then
               echo -e "${GREEN}✓ El servidor está respondiendo en el puerto 3000${NC}"
           else
               echo -e "${RED}✗ El servidor no está respondiendo en el puerto 3000${NC}"
           fi
       fi
   else
       echo -e "${RED}No se encontraron contenedores relacionados con crm-probolsas${NC}"
   fi

   # Verificar la red probolsas
   echo -e "\n${YELLOW}Verificando la red probolsas:${NC}"
   if docker network ls | grep -q probolsas; then
       echo -e "${GREEN}✓ La red probolsas existe${NC}"
       
       # Verificar los contenedores conectados a la red
       echo -e "\n${YELLOW}Contenedores conectados a la red probolsas:${NC}"
       docker network inspect probolsas -f '{{range .Containers}}{{.Name}} {{end}}' | tr ' ' '\n' | grep .
   else
       echo -e "${RED}✗ La red probolsas no existe${NC}"
   fi

   # Verificar el stack en Portainer
   echo -e "\n${YELLOW}Para verificar el stack en Portainer:${NC}"
   echo -e "1. Accede a Portainer en https://ippportainer.probolsas.co"
   echo -e "2. Ve a Stacks > probolsas_crm_v2"
   echo -e "3. Verifica el estado del stack y los logs"

   # Verificar Traefik
   echo -e "\n${YELLOW}Verificando Traefik:${NC}"
   TRAEFIK_CONTAINER=$(docker ps | grep traefik | awk '{print $1}')
   if [ -n "$TRAEFIK_CONTAINER" ]; then
       echo -e "${GREEN}✓ Traefik está en ejecución${NC}"
       
       # Verificar la configuración de Traefik
       echo -e "\n${YELLOW}Verificando la configuración de Traefik para ippcrm.probolsas.co:${NC}"
       docker exec -it $TRAEFIK_CONTAINER traefik version 2>/dev/null || echo -e "${RED}No se pudo ejecutar traefik version${NC}"
   else
       echo -e "${RED}✗ Traefik no está en ejecución${NC}"
   fi

   # Recomendaciones
   echo -e "\n${YELLOW}Recomendaciones:${NC}"
   echo -e "1. Verifica que el archivo dist/ exista y contenga los archivos de la aplicación"
   echo -e "2. Asegúrate de que el archivo server.js esté presente y sea correcto"
   echo -e "3. Verifica que las variables de entorno en .env.production sean correctas"
   echo -e "4. Intenta reconstruir la imagen con: docker-compose build --no-cache"
   echo -e "5. Reinicia el stack en Portainer"

   echo -e "\n${YELLOW}=== Diagnóstico Completo ===${NC}"
   EOF
   ```

9. **Dale permisos de ejecución al script**:
   ```bash
   chmod +x diagnostico-contenedor.sh
   ```

10. **Ejecuta el script**:
    ```bash
    ./diagnostico-contenedor.sh
    ```

## Interpretación de los Resultados

El script proporcionará información detallada sobre:

- El estado de los contenedores relacionados con crm-probolsas
- Los logs del contenedor
- Los procesos en ejecución dentro del contenedor
- Los puertos en uso
- La red probolsas
- La configuración de Traefik

Busca mensajes en rojo (errores) o amarillo (advertencias) que puedan indicar problemas. El script también proporcionará recomendaciones específicas basadas en los problemas encontrados.

## Solución de Problemas

Si encuentras problemas al ejecutar el script:

1. **Problema**: El script no tiene permisos de ejecución
   **Solución**: Ejecuta `chmod +x diagnostico-contenedor.sh`

2. **Problema**: El script muestra errores de sintaxis
   **Solución**: Asegúrate de haber copiado todo el contenido correctamente

3. **Problema**: No puedes acceder al servidor por SSH
   **Solución**: Utiliza la consola de Portainer como se describe en la Opción 3
