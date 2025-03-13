import React, { useState } from 'react';
import { AlertTriangle, Users, X, Loader2, Calendar, ArrowRight } from 'lucide-react';
import type { Agent } from '../lib/types';

type DeactivationReason = 'renuncia' | 'terminacion' | 'licencia' | 'otro';

interface AssignedClient {
  id: string;
  name: string;
  company: string;
  status: 'active' | 'inactive';
  stage: string;
  lastInteraction: string;
}

interface DeactivateAgentModalProps {
  isOpen: boolean;
  onClose: () => void;
  onConfirm: (data: {
    reason: DeactivationReason;
    details: string;
    effectiveDate: string;
    reassignments: Record<string, string>;
  }) => Promise<void>;
  agent: Agent;
  assignedClients: AssignedClient[];
  availableAgents: Agent[];
  isSubmitting?: boolean;
}

export function DeactivateAgentModal({ 
  isOpen, 
  onClose, 
  onConfirm, 
  agent, 
  assignedClients,
  availableAgents,
  isSubmitting 
}: DeactivateAgentModalProps) {
  const [reason, setReason] = useState<DeactivationReason>('renuncia');
  const [details, setDetails] = useState('');
  const [effectiveDate, setEffectiveDate] = useState(new Date().toISOString().split('T')[0]);
  const [reassignments, setReassignments] = useState<Record<string, string>>({});
  const [confirmed, setConfirmed] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const activeClients = assignedClients.filter(c => c.status === 'active');
  const inactiveClients = assignedClients.filter(c => c.status === 'inactive');

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError(null);

    // Validate form
    if (!reason) {
      setError('El motivo de desactivación es requerido');
      return;
    }

    if (!details.trim()) {
      setError('Los detalles son requeridos');
      return;
    }

    if (!effectiveDate) {
      setError('La fecha efectiva es requerida');
      return;
    }

    // Ensure all active clients are reassigned
    const unassignedClients = activeClients.filter(client => !reassignments[client.id]);
    if (unassignedClients.length > 0) {
      setError(`Hay ${unassignedClients.length} clientes activos sin reasignar`);
      return;
    }

    if (!confirmed) {
      setError('Debe confirmar que entiende las consecuencias');
      return;
    }

    try {
      await onConfirm({
        reason,
        details,
        effectiveDate,
        reassignments
      });
    } catch (error) {
      setError('Error al desactivar el asesor');
    }
  };

  const handleReassignmentChange = (clientId: string, newAgentId: string) => {
    setReassignments(prev => ({
      ...prev,
      [clientId]: newAgentId
    }));
  };

  if (!isOpen) return null;

  return (
    <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
      <div className="bg-white rounded-lg w-full max-w-lg p-6 max-h-[90vh] overflow-y-auto">
        <div className="flex justify-between items-center mb-4">
          <div className="flex items-center text-red-600">
            <AlertTriangle className="w-6 h-6 mr-2" />
            <h2 className="text-xl font-semibold">Desactivar Asesor</h2>
          </div>
          <button
            onClick={onClose}
            className="text-gray-400 hover:text-gray-500"
            disabled={isSubmitting}
          >
            <X className="w-6 h-6" />
          </button>
        </div>

        <div className="mb-6">
          <div className="bg-red-50 border border-red-200 rounded-lg p-4 mb-4">
            <p className="text-sm text-red-800">
              Está a punto de desactivar al asesor <strong>{agent.name}</strong>. Esta acción:
            </p>
            <ul className="mt-2 space-y-1 text-sm text-red-700">
              <li>• Bloqueará el acceso del asesor al sistema</li>
              <li>• Mantendrá el historial y datos para referencia</li>
              <li>• Requerirá reasignar los clientes activos</li>
              <li>• Notificará al administrador del sistema</li>
            </ul>
          </div>

          {assignedClients.length > 0 && (
            <div className="mb-4">
              <h3 className="text-sm font-medium text-gray-700 mb-2 flex items-center">
                <Users className="w-4 h-4 mr-1" />
                Clientes Asignados ({assignedClients.length})
              </h3>
              
              {/* Active Clients */}
              {activeClients.length > 0 && (
                <div className="mb-4">
                  <h4 className="text-sm font-medium text-green-700 mb-2">
                    Clientes Activos ({activeClients.length})
                  </h4>
                  <div className="space-y-3">
                    {activeClients.map((client) => (
                      <div key={client.id} className="bg-gray-50 rounded-lg p-3">
                        <div className="flex justify-between items-start mb-2">
                          <div>
                            <p className="text-sm font-medium text-gray-900">{client.name}</p>
                            <p className="text-sm text-gray-500">{client.company}</p>
                          </div>
                          <span className="px-2 py-1 text-xs font-medium rounded-full bg-green-100 text-green-800">
                            {client.stage}
                          </span>
                        </div>
                        <div className="flex items-center justify-between">
                          <select
                            value={reassignments[client.id] || ''}
                            onChange={(e) => handleReassignmentChange(client.id, e.target.value)}
                            className="mt-1 block w-full rounded-md border-gray-300 text-sm focus:border-blue-500 focus:ring-blue-500"
                            disabled={isSubmitting}
                          >
                            <option value="">Seleccionar nuevo asesor...</option>
                            {availableAgents.map((agent) => (
                              <option key={agent.id} value={agent.id}>
                                {agent.name}
                              </option>
                            ))}
                          </select>
                        </div>
                      </div>
                    ))}
                  </div>
                </div>
              )}

              {/* Inactive Clients */}
              {inactiveClients.length > 0 && (
                <div className="mb-4">
                  <h4 className="text-sm font-medium text-gray-700 mb-2">
                    Clientes Inactivos ({inactiveClients.length})
                  </h4>
                  <div className="max-h-32 overflow-y-auto bg-gray-50 rounded-lg p-3">
                    {inactiveClients.map((client) => (
                      <div key={client.id} className="text-sm text-gray-600 py-1">
                        <span className="font-medium">{client.name}</span>
                        <span className="text-gray-500"> - {client.company}</span>
                      </div>
                    ))}
                  </div>
                </div>
              )}
            </div>
          )}
        </div>

        <form onSubmit={handleSubmit} className="space-y-4">
          <div>
            <label className="block text-sm font-medium text-gray-700">
              Motivo de Desactivación
            </label>
            <select
              value={reason}
              onChange={(e) => setReason(e.target.value as DeactivationReason)}
              className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-red-500 focus:ring-red-500"
              disabled={isSubmitting}
            >
              <option value="renuncia">Renuncia Voluntaria</option>
              <option value="terminacion">Terminación de Contrato</option>
              <option value="licencia">Licencia Extendida</option>
              <option value="otro">Otro Motivo</option>
            </select>
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700">
              Detalles
            </label>
            <textarea
              value={details}
              onChange={(e) => setDetails(e.target.value)}
              className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-red-500 focus:ring-red-500"
              rows={3}
              placeholder="Proporcione detalles adicionales sobre la desactivación..."
              disabled={isSubmitting}
            />
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700">
              Fecha Efectiva
            </label>
            <div className="mt-1 relative">
              <input
                type="date"
                value={effectiveDate}
                onChange={(e) => setEffectiveDate(e.target.value)}
                className="block w-full rounded-md border-gray-300 shadow-sm focus:border-red-500 focus:ring-red-500"
                min={new Date().toISOString().split('T')[0]}
                disabled={isSubmitting}
              />
              <Calendar className="absolute right-3 top-2 h-5 w-5 text-gray-400" />
            </div>
          </div>

          <div className="flex items-start">
            <div className="flex items-center h-5">
              <input
                id="confirm"
                type="checkbox"
                checked={confirmed}
                onChange={(e) => setConfirmed(e.target.checked)}
                className="h-4 w-4 text-red-600 focus:ring-red-500 border-gray-300 rounded"
                disabled={isSubmitting}
              />
            </div>
            <label htmlFor="confirm" className="ml-2 text-sm text-gray-600">
              Confirmo que entiendo las consecuencias de desactivar este asesor y que esta acción requerirá reasignar los clientes activos.
            </label>
          </div>

          {error && (
            <div className="text-sm text-red-600 flex items-center">
              <AlertTriangle className="w-4 h-4 mr-1" />
              {error}
            </div>
          )}

          <div className="flex justify-end space-x-3 pt-4 border-t">
            <button
              type="button"
              onClick={onClose}
              className="px-4 py-2 border border-gray-300 rounded-md text-sm font-medium text-gray-700 hover:bg-gray-50"
              disabled={isSubmitting}
            >
              Cancelar
            </button>
            <button
              type="submit"
              disabled={isSubmitting || !details.trim() || !confirmed}
              className="flex items-center px-4 py-2 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-red-600 hover:bg-red-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-red-500 disabled:opacity-50"
            >
              {isSubmitting ? (
                <>
                  <Loader2 className="w-4 h-4 mr-2 animate-spin" />
                  Desactivando...
                </>
              ) : (
                'Desactivar Asesor'
              )}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
}