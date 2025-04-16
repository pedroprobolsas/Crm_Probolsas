# Corrección del Formato de Datos del Webhook de IA

Este documento proporciona instrucciones detalladas sobre cómo corregir el problema del formato de datos del webhook de IA utilizando los scripts proporcionados.

## Descripción del Problema

El webhook de IA está enviando los datos en un formato incorrecto. En lugar de enviar el JSON en el cuerpo (body) de la solicitud, está enviando parte del JSON en el encabezado "content-type". Esto causa que:

1. Los datos lleguen truncados debido a las limitaciones de tamaño de los encabezados HTTP
2. El cuerpo (body) de la solicitud esté vacío
3. El servicio que recibe el webhook no pueda procesar correctamente los datos

## Archivos Disponibles

Se han creado varios archivos para solucionar este problema:

1. **fix_ia_webhook_format.sql**: Script SQL que corrige la función `http_post` y la función `notify_message_webhook` para asegurar que los datos se envíen correctamente.

2. **test_ia_webhook_format.sql**: Script SQL para probar si la corrección ha funcionado correctamente.

3. **apply_fix_ia_webhook_format_fixed.ps1**: Script PowerShell corregido para aplicar la corrección.

4. **run_test_ia_webhook_format_fixed.ps1**: Script PowerShell corregido para ejecutar la prueba.

5. **setup_supabase_env.ps1**: Script PowerShell para configurar las variables de entorno necesarias para conectarse a Supabase.

## Opciones para Aplicar la Corrección

Hay tres formas de aplicar la corrección:

### Opción 1: Usar los Scripts PowerShell Corregidos

1. Ejecuta el script PowerShell corregido para aplicar la corrección:
   ```powershell
   .\apply_fix_ia_webhook_format_fixed.ps1
   ```

2. Después de aplicar la corrección, ejecuta el script PowerShell corregido para probar si ha funcionado correctamente:
   ```powershell
   .\run_test_ia_webhook_format_fixed.ps1
   ```

### Opción 2: Configurar Variables de Entorno y Ejecutar Scripts SQL Directamente

1. Ejecuta el script PowerShell para configurar las variables de entorno:
   ```powershell
   .\setup_supabase_env.ps1
   ```

2. Sigue las instrucciones que aparecen en la consola para configurar las variables de entorno necesarias para conectarse a Supabase.

3. Una vez configuradas las variables de entorno, ejecuta los scripts SQL directamente:

   Para aplicar la corrección:
   ```powershell
   psql -h $env:SUPABASE_DB_HOST -p $env:SUPABASE_DB_PORT -U $env:SUPABASE_DB_USER -d $env:SUPABASE_DB_NAME -f fix_ia_webhook_format.sql
   ```

   Para probar la corrección:
   ```powershell
   psql -h $env:SUPABASE_DB_HOST -p $env:SUPABASE_DB_PORT -U $env:SUPABASE_DB_USER -d $env:SUPABASE_DB_NAME -f test_ia_webhook_format.sql
   ```

### Opción 3: Aplicación Manual

1. Accede a la consola SQL de Supabase.
2. Copia y pega el contenido del archivo `fix_ia_webhook_format.sql`.
3. Ejecuta el script y revisa los resultados.
4. Luego, copia y pega el contenido del archivo `test_ia_webhook_format.sql`.
5. Ejecuta el script y revisa los resultados.

## Verificación

Para verificar que la solución ha funcionado correctamente:

1. Verifica los logs de Supabase para ver si el mensaje de prueba se envió correctamente al webhook de IA.
2. Verifica la respuesta del webhook para confirmar que los datos se recibieron correctamente en el cuerpo (body) de la solicitud.

El formato correcto que deberías recibir es:

```json
{
  "id": "cfd30f91-8b42-4c6f-9129-a250d22019e3",
  "conversation_id": "algún-uuid-aquí",
  "content": "Mensaje del cliente",
  "sender": "client",
  "sender_id": "e2c9d02d-0bf3-435a-a4d8-de7943828d68",
  "type": "text",
  "status": "sent",
  "created_at": "2025-04-16T00:12:41.380176+00:00",
  "asistente_ia_activado": true,
  "phone": "3125680519",
  "client": {
    "id": "e2c9d02d-0bf3-435a-a4d8-de7943828d68",
    "name": "Pedro Sandoval",
    "phone": "3125680519",
    // ... resto de datos del cliente
  }
}
```

## Solución de Problemas

### Error en los Scripts PowerShell

Si encuentras errores al ejecutar los scripts PowerShell, como el error "Token '}' inesperado", puedes:

1. Usar los scripts PowerShell corregidos (`apply_fix_ia_webhook_format_fixed.ps1` y `run_test_ia_webhook_format_fixed.ps1`).
2. Configurar las variables de entorno con `setup_supabase_env.ps1` y ejecutar los scripts SQL directamente.
3. Aplicar la corrección manualmente a través de la consola SQL de Supabase.

### Error de Conexión a Supabase

Si tienes problemas para conectarte a Supabase:

1. Verifica que las credenciales de Supabase sean correctas.
2. Asegúrate de que psql esté instalado y en el PATH.
3. Verifica que la base de datos de Supabase sea accesible desde tu red.

### Error al Ejecutar los Scripts SQL

Si encuentras errores al ejecutar los scripts SQL:

1. Verifica que la extensión http esté instalada en Supabase.
2. Asegúrate de que tengas los permisos necesarios para crear o modificar funciones en la base de datos.
3. Revisa los logs de Supabase para obtener más información sobre el error.

## Explicación Técnica

### Problema Original

El problema principal era que los datos del mensaje y del cliente se estaban enviando incorrectamente como parte del encabezado "content-type" en lugar de enviarse en el cuerpo (body) de la solicitud HTTP. Esto ocurría porque:

1. La función `http_post` podría estar implementada incorrectamente, mezclando los parámetros de encabezados y cuerpo.
2. O bien, la forma en que se llama a esta función desde `notify_message_webhook` podría estar intercambiando los parámetros.

### Solución Técnica

La solución implementada:

1. Corrige la función `http_post` para asegurar que maneje correctamente los encabezados y el cuerpo.
2. Corrige la función `notify_message_webhook` para asegurar que llame correctamente a `http_post`.
3. Recrea el trigger `message_webhook_trigger` para asegurarse de que esté usando la función actualizada.

## Prevención de Problemas Futuros

Para evitar que este problema vuelva a ocurrir:

1. **Asegúrate de que las funciones HTTP estén correctamente implementadas** y que manejen correctamente los encabezados y el cuerpo.
2. **Verifica periódicamente los logs de Supabase** para detectar errores relacionados con el webhook.
3. **Implementa pruebas automatizadas** para verificar que el webhook de IA está funcionando correctamente.
4. **Documenta claramente el orden de los parámetros** en las funciones HTTP para evitar confusiones.
