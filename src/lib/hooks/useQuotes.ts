import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { supabase } from '../supabase';
import { useAuthStore } from '../store/authStore';
import type { Quote, QuoteItem } from '../types';

export function useQuotes(clientId?: string) {
  const queryClient = useQueryClient();
  const { profile, isAdmin } = useAuthStore();

  const quotesQuery = useQuery({
    queryKey: ['quotes', clientId],
    queryFn: async () => {
      let query = supabase
        .from('quote_summaries')
        .select('*')
        .order('created_at', { ascending: false });

      // Si no es admin, solo mostrar cotizaciones del agente
      if (!isAdmin() && profile) {
        query = query.eq('agent_id', profile.id);
      }

      if (clientId) {
        query = query.eq('client_id', clientId);
      }

      const { data, error } = await query;
      if (error) throw error;

      // Obtener los items de cada cotización
      const quotesWithItems = await Promise.all(
        data.map(async (quote) => {
          const { data: items, error: itemsError } = await supabase
            .from('quote_items')
            .select('*')
            .eq('quote_id', quote.id);

          if (itemsError) throw itemsError;

          return {
            ...quote,
            items: items || []
          };
        })
      );

      return quotesWithItems;
    },
    enabled: !!clientId || isAdmin(),
  });

  const createQuoteMutation = useMutation({
    mutationFn: async (newQuote: Omit<Quote, 'id' | 'created_at'>) => {
      // Verificar permisos
      if (!isAdmin() && profile?.id !== newQuote.agent_id) {
        throw new Error('No tienes permiso para crear cotizaciones para otros asesores');
      }

      const { data, error } = await supabase
        .from('quotes')
        .insert({
          ...newQuote,
          agent_id: profile?.id
        })
        .select()
        .single();

      if (error) throw error;
      return data;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['quotes'] });
    },
  });

  const updateQuoteStatusMutation = useMutation({
    mutationFn: async ({ quoteId, status }: { quoteId: string; status: Quote['status'] }) => {
      // Verificar permisos
      if (!isAdmin()) {
        const { data: quote } = await supabase
          .from('quotes')
          .select('agent_id')
          .eq('id', quoteId)
          .single();

        if (quote?.agent_id !== profile?.id) {
          throw new Error('No tienes permiso para actualizar esta cotización');
        }
      }

      const { data, error } = await supabase
        .from('quotes')
        .update({ status })
        .eq('id', quoteId)
        .select()
        .single();

      if (error) throw error;
      return data;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['quotes'] });
    },
  });

  return {
    quotes: quotesQuery.data || [],
    isLoading: quotesQuery.isLoading,
    error: quotesQuery.error,
    createQuote: createQuoteMutation.mutate,
    updateQuoteStatus: updateQuoteStatusMutation.mutate,
    isCreating: createQuoteMutation.isPending,
    isUpdating: updateQuoteStatusMutation.isPending,
  };
}