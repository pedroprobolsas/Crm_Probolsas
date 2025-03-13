import React, { useState, useCallback, useMemo, useEffect } from 'react';
import { 
  Users, 
  UserPlus, 
  Search, 
  BarChart2, 
  MessageCircle, 
  Phone,
  Loader2,
  Edit,
  AlertTriangle,
  Bell,
  FileText,
  Filter,
  ArrowRight,
  Calendar,
  Info
} from 'lucide-react';
import { format } from 'date-fns';
import { es } from 'date-fns/locale';
import { useAgents } from '../lib/hooks/useAgents';
import { useClientTracking } from '../lib/hooks/useClientTracking';
import { useAgentReassignment } from '../lib/hooks/useAgentReassignment';
import { AgentModal } from '../components/AgentModal';
import { DeactivateAgentModal } from '../components/DeactivateAgentModal';
import { AgentReport } from '../components/reports/AgentReport';
import { Toaster, toast } from 'sonner';
import type { Agent } from '../lib/types';

type AgentFilter = 'all' | 'active' | 'inactive';

export function AgentManagement() {
  const [searchTerm, setSearchTerm] = useState('');
  const [selectedAgent, setSelectedAgent] = useState<Agent | null>(null);
  const [deactivatingAgent, setDeactivatingAgent] = useState<Agent | null>(null);
  const [showCreateModal, setShowCreateModal] = useState(false);
  const [showReport, setShowReport] = useState(false);
  const [reportAgent, setReportAgent] = useState<Agent | null>(null);
  const [statusFilter, setStatusFilter] = useState<AgentFilter>('active');
  const [successMessage, setSuccessMessage] = useState<string | null>(null);
  const [errorMessage, setErrorMessage] = useState<string | null>(null);

  const { 
    agents, 
    isLoading, 
    error, 
    createAgent, 
    updateAgent, 
    deactivateAgent,
    isCreating, 
    isUpdating,
    isDeactivating 
  } = useAgents();

  const { metrics } = useClientTracking();

  const { 
    assignedClients,
    isLoading: isLoadingClients,
    reassignClients,
    isReassigning
  } = useAgentReassignment(deactivatingAgent?.id || '');

  // Handle toast messages
  useEffect(() => {
    if (successMessage) {
      toast.success(successMessage);
      setSuccessMessage(null);
    }
  }, [successMessage]);

  useEffect(() => {
    if (errorMessage) {
      toast.error(errorMessage);
      setErrorMessage(null);
    }
  }, [errorMessage]);

  const getClientRiskIndicator = useCallback((agentId: string) => {
    const agentMetrics = metrics.byAgent.find(m => m.agent_id === agentId);
    if (!agentMetrics) return null;

    const activePercentage = agentMetrics.active_percentage;
    const atRiskPercentage = (agentMetrics.inactive_clients / 
      (agentMetrics.active_clients + agentMetrics.inactive_clients)) * 100;

    return {
      activePercentage,
      atRiskPercentage,
      needsAttention: activePercentage < 50 || atRiskPercentage > 30
    };
  }, [metrics.byAgent]);

  const filteredAgents = useMemo(() => {
    return agents?.filter(agent => {
      const matchesSearch = agent.name.toLowerCase().includes(searchTerm.toLowerCase()) ||
                          agent.email.toLowerCase().includes(searchTerm.toLowerCase());
      const matchesStatus = statusFilter === 'all' ? true :
                          statusFilter === 'active' ? agent.status !== 'inactive' :
                          agent.status === 'inactive';
      return matchesSearch && matchesStatus;
    });
  }, [agents, searchTerm, statusFilter]);

  const handleCreateAgent = useCallback(async (data: Omit<Agent, 'id' | 'createdAt' | 'updatedAt'>) => {
    try {
      await createAgent(data);
      setShowCreateModal(false);
      setSuccessMessage('Asesor creado exitosamente');
    } catch (error) {
      console.error('Error creating agent:', error);
      setErrorMessage('Error al crear el asesor');
    }
  }, [createAgent]);

  const handleUpdateAgent = useCallback(async (data: Omit<Agent, 'id' | 'createdAt' | 'updatedAt'>) => {
    if (!selectedAgent) return;
    try {
      await updateAgent({ id: selectedAgent.id, ...data });
      setSelectedAgent(null);
      setSuccessMessage('Asesor actualizado exitosamente');
    } catch (error) {
      console.error('Error updating agent:', error);
      setErrorMessage('Error al actualizar el asesor');
    }
  }, [selectedAgent, updateAgent]);

  const handleDeactivateAgent = useCallback(async (data: {
    reason: string;
    details: string;
    effectiveDate: string;
    reassignments: Record<string, string>;
  }) => {
    if (!deactivatingAgent?.id) return;
    
    try {
      await deactivateAgent({
        agentId: deactivatingAgent.id,
        reason: data.details,
        effectiveDate: data.effectiveDate,
        reassignments: data.reassignments
      });
      
      setDeactivatingAgent(null);
      setStatusFilter('inactive');
      setSuccessMessage('Asesor desactivado exitosamente');
    } catch (error) {
      console.error('Error deactivating agent:', error);
      setErrorMessage('Error al desactivar el asesor');
    }
  }, [deactivatingAgent, deactivateAgent]);

  const handleStartDeactivation = useCallback((agent: Agent) => {
    setDeactivatingAgent(agent);
  }, []);

  const handleViewReport = useCallback((agent: Agent) => {
    setReportAgent(agent);
    setShowReport(true);
  }, []);

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'online':
        return 'bg-green-100 text-green-800';
      case 'busy':
        return 'bg-yellow-100 text-yellow-800';
      case 'inactive':
        return 'bg-red-100 text-red-800';
      default:
        return 'bg-gray-100 text-gray-800';
    }
  };

  const getStatusText = (status: string) => {
    switch (status) {
      case 'online':
        return 'En línea';
      case 'busy':
        return 'Ocupado';
      case 'inactive':
        return 'Inactivo';
      default:
        return 'Desconectado';
    }
  };

  if (showReport && reportAgent) {
    return <AgentReport agent={reportAgent} onClose={() => setShowReport(false)} />;
  }

  return (
    <div className="p-8">
      <Toaster position="top-right" />
      
      <div className="flex justify-between items-center mb-6">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">Gestión de Asesores</h1>
          <p className="mt-1 text-sm text-gray-500">
            {filteredAgents?.filter(a => a.status !== 'inactive').length} asesores activos,{' '}
            {filteredAgents?.filter(a => a.status === 'inactive').length} inactivos
          </p>
        </div>
        <button 
          onClick={() => setShowCreateModal(true)}
          className="bg-blue-600 text-white px-4 py-2 rounded-lg flex items-center hover:bg-blue-700"
        >
          <UserPlus className="w-5 h-5 mr-2" />
          Agregar Asesor
        </button>
      </div>

      <div className="bg-white rounded-lg shadow">
        <div className="p-4 border-b border-gray-200">
          <div className="flex flex-col sm:flex-row gap-4">
            <div className="flex-1 relative">
              <input
                type="text"
                placeholder="Buscar asesores..."
                value={searchTerm}
                onChange={(e) => setSearchTerm(e.target.value)}
                className="w-full pl-10 pr-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
              />
              <Search className="w-5 h-5 text-gray-400 absolute left-3 top-2.5" />
            </div>
            <div className="flex gap-2">
              <select
                value={statusFilter}
                onChange={(e) => setStatusFilter(e.target.value as AgentFilter)}
                className="px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
              >
                <option value="all">Todos los asesores</option>
                <option value="active">Asesores activos</option>
                <option value="inactive">Asesores inactivos</option>
              </select>
              <button className="flex items-center px-4 py-2 text-gray-700 border border-gray-300 rounded-lg hover:bg-gray-50">
                <Filter className="w-5 h-5 mr-2" />
                Más Filtros
              </button>
            </div>
          </div>
        </div>

        <div className="overflow-x-auto">
          <table className="w-full">
            <thead className="bg-gray-50">
              <tr>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Asesor</th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Estado</th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">WhatsApp</th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Rol</th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Seguimiento de Clientes</th>
                <th className="px-6 py-3 text-right text-xs font-medium text-gray-500 uppercase tracking-wider">Acciones</th>
              </tr>
            </thead>
            <tbody className="bg-white divide-y divide-gray-200">
              {isLoading ? (
                <tr>
                  <td colSpan={6} className="px-6 py-4 whitespace-nowrap text-sm text-gray-500 text-center">
                    <div className="flex items-center justify-center">
                      <Loader2 className="w-5 h-5 mr-2 animate-spin" />
                      Cargando asesores...
                    </div>
                  </td>
                </tr>
              ) : error ? (
                <tr>
                  <td colSpan={6} className="px-6 py-4 whitespace-nowrap text-sm text-red-500 text-center">
                    Error al cargar los asesores: {error.message}
                  </td>
                </tr>
              ) : filteredAgents?.length === 0 ? (
                <tr>
                  <td colSpan={6} className="px-6 py-4 whitespace-nowrap text-sm text-gray-500 text-center">
                    No se encontraron asesores
                  </td>
                </tr>
              ) : (
                filteredAgents?.map((agent) => {
                  const riskIndicator = getClientRiskIndicator(agent.id);
                  return (
                    <tr key={agent.id} className={`hover:bg-gray-50 ${
                      agent.status === 'inactive' ? 'bg-gray-50' : ''
                    }`}>
                      <td className="px-6 py-4 whitespace-nowrap">
                        <div className="flex items-center">
                          <img
                            src={agent.avatar || `https://ui-avatars.com/api/?name=${encodeURIComponent(agent.name)}`}
                            alt={agent.name}
                            className="w-8 h-8 rounded-full"
                          />
                          <div className="ml-3">
                            <p className="text-sm font-medium text-gray-900">{agent.name}</p>
                            <p className="text-sm text-gray-500">{agent.email}</p>
                          </div>
                        </div>
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap">
                        <div className="flex flex-col">
                          <span className={`px-2 py-1 text-xs font-medium rounded-full ${getStatusColor(agent.status)}`}>
                            {getStatusText(agent.status)}
                          </span>
                          {agent.status === 'inactive' && agent.deactivationDate && (
                            <span className="mt-1 text-xs text-gray-500">
                              Desde: {format(new Date(agent.deactivationDate), 'dd/MM/yyyy', { locale: es })}
                            </span>
                          )}
                        </div>
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap">
                        <button
                          onClick={() => window.open(`https://wa.me/${agent.whatsappNumber}`, '_blank')}
                          className="flex items-center text-sm text-green-600 hover:text-green-800 transition-colors"
                        >
                          <MessageCircle className="w-4 h-4 mr-1" />
                          {agent.whatsappNumber}
                        </button>
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap">
                        <span className="px-2 py-1 text-xs font-medium rounded-full bg-blue-100 text-blue-800">
                          {agent.role === 'admin' ? 'Administrador' : 'Asesor'}
                        </span>
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap">
                        {agent.status !== 'inactive' ? (
                          riskIndicator && (
                            <div className="space-y-1">
                              <div className="flex items-center justify-between">
                                <span className="text-sm text-gray-500">Clientes Activos (30d):</span>
                                <span className={`px-2 py-1 text-xs font-medium rounded-full ${
                                  riskIndicator.activePercentage >= 70 ? 'bg-green-100 text-green-800' :
                                  riskIndicator.activePercentage >= 50 ? 'bg-yellow-100 text-yellow-800' :
                                  'bg-red-100 text-red-800'
                                }`}>
                                  {riskIndicator.activePercentage}%
                                </span>
                              </div>
                              <div className="flex items-center justify-between">
                                <span className="text-sm text-gray-500">Clientes en Riesgo:</span>
                                <span className={`px-2 py-1 text-xs font-medium rounded-full ${
                                  riskIndicator.atRiskPercentage > 30 ? 'bg-red-100 text-red-800' : 'bg-green-100 text-green-800'
                                }`}>
                                  {riskIndicator.atRiskPercentage.toFixed(1)}%
                                </span>
                              </div>
                            </div>
                          )
                        ) : (
                          <div className="flex items-center text-gray-500">
                            <Info className="w-4 h-4 mr-1" />
                            <span className="text-sm">Asesor inactivo</span>
                          </div>
                        )}
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap text-right text-sm font-medium space-x-3">
                        <button 
                          onClick={() => handleViewReport(agent)}
                          className="text-blue-600 hover:text-blue-900"
                          title="Ver reporte detallado"
                        >
                          <FileText className="w-5 h-5" />
                        </button>
                        <button 
                          onClick={() => setSelectedAgent(agent)}
                          className="text-blue-600 hover:text-blue-900"
                          title="Editar asesor"
                        >
                          <Edit className="w-5 h-5" />
                        </button>
                        {agent.status !== 'inactive' && (
                          <button 
                            onClick={() => handleStartDeactivation(agent)}
                            className="text-red-600 hover:text-red-900"
                            title="Desactivar asesor"
                          >
                            <AlertTriangle className="w-5 h-5" />
                          </button>
                        )}
                      </td>
                    </tr>
                  );
                })
              )}
            </tbody>
          </table>
        </div>
      </div>

      {/* Create/Edit Modal */}
      <AgentModal
        isOpen={showCreateModal || selectedAgent !== null}
        onClose={() => {
          setShowCreateModal(false);
          setSelectedAgent(null);
        }}
        onSubmit={selectedAgent ? handleUpdateAgent : handleCreateAgent}
        agent={selectedAgent || undefined}
        isSubmitting={isCreating || isUpdating}
      />

      {/* Deactivate Modal */}
      {deactivatingAgent && (
        <DeactivateAgentModal
          isOpen={true}
          onClose={() => setDeactivatingAgent(null)}
          onConfirm={handleDeactivateAgent}
          agent={deactivatingAgent}
          assignedClients={assignedClients}
          availableAgents={agents.filter(a => a.id !== deactivatingAgent.id && a.status !== 'inactive')}
          isSubmitting={isDeactivating || isReassigning}
        />
      )}
    </div>
  );
}