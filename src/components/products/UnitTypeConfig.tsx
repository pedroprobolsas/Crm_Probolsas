import React from 'react';
import { Settings } from 'lucide-react';
import type { ProductSetting } from '../../lib/types/product';

interface UnitTypeConfigProps {
  settings: ProductSetting[];
  onUpdate: (type: string, key: string, value: string) => void;
  isLoading?: boolean;
}

export function UnitTypeConfig({ settings, onUpdate, isLoading }: UnitTypeConfigProps) {
  const defaultUnitType = settings.find(s => s.setting_key === 'default_unit_type')?.setting_value || 'unidades';
  const customUnitType = settings.find(s => s.setting_key === 'custom_unit_type')?.setting_value || '';

  return (
    <div className="bg-white rounded-lg shadow p-6">
      <div className="flex items-center justify-between mb-6">
        <div className="flex items-center">
          <Settings className="w-5 h-5 text-blue-600 mr-2" />
          <h3 className="text-lg font-semibold text-gray-900">Configuración de Unidades</h3>
        </div>
      </div>

      <div className="space-y-6">
        <div>
          <label className="block text-sm font-medium text-gray-700 mb-2">
            Tipo de Unidad por Defecto
          </label>
          <select
            value={defaultUnitType}
            onChange={(e) => onUpdate('units', 'default_unit_type', e.target.value)}
            disabled={isLoading}
            className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
          >
            <option value="unidades">Unidades</option>
            <option value="paquetes">Paquetes</option>
            <option value="millares">Millares</option>
            <option value="rollos">Rollos</option>
            <option value="kilos">Kilos</option>
            <option value="bolsas">Bolsas</option>
            <option value="cajas">Cajas</option>
            <option value="metros">Metros</option>
            <option value="litros">Litros</option>
            <option value="docenas">Docenas</option>
            <option value="otro">Otro</option>
          </select>
        </div>

        {defaultUnitType === 'otro' && (
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">
              Tipo de Unidad Personalizado
            </label>
            <input
              type="text"
              value={customUnitType}
              onChange={(e) => onUpdate('units', 'custom_unit_type', e.target.value)}
              disabled={isLoading}
              placeholder="Especifique el tipo de unidad"
              className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
            />
          </div>
        )}

        <div className="mt-4 text-sm text-gray-500">
          <p>Esta configuración se aplicará a todos los productos nuevos.</p>
        </div>
      </div>
    </div>
  );
}