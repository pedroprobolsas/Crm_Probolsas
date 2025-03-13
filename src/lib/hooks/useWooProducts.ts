import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { supabase } from '../supabase';
import type { WooProduct, ProductPrice } from '../types/product';

export function useWooProducts() {
  const queryClient = useQueryClient();

  const productsQuery = useQuery({
    queryKey: ['woo-products'],
    queryFn: async () => {
      const { data: settings } = await supabase
        .from('product_settings')
        .select('*')
        .eq('setting_type', 'woocommerce');

      const apiUrl = settings?.find(s => s.setting_key === 'api_url')?.setting_value;
      if (!apiUrl) throw new Error('WooCommerce API URL not configured');

      const { data, error } = await supabase.functions.invoke('get-woo-products');
      if (error) throw error;
      return data as ProductPrice[];
    },
  });

  const updateProduct = useMutation({
    mutationFn: async (product: ProductPrice) => {
      const { data, error } = await supabase.functions.invoke('update-woo-product', {
        body: { product }
      });
      if (error) throw error;
      return data;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['woo-products'] });
    },
  });

  const syncProducts = useMutation({
    mutationFn: async (productIds: string[]) => {
      const { data, error } = await supabase.functions.invoke('sync-woo-products', {
        body: { productIds }
      });
      if (error) throw error;
      return data;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['woo-products'] });
    },
  });

  return {
    products: productsQuery.data || [],
    isLoading: productsQuery.isLoading,
    error: productsQuery.error,
    updateProduct: updateProduct.mutate,
    isUpdating: updateProduct.isPending,
    syncProducts: syncProducts.mutate,
    isSyncing: syncProducts.isPending,
  };
}