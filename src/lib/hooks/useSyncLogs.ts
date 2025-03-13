import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { supabase } from '../supabase';
import type { SyncLog } from '../types/product';

export function useSyncLogs() {
  const queryClient = useQueryClient();

  const logsQuery = useQuery({
    queryKey: ['sync-logs'],
    queryFn: async () => {
      const { data, error } = await supabase
        .from('sync_logs')
        .select('*')
        .order('created_at', { ascending: false })
        .limit(100);

      if (error) throw error;
      return data as SyncLog[];
    },
  });

  const startSync = useMutation({
    mutationFn: async () => {
      const { data, error } = await supabase.functions.invoke('start-product-sync');
      if (error) throw error;
      return data;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['sync-logs'] });
    },
  });

  const stopSync = useMutation({
    mutationFn: async () => {
      const { data, error } = await supabase.functions.invoke('stop-product-sync');
      if (error) throw error;
      return data;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['sync-logs'] });
    },
  });

  return {
    logs: logsQuery.data || [],
    isLoading: logsQuery.isLoading,
    error: logsQuery.error,
    startSync: startSync.mutate,
    stopSync: stopSync.mutate,
    isStarting: startSync.isPending,
    isStopping: stopSync.isPending,
  };
}