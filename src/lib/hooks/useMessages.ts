import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { supabase } from '../supabase';
import type { Message } from '../types';

export function useMessages(conversationId: string | null) {
  const queryClient = useQueryClient();

  const query = useQuery({
    queryKey: ['messages', conversationId],
    queryFn: async () => {
      if (!conversationId) return [];
      
      const { data, error } = await supabase
        .from('messages')
        .select('*')
        .eq('conversation_id', conversationId)
        .order('created_at', { ascending: true });

      if (error) throw error;
      return data as Message[];
    },
    enabled: !!conversationId,
  });

  const sendMessage = useMutation({
    mutationFn: async (message: Omit<Message, 'id' | 'created_at' | 'updated_at'>) => {
      console.log('Sending message (SUPER SIMPLE):', message);
      
      // Super simple insert
      const { data, error } = await supabase
        .from('messages')
        .insert({
          conversation_id: message.conversation_id,
          content: message.content,
          sender: message.sender,
          sender_id: message.sender_id,
          type: message.type,
          status: message.status
        });
      
      if (error) {
        console.error('Error inserting message:', error);
        throw error;
      }
      
      console.log('Message inserted successfully:', data);
      return data;
    },
    onSuccess: (data) => {
      console.log('Message mutation succeeded:', data);
      queryClient.invalidateQueries({ queryKey: ['messages', conversationId] });
      queryClient.invalidateQueries({ queryKey: ['conversations'] });
    },
    onError: (error) => {
      console.error('Message mutation failed:', error);
    },
  });

  // Subscribe to new messages
  const subscribeToMessages = () => {
    if (!conversationId) return;

    try {
      console.log(`Subscribing to messages for conversation: ${conversationId}`);
      
      const subscription = supabase
        .channel(`messages:${conversationId}`)
        .on(
          'postgres_changes',
          {
            event: 'INSERT',
            schema: 'public',
            table: 'messages',
            filter: `conversation_id=eq.${conversationId}`,
          },
          (payload) => {
            console.log('New message received:', payload);
            queryClient.invalidateQueries({ queryKey: ['messages', conversationId] });
          }
        )
        .subscribe((status) => {
          console.log(`Subscription status for conversation ${conversationId}: ${status}`);
        });

      return () => {
        console.log(`Unsubscribing from messages for conversation: ${conversationId}`);
        subscription.unsubscribe();
      };
    } catch (error) {
      console.error('Error subscribing to messages:', error);
      return undefined;
    }
  };

  return {
    messages: query.data || [],
    isLoading: query.isLoading,
    error: query.error,
    sendMessage: sendMessage.mutate,
    isSending: sendMessage.isPending,
    subscribeToMessages,
  };
}
