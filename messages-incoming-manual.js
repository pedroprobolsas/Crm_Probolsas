// Edge Function para procesar mensajes entrantes y enviarlos al webhook de IA
// Este archivo debe copiarse manualmente en la Edge Function messages-incoming en Supabase

// Importar las dependencias necesarias
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.38.4";

// Configuración
const WEBHOOK_URL_FALLBACK = "https://ippwebhookn8n.probolsas.co/webhook/d2d918c0-7132-43fe-9e8c-e07b033f2e6b";

// Función principal que maneja las solicitudes
serve(async (req) => {
  // Configurar el cliente de Supabase
  const supabaseClient = createClient(
    Deno.env.get("SUPABASE_URL") ?? "",
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "",
    {
      global: {
        headers: { Authorization: req.headers.get("Authorization") || "" },
      },
    }
  );

  // Obtener los datos de la solicitud
  const payload = await req.json();
  
  // Logging detallado para depuración
  console.log("Payload recibido:", JSON.stringify(payload, null, 2));
  
  try {
    // Verificar si es un evento de base de datos
    if (payload.type === "INSERT" || payload.type === "UPDATE") {
      const message = payload.record;
      
      // Verificaciones para determinar si el mensaje debe ser enviado al webhook
      if (!message) {
        console.log("No se encontró el mensaje en el payload");
        return new Response(JSON.stringify({ success: false, error: "No message found" }), {
          headers: { "Content-Type": "application/json" },
          status: 400,
        });
      }
      
      // Verificar si el mensaje ya ha sido enviado al webhook
      if (message.ia_webhook_sent === true) {
        console.log(`Mensaje ${message.id} ya enviado al webhook, omitiendo`);
        return new Response(JSON.stringify({ success: true, message: "Message already sent to webhook" }), {
          headers: { "Content-Type": "application/json" },
          status: 200,
        });
      }
      
      // Verificar si el asistente de IA está activado
      if (message.asistente_ia_activado !== true) {
        console.log(`Mensaje ${message.id} no tiene asistente_ia_activado=true, omitiendo`);
        return new Response(JSON.stringify({ success: true, message: "IA assistant not activated" }), {
          headers: { "Content-Type": "application/json" },
          status: 200,
        });
      }
      
      // Verificar si el mensaje es de un cliente
      if (message.sender !== "client") {
        console.log(`Mensaje ${message.id} no es de un cliente (sender=${message.sender}), omitiendo`);
        return new Response(JSON.stringify({ success: true, message: "Not a client message" }), {
          headers: { "Content-Type": "application/json" },
          status: 200,
        });
      }
      
      // Verificar si el mensaje está en estado enviado
      if (message.status !== "sent") {
        console.log(`Mensaje ${message.id} no está en estado enviado (status=${message.status}), omitiendo`);
        return new Response(JSON.stringify({ success: true, message: "Message not in sent status" }), {
          headers: { "Content-Type": "application/json" },
          status: 200,
        });
      }
      
      // Verificar si el mensaje es una respuesta de la IA
      if (message.content?.startsWith("[IA]")) {
        console.log(`Mensaje ${message.id} es una respuesta de la IA, omitiendo`);
        return new Response(JSON.stringify({ success: true, message: "Message is an IA response" }), {
          headers: { "Content-Type": "application/json" },
          status: 200,
        });
      }
      
      // Obtener la URL del webhook desde la configuración
      let webhookUrl = WEBHOOK_URL_FALLBACK;
      try {
        const { data: settingsData, error: settingsError } = await supabaseClient
          .from("app_settings")
          .select("value")
          .eq("key", "webhook_url_ia_production")
          .single();
        
        if (settingsError) {
          console.error("Error al obtener la URL del webhook:", settingsError);
        } else if (settingsData && settingsData.value) {
          webhookUrl = settingsData.value;
        }
      } catch (settingsError) {
        console.error("Error inesperado al obtener la URL del webhook:", settingsError);
      }
      
      // Obtener información del cliente
      let clientData = null;
      try {
        const { data: client, error: clientError } = await supabaseClient
          .from("clients")
          .select("*")
          .eq("id", message.sender_id)
          .single();
        
        if (clientError) {
          console.error("Error al obtener información del cliente:", clientError);
        } else {
          clientData = client;
        }
      } catch (clientError) {
        console.error("Error inesperado al obtener información del cliente:", clientError);
      }
      
      // Construir el payload para el webhook
      const webhookPayload = {
        id: message.id,
        conversation_id: message.conversation_id,
        content: message.content,
        sender: message.sender,
        sender_id: message.sender_id,
        type: message.type || "text",
        status: message.status,
        created_at: message.created_at,
        asistente_ia_activado: message.asistente_ia_activado,
        phone: clientData?.phone,
        client: clientData,
        source: "edge_function"
      };
      
      console.log("Enviando mensaje al webhook:", JSON.stringify(webhookPayload, null, 2));
      
      // Enviar al webhook
      try {
        const webhookResponse = await fetch(webhookUrl, {
          method: "POST",
          headers: {
            "Content-Type": "application/json"
          },
          body: JSON.stringify(webhookPayload)
        });
        
        if (!webhookResponse.ok) {
          const errorText = await webhookResponse.text();
          throw new Error(`Error al enviar al webhook: ${webhookResponse.status} ${errorText}`);
        }
        
        console.log(`Mensaje ${message.id} enviado correctamente al webhook de IA`);
        
        // Marcar el mensaje como enviado al webhook
        const { error: updateError } = await supabaseClient
          .from("messages")
          .update({ ia_webhook_sent: true })
          .eq("id", message.id);
        
        if (updateError) {
          console.error("Error al marcar el mensaje como enviado al webhook:", updateError);
        }
        
        return new Response(JSON.stringify({ success: true, message: "Message sent to webhook" }), {
          headers: { "Content-Type": "application/json" },
          status: 200,
        });
      } catch (webhookError) {
        console.error("Error al enviar mensaje al webhook:", webhookError);
        
        return new Response(JSON.stringify({ success: false, error: webhookError.message }), {
          headers: { "Content-Type": "application/json" },
          status: 500,
        });
      }
    }
    
    // Si no es un evento de base de datos, devolver una respuesta genérica
    return new Response(JSON.stringify({ success: true, message: "Event processed" }), {
      headers: { "Content-Type": "application/json" },
      status: 200,
    });
  } catch (error) {
    console.error("Error inesperado:", error);
    
    return new Response(JSON.stringify({ success: false, error: error.message }), {
      headers: { "Content-Type": "application/json" },
      status: 500,
    });
  }
});
