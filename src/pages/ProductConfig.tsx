import React, { useState } from 'react';
import { Tabs, TabsList, TabsTrigger, TabsContent } from '../components/ui/tabs';
import { WooCredentialsForm } from '../components/products/WooCredentialsForm';
import { UnitTypeConfig } from '../components/products/UnitTypeConfig';
import { PriceRangeConfig } from '../components/products/PriceRangeConfig';
import { ProductList } from '../components/products/ProductList';
import { ProductEditor } from '../components/products/ProductEditor';
import { ConnectionStatus } from '../components/products/ConnectionStatus';
import { useProductSettings } from '../lib/hooks/useProductSettings';
import { useWooProducts } from '../lib/hooks/useWooProducts';
import { useSyncLogs } from '../lib/hooks/useSyncLogs';
import type { ConnectionStatus as ConnectionStatusType } from '../lib/types/product';
import { toast } from 'sonner';

export function ProductConfig() {
  const [connectionStatus, setConnectionStatus] = useState<ConnectionStatusType>({
    state: 'disconnected',
    lastCheck: null
  });
  const [selectedProducts, setSelectedProducts] = useState<string[]>([]);
  const [activeTab, setActiveTab] = useState('credentials');

  const {
    settings,
    isLoading: isLoadingSettings,
    updateSetting,
    testConnection,
    isTesting,
    testError
  } = useProductSettings();

  const {
    products,
    isLoading: isLoadingProducts,
    syncProducts,
    isSyncing
  } = useWooProducts();

  const {
    logs,
    isLoading: isLoadingLogs,
    startSync,
    stopSync,
    isStarting,
    isStopping
  } = useSyncLogs();

  const handleTestConnection = async () => {
    console.log('Iniciando prueba de conexión...');
    
    try {
      // Get credentials from settings
      const apiUrl = settings.find(s => s.setting_key === 'api_url')?.setting_value;
      const consumerKey = settings.find(s => s.setting_key === 'consumer_key')?.setting_value;
      const consumerSecret = settings.find(s => s.setting_key === 'consumer_secret')?.setting_value;

      // Log credentials (without sensitive data)
      console.log('Credenciales configuradas:', {
        url: apiUrl,
        hasConsumerKey: !!consumerKey,
        hasConsumerSecret: !!consumerSecret
      });

      // Validate credentials
      if (!apiUrl || !consumerKey || !consumerSecret) {
        throw new Error('Faltan credenciales de WooCommerce');
      }

      // Test connection
      const result = await testConnection({
        api_url: apiUrl,
        consumer_key: consumerKey,
        consumer_secret: consumerSecret
      });

      // Log response
      console.log('Respuesta de prueba de conexión:', result);

      if (!result.success) {
        throw new Error(result.error || 'Error al probar la conexión');
      }

      // Update connection status
      setConnectionStatus({
        state: 'connected',
        lastCheck: new Date().toISOString(),
        productCount: result.productCount,
        storeInfo: result.storeInfo
      });

      toast.success('Conexión exitosa con WooCommerce');

      // Switch to products tab on success
      setActiveTab('products');

    } catch (error) {
      console.error('Error en prueba de conexión:', error);
      
      // Update connection status with error
      setConnectionStatus({
        state: 'error',
        lastCheck: new Date().toISOString(),
        error: error instanceof Error ? error.message : 'Error desconocido al probar la conexión'
      });

      // Show error toast
      toast.error(error instanceof Error ? error.message : 'Error al probar la conexión');
    }
  };

  const handleSettingUpdate = async (type: string, key: string, value: string) => {
    try {
      await updateSetting({ setting_type: type, setting_key: key, setting_value: value });
      toast.success('Configuración actualizada');
    } catch (error) {
      console.error('Error updating setting:', error);
      toast.error('Error al actualizar la configuración');
    }
  };

  const handleSelectProduct = (productId: string) => {
    setSelectedProducts(prev => {
      if (prev.includes(productId)) {
        return prev.filter(id => id !== productId);
      }
      return [...prev, productId];
    });
  };

  const handleSelectAll = () => {
    if (selectedProducts.length === products.length) {
      setSelectedProducts([]);
    } else {
      setSelectedProducts(products.map(p => p.id));
    }
  };

  const handleSync = async () => {
    if (selectedProducts.length === 0) {
      toast.error('Selecciona al menos un producto para sincronizar');
      return;
    }

    try {
      await syncProducts(selectedProducts);
      toast.success('Productos sincronizados exitosamente');
      setSelectedProducts([]);
    } catch (error) {
      console.error('Sync error:', error);
      toast.error('Error al sincronizar productos');
    }
  };

  return (
    <div className="p-8">
      <div className="max-w-7xl mx-auto">
        <h1 className="text-2xl font-bold text-gray-900 mb-6">Configuración de Productos</h1>

        <Tabs value={activeTab} onValueChange={setActiveTab} className="space-y-6">
          <TabsList>
            <TabsTrigger value="credentials">Credenciales</TabsTrigger>
            <TabsTrigger value="products">Lista Productos</TabsTrigger>
            <TabsTrigger value="edit">Edición de Productos</TabsTrigger>
            <TabsTrigger value="sync">Sincronización</TabsTrigger>
          </TabsList>

          <TabsContent value="credentials">
            <ConnectionStatus
              status={connectionStatus}
              onTest={handleTestConnection}
              isLoading={isTesting}
              error={testError instanceof Error ? testError.message : undefined}
            />

            <div className="bg-white rounded-lg shadow p-6">
              <h2 className="text-lg font-semibold text-gray-900 mb-4">Configuración de WooCommerce</h2>
              <WooCredentialsForm
                settings={settings}
                onUpdate={handleSettingUpdate}
                isLoading={isLoadingSettings}
              />
            </div>
          </TabsContent>

          <TabsContent value="products">
            <ProductList
              products={products}
              selectedProducts={selectedProducts}
              onSelectProduct={handleSelectProduct}
              onSelectAll={handleSelectAll}
              isLoading={isLoadingProducts}
            />
          </TabsContent>

          <TabsContent value="edit" id="edit-tab-content">
            <div className="space-y-6" id="edit-tab-wrapper">
              <UnitTypeConfig
                id="unit-type-config"
                settings={settings}
                onUpdate={handleSettingUpdate}
                isLoading={isLoadingSettings}
              />
              <PriceRangeConfig
                id="price-range-config"
                settings={settings}
                onUpdate={handleSettingUpdate}
                isLoading={isLoadingSettings}
              />
              <ProductEditor
                id="product-editor"
                products={products}
                onSave={async (product) => {
                  console.log('Intentando guardar producto:', product);
                  try {
                    await syncProducts([product.id]);
                    toast.success('Producto actualizado');
                  } catch (error) {
                    console.error('Error al guardar:', error);
                    toast.error('Error al actualizar el producto');
                  }
                }}
                isLoading={isLoadingProducts || isSyncing}
              />
            </div>
          </TabsContent>

          <TabsContent value="sync">
            <div className="bg-white rounded-lg shadow p-6">
              <div className="flex items-center justify-between mb-6">
                <h2 className="text-lg font-semibold text-gray-900">Sincronización con WooCommerce</h2>
                <div className="flex space-x-4">
                  <button
                    onClick={handleSync}
                    disabled={selectedProducts.length === 0 || isSyncing}
                    className="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 disabled:opacity-50"
                  >
                    {isSyncing ? 'Sincronizando...' : 'Sincronizar Seleccionados'}
                  </button>
                </div>
              </div>

              {isLoadingLogs ? (
                <div className="flex items-center justify-center py-8">
                  <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600"></div>
                </div>
              ) : (
                <div className="overflow-x-auto">
                  <table className="min-w-full divide-y divide-gray-200">
                    <thead className="bg-gray-50">
                      <tr>
                        <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                          Fecha
                        </th>
                        <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                          Tipo
                        </th>
                        <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                          Estado
                        </th>
                        <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                          Registros
                        </th>
                        <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                          Errores
                        </th>
                      </tr>
                    </thead>
                    <tbody className="bg-white divide-y divide-gray-200">
                      {logs.map((log) => (
                        <tr key={log.id}>
                          <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                            {new Date(log.created_at).toLocaleString()}
                          </td>
                          <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                            {log.sync_type}
                          </td>
                          <td className="px-6 py-4 whitespace-nowrap">
                            <span className={`px-2 py-1 text-xs font-medium rounded-full ${
                              log.status === 'completed' ? 'bg-green-100 text-green-800' :
                              log.status === 'failed' ? 'bg-red-100 text-red-800' :
                              log.status === 'running' ? 'bg-yellow-100 text-yellow-800' :
                              'bg-gray-100 text-gray-800'
                            }`}>
                              {log.status}
                            </span>
                          </td>
                          <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                            {log.records_processed}
                          </td>
                          <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                            {log.errors?.length || 0}
                          </td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>
              )}
            </div>
          </TabsContent>
        </Tabs>
      </div>
    </div>
  );
}