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
      clients: {
        Row: {
          id: string
          created_at: string
          updated_at: string
          name: string
          email: string
          phone: string
          company: string
          status: 'active' | 'inactive' | 'at_risk'
          tags: string[]
          notes: string
          ai_insights: Json
        }
        Insert: {
          id?: string
          created_at?: string
          updated_at?: string
          name: string
          email: string
          phone: string
          company: string
          status?: 'active' | 'inactive' | 'at_risk'
          tags?: string[]
          notes?: string
          ai_insights?: Json
        }
        Update: {
          id?: string
          created_at?: string
          updated_at?: string
          name?: string
          email?: string
          phone?: string
          company?: string
          status?: 'active' | 'inactive' | 'at_risk'
          tags?: string[]
          notes?: string
          ai_insights?: Json
        }
      }
      products: {
        Row: {
          id: string
          created_at: string
          updated_at: string
          name: string
          description: string
          packaging_type: string
          price: number
          stock: number
          min_stock: number
          last_sync: string
        }
        Insert: {
          id?: string
          created_at?: string
          updated_at?: string
          name: string
          description: string
          packaging_type: string
          price: number
          stock: number
          min_stock?: number
          last_sync?: string
        }
        Update: {
          id?: string
          created_at?: string
          updated_at?: string
          name?: string
          description?: string
          packaging_type?: string
          price?: number
          stock?: number
          min_stock?: number
          last_sync?: string
        }
      }
      conversations: {
        Row: {
          id: string
          created_at: string
          updated_at: string
          client_id: string
          agent_id: string
          whatsapp_chat_id: string
          last_message: string
          last_message_at: string
          ai_summary: string
        }
        Insert: {
          id?: string
          created_at?: string
          updated_at?: string
          client_id: string
          agent_id: string
          whatsapp_chat_id: string
          last_message?: string
          last_message_at?: string
          ai_summary?: string
        }
        Update: {
          id?: string
          created_at?: string
          updated_at?: string
          client_id?: string
          agent_id?: string
          whatsapp_chat_id?: string
          last_message?: string
          last_message_at?: string
          ai_summary?: string
        }
      }
    }
  }
}