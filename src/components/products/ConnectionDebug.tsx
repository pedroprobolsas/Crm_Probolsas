import React from 'react';
import { 
  CheckCircle, 
  XCircle, 
  Loader2, 
  Clock, 
  AlertTriangle,
  ChevronRight
} from 'lucide-react';
import type { DebugStep } from '../../lib/hooks/useWooDebug';

interface ConnectionDebugProps {
  steps: DebugStep[];
  isDebugging: boolean;
}

export function ConnectionDebug({ steps, isDebugging }: ConnectionDebugProps) {
  const getStepIcon = (status: DebugStep['status']) => {
    switch (status) {
      case 'success':
        return <CheckCircle className="w-5 h-5 text-green-500" />;
      case 'error':
        return <XCircle className="w-5 h-5 text-red-500" />;
      case 'running':
        return <Loader2 className="w-5 h-5 text-blue-500 animate-spin" />;
      default:
        return <Clock className="w-5 h-5 text-gray-400" />;
    }
  };

  const getStepColor = (status: DebugStep['status']) => {
    switch (status) {
      case 'success':
        return 'text-green-800 bg-green-50 border-green-100';
      case 'error':
        return 'text-red-800 bg-red-50 border-red-100';
      case 'running':
        return 'text-blue-800 bg-blue-50 border-blue-100';
      default:
        return 'text-gray-800 bg-gray-50 border-gray-100';
    }
  };

  return (
    <div className="mt-6 bg-white rounded-lg shadow-sm border border-gray-200 overflow-hidden">
      <div className="p-4 border-b border-gray-200">
        <h3 className="text-lg font-medium text-gray-900">Diagnóstico de Conexión</h3>
      </div>

      <div className="divide-y divide-gray-200">
        {steps.map((step, index) => (
          <div key={step.id} className={`p-4 ${getStepColor(step.status)}`}>
            <div className="flex items-center justify-between">
              <div className="flex items-center space-x-3">
                {getStepIcon(step.status)}
                <div>
                  <p className="text-sm font-medium">{step.name}</p>
                  {step.message && (
                    <p className="mt-1 text-sm opacity-75">{step.message}</p>
                  )}
                </div>
              </div>
              {step.timestamp && (
                <div className="text-xs opacity-75">
                  {new Date(step.timestamp).toLocaleTimeString()}
                </div>
              )}
            </div>

            {step.status === 'error' && step.message && (
              <div className="mt-2 p-2 rounded bg-red-100 border border-red-200">
                <div className="flex items-start">
                  <AlertTriangle className="w-4 h-4 text-red-600 mt-0.5 mr-2" />
                  <p className="text-sm text-red-800">{step.message}</p>
                </div>
              </div>
            )}

            {index < steps.length - 1 && step.status === 'success' && (
              <div className="flex justify-center mt-2">
                <ChevronRight className="w-4 h-4 text-gray-400" />
              </div>
            )}
          </div>
        ))}
      </div>

      {isDebugging && (
        <div className="p-4 bg-blue-50 border-t border-blue-100">
          <div className="flex items-center justify-center text-sm text-blue-800">
            <Loader2 className="w-4 h-4 mr-2 animate-spin" />
            Ejecutando diagnóstico...
          </div>
        </div>
      )}
    </div>
  );
}