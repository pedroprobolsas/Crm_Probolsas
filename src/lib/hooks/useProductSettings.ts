import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { supabase } from '../supabase';
import type { ProductSetting, WooCredentials } from '../types/product';

export function useProductSettings() {
  const queryClient = useQueryClient();

  const settingsQuery = useQuery({
    queryKey: ['product-settings'],
    queryFn: async () => {
      const { data, error } = await supabase
        .from('product_settings')
        .select('*')
        .order('setting_type', { ascending: true });

      if (error) throw error;
      return data as ProductSetting[];
    },
  });

  const updateSetting = useMutation({
    mutationFn: async ({ 
      setting_type, 
      setting_key, 
      setting_value 
    }: { 
      setting_type: string;
      setting_key: string;
      setting_value: string;
    }) => {
      const { data, error } = await supabase
        .from('product_settings')
        .update({ setting_value, updated_at: new Date().toISOString() })
        .eq('setting_type', setting_type)
        .eq('setting_key', setting_key)
        .select()
        .single();

      if (error) throw error;
      return data;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['product-settings'] });
    },
  });

  const testConnection = useMutation({
    mutationFn: async (credentials: WooCredentials) => {
      try {
        // Log connection attempt (without sensitive data)
        console.log('Testing connection with:', {
          api_url: credentials.api_url,
          hasConsumerKey: !!credentials.consumer_key,
          hasConsumerSecret: !!credentials.consumer_secret
        });

        // Validate credentials format
        if (!credentials.api_url || !credentials.consumer_key || !credentials.consumer_secret) {
          throw new Error('Faltan credenciales de WooCommerce');
        }

        if (!credentials.consumer_key.startsWith('ck_')) {
          throw new Error('Consumer Key debe comenzar con "ck_"');
        }

        if (!credentials.consumer_secret.startsWith('cs_')) {
          throw new Error('Consumer Secret debe comenzar con "cs_"');
        }

        // Get current session
        const { data: { session } } = await supabase.auth.getSession();
        if (!session) {
          throw new Error('No hay sesión activa');
        }

        // Call test function using the correct Supabase URL
        const { data, error } = await supabase.functions.invoke(
          'test-woo-connection',
          {
            body: credentials,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': `Bearer ${session.access_token}`
            }
          }
        );

        if (error) {
          console.error('Function error:', {
            name: error.name,
            message: error.message,
            details: error.cause || error.stack
          });
          throw new Error(error.message || 'Error al invocar la función de prueba');
        }

        // Log response
        console.log('Test connection response:', data);

        // Validate response structure
        if (!data || typeof data !== 'object') {
          throw new Error('Respuesta inválida del servidor');
        }

        if (!data.success) {
          throw new Error(data.error?.message || data.message || 'Error al probar la conexión');
        }

        return {
          success: true,
          productCount: data.productCount,
          storeInfo: data.storeInfo,
          message: data.message
        };

      } catch (error) {
        console.error('Connection test error:', {
          name: error.name,
          message: error.message,
          stack: error.stack,
          cause: error.cause
        });
        
        // Transform error to a consistent format
        const errorMessage = error instanceof Error 
          ? error.message 
          : 'Error desconocido al probar la conexión';

        throw new Error(errorMessage);
      }
    },
  });

  return {
    settings: settingsQuery.data || [],
    isLoading: settingsQuery.isLoading,
    error: settingsQuery.error,
    updateSetting: updateSetting.mutate,
    isUpdating: updateSetting.isPending,
    testConnection: testConnection.mutate,
    isTesting: testConnection.isPending,
    testError: testConnection.error
  };
}