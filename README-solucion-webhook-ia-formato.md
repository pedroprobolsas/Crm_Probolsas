# Solución para el Problema de Formato de Datos del Webhook de IA

Este documento proporciona una solución detallada para el problema donde los datos del mensaje y del cliente se están enviando incorrectamente como parte del encabezado "content-type" en lugar de enviarse en el cuerpo (body) de la solicitud HTTP.

## Descripción del Problema

El webhook de IA está enviando los datos en un formato incorrecto. En lugar de enviar el JSON en el cuerpo (body) de la solicitud, está enviando parte del JSON en el encabezado "content-type". Esto causa que:

1. Los datos lleguen truncados debido a las limitaciones de tamaño de los encabezados HTTP
2. El cuerpo (body) de la solicitud esté vacío
3. El servicio que recibe el webhook no pueda procesar correctamente los datos

Ejemplo de lo que se está recibiendo actualmente:

```json
[
{
"headers": 
{
"host": "ippwebhookn8n.probolsas.co",
"user-agent": "PostgreSQL 15.8 on aarch64-unknown-linux-gnu, compiled by gcc (GCC) 13.2.0, 64-bit",
"content-length": "1",
"accept": "*/*",
"accept-encoding": "deflate, gzip, br, zstd",
"charsets": "utf-8",
"content-type": "{"id": "cfd30f91-8b42-4c6f-9129-a250d22019e3", "type": "text", "phone": "3125680519", "client": {"id": "e2c9d02d-0bf3-435a-a4d8-de7943828d68", "nit": null, "name": "Pedro Sandoval", "tags": [], "brand": "", "email": null, "notes": "", "phone": "3125680519", "sector": null, "shifts": 1, "status": "active", "tax_id": null, "vision": null, "company": null, "mission": null, "segment": null, "website": null, "category": "prospect", "locations": [], "org_chart": [], "subsector": null, "created_at": "2025-04-16T00:12:41.380176+00:00", "updated_at": "2025-04-16T02:00:05.306362+00:00", "ai_insights": {}, "competitors": null, "departments": [], "description": "", "key_clients": null, "key_markets": null, "next_action": null, "work_shifts": [], "action_status": "pending", "current_stage": null, "key_equipment": [], "business_group": null, "certifications": [], "safety_metrics": {}, "fiscal_year_end": null, "last_year_sales": null, "packaging_types": [], "primary_contact": {}, "production_days": [], "quali",
"x-forwarded-for": "18.207.28.107",
"x-forwarded-host": "ippwebhookn8n.probolsas.co",
"x-forwarded-port": "443",
"x-forwarded-proto": "https",
"x-forwarded-server": "a7fa52393232",
"x-real-ip": "18.207.28.107"
},
"params": {},
"query": {},
"body": {},
"webhookUrl": "https://ippwebhookn8n.probolsas.co/webhook/d2d918c0-7132-43fe-9e8c-e07b033f2e6b",
"executionMode": "production"
}
]
```

## Causa del Problema

Después de analizar el código, se identificó que el problema está en la función `http_post` o en cómo se está llamando desde la función `notify_message_webhook`. Específicamente:

1. La función `http_post` podría estar enviando los datos incorrectamente, posiblemente mezclando los parámetros de encabezados y cuerpo.
2. O bien, la forma en que se llama a esta función desde `notify_message_webhook` podría estar intercambiando los parámetros.

## Solución Implementada

Se han creado varios archivos para corregir el problema:

1. **fix_ia_webhook_format.sql**: Script SQL que corrige la función `http_post` y la función `notify_message_webhook` para asegurar que los datos se envíen correctamente.
2. **apply_fix_ia_webhook_format.ps1**: Script PowerShell para aplicar la corrección.

### Correcciones Aplicadas

El script de corrección `fix_ia_webhook_format.sql` realiza las siguientes acciones:

1. **Verifica la definición actual de la función http_post** para entender cómo está implementada.
2. **Corrige la función http_post** para asegurar que maneje correctamente los encabezados y el cuerpo:
   ```sql
   CREATE OR REPLACE FUNCTION http_post(
     url text,
     body text,
     headers jsonb DEFAULT '{}'::jsonb
   ) RETURNS jsonb AS $$
   DECLARE
     result jsonb;
   BEGIN
     BEGIN
       -- Asegurarse de que los parámetros estén en el orden correcto
       -- y que el cuerpo se envíe como cuerpo y no como encabezado
       SELECT
         content::jsonb AS response_body
       INTO
         result
       FROM
         http((
           'POST',
           url,
           ARRAY(
             SELECT (key, value)::http_header
             FROM jsonb_each_text(headers)
           ),
           body,
           5 -- timeout in seconds
         )::http_request);
         
       RETURN jsonb_build_object('success', true, 'response', result);
     EXCEPTION WHEN OTHERS THEN
       RETURN jsonb_build_object('error', SQLERRM);
     END;
   END;
   $$ LANGUAGE plpgsql;
   ```

3. **Verifica la definición de la función notify_message_webhook** para entender cómo está llamando a `http_post`.
4. **Corrige la función notify_message_webhook** para asegurar que llame correctamente a `http_post`:
   ```sql
   -- CORRECCIÓN: Asegurarse de que los parámetros estén en el orden correcto
   -- Orden correcto: (url, body, headers)
   http_result := http_post(
     ia_webhook_url,
     payload::text,  -- Este es el cuerpo (body) de la solicitud
     jsonb_build_object('Content-Type', 'application/json')  -- Estos son los encabezados (headers)
   );
   ```

5. **Recrea el trigger message_webhook_trigger** para asegurarse de que esté usando la función actualizada.
6. **Inserta un mensaje de prueba** con `asistente_ia_activado = true` para verificar que el webhook funciona correctamente.

## Cómo Aplicar la Solución

### Método 1: Usando el Script PowerShell

1. Ejecuta el script PowerShell `apply_fix_ia_webhook_format.ps1`:
   ```powershell
   .\apply_fix_ia_webhook_format.ps1
   ```

2. Sigue las instrucciones que aparecen en la consola.

### Método 2: Aplicación Manual

1. Accede a la consola SQL de Supabase.
2. Copia y pega el contenido del archivo `fix_ia_webhook_format.sql`.
3. Ejecuta el script y revisa los resultados.
4. Verifica los logs de Supabase para confirmar que el webhook de IA está funcionando correctamente.

## Verificación

Para verificar que la solución ha funcionado correctamente:

1. Envía un nuevo mensaje desde la interfaz de usuario con el botón de asistente IA activado.
2. Verifica en los logs de Supabase que el mensaje se ha enviado al webhook de IA.
3. Confirma que el webhook de IA ha recibido el mensaje correctamente en el cuerpo (body) de la solicitud.

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

## Recursos Adicionales

- [README-webhook-ia.md](README-webhook-ia.md): Documentación original sobre la implementación del webhook de IA.
- [fix_ia_webhook_format.sql](fix_ia_webhook_format.sql): Script SQL para corregir el formato de datos del webhook de IA.
- [apply_fix_ia_webhook_format.ps1](apply_fix_ia_webhook_format.ps1): Script PowerShell para aplicar la corrección.
