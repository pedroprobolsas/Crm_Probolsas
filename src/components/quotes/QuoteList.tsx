import React, { useState } from 'react';
import { format } from 'date-fns';
import { es } from 'date-fns/locale';
import { FileText, Download, Eye, Clock, AlertCircle, CheckCircle, XCircle, Filter, ThumbsUp, ThumbsDown } from 'lucide-react';
import { useQuotes } from '../../lib/hooks/useQuotes';
import { useAuthStore } from '../../lib/store/authStore';
import { QuoteViewer } from './QuoteViewer';
import { generateQuotePDF } from '../../lib/utils/pdfGenerator';
import { toast } from 'sonner';
import type { Quote } from '../../lib/types';

interface QuoteListProps {
  clientId: string;
}

export function QuoteList({ clientId }: QuoteListProps) {
  const [selectedQuote, setSelectedQuote] = useState<Quote | null>(null);
  const [showViewer, setShowViewer] = useState(false);
  const [statusFilter, setStatusFilter] = useState<Quote['status'] | 'all'>('all');
  const { quotes, isLoading, updateQuoteStatus, isUpdating } = useQuotes(clientId);
  const { isAdmin } = useAuthStore();

  const filteredQuotes = quotes.filter(quote => 
    statusFilter === 'all' || quote.status === statusFilter
  );

  const handleDownloadPDF = async (quote: Quote) => {
    try {
      await generateQuotePDF(quote);
      toast.success('PDF generado exitosamente');
    } catch (error) {
      console.error('Error generating PDF:', error);
      toast.error('Error al generar el PDF');
    }
  };

  const handleApproveQuote = async (quoteId: string) => {
    try {
      await updateQuoteStatus({ quoteId, status: 'approved' });
      toast.success('Cotización aprobada exitosamente');
    } catch (error) {
      console.error('Error approving quote:', error);
      toast.error('Error al aprobar la cotización');
    }
  };

  const handleRejectQuote = async (quoteId: string) => {
    try {
      await updateQuoteStatus({ quoteId, status: 'rejected' });
      toast.success('Cotización rechazada');
    } catch (error) {
      console.error('Error rejecting quote:', error);
      toast.error('Error al rechazar la cotización');
    }
  };

  const handleSendQuote = async (quoteId: string) => {
    try {
      await updateQuoteStatus({ quoteId, status: 'sent' });
      toast.success('Cotización enviada al cliente');
    } catch (error) {
      console.error('Error sending quote:', error);
      toast.error('Error al enviar la cotización');
    }
  };

  const getStatusIcon = (status: Quote['status']) => {
    switch (status) {
      case 'draft':
        return <Clock className="w-5 h-5 text-gray-500" />;
      case 'sent':
        return <AlertCircle className="w-5 h-5 text-blue-500" />;
      case 'approved':
        return <CheckCircle className="w-5 h-5 text-green-500" />;
      case 'rejected':
        return <XCircle className="w-5 h-5 text-red-500" />;
      default:
        return null;
    }
  };

  const getStatusColor = (status: Quote['status']) => {
    switch (status) {
      case 'draft':
        return 'bg-gray-100 text-gray-800';
      case 'sent':
        return 'bg-blue-100 text-blue-800';
      case 'approved':
        return 'bg-green-100 text-green-800';
      case 'rejected':
        return 'bg-red-100 text-red-800';
      default:
        return 'bg-gray-100 text-gray-800';
    }
  };

  const getStatusText = (status: Quote['status']) => {
    switch (status) {
      case 'draft':
        return 'Borrador';
      case 'sent':
        return 'Enviada';
      case 'approved':
        return 'Aprobada';
      case 'rejected':
        return 'Rechazada';
      default:
        return status;
    }
  };

  if (isLoading) {
    return (
      <div className="flex justify-center py-8">
        <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600"></div>
      </div>
    );
  }

  return (
    <>
      <div className="bg-white rounded-lg shadow">
        <div className="p-4 border-b border-gray-200">
          <div className="flex justify-between items-center">
            <h3 className="text-lg font-medium text-gray-900">Cotizaciones</h3>
            <div className="flex items-center space-x-2">
              <div className="relative">
                <select
                  value={statusFilter}
                  onChange={(e) => setStatusFilter(e.target.value as Quote['status'] | 'all')}
                  className="appearance-none bg-white border border-gray-300 rounded-lg py-2 pl-3 pr-10 text-sm leading-5 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
                >
                  <option value="all">Todos los estados</option>
                  <option value="draft">Borradores</option>
                  <option value="sent">Enviadas</option>
                  <option value="approved">Aprobadas</option>
                  <option value="rejected">Rechazadas</option>
                </select>
                <Filter className="absolute right-3 top-2.5 h-5 w-5 text-gray-400 pointer-events-none" />
              </div>
            </div>
          </div>
        </div>

        {filteredQuotes.length === 0 ? (
          <div className="text-center py-8">
            <FileText className="mx-auto h-12 w-12 text-gray-400" />
            <h3 className="mt-2 text-sm font-medium text-gray-900">No hay cotizaciones</h3>
            <p className="mt-1 text-sm text-gray-500">
              Aún no se han generado cotizaciones para este cliente.
            </p>
          </div>
        ) : (
          <div className="overflow-x-auto">
            <table className="min-w-full divide-y divide-gray-200">
              <thead className="bg-gray-50">
                <tr>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Número
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Fecha
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Total
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Estado
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Validez
                  </th>
                  <th className="px-6 py-3 text-right text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Acciones
                  </th>
                </tr>
              </thead>
              <tbody className="bg-white divide-y divide-gray-200">
                {filteredQuotes.map((quote) => (
                  <tr key={quote.id} className="hover:bg-gray-50">
                    <td className="px-6 py-4 whitespace-nowrap text-sm font-medium text-gray-900">
                      {quote.quote_number}
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                      {format(new Date(quote.created_at), 'PPP', { locale: es })}
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                      ${quote.total_amount.toLocaleString('es-CO')}
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap">
                      <span className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${getStatusColor(quote.status)}`}>
                        {getStatusIcon(quote.status)}
                        <span className="ml-1">{getStatusText(quote.status)}</span>
                      </span>
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                      {format(new Date(quote.valid_until), 'PPP', { locale: es })}
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-right text-sm font-medium">
                      <div className="flex justify-end space-x-2">
                        {/* Acciones básicas */}
                        <button
                          onClick={() => {
                            setSelectedQuote(quote);
                            setShowViewer(true);
                          }}
                          className="text-blue-600 hover:text-blue-900"
                          title="Ver cotización"
                        >
                          <Eye className="w-5 h-5" />
                        </button>
                        <button
                          onClick={() => handleDownloadPDF(quote)}
                          className="text-blue-600 hover:text-blue-900"
                          title="Descargar PDF"
                        >
                          <Download className="w-5 h-5" />
                        </button>

                        {/* Acciones de estado */}
                        {quote.status === 'draft' && (
                          <button
                            onClick={() => handleSendQuote(quote.id)}
                            disabled={isUpdating}
                            className="text-blue-600 hover:text-blue-900 disabled:opacity-50"
                            title="Enviar al cliente"
                          >
                            <AlertCircle className="w-5 h-5" />
                          </button>
                        )}

                        {quote.status === 'sent' && isAdmin() && (
                          <>
                            <button
                              onClick={() => handleApproveQuote(quote.id)}
                              disabled={isUpdating}
                              className="text-green-600 hover:text-green-900 disabled:opacity-50"
                              title="Aprobar cotización"
                            >
                              <ThumbsUp className="w-5 h-5" />
                            </button>
                            <button
                              onClick={() => handleRejectQuote(quote.id)}
                              disabled={isUpdating}
                              className="text-red-600 hover:text-red-900 disabled:opacity-50"
                              title="Rechazar cotización"
                            >
                              <ThumbsDown className="w-5 h-5" />
                            </button>
                          </>
                        )}
                      </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </div>

      {selectedQuote && (
        <QuoteViewer
          quote={selectedQuote}
          isOpen={showViewer}
          onClose={() => {
            setShowViewer(false);
            setSelectedQuote(null);
          }}
          onDownload={() => handleDownloadPDF(selectedQuote)}
          onApprove={isAdmin() && selectedQuote.status === 'sent' ? () => handleApproveQuote(selectedQuote.id) : undefined}
          onReject={isAdmin() && selectedQuote.status === 'sent' ? () => handleRejectQuote(selectedQuote.id) : undefined}
          onSend={selectedQuote.status === 'draft' ? () => handleSendQuote(selectedQuote.id) : undefined}
          isUpdating={isUpdating}
        />
      )}
    </>
  );
}