// Versión simplificada de messages-outgoing/index.js
// Copiar y pegar este código en la consola de Supabase

// @ts-ignore
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const N8N_WEBHOOK_URL = 'https://petersandoval.app.n8n.cloud/webhook-test/6c94ca6d-5783-41f0-8839-8b574b17e01f';
const EVOLUTION_API_URL = 'https://ippevolutionapi.probolsas.co/manager/instance/7924d748-affb-4e2c-9099-9d0db457b2c0';
const EVOLUTION_API_KEY = '3958C61218A8-4B54-BA6D-F96FDAF30CC8';

serve(async (req) => {
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
    
    // MODIFICACIÓN IMPORTANTE: Verificación adicional para asegurarse de que no interfiera con el webhook de IA
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
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '', 
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    );
    
    const { data: conversation, error: convError } = await supabaseClient
      .from('conversations')
      .select('client_id, whatsapp_chat_id')
      .eq('id', record.conversation_id)
      .single();
      
    if (convError) {
      throw new Error(`Error al obtener la conversación: ${convError.message}`);
    }
    
    // Obtener datos del cliente para tener su número de teléfono
    const { data: client, error: clientError } = await supabaseClient
      .from('clients')
      .select('phone, name')
      .eq('id', conversation.client_id)
      .single();
      
    if (clientError) {
      throw new Error(`Error al obtener el cliente: ${clientError.message}`);
    }
    
    // Obtener datos del agente para incluir su nombre
    const { data: agent, error: agentError } = await supabaseClient
      .from('agents')
      .select('name')
      .eq('id', record.sender_id)
      .single();
      
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
        
        const { error: updateError } = await supabaseClient
          .from('messages')
          .update({
            sent_to_whatsapp: true
          })
          .eq('id', record.id);
        
        if (updateError) {
          console.error(`Error al actualizar el mensaje: ${updateError.message}`);
        }
      } else {
        // Si la tabla existe, insertamos un registro en ella
        const { error: insertError } = await supabaseClient
          .from('message_whatsapp_status')
          .insert({
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
