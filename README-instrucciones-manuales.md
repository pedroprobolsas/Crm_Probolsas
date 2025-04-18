# Instrucciones Manuales para Aplicar las Soluciones

Debido a problemas con los scripts PowerShell, aquí tienes instrucciones paso a paso para aplicar las soluciones manualmente.

## 1. Aplicar la Solución SQL para el Webhook de IA

1. Abre la consola SQL de Supabase
2. Copia y pega el contenido del archivo `fix_webhook_ia_completo_manual.sql`
3. Ejecuta el script completo

Este script realizará las siguientes acciones:
- Añadir la columna `ia_webhook_sent` a la tabla `messages` si no existe
- Crear o reemplazar la función `notify_message_webhook`
- Crear o reemplazar el trigger `message_webhook_trigger`
- Verificar que el trigger está activo
- Insertar un mensaje de prueba con `asistente_ia_activado=true`

## 2. Actualizar las Edge Functions

### Para la función `messages-incoming`:

1. Ve a la sección 'Edge Functions' en la consola de Supabase
2. Selecciona la función `messages-incoming`
3. Reemplaza el contenido del archivo `index.js` con el siguiente código:

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
    console.log('Mensaje recibido en messages-incoming:', body);
    
    // Crear cliente de Supabase
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '', 
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    );
    
    // Si es un evento de inserción de mensaje
    if (body.type === 'INSERT' && body.record) {
      const message = body.record;
      
      // Verificar si es un mensaje de cliente con asistente_ia_activado
      // MODIFICACIÓN: Verificar también si ya fue enviado al webhook de IA por el trigger SQL
      if (message.sender === 'client' && message.asistente_ia_activado === true && message.ia_webhook_sent !== true) {
        console.log('Procesando mensaje de cliente con asistente_ia_activado=true que no ha sido enviado al webhook:', message.id);
        
        try {
          // Obtener la URL del webhook de IA
          const { data: settingsData, error: settingsError } = await supabaseClient
            .from('app_settings')
            .select('value')
            .eq('key', 'webhook_url_ia_production')
            .single();
          
          const iaWebhookUrl = settingsError || !settingsData 
            ? IA_WEBHOOK_URL_FALLBACK 
            : settingsData.value;
          
          console.log('URL del webhook de IA:', iaWebhookUrl);
          
          // Obtener datos de la conversación
          const { data: conversation, error: convError } = await supabaseClient
            .from('conversations')
            .select('client_id, whatsapp_chat_id')
            .eq('id', message.conversation_id)
            .single();
          
          if (convError) {
            throw new Error(`Error al obtener la conversación: ${convError.message}`);
          }
          
          // Obtener datos del cliente
          const { data: client, error: clientError } = await supabaseClient
            .from('clients')
            .select('*')
            .eq('id', conversation.client_id)
            .single();
          
          if (clientError) {
            throw new Error(`Error al obtener el cliente: ${clientError.message}`);
          }
          
          // Preparar payload para el webhook de IA
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
            phone: client.phone,
            client: client
          };
          
          console.log('Enviando mensaje al webhook de IA:', iaPayload);
          
          // Enviar al webhook de IA
          const iaResponse = await fetch(iaWebhookUrl, {
            method: 'POST',
            headers: {
              'Content-Type': 'application/json'
            },
            body: JSON.stringify(iaPayload)
          });
          
          if (!iaResponse.ok) {
            console.error('Error al enviar al webhook de IA:', await iaResponse.text());
          } else {
            console.log('Mensaje enviado correctamente al webhook de IA');
            
            // Actualizar el mensaje para indicar que se envió al webhook de IA
            const { error: updateError } = await supabaseClient
              .from('messages')
              .update({ ia_webhook_sent: true })
              .eq('id', message.id);
            
            if (updateError) {
              console.error('Error al actualizar el estado del mensaje:', updateError.message);
            }
          }
        } catch (iaError) {
          console.error('Error al procesar mensaje para IA:', iaError);
        }
      }
    }
    
    // Respuesta de éxito
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

### Para la función `messages-outgoing`:

1. Ve a la sección 'Edge Functions' en la consola de Supabase
2. Selecciona la función `messages-outgoing`
3. Reemplaza el contenido del archivo `index.js` con el siguiente código:

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
    // Verificación estricta para evitar interferir con mensajes de clientes o con el webhook de IA
    if (type !== 'INSERT' || record.sender !== 'agent') {
      console.log('No es un mensaje de agente o no es una inserción, ignorando:', record.id);
      return new Response(JSON.stringify({
        success: false,
        message: 'No es un mensaje de agente o no es una inserción'
      }), {
        headers: {
          'Content-Type': 'application/json'
        },
        status: 200
      });
    }
    
    // Verificación adicional para asegurarse de que no interfiera con el webhook de IA
    if (record.asistente_ia_activado === true) {
      console.log('Mensaje con asistente_ia_activado=true, dejando que el trigger SQL lo maneje:', record.id);
      return new Response(JSON.stringify({
        success: false,
        message: 'Mensaje con asistente_ia_activado=true, dejando que el trigger SQL lo maneje'
      }), {
        headers: {
          'Content-Type': 'application/json'
        },
        status: 200
      });
    }
    
    console.log('Procesando mensaje de agente:', record.id);
    
    // Obtener datos de la conversación para tener el número de WhatsApp del cliente
    const supabaseClient = createClient(Deno.env.get('SUPABASE_URL') ?? '', Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '');
    
    const { data: conversation, error: convError } = await supabaseClient.from('conversations').select('client_id, whatsapp_chat_id').eq('id', record.conversation_id).single();
    if (convError) {
      throw new Error(`Error al obtener la conversación: ${convError.message}`);
    }
    
    // Obtener datos del cliente para tener su número de teléfono
    const { data: client, error: clientError } = await supabaseClient.from('clients').select('phone, name').eq('id', conversation.client_id).single();
    if (clientError) {
      throw new Error(`Error al obtener el cliente: ${clientError.message}`);
    }
    
    // Obtener datos del agente para incluir su nombre
    const { data: agent, error: agentError } = await supabaseClient.from('agents').select('name').eq('id', record.sender_id).single();
    if (agentError) {
      console.error(`Error al obtener el agente: ${agentError.message}`);
    // Continuamos aunque falle, no es crítico
    }
    
    // Preparar datos para enviar a n8n
    const webhookData = {
      message: {
        id: record.id,
        content: record.content,
        conversation_id: record.conversation_id,
        whatsapp_chat_id: conversation.whatsapp_chat_id,
        client_phone: client.phone,
        client_name: client.name,
        sender: record.sender,
        sender_id: record.sender_id,
        sender_name: agent?.name || 'Agente',
        created_at: record.created_at,
        type: record.type || 'text'
      },
      evolution_api: {
        url: EVOLUTION_API_URL,
        key: EVOLUTION_API_KEY
      }
    };
    
    console.log('Enviando mensaje al webhook de n8n:', webhookData);
    
    // Enviar datos al webhook de n8n
    const response = await fetch(N8N_WEBHOOK_URL, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json'
      },
      body: JSON.stringify(webhookData)
    });
    
    if (!response.ok) {
      throw new Error(`Error al enviar al webhook: ${response.statusText}`);
    }
    
    console.log('Mensaje enviado correctamente al webhook de n8n');
    
    // MODIFICACIÓN: En lugar de actualizar el mensaje, crear un registro en una tabla separada
    // para rastrear los mensajes enviados a WhatsApp
    try {
      // Primero verificamos si la tabla message_whatsapp_status existe
      const { data: tableExists, error: tableCheckError } = await supabaseClient.rpc(
        'check_if_table_exists',
        { table_name: 'message_whatsapp_status' }
      );
      
      // Si la tabla no existe o hay un error, usamos el método anterior pero con un log
      if (tableCheckError || !tableExists) {
        console.log('La tabla message_whatsapp_status no existe, usando método anterior');
        
        const { error: updateError } = await supabaseClient.from('messages').update({
          sent_to_whatsapp: true
        }).eq('id', record.id);
        
        if (updateError) {
          console.error(`Error al actualizar el mensaje: ${updateError.message}`);
        }
      } else {
        // Si la tabla existe, insertamos un registro en ella
        const { error: insertError } = await supabaseClient.from('message_whatsapp_status').insert({
          message_id: record.id,
          sent_to_whatsapp: true,
          sent_at: new Date().toISOString()
        });
        
        if (insertError) {
          console.error(`Error al registrar el estado del mensaje: ${insertError.message}`);
        }
      }
    } catch (statusError) {
      console.error(`Error al gestionar el estado del mensaje: ${statusError.message}`);
      // No lanzamos error para no interrumpir el flujo
    }
    
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

4. Guarda los cambios en ambas Edge Functions

## 3. Verificar la Solución

1. Envía un mensaje con el asistente de IA activado desde la interfaz de usuario
2. Verifica en los logs de Supabase que:
   - El mensaje se envía correctamente al webhook de IA
   - No hay errores relacionados con las Edge Functions
   - El mensaje se marca como enviado al webhook de IA (`ia_webhook_sent=true`)
3. Verifica que no aparecen clientes duplicados en el módulo de clientes ni en las conversaciones

## Notas Importantes

- Las Edge Functions han sido modificadas para que no interfieran con el webhook de IA, por lo que no es necesario deshabilitarlas.
- Si se realizan cambios en las Edge Functions en el futuro, es importante mantener la lógica que evita el procesamiento duplicado de mensajes.
- El sistema ahora utiliza un enfoque más robusto para manejar las suscripciones a cambios en la base de datos, lo que debería prevenir problemas similares en el futuro.

## Documentación Adicional

Para más detalles sobre las soluciones implementadas, consulta:

- `README-solucion-completa.md`: Guía completa de las soluciones
- `README-resumen-soluciones-implementadas.md`: Resumen de todas las soluciones
- `README-solucion-webhook-ia-y-duplicacion.md`: Explicación detallada de las soluciones
