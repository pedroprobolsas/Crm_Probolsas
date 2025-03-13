import React from 'react';
import { format } from 'date-fns';
import { es } from 'date-fns/locale';
import { X, Download, FileText, Package, DollarSign, Calendar, CheckCircle, XCircle, Clock, ThumbsUp, ThumbsDown, AlertCircle } from 'lucide-react';
import type { Quote } from '../../lib/types';

interface QuoteViewerProps {
  quote: Quote;
  isOpen: boolean;
  onClose: () => void;
  onDownload: () => void;
  onApprove?: () => void;
  onReject?: () => void;
  onSend?: () => void;
  isUpdating?: boolean;
}

export function QuoteViewer({ 
  quote, 
  isOpen, 
  onClose, 
  onDownload,
  onApprove,
  onReject,
  onSend,
  isUpdating 
}: QuoteViewerProps) {
  if (!isOpen) return null;

  const getStatusIcon = () => {
    switch (quote.status) {
      case 'approved':
        return <CheckCircle className="w-5 h-5 text-green-500" />;
      case 'rejected':
        return <XCircle className="w-5 h-5 text-red-500" />;
      case 'sent':
        return <FileText className="w-5 h-5 text-blue-500" />;
      default:
        return <Clock className="w-5 h-5 text-gray-500" />;
    }
  };

  const getStatusColor = () => {
    switch (quote.status) {
      case 'approved':
        return 'bg-green-100 text-green-800';
      case 'rejected':
        return 'bg-red-100 text-red-800';
      case 'sent':
        return 'bg-blue-100 text-blue-800';
      default:
        return 'bg-gray-100 text-gray-800';
    }
  };

  const getStatusText = () => {
    switch (quote.status) {
      case 'approved':
        return 'Aprobada';
      case 'rejected':
        return 'Rechazada';
      case 'sent':
        return 'Enviada';
      default:
        return 'Borrador';
    }
  };

  return (
    <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
      <div className="bg-white rounded-lg w-full max-w-4xl p-6 max-h-[90vh] overflow-y-auto">
        <div className="flex justify-between items-start mb-6">
          <div>
            <div className="flex items-center space-x-3">
              <h2 className="text-2xl font-bold text-gray-900">
                Cotización #{quote.quote_number}
              </h2>
              <span className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${getStatusColor()}`}>
                {getStatusIcon()}
                <span className="ml-1">{getStatusText()}</span>
              </span>
            </div>
            <p className="mt-1 text-sm text-gray-500">
              Creada el {format(new Date(quote.created_at), 'PPP', { locale: es })}
            </p>
          </div>
          <div className="flex items-center space-x-2">
            {/* Acciones de estado */}
            {quote.status === 'draft' && onSend && (
              <button
                onClick={onSend}
                disabled={isUpdating}
                className="inline-flex items-center px-4 py-2 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-blue-600 hover:bg-blue-700 disabled:opacity-50"
              >
                <AlertCircle className="w-4 h-4 mr-2" />
                Enviar al Cliente
              </button>
            )}
            
            {quote.status === 'sent' && (
              <>
                {onApprove && (
                  <button
                    onClick={onApprove}
                    disabled={isUpdating}
                    className="inline-flex items-center px-4 py-2 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-green-600 hover:bg-green-700 disabled:opacity-50"
                  >
                    <ThumbsUp className="w-4 h-4 mr-2" />
                    Aprobar
                  </button>
                )}
                {onReject && (
                  <button
                    onClick={onReject}
                    disabled={isUpdating}
                    className="inline-flex items-center px-4 py-2 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-red-600 hover:bg-red-700 disabled:opacity-50"
                  >
                    <ThumbsDown className="w-4 h-4 mr-2" />
                    Rechazar
                  </button>
                )}
              </>
            )}

            {/* Acciones básicas */}
            <button
              onClick={onDownload}
              className="inline-flex items-center px-4 py-2 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-blue-600 hover:bg-blue-700"
            >
              <Download className="w-4 h-4 mr-2" />
              Descargar PDF
            </button>
            <button
              onClick={onClose}
              className="p-2 text-gray-400 hover:text-gray-500"
            >
              <X className="w-6 h-6" />
            </button>
          </div>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-2 gap-6 mb-8">
          <div className="bg-gray-50 p-4 rounded-lg">
            <div className="flex items-center text-sm font-medium text-gray-500 mb-4">
              <Calendar className="w-4 h-4 mr-2" />
              Información General
            </div>
            <dl className="space-y-2">
              <div>
                <dt className="text-sm font-medium text-gray-500">Válida hasta</dt>
                <dd className="mt-1 text-sm text-gray-900">
                  {format(new Date(quote.valid_until), 'PPP', { locale: es })}
                </dd>
              </div>
              <div>
                <dt className="text-sm font-medium text-gray-500">Asesor</dt>
                <dd className="mt-1 text-sm text-gray-900">
                  {quote.agent_name}
                </dd>
              </div>
            </dl>
          </div>

          <div className="bg-gray-50 p-4 rounded-lg">
            <div className="flex items-center text-sm font-medium text-gray-500 mb-4">
              <DollarSign className="w-4 h-4 mr-2" />
              Resumen
            </div>
            <dl className="space-y-2">
              <div>
                <dt className="text-sm font-medium text-gray-500">Total</dt>
                <dd className="mt-1 text-lg font-semibold text-gray-900">
                  ${quote.total_amount.toLocaleString('es-CO')}
                </dd>
              </div>
              <div>
                <dt className="text-sm font-medium text-gray-500">Items</dt>
                <dd className="mt-1 text-sm text-gray-900">
                  {quote.items.length} productos
                </dd>
              </div>
            </dl>
          </div>
        </div>

        <div className="mb-8">
          <h3 className="text-lg font-medium text-gray-900 mb-4">Productos</h3>
          <div className="bg-white shadow overflow-hidden rounded-lg">
            <table className="min-w-full divide-y divide-gray-200">
              <thead className="bg-gray-50">
                <tr>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Producto
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Cantidad
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Precio Unitario
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Total
                  </th>
                </tr>
              </thead>
              <tbody className="bg-white divide-y divide-gray-200">
                {quote.items.map((item, index) => (
                  <tr key={index}>
                    <td className="px-6 py-4 whitespace-nowrap">
                      <div className="flex items-center">
                        <Package className="flex-shrink-0 h-5 w-5 text-gray-400" />
                        <div className="ml-4">
                          <div className="text-sm font-medium text-gray-900">
                            {item.product_name}
                          </div>
                          {item.notes && (
                            <div className="text-sm text-gray-500">
                              {item.notes}
                            </div>
                          )}
                        </div>
                      </div>
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                      {item.quantity.toLocaleString()}
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                      ${item.unit_price.toLocaleString('es-CO')}
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                      ${item.total_price.toLocaleString('es-CO')}
                    </td>
                  </tr>
                ))}
                <tr className="bg-gray-50">
                  <td colSpan={3} className="px-6 py-4 text-right font-medium text-gray-500">
                    Total
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap text-lg font-bold text-gray-900">
                    ${quote.total_amount.toLocaleString('es-CO')}
                  </td>
                </tr>
              </tbody>
            </table>
          </div>
        </div>

        {(quote.terms || quote.notes) && (
          <div className="space-y-6">
            {quote.terms && (
              <div>
                <h3 className="text-lg font-medium text-gray-900 mb-2">
                  Términos y Condiciones
                </h3>
                <div className="bg-gray-50 p-4 rounded-lg text-sm text-gray-700">
                  {quote.terms}
                </div>
              </div>
            )}
            {quote.notes && (
              <div>
                <h3 className="text-lg font-medium text-gray-900 mb-2">
                  Notas Adicionales
                </h3>
                <div className="bg-gray-50 p-4 rounded-lg text-sm text-gray-700">
                  {quote.notes}
                </div>
              </div>
            )}
          </div>
        )}
      </div>
    </div>
  );
}