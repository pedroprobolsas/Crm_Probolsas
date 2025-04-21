import { useState } from 'react';
import { 
  Building2, 
  FileText, 
  Users, 
  Briefcase, 
  Scale, 
  ArrowLeft,
  MessageCircle,
  Edit,
  Save,
  X,
  BarChart,
  Mail,
  Phone,
  Tag
} from 'lucide-react';
import "react-datepicker/dist/react-datepicker.css";
import { ClientTimeline } from './ClientTimeline';
import { useClientDetail } from '../lib/hooks/useClientDetail';
import { useQuotes } from '../lib/hooks/useQuotes';
import { QuoteModal } from './quotes/QuoteModal';
import { QuoteList } from './quotes/QuoteList';
import { ClientContacts } from './contacts/ClientContacts';
import { ClientFiscal } from './fiscal/ClientFiscal';
import { ClientCommercial } from './commercial/ClientCommercial';
import { ClientOrganizational } from './organizational/ClientOrganizational';
import type { Client } from '../lib/types';
import { toast } from 'sonner';

interface ClientDetailViewProps {
  client: Client;
  onClose: () => void;
  onStageChange: (newStage: string) => void;
  onNewInteraction: () => void;
}

type TabType = 'general' | 'contacts' | 'fiscal' | 'commercial' | 'quotes' | 'organizational' | 'transactions';

const tabs: { id: TabType; label: string; icon: React.ElementType }[] = [
  { id: 'general', label: 'General', icon: Building2 },
  { id: 'contacts', label: 'Contactos', icon: Users },
  { id: 'fiscal', label: 'Fiscal/Legal', icon: Scale },
  { id: 'commercial', label: 'Comercial', icon: Briefcase },
  { id: 'quotes', label: 'Cotizaciones', icon: FileText },
  { id: 'organizational', label: 'Organizacional', icon: FileText },
  { id: 'transactions', label: 'Transacciones', icon: BarChart },
];

export function ClientDetailView({ client, onClose, onStageChange, onNewInteraction }: ClientDetailViewProps) {
  const [activeTab, setActiveTab] = useState<TabType>('general');
  const [isEditing, setIsEditing] = useState(false);
  const [showQuoteModal, setShowQuoteModal] = useState(false);
  const { updateClient, isUpdating, interactions } = useClientDetail(client.id);
  const { createQuote, isCreating: isCreatingQuote } = useQuotes(client.id);
  const [formData, setFormData] = useState<Client>(client);
  
  // Función para obtener el color de estado del cliente
  const getStatusColor = (status: string) => {
    switch (status) {
      case 'active':
        return 'bg-green-100 text-green-800 border-green-200';
      case 'inactive':
        return 'bg-gray-100 text-gray-800 border-gray-200';
      case 'at_risk':
        return 'bg-red-100 text-red-800 border-red-200';
      default:
        return 'bg-gray-100 text-gray-800 border-gray-200';
    }
  };

  const handleSave = async () => {
    try {
      await updateClient(formData);
      setIsEditing(false);
      toast.success('Cliente actualizado exitosamente');
    } catch (error) {
      console.error('Error updating client:', error);
      toast.error('Error al actualizar el cliente');
    }
  };

  const handleCreateQuote = async (quote: any) => {
    try {
      await createQuote(quote);
      setShowQuoteModal(false);
      toast.success('Cotización creada exitosamente');
    } catch (error) {
      console.error('Error creating quote:', error);
      toast.error('Error al crear la cotización');
    }
  };

  const renderGeneralTab = () => (
    <div className="space-y-6">
      <div className="bg-white rounded-lg shadow-sm border border-gray-100 p-6">
        <h3 className="text-lg font-medium text-gray-900 mb-4 flex items-center">
          <Building2 className="w-5 h-5 mr-2 text-blue-500" />
          Información Básica
        </h3>
        <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
          <div>
            <label className="block text-sm font-medium text-gray-700">Razón Social</label>
            {isEditing ? (
              <input
                type="text"
                value={formData.company}
                onChange={(e) => setFormData({ ...formData, company: e.target.value })}
                className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
              />
            ) : (
              <p className="mt-1 text-sm text-gray-900">{client.company}</p>
            )}
          </div>
          <div>
            <label className="block text-sm font-medium text-gray-700">Nombre de Contacto</label>
            {isEditing ? (
              <input
                type="text"
                value={formData.name}
                onChange={(e) => setFormData({ ...formData, name: e.target.value })}
                className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
              />
            ) : (
              <p className="mt-1 text-sm text-gray-900">{client.name}</p>
            )}
          </div>
          <div>
            <label className="block text-sm font-medium text-gray-700">Correo Electrónico</label>
            {isEditing ? (
              <input
                type="email"
                value={formData.email}
                onChange={(e) => setFormData({ ...formData, email: e.target.value })}
                className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
              />
            ) : (
              <p className="mt-1 text-sm text-gray-900">{client.email}</p>
            )}
          </div>
          <div>
            <label className="block text-sm font-medium text-gray-700">Teléfono</label>
            {isEditing ? (
              <input
                type="tel"
                value={formData.phone}
                onChange={(e) => setFormData({ ...formData, phone: e.target.value })}
                className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
              />
            ) : (
              <p className="mt-1 text-sm text-gray-900">{client.phone}</p>
            )}
          </div>
          <div>
            <label className="block text-sm font-medium text-gray-700">Estado</label>
            {isEditing ? (
              <select
                value={formData.status}
                onChange={(e) => setFormData({ ...formData, status: e.target.value as 'active' | 'inactive' | 'at_risk' })}
                className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
              >
                <option value="active">Activo</option>
                <option value="inactive">Inactivo</option>
                <option value="at_risk">En Riesgo</option>
              </select>
            ) : (
              <p className="mt-1 text-sm text-gray-900">
                <span className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium border ${getStatusColor(client.status)}`}>
                  {client.status === 'active' ? 'Activo' :
                   client.status === 'inactive' ? 'Inactivo' :
                   'En Riesgo'}
                </span>
              </p>
            )}
          </div>
          <div>
            <label className="block text-sm font-medium text-gray-700">Marca</label>
            {isEditing ? (
              <input
                type="text"
                value={formData.brand || ''}
                onChange={(e) => setFormData({ ...formData, brand: e.target.value })}
                className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
              />
            ) : (
              <p className="mt-1 text-sm text-gray-900">{client.brand || 'No especificado'}</p>
            )}
          </div>
        </div>
      </div>

      <div className="bg-white rounded-lg shadow-sm border border-gray-100 p-6">
        <h3 className="text-lg font-medium text-gray-900 mb-4 flex items-center">
          <FileText className="w-5 h-5 mr-2 text-blue-500" />
          Información Adicional
        </h3>
        <div className="space-y-4">
          <div>
            <label className="block text-sm font-medium text-gray-700">Descripción</label>
            {isEditing ? (
              <textarea
                value={formData.description || ''}
                onChange={(e) => setFormData({ ...formData, description: e.target.value })}
                rows={3}
                className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
              />
            ) : (
              <p className="mt-1 text-sm text-gray-900">{client.description || 'Sin descripción'}</p>
            )}
          </div>
          <div>
            <label className="block text-sm font-medium text-gray-700">Notas</label>
            {isEditing ? (
              <textarea
                value={formData.notes || ''}
                onChange={(e) => setFormData({ ...formData, notes: e.target.value })}
                rows={3}
                className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
              />
            ) : (
              <p className="mt-1 text-sm text-gray-900">{client.notes || 'Sin notas'}</p>
            )}
          </div>
          <div>
            <label className="block text-sm font-medium text-gray-700">Etiquetas</label>
            {isEditing ? (
              <div className="mt-1">
                <input
                  type="text"
                  value={formData.tags ? formData.tags.join(', ') : ''}
                  onChange={(e) => {
                    const tagsArray = e.target.value.split(',').map(tag => tag.trim()).filter(tag => tag);
                    setFormData({ ...formData, tags: tagsArray });
                  }}
                  placeholder="Separadas por comas"
                  className="block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
                />
                <p className="mt-1 text-xs text-gray-500">Ingrese las etiquetas separadas por comas</p>
              </div>
            ) : (
              <div className="mt-1 flex flex-wrap gap-2">
                {client.tags && client.tags.length > 0 ? (
                  client.tags.map((tag, index) => (
                    <span 
                      key={index} 
                      className="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-blue-50 text-blue-700 border border-blue-100"
                    >
                      <Tag className="w-3 h-3 mr-1" />
                      {tag}
                    </span>
                  ))
                ) : (
                  <p className="text-sm text-gray-500">Sin etiquetas</p>
                )}
              </div>
            )}
          </div>
        </div>
      </div>

      {client.ai_insights && (
        <div className="bg-white rounded-lg shadow-sm border border-gray-100 p-6">
          <h3 className="text-lg font-medium text-gray-900 mb-4 flex items-center">
            <BarChart className="w-5 h-5 mr-2 text-blue-500" />
            Insights IA
          </h3>
          <div className="prose prose-sm max-w-none">
            <pre className="bg-gray-50 p-4 rounded-lg border border-gray-100 overflow-auto text-sm">
              {typeof client.ai_insights === 'string' 
                ? client.ai_insights 
                : JSON.stringify(client.ai_insights, null, 2)}
            </pre>
          </div>
        </div>
      )}
    </div>
  );

  const renderContactsTab = () => (
    <div className="space-y-8">
      <ClientContacts clientId={client.id} isEditing={isEditing} />
    </div>
  );

  const renderFiscalTab = () => (
    <div className="space-y-6">
      <ClientFiscal clientId={client.id} isEditing={isEditing} />
    </div>
  );

  const renderCommercialTab = () => (
    <div className="space-y-8">
      <ClientCommercial clientId={client.id} isEditing={isEditing} />
    </div>
  );

  const renderQuotesTab = () => (
    <div className="space-y-6">
      <QuoteList clientId={client.id} />
    </div>
  );

  const renderTransactionsTab = () => (
    <div className="space-y-6">
      <div className="bg-white rounded-lg shadow-sm border border-gray-100 p-6">
        <h3 className="text-lg font-medium text-gray-900 mb-4 flex items-center">
          <BarChart className="w-5 h-5 mr-2 text-blue-500" />
          Historial de Interacciones
        </h3>
        <ClientTimeline interactions={interactions} />
      </div>
    </div>
  );

  const renderOrganizationalTab = () => (
    <div className="space-y-6">
      <ClientOrganizational clientId={client.id} isEditing={isEditing} />
    </div>
  );

  const renderActiveTab = () => {
    switch (activeTab) {
      case 'general':
        return renderGeneralTab();
      case 'contacts':
        return renderContactsTab();
      case 'fiscal':
        return renderFiscalTab();
      case 'commercial':
        return renderCommercialTab();
      case 'quotes':
        return renderQuotesTab();
      case 'transactions':
        return renderTransactionsTab();
      case 'organizational':
        return renderOrganizationalTab();
      default:
        return null;
    }
  };

  return (
    <div className="min-h-screen bg-gray-50">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-6">
        {/* Header Mejorado */}
        <div className="mb-6">
          <button
            onClick={onClose}
            className="flex items-center text-gray-600 hover:text-gray-900 transition-colors duration-200 mb-4"
          >
            <ArrowLeft className="w-5 h-5 mr-2" />
            <span className="text-sm font-medium">Volver al listado</span>
          </button>
          
          <div className="bg-white rounded-xl shadow-sm border border-gray-100 p-6">
            <div className="flex flex-col md:flex-row md:items-center md:justify-between gap-4">
              <div className="flex-1">
                <div className="flex items-center">
                  <h1 className="text-2xl font-bold text-gray-900">{client.company}</h1>
                  <span className={`ml-3 px-3 py-1 rounded-full text-xs font-medium ${getStatusColor(client.status)} border`}>
                    {client.status === 'active' ? 'Activo' :
                     client.status === 'inactive' ? 'Inactivo' :
                     'En Riesgo'}
                  </span>
                </div>
                <div className="mt-2 flex flex-wrap items-center text-sm text-gray-500 gap-4">
                  {client.email && (
                    <span className="flex items-center">
                      <Mail className="w-4 h-4 mr-1 text-gray-400" />
                      {client.email}
                    </span>
                  )}
                  {client.phone && (
                    <span className="flex items-center">
                      <Phone className="w-4 h-4 mr-1 text-gray-400" />
                      {client.phone}
                    </span>
                  )}
                  {client.brand && (
                    <span className="flex items-center">
                      <Tag className="w-4 h-4 mr-1 text-gray-400" />
                      {client.brand}
                    </span>
                  )}
                </div>
              </div>
              
              <div className="flex flex-wrap items-center gap-3">
                {isEditing ? (
                  <>
                    <button
                      onClick={handleSave}
                      disabled={isUpdating}
                      className="inline-flex items-center px-4 py-2 border border-transparent rounded-lg shadow-sm text-sm font-medium text-white bg-green-600 hover:bg-green-700 transition-colors duration-200"
                    >
                      <Save className="w-4 h-4 mr-2" />
                      Guardar
                    </button>
                    <button
                      onClick={() => {
                        setIsEditing(false);
                        setFormData(client);
                      }}
                      className="inline-flex items-center px-4 py-2 border border-gray-300 rounded-lg shadow-sm text-sm font-medium text-gray-700 bg-white hover:bg-gray-50 transition-colors duration-200"
                    >
                      <X className="w-4 h-4 mr-2" />
                      Cancelar
                    </button>
                  </>
                ) : (
                  <button
                    onClick={() => setIsEditing(true)}
                    className="inline-flex items-center px-4 py-2 border border-transparent rounded-lg shadow-sm text-sm font-medium text-white bg-amber-600 hover:bg-amber-700 transition-colors duration-200"
                  >
                    <Edit className="w-4 h-4 mr-2" />
                    Editar
                  </button>
                )}
                <button
                  onClick={onNewInteraction}
                  className="inline-flex items-center px-4 py-2 border border-transparent rounded-lg shadow-sm text-sm font-medium text-white bg-blue-600 hover:bg-blue-700 transition-colors duration-200"
                >
                  <MessageCircle className="w-4 h-4 mr-2" />
                  Nueva Interacción
                </button>
                <button
                  onClick={() => setShowQuoteModal(true)}
                  className="inline-flex items-center px-4 py-2 border border-transparent rounded-lg shadow-sm text-sm font-medium text-white bg-indigo-600 hover:bg-indigo-700 transition-colors duration-200"
                >
                  <FileText className="w-4 h-4 mr-2" />
                  Nueva Cotización
                </button>
              </div>
            </div>
            
            {/* Tags del cliente */}
            {client.tags && client.tags.length > 0 && (
              <div className="mt-4 flex flex-wrap gap-2">
                {client.tags.map((tag, index) => (
                  <span 
                    key={index} 
                    className="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-blue-50 text-blue-700 border border-blue-100"
                  >
                    {tag}
                  </span>
                ))}
              </div>
            )}
          </div>
        </div>

        {/* Tabs Mejorados */}
        <div className="bg-white rounded-xl shadow-sm border border-gray-100 mb-6">
          <nav className="flex overflow-x-auto" aria-label="Tabs">
            {tabs.map((tab) => (
              <button
                key={tab.id}
                onClick={() => setActiveTab(tab.id)}
                className={`
                  flex items-center py-4 px-6 font-medium text-sm whitespace-nowrap transition-colors duration-200
                  ${activeTab === tab.id
                    ? 'text-blue-600 border-b-2 border-blue-500 bg-blue-50/50'
                    : 'text-gray-600 hover:text-gray-900 hover:bg-gray-50'}
                `}
                aria-current={activeTab === tab.id ? 'page' : undefined}
              >
                <tab.icon className={`w-5 h-5 mr-2 ${activeTab === tab.id ? 'text-blue-500' : 'text-gray-400'}`} />
                {tab.label}
              </button>
            ))}
          </nav>
        </div>

        {/* Tab Content */}
        <div className="bg-white rounded-xl shadow-sm border border-gray-100 p-6">
          {renderActiveTab()}
        </div>

        {/* Quote Modal */}
        <QuoteModal
          clientId={client.id}
          isOpen={showQuoteModal}
          onClose={() => setShowQuoteModal(false)}
          onSubmit={handleCreateQuote}
          isSubmitting={isCreatingQuote}
        />
      </div>
    </div>
  );
}
