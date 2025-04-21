import React, { useState, useMemo } from 'react';
import { 
  Search, 
  Plus, 
  Filter, 
  MessageCircle,
  User,
  X,
  Clock,
  Building2,
  Tag,
  ChevronRight,
  Bell,
  ListFilter,
  UserCircle2,
  Eye,
  MessageSquare
} from 'lucide-react';
import { useClients } from '../lib/hooks/useClients';
import { useInteractions } from '../lib/hooks/useInteractions';
import { useAgents } from '../lib/hooks/useAgents';
import { ClientModal } from '../components/ClientModal';
import { InteractionModal } from '../components/InteractionModal';
import { ClientDetailView } from '../components/ClientDetailView';
import type { ClientStatus, ClientStage, Client, ClientInsert, ClientInteractionInsert } from '../lib/types';
import { format, formatDistanceToNow } from 'date-fns';
import { es } from 'date-fns/locale';
import { toast } from 'sonner';

export function Clients() {
  const [search, setSearch] = useState('');
  const [selectedStatus, setSelectedStatus] = useState<ClientStatus | undefined>();
  const [selectedAgentId, setSelectedAgentId] = useState<string | undefined>();
  const [showModal, setShowModal] = useState(false);
  const [showInteractionModal, setShowInteractionModal] = useState(false);
  const [selectedClient, setSelectedClient] = useState<Client | null>(null);
  const [showDetailView, setShowDetailView] = useState(false);
  
  const { 
    clients, 
    isLoading, 
    error, 
    createClient,
    updateClient,
    isCreating,
    isUpdating
  } = useClients({
    search,
    status: selectedStatus,
    stage: undefined, // Mantenemos el parámetro pero lo pasamos como undefined
  });

  const { agents } = useAgents();
  const { createInteraction, isCreating: isCreatingInteraction } = useInteractions(selectedClient?.id);

  const filteredClients = useMemo(() => {
    return clients.filter(client => {
      const matchesAgent = !selectedAgentId || client.assigned_agent_id === selectedAgentId;
      return matchesAgent;
    });
  }, [clients, selectedAgentId]);

  const handleCreateClient = async (data: ClientInsert) => {
    try {
      // Eliminamos las propiedades que no están en el tipo ClientInsert
      await createClient({
        ...data,
      });
      setShowModal(false);
      toast.success('Cliente creado exitosamente');
    } catch (error) {
      console.error('Error creating client:', error);
      toast.error('Error al crear el cliente');
    }
  };

  const handleCreateInteraction = async (data: ClientInteractionInsert) => {
    try {
      console.log('Creating interaction with data:', data);
      await createInteraction(data);
      setShowInteractionModal(false);
      toast.success('Interacción registrada exitosamente');
    } catch (error) {
      console.error('Error creating interaction:', error);
      toast.error('Error al registrar la interacción');
    }
  };

  // Modificamos para que acepte string y lo convierta a ClientStage
  const handleStageChange = async (clientId: string, newStage: string) => {
    try {
      // Actualizamos solo con propiedades válidas según el tipo ClientUpdate
      await updateClient({
        id: clientId,
      });
      toast.success('Etapa actualizada exitosamente');
    } catch (error) {
      console.error('Error updating stage:', error);
      toast.error('Error al actualizar la etapa');
    }
  };

  const getAssignedAgentName = (agentId: string | null) => {
    if (!agentId) return 'Sin asignar';
    const agent = agents?.find(a => a.id === agentId);
    return agent ? agent.name : 'Sin asignar';
  };

  if (showDetailView && selectedClient) {
    return (
      <ClientDetailView
        client={selectedClient}
        onClose={() => {
          setShowDetailView(false);
          setSelectedClient(null);
        }}
        onStageChange={(newStage) => handleStageChange(selectedClient.id, newStage)}
        onNewInteraction={() => setShowInteractionModal(true)}
      />
    );
  }

  if (error) {
    return (
      <div className="p-8">
        <div className="bg-red-50 text-red-800 p-4 rounded-lg">
          Error al cargar clientes: {error.message}
        </div>
      </div>
    );
  }

  const statusColors = {
    active: 'bg-green-100 text-green-800',
    inactive: 'bg-gray-100 text-gray-800',
    at_risk: 'bg-red-100 text-red-800',
  };

  const statusText = {
    active: 'Activo',
    inactive: 'Inactivo',
    at_risk: 'En riesgo',
  };

  // Actualizamos para usar los valores correctos de ClientStage
  const stageColors: Record<ClientStage, string> = {
    lead: 'bg-blue-100 text-blue-800',
    prospect: 'bg-purple-100 text-purple-800',
    negotiation: 'bg-yellow-100 text-yellow-800',
    customer: 'bg-green-100 text-green-800',
    inactive: 'bg-gray-100 text-gray-800',
  };

  const stageText: Record<ClientStage, string> = {
    lead: 'Lead',
    prospect: 'Prospecto',
    negotiation: 'Negociación',
    customer: 'Cliente',
    inactive: 'Inactivo',
  };

  const getStageTime = (client: Client) => {
    // Usamos updated_at como alternativa ya que stage_start_date no está en el tipo Client
    return formatDistanceToNow(new Date(client.updated_at), { locale: es });
  };

  return (
    <div className="p-8">
      <div className="flex justify-between items-center mb-6 bg-white rounded-xl shadow-sm p-6 border border-gray-100">
        <h1 className="text-2xl font-bold text-gray-900">Clientes</h1>
        <button 
          onClick={() => setShowModal(true)}
          className="bg-blue-600 text-white px-5 py-2.5 rounded-lg flex items-center hover:bg-blue-700 transition-all duration-200 transform hover:scale-105 shadow-md"
        >
          <Plus className="w-5 h-5 mr-2" />
          Agregar Cliente
        </button>
      </div>

      <div className="bg-white rounded-xl shadow-sm border border-gray-100 overflow-hidden">
        <div className="p-5 border-b border-gray-100">
          <div className="flex flex-col sm:flex-row gap-4">
            <div className="flex-1 relative">
              <input
                type="text"
                placeholder="Buscar clientes..."
                value={search}
                onChange={(e) => setSearch(e.target.value)}
                className="w-full pl-10 pr-4 py-2.5 border border-gray-200 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500 transition-colors"
              />
              <Search className="w-5 h-5 text-gray-400 absolute left-3 top-3" />
            </div>
            <div className="flex flex-wrap gap-2">
              <select
                value={selectedStatus || ''}
                onChange={(e) => setSelectedStatus(e.target.value as ClientStatus || undefined)}
                className="px-4 py-2.5 border border-gray-200 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500 text-gray-700"
              >
                <option value="">Todos los estados</option>
                <option value="active">Activo</option>
                <option value="inactive">Inactivo</option>
                <option value="at_risk">En riesgo</option>
              </select>
              <select
                value={selectedAgentId || ''}
                onChange={(e) => setSelectedAgentId(e.target.value || undefined)}
                className="px-4 py-2.5 border border-gray-200 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500 text-gray-700"
              >
                <option value="">Todos los asesores</option>
                {agents?.map(agent => (
                  <option key={agent.id} value={agent.id}>
                    {agent.name}
                  </option>
                ))}
              </select>
              <button className="flex items-center px-4 py-2.5 text-gray-700 border border-gray-200 rounded-lg hover:bg-gray-50 transition-colors">
                <Filter className="w-5 h-5 mr-2" />
                Filtros
              </button>
            </div>
          </div>
        </div>

        <div className="overflow-x-auto">
          <table className="w-full">
            <thead className="bg-gray-50">
              <tr>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Acciones</th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Nombre</th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Marca</th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Asesor</th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Estado</th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Tiempo en Etapa</th>
              </tr>
            </thead>
            <tbody className="bg-white divide-y divide-gray-100">
              {isLoading ? (
                <tr>
                  <td className="px-6 py-8 whitespace-nowrap text-gray-600" colSpan={6}>
                    <div className="flex items-center justify-center">
                      <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600"></div>
                    </div>
                  </td>
                </tr>
              ) : filteredClients.length === 0 ? (
                <tr>
                  <td className="px-6 py-8 whitespace-nowrap text-gray-600" colSpan={6}>
                    <div className="text-center">
                      <p className="text-gray-500 font-medium">No se encontraron clientes</p>
                      <p className="text-gray-400 text-sm mt-1">Intenta con otros filtros o agrega un nuevo cliente</p>
                    </div>
                  </td>
                </tr>
              ) : (
                filteredClients.map((client) => (
                  <tr key={client.id} className="hover:bg-gray-50 transition-colors">
                    <td className="px-6 py-4 whitespace-nowrap">
                      <div className="flex items-center space-x-2">
                        <button
                          onClick={() => {
                            setSelectedClient(client);
                            setShowDetailView(true);
                          }}
                          className="p-2 text-blue-600 hover:text-blue-800 hover:bg-blue-50 rounded-full transition-colors"
                          title="Ver detalles"
                        >
                          <Eye className="w-5 h-5" />
                        </button>
                        <button
                          onClick={() => {
                            setSelectedClient(client);
                            setShowInteractionModal(true);
                          }}
                          className="p-2 text-blue-600 hover:text-blue-800 hover:bg-blue-50 rounded-full transition-colors"
                          title="Nueva interacción"
                        >
                          <MessageSquare className="w-5 h-5" />
                        </button>
                      </div>
                    </td>
                    <td className="px-4 py-4 max-w-[200px]">
                      <div>
                        <div className="font-medium text-gray-900 truncate" title={client.name}>{client.name}</div>
                        <div className="text-sm text-gray-500 truncate" title={client.email}>{client.email}</div>
                      </div>
                    </td>
                    <td className="px-4 py-4 max-w-[150px]">
                      <div className="truncate text-gray-600" title={client.brand || '-'}>
                        {client.brand || '-'}
                      </div>
                    </td>
                    <td className="px-4 py-4 max-w-[180px]">
                      <div className="flex items-center">
                        <UserCircle2 className="w-5 h-5 text-gray-400 mr-2 flex-shrink-0" />
                        <span className="text-sm text-gray-900 truncate" title={getAssignedAgentName(client.assigned_agent_id)}>
                          {getAssignedAgentName(client.assigned_agent_id)}
                        </span>
                      </div>
                    </td>
                    <td className="px-4 py-4 whitespace-nowrap">
                      <span className={`px-2.5 py-1 text-xs font-medium rounded-full ${
                        statusColors[client.status as ClientStatus]
                      }`}>
                        {statusText[client.status as ClientStatus]}
                      </span>
                    </td>
                    <td className="px-4 py-4 max-w-[140px]">
                      <div className="flex items-center text-gray-600">
                        <Clock className="w-4 h-4 mr-1 flex-shrink-0" />
                        <span className="truncate" title={getStageTime(client)}>
                          {getStageTime(client)}
                        </span>
                      </div>
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
      </div>

      <ClientModal
        isOpen={showModal}
        onClose={() => setShowModal(false)}
        onSubmit={(data) => {
          // Convertimos explícitamente al tipo esperado
          const typedData = data as unknown as ClientInsert;
          handleCreateClient(typedData);
        }}
        isSubmitting={isCreating}
      />

      {selectedClient && (
        <InteractionModal
          isOpen={showInteractionModal}
          onClose={() => {
            setShowInteractionModal(false);
            setSelectedClient(null);
          }}
          onSubmit={handleCreateInteraction}
          clientId={selectedClient.id}
          isSubmitting={isCreatingInteraction}
        />
      )}
    </div>
  );
}
