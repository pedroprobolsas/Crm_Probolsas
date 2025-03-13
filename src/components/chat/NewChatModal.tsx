import React, { useState } from 'react';
import { Search, Plus, Loader2, X, MessageCircle } from 'lucide-react';
import { useClients } from '../../lib/hooks/useClients';
import { useConversations } from '../../lib/hooks/useConversations';
import { useAuthStore } from '../../lib/store/authStore';
import { toast } from 'sonner';
import type { Client, ClientInsert } from '../../lib/types';

interface NewChatModalProps {
  isOpen: boolean;
  onClose: () => void;
  onSelectClient: (client: Client) => void;
}

export function NewChatModal({ isOpen, onClose, onSelectClient }: NewChatModalProps) {
  const [searchTerm, setSearchTerm] = useState('');
  const [showNewClientForm, setShowNewClientForm] = useState(false);
  const [newClient, setNewClient] = useState<ClientInsert>({
    name: '',
    email: '',
    phone: '',
    company: '',
    description: '',
    brand: '',
    status: 'active'
  });

  const { user } = useAuthStore();
  const { clients, isLoading, createClient, isCreating } = useClients({
    search: searchTerm
  });
  const { createConversation, isCreating: isCreatingConversation } = useConversations();

  const handleCreateClient = async (e: React.FormEvent) => {
    e.preventDefault();
    try {
      const client = await createClient(newClient);
      await handleStartConversation(client);
    } catch (error) {
      console.error('Error al crear el cliente:', error);
      toast.error('Error al crear el cliente');
    }
  };

  const handleStartConversation = async (client: Client) => {
    if (!user) {
      toast.error('No hay usuario autenticado');
      return;
    }

    try {
      // Create a new conversation
      const conversation = await createConversation({
        client_id: client.id,
        agent_id: user.id,
        whatsapp_chat_id: `chat_${Date.now()}`, // Temporary ID until WhatsApp integration
        last_message: 'Inicio de conversación',
        last_message_at: new Date().toISOString()
      });

      // Notify parent component
      onSelectClient(client);
      onClose();
      
      toast.success(`Chat iniciado con ${client.name}`);
    } catch (error) {
      console.error('Error al iniciar la conversación:', error);
      toast.error('Error al iniciar la conversación');
    }
  };

  if (!isOpen) return null;

  return (
    <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
      <div className="bg-white rounded-lg w-full max-w-2xl p-6">
        <div className="flex justify-between items-center mb-4">
          <h2 className="text-xl font-semibold text-gray-900">
            {showNewClientForm ? 'Registrar Nuevo Cliente' : 'Nuevo Chat'}
          </h2>
          <button
            onClick={onClose}
            className="text-gray-400 hover:text-gray-500"
          >
            <X className="w-6 h-6" />
          </button>
        </div>

        {showNewClientForm ? (
          <form onSubmit={handleCreateClient}>
            <div className="space-y-4">
              <div>
                <label htmlFor="name" className="block text-sm font-medium text-gray-700">
                  Nombre
                </label>
                <input
                  type="text"
                  id="name"
                  value={newClient.name}
                  onChange={(e) => setNewClient(prev => ({ ...prev, name: e.target.value }))}
                  className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
                  required
                />
              </div>

              <div>
                <label htmlFor="email" className="block text-sm font-medium text-gray-700">
                  Correo Electrónico
                </label>
                <input
                  type="email"
                  id="email"
                  value={newClient.email}
                  onChange={(e) => setNewClient(prev => ({ ...prev, email: e.target.value }))}
                  className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
                  required
                />
              </div>

              <div>
                <label htmlFor="phone" className="block text-sm font-medium text-gray-700">
                  Teléfono (WhatsApp)
                </label>
                <input
                  type="tel"
                  id="phone"
                  value={newClient.phone}
                  onChange={(e) => setNewClient(prev => ({ ...prev, phone: e.target.value }))}
                  placeholder="+52 1 55 1234 5678"
                  className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
                  required
                />
              </div>

              <div>
                <label htmlFor="company" className="block text-sm font-medium text-gray-700">
                  Empresa
                </label>
                <input
                  type="text"
                  id="company"
                  value={newClient.company}
                  onChange={(e) => setNewClient(prev => ({ ...prev, company: e.target.value }))}
                  className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
                  required
                />
              </div>

              <div>
                <label htmlFor="brand" className="block text-sm font-medium text-gray-700">
                  Marca
                </label>
                <input
                  type="text"
                  id="brand"
                  value={newClient.brand}
                  onChange={(e) => setNewClient(prev => ({ ...prev, brand: e.target.value }))}
                  className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
                  required
                  placeholder="Marca principal del cliente"
                />
              </div>

              <div>
                <label htmlFor="description" className="block text-sm font-medium text-gray-700">
                  Descripción
                </label>
                <textarea
                  id="description"
                  value={newClient.description}
                  onChange={(e) => setNewClient(prev => ({ ...prev, description: e.target.value }))}
                  className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
                  required
                  rows={3}
                  placeholder="Describe la actividad principal del cliente"
                />
              </div>
            </div>

            <div className="mt-6 flex justify-end space-x-3">
              <button
                type="button"
                onClick={() => setShowNewClientForm(false)}
                className="px-4 py-2 border border-gray-300 rounded-md text-sm font-medium text-gray-700 hover:bg-gray-50"
              >
                Cancelar
              </button>
              <button
                type="submit"
                disabled={isCreating || isCreatingConversation}
                className="px-4 py-2 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-blue-600 hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 disabled:opacity-50"
              >
                {isCreating || isCreatingConversation ? 'Guardando...' : 'Guardar y Comenzar Chat'}
              </button>
            </div>
          </form>
        ) : (
          <>
            <div className="mb-4">
              <div className="relative">
                <input
                  type="text"
                  placeholder="Buscar por nombre, empresa, marca o descripción..."
                  value={searchTerm}
                  onChange={(e) => setSearchTerm(e.target.value)}
                  className="w-full pl-10 pr-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
                />
                <Search className="w-5 h-5 text-gray-400 absolute left-3 top-2.5" />
              </div>
            </div>

            <div className="mb-4">
              <button
                onClick={() => setShowNewClientForm(true)}
                className="w-full flex items-center justify-center px-4 py-2 border border-gray-300 rounded-md text-sm font-medium text-gray-700 hover:bg-gray-50"
              >
                <Plus className="w-5 h-5 mr-2" />
                Registrar Nuevo Cliente
              </button>
            </div>

            <div className="max-h-96 overflow-y-auto">
              {isLoading ? (
                <div className="flex items-center justify-center py-8">
                  <Loader2 className="w-8 h-8 animate-spin text-blue-600" />
                </div>
              ) : clients.length === 0 ? (
                <div className="text-center py-8 text-gray-500">
                  No se encontraron clientes
                </div>
              ) : (
                <div className="space-y-2">
                  {clients.map((client) => (
                    <button
                      key={client.id}
                      onClick={() => handleStartConversation(client)}
                      className="w-full p-4 text-left hover:bg-gray-50 rounded-lg border border-gray-200"
                    >
                      <div className="flex justify-between items-start">
                        <div>
                          <h3 className="text-sm font-medium text-gray-900">{client.name}</h3>
                          <p className="text-sm text-gray-500">{client.company}</p>
                          <p className="text-sm text-gray-500">Marca: {client.brand}</p>
                        </div>
                        <span className={`px-2 py-1 text-xs font-medium rounded-full ${
                          client.status === 'active'
                            ? 'bg-green-100 text-green-800'
                            : client.status === 'inactive'
                            ? 'bg-gray-100 text-gray-800'
                            : 'bg-red-100 text-red-800'
                        }`}>
                          {client.status === 'active' ? 'Activo' : 
                           client.status === 'inactive' ? 'Inactivo' : 'En riesgo'}
                        </span>
                      </div>
                      <div className="mt-1 text-sm text-gray-500">
                        {client.email} • {client.phone}
                      </div>
                      <p className="mt-2 text-sm text-gray-600 line-clamp-2">
                        {client.description}
                      </p>
                    </button>
                  ))}
                </div>
              )}
            </div>
          </>
        )}
      </div>
    </div>
  );
}