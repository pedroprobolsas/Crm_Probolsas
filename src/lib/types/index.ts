// Agregar estos tipos al archivo de tipos existente

export interface Quote {
  id: string;
  quote_number: string;
  client_id: string;
  client_name: string;
  client_company: string;
  agent_id: string;
  agent_name: string;
  status: 'draft' | 'sent' | 'approved' | 'rejected';
  total_amount: number;
  valid_until: string;
  terms: string;
  notes: string;
  items: QuoteItem[];
  created_at: string;
}

export interface QuoteItem {
  id?: string;
  quote_id: string;
  product_id: string;
  product_name: string;
  quantity: number;
  unit_price: number;
  total_price: number;
  notes?: string;
}

export interface QuoteHistory {
  id: string;
  quote_id: string;
  agent_id: string;
  action: 'created' | 'updated' | 'status_changed';
  previous_status?: string;
  new_status?: string;
  changes?: Record<string, any>;
  created_at: string;
}