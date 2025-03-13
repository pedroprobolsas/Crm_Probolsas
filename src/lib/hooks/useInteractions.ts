import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { supabase } from '../supabase';
import type { ClientInteraction, ClientInteractionInsert } from '../types';

export function useInteractions(clientId?: string) {
  const queryClient = useQueryClient();

  const query = useQuery({
    queryKey: ['interactions', clientId],
    queryFn: async () => {
      if (!clientId) return [];
      
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
    enabled: !!clientId,
  });

  const createMutation = useMutation({
    mutationFn: async (newInteraction: ClientInteractionInsert) => {
      console.log('Creating new interaction:', newInteraction);
      
      if (!newInteraction.client_id || !newInteraction.agent_id) {
        throw new Error('client_id and agent_id are required');
      }

      // Format the data for insertion
      const interactionData = {
        client_id: newInteraction.client_id,
        agent_id: newInteraction.agent_id,
        type: newInteraction.type,
        date: newInteraction.date,
        notes: newInteraction.notes.trim(),
        next_action: newInteraction.next_action?.trim() || null,
        next_action_date: newInteraction.next_action_date || null,
        priority: newInteraction.priority,
        status: newInteraction.status,
        attachments: newInteraction.attachments || [],
      };

      console.log('Formatted interaction data:', interactionData);

      const { data, error } = await supabase
        .from('client_interactions')
        .insert(interactionData)
        .select(`
          *,
          agent:agents(name)
        `)
        .single();

      if (error) {
        console.error('Error creating interaction:', error);
        throw error;
      }

      console.log('Successfully created interaction:', data);

      // Also update the client's last_interaction_date
      const { error: clientUpdateError } = await supabase
        .from('clients')
        .update({
          last_interaction_date: newInteraction.date,
          next_action: newInteraction.next_action?.trim() || null,
          next_action_date: newInteraction.next_action_date || null,
          updated_at: new Date().toISOString()
        })
        .eq('id', newInteraction.client_id);

      if (clientUpdateError) {
        console.error('Error updating client:', clientUpdateError);
        throw clientUpdateError;
      }

      return data;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['interactions', clientId] });
      queryClient.invalidateQueries({ queryKey: ['clients'] });
    },
  });

  const updateMutation = useMutation({
    mutationFn: async (interaction: Partial<ClientInteraction> & { id: string }) => {
      console.log('Updating interaction:', interaction);
      
      const { data, error } = await supabase
        .from('client_interactions')
        .update({
          ...interaction,
          notes: interaction.notes?.trim(),
          next_action: interaction.next_action?.trim() || null,
          updated_at: new Date().toISOString()
        })
        .eq('id', interaction.id)
        .select(`
          *,
          agent:agents(name)
        `)
        .single();

      if (error) {
        console.error('Error updating interaction:', error);
        throw error;
      }

      console.log('Successfully updated interaction:', data);
      return data;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['interactions', clientId] });
      queryClient.invalidateQueries({ queryKey: ['clients'] });
    },
  });

  return {
    interactions: query.data ?? [],
    isLoading: query.isLoading,
    error: query.error,
    createInteraction: createMutation.mutate,
    updateInteraction: updateMutation.mutate,
    isCreating: createMutation.isPending,
    isUpdating: updateMutation.isPending,
  };
}