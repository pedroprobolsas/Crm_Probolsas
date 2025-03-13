import React from 'react';
import { DollarSign, AlertTriangle } from 'lucide-react';
import type { ProductSetting } from '../../lib/types/product';

interface PriceRangeConfigProps {
  settings: ProductSetting[];
  onUpdate: (type: string, key: string, value: string) => void;
  isLoading?: boolean;
}

export function PriceRangeConfig({ settings, onUpdate, isLoading }: PriceRangeConfigProps) {
  const priceRanges = {
    price_2: {
      from: settings.find(s => s.setting_key === 'price_2_from')?.setting_value || '100',
      to: settings.find(s => s.setting_key === 'price_2_to')?.setting_value || '499',
      show: settings.find(s => s.setting_key === 'show_price_2')?.setting_value === 'true'
    },
    price_3: {
      from: settings.find(s => s.setting_key === 'price_3_from')?.setting_value || '500',
      to: settings.find(s => s.setting_key === 'price_3_to')?.setting_value || '999',
      show: settings.find(s => s.setting_key === 'show_price_3')?.setting_value === 'true'
    },
    price_4: {
      from: settings.find(s => s.setting_key === 'price_4_from')?.setting_value || '1000',
      to: settings.find(s => s.setting_key === 'price_4_to')?.setting_value || '',
      show: settings.find(s => s.setting_key === 'show_price_4')?.setting_value === 'true'
    }
  };

  const validateRanges = (tier: number, value: string, isFrom: boolean) => {
    const numValue = parseInt(value);
    if (isNaN(numValue)) return false;

    if (isFrom) {
      // Validate "from" value
      if (tier > 2) {
        const prevTo = parseInt(priceRanges[`price_${tier-1}` as keyof typeof priceRanges].to);
        if (!isNaN(prevTo) && numValue <= prevTo) return false;
      }
    } else {
      // Validate "to" value
      const from = parseInt(priceRanges[`price_${tier}` as keyof typeof priceRanges].from);
      if (!isNaN(from) && numValue <= from) return false;
      
      if (tier < 4) {
        const nextFrom = parseInt(priceRanges[`price_${tier+1}` as keyof typeof priceRanges].from);
        if (!isNaN(nextFrom) && numValue >= nextFrom) return false;
      }
    }

    return true;
  };

  return (
    <div className="bg-white rounded-lg shadow p-6">
      <div className="flex items-center justify-between mb-6">
        <div className="flex items-center">
          <DollarSign className="w-5 h-5 text-blue-600 mr-2" />
          <h3 className="text-lg font-semibold text-gray-900">Rangos de Precios</h3>
        </div>
      </div>

      <div className="space-y-6">
        {[2, 3, 4].map((tier) => {
          const priceKey = `price_${tier}` as keyof typeof priceRanges;
          const range = priceRanges[priceKey];

          return (
            <div key={tier} className="border rounded-lg p-4">
              <div className="flex items-center justify-between mb-4">
                <h4 className="text-sm font-medium text-gray-900">Precio {tier}</h4>
                <label className="flex items-center">
                  <input
                    type="checkbox"
                    checked={range.show}
                    onChange={(e) => onUpdate('prices', `show_price_${tier}`, e.target.checked.toString())}
                    disabled={isLoading}
                    className="rounded border-gray-300 text-blue-600 shadow-sm focus:border-blue-300 focus:ring focus:ring-blue-200 focus:ring-opacity-50"
                  />
                  <span className="ml-2 text-sm text-gray-600">Mostrar en tienda</span>
                </label>
              </div>

              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">
                    Cantidad Desde
                  </label>
                  <input
                    type="number"
                    value={range.from}
                    onChange={(e) => {
                      if (validateRanges(tier, e.target.value, true)) {
                        onUpdate('prices', `price_${tier}_from`, e.target.value);
                      }
                    }}
                    min="1"
                    disabled={isLoading}
                    className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
                  />
                </div>

                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">
                    Cantidad Hasta
                  </label>
                  <input
                    type="number"
                    value={range.to}
                    onChange={(e) => {
                      if (validateRanges(tier, e.target.value, false)) {
                        onUpdate('prices', `price_${tier}_to`, e.target.value);
                      }
                    }}
                    min={parseInt(range.from) + 1}
                    disabled={isLoading || tier === 4}
                    placeholder={tier === 4 ? "Sin límite" : ""}
                    className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
                  />
                </div>
              </div>

              {!validateRanges(tier, range.from, true) && (
                <p className="mt-2 text-sm text-red-600 flex items-center">
                  <AlertTriangle className="w-4 h-4 mr-1" />
                  Rango inválido: La cantidad inicial debe ser mayor que el rango anterior
                </p>
              )}
            </div>
          );
        })}

        <div className="mt-4 text-sm text-gray-500">
          <p>Esta configuración se aplicará a todos los productos nuevos.</p>
        </div>
      </div>
    </div>
  );
}