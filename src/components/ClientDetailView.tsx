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
  BarChart
} from 'lucide-react';
import "react-datepicker/dist/react-datepicker.css";
import { ClientTimeline } from './ClientTimeline';
import { useClientDetail } from '../lib/hooks/useClientDetail';
import { useQuotes } from '../lib/hooks/useQuotes';
import { QuoteModal } from './quotes/QuoteModal';
import { QuoteList } from './quotes/QuoteList';
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
      {/* General tab content */}
      <div className="grid grid-cols-2 gap-6">
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
        {/* Other general tab fields */}
      </div>
    </div>
  );

  const renderContactsTab = () => (
    <div className="space-y-8">
      {/* Contacts tab content */}
    </div>
  );

  const renderFiscalTab = () => (
    <div className="space-y-6">
      {/* Fiscal tab content */}
    </div>
  );

  const renderCommercialTab = () => (
    <div className="space-y-8">
      {/* Commercial tab content */}
    </div>
  );

  const renderQuotesTab = () => (
    <div className="space-y-6">
      <QuoteList clientId={client.id} />
    </div>
  );

  const renderTransactionsTab = () => (
    <div className="space-y-6">
      <h3 className="text-lg font-medium text-gray-900 mb-4">Historial de Interacciones</h3>
      <ClientTimeline interactions={interactions} />
    </div>
  );

  const renderOrganizationalTab = () => (
    <div className="space-y-6">
      {/* Organizational tab content */}
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
    <div className="min-h-screen bg-gray-100">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        {/* Header */}
        <div className="mb-8">
          <div className="flex justify-between items-center">
            <div>
              <button
                onClick={onClose}
                className="flex items-center text-gray-600 hover:text-gray-900"
              >
                <ArrowLeft className="w-5 h-5 mr-2" />
                Volver
              </button>
              <h1 className="text-2xl font-bold text-gray-900 mt-2">{client.company}</h1>
            </div>
            <div className="flex items-center space-x-4">
              <button
                onClick={() => setShowQuoteModal(true)}
                className="inline-flex items-center px-4 py-2 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-green-600 hover:bg-green-700"
              >
                <FileText className="w-5 h-5 mr-2" />
                Nueva Cotización
              </button>
              <button
                onClick={onNewInteraction}
                className="inline-flex items-center px-4 py-2 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-blue-600 hover:bg-blue-700"
              >
                <MessageCircle className="w-5 h-5 mr-2" />
                Nueva Interacción
              </button>
              {isEditing ? (
                <>
                  <button
                    onClick={handleSave}
                    disabled={isUpdating}
                    className="inline-flex items-center px-4 py-2 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-green-600 hover:bg-green-700"
                  >
                    <Save className="w-5 h-5 mr-2" />
                    Guardar
                  </button>
                  <button
                    onClick={() => {
                      setIsEditing(false);
                      setFormData(client);
                    }}
                    className="inline-flex items-center px-4 py-2 border border-gray-300 shadow-sm text-sm font-medium text-gray-700 bg-white hover:bg-gray-50"
                  >
                    <X className="w-5 h-5 mr-2" />
                    Cancelar
                  </button>
                </>
              ) : (
                <button
                  onClick={() => setIsEditing(true)}
                  className="inline-flex items-center px-4 py-2 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-yellow-600 hover:bg-yellow-700"
                >
                  <Edit className="w-5 h-5 mr-2" />
                  Editar
                </button>
              )}
            </div>
          </div>
        </div>

        {/* Tabs */}
        <div className="border-b border-gray-200">
          <nav className="-mb-px flex space-x-8" aria-label="Tabs">
            {tabs.map((tab) => (
              <button
                key={tab.id}
                onClick={() => setActiveTab(tab.id)}
                className={`${
                  activeTab === tab.id
                    ? 'border-blue-500 text-blue-600'
                    : 'border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300'
                } group inline-flex items-center py-4 px-1 border-b-2 font-medium text-sm`}
                aria-current={activeTab === tab.id ? 'page' : undefined}
              >
                <tab.icon className="w-5 h-5 mr-2" />
                {tab.label}
              </button>
            ))}
          </nav>
        </div>

        {/* Tab Content */}
        <div className="py-6">
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
