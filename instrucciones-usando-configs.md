# Solución Alternativa: Usando Configs en Docker Swarm

Hemos identificado que los volúmenes están causando problemas en Docker Swarm. Como alternativa, he modificado el docker-compose.yml para usar configs de Docker Swarm, que son más compatibles con el entorno de Swarm.

## Cambios Realizados

1. **Eliminados los volúmenes**:
   - Los volúmenes estaban causando problemas en Docker Swarm
   - En su lugar, estamos usando configs de Docker Swarm

2. **Añadida una config para el archivo index.html**:
   - La config contiene directamente el contenido HTML
   - Se inyecta en el contenedor en la ruta `/usr/share/nginx/html/index.html`

## Cómo Funciona Esta Solución

Esta solución funciona de la siguiente manera:

1. En lugar de montar un volumen, definimos una config en el docker-compose.yml
2. La config contiene directamente el contenido del archivo HTML
3. Docker Swarm inyecta esta config en el contenedor en la ruta especificada
4. Nginx sirve este archivo como contenido estático

## Ventajas de Usar Configs

Las configs de Docker Swarm tienen varias ventajas sobre los volúmenes en este contexto:

1. **Mayor compatibilidad**: Las configs están diseñadas específicamente para Docker Swarm
2. **Inmutabilidad**: Las configs son inmutables, lo que garantiza consistencia
3. **Simplicidad**: No es necesario preocuparse por la sincronización de archivos entre nodos
4. **Seguridad**: Las configs pueden ser encriptadas y tienen un ciclo de vida gestionado

## Pasos para Implementar

### 1. Sube los cambios al repositorio

```bash
git add docker-compose.yml instrucciones-usando-configs.md
git commit -m "Usar configs en lugar de volúmenes para mayor compatibilidad con Swarm"
git push origin main
```

### 2. Actualiza el stack en Portainer

1. Accede a Portainer en `https://ippportainer.probolsas.co`
2. Ve a "Stacks" en el menú lateral
3. Encuentra tu stack `probolsas_crm_v2`
4. Haz clic en "Pull and redeploy" o similar
5. Confirma la acción

### 3. Verifica el despliegue

1. Revisa los logs en Portainer para ver si hay errores
2. Accede a la aplicación en `https://ippcrm.probolsas.co`
   - Deberías ver la página HTML definida en la config

## Interpretación de los Resultados

### Si el despliegue es exitoso

Si el despliegue es exitoso y puedes ver la página HTML, esto significa que:

1. Docker Swarm está configurado correctamente
2. Las configs están funcionando correctamente
3. Nginx está sirviendo correctamente el contenido
4. Traefik está enrutando correctamente el tráfico

En este caso, podemos proceder al siguiente paso: cambiar a una imagen de Node.js y servir el contenido con Express.

### Si el despliegue falla

Si el despliegue sigue fallando, esto podría indicar problemas más fundamentales:

1. **Problema con Docker Swarm**: Verifica que Swarm esté inicializado correctamente
2. **Problema con Portainer**: Verifica los logs de Portainer
3. **Problema con la red**: Verifica que la red `probolsas` exista y esté configurada correctamente

## Próximos Pasos

Si este enfoque funciona, procederemos al Paso 2: cambiar a una imagen de Node.js y servir el contenido con Express. Podemos seguir usando configs para inyectar archivos en el contenedor, o explorar otras alternativas como construir una imagen personalizada.
