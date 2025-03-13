import React from 'react';
import { BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, Legend, ResponsiveContainer } from 'recharts';
import { useClientTracking } from '../../lib/hooks/useClientTracking';
import { Loader2, AlertCircle, Users, Clock } from 'lucide-react';

export function ClientTrackingPanel() {
  const { metrics, agentPerformance, isLoading, error } = useClientTracking();

  if (isLoading) {
    return (
      <div className="flex items-center justify-center h-64">
        <Loader2 className="w-8 h-8 animate-spin text-blue-600" />
      </div>
    );
  }

  if (error) {
    return (
      <div className="bg-red-50 p-4 rounded-lg">
        <div className="flex items-center">
          <AlertCircle className="w-5 h-5 text-red-400 mr-2" />
          <p className="text-red-600">Error al cargar métricas: {error.message}</p>
        </div>
      </div>
    );
  }

  const getRangeColor = (range: string) => {
    switch (range) {
      case '0-30':
        return 'bg-green-100 text-green-800 border-green-200';
      case '31-60':
        return 'bg-yellow-100 text-yellow-800 border-yellow-200';
      case '61-90':
        return 'bg-orange-100 text-orange-800 border-orange-200';
      default:
        return 'bg-red-100 text-red-800 border-red-200';
    }
  };

  return (
    <div className="space-y-6">
      {/* Summary Cards */}
      <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
        {Object.entries(metrics.summary).map(([range, data]) => (
          <div 
            key={range} 
            className={`border rounded-lg shadow-sm ${getRangeColor(range)} p-4`}
          >
            <div className="flex items-center justify-between">
              <div className="flex items-center">
                <Clock className="w-5 h-5 mr-2 opacity-70" />
                <h3 className="text-sm font-medium">{range} días</h3>
              </div>
              <span className="text-xs font-medium px-2 py-1 rounded-full bg-white bg-opacity-50">
                {data.percentage}%
              </span>
            </div>
            <p className="mt-2 text-2xl font-semibold">
              {data.count}
              <span className="text-sm font-normal ml-1">clientes</span>
            </p>
          </div>
        ))}
      </div>

      {/* Performance Chart */}
      <div className="bg-white p-6 rounded-lg shadow-sm border border-gray-200">
        <div className="flex items-center justify-between mb-6">
          <h3 className="text-lg font-medium text-gray-900">
            Tendencia de Seguimiento por Asesor
          </h3>
          <div className="flex items-center text-sm text-gray-500">
            <Users className="w-4 h-4 mr-1" />
            <span>Últimos 12 meses</span>
          </div>
        </div>
        <div className="h-80">
          <ResponsiveContainer width="100%" height="100%">
            <BarChart data={agentPerformance}>
              <CartesianGrid strokeDasharray="3 3" stroke="#E5E7EB" />
              <XAxis 
                dataKey="month" 
                tick={{ fontSize: 12 }}
                tickLine={false}
              />
              <YAxis 
                tick={{ fontSize: 12 }}
                tickLine={false}
                axisLine={false}
              />
              <Tooltip 
                contentStyle={{ 
                  backgroundColor: 'white',
                  border: '1px solid #E5E7EB',
                  borderRadius: '0.375rem',
                  boxShadow: '0 1px 2px 0 rgba(0, 0, 0, 0.05)'
                }}
              />
              <Legend />
              <Bar 
                dataKey="active_clients_30d" 
                name="Clientes Activos (30d)" 
                fill="#4F46E5"
                radius={[4, 4, 0, 0]}
              />
              <Bar 
                dataKey="total_clients_contacted" 
                name="Total Clientes" 
                fill="#E5E7EB"
                radius={[4, 4, 0, 0]}
              />
            </BarChart>
          </ResponsiveContainer>
        </div>
      </div>

      {/* Detailed Metrics Table */}
      <div className="bg-white rounded-lg shadow-sm border border-gray-200 overflow-hidden">
        <div className="px-6 py-4 border-b border-gray-200">
          <h3 className="text-lg font-medium text-gray-900">
            Métricas por Asesor
          </h3>
        </div>
        <div className="overflow-x-auto">
          <table className="min-w-full divide-y divide-gray-200">
            <thead className="bg-gray-50">
              <tr>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Asesor
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Clientes Activos
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  % Activos
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Sin Contacto +60d
                </th>
              </tr>
            </thead>
            <tbody className="bg-white divide-y divide-gray-200">
              {metrics.byAgent.map((agent) => (
                <tr key={agent.agent_id} className="hover:bg-gray-50">
                  <td className="px-6 py-4 whitespace-nowrap">
                    <div className="flex items-center">
                      <img
                        src={`https://ui-avatars.com/api/?name=${encodeURIComponent(agent.agent_name)}&background=random`}
                        alt={agent.agent_name}
                        className="w-8 h-8 rounded-full"
                      />
                      <div className="ml-3">
                        <div className="text-sm font-medium text-gray-900">
                          {agent.agent_name}
                        </div>
                      </div>
                    </div>
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap">
                    <div className="text-sm text-gray-900">{agent.active_clients}</div>
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap">
                    <span className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${
                      agent.active_percentage >= 70
                        ? 'bg-green-100 text-green-800'
                        : agent.active_percentage >= 50
                        ? 'bg-yellow-100 text-yellow-800'
                        : 'bg-red-100 text-red-800'
                    }`}>
                      {agent.active_percentage}%
                    </span>
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap">
                    <div className="text-sm text-gray-900">{agent.inactive_clients}</div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
}