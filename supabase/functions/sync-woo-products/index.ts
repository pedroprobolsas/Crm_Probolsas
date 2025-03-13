import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { corsHeaders } from '../_shared/cors.ts';
import { getWooHeaders, validateWooCredentials } from '../_shared/woo.ts';

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    // Get WooCommerce credentials
    const { data: settings, error: settingsError } = await supabase
      .from('product_settings')
      .select('*')
      .eq('setting_type', 'woocommerce');

    if (settingsError) throw settingsError;

    const credentials = {
      api_url: settings.find(s => s.setting_key === 'api_url')?.setting_value,
      consumer_key: settings.find(s => s.setting_key === 'consumer_key')?.setting_value,
      consumer_secret: settings.find(s => s.setting_key === 'consumer_secret')?.setting_value
    };

    const validatedCreds = validateWooCredentials(credentials);
    const headers = getWooHeaders(validatedCreds.consumer_key, validatedCreds.consumer_secret);

    // Get products to sync
    const { products } = await req.json();

    // Sync each product
    const results = await Promise.all(products.map(async (product: any) => {
      const response = await fetch(
        `${validatedCreds.api_url}/wp-json/wc/v3/products/${product.id}`,
        {
          method: 'PUT',
          headers,
          body: JSON.stringify({
            regular_price: product.regular_price.toString(),
            meta_data: [
              {
                key: 'price_2',
                value: product.price_2.toString()
              },
              {
                key: 'price_3',
                value: product.price_3.toString()
              },
              {
                key: 'price_4',
                value: product.price_4.toString()
              },
              {
                key: 'min_quantities',
                value: JSON.stringify(product.min_quantities)
              }
            ]
          })
        }
      );

      if (!response.ok) {
        throw new Error(`Error updating product ${product.id}: ${response.status}`);
      }

      return await response.json();
    }));

    // Log sync results
    const { error: logError } = await supabase
      .from('sync_logs')
      .insert({
        sync_type: 'products',
        status: 'completed',
        records_processed: results.length,
        end_time: new Date().toISOString()
      });

    if (logError) throw logError;

    return new Response(
      JSON.stringify({ success: true, results }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );

  } catch (error) {
    return new Response(
      JSON.stringify({
        success: false,
        error: error instanceof Error ? error.message : 'Error desconocido'
      }),
      {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      }
    );
  }
});