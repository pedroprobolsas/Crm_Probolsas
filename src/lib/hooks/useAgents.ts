import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { supabase } from '../supabase';
import type { Agent, AgentDB, AgentInsert, AgentUpdate } from '../types';

// Utility functions to transform between DB and UI formats
function toUIFormat(agent: AgentDB): Agent {
  return {
    id: agent.id,
    name: agent.name,
    email: agent.email,
    whatsappNumber: agent.whatsapp_number,
    role: agent.role,
    status: agent.status,
    avatar: agent.avatar,
    activeChats: agent.active_chats,
    satisfactionScore: agent.satisfaction_score,
    lastActive: agent.last_active,
    createdAt: agent.created_at,
    updatedAt: agent.updated_at,
    deactivationReason: agent.deactivation_reason,
    deactivationDate: agent.deactivation_date,
  };
}

function toDBFormat(agent: Partial<Agent>): Partial<AgentDB> {
  const dbAgent: Partial<AgentDB> = {};

  if (agent.name !== undefined) dbAgent.name = agent.name;
  if (agent.email !== undefined) dbAgent.email = agent.email;
  if (agent.whatsappNumber !== undefined) dbAgent.whatsapp_number = agent.whatsappNumber;
  if (agent.role !== undefined) dbAgent.role = agent.role;
  if (agent.status !== undefined) dbAgent.status = agent.status;
  if (agent.avatar !== undefined) dbAgent.avatar = agent.avatar;
  if (agent.activeChats !== undefined) dbAgent.active_chats = agent.activeChats;
  if (agent.satisfactionScore !== undefined) dbAgent.satisfaction_score = agent.satisfactionScore;
  if (agent.lastActive !== undefined) dbAgent.last_active = agent.lastActive;
  if (agent.deactivationReason !== undefined) dbAgent.deactivation_reason = agent.deactivationReason;
  if (agent.deactivationDate !== undefined) dbAgent.deactivation_date = agent.deactivationDate;

  return dbAgent;
}

export function useAgents() {
  const queryClient = useQueryClient();

  const query = useQuery({
    queryKey: ['agents'],
    queryFn: async () => {
      const { data, error } = await supabase
        .from('agents')
        .select('*')
        .order('name');

      if (error) throw error;
      return (data as AgentDB[]).map(toUIFormat);
    },
  });

  const createMutation = useMutation({
    mutationFn: async (newAgent: Omit<Agent, 'id' | 'createdAt' | 'updatedAt'>) => {
      const { data, error } = await supabase
        .from('agents')
        .insert(toDBFormat(newAgent))
        .select()
        .single();

      if (error) throw error;
      return toUIFormat(data as AgentDB);
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['agents'] });
    },
  });

  const updateMutation = useMutation({
    mutationFn: async ({ id, ...updates }: Partial<Agent> & { id: string }) => {
      // First verify the agent exists
      const { data: existingAgent, error: checkError } = await supabase
        .from('agents')
        .select('id')
        .eq('id', id)
        .maybeSingle();

      if (checkError) throw checkError;
      if (!existingAgent) throw new Error('Agent not found');

      // Then perform the update
      const { data, error } = await supabase
        .from('agents')
        .update(toDBFormat(updates))
        .eq('id', id)
        .select()
        .single();

      if (error) throw error;
      return toUIFormat(data as AgentDB);
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['agents'] });
    },
  });

  const deactivateMutation = useMutation({
    mutationFn: async ({ 
      agentId, 
      reason, 
      effectiveDate, 
      reassignments 
    }: { 
      agentId: string;
      reason: string;
      effectiveDate: string;
      reassignments: Record<string, string>;
    }) => {
      // First verify the agent exists and is active
      const { data: existingAgent, error: checkError } = await supabase
        .from('agents')
        .select('id, status')
        .eq('id', agentId)
        .maybeSingle();

      if (checkError) throw checkError;
      if (!existingAgent) throw new Error('Agent not found');
      if (existingAgent.status === 'inactive') throw new Error('Agent is already inactive');

      // Start a transaction using RPC
      const { error: deactivateError } = await supabase.rpc('deactivate_agent', {
        p_agent_id: agentId,
        p_reason: reason,
        p_effective_date: effectiveDate,
        p_reassignments: reassignments
      });

      if (deactivateError) throw deactivateError;

      // Fetch the updated agent data
      const { data: updatedAgent, error: fetchError } = await supabase
        .from('agents')
        .select('*')
        .eq('id', agentId)
        .single();

      if (fetchError) throw fetchError;
      return toUIFormat(updatedAgent as AgentDB);
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['agents'] });
      queryClient.invalidateQueries({ queryKey: ['assigned-clients'] });
    },
  });

  return {
    agents: query.data ?? [],
    isLoading: query.isLoading,
    error: query.error,
    createAgent: createMutation.mutate,
    updateAgent: updateMutation.mutate,
    deactivateAgent: deactivateMutation.mutate,
    isCreating: createMutation.isPending,
    isUpdating: updateMutation.isPending,
    isDeactivating: deactivateMutation.isPending,
  };
}