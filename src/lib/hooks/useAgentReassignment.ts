import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { supabase } from '../supabase';
import type { AssignedClient } from '../types';

export function useAgentReassignment(agentId: string) {
  const queryClient = useQueryClient();

  const assignedClientsQuery = useQuery({
    queryKey: ['assigned-clients', agentId],
    queryFn: async () => {
      const { data, error } = await supabase.rpc('get_assigned_clients', {
        p_agent_id: agentId
      });

      if (error) throw error;
      return data as AssignedClient[];
    },
    enabled: !!agentId,
  });

  const reassignClientsMutation = useMutation({
    mutationFn: async ({ 
      fromAgentId, 
      reassignments 
    }: { 
      fromAgentId: string;
      reassignments: Record<string, string>;
    }) => {
      const { error } = await supabase.rpc('reassign_clients', {
        p_old_agent_id: fromAgentId,
        p_assignments: reassignments
      });

      if (error) throw error;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['assigned-clients'] });
      queryClient.invalidateQueries({ queryKey: ['agents'] });
    },
  });

  return {
    assignedClients: assignedClientsQuery.data ?? [],
    isLoading: assignedClientsQuery.isLoading,
    error: assignedClientsQuery.error,
    reassignClients: reassignClientsMutation.mutate,
    isReassigning: reassignClientsMutation.isPending,
  };
}