import React, { useState } from 'react';
import { Package, Plus, X, ChevronDown, ChevronUp } from 'lucide-react';
import { usePackagingTypes } from '../lib/hooks/usePackagingTypes';
import type { PackagingType } from '../lib/hooks/usePackagingTypes';

interface PackagingTypeValue {
  code: string;
  type: string;
  monthly_volume: number;
  unit: string;
  features: Record<string, string>;
}

interface PackagingTypeSelectorProps {
  value: PackagingTypeValue[];
  onChange: (value: PackagingTypeValue[]) => void;
  error?: string;
}

export function PackagingTypeSelector({ value, onChange, error }: PackagingTypeSelectorProps) {
  const { packagingTypes, isLoading } = usePackagingTypes();
  const [expandedIndex, setExpandedIndex] = useState<number | null>(null);

  const handleAddType = () => {
    if (packagingTypes.length > 0) {
      const newType: PackagingTypeValue = {
        code: packagingTypes[0].code,
        type: packagingTypes[0].name,
        monthly_volume: 0,
        unit: 'kg',
        features: {},
      };
      onChange([...value, newType]);
      setExpandedIndex(value.length);
    }
  };

  const handleRemoveType = (index: number) => {
    onChange(value.filter((_, i) => i !== index));
    if (expandedIndex === index) {
      setExpandedIndex(null);
    }
  };

  const handleTypeChange = (index: number, packagingType: PackagingType) => {
    const newValue = [...value];
    newValue[index] = {
      ...newValue[index],
      code: packagingType.code,
      type: packagingType.name,
      features: {},
    };
    onChange(newValue);
  };

  const handleVolumeChange = (index: number, volume: number) => {
    const newValue = [...value];
    newValue[index] = {
      ...newValue[index],
      monthly_volume: volume,
    };
    onChange(newValue);
  };

  const handleUnitChange = (index: number, unit: string) => {
    const newValue = [...value];
    newValue[index] = {
      ...newValue[index],
      unit,
    };
    onChange(newValue);
  };

  const handleFeatureChange = (index: number, feature: string, option: string) => {
    const newValue = [...value];
    newValue[index] = {
      ...newValue[index],
      features: {
        ...newValue[index].features,
        [feature]: option,
      },
    };
    onChange(newValue);
  };

  if (isLoading) {
    return <div className="text-gray-500">Cargando tipos de empaques...</div>;
  }

  return (
    <div className="space-y-4">
      {value.map((type, index) => {
        const packagingType = packagingTypes.find(pt => pt.code === type.code);
        const isExpanded = expandedIndex === index;

        return (
          <div key={index} className="border rounded-lg p-4">
            <div className="flex items-center justify-between mb-4">
              <div className="flex-1">
                <select
                  value={type.code}
                  onChange={(e) => {
                    const newType = packagingTypes.find(pt => pt.code === e.target.value);
                    if (newType) handleTypeChange(index, newType);
                  }}
                  className="w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
                >
                  {packagingTypes.map(pt => (
                    <option key={pt.code} value={pt.code}>{pt.name}</option>
                  ))}
                </select>
              </div>
              <div className="flex items-center ml-4 space-x-2">
                <button
                  type="button"
                  onClick={() => setExpandedIndex(isExpanded ? null : index)}
                  className="p-2 text-gray-500 hover:text-gray-700"
                >
                  {isExpanded ? (
                    <ChevronUp className="w-5 h-5" />
                  ) : (
                    <ChevronDown className="w-5 h-5" />
                  )}
                </button>
                <button
                  type="button"
                  onClick={() => handleRemoveType(index)}
                  className="p-2 text-red-500 hover:text-red-700"
                >
                  <X className="w-5 h-5" />
                </button>
              </div>
            </div>

            <div className="grid grid-cols-2 gap-4 mb-4">
              <div>
                <label className="block text-sm font-medium text-gray-700">
                  Volumen Mensual
                </label>
                <div className="mt-1 flex rounded-md shadow-sm">
                  <input
                    type="number"
                    value={type.monthly_volume}
                    onChange={(e) => handleVolumeChange(index, parseFloat(e.target.value) || 0)}
                    min="0"
                    step="0.01"
                    className="flex-1 rounded-l-md border-gray-300 focus:border-blue-500 focus:ring-blue-500"
                  />
                  <select
                    value={type.unit}
                    onChange={(e) => handleUnitChange(index, e.target.value)}
                    className="rounded-r-md border-l-0 border-gray-300 focus:border-blue-500 focus:ring-blue-500"
                  >
                    <option value="kg">kg</option>
                    <option value="units">unidades</option>
                    <option value="rolls">paquetes</option>
                    <option value="rolls">rollos</option>
                  </select>
                </div>
              </div>
            </div>

            {isExpanded && packagingType && (
              <div className="mt-4 space-y-4">
                <div className="text-sm text-gray-600">{packagingType.description}</div>

                <div>
                  <h4 className="text-sm font-medium text-gray-900 mb-2">Características</h4>
                  <div className="space-y-3">
                    {packagingType.typical_features.map((feature) => (
                      <div key={feature.name}>
                        <label className="block text-sm font-medium text-gray-700">
                          {feature.name}
                        </label>
                        <select
                          value={type.features[feature.name] || ''}
                          onChange={(e) => handleFeatureChange(index, feature.name, e.target.value)}
                          className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
                        >
                          <option value="">Seleccionar</option>
                          {feature.options.map(option => (
                            <option key={option} value={option}>{option}</option>
                          ))}
                        </select>
                      </div>
                    ))}
                  </div>
                </div>

                <div>
                  <h4 className="text-sm font-medium text-gray-900 mb-2">Usos Comunes</h4>
                  <div className="flex flex-wrap gap-2">
                    {packagingType.common_uses.map((use) => (
                      <span
                        key={use}
                        className="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-blue-100 text-blue-800"
                      >
                        {use}
                      </span>
                    ))}
                  </div>
                </div>
              </div>
            )}
          </div>
        );
      })}

      <button
        type="button"
        onClick={handleAddType}
        className="w-full flex items-center justify-center px-4 py-2 border border-gray-300 rounded-md shadow-sm text-sm font-medium text-gray-700 bg-white hover:bg-gray-50"
      >
        <Plus className="w-5 h-5 mr-2" />
        Agregar Tipo de Empaque
      </button>

      {error && (
        <p className="mt-2 text-sm text-red-600">{error}</p>
      )}
    </div>
  );
}