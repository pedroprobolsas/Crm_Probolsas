import React, { useState, useEffect } from 'react';
import { Bell, AlertTriangle, Clock, User2, MessageCircle, Inbox as InboxX } from 'lucide-react';
import { format } from 'date-fns';
import { es } from 'date-fns/locale';

interface Notification {
  id: string;
  client_name: string;
  client_company: string;
  days_without_interaction: number;
  alert_level: 'normal' | 'medium' | 'high' | 'critical';
  notification_status: 'pending' | 'sent' | 'read';
}

interface NotificationCenterProps {
  notifications: Notification[];
  onNotificationClick: (notification: Notification) => void;
  onMarkAsRead: (notificationId: string) => void;
}

export function NotificationCenter({ 
  notifications, 
  onNotificationClick, 
  onMarkAsRead 
}: NotificationCenterProps) {
  const [isOpen, setIsOpen] = useState(false);
  const [selectedFilter, setSelectedFilter] = useState<'all' | 'medium' | 'high' | 'critical'>('all');

  // Ensure unique notifications by filtering duplicates based on ID
  const uniqueNotifications = Array.from(new Map(notifications.map(n => [n.id, n])).values());
  const pendingCount = uniqueNotifications.filter(n => n.notification_status === 'pending').length;

  const filteredNotifications = uniqueNotifications.filter(notification => 
    selectedFilter === 'all' || notification.alert_level === selectedFilter
  );

  // Close notification panel when clicking outside
  useEffect(() => {
    const handleClickOutside = (event: MouseEvent) => {
      const target = event.target as HTMLElement;
      if (isOpen && !target.closest('.notification-panel')) {
        setIsOpen(false);
      }
    };

    document.addEventListener('mousedown', handleClickOutside);
    return () => {
      document.removeEventListener('mousedown', handleClickOutside);
    };
  }, [isOpen]);

  const getAlertColor = (level: Notification['alert_level']) => {
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

  const filters = [
    { id: 'all', value: 'all', label: 'Todas' },
    { id: 'medium', value: 'medium', label: 'Media' },
    { id: 'high', value: 'high', label: 'Alta' },
    { id: 'critical', value: 'critical', label: 'Crítica' }
  ];

  return (
    <div className="relative">
      {/* Notification Bell */}
      <button
        onClick={() => setIsOpen(!isOpen)}
        className="relative p-2 text-gray-600 hover:text-gray-900 transition-colors"
      >
        <Bell className="w-6 h-6" />
        {pendingCount > 0 && (
          <span className="absolute top-0 right-0 transform translate-x-1/2 -translate-y-1/2 bg-red-500 text-white text-xs rounded-full w-5 h-5 flex items-center justify-center">
            {pendingCount}
          </span>
        )}
      </button>

      {/* Notification Panel */}
      {isOpen && (
        <div className="notification-panel absolute right-0 mt-2 w-96 bg-white rounded-lg shadow-lg z-50 overflow-hidden">
          <div className="p-4 border-b border-gray-200">
            <div className="flex justify-between items-center mb-4">
              <h3 className="text-lg font-semibold text-gray-900">Notificaciones</h3>
              <button
                onClick={() => setIsOpen(false)}
                className="text-gray-500 hover:text-gray-700"
              >
                <AlertTriangle className="w-5 h-5" />
              </button>
            </div>

            {/* Filters */}
            <div className="flex gap-2">
              {filters.map((filter) => (
                <button
                  key={filter.id}
                  onClick={() => setSelectedFilter(filter.value as any)}
                  className={`px-3 py-1 rounded-full text-sm transition-colors ${
                    selectedFilter === filter.value
                      ? 'bg-blue-100 text-blue-800'
                      : 'bg-gray-100 text-gray-600 hover:bg-gray-200'
                  }`}
                >
                  {filter.label}
                </button>
              ))}
            </div>
          </div>

          <div className="max-h-[60vh] overflow-y-auto">
            {filteredNotifications.length === 0 ? (
              <div className="flex flex-col items-center justify-center py-12 px-4 text-gray-500">
                <InboxX className="w-12 h-12 mb-4 text-gray-400" />
                <p className="text-lg font-medium text-gray-600">No hay alertas pendientes</p>
                <p className="text-sm text-gray-500 mt-1">
                  Las notificaciones aparecerán aquí cuando haya actualizaciones importantes
                </p>
              </div>
            ) : (
              <div className="divide-y divide-gray-200">
                {filteredNotifications.map((notification) => (
                  <div
                    key={notification.id}
                    className={`p-4 hover:bg-gray-50 cursor-pointer transition-colors ${
                      notification.notification_status === 'pending' ? 'bg-blue-50' : ''
                    }`}
                    onClick={() => {
                      onNotificationClick(notification);
                      onMarkAsRead(notification.id);
                      setIsOpen(false);
                    }}
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
                          // Implement quick action
                        }}
                        className="ml-2 p-2 text-blue-600 hover:text-blue-800 hover:bg-blue-50 rounded-full transition-colors"
                        title="Iniciar conversación"
                      >
                        <MessageCircle className="w-5 h-5" />
                      </button>
                    </div>
                  </div>
                ))}
              </div>
            )}
          </div>

          <div className="p-4 border-t border-gray-200 bg-gray-50">
            <button
              onClick={() => {
                // Implement view all notifications
              }}
              className="w-full text-center text-sm text-blue-600 hover:text-blue-800 transition-colors"
            >
              Ver todas las notificaciones
            </button>
          </div>
        </div>
      )}
    </div>
  );
}