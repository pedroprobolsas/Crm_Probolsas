// Versión simplificada de messages-incoming/index.js
// Copiar y pegar este código en la consola de Supabase

// @ts-ignore
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

// URL del webhook de IA (respaldo)
const IA_WEBHOOK_URL_FALLBACK = 'https://ippwebhookn8n.probolsas.co/webhook/d2d918c0-7132-43fe-9e8c-e07b033f2e6b';

serve(async (req) => {
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
      
      // MODIFICACIÓN IMPORTANTE: Verificar si ya fue enviado al webhook de IA
      if (message.sender === 'client' && message.asistente_ia_activado === true && message.ia_webhook_sent !== true) {
        console.log('Procesando mensaje con asistente_ia_activado=true que no ha sido enviado al webhook:', message.id);
        
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
