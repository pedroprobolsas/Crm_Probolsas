# Funcionamiento del Webhook de IA en la Aplicación

Este documento explica cómo funciona el webhook de IA en la aplicación y cómo se relaciona con las Edge Functions y los triggers de base de datos.

## ¿Qué es el Webhook de IA?

El webhook de IA es un endpoint externo que procesa los mensajes de los clientes y genera respuestas automáticas utilizando inteligencia artificial. Está alojado en n8n, una plataforma de automatización de flujos de trabajo.

## Flujo de Trabajo del Webhook de IA

El flujo de trabajo del webhook de IA es el siguiente:

1. **Recepción del Mensaje**: El webhook recibe un mensaje de un cliente con `asistente_ia_activado = true`.

2. **Procesamiento del Mensaje**: El webhook procesa el mensaje utilizando inteligencia artificial para generar una respuesta.

3. **Generación de Respuesta**: El webhook genera una respuesta automática basada en el contenido del mensaje y el contexto de la conversación.

4. **Envío de Respuesta**: El webhook envía la respuesta a la aplicación, que la inserta en la tabla `messages` como un mensaje del agente.

## Configuración del Webhook de IA

La configuración del webhook de IA se almacena en la tabla `app_settings` de la base de datos:

- `webhook_url_ia_production`: URL del webhook de IA en producción.
- `webhook_url_ia_test`: URL del webhook de IA en pruebas.
- `is_production_environment`: Indica si el entorno actual es de producción o pruebas.

## Envío de Mensajes al Webhook de IA

Hay dos formas de enviar mensajes al webhook de IA:

1. **Trigger de Base de Datos**: Cuando se inserta un nuevo mensaje en la tabla `messages` con `asistente_ia_activado = true`, se activa el trigger `message_webhook_trigger`, que llama a la función `notify_message_webhook`.

2. **Edge Function `messages-incoming`**: Además del trigger de base de datos, la Edge Function `messages-incoming` también puede enviar mensajes al webhook de IA cuando `asistente_ia_activado = true`.

### Función `notify_message_webhook`

La función `notify_message_webhook` es la encargada de enviar los mensajes al webhook de IA. Esta función:

1. Verifica si el mensaje tiene `asistente_ia_activado = true`.
2. Obtiene la URL del webhook de IA de la tabla `app_settings`.
3. Prepara los datos del mensaje para enviar al webhook.
4. Envía los datos al webhook utilizando la función `http_post`.
5. Actualiza el campo `ia_webhook_sent` a `true` cuando un mensaje se envía correctamente al webhook de IA.

```sql
CREATE OR REPLACE FUNCTION notify_message_webhook()
RETURNS TRIGGER AS $$
DECLARE
  webhook_url TEXT;
  is_production BOOLEAN;
  client_data JSONB;
  payload JSONB;
BEGIN
  -- Solo procesar mensajes de clientes con asistente_ia_activado = true
  IF NEW.sender = 'client' AND NEW.asistente_ia_activado = TRUE THEN
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
    
    -- Obtener datos del cliente
    SELECT row_to_json(c) INTO client_data
    FROM (
      SELECT * FROM clients WHERE id = (
        SELECT client_id FROM conversations WHERE id = NEW.conversation_id
      )
    ) c;
    
    -- Preparar payload para el webhook
    payload = jsonb_build_object(
      'id', NEW.id,
      'conversation_id', NEW.conversation_id,
      'content', NEW.content,
      'sender', NEW.sender,
      'sender_id', NEW.sender_id,
      'type', COALESCE(NEW.type, 'text'),
      'status', NEW.status,
      'created_at', NEW.created_at,
      'asistente_ia_activado', NEW.asistente_ia_activado,
      'client', client_data
    );
    
    -- Enviar al webhook
    PERFORM http_post(
      webhook_url,
      payload::text,
      'application/json'
    );
    
    -- Actualizar el mensaje para indicar que se envió al webhook de IA
    UPDATE messages
    SET ia_webhook_sent = TRUE
    WHERE id = NEW.id;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;
```

### Edge Function `messages-incoming`

La Edge Function `messages-incoming` también puede enviar mensajes al webhook de IA cuando `asistente_ia_activado = true`. Esta función:

1. Verifica si el mensaje tiene `asistente_ia_activado = true`.
2. Obtiene la URL del webhook de IA de la tabla `app_settings`.
3. Prepara los datos del mensaje para enviar al webhook.
4. Envía los datos al webhook.
5. Actualiza el campo `ia_webhook_sent` a `true` cuando un mensaje se envía correctamente al webhook de IA.

```javascript
// Si es un evento de inserción de mensaje
if (body.type === 'INSERT' && body.record) {
  const message = body.record;
  
  // Verificar si es un mensaje de cliente con asistente_ia_activado
  if (message.sender === 'client' && message.asistente_ia_activado === true) {
    // Obtener la URL del webhook de IA
    const { data: settingsData, error: settingsError } = await supabaseClient
      .from('app_settings')
      .select('value')
      .eq('key', 'webhook_url_ia_production')
      .single();
    
    const iaWebhookUrl = settingsError || !settingsData 
      ? IA_WEBHOOK_URL_FALLBACK 
      : settingsData.value;
    
    // Obtener datos del cliente
    // ... (código para obtener datos del cliente)
    
    // Preparar payload para el webhook
    const iaPayload = {
      id: message.id,
      conversation_id: message.conversation_id,
      content: message.content,
      sender: message.sender,
      sender_id: message.sender_id,
      type: message.type || 'text',
      status: message.status,
      created_at: message.created_at,
      asistente_ia_activado: message.asistente_ia_activado,
      client: client
    };
    
    // Enviar al webhook
    const iaResponse = await fetch(iaWebhookUrl, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json'
      },
      body: JSON.stringify(iaPayload)
    });
    
    // Actualizar el mensaje para indicar que se envió al webhook de IA
    if (iaResponse.ok) {
      const { error: updateError } = await supabaseClient
        .from('messages')
        .update({ ia_webhook_sent: true })
        .eq('id', message.id);
    }
  }
}
```

## Recepción de Respuestas del Webhook de IA

El webhook de IA procesa el mensaje y genera una respuesta, que se inserta en la tabla `messages` como un mensaje del agente. Este proceso se realiza a través de la API de Supabase.

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

## Conclusión

El webhook de IA es una parte fundamental de la aplicación, ya que permite procesar los mensajes de los clientes y generar respuestas automáticas utilizando inteligencia artificial. La solución implementada corrige el problema del webhook de IA y establece una base sólida para el futuro.
