# Edge Functions en Supabase y su Relación con el Webhook de IA

Este documento explica cómo funcionan las Edge Functions en Supabase y cómo se relacionan con el webhook de IA en la aplicación.

## ¿Qué son las Edge Functions en Supabase?

Las Edge Functions en Supabase son funciones serverless que se ejecutan en el borde de la red, cerca de los usuarios. Están basadas en Deno, un entorno de ejecución seguro para JavaScript y TypeScript.

Las Edge Functions permiten ejecutar código en respuesta a eventos, como solicitudes HTTP, cambios en la base de datos, o eventos programados. Son ideales para:

- Procesamiento de datos en tiempo real
- Integración con servicios externos
- Lógica de negocio personalizada
- Webhooks y notificaciones

## Edge Functions en la Aplicación

En nuestra aplicación, utilizamos dos Edge Functions principales:

1. **messages-outgoing**: Procesa los mensajes salientes (de agentes a clientes) y los envía a WhatsApp a través de Evolution API.
2. **messages-incoming**: Procesa los mensajes entrantes (de clientes a agentes) y los envía al webhook de IA cuando `asistente_ia_activado = true`.

### messages-outgoing

Esta Edge Function se activa cuando se inserta un nuevo mensaje en la tabla `messages` con `sender = 'agent'`. Su función principal es enviar el mensaje al cliente a través de WhatsApp utilizando Evolution API.

```javascript
import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "npm:@supabase/supabase-js@2";
const N8N_WEBHOOK_URL = 'https://petersandoval.app.n8n.cloud/webhook-test/6c94ca6d-5783-41f0-8839-8b574b17e01f';
const EVOLUTION_API_URL = 'https://ippevolutionapi.probolsas.co/manager/instance/7924d748-affb-4e2c-9099-9d0db457b2c0';
const EVOLUTION_API_KEY = '3958C61218A8-4B54-BA6D-F96FDAF30CC8';

Deno.serve(async (req)=>{
  try {
    const { record, type } = await req.json();
    
    // IMPORTANTE: Solo procesar inserciones de mensajes de agentes
    if (type !== 'INSERT' || record.sender !== 'agent') {
      return new Response(JSON.stringify({
        success: false,
        message: 'No es un mensaje de agente'
      }), {
        headers: {
          'Content-Type': 'application/json'
        },
        status: 200
      });
    }
    
    // Obtener datos de la conversación y cliente
    const supabaseClient = createClient(Deno.env.get('SUPABASE_URL') ?? '', Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '');
    
    // ... (código para obtener datos de la conversación y cliente)
    
    // Enviar mensaje a WhatsApp a través de Evolution API
    // ... (código para enviar mensaje a WhatsApp)
    
    // Registrar el estado del envío
    // ... (código para registrar el estado del envío)
    
    return new Response(JSON.stringify({
      success: true
    }), {
      headers: {
        'Content-Type': 'application/json'
      },
      status: 200
    });
  } catch (error) {
    console.error('Error:', error.message);
    return new Response(JSON.stringify({
      success: false,
      error: error.message
    }), {
      headers: {
        'Content-Type': 'application/json'
      },
      status: 500
    });
  }
});
```

### messages-incoming

Esta Edge Function se activa cuando se inserta un nuevo mensaje en la tabla `messages` con `sender = 'client'` y `asistente_ia_activado = true`. Su función principal es enviar el mensaje al webhook de IA para procesamiento.

```javascript
import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "npm:@supabase/supabase-js@2";

// URL del webhook de IA (respaldo en caso de que no se pueda obtener de app_settings)
const IA_WEBHOOK_URL_FALLBACK = 'https://ippwebhookn8n.probolsas.co/webhook/d2d918c0-7132-43fe-9e8c-e07b033f2e6b';

Deno.serve(async (req)=>{
  if (req.method === 'OPTIONS') {
    return new Response('ok', {
      headers: {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'POST, OPTIONS'
      }
    });
  }
  
  try {
    const body = await req.json();
    
    // Si es un evento de inserción de mensaje
    if (body.type === 'INSERT' && body.record) {
      const message = body.record;
      
      // Verificar si es un mensaje de cliente con asistente_ia_activado
      if (message.sender === 'client' && message.asistente_ia_activado === true) {
        // Obtener la URL del webhook de IA
        const supabaseClient = createClient(
          Deno.env.get('SUPABASE_URL') ?? '', 
          Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
        );
        
        // ... (código para obtener la URL del webhook de IA)
        
        // Enviar mensaje al webhook de IA
        // ... (código para enviar mensaje al webhook de IA)
        
        // Actualizar el estado del mensaje
        // ... (código para actualizar el estado del mensaje)
      }
    }
    
    return new Response(JSON.stringify({
      message: 'Mensaje recibido correctamente'
    }), {
      headers: {
        'Content-Type': 'application/json',
        'Connection': 'keep-alive'
      },
      status: 200
    });
  } catch (error) {
    console.error('Error al procesar el mensaje:', error);
    return new Response(JSON.stringify({
      error: 'Error al procesar el mensaje'
    }), {
      headers: {
        'Content-Type': 'application/json',
        'Connection': 'keep-alive'
      },
      status: 400
    });
  }
});
```

## Relación con el Webhook de IA

El webhook de IA es un endpoint externo que procesa los mensajes de los clientes y genera respuestas automáticas utilizando inteligencia artificial. La relación entre las Edge Functions y el webhook de IA es la siguiente:

1. **Trigger de Base de Datos**: Cuando se inserta un nuevo mensaje en la tabla `messages` con `asistente_ia_activado = true`, se activa el trigger `message_webhook_trigger`.

2. **Función `notify_message_webhook`**: El trigger llama a la función `notify_message_webhook`, que envía el mensaje al webhook de IA utilizando la función `http_post`.

3. **Edge Function `messages-incoming`**: Además del trigger de base de datos, la Edge Function `messages-incoming` también puede enviar mensajes al webhook de IA cuando `asistente_ia_activado = true`.

4. **Respuesta del Webhook de IA**: El webhook de IA procesa el mensaje y genera una respuesta, que se inserta en la tabla `messages` como un mensaje del agente.

5. **Edge Function `messages-outgoing`**: Cuando se inserta un nuevo mensaje en la tabla `messages` con `sender = 'agent'`, se activa la Edge Function `messages-outgoing`, que envía el mensaje al cliente a través de WhatsApp.

## Problema y Solución

El problema que se identificó es que las Edge Functions estaban interfiriendo con el procesamiento de mensajes y el envío al webhook de IA:

1. La Edge Function `messages-outgoing` estaba actualizando los mensajes en la base de datos, lo que podría estar causando que los mensajes se procesen incorrectamente.
2. La función `notify_message_webhook` no estaba procesando correctamente los mensajes con `asistente_ia_activado = true`.

La solución implementada:

1. **Recreación de la función `notify_message_webhook`**: Se ha recreado la función para asegurar que procese correctamente los mensajes con `asistente_ia_activado = true`.
2. **Modificación de las Edge Functions**: Se han modificado las Edge Functions para que no interfieran con el procesamiento de mensajes.
3. **Creación de la tabla `message_whatsapp_status`**: Se ha creado una tabla para rastrear el estado de envío de mensajes a WhatsApp sin modificar directamente los mensajes en la tabla `messages`.

## Despliegue de Edge Functions

Para desplegar las Edge Functions en Supabase, se utiliza el comando `supabase functions deploy`:

```bash
supabase functions deploy messages-outgoing
supabase functions deploy messages-incoming
```

También puedes utilizar el script `update_edge_functions.ps1` para actualizar las Edge Functions:

```powershell
.\update_edge_functions.ps1
```

## Verificación de Edge Functions

Para verificar si las Edge Functions están correctamente desplegadas en Supabase, puedes utilizar el script `verify_edge_functions.ps1`:

```powershell
.\verify_edge_functions.ps1
```

## Conclusión

Las Edge Functions en Supabase son una herramienta poderosa para extender la funcionalidad de la aplicación. Sin embargo, es importante asegurarse de que no interfieran con el procesamiento de mensajes y el envío al webhook de IA.

La solución implementada corrige el problema del webhook de IA y establece una base sólida para el futuro. Al separar claramente las responsabilidades entre las Edge Functions y los triggers de base de datos, se evita que este problema vuelva a ocurrir.
