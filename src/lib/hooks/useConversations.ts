import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { supabase } from '../supabase';
import type { Conversation, ConversationInsert, ConversationUpdate } from '../types';

export function useConversations() {
  const queryClient = useQueryClient();

  const query = useQuery({
    queryKey: ['conversations'],
    queryFn: async () => {
      const { data, error } = await supabase
        .from('conversations')
        .select(`
          *,
          clients:client_id (
            name,
            company
          )
        `)
        .order('last_message_at', { ascending: false });

      if (error) throw error;
      
      // Transformar los datos para que coincidan con la estructura esperada
      const transformedData = data?.map(conv => ({
        ...conv,
        client_name: conv.clients?.name,
        client_company: conv.clients?.company
      }));
      
      // Filtrar para mostrar solo la conversación más reciente por cliente
      const clientConversations = new Map();
      
      transformedData?.forEach(conv => {
        if (!clientConversations.has(conv.client_id) || 
            new Date(conv.last_message_at) > new Date(clientConversations.get(conv.client_id).last_message_at)) {
          clientConversations.set(conv.client_id, conv);
        }
      });
      
      // Convertir el Map a un array y ordenar por last_message_at (más reciente primero)
      return Array.from(clientConversations.values())
        .sort((a, b) => new Date(b.last_message_at).getTime() - new Date(a.last_message_at).getTime());
    },
  });

  const createMutation = useMutation({
    mutationFn: async (newConversation: ConversationInsert) => {
      const { data, error } = await supabase
        .from('conversations')
        .insert(newConversation)
        .select()
        .single();

      if (error) throw error;
      return data;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['conversations'] });
    },
  });

  const updateMutation = useMutation({
    mutationFn: async ({ id, ...updates }: ConversationUpdate & { id: string }) => {
      const { data, error } = await supabase
        .from('conversations')
        .update(updates)
        .eq('id', id)
        .select()
        .single();

      if (error) throw error;
      return data;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['conversations'] });
    },
  });

  return {
    conversations: query.data ?? [],
    isLoading: query.isLoading,
    error: query.error,
    createConversation: createMutation.mutate,
    updateConversation: updateMutation.mutate,
    isCreating: createMutation.isPending,
    isUpdating: updateMutation.isPending,
  };
}
