export const getWooHeaders = (consumerKey: string, consumerSecret: string) => {
  const authString = btoa(`${consumerKey}:${consumerSecret}`);
  return {
    'Authorization': `Basic ${authString}`,
    'Content-Type': 'application/json',
    'Accept': 'application/json'
  };
};

export const handleWooError = (error: any) => {
  if (error.response) {
    return `WooCommerce API error: ${error.response.status} - ${error.response.statusText}`;
  }
  if (error.request) {
    return 'No se pudo conectar con WooCommerce';
  }
  return error.message || 'Error desconocido';
};

export const validateWooCredentials = (credentials: {
  api_url?: string;
  consumer_key?: string;
  consumer_secret?: string;
}) => {
  const { api_url, consumer_key, consumer_secret } = credentials;

  if (!api_url) {
    throw new Error('URL de la API es requerida');
  }
  if (!consumer_key) {
    throw new Error('Consumer Key es requerida');
  }
  if (!consumer_secret) {
    throw new Error('Consumer Secret es requerida');
  }

  if (!consumer_key.startsWith('ck_')) {
    throw new Error('Consumer Key debe comenzar con "ck_"');
  }
  if (!consumer_secret.startsWith('cs_')) {
    throw new Error('Consumer Secret debe comenzar con "cs_"');
  }

  return {
    api_url: api_url.replace(/\/+$/, ''),
    consumer_key,
    consumer_secret
  };
};