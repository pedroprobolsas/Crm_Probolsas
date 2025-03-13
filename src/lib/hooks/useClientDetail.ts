import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { supabase } from '../supabase';
import type { Client, ClientStage, ClientInteraction } from '../types';

export function useClientDetail(clientId: string) {
  const queryClient = useQueryClient();

  const query = useQuery({
    queryKey: ['client', clientId],
    queryFn: async () => {
      const { data, error } = await supabase
        .from('clients')
        .select('*')
        .eq('id', clientId)
        .single();

      if (error) throw error;
      return data as Client;
    },
  });

  const interactionsQuery = useQuery({
    queryKey: ['client-interactions', clientId],
    queryFn: async () => {
      console.log('Fetching interactions for client:', clientId);
      
      const { data, error } = await supabase
        .from('client_interactions')
        .select(`
          *,
          agent:agents(name)
        `)
        .eq('client_id', clientId)
        .order('date', { ascending: false });

      if (error) {
        console.error('Error fetching interactions:', error);
        throw error;
      }

      console.log('Fetched interactions:', data);
      return data as (ClientInteraction & { agent: { name: string } })[];
    },
  });

  const updateMutation = useMutation({
    mutationFn: async (updates: Partial<Client>) => {
      const { data, error } = await supabase
        .from('clients')
        .update({
          ...updates,
          updated_at: new Date().toISOString()
        })
        .eq('id', clientId)
        .select()
        .single();

      if (error) throw error;
      return data as Client;
    },
    onSuccess: (updatedClient) => {
      queryClient.setQueryData(['client', clientId], updatedClient);
      queryClient.invalidateQueries({ queryKey: ['clients'] });
    },
  });

  const updateStageMutation = useMutation({
    mutationFn: async ({ newStage, notes }: { newStage: ClientStage; notes?: string }) => {
      const { data: { user } } = await supabase.auth.getUser();
      if (!user) throw new Error('No hay usuario autenticado');

      const { error } = await supabase.rpc('update_client_stage', {
        p_client_id: clientId,
        p_new_stage: newStage,
        p_agent_id: user.id,
        p_notes: notes
      });

      if (error) throw error;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['client', clientId] });
      queryClient.invalidateQueries({ queryKey: ['client-interactions', clientId] });
    },
  });

  return {
    client: query.data,
    interactions: interactionsQuery.data ?? [],
    isLoading: query.isLoading || interactionsQuery.isLoading,
    error: query.error || interactionsQuery.error,
    updateClient: updateMutation.mutate,
    updateStage: updateStageMutation.mutate,
    isUpdating: updateMutation.isPending || updateStageMutation.isPending,
  };
}