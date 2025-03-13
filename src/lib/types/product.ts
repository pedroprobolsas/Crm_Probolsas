export interface WooProduct {
  id: string;
  name: string;
  sku: string;
  regular_price: number;
  categories: string[];
  status: 'publish' | 'draft';
  image?: string;
}

export interface ProductPrice extends WooProduct {
  price_2: number;
  price_3: number;
  price_4: number;
  unit_type: string;
  min_quantities: {
    price_2: number;
    price_3: number;
    price_4: number;
  };
}

export interface WooCredentials {
  api_url: string;
  consumer_key: string;
  consumer_secret: string;
}

export interface ConnectionStatus {
  state: 'connected' | 'disconnected' | 'error';
  lastCheck: string | null;
  error?: string;
  productCount?: number;
  storeInfo?: {
    name: string;
    url: string;
    version: string;
  };
}

export interface ProductSetting {
  id: string;
  setting_type: string;
  setting_key: string;
  setting_value: string;
  is_encrypted: boolean;
  created_at: string;
  updated_at: string;
}