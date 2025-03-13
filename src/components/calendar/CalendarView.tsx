import React, { useState, useEffect, useRef } from 'react';
import DatePicker from 'react-datepicker';
import { format, addDays, startOfWeek, endOfWeek, eachDayOfInterval, isSameDay, isToday } from 'date-fns';
import { es } from 'date-fns/locale';
import {
  Calendar as CalendarIcon,
  ChevronLeft,
  ChevronRight,
  Plus,
  Clock,
  User2,
  Phone,
  FileText,
  CheckCircle,
  XCircle,
  AlertCircle,
  Menu,
  MoreVertical,
  Filter,
  Bell,
  Star,
  Trash2,
  Edit,
  Share2
} from 'lucide-react';

type EventType = 'product_development' | 'technical_test' | 'delivery' | 'commercial_visit' | 'post_sale';
type EventPriority = 'high' | 'medium' | 'low';

interface CalendarEvent {
  id: string;
  title: string;
  type: EventType;
  date: Date;
  status: 'pending' | 'completed' | 'cancelled';
  priority: EventPriority;
  references?: string[];
  internalResponsible?: string;
  clientContact?: string;
  notes?: string;
  reminder?: boolean;
}

const eventTypeColors: Record<EventType, { bg: string; text: string; border: string }> = {
  product_development: { bg: 'bg-red-100', text: 'text-red-800', border: 'border-red-200' },
  technical_test: { bg: 'bg-yellow-100', text: 'text-yellow-800', border: 'border-yellow-200' },
  delivery: { bg: 'bg-green-100', text: 'text-green-800', border: 'border-green-200' },
  commercial_visit: { bg: 'bg-blue-100', text: 'text-blue-800', border: 'border-blue-200' },
  post_sale: { bg: 'bg-purple-100', text: 'text-purple-800', border: 'border-purple-200' }
};

const priorityColors: Record<EventPriority, { bg: string; text: string }> = {
  high: { bg: 'bg-red-100', text: 'text-red-800' },
  medium: { bg: 'bg-yellow-100', text: 'text-yellow-800' },
  low: { bg: 'bg-green-100', text: 'text-green-800' }
};

const eventTypeLabels: Record<EventType, string> = {
  product_development: 'Desarrollo de Producto',
  technical_test: 'Prueba Técnica',
  delivery: 'Entrega',
  commercial_visit: 'Visita Comercial',
  post_sale: 'Seguimiento Post-venta'
};

export function CalendarView() {
  const [selectedDate, setSelectedDate] = useState(new Date());
  const [view, setView] = useState<'day' | 'week' | 'month'>(() => {
    return window.innerWidth < 768 ? 'day' : 'week';
  });
  const [showEventModal, setShowEventModal] = useState(false);
  const [selectedEvent, setSelectedEvent] = useState<CalendarEvent | null>(null);
  const [showViewSelector, setShowViewSelector] = useState(false);
  const [showMiniCalendar, setShowMiniCalendar] = useState(false);
  const [showQuickActions, setShowQuickActions] = useState(false);
  const [showFilters, setShowFilters] = useState(false);
  const [isRefreshing, setIsRefreshing] = useState(false);
  const [activeFilters, setActiveFilters] = useState<{
    types: EventType[];
    priorities: EventPriority[];
    status: ('pending' | 'completed' | 'cancelled')[];
  }>({
    types: [],
    priorities: [],
    status: []
  });

  // Pull to refresh functionality
  const pullToRefreshRef = useRef<HTMLDivElement>(null);
  const [pullStartY, setPullStartY] = useState<number | null>(null);
  const [isPulling, setIsPulling] = useState(false);

  const handlePullStart = (e: React.TouchEvent) => {
    if (pullToRefreshRef.current?.scrollTop === 0) {
      setPullStartY(e.touches[0].clientY);
    }
  };

  const handlePullMove = (e: React.TouchEvent) => {
    if (!pullStartY) return;
    
    const pullDistance = e.touches[0].clientY - pullStartY;
    if (pullDistance > 0 && pullDistance < 100) {
      setIsPulling(true);
    }
  };

  const handlePullEnd = async () => {
    if (isPulling) {
      setIsRefreshing(true);
      // Simulated refresh
      await new Promise(resolve => setTimeout(resolve, 1000));
      setIsRefreshing(false);
    }
    setPullStartY(null);
    setIsPulling(false);
  };

  // Long press functionality
  const [longPressTimer, setLongPressTimer] = useState<NodeJS.Timeout | null>(null);
  const [longPressEvent, setLongPressEvent] = useState<CalendarEvent | null>(null);

  const handleLongPressStart = (event: CalendarEvent) => {
    const timer = setTimeout(() => {
      setLongPressEvent(event);
      setShowQuickActions(true);
    }, 500);
    setLongPressTimer(timer);
  };

  const handleLongPressEnd = () => {
    if (longPressTimer) {
      clearTimeout(longPressTimer);
      setLongPressTimer(null);
    }
  };

  // Double tap functionality
  const [lastTap, setLastTap] = useState<number>(0);
  
  const handleDoubleTap = (event: CalendarEvent) => {
    const now = Date.now();
    const DOUBLE_TAP_DELAY = 300;
    
    if (now - lastTap < DOUBLE_TAP_DELAY) {
      setSelectedEvent(event);
      setShowEventModal(true);
    }
    
    setLastTap(now);
  };

  // Swipe functionality for event actions
  const [swipeStart, setSwipeStart] = useState<{ x: number; y: number } | null>(null);
  const [swipeEvent, setSwipeEvent] = useState<CalendarEvent | null>(null);

  const handleSwipeStart = (e: React.TouchEvent, event: CalendarEvent) => {
    setSwipeStart({
      x: e.touches[0].clientX,
      y: e.touches[0].clientY
    });
    setSwipeEvent(event);
  };

  const handleSwipeMove = (e: React.TouchEvent) => {
    if (!swipeStart || !swipeEvent) return;

    const deltaX = e.touches[0].clientX - swipeStart.x;
    const deltaY = e.touches[0].clientY - swipeStart.y;

    // If horizontal swipe is greater than vertical
    if (Math.abs(deltaX) > Math.abs(deltaY)) {
      if (deltaX > 100) {
        // Swipe right - mark as completed
        handleCompleteEvent(swipeEvent);
      } else if (deltaX < -100) {
        // Swipe left - show quick actions
        setShowQuickActions(true);
        setLongPressEvent(swipeEvent);
      }
      setSwipeStart(null);
      setSwipeEvent(null);
    }
  };

  const handleCompleteEvent = (event: CalendarEvent) => {
    // Implementation for completing event
    console.log('Completing event:', event.id);
  };

  // Mock events with priorities
  const events: CalendarEvent[] = [
    {
      id: '1',
      title: 'Muestreo inicial bolsas stand-up',
      type: 'product_development',
      date: new Date(2024, 1, 15),
      status: 'pending',
      priority: 'high',
      references: ['BSU-001', 'BSU-002'],
      internalResponsible: 'Ana Martínez',
      clientContact: 'Juan Pérez',
      notes: 'Preparar muestras en diferentes espesores',
      reminder: true
    },
    {
      id: '2',
      title: 'Prueba de sellado',
      type: 'technical_test',
      date: new Date(2024, 1, 16),
      status: 'completed',
      priority: 'medium',
      references: ['BSU-001'],
      internalResponsible: 'Carlos López',
      clientContact: 'María González',
      notes: 'Verificar resistencia del sello lateral'
    }
  ];

  const getEventsByDate = (date: Date) => {
    let filteredEvents = events.filter(event => 
      isSameDay(new Date(event.date), date)
    );

    // Apply filters
    if (activeFilters.types.length > 0) {
      filteredEvents = filteredEvents.filter(event => 
        activeFilters.types.includes(event.type)
      );
    }
    if (activeFilters.priorities.length > 0) {
      filteredEvents = filteredEvents.filter(event => 
        activeFilters.priorities.includes(event.priority)
      );
    }
    if (activeFilters.status.length > 0) {
      filteredEvents = filteredEvents.filter(event => 
        activeFilters.status.includes(event.status)
      );
    }

    return filteredEvents;
  };

  const renderQuickActions = () => {
    if (!showQuickActions || !longPressEvent) return null;

    return (
      <div className="fixed inset-0 bg-black bg-opacity-50 z-50 flex items-end">
        <div className="bg-white w-full rounded-t-xl p-4 space-y-4">
          <div className="flex justify-between items-center">
            <h3 className="text-lg font-medium">Acciones Rápidas</h3>
            <button
              onClick={() => {
                setShowQuickActions(false);
                setLongPressEvent(null);
              }}
              className="p-2"
            >
              <XCircle className="w-6 h-6" />
            </button>
          </div>
          
          <div className="grid grid-cols-4 gap-4">
            <button className="flex flex-col items-center p-4 text-green-600">
              <CheckCircle className="w-6 h-6 mb-1" />
              <span className="text-xs">Completar</span>
            </button>
            <button className="flex flex-col items-center p-4 text-blue-600">
              <Edit className="w-6 h-6 mb-1" />
              <span className="text-xs">Editar</span>
            </button>
            <button className="flex flex-col items-center p-4 text-yellow-600">
              <Bell className="w-6 h-6 mb-1" />
              <span className="text-xs">Recordatorio</span>
            </button>
            <button className="flex flex-col items-center p-4 text-red-600">
              <Trash2 className="w-6 h-6 mb-1" />
              <span className="text-xs">Eliminar</span>
            </button>
          </div>
        </div>
      </div>
    );
  };

  const renderFilters = () => {
    if (!showFilters) return null;

    return (
      <div className="fixed inset-0 bg-black bg-opacity-50 z-50 flex items-end">
        <div className="bg-white w-full rounded-t-xl p-4 space-y-4 max-h-[80vh] overflow-y-auto">
          <div className="flex justify-between items-center">
            <h3 className="text-lg font-medium">Filtros</h3>
            <button
              onClick={() => setShowFilters(false)}
              className="p-2"
            >
              <XCircle className="w-6 h-6" />
            </button>
          </div>

          <div className="space-y-4">
            <div>
              <h4 className="text-sm font-medium mb-2">Tipo de Evento</h4>
              <div className="grid grid-cols-2 gap-2">
                {Object.entries(eventTypeLabels).map(([type, label]) => (
                  <button
                    key={type}
                    onClick={() => {
                      const newTypes = activeFilters.types.includes(type as EventType)
                        ? activeFilters.types.filter(t => t !== type)
                        : [...activeFilters.types, type as EventType];
                      setActiveFilters({ ...activeFilters, types: newTypes });
                    }}
                    className={`p-2 rounded-lg text-sm ${
                      activeFilters.types.includes(type as EventType)
                        ? 'bg-blue-100 text-blue-800'
                        : 'bg-gray-100 text-gray-800'
                    }`}
                  >
                    {label}
                  </button>
                ))}
              </div>
            </div>

            <div>
              <h4 className="text-sm font-medium mb-2">Prioridad</h4>
              <div className="flex gap-2">
                {(['high', 'medium', 'low'] as const).map((priority) => (
                  <button
                    key={priority}
                    onClick={() => {
                      const newPriorities = activeFilters.priorities.includes(priority)
                        ? activeFilters.priorities.filter(p => p !== priority)
                        : [...activeFilters.priorities, priority];
                      setActiveFilters({ ...activeFilters, priorities: newPriorities });
                    }}
                    className={`px-3 py-1 rounded-full text-sm ${
                      activeFilters.priorities.includes(priority)
                        ? `${priorityColors[priority].bg} ${priorityColors[priority].text}`
                        : 'bg-gray-100 text-gray-800'
                    }`}
                  >
                    {priority === 'high' ? 'Alta' : priority === 'medium' ? 'Media' : 'Baja'}
                  </button>
                ))}
              </div>
            </div>

            <div>
              <h4 className="text-sm font-medium mb-2">Estado</h4>
              <div className="flex gap-2">
                {([
                  { value: 'pending', label: 'Pendiente' },
                  { value: 'completed', label: 'Completado' },
                  { value: 'cancelled', label: 'Cancelado' }
                ] as const).map(({ value, label }) => (
                  <button
                    key={value}
                    onClick={() => {
                      const newStatus = activeFilters.status.includes(value)
                        ? activeFilters.status.filter(s => s !== value)
                        : [...activeFilters.status, value];
                      setActiveFilters({ ...activeFilters, status: newStatus });
                    }}
                    className={`px-3 py-1 rounded-full text-sm ${
                      activeFilters.status.includes(value)
                        ? 'bg-blue-100 text-blue-800'
                        : 'bg-gray-100 text-gray-800'
                    }`}
                  >
                    {label}
                  </button>
                ))}
              </div>
            </div>
          </div>

          <div className="flex justify-end space-x-2 pt-4 border-t">
            <button
              onClick={() => {
                setActiveFilters({ types: [], priorities: [], status: [] });
              }}
              className="px-4 py-2 text-sm text-gray-600"
            >
              Limpiar Filtros
            </button>
            <button
              onClick={() => setShowFilters(false)}
              className="px-4 py-2 bg-blue-600 text-white rounded-lg text-sm"
            >
              Aplicar
            </button>
          </div>
        </div>
      </div>
    );
  };

  const renderDayView = () => {
    const dayEvents = getEventsByDate(selectedDate);

    return (
      <div 
        ref={pullToRefreshRef}
        className="space-y-4 px-4 h-full overflow-y-auto"
        onTouchStart={handlePullStart}
        onTouchMove={handlePullMove}
        onTouchEnd={handlePullEnd}
      >
        {isRefreshing && (
          <div className="flex justify-center py-4">
            <div className="animate-spin rounded-full h-6 w-6 border-b-2 border-blue-600"></div>
          </div>
        )}

        <div className="sticky top-0 bg-white z-10 py-2">
          <h3 className="text-lg font-medium text-gray-900">
            {format(selectedDate, "EEEE d 'de' MMMM", { locale: es })}
          </h3>
        </div>

        {dayEvents.length === 0 ? (
          <div className="text-center py-8 text-gray-500">
            No hay eventos programados
          </div>
        ) : (
          <div className="space-y-4">
            {dayEvents.map((event) => {
              const { bg, text, border } = eventTypeColors[event.type];
              const priorityColor = priorityColors[event.priority];
              
              return (
                <div
                  key={event.id}
                  onTouchStart={(e) => {
                    handleLongPressStart(event);
                    handleSwipeStart(e, event);
                  }}
                  onTouchEnd={() => {
                    handleLongPressEnd();
                    handleDoubleTap(event);
                  }}
                  onTouchMove={handleSwipeMove}
                  className="transform transition-transform active:scale-98"
                >
                  <div className={`p-4 rounded-lg ${bg} ${text} border ${border}`}>
                    <div className="flex items-center justify-between mb-2">
                      <div className="flex items-center space-x-2">
                        <span className="text-sm font-medium">
                          {format(new Date(event.date), 'HH:mm')}
                        </span>
                        <span className={`px-2 py-0.5 rounded-full text-xs font-medium ${priorityColor.bg} ${priorityColor.text}`}>
                          {event.priority === 'high' ? 'Alta' : event.priority === 'medium' ? 'Media' : 'Baja'}
                        </span>
                      </div>
                      <div className="flex items-center space-x-2">
                        {event.reminder && (
                          <Bell className="w-4 h-4" />
                        )}
                        <span className="text-xs font-medium px-2 py-1 rounded-full bg-white bg-opacity-50">
                          {eventTypeLabels[event.type]}
                        </span>
                      </div>
                    </div>
                    
                    <h4 className="font-medium mb-1">{event.title}</h4>
                    
                    {event.clientContact && (
                      <div className="flex items-center text-sm">
                        <User2 className="w-4 h-4 mr-1" />
                        {event.clientContact}
                      </div>
                    )}
                    
                    {event.notes && (
                      <p className="text-sm mt-2 line-clamp-2">{event.notes}</p>
                    )}

                    <div className="flex items-center justify-between mt-2 pt-2 border-t border-current border-opacity-20">
                      <span className={`text-xs ${
                        event.status === 'completed' ? 'text-green-800' :
                        event.status === 'cancelled' ? 'text-red-800' :
                        'text-yellow-800'
                      }`}>
                        {event.status === 'completed' ? 'Completado' :
                         event.status === 'cancelled' ? 'Cancelado' :
                         'Pendiente'}
                      </span>
                      <button className="p-1">
                        <MoreVertical className="w-4 h-4" />
                      </button>
                    </div>
                  </div>
                </div>
              );
            })}
          </div>
        )}
      </div>
    );
  };

  return (
    <div className="h-full flex flex-col bg-gray-100">
      {/* Header */}
      <div className="bg-white border-b border-gray-200 px-4 py-4">
        <div className="flex flex-col space-y-4 md:flex-row md:items-center md:justify-between md:space-y-0">
          <div className="flex items-center justify-between">
            <div className="flex items-center space-x-4">
              <button
                onClick={() => setSelectedDate(new Date())}
                className="inline-flex items-center px-3 py-1.5 border border-gray-300 rounded text-sm font-medium text-gray-700 bg-white hover:bg-gray-50"
              >
                <CalendarIcon className="w-4 h-4 mr-1" />
                Hoy
              </button>
              <div className="flex items-center space-x-1">
                <button
                  onClick={() => setSelectedDate(addDays(selectedDate, -1))}
                  className="p-1.5 hover:bg-gray-100 rounded"
                >
                  <ChevronLeft className="w-5 h-5 text-gray-600" />
                </button>
                <button
                  onClick={() => setShowMiniCalendar(!showMiniCalendar)}
                  className="text-lg font-semibold text-gray-900"
                >
                  {format(selectedDate, "d MMM", { locale: es })}
                </button>
                <button
                  onClick={() => setSelectedDate(addDays(selectedDate, 1))}
                  className="p-1.5 hover:bg-gray-100 rounded"
                >
                  <ChevronRight className="w-5 h-5 text-gray-600" />
                </button>
              </div>
            </div>
            <button
              onClick={() => setShowFilters(true)}
              className="md:hidden p-2 text-gray-600"
            >
              <Filter className="w-5 h-5" />
            </button>
          </div>

          {/* Mini Calendar Popover */}
          {showMiniCalendar && (
            <div className="absolute top-20 left-4 z-50 bg-white rounded-lg shadow-lg p-4">
              <DatePicker
                selected={selectedDate}
                onChange={(date: Date) => {
                  setSelectedDate(date);
                  setShowMiniCalendar(false);
                }}
                inline
                locale={es}
                dayClassName={(date) => {
                  const hasEvents = getEventsByDate(date).length > 0;
                  return hasEvents ? 'font-bold text-blue-600' : undefined;
                }}
              />
            </div>
          )}
        </div>
      </div>

      {/* Calendar Content */}
      <div className="flex-1 overflow-hidden">
        {renderDayView()}
      </div>

      {/* Floating Action Button */}
      <button className="fixed right-4 bottom-4 w-14 h-14 bg-blue-600 text-white rounded-full shadow-lg flex items-center justify-center hover:bg-blue-700">
        <Plus className="w-6 h-6" />
      </button>

      {/* Quick Actions Sheet */}
      {renderQuickActions()}

      {/* Filters Sheet */}
      {renderFilters()}
    </div>
  );
}