export type Json =
  | string
  | number
  | boolean
  | null
  | { [key: string]: Json | undefined }
  | Json[]

export interface Database {
  public: {
    Tables: {
      agents: {
        Row: {
          id: string
          created_at: string
          updated_at: string
          name: string
          email: string
          whatsapp_number: string
          role: 'admin' | 'agent'
          status: 'online' | 'busy' | 'offline' | 'inactive'
          avatar: string | null
          active_chats: number
          satisfaction_score: number
          last_active: string
          deactivation_reason: string | null
          deactivation_date: string | null
        }
        Insert: {
          id?: string
          created_at?: string
          updated_at?: string
          name: string
          email: string
          whatsapp_number: string
          role?: 'admin' | 'agent'
          status?: 'online' | 'busy' | 'offline' | 'inactive'
          avatar?: string | null
          active_chats?: number
          satisfaction_score?: number
          last_active?: string
          deactivation_reason?: string | null
          deactivation_date?: string | null
        }
        Update: {
          id?: string
          created_at?: string
          updated_at?: string
          name?: string
          email?: string
          whatsapp_number?: string
          role?: 'admin' | 'agent'
          status?: 'online' | 'busy' | 'offline' | 'inactive'
          avatar?: string | null
          active_chats?: number
          satisfaction_score?: number
          last_active?: string
          deactivation_reason?: string | null
          deactivation_date?: string | null
        }
      }
      clients_agents: {
        Row: {
          id: string
          client_id: string
          agent_id: string
          assigned_at: string
          active: boolean
          created_at: string
          updated_at: string
        }
        Insert: {
          id?: string
          client_id: string
          agent_id: string
          assigned_at?: string
          active?: boolean
          created_at?: string
          updated_at?: string
        }
        Update: {
          id?: string
          client_id?: string
          agent_id?: string
          assigned_at?: string
          active?: boolean
          created_at?: string
          updated_at?: string
        }
      }
    }
  }
}

export type AgentDB = Database['public']['Tables']['agents']['Row']
export type AgentInsert = Database['public']['Tables']['agents']['Insert']
export type AgentUpdate = Database['public']['Tables']['agents']['Update']

export interface Agent {
  id: string
  name: string
  email: string
  whatsappNumber: string
  role: 'admin' | 'agent'
  status: 'online' | 'busy' | 'offline' | 'inactive'
  avatar: string | null
  activeChats: number
  satisfactionScore: number
  lastActive: string
  createdAt: string
  updatedAt: string
  deactivationReason?: string | null
  deactivationDate?: string | null
}

export interface AssignedClient {
  id: string
  name: string
  company: string
  status: 'active' | 'inactive' | 'at_risk'
  stage: string | null
  lastInteraction: string | null
}

export interface ClientReassignment {
  clientId: string
  fromAgentId: string
  toAgentId: string
  effectiveDate: string
}

export interface Message {
  id: string;
  conversation_id: string;
  content: string;
  sender: 'agent' | 'client';
  sender_id: string;
  type: 'text' | 'image' | 'file' | 'audio' | 'pdf';
  status: 'sent' | 'delivered' | 'read';
  asistente_ia_activado?: boolean;
  metadata?: any;
  file_url?: string;
  file_name?: string;
  file_size?: number;
  recipient_phone?: string;
  message_id?: string;
  direction?: string;
  error_message?: string;
  retry_count?: number;
  last_retry_at?: string;
  processed_at?: string;
  delivered_at?: string;
  read_at?: string;
  created_at: string;
  updated_at: string;
  embedding?: any;
}

export interface Conversation {
  id: string;
  created_at: string;
  updated_at: string;
  client_id: string;
  agent_id: string;
  whatsapp_chat_id: string;
  last_message: string;
  last_message_at: string;
  ai_summary?: string;
  client_name?: string;
  client_company?: string;
  unread_count?: number;
}

export type ConversationInsert = Omit<Conversation, 'id' | 'created_at' | 'updated_at' | 'client_name' | 'client_company' | 'unread_count'>;
export type ConversationUpdate = Partial<Omit<Conversation, 'id' | 'created_at' | 'updated_at'>>;

export interface Client {
  id: string;
  name: string;
  email: string;
  phone: string;
  company: string;
  status: 'active' | 'inactive' | 'at_risk';
  tags?: string[];
  notes?: string;
  ai_insights?: any;
  description?: string;
  brand?: string;
  created_at: string;
  updated_at: string;
}

export type ClientInsert = Omit<Client, 'id' | 'created_at' | 'updated_at'>;
export type ClientUpdate = Partial<Omit<Client, 'id' | 'created_at' | 'updated_at'>>;

export interface ClientFilters {
  search?: string;
  status?: 'active' | 'inactive' | 'at_risk';
  stage?: string;
  tags?: string[];
}

export type ClientStatus = 'active' | 'inactive' | 'at_risk';

export type ClientStage = 'lead' | 'prospect' | 'negotiation' | 'customer' | 'inactive';

export interface ClientInteraction {
  id: string;
  client_id: string;
  agent_id: string;
  type: 'call' | 'email' | 'visit' | 'consultation';
  date: string;
  notes: string;
  next_action?: string | null;
  next_action_date?: string | null;
  priority: 'low' | 'medium' | 'high';
  status: 'pending' | 'completed' | 'cancelled';
  attachments?: Array<{
    name: string;
    url: string;
    type?: string;
    size?: number;
  }> | null;
  created_at: string;
  updated_at: string;
}

export type ClientInteractionInsert = Omit<ClientInteraction, 'id' | 'created_at' | 'updated_at'>;

export interface Product {
  id: string;
  name: string;
  sku: string;
  description?: string;
  regular_price: number;
  price_2: number;
  price_3: number;
  price_4: number;
  unit_type: string;
  categories: string[];
  status: 'active' | 'inactive';
  woo_status: 'publish' | 'draft';
  image?: string;
  created_at: string;
  updated_at: string;
}

export type NewProduct = Omit<Product, 'id' | 'status' | 'woo_status' | 'created_at' | 'updated_at'>;

export interface Quote {
  id: string;
  client_id: string;
  agent_id: string;
  title: string;
  status: 'draft' | 'sent' | 'approved' | 'rejected' | 'expired';
  subtotal: number;
  tax: number;
  discount: number;
  total: number;
  notes?: string;
  valid_until?: string;
  created_at: string;
  updated_at: string;
}

export interface QuoteItem {
  id: string;
  quote_id: string;
  product_id: string;
  product_name: string;
  product_sku: string;
  quantity: number;
  unit_price: number;
  subtotal: number;
  created_at: string;
  updated_at: string;
}

export interface EventType {
  id: string;
  name: string;
  color: string;
}
