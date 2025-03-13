import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { corsHeaders } from '../_shared/cors.ts';

serve(async (req) => {
  // Handle CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    // Get WooCommerce credentials from settings
    const { data: settings, error: settingsError } = await supabase
      .from('product_settings')
      .select('*')
      .eq('setting_type', 'woocommerce');

    if (settingsError) throw settingsError;

    const apiUrl = settings.find(s => s.setting_key === 'api_url')?.setting_value;
    const consumerKey = settings.find(s => s.setting_key === 'consumer_key')?.setting_value;
    const consumerSecret = settings.find(s => s.setting_key === 'consumer_secret')?.setting_value;

    if (!apiUrl || !consumerKey || !consumerSecret) {
      throw new Error('Missing WooCommerce credentials');
    }

    // Create auth headers
    const authString = btoa(`${consumerKey}:${consumerSecret}`);
    const headers = {
      'Authorization': `Basic ${authString}`,
      'Content-Type': 'application/json'
    };

    // Fetch products from WooCommerce
    const response = await fetch(`${apiUrl}/wp-json/wc/v3/products?per_page=100`, {
      headers
    });

    if (!response.ok) {
      throw new Error(`Error fetching products: ${response.status}`);
    }

    const products = await response.json();

    // Transform products to our format
    const transformedProducts = products.map((product: any) => ({
      id: product.id,
      name: product.name,
      sku: product.sku,
      regular_price: parseFloat(product.regular_price || '0'),
      categories: product.categories.map((cat: any) => cat.name),
      status: product.status,
      image: product.images[0]?.src
    }));

    return new Response(
      JSON.stringify(transformedProducts),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      }
    );

  } catch (error) {
    return new Response(
      JSON.stringify({
        error: error instanceof Error ? error.message : 'Error desconocido'
      }),
      {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      }
    );
  }
});