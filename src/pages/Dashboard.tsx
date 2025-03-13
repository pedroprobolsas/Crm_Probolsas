import React from 'react';
import { BarChart3, Users, Package, TrendingUp, AlertTriangle, Clock, MessageCircle } from 'lucide-react';
import { useQuery } from '@tanstack/react-query';
import { useNavigate } from 'react-router-dom';
import { supabase } from '../lib/supabase';
import { format } from 'date-fns';
import { es } from 'date-fns/locale';

export function Dashboard() {
  const navigate = useNavigate();
  const stats = [
    { id: 'total-clients', label: 'Total Clients', value: '156', icon: Users, trend: '+12%' },
    { id: 'active-products', label: 'Active Products', value: '43', icon: Package, trend: '+5%' },
    { id: 'monthly-sales', label: 'Monthly Sales', value: '$45,231', icon: TrendingUp, trend: '+8%' },
  ];

  // Fetch recent activities
  const { data: activities = [], isLoadingActivities } = useQuery({
    queryKey: ['recent-activities'],
    queryFn: async () => {
      const { data, error } = await supabase
        .from('client_interactions')
        .select(`
          id,
          type,
          date,
          notes,
          client:clients(name, company)
        `)
        .order('date', { ascending: false })
        .limit(5);

      if (error) throw error;
      return data;
    }
  });

  // Fetch notifications with unique clients and highest days without interaction
  const { data: notifications = [], isLoading } = useQuery({
    queryKey: ['notifications'],
    queryFn: async () => {
      const { data, error } = await supabase
        .from('pending_alerts')
        .select('*')
        .order('days_without_interaction', { ascending: false });

      if (error) throw error;

      // Create a map to store only the notification with highest days for each client
      const clientMap = new Map();
      
      data.forEach(notification => {
        const existingNotification = clientMap.get(notification.client_id);
        if (!existingNotification || notification.days_without_interaction > existingNotification.days_without_interaction) {
          clientMap.set(notification.client_id, {
            ...notification,
            uniqueId: `${notification.id}-${Date.now()}-${Math.random().toString(36).substring(7)}`
          });
        }
      });

      // Convert map values back to array and sort by days_without_interaction
      return Array.from(clientMap.values())
        .sort((a, b) => b.days_without_interaction - a.days_without_interaction)
        .slice(0, 5); // Limit to 5 notifications
    },
    refetchInterval: 30000 // Refetch every 30 seconds
  });

  const getAlertColor = (level: string) => {
    switch (level) {
      case 'critical':
        return 'bg-red-100 text-red-800 border-red-200';
      case 'high':
        return 'bg-orange-100 text-orange-800 border-orange-200';
      case 'medium':
        return 'bg-yellow-100 text-yellow-800 border-yellow-200';
      default:
        return 'bg-gray-100 text-gray-800 border-gray-200';
    }
  };

  const handleChatClick = async (clientId: string, clientName: string) => {
    try {
      // Check if there's an existing conversation
      const { data: existingConversation, error: conversationError } = await supabase
        .from('conversations')
        .select('id')
        .eq('client_id', clientId)
        .order('created_at', { ascending: false })
        .limit(1)
        .single();

      if (conversationError && conversationError.code !== 'PGRST116') {
        throw conversationError;
      }

      // Navigate to communications page with client info
      navigate('/communications', { 
        state: { 
          openChat: true,
          clientId,
          clientName,
          conversationId: existingConversation?.id
        }
      });
    } catch (error) {
      console.error('Error checking conversation:', error);
      // Still navigate but without conversation ID
      navigate('/communications', {
        state: {
          openChat: true,
          clientId,
          clientName
        }
      });
    }
  };

  return (
    <div className="p-8">
      <h1 className="text-2xl font-bold text-gray-900 mb-6">Panel Principal</h1>
      
      <div className="grid grid-cols-1 md:grid-cols-3 gap-6 mb-8">
        {stats.map((stat) => (
          <div key={stat.id} className="bg-white rounded-lg shadow p-6">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm font-medium text-gray-600">{stat.label}</p>
                <p className="text-2xl font-semibold text-gray-900 mt-1">{stat.value}</p>
              </div>
              <div className="bg-blue-50 p-3 rounded-lg">
                <stat.icon className="w-6 h-6 text-blue-600" />
              </div>
            </div>
            <div className="mt-4">
              <span className="text-sm font-medium text-green-600">{stat.trend}</span>
              <span className="text-sm text-gray-600 ml-2">vs last month</span>
            </div>
          </div>
        ))}
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <div className="bg-white rounded-lg shadow p-6">
          <h2 className="text-lg font-semibold text-gray-900 mb-4">Actividad Reciente</h2>
          <div className="space-y-4">
            {isLoadingActivities ? (
              <div className="text-center py-4">
                <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600 mx-auto"></div>
                <p className="text-sm text-gray-500 mt-2">Cargando actividades...</p>
              </div>
            ) : activities.length === 0 ? (
              <div className="text-center py-8">
                <Clock className="w-12 h-12 text-gray-400 mx-auto mb-2" />
                <p className="text-gray-500">No hay actividades recientes</p>
              </div>
            ) : (
              activities.map((activity) => (
                <div key={activity.id} className="flex items-start space-x-3">
                  <div className="flex-shrink-0">
                    <div className="w-8 h-8 rounded-full bg-blue-100 flex items-center justify-center">
                      <Clock className="w-4 h-4 text-blue-600" />
                    </div>
                  </div>
                  <div>
                    <p className="text-sm text-gray-900">{activity.notes}</p>
                    <div className="mt-1 text-xs text-gray-500">
                      {activity.client?.name} • {format(new Date(activity.date), 'HH:mm')}
                    </div>
                  </div>
                </div>
              ))
            )}
          </div>
        </div>

        <div className="bg-white rounded-lg shadow p-6">
          <div className="flex items-center justify-between mb-4">
            <h2 className="text-lg font-semibold text-gray-900">Alerta de Seguimientos</h2>
            <span className="text-sm text-gray-500">
              {notifications.length} alertas pendientes
            </span>
          </div>
          
          <div className="space-y-4">
            {isLoading ? (
              <div className="text-center py-4">
                <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600 mx-auto"></div>
                <p className="text-sm text-gray-500 mt-2">Cargando alertas...</p>
              </div>
            ) : notifications.length === 0 ? (
              <div className="text-center py-8">
                <AlertTriangle className="w-12 h-12 text-gray-400 mx-auto mb-2" />
                <p className="text-gray-500">No hay alertas pendientes</p>
              </div>
            ) : (
              notifications.map((notification) => (
                <div
                  key={notification.uniqueId}
                  className="p-4 rounded-lg border hover:bg-gray-50 transition-colors cursor-pointer"
                >
                  <div className="flex items-start justify-between">
                    <div className="flex-1">
                      <div className="flex items-center mb-1">
                        <span className={`px-2 py-0.5 rounded-full text-xs font-medium ${
                          getAlertColor(notification.alert_level)
                        }`}>
                          {notification.alert_level === 'critical' ? 'Crítica' :
                           notification.alert_level === 'high' ? 'Alta' :
                           notification.alert_level === 'medium' ? 'Media' : 'Normal'}
                        </span>
                      </div>
                      <p className="text-sm font-medium text-gray-900">
                        {notification.client_name}
                      </p>
                      <p className="text-sm text-gray-600">
                        {notification.client_company}
                      </p>
                      <div className="mt-1 flex items-center text-xs text-gray-500">
                        <Clock className="w-4 h-4 mr-1" />
                        {notification.days_without_interaction} días sin interacción
                      </div>
                    </div>
                    <button
                      onClick={(e) => {
                        e.stopPropagation();
                        handleChatClick(notification.client_id, notification.client_name);
                      }}
                      className="ml-2 p-2 text-blue-600 hover:text-blue-800 rounded-full hover:bg-blue-50"
                      title="Iniciar conversación"
                    >
                      <MessageCircle className="w-5 h-5" />
                    </button>
                  </div>
                </div>
              ))
            )}
          </div>

          {notifications.length > 0 && (
            <div className="mt-4 text-center">
              <button className="text-sm text-blue-600 hover:text-blue-800">
                Ver todas las alertas
              </button>
            </div>
          )}
        </div>
      </div>
    </div>
  );
}