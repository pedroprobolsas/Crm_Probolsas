import React, { useState, useEffect } from 'react';
import { X, Save, AlertTriangle } from 'lucide-react';

interface Product {
  id: string;
  sku: string;
  name: string;
  existencia: number;
  margen: number;
  margen2: number;
  margen3: number;
  margen4: number;
  unit_type: string;
  costo: number;
}

interface ProductEditModalProps {
  product: Product | null;
  isOpen: boolean;
  onClose: () => void;
  onSave: (product: Product) => Promise<void>;
  isSubmitting?: boolean;
}

export function ProductEditModal({ product, isOpen, onClose, onSave, isSubmitting }: ProductEditModalProps) {
  const [formData, setFormData] = useState<Product | null>(null);
  const [errors, setErrors] = useState<Record<string, string>>({});

  useEffect(() => {
    if (product) {
      setFormData(product);
    }
  }, [product]);

  if (!isOpen || !formData) return null;

  const validateForm = () => {
    const newErrors: Record<string, string> = {};

    if (!formData.sku.trim()) {
      newErrors.sku = 'El SKU es requerido';
    }

    if (!formData.name.trim()) {
      newErrors.name = 'El nombre es requerido';
    }

    if (formData.existencia < 0) {
      newErrors.existencia = 'La existencia no puede ser negativa';
    }

    if (formData.costo < 0) {
      newErrors.costo = 'El costo no puede ser negativo';
    }

    if (formData.margen <= 0) {
      newErrors.margen = 'El margen debe ser mayor a 0';
    }

    setErrors(newErrors);
    return Object.keys(newErrors).length === 0;
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (validateForm() && formData) {
      await onSave(formData);
    }
  };

  const handleChange = (field: keyof Product, value: string | number) => {
    if (formData) {
      // Convert empty strings to 0 for numeric fields
      const processedValue = typeof value === 'string' && value.trim() === '' ? 0 : value;
      
      setFormData({
        ...formData,
        [field]: processedValue
      });

      // Clear error when field is modified
      if (errors[field]) {
        setErrors(prev => {
          const newErrors = { ...prev };
          delete newErrors[field];
          return newErrors;
        });
      }
    }
  };

  return (
    <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
      <div className="bg-white rounded-lg w-full max-w-2xl p-6">
        <div className="flex justify-between items-center mb-4">
          <h2 className="text-xl font-semibold text-gray-900">
            Editar Producto
          </h2>
          <button
            onClick={onClose}
            className="text-gray-400 hover:text-gray-500"
          >
            <X className="w-6 h-6" />
          </button>
        </div>

        <form onSubmit={handleSubmit} className="space-y-6">
          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="block text-sm font-medium text-gray-700">
                SKU
              </label>
              <input
                type="text"
                value={formData.sku}
                onChange={(e) => handleChange('sku', e.target.value)}
                className={`mt-1 block w-full rounded-md shadow-sm ${
                  errors.sku ? 'border-red-300' : 'border-gray-300'
                } focus:border-blue-500 focus:ring-blue-500`}
                disabled={isSubmitting}
              />
              {errors.sku && (
                <p className="mt-1 text-sm text-red-600 flex items-center">
                  <AlertTriangle className="w-4 h-4 mr-1" />
                  {errors.sku}
                </p>
              )}
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700">
                Nombre
              </label>
              <input
                type="text"
                value={formData.name}
                onChange={(e) => handleChange('name', e.target.value)}
                className={`mt-1 block w-full rounded-md shadow-sm ${
                  errors.name ? 'border-red-300' : 'border-gray-300'
                } focus:border-blue-500 focus:ring-blue-500`}
                disabled={isSubmitting}
              />
              {errors.name && (
                <p className="mt-1 text-sm text-red-600 flex items-center">
                  <AlertTriangle className="w-4 h-4 mr-1" />
                  {errors.name}
                </p>
              )}
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700">
                Existencia
              </label>
              <input
                type="number"
                value={formData.existencia.toString()}
                onChange={(e) => handleChange('existencia', parseInt(e.target.value) || 0)}
                className={`mt-1 block w-full rounded-md shadow-sm ${
                  errors.existencia ? 'border-red-300' : 'border-gray-300'
                } focus:border-blue-500 focus:ring-blue-500`}
                disabled={isSubmitting}
                min="0"
              />
              {errors.existencia && (
                <p className="mt-1 text-sm text-red-600 flex items-center">
                  <AlertTriangle className="w-4 h-4 mr-1" />
                  {errors.existencia}
                </p>
              )}
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700">
                Unidad
              </label>
              <select
                value={formData.unit_type}
                onChange={(e) => handleChange('unit_type', e.target.value)}
                className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
                disabled={isSubmitting}
              >
                <option value="unidades">Unidades</option>
                <option value="paquetes">Paquetes</option>
                <option value="kilos">Kilos</option>
                <option value="metros">Metros</option>
                <option value="rollos">Rollos</option>
              </select>
            </div>
          </div>

          <div className="border-t border-gray-200 pt-4">
            <h3 className="text-lg font-medium text-gray-900 mb-4">Costos y Precios</h3>
            <div className="grid grid-cols-2 gap-4">
              <div>
                <label className="block text-sm font-medium text-gray-700">
                  Costo
                </label>
                <input
                  type="number"
                  step="0.01"
                  value={formData.costo.toString()}
                  onChange={(e) => handleChange('costo', parseFloat(e.target.value) || 0)}
                  className={`mt-1 block w-full rounded-md shadow-sm ${
                    errors.costo ? 'border-red-300' : 'border-gray-300'
                  } focus:border-blue-500 focus:ring-blue-500`}
                  disabled={isSubmitting}
                  min="0"
                />
                {errors.costo && (
                  <p className="mt-1 text-sm text-red-600 flex items-center">
                    <AlertTriangle className="w-4 h-4 mr-1" />
                    {errors.costo}
                  </p>
                )}
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700">
                  % Margen 
                </label>
                <input
                  type="number"
                  step="0.01"
                  value={formData.margen.toString()}
                  onChange={(e) => handleChange('margen', parseFloat(e.target.value) || 0)}
                  className={`mt-1 block w-full rounded-md shadow-sm ${
                    errors.margen ? 'border-red-300' : 'border-gray-300'
                  } focus:border-blue-500 focus:ring-blue-500`}
                  disabled={isSubmitting}
                  min="0"
                />
                {errors.margen && (
                  <p className="mt-1 text-sm text-red-600 flex items-center">
                    <AlertTriangle className="w-4 h-4 mr-1" />
                    {errors.margen}
                  </p>
                )}
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700">
                  % Margen 2
                </label>
                <input
                  type="number"
                  step="0.01"
                  value={formData.margen2.toString()}
                  onChange={(e) => handleChange('margen2', parseFloat(e.target.value) || 0)}
                  className={`mt-1 block w-full rounded-md shadow-sm ${
                    errors.margen2 ? 'border-red-300' : 'border-gray-300'
                  } focus:border-blue-500 focus:ring-blue-500`}
                  disabled={isSubmitting}
                  min="0"
                />
                {errors.margen2 && (
                  <p className="mt-1 text-sm text-red-600 flex items-center">
                    <AlertTriangle className="w-4 h-4 mr-1" />
                    {errors.margen2}
                  </p>
                )}
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700">
                  % Margen 3
                </label>
                <input
                  type="number"
                  step="0.01"
                  value={formData.margen3.toString()}
                  onChange={(e) => handleChange('margen3', parseFloat(e.target.value) || 0)}
                  className={`mt-1 block w-full rounded-md shadow-sm ${
                    errors.margen3 ? 'border-red-300' : 'border-gray-300'
                  } focus:border-blue-500 focus:ring-blue-500`}
                  disabled={isSubmitting}
                  min="0"
                />
                {errors.margen3 && (
                  <p className="mt-1 text-sm text-red-600 flex items-center">
                    <AlertTriangle className="w-4 h-4 mr-1" />
                    {errors.margen3}
                  </p>
                )}
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700">
                  % Margen 4
                </label>
                <input
                  type="number"
                  step="0.01"
                  value={formData.margen4.toString()}
                  onChange={(e) => handleChange('margen4', parseFloat(e.target.value) || 0)}
                  className={`mt-1 block w-full rounded-md shadow-sm ${
                    errors.margen4 ? 'border-red-300' : 'border-gray-300'
                  } focus:border-blue-500 focus:ring-blue-500`}
                  disabled={isSubmitting}
                  min="0"
                />
                {errors.margen4 && (
                  <p className="mt-1 text-sm text-red-600 flex items-center">
                    <AlertTriangle className="w-4 h-4 mr-1" />
                    {errors.margen4}
                  </p>
                )}
              </div>
            </div>
          </div>

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
              disabled={isSubmitting}
              className="px-4 py-2 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-blue-600 hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 disabled:opacity-50"
            >
              {isSubmitting ? (
                <span className="flex items-center">
                  <svg className="animate-spin -ml-1 mr-2 h-4 w-4 text-white" fill="none" viewBox="0 0 24 24">
                    <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4" />
                    <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z" />
                  </svg>
                  Guardando...
                </span>
              ) : (
                'Guardar Cambios'
              )}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
}