// messages-outgoing Edge Function (Versión Corregida)
// Esta función procesa mensajes de agentes y los envía a n8n.
// Versión corregida para evitar actualizar directamente los mensajes en la tabla messages.

import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "npm:@supabase/supabase-js@2";

// Configuración de URLs y claves
const N8N_WEBHOOK_URL = 'https://petersandoval.app.n8n.cloud/webhook-test/6c94ca6d-5783-41f0-8839-8b574b17e01f';
const EVOLUTION_API_URL = 'https://ippevolutionapi.probolsas.co/manager/instance/7924d748-affb-4e2c-9099-9d0db457b2c0';
const EVOLUTION_API_KEY = '3958C61218A8-4B54-BA6D-F96FDAF30CC8';

Deno.serve(async (req) => {
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
