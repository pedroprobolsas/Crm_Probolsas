import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { corsHeaders } from '../_shared/cors.ts';
import { getWooHeaders, validateWooCredentials } from '../_shared/woo.ts';
import { supabase } from '../_shared/supabase.ts';

serve(async (req) => {
  // Handle CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    // Parse and validate credentials
    const credentials = await req.json();
    
    // Log incoming request (without sensitive data)
    console.log('Testing connection with:', {
      api_url: credentials.api_url,
      hasConsumerKey: !!credentials.consumer_key,
      hasConsumerSecret: !!credentials.consumer_secret
    });

    // Validate credentials
    const validatedCreds = validateWooCredentials(credentials);
    const { api_url, consumer_key, consumer_secret } = validatedCreds;

    // Create headers
    const headers = getWooHeaders(consumer_key, consumer_secret);

    // Test system status endpoint first
    console.log('Testing system status endpoint...');
    const systemResponse = await fetch(`${api_url}/wp-json/wc/v3/system_status`, { 
      method: 'GET',
      headers 
    });

    // Log response status
    console.log('System status response:', {
      status: systemResponse.status,
      ok: systemResponse.ok,
      contentType: systemResponse.headers.get('Content-Type')
    });

    if (!systemResponse.ok) {
      const errorText = await systemResponse.text();
      throw new Error(`Error al verificar estado del sistema: ${systemResponse.status} - ${errorText}`);
    }

    const systemData = await systemResponse.json();

    // Validate system status response
    if (!systemData || typeof systemData !== 'object') {
      throw new Error('Respuesta de estado del sistema inválida');
    }

    if (!systemData.environment) {
      throw new Error('No se pudo obtener información del ambiente');
    }

    // Test products endpoint
    console.log('Testing products endpoint...');
    const productsResponse = await fetch(`${api_url}/wp-json/wc/v3/products?per_page=1`, { 
      method: 'GET',
      headers 
    });

    // Log products response status
    console.log('Products response:', {
      status: productsResponse.status,
      ok: productsResponse.ok,
      contentType: productsResponse.headers.get('Content-Type')
    });

    if (!productsResponse.ok) {
      const errorText = await productsResponse.text();
      throw new Error(`Error al consultar productos: ${productsResponse.status} - ${errorText}`);
    }

    const totalProducts = productsResponse.headers.get('X-WP-Total');
    if (!totalProducts) {
      throw new Error('No se pudo obtener el total de productos');
    }

    // Return success response with validated data
    const response = {
      success: true,
      productCount: parseInt(totalProducts),
      storeInfo: {
        name: systemData.environment?.name || 'WooCommerce Store',
        url: api_url,
        version: systemData.environment?.version || 'Unknown'
      },
      message: 'Conexión exitosa'
    };

    console.log('Returning success response:', response);

    return new Response(
      JSON.stringify(response),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      }
    );

  } catch (error) {
    // Log error details
    console.error('Connection test error:', {
      name: error.name,
      message: error.message,
      stack: error.stack,
      cause: error.cause
    });

    // Return error response with detailed information
    const errorResponse = {
      success: false,
      error: {
        message: error instanceof Error ? error.message : 'Error desconocido',
        type: error.name || 'UnknownError',
        details: error.cause || null
      },
      message: `Error de conexión: ${error instanceof Error ? error.message : 'Error desconocido'}`
    };

    console.log('Returning error response:', errorResponse);

    return new Response(
      JSON.stringify(errorResponse),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 400
      }
    );
  }
});