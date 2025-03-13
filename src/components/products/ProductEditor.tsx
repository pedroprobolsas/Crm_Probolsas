import React, { useState } from 'react';
import { Search, Package, AlertTriangle, Edit2, Save, Loader2 } from 'lucide-react';
import { UnitTypeConfig } from './UnitTypeConfig';
import { PriceRangeConfig } from './PriceRangeConfig';
import { PriceGrid } from './PriceGrid';
import type { ProductPrice } from '../../lib/types/product';
import { toast } from 'sonner';

interface ProductEditorProps {
  products: ProductPrice[];
  onSave: (product: ProductPrice) => Promise<void>;
  isLoading?: boolean;
}

export function ProductEditor({ products, onSave, isLoading }: ProductEditorProps) {
  const [searchTerm, setSearchTerm] = useState('');
  const [selectedProduct, setSelectedProduct] = useState<ProductPrice | null>(null);
  const [isSaving, setIsSaving] = useState(false);

  const filteredProducts = products.filter(product => 
    product.name.toLowerCase().includes(searchTerm.toLowerCase()) ||
    product.sku.toLowerCase().includes(searchTerm.toLowerCase())
  );

  const handleSelectProduct = (product: ProductPrice) => {
    setSelectedProduct(product);
  };

  const handleSaveChanges = async (updatedProduct: ProductPrice) => {
    try {
      setIsSaving(true);
      await onSave(updatedProduct);
      toast.success('Producto actualizado exitosamente');
    } catch (error) {
      console.error('Error saving product:', error);
      toast.error('Error al actualizar el producto');
    } finally {
      setIsSaving(false);
    }
  };

  if (isLoading) {
    return (
      <div className="flex items-center justify-center py-8">
        <Loader2 className="w-8 h-8 animate-spin text-blue-600" />
      </div>
    );
  }

  return (
    <div className="space-y-6">
      {/* Search Section - Always at the top */}
      <div className="bg-white rounded-lg shadow p-6">
        <h2 className="text-lg font-semibold text-gray-900 mb-4">Buscar Producto</h2>
        <div className="relative">
          <input
            type="text"
            placeholder="Buscar por nombre o SKU..."
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
            className="w-full pl-10 pr-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
          />
          <Search className="w-5 h-5 text-gray-400 absolute left-3 top-2.5" />
        </div>
      </div>

      {/* Results Section */}
      {!selectedProduct && (
        <div className="bg-white rounded-lg shadow overflow-hidden">
          <div className="p-4 border-b border-gray-200">
            <h3 className="text-lg font-semibold text-gray-900">Resultados de Búsqueda</h3>
          </div>

          {filteredProducts.length === 0 ? (
            <div className="p-8 text-center">
              <AlertTriangle className="w-8 h-8 text-yellow-500 mx-auto mb-2" />
              <p className="text-gray-500">No se encontraron productos</p>
            </div>
          ) : (
            <div className="divide-y divide-gray-200">
              {filteredProducts.map((product) => (
                <div
                  key={product.id}
                  className="p-4 hover:bg-gray-50 cursor-pointer flex items-center justify-between"
                  onClick={() => handleSelectProduct(product)}
                >
                  <div className="flex items-center">
                    <Package className="w-8 h-8 text-gray-400" />
                    <div className="ml-3">
                      <p className="text-sm font-medium text-gray-900">{product.name}</p>
                      <p className="text-sm text-gray-500">SKU: {product.sku}</p>
                    </div>
                  </div>
                  <button className="p-2 text-blue-600 hover:text-blue-800">
                    <Edit2 className="w-5 h-5" />
                  </button>
                </div>
              ))}
            </div>
          )}
        </div>
      )}

      {/* Edit Form */}
      {selectedProduct && (
        <div className="space-y-6">
          {/* Product Header */}
          <div className="bg-white rounded-lg shadow p-6">
            <div className="flex items-center justify-between">
              <div className="flex items-center">
                <Package className="w-8 h-8 text-gray-400" />
                <div className="ml-3">
                  <h3 className="text-lg font-semibold text-gray-900">{selectedProduct.name}</h3>
                  <p className="text-sm text-gray-500">SKU: {selectedProduct.sku}</p>
                </div>
              </div>
              <button
                onClick={() => setSelectedProduct(null)}
                className="text-gray-400 hover:text-gray-600"
              >
                <Edit2 className="w-5 h-5" />
              </button>
            </div>
          </div>

          {/* Price Grid */}
          <div className="bg-white rounded-lg shadow p-6">
            <h3 className="text-lg font-semibold text-gray-900 mb-4">Precios Escalonados</h3>
            <PriceGrid
              products={[selectedProduct]}
              onSave={handleSaveChanges}
              isLoading={isSaving}
            />
          </div>

          {/* Save Button - Always visible at bottom */}
          <div className="fixed bottom-0 left-0 right-0 bg-white border-t border-gray-200 p-4 shadow-lg">
            <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
              <div className="flex justify-end">
                <button
                  onClick={() => handleSaveChanges(selectedProduct)}
                  disabled={isSaving}
                  className="inline-flex items-center px-6 py-3 border border-transparent rounded-md shadow-sm text-base font-medium text-white bg-blue-600 hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 disabled:opacity-50"
                >
                  {isSaving ? (
                    <>
                      <Loader2 className="w-5 h-5 mr-2 animate-spin" />
                      Guardando...
                    </>
                  ) : (
                    <>
                      <Save className="w-5 h-5 mr-2" />
                      Guardar Cambios
                    </>
                  )}
                </button>
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}