import React, { useState, useEffect, useCallback } from 'react';
import { Edit2, Save, AlertTriangle, Clock, History } from 'lucide-react';
import type { ProductPrice } from '../../lib/types/product';
import { toast } from 'sonner';

interface PriceGridProps {
  products: ProductPrice[];
  onSave: (product: ProductPrice) => Promise<void>;
  isLoading?: boolean;
}

export function PriceGrid({ products, onSave, isLoading }: PriceGridProps) {
  const [editingCell, setEditingCell] = useState<{
    sku: string;
    field: keyof ProductPrice;
  } | null>(null);
  const [editValue, setEditValue] = useState<string>('');
  const [validationErrors, setValidationErrors] = useState<Record<string, string>>({});

  const validatePrice = useCallback((product: ProductPrice, field: string, value: number) => {
    const errors: Record<string, string> = {};
    
    // Validate price hierarchy
    if (field === 'regular_price' && value <= product.price_2) {
      errors[`${product.sku}_regular_price`] = 'Precio base debe ser mayor que Precio 2';
    }
    if (field === 'price_2') {
      if (value >= product.regular_price) {
        errors[`${product.sku}_price_2`] = 'Precio 2 debe ser menor que Precio base';
      }
      if (value <= product.price_3) {
        errors[`${product.sku}_price_2`] = 'Precio 2 debe ser mayor que Precio 3';
      }
    }
    if (field === 'price_3') {
      if (value >= product.price_2) {
        errors[`${product.sku}_price_3`] = 'Precio 3 debe ser menor que Precio 2';
      }
      if (value <= product.price_4) {
        errors[`${product.sku}_price_3`] = 'Precio 3 debe ser mayor que Precio 4';
      }
    }
    if (field === 'price_4' && value >= product.price_3) {
      errors[`${product.sku}_price_4`] = 'Precio 4 debe ser menor que Precio 3';
    }

    return errors;
  }, []);

  const handleEdit = (product: ProductPrice, field: keyof ProductPrice) => {
    setEditingCell({ sku: product.sku, field });
    setEditValue(product[field].toString());
  };

  const handleSave = async (product: ProductPrice) => {
    if (!editingCell) return;

    const newValue = parseFloat(editValue);
    if (isNaN(newValue)) {
      toast.error('Valor inválido');
      return;
    }

    const errors = validatePrice(product, editingCell.field, newValue);
    if (Object.keys(errors).length > 0) {
      setValidationErrors(errors);
      return;
    }

    try {
      await onSave({
        ...product,
        [editingCell.field]: newValue
      });
      setEditingCell(null);
      setEditValue('');
      setValidationErrors({});
      toast.success('Precio actualizado');
    } catch (error) {
      toast.error('Error al actualizar el precio');
    }
  };

  const handleKeyDown = (e: React.KeyboardEvent, product: ProductPrice) => {
    if (e.key === 'Enter') {
      handleSave(product);
    }
    if (e.key === 'Escape') {
      setEditingCell(null);
      setEditValue('');
    }
  };

  if (isLoading) {
    return (
      <div className="flex items-center justify-center py-8">
        <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600"></div>
      </div>
    );
  }

  return (
    <div className="overflow-x-auto">
      <table className="min-w-full divide-y divide-gray-200">
        <thead className="bg-gray-50">
          <tr>
            <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
              SKU
            </th>
            <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
              Nombre
            </th>
            <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
              Precio Base
            </th>
            <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
              Precio 2
            </th>
            <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
              Precio 3
            </th>
            <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
              Precio 4
            </th>
          </tr>
        </thead>
        <tbody className="bg-white divide-y divide-gray-200">
          {products.map((product) => (
            <tr key={product.sku} className="hover:bg-gray-50">
              <td className="px-6 py-4 whitespace-nowrap text-sm font-medium text-gray-900">
                {product.sku}
              </td>
              <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                {product.name}
              </td>
              {['regular_price', 'price_2', 'price_3', 'price_4'].map((field) => (
                <td key={field} className="px-6 py-4 whitespace-nowrap">
                  {editingCell?.sku === product.sku && editingCell?.field === field ? (
                    <div className="flex items-center space-x-2">
                      <input
                        type="number"
                        value={editValue}
                        onChange={(e) => setEditValue(e.target.value)}
                        onKeyDown={(e) => handleKeyDown(e, product)}
                        className="block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500 sm:text-sm"
                        step="0.01"
                        min="0"
                        autoFocus
                      />
                      <button
                        onClick={() => handleSave(product)}
                        className="p-1 text-green-600 hover:text-green-800"
                      >
                        <Save className="w-4 h-4" />
                      </button>
                    </div>
                  ) : (
                    <div className="flex items-center justify-between group">
                      <span className="text-sm text-gray-900">
                        ${product[field as keyof ProductPrice].toFixed(2)}
                      </span>
                      <button
                        onClick={() => handleEdit(product, field as keyof ProductPrice)}
                        className="p-1 text-gray-400 hover:text-gray-600 opacity-0 group-hover:opacity-100"
                      >
                        <Edit2 className="w-4 h-4" />
                      </button>
                    </div>
                  )}
                  {validationErrors[`${product.sku}_${field}`] && (
                    <p className="mt-1 text-xs text-red-600 flex items-center">
                      <AlertTriangle className="w-3 h-3 mr-1" />
                      {validationErrors[`${product.sku}_${field}`]}
                    </p>
                  )}
                </td>
              ))}
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}