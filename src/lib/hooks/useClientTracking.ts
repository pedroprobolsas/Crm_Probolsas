import React from 'react';
import { useQuery } from '@tanstack/react-query';
import { supabase } from '../supabase';

interface ClientMetrics {
  summary: {
    '0-30': { count: number; percentage: number };
    '31-60': { count: number; percentage: number };
    '61-90': { count: number; percentage: number };
    '90+': { count: number; percentage: number };
  };
  byAgent: Array<{
    agent_id: string;
    agent_name: string;
    active_clients: number;
    active_percentage: number;
    inactive_clients: number;
  }>;
}

interface AgentPerformance {
  month: string;
  agent_name: string;
  total_clients_contacted: number;
  active_clients_30d: number;
  active_percentage: number;
}

export function useClientTracking() {
  const metricsQuery = useQuery({
    queryKey: ['clientMetrics'],
    queryFn: async (): Promise<ClientMetrics> => {
      const { data: interactionMetrics, error: metricsError } = await supabase
        .from('client_interaction_metrics')
        .select('*');

      // Get current month range
      const now = new Date();
      const currentMonthStart = new Date(now.getFullYear(), now.getMonth(), 1).toISOString();
      const nextMonthStart = new Date(now.getFullYear(), now.getMonth() + 1, 1).toISOString();

      const { data: agentMetrics, error: agentError } = await supabase
        .from('agent_performance_metrics')
        .select('*')
        .gte('month', currentMonthStart)
        .lt('month', nextMonthStart);

      if (metricsError) throw metricsError;
      if (agentError) throw agentError;

      // Process metrics into required format
      const summary: ClientMetrics['summary'] = {
        '0-30': { count: 0, percentage: 0 },
        '31-60': { count: 0, percentage: 0 },
        '61-90': { count: 0, percentage: 0 },
        '90+': { count: 0, percentage: 0 },
      };

      const byAgent: ClientMetrics['byAgent'] = agentMetrics.map(agent => ({
        agent_id: agent.agent_id,
        agent_name: agent.agent_name,
        active_clients: agent.active_clients_30d,
        active_percentage: agent.active_percentage,
        inactive_clients: agent.total_clients_contacted - agent.active_clients_30d,
      }));

      interactionMetrics.forEach(metric => {
        const range = metric.interaction_range as keyof typeof summary;
        summary[range] = {
          count: metric.client_count,
          percentage: metric.percentage,
        };
      });

      return { summary, byAgent };
    },
    refetchInterval: 30000, // Refetch every 30 seconds
  });

  const performanceQuery = useQuery({
    queryKey: ['agentPerformance'],
    queryFn: async (): Promise<AgentPerformance[]> => {
      // Get last 12 months
      const now = new Date();
      const twelveMonthsAgo = new Date(now.getFullYear(), now.getMonth() - 11, 1).toISOString();

      const { data, error } = await supabase
        .from('agent_performance_metrics')
        .select('*')
        .gte('month', twelveMonthsAgo)
        .order('month', { ascending: true });

      if (error) throw error;

      return data.map(item => ({
        ...item,
        month: new Date(item.month).toLocaleDateString('es-ES', { month: 'short', year: 'numeric' }),
      }));
    },
    refetchInterval: 30000, // Refetch every 30 seconds
  });

  // Subscribe to real-time changes
  React.useEffect(() => {
    const subscription = supabase
      .channel('client-tracking')
      .on(
        'postgres_changes',
        {
          event: '*',
          schema: 'public',
          table: 'conversations',
        },
        () => {
          // Invalidate queries to refresh data
          metricsQuery.refetch();
          performanceQuery.refetch();
        }
      )
      .subscribe();

    return () => {
      subscription.unsubscribe();
    };
  }, [metricsQuery, performanceQuery]);

  return {
    metrics: metricsQuery.data ?? { 
      summary: {
        '0-30': { count: 0, percentage: 0 },
        '31-60': { count: 0, percentage: 0 },
        '61-90': { count: 0, percentage: 0 },
        '90+': { count: 0, percentage: 0 },
      }, 
      byAgent: [] 
    },
    agentPerformance: performanceQuery.data ?? [],
    isLoading: metricsQuery.isLoading || performanceQuery.isLoading,
    error: metricsQuery.error || performanceQuery.error,
  };
}