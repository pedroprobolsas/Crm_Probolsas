import { useMutation, useQueryClient } from '@tanstack/react-query';
import { supabase } from '../supabase';
import type { ProductPrice } from '../types/product';

export function useWooSync() {
  const queryClient = useQueryClient();

  const syncMutation = useMutation({
    mutationFn: async (products: ProductPrice[]) => {
      const { data, error } = await supabase.functions.invoke('sync-woo-products', {
        body: { products }
      });

      if (error) throw error;
      return data;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['products'] });
      queryClient.invalidateQueries({ queryKey: ['woo-products'] });
    },
  });

  return {
    syncProducts: syncMutation.mutate,
    isSyncing: syncMutation.isPending,
    error: syncMutation.error
  };
}