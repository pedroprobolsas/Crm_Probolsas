// messages-incoming Edge Function (Versión Corregida)
// Esta función procesa mensajes entrantes.
// Versión corregida para asegurar que no interfiera con el procesamiento de mensajes.

import "jsr:@supabase/functions-js/edge-runtime.d.ts";

Deno.serve(async (req) => {
  // Manejar solicitudes OPTIONS para CORS
  if (req.method === 'OPTIONS') {
    return new Response('ok', {
      headers: {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'POST, OPTIONS',
        'Access-Control-Allow-Headers': 'Content-Type, Authorization'
      }
    });
  }
  
  try {
    const body = await req.json();
    
    // Solo registrar el mensaje recibido sin modificar nada en la base de datos
    console.log('Mensaje recibido:', JSON.stringify(body, null, 2));
    
    // Respuesta de éxito
    return new Response(JSON.stringify({
      success: true,
      message: 'Mensaje recibido correctamente'
    }), {
      headers: {
        'Content-Type': 'application/json',
        'Connection': 'keep-alive'
      },
      status: 200
    });
  } catch (error) {
    // Registrar el error
    console.error('Error al procesar el mensaje:', error.message);
    
    // Respuesta de error
    return new Response(JSON.stringify({
      success: false,
      error: 'Error al procesar el mensaje: ' + error.message
    }), {
      headers: {
        'Content-Type': 'application/json',
        'Connection': 'keep-alive'
      },
      status: 400
    });
  }
});
