import { useQuery, useMutation } from '@tanstack/react-query';
import { supabase } from '../supabase';
import type { Message } from '../types';

export function useAI() {
  const generateSuggestions = useMutation({
    mutationFn: async (context: { messages: Message[]; clientInfo: any }) => {
      const { data, error } = await supabase.functions.invoke('generate-suggestions', {
        body: {
          messages: context.messages,
          clientInfo: context.clientInfo,
        },
      });

      if (error) throw error;
      return data.suggestions as string[];
    },
  });

  return {
    generateSuggestions: generateSuggestions.mutate,
    isGenerating: generateSuggestions.isPending,
    error: generateSuggestions.error,
  };
}