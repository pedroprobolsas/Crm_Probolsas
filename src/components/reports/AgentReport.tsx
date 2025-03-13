import React, { useState } from 'react';
import { 
  LineChart, 
  Line, 
  BarChart, 
  Bar, 
  XAxis, 
  YAxis, 
  CartesianGrid, 
  Tooltip, 
  Legend, 
  ResponsiveContainer,
  PieChart,
  Pie,
  Cell
} from 'recharts';
import { 
  Users, 
  Clock, 
  AlertTriangle, 
  MessageCircle, 
  CheckCircle, 
  XCircle,
  ArrowLeft,
  MessageCircle as MessageCircle2,
  DollarSign,
  BarChart2,
  FileText,
  Mail,
  ChevronLeft,
  ChevronRight,
  Search
} from 'lucide-react';
import { format } from 'date-fns';
import { es } from 'date-fns/locale';
import { useClientTracking } from '../../lib/hooks/useClientTracking';
import { useAgentReassignment } from '../../lib/hooks/useAgentReassignment';
import type { Agent } from '../../lib/types';

interface AgentReportProps {
  agent: Agent;
  onClose: () => void;
}

const ITEMS_PER_PAGE = 5;
const COLORS = ['#4F46E5', '#10B981', '#F59E0B', '#EF4444'];

export function AgentReport({ agent, onClose }: AgentReportProps) {
  const [currentPage, setCurrentPage] = useState(1);
  const [searchTerm, setSearchTerm] = useState('');
  
  const { metrics, agentPerformance } = useClientTracking();
  const { assignedClients, isLoading } = useAgentReassignment(agent.id);
  
  const agentMetrics = metrics.byAgent.find(m => m.agent_id === agent.id);
  const agentHistory = agentPerformance.filter(p => p.agent_id === agent.id);

  const clientDistribution = [
    { name: '0-30 días', value: agentMetrics?.active_clients || 0 },
    { name: '31-60 días', value: agentMetrics?.inactive_clients || 0 },
    { name: '61-90 días', value: agentMetrics?.at_risk_clients || 0 },
    { name: '+90 días', value: agentMetrics?.lost_clients || 0 },
  ];

  const interactionTypes = [
    { name: 'Llamadas', value: 35 },
    { name: 'Emails', value: 25 },
    { name: 'WhatsApp', value: 30 },
    { name: 'Visitas', value: 10 }
  ];

  const dailyInteractions = Array.from({ length: 30 }, (_, i) => ({
    date: format(new Date(Date.now() - (29 - i) * 24 * 60 * 60 * 1000), 'dd/MM'),
    interactions: Math.floor(Math.random() * 20),
    responseTime: Math.floor(Math.random() * 120)
  }));

  const salesKPIs = {
    quotations: {
      sent: 45,
      approved: 28,
      total: '$125,000',
      conversion: '62%'
    }
  };

  // Filter and paginate clients
  const filteredClients = assignedClients.filter(client => 
    client.client_name.toLowerCase().includes(searchTerm.toLowerCase()) ||
    client.company.toLowerCase().includes(searchTerm.toLowerCase())
  );

  const totalPages = Math.ceil(filteredClients.length / ITEMS_PER_PAGE);
  const paginatedClients = filteredClients.slice(
    (currentPage - 1) * ITEMS_PER_PAGE,
    currentPage * ITEMS_PER_PAGE
  );

  const handlePageChange = (page: number) => {
    setCurrentPage(page);
  };

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'active':
        return 'bg-green-100 text-green-800';
      case 'inactive':
        return 'bg-yellow-100 text-yellow-800';
      case 'at_risk':
        return 'bg-red-100 text-red-800';
      default:
        return 'bg-gray-100 text-gray-800';
    }
  };

  const getStageColor = (stage: string) => {
    switch (stage) {
      case 'communication':
        return 'bg-blue-100 text-blue-800';
      case 'quotation':
        return 'bg-purple-100 text-purple-800';
      case 'deposit':
        return 'bg-yellow-100 text-yellow-800';
      case 'approval':
        return 'bg-green-100 text-green-800';
      case 'shipping':
        return 'bg-orange-100 text-orange-800';
      case 'post_sale':
        return 'bg-gray-100 text-gray-800';
      default:
        return 'bg-gray-100 text-gray-800';
    }
  };

  const formatWhatsAppNumber = (number: string) => {
    return number.replace(/\D/g, '');
  };

  const openWhatsApp = (number: string) => {
    const formattedNumber = formatWhatsAppNumber(number);
    window.open(`https://wa.me/${formattedNumber}`, '_blank');
  };

  return (
    <div className="min-h-screen bg-gray-100">
      {/* Header */}
      <div className="flex items-center justify-between mb-8">
        <button
          onClick={onClose}
          className="flex items-center text-gray-600 hover:text-gray-900"
        >
          <ArrowLeft className="w-5 h-5 mr-2" />
          Volver a Gestión de Asesores
        </button>
        <h1 className="text-2xl font-bold text-gray-900">
          Reporte de Desempeño - {agent.name}
        </h1>
      </div>

      {/* Agent Info Card */}
      <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6 mb-8">
        <div className="flex items-center justify-between">
          <div className="flex items-center">
            <img
              src={agent.avatar || `https://ui-avatars.com/api/?name=${encodeURIComponent(agent.name)}&background=random`}
              alt={agent.name}
              className="w-16 h-16 rounded-full"
            />
            <div className="ml-4">
              <h2 className="text-xl font-semibold text-gray-900">{agent.name}</h2>
              <p className="text-gray-500">{agent.email}</p>
              <div className="flex items-center mt-2">
                <span className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${
                  agent.status === 'online' 
                    ? 'bg-green-100 text-green-800' 
                    : agent.status === 'busy'
                    ? 'bg-yellow-100 text-yellow-800'
                    : 'bg-gray-100 text-gray-800'
                }`}>
                  {agent.status === 'online' ? 'En línea' : agent.status === 'busy' ? 'Ocupado' : 'Desconectado'}
                </span>
                <span className="mx-2">•</span>
                <span className="text-sm text-gray-500">
                  Última actividad: {format(new Date(agent.lastActive), 'PPp', { locale: es })}
                </span>
              </div>
            </div>
          </div>
          <div className="flex space-x-3">
            <button
              onClick={() => openWhatsApp(agent.whatsappNumber)}
              className="flex items-center px-4 py-2 bg-green-500 text-white rounded-lg hover:bg-green-600 transition-colors"
            >
              <MessageCircle className="w-5 h-5 mr-2" />
              WhatsApp
            </button>
            <button
              onClick={() => window.location.href = `mailto:${agent.email}`}
              className="flex items-center px-4 py-2 bg-blue-500 text-white rounded-lg hover:bg-blue-600 transition-colors"
            >
              <Mail className="w-5 h-5 mr-2" />
              Email
            </button>
          </div>
        </div>
      </div>

      {/* Key Metrics Cards */}
      <div className="grid grid-cols-1 md:grid-cols-4 gap-6 mb-8">
        <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm font-medium text-gray-600">Clientes Activos</p>
              <p className="text-2xl font-semibold text-gray-900 mt-1">
                {agentMetrics?.active_clients || 0}/{(agentMetrics?.active_clients || 0) + (agentMetrics?.inactive_clients || 0)}
              </p>
            </div>
            <div className="bg-blue-50 p-3 rounded-lg">
              <Users className="w-6 h-6 text-blue-600" />
            </div>
          </div>
          <div className="mt-4">
            <span className="text-sm font-medium text-green-600">+12%</span>
            <span className="text-sm text-gray-600 ml-2">vs mes anterior</span>
          </div>
        </div>

        <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm font-medium text-gray-600">Tasa de Respuesta</p>
              <p className="text-2xl font-semibold text-gray-900 mt-1">98.5%</p>
            </div>
            <div className="bg-green-50 p-3 rounded-lg">
              <MessageCircle className="w-6 h-6 text-green-600" />
            </div>
          </div>
          <div className="mt-4">
            <span className="text-sm font-medium text-green-600">+2.3%</span>
            <span className="text-sm text-gray-600 ml-2">vs mes anterior</span>
          </div>
        </div>

        <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm font-medium text-gray-600">Tiempo de Respuesta</p>
              <p className="text-2xl font-semibold text-gray-900 mt-1">24 min</p>
            </div>
            <div className="bg-yellow-50 p-3 rounded-lg">
              <Clock className="w-6 h-6 text-yellow-600" />
            </div>
          </div>
          <div className="mt-4">
            <span className="text-sm font-medium text-red-600">+5 min</span>
            <span className="text-sm text-gray-600 ml-2">vs mes anterior</span>
          </div>
        </div>

        <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm font-medium text-gray-600">Efectividad</p>
              <p className="text-2xl font-semibold text-gray-900 mt-1">{agentMetrics?.active_percentage || 0}%</p>
            </div>
            <div className="bg-purple-50 p-3 rounded-lg">
              <BarChart2 className="w-6 h-6 text-purple-600" />
            </div>
          </div>
          <div className="mt-4">
            <span className="text-sm font-medium text-green-600">+5%</span>
            <span className="text-sm text-gray-600 ml-2">vs mes anterior</span>
          </div>
        </div>
      </div>

      {/* Activity Charts */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6 mb-8">
        <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
          <h3 className="text-lg font-semibold text-gray-900 mb-4">Interacciones Diarias</h3>
          <div className="h-80">
            <ResponsiveContainer width="100%" height="100%">
              <LineChart data={dailyInteractions}>
                <CartesianGrid strokeDasharray="3 3" stroke="#E5E7EB" />
                <XAxis dataKey="date" />
                <YAxis />
                <Tooltip />
                <Legend />
                <Line type="monotone" dataKey="interactions" stroke="#4F46E5" name="Interacciones" />
              </LineChart>
            </ResponsiveContainer>
          </div>
        </div>

        <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
          <h3 className="text-lg font-semibold text-gray-900 mb-4">Distribución de Interacciones</h3>
          <div className="h-80">
            <ResponsiveContainer width="100%" height="100%">
              <PieChart>
                <Pie
                  data={interactionTypes}
                  cx="50%"
                  cy="50%"
                  labelLine={false}
                  outerRadius={80}
                  fill="#8884d8"
                  dataKey="value"
                >
                  {interactionTypes.map((entry, index) => (
                    <Cell key={`cell-${index}`} fill={COLORS[index % COLORS.length]} />
                  ))}
                </Pie>
                <Tooltip />
                <Legend />
              </PieChart>
            </ResponsiveContainer>
          </div>
        </div>
      </div>

      {/* Clients Section */}
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        <div className="bg-white rounded-lg shadow">
          <div className="p-6 border-b border-gray-200">
            <div className="flex justify-between items-center mb-4">
              <h3 className="text-lg font-semibold text-gray-900">Clientes Asignados</h3>
              <div className="flex items-center space-x-2">
                <div className="relative">
                  <input
                    type="text"
                    placeholder="Buscar cliente..."
                    value={searchTerm}
                    onChange={(e) => setSearchTerm(e.target.value)}
                    className="pl-10 pr-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
                  />
                  <Search className="w-5 h-5 text-gray-400 absolute left-3 top-2.5" />
                </div>
                <span className="text-sm text-gray-500">
                  {filteredClients.length} clientes
                </span>
              </div>
            </div>
            
            {isLoading ? (
              <div className="flex justify-center py-8">
                <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600"></div>
              </div>
            ) : paginatedClients.length === 0 ? (
              <div className="text-center py-8 text-gray-500">
                {searchTerm ? 'No se encontraron clientes' : 'No hay clientes asignados'}
              </div>
            ) : (
              <>
                <div className="overflow-x-auto">
                  <table className="min-w-full divide-y divide-gray-200">
                    <thead className="bg-gray-50">
                      <tr>
                        <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Cliente</th>
                        <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Estado</th>
                        <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Etapa</th>
                        <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Última Interacción</th>
                        <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Acciones</th>
                      </tr>
                    </thead>
                    <tbody className="bg-white divide-y divide-gray-200">
                      {paginatedClients.map((client) => (
                        <tr key={client.client_id} className="hover:bg-gray-50">
                          <td className="px-6 py-4 whitespace-nowrap">
                            <div>
                              <div className="text-sm font-medium text-gray-900">{client.client_name}</div>
                              <div className="text-sm text-gray-500">{client.company}</div>
                            </div>
                          </td>
                          <td className="px-6 py-4 whitespace-nowrap">
                            <span className={`px-2 py-1 text-xs font-medium rounded-full ${getStatusColor(client.status)}`}>
                              {client.status}
                            </span>
                          </td>
                          <td className="px-6 py-4 whitespace-nowrap">
                            <span className={`px-2 py-1 text-xs font-medium rounded-full ${getStageColor(client.stage)}`}>
                              {client.stage}
                            </span>
                          </td>
                          <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                            {client.last_interaction ? (
                              format(new Date(client.last_interaction), 'dd/MM/yyyy HH:mm', { locale: es })
                            ) : (
                              'Sin interacciones'
                            )}
                          </td>
                          <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                            <button
                              onClick={() => window.location.href = `/clients/${client.client_id}`}
                              className="text-blue-600 hover:text-blue-900"
                            >
                              Ver Detalles
                            </button>
                          </td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>

                {/* Pagination */}
                {totalPages > 1 && (
                  <div className="flex items-center justify-between px-4 py-3 border-t border-gray-200 sm:px-6">
                    <div className="flex items-center">
                      <p className="text-sm text-gray-700">
                        Mostrando <span className="font-medium">{((currentPage - 1) * ITEMS_PER_PAGE) + 1}</span> a{' '}
                        <span className="font-medium">
                          {Math.min(currentPage * ITEMS_PER_PAGE, filteredClients.length)}
                        </span>{' '}
                        de <span className="font-medium">{filteredClients.length}</span> resultados
                      </p>
                    </div>
                    <div className="flex items-center space-x-2">
                      <button
                        onClick={() => handlePageChange(currentPage - 1)}
                        disabled={currentPage === 1}
                        className="p-2 rounded-md border border-gray-300 text-gray-700 hover:bg-gray-50 disabled:opacity-50 disabled:cursor-not-allowed"
                      >
                        <ChevronLeft className="w-5 h-5" />
                      </button>
                      {Array.from({ length: totalPages }, (_, i) => i + 1).map((page) => (
                        <button
                          key={page}
                          onClick={() => handlePageChange(page)}
                          className={`px-3 py-1 rounded-md ${
                            currentPage === page
                              ? 'bg-blue-600 text-white'
                              : 'text-gray-700 hover:bg-gray-50'
                          }`}
                        >
                          {page}
                        </button>
                      ))}
                      <button
                        onClick={() => handlePageChange(currentPage + 1)}
                        disabled={currentPage === totalPages}
                        className="p-2 rounded-md border border-gray-300 text-gray-700 hover:bg-gray-50 disabled:opacity-50 disabled:cursor-not-allowed"
                      >
                        <ChevronRight className="w-5 h-5" />
                      </button>
                    </div>
                  </div>
                )}
              </>
            )}
          </div>
        </div>
      </div>

      {/* Sales KPIs */}
      <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
        <h3 className="text-lg font-semibold text-gray-900 mb-6">KPIs de Ventas</h3>
        <div className="grid grid-cols-1 md:grid-cols-4 gap-6">
          <div className="bg-gray-50 rounded-lg p-4">
            <div className="flex items-center justify-between mb-2">
              <FileText className="w-5 h-5 text-blue-600" />
              <span className="text-xs font-medium text-gray-500">Este mes</span>
            </div>
            <p className="text-2xl font-semibold text-gray-900">{salesKPIs.quotations.sent}</p>
            <p className="text-sm text-gray-600">Cotizaciones Enviadas</p>
          </div>

          <div className="bg-gray-50 rounded-lg p-4">
            <div className="flex items-center justify-between mb-2">
              <CheckCircle className="w-5 h-5 text-green-600" />
              <span className="text-xs font-medium text-gray-500">Este mes</span>
            </div>
            <p className="text-2xl font-semibold text-gray-900">{salesKPIs.quotations.approved}</p>
            <p className="text-sm text-gray-600">Cotizaciones Aprobadas</p>
          </div>

          <div className="bg-gray-50 rounded-lg p-4">
            <div className="flex items-center justify-between mb-2">
              <DollarSign className="w-5 h-5 text-yellow-600" />
              <span className="text-xs font-medium text-gray-500">Este mes</span>
            </div>
            <p className="text-2xl font-semibold text-gray-900">{salesKPIs.quotations.total}</p>
            <p className="text-sm text-gray-600">Monto Total Cotizado</p>
          </div>

          <div className="bg-gray-50 rounded-lg p-4">
            <div className="flex items-center justify-between mb-2">
              <BarChart2 className="w-5 h-5 text-purple-600" />
              <span className="text-xs font-medium text-gray-500">Este mes</span>
            </div>
            <p className="text-2xl font-semibold text-gray-900">{salesKPIs.quotations.conversion}</p>
            <p className="text-sm text-gray-600">Tasa de Conversión</p>
          </div>
        </div>
      </div>
    </div>
  );
}