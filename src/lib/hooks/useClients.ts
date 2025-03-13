import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { supabase } from '../supabase';
import { useAuthStore } from '../store/authStore';
import type { Client, ClientInsert, ClientUpdate, ClientFilters } from '../types';

export function useClients(filters?: ClientFilters) {
  const queryClient = useQueryClient();
  const { profile, isAdmin } = useAuthStore();

  const query = useQuery({
    queryKey: ['clients', filters, profile?.id],
    queryFn: async () => {
      let query = supabase
        .from('clients')
        .select('*')
        .order('created_at', { ascending: false });

      // Si no es admin, solo mostrar los clientes asignados al agente
      if (!isAdmin() && profile) {
        query = query.eq('assigned_agent_id', profile.id);
      }

      if (filters?.search) {
        query = query.or(`name.ilike.%${filters.search}%,company.ilike.%${filters.search}%,email.ilike.%${filters.search}%`);
      }

      if (filters?.status) {
        query = query.eq('status', filters.status);
      }

      if (filters?.stage) {
        query = query.eq('current_stage', filters.stage);
      }

      if (filters?.tags && filters.tags.length > 0) {
        query = query.contains('tags', filters.tags);
      }

      const { data, error } = await query;

      if (error) throw error;
      return data;
    },
  });

  const createMutation = useMutation({
    mutationFn: async (newClient: ClientInsert) => {
      // Asignar el agente actual como responsable si no es admin
      const clientData = {
        ...newClient,
        assigned_agent_id: !isAdmin() ? profile?.id : newClient.assigned_agent_id,
        created_at: new Date().toISOString(),
        updated_at: new Date().toISOString()
      };

      const { data, error } = await supabase
        .from('clients')
        .insert(clientData)
        .select()
        .single();

      if (error) throw error;
      return data;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['clients'] });
    },
  });

  const updateMutation = useMutation({
    mutationFn: async ({ id, ...updates }: ClientUpdate & { id: string }) => {
      // Verificar que el agente tenga permiso para actualizar este cliente
      if (!isAdmin()) {
        const { data: client } = await supabase
          .from('clients')
          .select('assigned_agent_id')
          .eq('id', id)
          .single();

        if (client?.assigned_agent_id !== profile?.id) {
          throw new Error('No tienes permiso para actualizar este cliente');
        }
      }

      const { data, error } = await supabase
        .from('clients')
        .update({
          ...updates,
          updated_at: new Date().toISOString()
        })
        .eq('id', id)
        .select()
        .single();

      if (error) throw error;
      return data;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['clients'] });
    },
  });

  return {
    clients: query.data ?? [],
    isLoading: query.isLoading,
    error: query.error,
    createClient: createMutation.mutate,
    updateClient: updateMutation.mutate,
    isCreating: createMutation.isPending,
    isUpdating: updateMutation.isPending,
  };
}