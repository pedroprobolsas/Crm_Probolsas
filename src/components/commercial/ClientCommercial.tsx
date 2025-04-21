import React, { useState, useEffect } from 'react';
import { BarChart2, TrendingUp, DollarSign, ShoppingCart, Tag, Calendar, AlertTriangle, UserCircle } from 'lucide-react';
import { supabase } from '../../lib/supabase';
import { toast } from 'sonner';
import { useAgents } from '../../lib/hooks/useAgents';

interface CommercialData {
  id: string;
  client_id: string;
  sales_channel: string;
  payment_terms: string;
  credit_limit?: number;
  current_balance?: number;
  preferred_shipping_method?: string;
  discount_tier?: string;
  customer_since?: string;
  last_purchase_date?: string;
  total_purchases?: number;
  average_order_value?: number;
  preferred_products?: string[];
  notes?: string;
  created_at: string;
  updated_at: string;
}

interface SalesData {
  month: string;
  amount: number;
}

interface ClientCommercialProps {
  clientId: string;
  isEditing: boolean;
}

export function ClientCommercial({ clientId, isEditing }: ClientCommercialProps) {
  const { agents } = useAgents();
  const [commercialData, setCommercialData] = useState<CommercialData | null>(null);
  const [loading, setLoading] = useState(true);
  const [salesData, setSalesData] = useState<SalesData[]>([]);
  const [formData, setFormData] = useState<Partial<CommercialData>>({
    client_id: clientId,
    sales_channel: '',
    payment_terms: '',
    preferred_shipping_method: '',
    discount_tier: '',
    preferred_products: []
  });
  const [errors, setErrors] = useState<Record<string, string>>({});
  const [clientData, setClientData] = useState<any>(null);
  const [assignedAgentId, setAssignedAgentId] = useState<string>('');

  useEffect(() => {
    fetchCommercialData();
    fetchSalesData();
    fetchClientData();
  }, [clientId]);

  const fetchClientData = async () => {
    try {
      const { data, error } = await supabase
        .from('clients')
        .select('*')
        .eq('id', clientId)
        .single();

      if (error) throw error;

      setClientData(data);
      setAssignedAgentId(data.assigned_agent_id || '');
    } catch (error) {
      console.error('Error fetching client data:', error);
      toast.error('Error al cargar los datos del cliente');
    }
  };

  const fetchCommercialData = async () => {
    try {
      setLoading(true);
      const { data, error } = await supabase
        .from('client_commercial')
        .select('*')
        .eq('client_id', clientId)
        .single();

      if (error && error.code !== 'PGRST116') {
        // PGRST116 es el código para "no se encontraron resultados"
        throw error;
      }

      if (data) {
        setCommercialData(data);
        setFormData({
          client_id: data.client_id,
          sales_channel: data.sales_channel,
          payment_terms: data.payment_terms,
          credit_limit: data.credit_limit,
          current_balance: data.current_balance,
          preferred_shipping_method: data.preferred_shipping_method,
          discount_tier: data.discount_tier,
          customer_since: data.customer_since,
          preferred_products: data.preferred_products || [],
          notes: data.notes
        });
      }
    } catch (error) {
      console.error('Error fetching commercial data:', error);
      toast.error('Error al cargar los datos comerciales');
    } finally {
      setLoading(false);
    }
  };

  const fetchSalesData = async () => {
    try {
      // Simulación de datos de ventas por mes
      // En una implementación real, esto vendría de una consulta a la base de datos
      const mockSalesData: SalesData[] = [
        { month: 'Ene', amount: 12500 },
        { month: 'Feb', amount: 8700 },
        { month: 'Mar', amount: 15200 },
        { month: 'Abr', amount: 9800 },
        { month: 'May', amount: 14300 },
        { month: 'Jun', amount: 11900 }
      ];
      
      setSalesData(mockSalesData);
    } catch (error) {
      console.error('Error fetching sales data:', error);
    }
  };

  const validateForm = () => {
    const newErrors: Record<string, string> = {};
    
    if (!formData.sales_channel?.trim()) {
      newErrors.sales_channel = 'El canal de ventas es requerido';
    }
    
    if (!formData.payment_terms?.trim()) {
      newErrors.payment_terms = 'Los términos de pago son requeridos';
    }
    
    if (formData.credit_limit && formData.credit_limit < 0) {
      newErrors.credit_limit = 'El límite de crédito no puede ser negativo';
    }
    
    if (!assignedAgentId) {
      newErrors.assigned_agent_id = 'El asesor es requerido';
    }
    
    setErrors(newErrors);
    return Object.keys(newErrors).length === 0;
  };

  const getAssignedAgentName = (agentId?: string) => {
    if (!agentId) return 'Sin asignar';
    const agent = agents?.find(a => a.id === agentId);
    return agent ? agent.name : 'Asesor no encontrado';
  };

  const handleAgentChange = (agentId: string) => {
    setAssignedAgentId(agentId);
  };

  const handleSave = async () => {
    if (!validateForm()) return;
    
    try {
      // Actualizar el asesor asignado en la tabla de clientes
      const { error: clientError } = await supabase
        .from('clients')
        .update({
          assigned_agent_id: assignedAgentId,
          updated_at: new Date().toISOString()
        })
        .eq('id', clientId);

      if (clientError) throw clientError;
      
      if (commercialData) {
        // Actualizar datos comerciales existentes
        const { error } = await supabase
          .from('client_commercial')
          .update({
            sales_channel: formData.sales_channel,
            payment_terms: formData.payment_terms,
            credit_limit: formData.credit_limit,
            current_balance: formData.current_balance,
            preferred_shipping_method: formData.preferred_shipping_method,
            discount_tier: formData.discount_tier,
            customer_since: formData.customer_since,
            preferred_products: formData.preferred_products,
            notes: formData.notes,
            updated_at: new Date().toISOString()
          })
          .eq('id', commercialData.id);

        if (error) throw error;
        toast.success('Datos comerciales actualizados exitosamente');
      } else {
        // Crear nuevos datos comerciales
        const { error } = await supabase
          .from('client_commercial')
          .insert({
            client_id: clientId,
            sales_channel: formData.sales_channel,
            payment_terms: formData.payment_terms,
            credit_limit: formData.credit_limit,
            current_balance: formData.current_balance,
            preferred_shipping_method: formData.preferred_shipping_method,
            discount_tier: formData.discount_tier,
            customer_since: formData.customer_since,
            preferred_products: formData.preferred_products,
            notes: formData.notes
          });

        if (error) throw error;
        toast.success('Datos comerciales guardados exitosamente');
      }
      
      fetchCommercialData();
      fetchClientData();
    } catch (error) {
      console.error('Error saving commercial data:', error);
      toast.error('Error al guardar los datos comerciales');
    }
  };

  const formatCurrency = (amount?: number) => {
    if (amount === undefined || amount === null) return 'No especificado';
    return new Intl.NumberFormat('es-CO', { style: 'currency', currency: 'COP' }).format(amount);
  };

  const formatDate = (dateString?: string) => {
    if (!dateString) return 'No especificado';
    return new Date(dateString).toLocaleDateString();
  };

  if (loading) {
    return (
      <div className="flex justify-center py-8">
        <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600"></div>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      {/* Métricas Comerciales */}
      <div className="bg-white shadow rounded-lg overflow-hidden">
        <div className="p-4 sm:px-6 border-b border-gray-200">
          <h3 className="text-lg font-medium text-gray-900">Métricas Comerciales</h3>
        </div>
        
        <div className="p-6">
          <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
            <div className="bg-blue-50 p-4 rounded-lg">
              <div className="flex items-center">
                <div className="flex-shrink-0 bg-blue-100 rounded-md p-3">
                  <ShoppingCart className="h-6 w-6 text-blue-600" />
                </div>
                <div className="ml-4">
                  <h4 className="text-sm font-medium text-gray-500">Total de Compras</h4>
                  <p className="text-lg font-semibold text-gray-900">
                    {formatCurrency(commercialData?.total_purchases)}
                  </p>
                </div>
              </div>
            </div>
            
            <div className="bg-green-50 p-4 rounded-lg">
              <div className="flex items-center">
                <div className="flex-shrink-0 bg-green-100 rounded-md p-3">
                  <TrendingUp className="h-6 w-6 text-green-600" />
                </div>
                <div className="ml-4">
                  <h4 className="text-sm font-medium text-gray-500">Valor Promedio</h4>
                  <p className="text-lg font-semibold text-gray-900">
                    {formatCurrency(commercialData?.average_order_value)}
                  </p>
                </div>
              </div>
            </div>
            
            <div className="bg-purple-50 p-4 rounded-lg">
              <div className="flex items-center">
                <div className="flex-shrink-0 bg-purple-100 rounded-md p-3">
                  <Calendar className="h-6 w-6 text-purple-600" />
                </div>
                <div className="ml-4">
                  <h4 className="text-sm font-medium text-gray-500">Última Compra</h4>
                  <p className="text-lg font-semibold text-gray-900">
                    {formatDate(commercialData?.last_purchase_date)}
                  </p>
                </div>
              </div>
            </div>
          </div>
          
          {/* Gráfico de Ventas */}
          {salesData.length > 0 && (
            <div className="mt-8">
              <h4 className="text-sm font-medium text-gray-700 mb-4">Historial de Ventas (Últimos 6 meses)</h4>
              <div className="h-64 relative">
                <div className="absolute inset-0 flex items-end">
                  {salesData.map((data, index) => (
                    <div key={index} className="flex-1 flex flex-col items-center">
                      <div 
                        className="w-full max-w-[40px] bg-blue-500 rounded-t"
                        style={{ 
                          height: `${(data.amount / Math.max(...salesData.map(d => d.amount))) * 100}%`,
                          minHeight: '10px'
                        }}
                      ></div>
                      <div className="mt-2 text-xs text-gray-600">{data.month}</div>
                      <div className="text-xs font-medium text-gray-900">
                        {formatCurrency(data.amount).replace('COP', '').trim()}
                      </div>
                    </div>
                  ))}
                </div>
              </div>
            </div>
          )}
        </div>
      </div>

      {/* Información Comercial */}
      <div className="bg-white shadow rounded-lg overflow-hidden">
        <div className="p-4 sm:px-6 border-b border-gray-200">
          <h3 className="text-lg font-medium text-gray-900">Información Comercial</h3>
        </div>
        
        <div className="p-6">
          <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
            <div>
              <label className="block text-sm font-medium text-gray-700">
                Canal de Ventas <span className="text-red-500">*</span>
              </label>
              {isEditing ? (
                <div>
                  <select
                    value={formData.sales_channel || ''}
                    onChange={(e) => setFormData({ ...formData, sales_channel: e.target.value })}
                    className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
                  >
                    <option value="">Seleccionar canal</option>
                    <option value="direct">Venta Directa</option>
                    <option value="distributor">Distribuidor</option>
                    <option value="online">Online</option>
                    <option value="retail">Retail</option>
                    <option value="wholesale">Mayorista</option>
                  </select>
                  {errors.sales_channel && (
                    <p className="mt-1 text-sm text-red-600 flex items-center">
                      <AlertTriangle className="w-4 h-4 mr-1" />
                      {errors.sales_channel}
                    </p>
                  )}
                </div>
              ) : (
                <p className="mt-1 text-sm text-gray-900">
                  {commercialData?.sales_channel === 'direct' ? 'Venta Directa' :
                   commercialData?.sales_channel === 'distributor' ? 'Distribuidor' :
                   commercialData?.sales_channel === 'online' ? 'Online' :
                   commercialData?.sales_channel === 'retail' ? 'Retail' :
                   commercialData?.sales_channel === 'wholesale' ? 'Mayorista' :
                   commercialData?.sales_channel || 'No especificado'}
                </p>
              )}
            </div>
            
            <div>
              <label className="block text-sm font-medium text-gray-700">
                Términos de Pago <span className="text-red-500">*</span>
              </label>
              {isEditing ? (
                <div>
                  <select
                    value={formData.payment_terms || ''}
                    onChange={(e) => setFormData({ ...formData, payment_terms: e.target.value })}
                    className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
                  >
                    <option value="">Seleccionar términos</option>
                    <option value="immediate">Pago Inmediato</option>
                    <option value="15_days">15 días</option>
                    <option value="30_days">30 días</option>
                    <option value="45_days">45 días</option>
                    <option value="60_days">60 días</option>
                    <option value="90_days">90 días</option>
                  </select>
                  {errors.payment_terms && (
                    <p className="mt-1 text-sm text-red-600 flex items-center">
                      <AlertTriangle className="w-4 h-4 mr-1" />
                      {errors.payment_terms}
                    </p>
                  )}
                </div>
              ) : (
                <p className="mt-1 text-sm text-gray-900">
                  {commercialData?.payment_terms === 'immediate' ? 'Pago Inmediato' :
                   commercialData?.payment_terms === '15_days' ? '15 días' :
                   commercialData?.payment_terms === '30_days' ? '30 días' :
                   commercialData?.payment_terms === '45_days' ? '45 días' :
                   commercialData?.payment_terms === '60_days' ? '60 días' :
                   commercialData?.payment_terms === '90_days' ? '90 días' :
                   commercialData?.payment_terms || 'No especificado'}
                </p>
              )}
            </div>
            
            <div>
              <label className="block text-sm font-medium text-gray-700">
                Límite de Crédito
              </label>
              {isEditing ? (
                <div>
                  <input
                    type="number"
                    value={formData.credit_limit || ''}
                    onChange={(e) => setFormData({ ...formData, credit_limit: parseFloat(e.target.value) || undefined })}
                    className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
                  />
                  {errors.credit_limit && (
                    <p className="mt-1 text-sm text-red-600 flex items-center">
                      <AlertTriangle className="w-4 h-4 mr-1" />
                      {errors.credit_limit}
                    </p>
                  )}
                </div>
              ) : (
                <p className="mt-1 text-sm text-gray-900">
                  {commercialData?.credit_limit !== undefined ? formatCurrency(commercialData.credit_limit) : 'No especificado'}
                </p>
              )}
            </div>
            
            <div>
              <label className="block text-sm font-medium text-gray-700">
                Saldo Actual
              </label>
              {isEditing ? (
                <input
                  type="number"
                  value={formData.current_balance || ''}
                  onChange={(e) => setFormData({ ...formData, current_balance: parseFloat(e.target.value) || undefined })}
                  className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
                />
              ) : (
                <p className="mt-1 text-sm text-gray-900">
                  {commercialData?.current_balance !== undefined ? formatCurrency(commercialData.current_balance) : 'No especificado'}
                </p>
              )}
            </div>
            
            <div>
              <label className="block text-sm font-medium text-gray-700">
                Método de Envío Preferido
              </label>
              {isEditing ? (
                <select
                  value={formData.preferred_shipping_method || ''}
                  onChange={(e) => setFormData({ ...formData, preferred_shipping_method: e.target.value })}
                  className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
                >
                  <option value="">Seleccionar método</option>
                  <option value="standard">Estándar</option>
                  <option value="express">Express</option>
                  <option value="pickup">Recogida en Tienda</option>
                  <option value="courier">Mensajería</option>
                </select>
              ) : (
                <p className="mt-1 text-sm text-gray-900">
                  {commercialData?.preferred_shipping_method === 'standard' ? 'Estándar' :
                   commercialData?.preferred_shipping_method === 'express' ? 'Express' :
                   commercialData?.preferred_shipping_method === 'pickup' ? 'Recogida en Tienda' :
                   commercialData?.preferred_shipping_method === 'courier' ? 'Mensajería' :
                   commercialData?.preferred_shipping_method || 'No especificado'}
                </p>
              )}
            </div>
            
            <div>
              <label className="block text-sm font-medium text-gray-700">
                Nivel de Descuento
              </label>
              {isEditing ? (
                <select
                  value={formData.discount_tier || ''}
                  onChange={(e) => setFormData({ ...formData, discount_tier: e.target.value })}
                  className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
                >
                  <option value="">Seleccionar nivel</option>
                  <option value="none">Sin Descuento</option>
                  <option value="bronze">Bronce (5%)</option>
                  <option value="silver">Plata (10%)</option>
                  <option value="gold">Oro (15%)</option>
                  <option value="platinum">Platino (20%)</option>
                </select>
              ) : (
                <p className="mt-1 text-sm text-gray-900">
                  {commercialData?.discount_tier === 'none' ? 'Sin Descuento' :
                   commercialData?.discount_tier === 'bronze' ? 'Bronce (5%)' :
                   commercialData?.discount_tier === 'silver' ? 'Plata (10%)' :
                   commercialData?.discount_tier === 'gold' ? 'Oro (15%)' :
                   commercialData?.discount_tier === 'platinum' ? 'Platino (20%)' :
                   commercialData?.discount_tier || 'No especificado'}
                </p>
              )}
            </div>
            
            <div>
              <label className="block text-sm font-medium text-gray-700">
                Cliente Desde
              </label>
              {isEditing ? (
                <input
                  type="date"
                  value={formData.customer_since || ''}
                  onChange={(e) => setFormData({ ...formData, customer_since: e.target.value })}
                  className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
                />
              ) : (
                <p className="mt-1 text-sm text-gray-900">
                  {formatDate(commercialData?.customer_since)}
                </p>
              )}
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700">
                Asesor Asignado <span className="text-red-500">*</span>
              </label>
              {isEditing ? (
                <div>
                  <select
                    value={assignedAgentId}
                    onChange={(e) => handleAgentChange(e.target.value)}
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
                    <p className="mt-1 text-sm text-red-600 flex items-center">
                      <AlertTriangle className="w-4 h-4 mr-1" />
                      {errors.assigned_agent_id}
                    </p>
                  )}
                </div>
              ) : (
                <p className="mt-1 text-sm text-gray-900 flex items-center">
                  <UserCircle className="w-4 h-4 mr-1 text-gray-400" />
                  {getAssignedAgentName(clientData?.assigned_agent_id)}
                </p>
              )}
            </div>
            
            <div className="md:col-span-2">
              <label className="block text-sm font-medium text-gray-700">
                Productos Preferidos
              </label>
              {isEditing ? (
                <div className="mt-1">
                  <input
                    type="text"
                    value={formData.preferred_products ? formData.preferred_products.join(', ') : ''}
                    onChange={(e) => {
                      const productsArray = e.target.value.split(',').map(product => product.trim()).filter(product => product);
                      setFormData({ ...formData, preferred_products: productsArray });
                    }}
                    placeholder="Separados por comas"
                    className="block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
                  />
                  <p className="mt-1 text-xs text-gray-500">Ingrese los productos separados por comas</p>
                </div>
              ) : (
                <div className="mt-1 flex flex-wrap gap-2">
                  {commercialData?.preferred_products && commercialData.preferred_products.length > 0 ? (
                    commercialData.preferred_products.map((product, index) => (
                      <span 
                        key={index} 
                        className="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-blue-100 text-blue-800"
                      >
                        <Tag className="w-3 h-3 mr-1" />
                        {product}
                      </span>
                    ))
                  ) : (
                    <p className="text-sm text-gray-500">Sin productos preferidos</p>
                  )}
                </div>
              )}
            </div>
            
            <div className="md:col-span-2">
              <label className="block text-sm font-medium text-gray-700">
                Notas Comerciales
              </label>
              {isEditing ? (
                <textarea
                  value={formData.notes || ''}
                  onChange={(e) => setFormData({ ...formData, notes: e.target.value })}
                  rows={3}
                  className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
                />
              ) : (
                <p className="mt-1 text-sm text-gray-900">
                  {commercialData?.notes || 'Sin notas comerciales'}
                </p>
              )}
            </div>
          </div>
          
          {isEditing && (
            <div className="mt-6 flex justify-end">
              <button
                onClick={handleSave}
                className="inline-flex items-center px-4 py-2 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-blue-600 hover:bg-blue-700"
              >
                <DollarSign className="w-4 h-4 mr-2" />
                Guardar Información Comercial
              </button>
            </div>
          )}
        </div>
      </div>
    </div>
  );
}
