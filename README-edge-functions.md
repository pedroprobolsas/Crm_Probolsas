# Corrección de Edge Functions para Solucionar Problemas con Webhooks

Este documento proporciona instrucciones detalladas para corregir las Edge Functions que están causando problemas con los webhooks y el manejo de mensajes.

## Problemas Identificados

1. **Mensajes de agentes tratados como mensajes de clientes**: Los mensajes enviados por agentes se están copiando en la base de datos como si fueran de clientes.
2. **Contenido faltante en el webhook de IA**: El contenido del mensaje no se está incluyendo en el payload enviado al webhook de IA.
3. **Error de sintaxis**: Hay un error de sintaxis en alguna parte del código: "ERROR: 42601: syntax error at or near "DECLARE"".

## Corrección de Edge Function: messages-outgoing

La función `messages-outgoing` procesa mensajes de agentes y los envía a n8n. El problema principal es que está actualizando los mensajes en la base de datos, lo que podría estar causando que los mensajes de agentes se traten como mensajes de clientes.

### Código Actual

```javascript
import { createClient } from "npm:@supabase/supabase-js@2";
const N8N_WEBHOOK_URL = 'https://petersandoval.app.n8n.cloud/webhook-test/6c94ca6d-5783-41f0-8839-8b574b17e01f';
const EVOLUTION_API_URL = 'https://ippevolutionapi.probolsas.co/manager/instance/7924d748-affb-4e2c-9099-9d0db457b2c0';
const EVOLUTION_API_KEY = '3958C61218A8-4B54-BA6D-F96FDAF30CC8';

Deno.serve(async (req)=>{
  try {
    const { record, type } = await req.json();
    // Solo procesar inserciones de mensajes de agentes
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
    
    // Actualizar el mensaje como enviado a WhatsApp
    const { error: updateError } = await supabaseClient.from('messages').update({
      sent_to_whatsapp: true
    }).eq('id', record.id);
    
    if (updateError) {
      throw new Error(`Error al actualizar el mensaje: ${updateError.message}`);
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

### Problema

El problema principal está en esta parte del código:

```javascript
// Actualizar el mensaje como enviado a WhatsApp
const { error: updateError } = await supabaseClient.from('messages').update({
  sent_to_whatsapp: true
}).eq('id', record.id);
```

Esta actualización podría estar causando que los mensajes de agentes se traten como mensajes de clientes, ya que está modificando registros en la tabla `messages` después de que han sido insertados.

### Solución Propuesta

Modifica la función `messages-outgoing` de la siguiente manera:

```javascript
import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "npm:@supabase/supabase-js@2";
const N8N_WEBHOOK_URL = 'https://petersandoval.app.n8n.cloud/webhook-test/6c94ca6d-5783-41f0-8839-8b574b17e01f';
const EVOLUTION_API_URL = 'https://ippevolutionapi.probolsas.co/manager/instance/7924d748-affb-4e2c-9099-9d0db457b2c0';
const EVOLUTION_API_KEY = '3958C61218A8-4B54-BA6D-F96FDAF30CC8';

Deno.serve(async (req)=>{
  try {
    const { record, type } = await req.json();
    // Solo procesar inserciones de mensajes de agentes
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
    
    // MODIFICACIÓN: En lugar de actualizar el mensaje, crear un registro en una tabla separada
    // para rastrear los mensajes enviados a WhatsApp
    const { error: insertError } = await supabaseClient.from('message_whatsapp_status').insert({
      message_id: record.id,
      sent_to_whatsapp: true,
      sent_at: new Date().toISOString()
    });
    
    if (insertError) {
      console.error(`Error al registrar el estado del mensaje: ${insertError.message}`);
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

### Cambios Realizados

1. Se ha añadido la importación correcta para el entorno de ejecución de Edge Functions:
   ```javascript
   import "jsr:@supabase/functions-js/edge-runtime.d.ts";
   ```

2. Se ha modificado la forma en que se registra el estado de envío a WhatsApp:
   - En lugar de actualizar el mensaje original, se crea un registro en una tabla separada `message_whatsapp_status`.
   - Esto evita modificar los mensajes originales y previene posibles conflictos.

3. Se ha mejorado el manejo de errores para que un fallo en el registro del estado no interrumpa el flujo principal.

## Corrección de Edge Function: messages-incoming

La función `messages-incoming` procesa mensajes entrantes. Actualmente es muy simple y solo registra los mensajes recibidos.

### Código Actual

```javascript
import "jsr:@supabase/functions-js/edge-runtime.d.ts";

Deno.serve(async (req) => {
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
    // Aquí puedes procesar el mensaje entrante
    console.log('Mensaje recibido:', body);
    
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

### Problema

Esta función no parece estar causando problemas directamente, pero podría mejorarse para asegurar que no interfiera con el procesamiento de mensajes.

### Solución Propuesta

Mantén la función como está, ya que es simple y no parece estar causando problemas. Si en el futuro necesitas procesar mensajes entrantes, asegúrate de no modificar los mensajes existentes en la tabla `messages`.

## Creación de la Tabla message_whatsapp_status

Para implementar la solución propuesta para la función `messages-outgoing`, necesitas crear una nueva tabla `message_whatsapp_status`. Aquí está el SQL para crearla:

```sql
-- Crear tabla para rastrear el estado de envío a WhatsApp
CREATE TABLE IF NOT EXISTS message_whatsapp_status (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  message_id UUID REFERENCES messages(id) ON DELETE CASCADE,
  sent_to_whatsapp BOOLEAN DEFAULT FALSE,
  sent_at TIMESTAMPTZ,
  delivery_status TEXT,
  error_message TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Crear índice para búsquedas rápidas por message_id
CREATE INDEX IF NOT EXISTS idx_message_whatsapp_status_message_id ON message_whatsapp_status(message_id);

-- Trigger para actualizar updated_at
CREATE TRIGGER update_message_whatsapp_status_updated_at
  BEFORE UPDATE ON message_whatsapp_status
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();
```

## Pasos para Implementar las Correcciones

1. **Crear la tabla message_whatsapp_status**:
   - Ejecuta el SQL proporcionado en la consola SQL de Supabase.

2. **Actualizar la Edge Function messages-outgoing**:
   - Ve a la sección "Edge Functions" en Supabase.
   - Selecciona la función `messages-outgoing`.
   - Reemplaza el código actual con el código corregido proporcionado.
   - Guarda los cambios.

3. **Verificar la Edge Function messages-incoming**:
   - Ve a la sección "Edge Functions" en Supabase.
   - Selecciona la función `messages-incoming`.
   - Verifica que el código sea similar al proporcionado.
   - Si hay diferencias significativas, considera actualizarlo para que sea más simple y no interfiera con el procesamiento de mensajes.

4. **Ejecutar el script SQL fix_webhook_edge_functions_final.sql**:
   - Ejecuta el script SQL en la consola SQL de Supabase para corregir los problemas con el webhook de IA.

5. **Probar las correcciones**:
   - Envía un mensaje como agente y verifica que se procese correctamente.
   - Envía un mensaje como cliente con el asistente de IA activado y verifica que llegue al webhook de IA.
   - Verifica los logs de Supabase para confirmar que no hay errores.

## Verificación

Para verificar que las correcciones han funcionado correctamente:

1. **Verificar que los mensajes de agentes no se traten como mensajes de clientes**:
   ```sql
   SELECT 
     id, 
     content, 
     sender, 
     sender_id,
     status, 
     created_at
   FROM 
     messages
   WHERE 
     sender = 'client' AND
     sender_id IN (SELECT id FROM agents)
   ORDER BY 
     created_at DESC
   LIMIT 10;
   ```
   Esta consulta no debería devolver resultados si la corrección ha funcionado.

2. **Verificar que los mensajes con asistente_ia_activado=true lleguen al webhook de IA**:
   - Envía un mensaje con el asistente de IA activado.
   - Verifica los logs de Supabase para confirmar que el mensaje se ha enviado al webhook de IA.
   - Verifica que el contenido del mensaje se incluya en el payload.

3. **Verificar que no haya errores de sintaxis**:
   - Revisa los logs de Supabase para confirmar que no hay errores de sintaxis.
