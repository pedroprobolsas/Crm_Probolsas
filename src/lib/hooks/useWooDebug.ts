import { useState } from 'react';
import type { WooCredentials } from '../types/product';

export interface DebugStep {
  id: string;
  name: string;
  status: 'pending' | 'running' | 'success' | 'error';
  message?: string;
  timestamp?: string;
}

interface DebugResult {
  success: boolean;
  steps: DebugStep[];
  error?: string;
  timestamp: string;
}

export function useWooDebug() {
  const [debugSteps, setDebugSteps] = useState<DebugStep[]>([]);
  const [isDebugging, setIsDebugging] = useState(false);

  const updateStep = (stepId: string, update: Partial<DebugStep>) => {
    setDebugSteps(steps => 
      steps.map(step => 
        step.id === stepId ? { ...step, ...update } : step
      )
    );
  };

  const testConnection = async (credentials: WooCredentials): Promise<DebugResult> => {
    setIsDebugging(true);
    const startTime = new Date();

    // Initialize steps
    setDebugSteps([
      { id: 'url', name: 'Validación de URL', status: 'pending' },
      { id: 'auth', name: 'Verificación de Credenciales', status: 'pending' },
      { id: 'api', name: 'Conexión a API', status: 'pending' },
      { id: 'products', name: 'Consulta de Productos', status: 'pending' }
    ]);

    try {
      // Step 1: Validate URL
      updateStep('url', { status: 'running' });
      const baseUrl = credentials.api_url.replace(/\/+$/, '');
      const apiUrl = `${baseUrl}/wp-json/wc/v3`;

      if (!baseUrl.startsWith('http')) {
        throw new Error('URL inválida: debe comenzar con http:// o https://');
      }

      updateStep('url', { 
        status: 'success',
        message: `URL base: ${baseUrl}\nURL de API: ${apiUrl}`,
        timestamp: new Date().toISOString()
      });

      // Step 2: Validate Auth
      updateStep('auth', { status: 'running' });
      
      if (!credentials.consumer_key.startsWith('ck_') || !credentials.consumer_secret.startsWith('cs_')) {
        throw new Error('Credenciales inválidas: formato incorrecto');
      }

      updateStep('auth', { 
        status: 'success',
        message: 'Credenciales en formato correcto',
        timestamp: new Date().toISOString()
      });

      // Step 3: Test API Connection
      updateStep('api', { status: 'running' });
      
      const response = await fetch('/api/test-woo-connection', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${localStorage.getItem('supabase.auth.token')}`
        },
        body: JSON.stringify(credentials)
      });

      if (!response.ok) {
        const error = await response.json();
        throw new Error(error.error || 'Error al conectar con la API');
      }

      const result = await response.json();
      
      if (!result.success) {
        throw new Error(result.error || 'Error al probar la conexión');
      }

      updateStep('api', { 
        status: 'success',
        message: `Versión WooCommerce: ${result.storeInfo.version}`,
        timestamp: new Date().toISOString()
      });

      // Step 4: Products
      updateStep('products', { 
        status: 'success',
        message: `Total productos encontrados: ${result.productCount}`,
        timestamp: new Date().toISOString()
      });

      const endTime = new Date();
      const duration = endTime.getTime() - startTime.getTime();

      return {
        success: true,
        steps: debugSteps,
        timestamp: endTime.toISOString(),
        duration
      };

    } catch (error) {
      // Find the current running step and mark it as failed
      const failedStep = debugSteps.find(step => step.status === 'running');
      if (failedStep) {
        updateStep(failedStep.id, { 
          status: 'error',
          message: error instanceof Error ? error.message : 'Error desconocido',
          timestamp: new Date().toISOString()
        });
      }

      return {
        success: false,
        steps: debugSteps,
        error: error instanceof Error ? error.message : 'Error desconocido',
        timestamp: new Date().toISOString()
      };
    } finally {
      setIsDebugging(false);
    }
  };

  return {
    testConnection,
    debugSteps,
    isDebugging
  };
}