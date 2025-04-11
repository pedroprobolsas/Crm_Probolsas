import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { supabase } from '../supabase';
import type { Message } from '../types';

/**
 * Sends a message to the webhook directly
 * This is a backup method in case the database trigger fails
 */
export async function sendMessageToWebhook(message: any) {
  try {
    console.log('Sending message to webhook directly:', message);
    
    // Get the webhook URL from app_settings
    const { data: settingsData, error: settingsError } = await supabase
      .from('app_settings')
      .select('value')
      .eq('key', 'webhook_url_production')
      .single();
    
    if (settingsError || !settingsData) {
      console.error('Error getting webhook URL:', settingsError);
      return false;
    }
    
    const webhookUrl = settingsData.value;
    
    // Send the message to the webhook
    const response = await fetch(webhookUrl, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json'
      },
      body: JSON.stringify(message)
    });
    
    if (!response.ok) {
      console.error('Error sending message to webhook:', await response.text());
      return false;
    }
    
    console.log('Message sent to webhook successfully');
    return true;
  } catch (err) {
    console.error('Error sending message to webhook:', err);
    return false;
  }
}

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
      console.log('Sending message:', message);
      
      try {
        // Insert the message into the database
        // The webhook trigger should handle sending it to the webhook
        const { data, error } = await supabase
          .from('messages')
          .insert([
            {
              conversation_id: message.conversation_id,
              content: message.content,
              sender: message.sender,
              sender_id: message.sender_id,
              type: message.type || 'text',
              status: message.status || 'sent'
            }
          ])
          .select();
        
        if (error) {
          console.error('Error inserting message:', error);
          throw error;
        }
        
        console.log('Message inserted successfully:', data);
        
        // As a backup, also try to send the message to the webhook directly
        // This ensures the message is sent even if the trigger fails
        if (message.sender === 'agent' && message.status === 'sent') {
          sendMessageToWebhook({
            id: data[0].id,
            conversation_id: data[0].conversation_id,
            content: data[0].content,
            sender: data[0].sender,
            sender_id: data[0].sender_id,
            type: data[0].type,
            status: data[0].status,
            created_at: data[0].created_at
          }).catch(err => {
            console.error('Error in backup webhook send:', err);
          });
        }
        
        return data;
      } catch (error) {
        console.error('Error in message sending process:', error);
        throw error;
      }
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
