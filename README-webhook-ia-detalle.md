# Funcionamiento Detallado del Webhook de IA

Este documento proporciona una explicación detallada de cómo funciona el webhook de IA en la aplicación.

## ¿Qué es el Webhook de IA?

El webhook de IA es un endpoint externo que procesa los mensajes de los clientes y genera respuestas automáticas utilizando inteligencia artificial. Está alojado en n8n, una plataforma de automatización de flujos de trabajo.

## Arquitectura del Webhook de IA

La arquitectura del webhook de IA consta de varios componentes:

1. **Aplicación**: La aplicación envía los mensajes de los clientes al webhook de IA y recibe las respuestas generadas.

2. **Base de Datos**: La base de datos almacena los mensajes y su estado de procesamiento.

3. **Trigger de Base de Datos**: El trigger `message_webhook_trigger` se activa cuando se inserta un nuevo mensaje con `asistente_ia_activado = true` y llama a la función `notify_message_webhook`.

4. **Función `notify_message_webhook`**: Esta función envía el mensaje al webhook de IA y actualiza el campo `ia_webhook_sent` a `true`.

5. **Edge Function `messages-incoming`**: Esta Edge Function también puede enviar mensajes al webhook de IA cuando `asistente_ia_activado = true`.

6. **Webhook de IA**: El webhook de IA procesa el mensaje y genera una respuesta, que se inserta en la tabla `messages` como un mensaje del agente.

7. **Edge Function `messages-outgoing`**: Esta Edge Function se activa cuando se inserta un nuevo mensaje con `sender = 'agent'` y lo envía al cliente a través de WhatsApp.

## Flujo de Trabajo del Webhook de IA

El flujo de trabajo del webhook de IA es el siguiente:

1. **Cliente envía un mensaje**:
   - El cliente envía un mensaje a través de WhatsApp.
   - El mensaje se recibe en la aplicación y se inserta en la tabla `messages` con `sender = 'client'` y `asistente_ia_activado = true`.

2. **Trigger de Base de Datos se activa**:
   - El trigger `message_webhook_trigger` se activa cuando se inserta un nuevo mensaje con `asistente_ia_activado = true`.
   - El trigger llama a la función `notify_message_webhook`.

3. **Función `notify_message_webhook` envía el mensaje al webhook de IA**:
   - La función `notify_message_webhook` obtiene la URL del webhook de IA de la tabla `app_settings`.
   - La función prepara los datos del mensaje para enviar al webhook.
   - La función envía los datos al webhook utilizando la función `http_post`.
   - La función actualiza el campo `ia_webhook_sent` a `true` cuando un mensaje se envía correctamente al webhook de IA.

4. **Webhook de IA procesa el mensaje**:
   - El webhook de IA recibe el mensaje.
   - El webhook procesa el mensaje utilizando inteligencia artificial para generar una respuesta.
   - El webhook genera una respuesta automática basada en el contenido del mensaje y el contexto de la conversación.

5. **Webhook de IA envía la respuesta**:
   - El webhook de IA envía la respuesta a la aplicación.
   - La respuesta se inserta en la tabla `messages` como un mensaje del agente.

6. **Edge Function `messages-outgoing` envía la respuesta al cliente**:
   - La Edge Function `messages-outgoing` se activa cuando se inserta un nuevo mensaje con `sender = 'agent'`.
   - La Edge Function envía el mensaje al cliente a través de WhatsApp.
   - La Edge Function registra el estado de envío en la tabla `message_whatsapp_status`.

## Configuración del Webhook de IA

La configuración del webhook de IA se almacena en la tabla `app_settings` de la base de datos:

- `webhook_url_ia_production`: URL del webhook de IA en producción.
- `webhook_url_ia_test`: URL del webhook de IA en pruebas.
- `is_production_environment`: Indica si el entorno actual es de producción o pruebas.

La función `notify_message_webhook` utiliza esta configuración para determinar qué URL de webhook utilizar:

```sql
-- Determinar qué URL de webhook usar basado en el entorno
SELECT (value = 'true') INTO is_production 
FROM app_settings 
WHERE key = 'is_production_environment';

IF is_production THEN
  SELECT value INTO webhook_url 
  FROM app_settings 
  WHERE key = 'webhook_url_ia_production';
ELSE
  SELECT value INTO webhook_url 
  FROM app_settings 
  WHERE key = 'webhook_url_ia_test';
END IF;
```

## Payload del Webhook de IA

El payload que se envía al webhook de IA contiene la siguiente información:

```json
{
  "id": "mensaje-id",
  "conversation_id": "conversacion-id",
  "content": "Contenido del mensaje",
  "sender": "client",
  "sender_id": "cliente-id",
  "type": "text",
  "status": "sent",
  "created_at": "2025-04-16T12:00:00Z",
  "asistente_ia_activado": true,
  "client": {
    "id": "cliente-id",
    "name": "Nombre del Cliente",
    "phone": "1234567890",
    "email": "cliente@example.com",
    "company": "Empresa del Cliente",
    "created_at": "2025-01-01T00:00:00Z",
    "updated_at": "2025-01-01T00:00:00Z"
  }
}
```

## Respuesta del Webhook de IA

La respuesta del webhook de IA se inserta en la tabla `messages` como un mensaje del agente:

```json
{
  "conversation_id": "conversacion-id",
  "content": "Respuesta generada por la IA",
  "sender": "agent",
  "sender_id": "agente-ia-id",
  "type": "text",
  "status": "sent"
}
```

## Problema y Solución

El problema que se identificó es que las Edge Functions estaban interfiriendo con el procesamiento de mensajes y el envío al webhook de IA:

1. La Edge Function `messages-outgoing` estaba actualizando los mensajes en la base de datos, lo que podría estar causando que los mensajes se procesen incorrectamente.
2. La función `notify_message_webhook` no estaba procesando correctamente los mensajes con `asistente_ia_activado = true`.

La solución implementada:

1. **Recreación de la función `notify_message_webhook`**: Se ha recreado la función para asegurar que procese correctamente los mensajes con `asistente_ia_activado = true`.

2. **Modificación de las Edge Functions**: Se han modificado las Edge Functions para que no interfieran con el procesamiento de mensajes.

3. **Creación de la tabla `message_whatsapp_status`**: Se ha creado una tabla para rastrear el estado de envío de mensajes a WhatsApp sin modificar directamente los mensajes en la tabla `messages`.

## Verificación del Webhook de IA

Para verificar si el webhook de IA está funcionando correctamente, puedes utilizar los siguientes scripts:

1. **verify_webhook_ia_status.sql**: Script SQL para verificar el estado del webhook de IA.
2. **run_verify_webhook_ia_status.ps1**: Script PowerShell para ejecutar `verify_webhook_ia_status.sql`.
3. **verify_webhook_ia_functionality.ps1**: Script PowerShell para verificar si el webhook de IA está funcionando correctamente.
4. **test_webhook_ia.ps1**: Script PowerShell para probar el webhook de IA.

## Logs del Webhook de IA

Los logs del webhook de IA se pueden encontrar en la consola de Supabase. Busca mensajes relacionados con "IA webhook", como:

- "Selected IA webhook URL: X (is_production=true/false)"
- "IA webhook payload: {...}"
- "IA webhook request succeeded for message ID: X"

## Conclusión

El webhook de IA es una parte fundamental de la aplicación, ya que permite procesar los mensajes de los clientes y generar respuestas automáticas utilizando inteligencia artificial. La solución implementada corrige el problema del webhook de IA y establece una base sólida para el futuro.

Al separar claramente las responsabilidades entre las Edge Functions y los triggers de base de datos, se evita que este problema vuelva a ocurrir. La tabla `message_whatsapp_status` permite rastrear el estado de envío de mensajes a WhatsApp sin interferir con el procesamiento de mensajes por parte del webhook de IA.
