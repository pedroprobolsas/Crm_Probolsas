import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { supabase } from '../supabase';
import type { ProductPrice } from '../types/product';

export function useProducts() {
  const queryClient = useQueryClient();

  const productsQuery = useQuery({
    queryKey: ['products'],
    queryFn: async () => {
      const { data, error } = await supabase
        .from('products')
        .select('*')
        .order('sku');

      if (error) throw error;
      return data as ProductPrice[];
    },
  });

  const updatePrice = useMutation({
    mutationFn: async (product: ProductPrice) => {
      // First update the product
      const { error: productError } = await supabase
        .from('products')
        .update({
          regular_price: product.regular_price,
          price_2: product.price_2,
          price_3: product.price_3,
          price_4: product.price_4,
          updated_at: new Date().toISOString()
        })
        .eq('sku', product.sku);

      if (productError) throw productError;

      // Then record the change in price_changes
      const { data: { user } } = await supabase.auth.getUser();
      if (!user) throw new Error('No authenticated user');

      const { error: changeError } = await supabase
        .from('price_changes')
        .insert({
          product_id: product.id,
          sku: product.sku,
          field_name: 'prices',
          old_value: null, // We'll implement this later
          new_value: null, // We'll implement this later
          changed_by: user.id
        });

      if (changeError) throw changeError;

      return product;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['products'] });
    },
  });

  return {
    products: productsQuery.data || [],
    isLoading: productsQuery.isLoading,
    error: productsQuery.error,
    updatePrice: updatePrice.mutate,
    isUpdating: updatePrice.isPending,
  };
}