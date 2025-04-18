# Instrucciones Actualizadas para Aplicar las Soluciones

Debido a los problemas encontrados, he creado versiones simplificadas de los archivos para facilitar la implementación manual de las soluciones.

## 1. Aplicar la Solución SQL para el Webhook de IA

1. Abre la consola SQL de Supabase
2. Copia y pega el contenido del archivo `fix_webhook_ia_simplificado.sql`
3. Ejecuta el script completo

Este script corregido:
- Añade la columna `ia_webhook_sent` a la tabla `messages` si no existe
- Crea o reemplaza la función `notify_message_webhook`
- Crea o reemplaza el trigger `message_webhook_trigger`
- Verifica que el trigger está activo
- Inserta un mensaje de prueba con `asistente_ia_activado=true`

## 2. Actualizar las Edge Functions

### Para la función `messages-incoming`:

1. Ve a la sección 'Edge Functions' en la consola de Supabase
2. Selecciona la función `messages-incoming`
3. Reemplaza el contenido del archivo `index.js` con el código del archivo `messages-incoming-simplificado.js`

Si tienes problemas para pegar el código completo, puedes:
- Crear un archivo temporal y subirlo usando el botón "Add File" o "Upload"
- Actualizar el código por secciones pequeñas
- Usar la CLI de Supabase si tienes acceso

### Para la función `messages-outgoing`:

1. Ve a la sección 'Edge Functions' en la consola de Supabase
2. Selecciona la función `messages-outgoing`
3. Reemplaza el contenido del archivo `index.js` con el código del archivo `messages-outgoing-simplificado.js`

## 3. Verificar la Solución

1. Envía un mensaje con el asistente de IA activado desde la interfaz de usuario
2. Verifica en los logs de Supabase que:
   - El mensaje se envía correctamente al webhook de IA
   - No hay errores relacionados con las Edge Functions
   - El mensaje se marca como enviado al webhook de IA (`ia_webhook_sent=true`)
3. Verifica que no aparecen clientes duplicados en el módulo de clientes ni en las conversaciones

## Cambios Clave en las Versiones Simplificadas

### En el Script SQL:

- Se corrigió el error "query has no destination for result data" asignando el resultado de la consulta SELECT a una variable
- Se mejoró la estructura del script para evitar errores de sintaxis

### En la Edge Function `messages-incoming`:

- Se añadió una verificación para comprobar si el mensaje ya fue enviado al webhook de IA (`message.ia_webhook_sent !== true`)
- Se mejoró el manejo de errores

### En la Edge Function `messages-outgoing`:

- Se añadió una verificación para ignorar mensajes con `asistente_ia_activado=true`
- Se mejoró el manejo de errores

## Notas Importantes

- Las Edge Functions han sido modificadas para que no interfieran con el webhook de IA, por lo que no es necesario deshabilitarlas.
- Si se realizan cambios en las Edge Functions en el futuro, es importante mantener la lógica que evita el procesamiento duplicado de mensajes.
- El sistema ahora utiliza un enfoque más robusto para manejar las suscripciones a cambios en la base de datos, lo que debería prevenir problemas similares en el futuro.

## Solución de Problemas

Si sigues teniendo problemas para actualizar las Edge Functions:

1. **Problema**: No puedes pegar todo el código de una vez
   **Solución**: Divide el código en secciones más pequeñas y pégalas una por una

2. **Problema**: La interfaz de Supabase no permite editar el código
   **Solución**: Crea un nuevo archivo con el código y súbelo usando el botón "Add File" o "Upload"

3. **Problema**: Errores al ejecutar el script SQL
   **Solución**: Ejecuta las secciones del script una por una para identificar dónde está el error
