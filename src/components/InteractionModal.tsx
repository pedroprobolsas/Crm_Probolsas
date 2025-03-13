import React, { useState, useCallback, useEffect } from 'react';
import { X, Phone, Mail, Users, HelpCircle, Upload, AlertCircle, Flag } from 'lucide-react';
import { useDropzone } from 'react-dropzone';
import DatePicker from 'react-datepicker';
import "react-datepicker/dist/react-datepicker.css";
import type { InteractionType, ClientInteraction, ClientInteractionInsert, InteractionPriority } from '../types';
import { useAuthStore } from '../lib/store/authStore';
import { supabase } from '../lib/supabase';

interface InteractionModalProps {
  isOpen: boolean;
  onClose: () => void;
  onSubmit: (data: ClientInteractionInsert) => void;
  clientId: string;
  interaction?: ClientInteraction;
  isSubmitting?: boolean;
}

const interactionTypes: { value: InteractionType; label: string; icon: React.ElementType }[] = [
  { value: 'call', label: 'Llamada', icon: Phone },
  { value: 'email', label: 'Email', icon: Mail },
  { value: 'visit', label: 'Visita Técnica', icon: Users },
  { value: 'consultation', label: 'Asesoría', icon: HelpCircle },
];

const priorityOptions: { value: InteractionPriority; label: string; color: string }[] = [
  { value: 'low', label: 'Baja', color: 'bg-gray-100 text-gray-800' },
  { value: 'medium', label: 'Media', color: 'bg-yellow-100 text-yellow-800' },
  { value: 'high', label: 'Alta', color: 'bg-red-100 text-red-800' },
];

export function InteractionModal({ isOpen, onClose, onSubmit, clientId, interaction, isSubmitting }: InteractionModalProps) {
  const { user } = useAuthStore();
  const [formData, setFormData] = useState<Omit<ClientInteractionInsert, 'client_id' | 'agent_id'>>({
    type: 'call',
    date: new Date().toISOString(),
    notes: '',
    next_action: '',
    next_action_date: null,
    priority: 'medium',
    status: 'pending',
    attachments: [],
  });
  const [uploadingFiles, setUploadingFiles] = useState(false);
  const [errors, setErrors] = useState<Record<string, string>>({});

  // Initialize form with interaction data if editing
  useEffect(() => {
    if (interaction) {
      setFormData({
        type: interaction.type,
        date: interaction.date,
        notes: interaction.notes,
        next_action: interaction.next_action || '',
        next_action_date: interaction.next_action_date,
        priority: interaction.priority,
        status: interaction.status,
        attachments: interaction.attachments || [],
      });
    } else {
      // Reset form for new interaction
      setFormData({
        type: 'call',
        date: new Date().toISOString(),
        notes: '',
        next_action: '',
        next_action_date: null,
        priority: 'medium',
        status: 'pending',
        attachments: [],
      });
    }
  }, [interaction]);

  const onDrop = useCallback(async (acceptedFiles: File[]) => {
    setUploadingFiles(true);
    try {
      const uploadedFiles = await Promise.all(
        acceptedFiles.map(async (file) => {
          const fileExt = file.name.split('.').pop();
          const fileName = `${Math.random().toString(36).substring(2)}.${fileExt}`;
          const filePath = `${clientId}/${fileName}`;

          const { error: uploadError, data } = await supabase.storage
            .from('interaction-attachments')
            .upload(filePath, file);

          if (uploadError) throw uploadError;

          const { data: { publicUrl } } = supabase.storage
            .from('interaction-attachments')
            .getPublicUrl(filePath);

          return {
            name: file.name,
            url: publicUrl,
            type: file.type,
          };
        })
      );

      setFormData(prev => ({
        ...prev,
        attachments: [...(prev.attachments || []), ...uploadedFiles],
      }));
    } catch (error) {
      console.error('Error uploading files:', error);
    } finally {
      setUploadingFiles(false);
    }
  }, [clientId]);

  const { getRootProps, getInputProps, isDragActive } = useDropzone({
    onDrop,
    accept: {
      'image/*': ['.png', '.jpg', '.jpeg', '.gif'],
      'application/pdf': ['.pdf'],
      'application/msword': ['.doc'],
      'application/vnd.openxmlformats-officedocument.wordprocessingml.document': ['.docx'],
    },
    maxSize: 5242880, // 5MB
  });

  const validateForm = () => {
    const newErrors: Record<string, string> = {};

    if (!formData.notes?.trim()) {
      newErrors.notes = 'Las notas son requeridas';
    }

    if (formData.next_action?.trim() && !formData.next_action_date) {
      newErrors.next_action_date = 'La fecha de siguiente acción es requerida';
    }

    if (!user?.id) {
      newErrors.user = 'No hay usuario autenticado';
    }

    if (!clientId) {
      newErrors.client = 'No se ha especificado el cliente';
    }

    setErrors(newErrors);
    return Object.keys(newErrors).length === 0;
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    console.log('Guardando interacción...');
    
    if (!user?.id) {
      console.error('No user ID available');
      return;
    }

    if (validateForm()) {
      const interactionData: ClientInteractionInsert = {
        ...formData,
        client_id: clientId,
        agent_id: user.id,
      };
      
      console.log('Submitting interaction data:', interactionData);
      try {
        await onSubmit(interactionData);
      } catch (error) {
        console.error('Error submitting interaction:', error);
      }
    }
  };

  if (!isOpen) return null;

  return (
    <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 overflow-y-auto">
      <div className="bg-white rounded-lg w-full max-w-2xl p-6 m-4">
        <div className="flex justify-between items-center mb-4">
          <h2 className="text-xl font-semibold text-gray-900">
            {interaction ? 'Editar Interacción' : 'Nueva Interacción'}
          </h2>
          <button
            onClick={onClose}
            className="text-gray-400 hover:text-gray-500"
          >
            <X className="w-6 h-6" />
          </button>
        </div>

        <form onSubmit={handleSubmit} className="space-y-6">
          {errors.user && (
            <div className="bg-red-50 p-4 rounded-md">
              <div className="flex">
                <AlertCircle className="h-5 w-5 text-red-400" />
                <p className="ml-3 text-sm text-red-700">{errors.user}</p>
              </div>
            </div>
          )}

          {errors.client && (
            <div className="bg-red-50 p-4 rounded-md">
              <div className="flex">
                <AlertCircle className="h-5 w-5 text-red-400" />
                <p className="ml-3 text-sm text-red-700">{errors.client}</p>
              </div>
            </div>
          )}

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">
              Tipo de Interacción
            </label>
            <div className="grid grid-cols-2 gap-2">
              {interactionTypes.map(({ value, label, icon: Icon }) => (
                <button
                  key={value}
                  type="button"
                  onClick={() => setFormData(prev => ({ ...prev, type: value }))}
                  className={`flex items-center justify-center p-3 rounded-lg border ${
                    formData.type === value
                      ? 'border-blue-500 bg-blue-50 text-blue-700'
                      : 'border-gray-200 hover:border-gray-300'
                  }`}
                >
                  <Icon className="w-5 h-5 mr-2" />
                  {label}
                </button>
              ))}
            </div>
          </div>

          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="block text-sm font-medium text-gray-700">
                Fecha y Hora
              </label>
              <DatePicker
                selected={new Date(formData.date)}
                onChange={(date: Date) => setFormData(prev => ({ 
                  ...prev, 
                  date: date.toISOString() 
                }))}
                showTimeSelect
                dateFormat="Pp"
                className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
              />
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">
                Prioridad
              </label>
              <div className="flex space-x-2">
                {priorityOptions.map(({ value, label, color }) => (
                  <button
                    key={value}
                    type="button"
                    onClick={() => setFormData(prev => ({ ...prev, priority: value }))}
                    className={`flex items-center px-3 py-1 rounded-full border ${
                      formData.priority === value
                        ? `${color} border-transparent`
                        : 'border-gray-300 hover:bg-gray-50'
                    }`}
                  >
                    <Flag className={`w-4 h-4 mr-1 ${formData.priority === value ? '' : 'text-gray-400'}`} />
                    {label}
                  </button>
                ))}
              </div>
            </div>
          </div>

          <div>
            <label htmlFor="notes" className="block text-sm font-medium text-gray-700">
              Notas
            </label>
            <textarea
              id="notes"
              value={formData.notes}
              onChange={(e) => setFormData(prev => ({ ...prev, notes: e.target.value }))}
              rows={3}
              className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
              placeholder="Describe el resultado de la interacción"
            />
            {errors.notes && (
              <p className="mt-1 text-sm text-red-600">{errors.notes}</p>
            )}
          </div>

          <div>
            <label htmlFor="next_action" className="block text-sm font-medium text-gray-700">
              Siguiente Acción
            </label>
            <input
              type="text"
              id="next_action"
              value={formData.next_action || ''}
              onChange={(e) => setFormData(prev => ({ ...prev, next_action: e.target.value }))}
              className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
              placeholder="¿Qué acción se debe tomar después?"
            />
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700">
              Fecha de Siguiente Acción
            </label>
            <DatePicker
              selected={formData.next_action_date ? new Date(formData.next_action_date) : null}
              onChange={(date: Date | null) => setFormData(prev => ({ 
                ...prev, 
                next_action_date: date ? date.toISOString() : null 
              }))}
              showTimeSelect
              dateFormat="Pp"
              isClearable
              placeholderText="Selecciona una fecha"
              className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
            />
            {errors.next_action_date && (
              <p className="mt-1 text-sm text-red-600">{errors.next_action_date}</p>
            )}
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">
              Estado
            </label>
            <select
              value={formData.status}
              onChange={(e) => setFormData(prev => ({ ...prev, status: e.target.value as 'pending' | 'completed' | 'cancelled' }))}
              className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
            >
              <option value="pending">Pendiente</option>
              <option value="completed">Completada</option>
              <option value="cancelled">Cancelada</option>
            </select>
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">
              Adjuntar Archivos
            </label>
            <div
              {...getRootProps()}
              className={`border-2 border-dashed rounded-lg p-4 text-center cursor-pointer transition-colors ${
                isDragActive ? 'border-blue-500 bg-blue-50' : 'border-gray-300 hover:border-gray-400'
              }`}
            >
              <input {...getInputProps()} />
              <Upload className="w-8 h-8 mx-auto mb-2 text-gray-400" />
              {uploadingFiles ? (
                <p className="text-sm text-gray-600">Subiendo archivos...</p>
              ) : isDragActive ? (
                <p className="text-sm text-blue-600">Suelta los archivos aquí</p>
              ) : (
                <>
                  <p className="text-sm text-gray-600">
                    Arrastra archivos aquí o haz clic para seleccionar
                  </p>
                  <p className="text-xs text-gray-500 mt-1">
                    Máximo 5MB por archivo. Formatos: PDF, DOC, DOCX, PNG, JPG
                  </p>
                </>
              )}
            </div>
            {formData.attachments && formData.attachments.length > 0 && (
              <div className="mt-2 space-y-1">
                {formData.attachments.map((file, fileIndex) => (
                  <div key={fileIndex} className="flex items-center text-sm text-gray-600">
                    <a
                      href={file.url}
                      target="_blank"
                      rel="noopener noreferrer"
                      className="hover:text-blue-600"
                    >
                      {file.name}
                    </a>
                    <button
                      type="button"
                      onClick={() => setFormData(prev => ({
                        ...prev,
                        attachments: prev.attachments?.filter((_, i) => i !== fileIndex) || [],
                      }))}
                      className="ml-2 text-red-600 hover:text-red-800"
                    >
                      <X className="w-4 h-4" />
                    </button>
                  </div>
                ))}
              </div>
            )}
          </div>

          <div className="mt-6 flex justify-end space-x-3">
            <button
              type="button"
              onClick={onClose}
              className="px-4 py-2 border border-gray-300 rounded-md text-sm font-medium text-gray-700 hover:bg-gray-50"
            >
              Cancelar
            </button>
            <button
              type="submit"
              disabled={isSubmitting || uploadingFiles}
              className="px-4 py-2 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-blue-600 hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 disabled:opacity-50"
            >
              {isSubmitting ? 'Guardando...' : interaction ? 'Actualizar' : 'Guardar'}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
}