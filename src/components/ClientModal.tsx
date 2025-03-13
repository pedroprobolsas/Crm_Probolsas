import React, { useState } from 'react';
import { X, Package, AlertTriangle } from 'lucide-react';
import { useAgents } from '../lib/hooks/useAgents';
import { usePackagingTypes, PackagingType as BasePackagingType } from '../lib/hooks/usePackagingTypes';
import { supabase } from '../lib/supabase';
import { toast } from 'sonner';

// Define Client and ClientInsert types if they're not available in the types file
interface Client {
  id: string;
  name: string;
  email: string;
  phone: string;
  company: string;
  description: string;
  brand: string;
  status: string;
  assigned_agent_id: string;
  packaging_types: Array<{
    code: string;
    type: string;
    monthly_volume: number;
    unit: string;
    material?: string;
    thickness?: string;
    processes?: string[];
    features: Record<string, any>;
  }>;
}

interface ClientInsert {
  name: string;
  email: string;
  phone: string;
  company: string;
  description: string;
  brand: string;
  status: string;
  assigned_agent_id: string;
  packaging_types?: Array<{
    code: string;
    type: string;
    monthly_volume: number;
    unit: string;
    material?: string;
    thickness?: string;
    processes?: string[];
    features: Record<string, any>;
  }>;
}

// Extend the PackagingType interface to include the properties we need
interface PackagingType extends BasePackagingType {
  materials: string[];
  thicknesses: string[];
  processes: string[];
}

interface ClientModalProps {
  isOpen: boolean;
  onClose: () => void;
  onSubmit: (data: ClientInsert) => void;
  client?: Client;
  isSubmitting?: boolean;
}

export function ClientModal({ isOpen, onClose, onSubmit, client, isSubmitting }: ClientModalProps) {
  const { agents } = useAgents();
  const { packagingTypes: fetchedPackagingTypes, isLoading: isLoadingPackagingTypes, error: packagingTypesError } = usePackagingTypes();
  
  // Cast the fetched packaging types to our extended interface
  const packagingTypes = fetchedPackagingTypes as PackagingType[];
  
  const [formData, setFormData] = useState<ClientInsert>({
    name: client?.name || '',
    email: client?.email || '',
    phone: client?.phone || '',
    company: client?.company || '',
    description: client?.description || '',
    brand: client?.brand || '',
    status: client?.status || 'active',
    assigned_agent_id: client?.assigned_agent_id || '',
    packaging_types: client?.packaging_types || []
  });

  const [errors, setErrors] = useState<Record<string, string>>({});
  const [selectedPackagingType, setSelectedPackagingType] = useState<string>('');
  const [selectedMaterial, setSelectedMaterial] = useState<string>('');
  const [selectedThickness, setSelectedThickness] = useState<string>('');
  const [monthlyVolume, setMonthlyVolume] = useState<number>(0);
  const [selectedProcesses, setSelectedProcesses] = useState<string[]>([]);

  const handleAddPackagingType = () => {
    if (!selectedPackagingType) {
      setErrors((prev: Record<string, string>) => ({ ...prev, packaging_type: 'Seleccione un tipo de empaque' }));
      return;
    }

    const packagingType = packagingTypes.find(pt => pt.code === selectedPackagingType);
    if (!packagingType) return;

    const newPackagingType = {
      code: selectedPackagingType,
      type: packagingType.name,
      monthly_volume: monthlyVolume,
      unit: 'unidades',
      material: selectedMaterial,
      thickness: selectedThickness,
      processes: selectedProcesses,
      features: {}
    };

    setFormData((prev: ClientInsert) => ({
      ...prev,
      packaging_types: [...(prev.packaging_types || []), newPackagingType]
    }));

    // Reset selections
    setSelectedPackagingType('');
    setSelectedMaterial('');
    setSelectedThickness('');
    setMonthlyVolume(0);
    setSelectedProcesses([]);
    setErrors((prev: Record<string, string>) => {
      const newErrors = { ...prev };
      delete newErrors.packaging_type;
      return newErrors;
    });
  };

  const handleRemovePackagingType = (index: number) => {
    setFormData((prev: ClientInsert) => ({
      ...prev,
      packaging_types: prev.packaging_types?.filter((_: any, i: number) => i !== index) || []
    }));
  };

  const validateForm = () => {
    const newErrors: Record<string, string> = {};

    if (!formData.name.trim()) {
      newErrors.name = 'El nombre es requerido';
    }

    if (!formData.email.trim()) {
      newErrors.email = 'El correo es requerido';
    } else if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(formData.email)) {
      newErrors.email = 'Correo electrónico inválido';
    }

    if (!formData.phone.trim()) {
      newErrors.phone = 'El teléfono es requerido';
    }

    if (!formData.company.trim()) {
      newErrors.company = 'La empresa es requerida';
    }

    if (!formData.description.trim()) {
      newErrors.description = 'La descripción es requerida';
    }

    if (!formData.brand.trim()) {
      newErrors.brand = 'La marca es requerida';
    }

    if (!formData.assigned_agent_id) {
      newErrors.assigned_agent_id = 'El asesor es requerido';
    }

    setErrors(newErrors);
    return Object.keys(newErrors).length === 0;
  };

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (validateForm()) {
      onSubmit(formData);
    }
  };

  if (!isOpen) return null;

  const currentPackagingType = packagingTypes.find(pt => pt.code === selectedPackagingType);

  return (
    <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
      <div className="bg-white rounded-lg w-full max-w-4xl p-6 max-h-[90vh] overflow-y-auto">
        <div className="flex justify-between items-center mb-4">
          <h2 className="text-xl font-semibold text-gray-900">
            {client ? 'Editar Cliente' : 'Nuevo Cliente'}
          </h2>
          <button
            onClick={onClose}
            className="text-gray-400 hover:text-gray-500"
          >
            <X className="w-6 h-6" />
          </button>
        </div>

        <form onSubmit={handleSubmit} className="space-y-6">
          <div className="grid grid-cols-2 gap-6">
            <div>
              <label htmlFor="name" className="block text-sm font-medium text-gray-700">
                Nombre
              </label>
              <input
                type="text"
                id="name"
                value={formData.name}
                onChange={(e) => setFormData((prev: ClientInsert) => ({ ...prev, name: e.target.value }))}
                className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
              />
              {errors.name && (
                <p className="mt-1 text-sm text-red-600">{errors.name}</p>
              )}
            </div>

            <div>
              <label htmlFor="email" className="block text-sm font-medium text-gray-700">
                Correo Electrónico
              </label>
              <input
                type="email"
                id="email"
                value={formData.email}
                onChange={(e) => setFormData((prev: ClientInsert) => ({ ...prev, email: e.target.value }))}
                className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
              />
              {errors.email && (
                <p className="mt-1 text-sm text-red-600">{errors.email}</p>
              )}
            </div>

            <div>
              <label htmlFor="phone" className="block text-sm font-medium text-gray-700">
                Teléfono
              </label>
              <input
                type="tel"
                id="phone"
                value={formData.phone}
                onChange={(e) => setFormData((prev: ClientInsert) => ({ ...prev, phone: e.target.value }))}
                className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
              />
              {errors.phone && (
                <p className="mt-1 text-sm text-red-600">{errors.phone}</p>
              )}
            </div>

            <div>
              <label htmlFor="company" className="block text-sm font-medium text-gray-700">
                Empresa
              </label>
              <input
                type="text"
                id="company"
                value={formData.company}
                onChange={(e) => setFormData((prev: ClientInsert) => ({ ...prev, company: e.target.value }))}
                className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
              />
              {errors.company && (
                <p className="mt-1 text-sm text-red-600">{errors.company}</p>
              )}
            </div>

            <div>
              <label htmlFor="brand" className="block text-sm font-medium text-gray-700">
                Marca
              </label>
              <input
                type="text"
                id="brand"
                value={formData.brand}
                onChange={(e) => setFormData((prev: ClientInsert) => ({ ...prev, brand: e.target.value }))}
                className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
                placeholder="Marca principal del cliente"
              />
              {errors.brand && (
                <p className="mt-1 text-sm text-red-600">{errors.brand}</p>
              )}
            </div>

            <div>
              <label htmlFor="assigned_agent_id" className="block text-sm font-medium text-gray-700">
                Asesor Asignado
              </label>
              <select
                id="assigned_agent_id"
                value={formData.assigned_agent_id}
                onChange={(e) => setFormData((prev: ClientInsert) => ({ ...prev, assigned_agent_id: e.target.value }))}
                className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
              >
                <option value="">Seleccionar asesor</option>
                {agents?.filter(a => a.status !== 'inactive').map((agent) => (
                  <option key={agent.id} value={agent.id}>
                    {agent.name}
                  </option>
                ))}
              </select>
              {errors.assigned_agent_id && (
                <p className="mt-1 text-sm text-red-600">{errors.assigned_agent_id}</p>
              )}
            </div>
          </div>

          <div>
            <label htmlFor="description" className="block text-sm font-medium text-gray-700">
              Descripción
            </label>
            <textarea
              id="description"
              value={formData.description}
              onChange={(e) => setFormData((prev: ClientInsert) => ({ ...prev, description: e.target.value }))}
              rows={3}
              className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
              placeholder="Describe la actividad principal del cliente"
            />
            {errors.description && (
              <p className="mt-1 text-sm text-red-600">{errors.description}</p>
            )}
          </div>

          {/* Packaging Types Section */}
          <div className="border-t border-gray-200 pt-6">
            <h3 className="text-lg font-medium text-gray-900 mb-4 flex items-center">
              <Package className="w-5 h-5 mr-2 text-gray-500" />
              Tipos de Empaque
            </h3>

            {packagingTypesError ? (
              <div className="bg-red-50 border border-red-200 rounded-lg p-4 mb-4">
                <div className="flex items-center">
                  <AlertTriangle className="w-5 h-5 text-red-400 mr-2" />
                  <p className="text-sm text-red-700">{packagingTypesError.toString()}</p>
                </div>
                <button
                  type="button"
                  onClick={() => window.location.reload()}
                  className="mt-2 text-sm text-red-600 hover:text-red-800"
                >
                  Reintentar
                </button>
              </div>
            ) : (
              <div className="space-y-4">
                {/* Current Packaging Types */}
                {formData.packaging_types && formData.packaging_types.length > 0 && (
                  <div className="space-y-2">
                    {formData.packaging_types.map((pt, index) => (
                      <div key={index} className="flex items-center justify-between bg-gray-50 p-3 rounded-lg">
                        <div className="flex-1">
                          <p className="font-medium text-gray-900">{pt.type}</p>
                          <p className="text-sm text-gray-500">
                            {pt.monthly_volume} {pt.unit} / mes
                            {pt.material && ` • ${pt.material}`}
                            {pt.thickness && ` • ${pt.thickness}`}
                          </p>
                          {pt.processes && pt.processes.length > 0 && (
                            <div className="mt-1 flex flex-wrap gap-1">
                              {pt.processes.map((process, i) => (
                                <span key={i} className="inline-flex items-center px-2 py-0.5 rounded text-xs font-medium bg-blue-100 text-blue-800">
                                  {process}
                                </span>
                              ))}
                            </div>
                          )}
                        </div>
                        <button
                          type="button"
                          onClick={() => handleRemovePackagingType(index)}
                          className="ml-2 text-red-600 hover:text-red-800"
                        >
                          <X className="w-5 h-5" />
                        </button>
                      </div>
                    ))}
                  </div>
                )}

                {/* Add New Packaging Type */}
                <div className="bg-gray-50 p-4 rounded-lg">
                  <div className="grid grid-cols-2 gap-4">
                    <div>
                      <label className="block text-sm font-medium text-gray-700">
                        Tipo de Empaque
                      </label>
                      <select
                        value={selectedPackagingType}
                        onChange={(e) => {
                          setSelectedPackagingType(e.target.value);
                          setErrors((prev: Record<string, string>) => {
                            const newErrors = { ...prev };
                            delete newErrors.packaging_type;
                            return newErrors;
                          });
                        }}
                        className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
                        disabled={isLoadingPackagingTypes}
                      >
                        <option value="">Seleccionar tipo</option>
                        {packagingTypes.map((pt) => (
                          <option key={pt.code} value={pt.code}>
                            {pt.name}
                          </option>
                        ))}
                      </select>
                      {errors.packaging_type && (
                        <p className="mt-1 text-sm text-red-600">{errors.packaging_type}</p>
                      )}
                    </div>

                    <div>
                      <label className="block text-sm font-medium text-gray-700">
                        Volumen Mensual
                      </label>
                      <div className="mt-1 flex rounded-md shadow-sm">
                        <input
                          type="number"
                          value={monthlyVolume}
                          onChange={(e) => setMonthlyVolume(parseInt(e.target.value) || 0)}
                          min="0"
                          className="flex-1 rounded-l-md border-gray-300 focus:border-blue-500 focus:ring-blue-500"
                          disabled={isLoadingPackagingTypes}
                        />
                        <span className="inline-flex items-center px-3 rounded-r-md border border-l-0 border-gray-300 bg-gray-50 text-gray-500 sm:text-sm">
                          unidades
                        </span>
                      </div>
                    </div>

                    {currentPackagingType && (
                      <>
                        <div>
                          <label className="block text-sm font-medium text-gray-700">
                            Material
                          </label>
                          <select
                            value={selectedMaterial}
                            onChange={(e) => setSelectedMaterial(e.target.value)}
                            className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
                            disabled={isLoadingPackagingTypes}
                          >
                            <option value="">Seleccionar material</option>
                            {currentPackagingType.materials.map((material: string) => (
                              <option key={material} value={material}>
                                {material}
                              </option>
                            ))}
                          </select>
                        </div>

                        <div>
                          <label className="block text-sm font-medium text-gray-700">
                            Espesor
                          </label>
                          <select
                            value={selectedThickness}
                            onChange={(e) => setSelectedThickness(e.target.value)}
                            className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
                            disabled={isLoadingPackagingTypes}
                          >
                            <option value="">Seleccionar espesor</option>
                            {currentPackagingType.thicknesses.map((thickness: string) => (
                              <option key={thickness} value={thickness}>
                                {thickness}
                              </option>
                            ))}
                          </select>
                        </div>

                        <div className="col-span-2">
                          <label className="block text-sm font-medium text-gray-700 mb-1">
                            Procesos
                          </label>
                          <div className="space-y-2">
                            {currentPackagingType.processes.map((process: string) => (
                              <label key={process} className="inline-flex items-center mr-4">
                                <input
                                  type="checkbox"
                                  checked={selectedProcesses.includes(process)}
                                  onChange={(e) => {
                                    if (e.target.checked) {
                                      setSelectedProcesses([...selectedProcesses, process]);
                                    } else {
                                      setSelectedProcesses(selectedProcesses.filter(p => p !== process));
                                    }
                                  }}
                                  className="rounded border-gray-300 text-blue-600 shadow-sm focus:border-blue-300 focus:ring focus:ring-blue-200 focus:ring-opacity-50"
                                  disabled={isLoadingPackagingTypes}
                                />
                                <span className="ml-2 text-sm text-gray-700">{process}</span>
                              </label>
                            ))}
                          </div>
                        </div>
                      </>
                    )}
                  </div>

                  <div className="mt-4">
                    <button
                      type="button"
                      onClick={handleAddPackagingType}
                      disabled={isLoadingPackagingTypes}
                      className="inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md shadow-sm text-white bg-blue-600 hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 disabled:opacity-50"
                    >
                      {isLoadingPackagingTypes ? (
                        <>
                          <div className="animate-spin rounded-full h-4 w-4 border-b-2 border-white mr-2"></div>
                          Cargando...
                        </>
                      ) : (
                        'Agregar Tipo de Empaque'
                      )}
                    </button>
                  </div>
                </div>
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
              disabled={isSubmitting || isLoadingPackagingTypes}
              className="px-4 py-2 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-blue-600 hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 disabled:opacity-50"
            >
              {isSubmitting ? 'Guardando...' : client ? 'Actualizar' : 'Crear'}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
}
