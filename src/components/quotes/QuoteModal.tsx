import React, { useState, useEffect } from 'react';
import { X, Plus, Save, AlertTriangle, Calendar, FileText, Calculator } from 'lucide-react';
import DatePicker from 'react-datepicker';
import { es } from 'date-fns/locale';
import { ProductSelector } from './ProductSelector';
import type { Product, Quote, QuoteItem } from '../../lib/types';
import { toast } from 'sonner';
import "react-datepicker/dist/react-datepicker.css";

interface QuoteModalProps {
  isOpen: boolean;
  onClose: () => void;
  onSubmit: (quote: Omit<Quote, 'id' | 'created_at'>) => Promise<void>;
  clientId: string;
  isSubmitting?: boolean;
}

export function QuoteModal({ isOpen, onClose, onSubmit, clientId, isSubmitting }: QuoteModalProps) {
  const [formData, setFormData] = useState<Omit<Quote, 'id' | 'created_at'>>({
    client_id: clientId,
    quote_number: `COT-${Date.now()}`,
    status: 'draft',
    total_amount: 0,
    valid_until: new Date(Date.now() + 15 * 24 * 60 * 60 * 1000), // 15 days from now
    terms: '',
    notes: '',
    items: []
  });

  const [errors, setErrors] = useState<Record<string, string>>({});

  const calculateTotals = (items: QuoteItem[]) => {
    const total = items.reduce((sum, item) => sum + (item.quantity * item.unit_price), 0);
    return total;
  };

  const handleAddItem = (product: Product, quantity: number, priceLevel: 'regular' | 'price_2' | 'price_3' | 'price_4') => {
    const price = product[priceLevel];
    const newItem: QuoteItem = {
      product_id: product.id,
      product_name: product.name,
      quantity,
      unit_price: price,
      total_price: quantity * price,
      notes: ''
    };

    setFormData(prev => {
      const newItems = [...prev.items, newItem];
      return {
        ...prev,
        items: newItems,
        total_amount: calculateTotals(newItems)
      };
    });
  };

  const handleRemoveItem = (index: number) => {
    setFormData(prev => {
      const newItems = prev.items.filter((_, i) => i !== index);
      return {
        ...prev,
        items: newItems,
        total_amount: calculateTotals(newItems)
      };
    });
  };

  const validateForm = () => {
    const newErrors: Record<string, string> = {};

    if (formData.items.length === 0) {
      newErrors.items = 'Debe agregar al menos un producto';
    }

    if (!formData.valid_until) {
      newErrors.valid_until = 'La fecha de validez es requerida';
    }

    setErrors(newErrors);
    return Object.keys(newErrors).length === 0;
  };

  const handleSubmit = async (e: React.FormEvent, asDraft = true) => {
    e.preventDefault();
    
    if (!validateForm()) return;

    try {
      await onSubmit({
        ...formData,
        status: asDraft ? 'draft' : 'sent'
      });
      toast.success(asDraft ? 'Cotización guardada como borrador' : 'Cotización enviada');
      onClose();
    } catch (error) {
      console.error('Error saving quote:', error);
      toast.error('Error al guardar la cotización');
    }
  };

  if (!isOpen) return null;

  return (
    <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
      <div className="bg-white rounded-lg w-full max-w-4xl p-6 max-h-[90vh] overflow-y-auto">
        <div className="flex justify-between items-center mb-4">
          <h2 className="text-xl font-semibold text-gray-900">
            Nueva Cotización
          </h2>
          <button
            onClick={onClose}
            className="text-gray-400 hover:text-gray-500"
          >
            <X className="w-6 h-6" />
          </button>
        </div>

        <form onSubmit={(e) => handleSubmit(e, true)} className="space-y-6">
          {/* Product Selection */}
          <div>
            <h3 className="text-lg font-medium text-gray-900 mb-4 flex items-center">
              <Calculator className="w-5 h-5 mr-2 text-gray-500" />
              Productos y Cantidades
            </h3>
            <ProductSelector onAddItem={handleAddItem} />
            
            {/* Selected Products Table */}
            {formData.items.length > 0 && (
              <div className="mt-4">
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
                      <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                        Acciones
                      </th>
                    </tr>
                  </thead>
                  <tbody className="bg-white divide-y divide-gray-200">
                    {formData.items.map((item, index) => (
                      <tr key={index}>
                        <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                          {item.product_name}
                        </td>
                        <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                          {item.quantity}
                        </td>
                        <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                          ${item.unit_price.toFixed(2)}
                        </td>
                        <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                          ${item.total_price.toFixed(2)}
                        </td>
                        <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                          <button
                            type="button"
                            onClick={() => handleRemoveItem(index)}
                            className="text-red-600 hover:text-red-900"
                          >
                            Eliminar
                          </button>
                        </td>
                      </tr>
                    ))}
                    <tr className="bg-gray-50">
                      <td colSpan={3} className="px-6 py-4 text-right font-medium">
                        Total:
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap text-lg font-bold text-gray-900">
                        ${formData.total_amount.toFixed(2)}
                      </td>
                      <td></td>
                    </tr>
                  </tbody>
                </table>
              </div>
            )}

            {errors.items && (
              <p className="mt-2 text-sm text-red-600 flex items-center">
                <AlertTriangle className="w-4 h-4 mr-1" />
                {errors.items}
              </p>
            )}
          </div>

          {/* Quote Details */}
          <div className="grid grid-cols-2 gap-6">
            <div>
              <label className="block text-sm font-medium text-gray-700">
                Válido Hasta
              </label>
              <div className="mt-1">
                <DatePicker
                  selected={formData.valid_until}
                  onChange={(date: Date) => setFormData(prev => ({ ...prev, valid_until: date }))}
                  className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
                  dateFormat="dd/MM/yyyy"
                  locale={es}
                  minDate={new Date()}
                />
              </div>
              {errors.valid_until && (
                <p className="mt-2 text-sm text-red-600 flex items-center">
                  <AlertTriangle className="w-4 h-4 mr-1" />
                  {errors.valid_until}
                </p>
              )}
            </div>
          </div>

          {/* Terms and Conditions */}
          <div>
            <label className="block text-sm font-medium text-gray-700">
              Términos y Condiciones
            </label>
            <textarea
              value={formData.terms}
              onChange={(e) => setFormData(prev => ({ ...prev, terms: e.target.value }))}
              rows={4}
              className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
              placeholder="Ingrese los términos y condiciones de la cotización..."
            />
          </div>

          {/* Notes */}
          <div>
            <label className="block text-sm font-medium text-gray-700">
              Notas Adicionales
            </label>
            <textarea
              value={formData.notes}
              onChange={(e) => setFormData(prev => ({ ...prev, notes: e.target.value }))}
              rows={3}
              className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
              placeholder="Notas adicionales para el cliente..."
            />
          </div>

          {/* Action Buttons */}
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
              {isSubmitting ? 'Guardando...' : 'Guardar como Borrador'}
            </button>
            <button
              type="button"
              onClick={(e) => handleSubmit(e, false)}
              disabled={isSubmitting}
              className="px-4 py-2 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-green-600 hover:bg-green-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-green-500 disabled:opacity-50"
            >
              {isSubmitting ? 'Enviando...' : 'Enviar Cotización'}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
}