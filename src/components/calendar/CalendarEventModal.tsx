import React, { useState } from 'react';
import { X, Package, FileText, User2, Clock, AlertTriangle } from 'lucide-react';
import DatePicker from 'react-datepicker';
import "react-datepicker/dist/react-datepicker.css";
import { es } from 'date-fns/locale';
import type { EventType } from './CalendarView';

interface CalendarEventModalProps {
  isOpen: boolean;
  onClose: () => void;
  onSubmit: (data: any) => void;
  event?: any;
  isSubmitting?: boolean;
}

export function CalendarEventModal({ isOpen, onClose, onSubmit, event, isSubmitting }: CalendarEventModalProps) {
  const [formData, setFormData] = useState({
    title: event?.title || '',
    type: event?.type || 'product_development',
    date: event?.date || new Date(),
    status: event?.status || 'pending',
    priority: event?.priority || 'medium',
    phase: event?.phase || 'communication',
    packagingType: event?.packagingType || '',
    references: event?.references || [],
    internalResponsible: event?.internalResponsible || '',
    clientContact: event?.clientContact || '',
    notes: event?.notes || '',
    requiredDocuments: event?.requiredDocuments || [],
    followUpActions: event?.followUpActions || [],
    attachments: event?.attachments || []
  });

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    onSubmit(formData);
  };

  if (!isOpen) return null;

  return (
    <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 overflow-y-auto">
      <div className="bg-white rounded-lg w-full max-w-3xl p-6 m-4">
        <div className="flex justify-between items-center mb-4">
          <h2 className="text-xl font-semibold text-gray-900">
            {event ? 'Editar Evento' : 'Nuevo Evento'}
          </h2>
          <button
            onClick={onClose}
            className="text-gray-400 hover:text-gray-500"
          >
            <X className="w-6 h-6" />
          </button>
        </div>

        <form onSubmit={handleSubmit} className="space-y-6">
          {/* Basic Information */}
          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="block text-sm font-medium text-gray-700">
                Título
              </label>
              <input
                type="text"
                value={formData.title}
                onChange={(e) => setFormData({ ...formData, title: e.target.value })}
                className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
                required
              />
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700">
                Tipo de Evento
              </label>
              <select
                value={formData.type}
                onChange={(e) => setFormData({ ...formData, type: e.target.value as EventType })}
                className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
              >
                <option value="product_development">Desarrollo de Producto</option>
                <option value="technical_test">Prueba Técnica</option>
                <option value="delivery">Entrega</option>
                <option value="commercial_visit">Visita Comercial</option>
                <option value="post_sale">Seguimiento Post-venta</option>
              </select>
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700">
                Fecha y Hora
              </label>
              <DatePicker
                selected={formData.date}
                onChange={(date: Date) => setFormData({ ...formData, date })}
                showTimeSelect
                timeFormat="HH:mm"
                timeIntervals={15}
                dateFormat="dd/MM/yyyy HH:mm"
                locale={es}
                className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
              />
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700">
                Fase del Proceso
              </label>
              <select
                value={formData.phase}
                onChange={(e) => setFormData({ ...formData, phase: e.target.value })}
                className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
              >
                <option value="communication">Comunicación</option>
                <option value="quotation">Presupuesto</option>
                <option value="development">Desarrollo</option>
                <option value="testing">Pruebas</option>
                <option value="approval">Aprobación</option>
                <option value="production">Producción</option>
              </select>
            </div>
          </div>

          {/* Packaging Information */}
          <div>
            <h3 className="text-sm font-medium text-gray-700 mb-2 flex items-center">
              <Package className="w-4 h-4 mr-1" />
              Información de Empaque
            </h3>
            <div className="grid grid-cols-2 gap-4">
              <div>
                <label className="block text-sm font-medium text-gray-700">
                  Tipo de Empaque
                </label>
                <select
                  value={formData.packagingType}
                  onChange={(e) => setFormData({ ...formData, packagingType: e.target.value })}
                  className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
                >
                  <option value="">Seleccionar tipo...</option>
                  <option value="bags">Bolsas</option>
                  <option value="pouches">Pouches</option>
                  <option value="films">Películas</option>
                  <option value="labels">Etiquetas</option>
                </select>
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700">
                  Referencias
                </label>
                <div className="mt-1 flex gap-2">
                  <input
                    type="text"
                    placeholder="Agregar referencia"
                    className="flex-1 rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
                    onKeyPress={(e) => {
                      if (e.key === 'Enter') {
                        e.preventDefault();
                        const input = e.target as HTMLInputElement;
                        if (input.value.trim()) {
                          setFormData({
                            ...formData,
                            references: [...formData.references, input.value.trim()]
                          });
                          input.value = '';
                        }
                      }
                    }}
                  />
                </div>
                <div className="mt-2 flex flex-wrap gap-2">
                  {formData.references.map((ref, index) => (
                    <span
                      key={index}
                      className="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-blue-100 text-blue-800"
                    >
                      {ref}
                      <button
                        type="button"
                        onClick={() => {
                          const newRefs = formData.references.filter((_, i) => i !== index);
                          setFormData({ ...formData, references: newRefs });
                        }}
                        className="ml-1 text-blue-600 hover:text-blue-800"
                      >
                        <X className="w-3 h-3" />
                      </button>
                    </span>
                  ))}
                </div>
              </div>
            </div>
          </div>

          {/* Responsible Parties */}
          <div>
            <h3 className="text-sm font-medium text-gray-700 mb-2 flex items-center">
              <User2 className="w-4 h-4 mr-1" />
              Responsables
            </h3>
            <div className="grid grid-cols-2 gap-4">
              <div>
                <label className="block text-sm font-medium text-gray-700">
                  Responsable Interno
                </label>
                <input
                  type="text"
                  value={formData.internalResponsible}
                  onChange={(e) => setFormData({ ...formData, internalResponsible: e.target.value })}
                  className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
                />
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700">
                  Contacto del Cliente
                </label>
                <input
                  type="text"
                  value={formData.clientContact}
                  onChange={(e) => setFormData({ ...formData, clientContact: e.target.value })}
                  className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
                />
              </div>
            </div>
          </div>

          {/* Required Documents */}
          <div>
            <h3 className="text-sm font-medium text-gray-700 mb-2 flex items-center">
              <FileText className="w-4 h-4 mr-1" />
              Documentos Requeridos
            </h3>
            <div className="space-y-2">
              {formData.requiredDocuments.map((doc, index) => (
                <div key={index} className="flex items-center gap-2">
                  <input
                    type="text"
                    value={doc}
                    onChange={(e) => {
                      const newDocs = [...formData.requiredDocuments];
                      newDocs[index] = e.target.value;
                      setFormData({ ...formData, requiredDocuments: newDocs });
                    }}
                    className="flex-1 rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
                    placeholder="Nombre del documento"
                  />
                  <button
                    type="button"
                    onClick={() => {
                      const newDocs = formData.requiredDocuments.filter((_, i) => i !== index);
                      setFormData({ ...formData, requiredDocuments: newDocs });
                    }}
                    className="text-red-600 hover:text-red-800"
                  >
                    <X className="w-5 h-5" />
                  </button>
                </div>
              ))}
              <button
                type="button"
                onClick={() => {
                  setFormData({
                    ...formData,
                    requiredDocuments: [...formData.requiredDocuments, '']
                  });
                }}
                className="inline-flex items-center px-3 py-1.5 border border-gray-300 shadow-sm text-sm font-medium rounded text-gray-700 bg-white hover:bg-gray-50"
              >
                + Agregar Documento
              </button>
            </div>
          </div>

          {/* Follow-up Actions */}
          <div>
            <h3 className="text-sm font-medium text-gray-700 mb-2 flex items-center">
              <Clock className="w-4 h-4 mr-1" />
              Acciones de Seguimiento
            </h3>
            <div className="space-y-2">
              {formData.followUpActions.map((action, index) => (
                <div key={index} className="flex items-center gap-2">
                  <input
                    type="text"
                    value={action}
                    onChange={(e) => {
                      const newActions = [...formData.followUpActions];
                      newActions[index] = e.target.value;
                      setFormData({ ...formData, followUpActions: newActions });
                    }}
                    className="flex-1 rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
                    placeholder="Acción de seguimiento"
                  />
                  <button
                    type="button"
                    onClick={() => {
                      const newActions = formData.followUpActions.filter((_, i) => i !== index);
                      setFormData({ ...formData, followUpActions: newActions });
                    }}
                    className="text-red-600 hover:text-red-800"
                  >
                    <X className="w-5 h-5" />
                  </button>
                </div>
              ))}
              <button
                type="button"
                onClick={() => {
                  setFormData({
                    ...formData,
                    followUpActions: [...formData.followUpActions, '']
                  });
                }}
                className="inline-flex items-center px-3 py-1.5 border border-gray-300 shadow-sm text-sm font-medium rounded text-gray-700 bg-white hover:bg-gray-50"
              >
                + Agregar Acción
              </button>
            </div>
          </div>

          {/* Notes */}
          <div>
            <label className="block text-sm font-medium text-gray-700">
              Notas y Observaciones
            </label>
            <textarea
              value={formData.notes}
              onChange={(e) => setFormData({ ...formData, notes: e.target.value })}
              rows={3}
              className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
            />
          </div>

          {/* Priority and Status */}
          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="block text-sm font-medium text-gray-700">
                Prioridad
              </label>
              <select
                value={formData.priority}
                onChange={(e) => setFormData({ ...formData, priority: e.target.value })}
                className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
              >
                <option value="low">Baja</option>
                <option value="medium">Media</option>
                <option value="high">Alta</option>
              </select>
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700">
                Estado
              </label>
              <select
                value={formData.status}
                onChange={(e) => setFormData({ ...formData, status: e.target.value })}
                className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
              >
                <option value="pending">Pendiente</option>
                <option value="in_progress">En Proceso</option>
                <option value="completed">Completado</option>
                <option value="cancelled">Cancelado</option>
              </select>
            </div>
          </div>

          {/* Submit Buttons */}
          <div className="flex justify-end space-x-3 pt-4 border-t">
            <button
              type="button"
              onClick={onClose}
              className="px-4 py-2 border border-gray-300 rounded-md text-sm font-medium text-gray-700 hover:bg-gray-50"
            >
              Cancelar
            </button>
            <button
              type="submit"
              disabled={isSubmitting}
              className="px-4 py-2 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-blue-600 hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 disabled:opacity-50"
            >
              {isSubmitting ? 'Guardando...' : event ? 'Actualizar' : 'Crear'}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
}