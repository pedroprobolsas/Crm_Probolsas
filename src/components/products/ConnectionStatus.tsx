import React, { useState } from 'react';
import { CheckCircle, XCircle, AlertTriangle, Clock, RefreshCw } from 'lucide-react';
import { ConnectionDebug } from './ConnectionDebug';
import { useWooDebug } from '../../lib/hooks/useWooDebug';
import type { ConnectionStatus as ConnectionStatusType } from '../../lib/types/product';

interface ConnectionStatusProps {
  status: ConnectionStatusType;
  onTest: () => void;
  isLoading?: boolean;
  error?: string;
}

export function ConnectionStatus({ status, onTest, isLoading, error }: ConnectionStatusProps) {
  const [showDebug, setShowDebug] = useState(false);
  const { debugSteps, isDebugging } = useWooDebug();

  const getStatusColor = () => {
    switch (status.state) {
      case 'connected':
        return 'bg-green-100 text-green-800 border-green-200';
      case 'disconnected':
        return 'bg-red-100 text-red-800 border-red-200';
      case 'error':
        return 'bg-yellow-100 text-yellow-800 border-yellow-200';
      default:
        return 'bg-gray-100 text-gray-800 border-gray-200';
    }
  };

  const getStatusIcon = () => {
    switch (status.state) {
      case 'connected':
        return <CheckCircle className="w-5 h-5 text-green-600" />;
      case 'disconnected':
        return <XCircle className="w-5 h-5 text-red-600" />;
      case 'error':
        return <AlertTriangle className="w-5 h-5 text-yellow-600" />;
      default:
        return <Clock className="w-5 h-5 text-gray-600" />;
    }
  };

  const handleTest = () => {
    setShowDebug(true);
    onTest();
  };

  return (
    <div className="space-y-6 mb-6">
      <div className="bg-white rounded-lg shadow p-6">
        <div className="flex items-center justify-between mb-4">
          <div className="flex items-center">
            {getStatusIcon()}
            <h3 className="text-lg font-medium ml-2">Estado de WooCommerce</h3>
          </div>
          <div className="flex items-center space-x-4">
            <button
              onClick={() => setShowDebug(!showDebug)}
              className="text-sm text-gray-600 hover:text-gray-900"
            >
              {showDebug ? 'Ocultar Diagnóstico' : 'Mostrar Diagnóstico'}
            </button>
            <button
              onClick={handleTest}
              disabled={isLoading}
              className="flex items-center px-4 py-2 text-sm font-medium text-gray-700 bg-white border border-gray-300 rounded-md hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500"
            >
              {isLoading ? (
                <RefreshCw className="w-4 h-4 mr-2 animate-spin" />
              ) : (
                <RefreshCw className="w-4 h-4 mr-2" />
              )}
              Probar Conexión
            </button>
          </div>
        </div>

        <div className="grid grid-cols-2 gap-4">
          <div>
            <p className="text-sm text-gray-500">Estado</p>
            <div className={`mt-1 inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${getStatusColor()}`}>
              {status.state === 'connected' ? 'Conectado' :
               status.state === 'disconnected' ? 'Desconectado' :
               status.state === 'error' ? 'Error' : 'Desconocido'}
            </div>
          </div>

          <div>
            <p className="text-sm text-gray-500">Última Verificación</p>
            <p className="mt-1 text-sm font-medium text-gray-900">
              {status.lastCheck ? new Date(status.lastCheck).toLocaleString() : 'Nunca'}
            </p>
          </div>

          {status.productCount !== undefined && (
            <div>
              <p className="text-sm text-gray-500">Productos Sincronizados</p>
              <p className="mt-1 text-sm font-medium text-gray-900">{status.productCount}</p>
            </div>
          )}

          {(status.error || error) && (
            <div className="col-span-2">
              <p className="text-sm text-gray-500">Error</p>
              <p className="mt-1 text-sm font-medium text-red-600">{status.error || error}</p>
            </div>
          )}
        </div>
      </div>

      {showDebug && (
        <ConnectionDebug
          steps={debugSteps}
          isDebugging={isDebugging}
        />
      )}
    </div>
  );
}