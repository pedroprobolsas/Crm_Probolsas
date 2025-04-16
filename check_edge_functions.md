# Verificación de Edge Functions

Este documento proporciona instrucciones para verificar las Edge Functions que podrían estar interfiriendo con el webhook de IA.

## Edge Functions Identificadas

En las imágenes proporcionadas, se observan dos Edge Functions:
- `messages-incoming`
- `messages-outgoing`

Estas funciones podrían estar interceptando los mensajes antes de que lleguen al webhook o modificando su comportamiento.

## Pasos para Verificar las Edge Functions

1. **Acceder a la consola de Supabase**
   - Ve a la sección "Edge Functions"

2. **Examinar la función `messages-incoming`**
   - Haz clic en la función para ver su código
   - Verifica si esta función está procesando mensajes entrantes y cómo los está manejando
   - Busca cualquier lógica relacionada con webhooks o el campo `asistente_ia_activado`

3. **Examinar la función `messages-outgoing`**
   - Haz clic en la función para ver su código
   - Verifica si esta función está procesando mensajes salientes y cómo los está manejando
   - Busca cualquier lógica relacionada con webhooks o el campo `asistente_ia_activado`

4. **Verificar los logs de las Edge Functions**
   - Ve a la sección "Logs" en Supabase
   - Filtra los logs por "Edge Functions"
   - Busca cualquier error o comportamiento inesperado relacionado con estas funciones

## Posibles Problemas y Soluciones

### Problema 1: Edge Functions interceptando mensajes

Si las Edge Functions están interceptando los mensajes antes de que lleguen al webhook, podrían estar modificando el campo `asistente_ia_activado` o el tipo de remitente (`sender`).

**Solución**: Modificar las Edge Functions para que respeten el campo `asistente_ia_activado` y el tipo de remitente.

### Problema 2: Edge Functions enviando mensajes a webhooks incorrectos

Las Edge Functions podrían estar enviando los mensajes a webhooks diferentes a los configurados en `app_settings`.

**Solución**: Asegurarse de que las Edge Functions utilicen las URLs de webhook correctas, preferiblemente obtenidas de `app_settings`.

### Problema 3: Edge Functions con errores

Las Edge Functions podrían tener errores que impiden que los mensajes se envíen correctamente.

**Solución**: Revisar los logs de las Edge Functions y corregir cualquier error.

## Notas Importantes

- Las Edge Functions se ejecutan en un entorno serverless, por lo que pueden tener limitaciones de tiempo de ejecución y recursos.
- Las Edge Functions pueden tener su propia lógica de manejo de errores y reintentos.
- Es posible que las Edge Functions estén utilizando credenciales o configuraciones diferentes a las utilizadas por los triggers de la base de datos.
