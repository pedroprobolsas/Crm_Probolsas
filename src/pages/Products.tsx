import React, { useState, useEffect, useMemo } from 'react';
import { Search, Plus, Filter, Package, Tag, Clock, Check, X } from 'lucide-react';
import { supabase } from '../lib/supabase';
import { format } from 'date-fns';
import { ProductEditModal } from '../components/products/ProductEditModal';
import { ProductCreateModal } from '../components/products/ProductCreateModal';
import { toast } from 'sonner';

interface Product {
  id: string;
  sku: string;
  name: string;
  regular_price: number;
  price_2: number;
  price_3: number;
  price_4: number;
  unit_type: string;
  woo_status: string;
  existencia: number;
  costo: number;
  margen: number;
  status: 'active' | 'inactive';
}

export function Products() {
  const [products, setProducts] = useState<Product[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [selectedProduct, setSelectedProduct] = useState<Product | null>(null);
  const [showCreateModal, setShowCreateModal] = useState(false);
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [statusUpdating, setStatusUpdating] = useState<string | null>(null);
  const [searchTerm, setSearchTerm] = useState('');

  useEffect(() => {
    fetchProducts();
  }, []);

  const fetchProducts = async () => {
    try {
      const { data, error } = await supabase
        .from('products')
        .select('*')
        .order('created_at', { ascending: false });

      if (error) throw error;

      setProducts(data || []);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Error al cargar productos');
      console.error('Error fetching products:', err);
    } finally {
      setLoading(false);
    }
  };

  const filteredProducts = useMemo(() => {
    if (!searchTerm.trim()) return products;

    const searchLower = searchTerm.toLowerCase().trim();
    return products.filter(product => 
      product.name.toLowerCase().includes(searchLower) ||
      product.sku.toLowerCase().includes(searchLower)
    );
  }, [products, searchTerm]);

  const handleCreateProduct = async (newProduct: Omit<Product, 'id' | 'woo_status' | 'status'>) => {
    setIsSubmitting(true);
    try {
      const { error } = await supabase
        .from('products')
        .insert({
          ...newProduct,
          woo_status: 'draft',
          status: 'active'
        });

      if (error) throw error;

      toast.success('Producto creado exitosamente');
      setShowCreateModal(false);
      fetchProducts();
    } catch (err) {
      console.error('Error creating product:', err);
      toast.error('Error al crear el producto');
    } finally {
      setIsSubmitting(false);
    }
  };

  const handleEditProduct = async (product: Product) => {
    setIsSubmitting(true);
    try {
      const { error } = await supabase
        .from('products')
        .update({
          sku: product.sku,
          name: product.name,
          existencia: product.existencia,
          regular_price: product.regular_price,
          price_2: product.price_2,
          price_3: product.price_3,
          price_4: product.price_4,
          unit_type: product.unit_type,
          costo: product.costo,
          margen: product.margen
        })
        .eq('id', product.id);

      if (error) throw error;

      toast.success('Producto actualizado exitosamente');
      setSelectedProduct(null);
      fetchProducts();
    } catch (err) {
      console.error('Error updating product:', err);
      toast.error('Error al actualizar el producto');
    } finally {
      setIsSubmitting(false);
    }
  };

  const handleToggleStatus = async (productId: string, currentStatus: 'active' | 'inactive') => {
    setStatusUpdating(productId);
    try {
      const newStatus = currentStatus === 'active' ? 'inactive' : 'active';
      const { error } = await supabase
        .from('products')
        .update({ status: newStatus })
        .eq('id', productId);

      if (error) throw error;

      // Optimistic update
      setProducts(prevProducts => 
        prevProducts.map(p => 
          p.id === productId ? { ...p, status: newStatus } : p
        )
      );

      toast.success(`Producto ${newStatus === 'active' ? 'activado' : 'desactivado'} exitosamente`);
    } catch (err) {
      console.error('Error toggling status:', err);
      toast.error('Error al cambiar el estado del producto');
      // Revert optimistic update on error
      await fetchProducts();
    } finally {
      setStatusUpdating(null);
    }
  };

  const getStockStatusColor = (existencia: number) => {
    if (existencia === 0) return 'bg-red-100 text-red-800';
    if (existencia <= 10) return 'bg-yellow-100 text-yellow-800';
    return 'bg-green-100 text-green-800';
  };

  const getStockStatus = (existencia: number) => {
    if (existencia === 0) return 'Sin existencias';
    if (existencia <= 10) return 'Bajo inventario';
    return 'En existencia';
  };

  return (
    <div className="p-8">
      <div className="flex justify-between items-center mb-6 bg-white rounded-xl shadow-sm p-6 border border-gray-100">
        <h1 className="text-2xl font-bold text-gray-900">Productos</h1>
        <button 
          onClick={() => setShowCreateModal(true)}
          className="bg-blue-600 text-white px-5 py-2.5 rounded-lg flex items-center hover:bg-blue-700 transition-all duration-200 transform hover:scale-105 shadow-md"
        >
          <Plus className="w-5 h-5 mr-2" />
          Agregar Producto
        </button>
      </div>

      <div className="bg-white rounded-xl shadow-sm border border-gray-100 overflow-hidden">
        <div className="p-5 border-b border-gray-100">
          <div className="flex flex-col sm:flex-row gap-4">
            <div className="flex-1 relative">
              <input
                type="text"
                placeholder="Buscar por nombre o SKU..."
                value={searchTerm}
                onChange={(e) => setSearchTerm(e.target.value)}
                className="w-full pl-10 pr-4 py-2.5 border border-gray-200 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500 transition-colors"
                autoComplete="off"
                spellCheck="false"
              />
              <Search className="w-5 h-5 text-gray-400 absolute left-3 top-3" />
              {searchTerm && (
                <button
                  onClick={() => setSearchTerm('')}
                  className="absolute right-3 top-1/2 transform -translate-y-1/2 text-gray-400 hover:text-gray-600"
                >
                  <X className="w-5 h-5" />
                </button>
              )}
            </div>
            <button className="flex items-center px-4 py-2.5 text-gray-700 border border-gray-200 rounded-lg hover:bg-gray-50 transition-colors">
              <Filter className="w-5 h-5 mr-2" />
              Filtros
            </button>
          </div>
        </div>

        <div className="overflow-x-auto">
          <table className="w-full">
            <thead className="bg-gray-50">
              <tr>
                <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Nombre</th>
                <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">SKU</th>
                <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Precio</th>
                <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Unidad</th>
                <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Estado</th>
                <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Existencia</th>
                <th className="px-4 py-3 text-right text-xs font-medium text-gray-500 uppercase tracking-wider">Acciones</th>
              </tr>
            </thead>
            <tbody className="bg-white divide-y divide-gray-200">
              {loading ? (
                <tr>
                  <td className="px-4 py-8 whitespace-nowrap text-gray-600" colSpan={7}>
                    <div className="flex items-center justify-center">
                      <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600"></div>
                    </div>
                  </td>
                </tr>
              ) : error ? (
                <tr>
                  <td className="px-4 py-8 whitespace-nowrap text-red-600" colSpan={7}>
                    <div className="bg-red-50 p-4 rounded-lg text-center">
                      <p className="font-medium">{error}</p>
                    </div>
                  </td>
                </tr>
              ) : filteredProducts.length === 0 ? (
                <tr>
                  <td className="px-4 py-8 whitespace-nowrap text-gray-600" colSpan={7}>
                    <div className="text-center">
                      <p className="text-gray-500 font-medium">
                        {searchTerm ? 'No se encontraron productos que coincidan con la búsqueda' : 'No hay productos registrados'}
                      </p>
                      <p className="text-gray-400 text-sm mt-1">
                        {searchTerm ? 'Intenta con otros términos de búsqueda' : 'Agrega un nuevo producto para comenzar'}
                      </p>
                    </div>
                  </td>
                </tr>
              ) : (
                filteredProducts.map((product) => (
                  <tr key={product.id} className="hover:bg-gray-50">
                    <td className="px-4 py-4 max-w-[200px]">
                      <div className="flex items-center">
                        <Package className="w-8 h-8 text-gray-400 mr-3 flex-shrink-0" />
                        <div className="min-w-0">
                          <div className="text-sm font-medium text-gray-900 truncate" title={product.name}>{product.name}</div>
                        </div>
                      </div>
                    </td>
                    <td className="px-4 py-4 max-w-[120px]">
                      <div className="text-sm text-gray-500 truncate" title={product.sku}>
                        {product.sku}
                      </div>
                    </td>
                    <td className="px-4 py-4 whitespace-nowrap text-sm text-gray-900">
                      ${product.regular_price.toFixed(2)}
                    </td>
                    <td className="px-4 py-4 max-w-[100px]">
                      <div className="text-sm text-gray-500 truncate" title={product.unit_type}>
                        {product.unit_type}
                      </div>
                    </td>
                    <td className="px-4 py-4 whitespace-nowrap">
                      <button
                        onClick={() => handleToggleStatus(product.id, product.status)}
                        disabled={statusUpdating === product.id}
                        className={`inline-flex items-center px-2.5 py-1 rounded-full text-xs font-medium transition-colors ${
                          product.status === 'active'
                            ? 'bg-green-100 text-green-800 hover:bg-green-200'
                            : 'bg-red-100 text-red-800 hover:bg-red-200'
                        }`}
                      >
                        {statusUpdating === product.id ? (
                          <div className="flex items-center">
                            <div className="animate-spin rounded-full h-4 w-4 border-b-2 border-current"></div>
                          </div>
                        ) : (
                          <>
                            {product.status === 'active' ? (
                              <Check className="w-4 h-4 mr-1" />
                            ) : (
                              <X className="w-4 h-4 mr-1" />
                            )}
                            {product.status === 'active' ? 'Activo' : 'Inactivo'}
                          </>
                        )}
                      </button>
                    </td>
                    <td className="px-4 py-4 whitespace-nowrap">
                      <div className="flex items-center space-x-2">
                        <span className={`px-2 py-1 text-xs font-medium rounded-full ${getStockStatusColor(product.existencia)}`}>
                          {product.existencia}
                        </span>
                        <span className="text-xs text-gray-500 hidden sm:inline">
                          {getStockStatus(product.existencia)}
                        </span>
                      </div>
                    </td>
                    <td className="px-4 py-4 whitespace-nowrap text-right text-sm font-medium">
                      <button 
                        onClick={() => setSelectedProduct(product)}
                        className="text-blue-600 hover:text-blue-900"
                      >
                        Editar
                      </button>
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
      </div>

      <ProductEditModal
        product={selectedProduct}
        isOpen={!!selectedProduct}
        onClose={() => setSelectedProduct(null)}
        onSave={handleEditProduct}
        isSubmitting={isSubmitting}
      />

      <ProductCreateModal
        isOpen={showCreateModal}
        onClose={() => setShowCreateModal(false)}
        onSave={handleCreateProduct}
        isSubmitting={isSubmitting}
      />
    </div>
  );
}
