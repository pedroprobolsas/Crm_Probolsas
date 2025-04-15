import { useState } from 'react';
import { Search, Package, Plus, X } from 'lucide-react';
import { useProducts } from '../../lib/hooks/useProducts';
import type { Product } from '../../lib/types';

interface ProductSelectorProps {
  onAddItem: (product: Product, quantity: number, priceLevel: 'regular' | 'price_2' | 'price_3' | 'price_4') => void;
}

export function ProductSelector({ onAddItem }: ProductSelectorProps) {
  const [searchTerm, setSearchTerm] = useState('');
  const [selectedProduct, setSelectedProduct] = useState<Product | null>(null);
  const [quantity, setQuantity] = useState<number>(1);
  const [priceLevel, setPriceLevel] = useState<'regular' | 'price_2' | 'price_3' | 'price_4'>('regular');

  const { products, isLoading } = useProducts();

  const filteredProducts = products.filter(product => 
    product.status === 'active' && (
      product.name.toLowerCase().includes(searchTerm.toLowerCase()) ||
      product.sku.toLowerCase().includes(searchTerm.toLowerCase())
    )
  );

  const handleAddProduct = () => {
    if (selectedProduct && quantity > 0) {
      onAddItem(selectedProduct, quantity, priceLevel);
      setSelectedProduct(null);
      setQuantity(1);
      setPriceLevel('regular');
      setSearchTerm('');
    }
  };

  const getPriceLabel = (level: 'regular' | 'price_2' | 'price_3' | 'price_4') => {
    switch (level) {
      case 'regular': return 'Precio Base';
      case 'price_2': return 'Precio 2';
      case 'price_3': return 'Precio 3';
      case 'price_4': return 'Precio 4';
    }
  };

  return (
    <div className="space-y-4">
      {/* Product Search */}
      <div className="relative">
        <input
          type="text"
          placeholder="Buscar productos por nombre o SKU..."
          value={searchTerm}
          onChange={(e) => setSearchTerm(e.target.value)}
          className="w-full pl-10 pr-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
        />
        <Search className="w-5 h-5 text-gray-400 absolute left-3 top-2.5" />
      </div>

      {/* Product List */}
      {searchTerm && (
        <div className="border rounded-lg divide-y divide-gray-200 max-h-60 overflow-y-auto">
          {isLoading ? (
            <div className="p-4 text-center text-gray-500">
              Cargando productos...
            </div>
          ) : filteredProducts.length === 0 ? (
            <div className="p-4 text-center text-gray-500">
              No se encontraron productos
            </div>
          ) : (
            filteredProducts.map((product) => (
              <button
                key={product.id}
                onClick={() => setSelectedProduct(product)}
                className={`w-full p-4 text-left hover:bg-gray-50 flex items-center justify-between ${
                  selectedProduct?.id === product.id ? 'bg-blue-50' : ''
                }`}
              >
                <div className="flex items-center">
                  <Package className="w-5 h-5 text-gray-400 mr-3" />
                  <div>
                    <p className="font-medium text-gray-900">{product.name}</p>
                    <p className="text-sm text-gray-500">SKU: {product.sku}</p>
                  </div>
                </div>
                <div className="text-sm text-gray-900">
                  ${product.regular_price.toFixed(2)}
                </div>
              </button>
            ))
          )}
        </div>
      )}

      {/* Selected Product Details */}
      {selectedProduct && (
        <div className="border rounded-lg p-4 bg-gray-50">
          <div className="flex justify-between items-start mb-4">
            <div>
              <h4 className="font-medium text-gray-900">{selectedProduct.name}</h4>
              <p className="text-sm text-gray-500">SKU: {selectedProduct.sku}</p>
            </div>
            <button
              type="button"
              onClick={() => setSelectedProduct(null)}
              className="text-gray-400 hover:text-gray-500"
            >
              <span className="sr-only">Cerrar</span>
              <X className="w-5 h-5" />
            </button>
          </div>

          <div className="grid grid-cols-3 gap-4">
            <div>
              <label className="block text-sm font-medium text-gray-700">
                Cantidad
              </label>
              <input
                type="number"
                min="1"
                value={quantity}
                onChange={(e) => setQuantity(Math.max(1, parseInt(e.target.value) || 0))}
                className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
              />
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700">
                Lista de Precios
              </label>
              <select
                value={priceLevel}
                onChange={(e) => setPriceLevel(e.target.value as typeof priceLevel)}
                className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
              >
                <option value="regular">Precio Base (${selectedProduct.regular_price.toFixed(2)})</option>
                <option value="price_2">Precio 2 (${selectedProduct.price_2.toFixed(2)})</option>
                <option value="price_3">Precio 3 (${selectedProduct.price_3.toFixed(2)})</option>
                <option value="price_4">Precio 4 (${selectedProduct.price_4.toFixed(2)})</option>
              </select>
            </div>

            <div className="flex items-end">
              <button
                type="button"
                onClick={handleAddProduct}
                className="w-full flex items-center justify-center px-4 py-2 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-blue-600 hover:bg-blue-700"
              >
                <Plus className="w-4 h-4 mr-2" />
                Agregar
              </button>
            </div>
          </div>

          <div className="mt-4 text-sm text-gray-500">
            Subtotal: ${(quantity * selectedProduct[priceLevel]).toFixed(2)}
          </div>
        </div>
      )}
    </div>
  );
}
