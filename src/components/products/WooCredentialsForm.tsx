import React, { useState, useEffect } from 'react';
import { Eye, EyeOff, Copy, Check, AlertTriangle, HelpCircle } from 'lucide-react';
import { toast } from 'sonner';
import type { ProductSetting } from '../../lib/types/product';

interface WooCredentialsFormProps {
  settings: ProductSetting[];
  onUpdate: (type: string, key: string, value: string) => void;
  isLoading?: boolean;
}

interface ValidationState {
  consumer_key: string[];
  consumer_secret: string[];
}

export function WooCredentialsForm({ settings, onUpdate, isLoading }: WooCredentialsFormProps) {
  const [showSecrets, setShowSecrets] = useState(false);
  const [copied, setCopied] = useState<Record<string, boolean>>({});
  const [errors, setErrors] = useState<ValidationState>({
    consumer_key: [],
    consumer_secret: []
  });

  const credentials = {
    api_url: settings.find(s => s.setting_key === 'api_url')?.setting_value || '',
    consumer_key: settings.find(s => s.setting_key === 'consumer_key')?.setting_value || '',
    consumer_secret: settings.find(s => s.setting_key === 'consumer_secret')?.setting_value || ''
  };

  const validateKey = (key: string, type: 'consumer_key' | 'consumer_secret'): string[] => {
    const errors: string[] = [];
    const prefix = type === 'consumer_key' ? 'ck_' : 'cs_';
    const keyFormat = new RegExp(`^${prefix}[a-zA-Z0-9]{40}$`);

    if (!key) {
      errors.push(`${type === 'consumer_key' ? 'Consumer Key' : 'Consumer Secret'} es requerida`);
    } else if (!key.startsWith(prefix)) {
      errors.push(`Debe comenzar con "${prefix}"`);
    } else if (!keyFormat.test(key)) {
      errors.push(`Formato inválido. Debe ser ${prefix} seguido de 40 caracteres alfanuméricos`);
    }

    return errors;
  };

  const handleChange = (type: string, key: string, value: string) => {
    // For consumer keys, automatically add prefix if not present
    if (key === 'consumer_key' && value && !value.startsWith('ck_')) {
      value = `ck_${value.replace('ck_', '')}`;
    }
    if (key === 'consumer_secret' && value && !value.startsWith('cs_')) {
      value = `cs_${value.replace('cs_', '')}`;
    }

    // Validate keys
    if (key === 'consumer_key' || key === 'consumer_secret') {
      const validationErrors = validateKey(value, key as 'consumer_key' | 'consumer_secret');
      setErrors(prev => ({
        ...prev,
        [key]: validationErrors
      }));
    }

    onUpdate(type, key, value);
  };

  const handleCopy = async (text: string, field: string) => {
    try {
      await navigator.clipboard.writeText(text);
      setCopied({ [field]: true });
      setTimeout(() => setCopied({ [field]: false }), 2000);
      toast.success('Copiado al portapapeles');
    } catch (error) {
      toast.error('Error al copiar al portapapeles');
    }
  };

  return (
    <div className="space-y-6">
      <div>
        <label className="block text-sm font-medium text-gray-700">URL de la API</label>
        <div className="mt-1 relative rounded-md shadow-sm">
          <input
            type="url"
            value={credentials.api_url}
            onChange={(e) => handleChange('woocommerce', 'api_url', e.target.value)}
            className="block w-full pr-10 rounded-md border-gray-300 focus:ring-blue-500 focus:border-blue-500 sm:text-sm"
            placeholder="https://tutienda.com"
            disabled={isLoading}
          />
        </div>
      </div>

      <div>
        <div className="flex items-center justify-between">
          <label className="block text-sm font-medium text-gray-700">Consumer Key</label>
          <button
            type="button"
            onClick={() => handleCopy(credentials.consumer_key, 'consumer_key')}
            className="p-1 text-gray-400 hover:text-gray-600"
          >
            {copied.consumer_key ? (
              <Check className="w-4 h-4 text-green-500" />
            ) : (
              <Copy className="w-4 h-4" />
            )}
          </button>
        </div>
        <div className="mt-1 relative rounded-md shadow-sm">
          <div className="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
            <span className="text-gray-500 sm:text-sm">ck_</span>
          </div>
          <input
            type={showSecrets ? 'text' : 'password'}
            value={credentials.consumer_key.replace('ck_', '')}
            onChange={(e) => handleChange('woocommerce', 'consumer_key', e.target.value)}
            className={`block w-full pl-12 pr-10 rounded-md sm:text-sm ${
              errors.consumer_key.length > 0
                ? 'border-red-300 focus:ring-red-500 focus:border-red-500'
                : 'border-gray-300 focus:ring-blue-500 focus:border-blue-500'
            }`}
            placeholder="xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
            disabled={isLoading}
            spellCheck={false}
            autoComplete="off"
          />
          <div className="absolute inset-y-0 right-0 pr-3 flex items-center">
            <button
              type="button"
              onClick={() => setShowSecrets(!showSecrets)}
              className="text-gray-400 hover:text-gray-600"
            >
              {showSecrets ? (
                <EyeOff className="w-4 h-4" />
              ) : (
                <Eye className="w-4 h-4" />
              )}
            </button>
          </div>
        </div>
        {errors.consumer_key.map((error, index) => (
          <p key={index} className="mt-2 text-sm text-red-600 flex items-center">
            <AlertTriangle className="w-4 h-4 mr-1" />
            {error}
          </p>
        ))}
      </div>

      <div>
        <div className="flex items-center justify-between">
          <label className="block text-sm font-medium text-gray-700">Consumer Secret</label>
          <button
            type="button"
            onClick={() => handleCopy(credentials.consumer_secret, 'consumer_secret')}
            className="p-1 text-gray-400 hover:text-gray-600"
          >
            {copied.consumer_secret ? (
              <Check className="w-4 h-4 text-green-500" />
            ) : (
              <Copy className="w-4 h-4" />
            )}
          </button>
        </div>
        <div className="mt-1 relative rounded-md shadow-sm">
          <div className="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
            <span className="text-gray-500 sm:text-sm">cs_</span>
          </div>
          <input
            type={showSecrets ? 'text' : 'password'}
            value={credentials.consumer_secret.replace('cs_', '')}
            onChange={(e) => handleChange('woocommerce', 'consumer_secret', e.target.value)}
            className={`block w-full pl-12 pr-10 rounded-md sm:text-sm ${
              errors.consumer_secret.length > 0
                ? 'border-red-300 focus:ring-red-500 focus:border-red-500'
                : 'border-gray-300 focus:ring-blue-500 focus:border-blue-500'
            }`}
            placeholder="xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
            disabled={isLoading}
            spellCheck={false}
            autoComplete="off"
          />
          <div className="absolute inset-y-0 right-0 pr-3 flex items-center">
            <button
              type="button"
              onClick={() => setShowSecrets(!showSecrets)}
              className="text-gray-400 hover:text-gray-600"
            >
              {showSecrets ? (
                <EyeOff className="w-4 h-4" />
              ) : (
                <Eye className="w-4 h-4" />
              )}
            </button>
          </div>
        </div>
        {errors.consumer_secret.map((error, index) => (
          <p key={index} className="mt-2 text-sm text-red-600 flex items-center">
            <AlertTriangle className="w-4 h-4 mr-1" />
            {error}
          </p>
        ))}
      </div>

      <div className="mt-4 p-4 bg-blue-50 rounded-lg">
        <div className="flex">
          <div className="flex-shrink-0">
            <HelpCircle className="h-5 w-5 text-blue-400" />
          </div>
          <div className="ml-3">
            <h3 className="text-sm font-medium text-blue-800">Formato de Claves WooCommerce</h3>
            <div className="mt-2 text-sm text-blue-700">
              <ul className="list-disc pl-5 space-y-1">
                <li>Consumer Key debe comenzar con "ck_"</li>
                <li>Consumer Secret debe comenzar con "cs_"</li>
                <li>Ambas claves deben tener 40 caracteres alfanuméricos después del prefijo</li>
                <li>Las claves se pueden obtener en WooCommerce &gt; Ajustes &gt; Avanzado &gt; API REST</li>
              </ul>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}