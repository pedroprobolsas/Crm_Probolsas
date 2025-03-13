import { useState } from 'react';
import type { Conversation, Message } from '../types';

const mockConversations: Conversation[] = [
  {
    id: '1',
    created_at: new Date(2024, 1, 15).toISOString(),
    updated_at: new Date().toISOString(),
    client_id: '1',
    agent_id: '1',
    whatsapp_chat_id: '1',
    last_message: '¿Podrían enviarme una cotización para 1000 cajas?',
    last_message_at: new Date().toISOString(),
    client_name: 'Juan Pérez',
    client_company: 'Distribuidora El Sol',
    unread_count: 3,
  },
  {
    id: '2',
    created_at: new Date(2024, 1, 14).toISOString(),
    updated_at: new Date().toISOString(),
    client_id: '2',
    agent_id: '1',
    whatsapp_chat_id: '2',
    last_message: 'Gracias por la información',
    last_message_at: new Date(Date.now() - 3600000).toISOString(),
    client_name: 'María González',
    client_company: 'Supermercados MG',
    unread_count: 0,
  },
  {
    id: '3',
    created_at: new Date(2024, 1, 13).toISOString(),
    updated_at: new Date().toISOString(),
    client_id: '3',
    agent_id: '1',
    whatsapp_chat_id: '3',
    last_message: 'El pedido llegó en perfectas condiciones',
    last_message_at: new Date(Date.now() - 7200000).toISOString(),
    client_name: 'Carlos Rodríguez',
    client_company: 'Importadora CR',
    unread_count: 1,
  },
];

const mockMessages: Record<string, Message[]> = {
  '1': [
    {
      id: '1',
      conversation_id: '1',
      content: 'Buenos días, necesito información sobre sus empaques ecológicos',
      sender: 'client',
      sender_id: '1',
      created_at: new Date(Date.now() - 3600000).toISOString(),
      status: 'read',
      type: 'text',
    },
    {
      id: '2',
      conversation_id: '1',
      content: '¡Hola! Con gusto te ayudo. Contamos con una línea completa de empaques biodegradables',
      sender: 'agent',
      sender_id: 'agent1',
      created_at: new Date(Date.now() - 3500000).toISOString(),
      status: 'read',
      type: 'text',
    },
    {
      id: '3',
      conversation_id: '1',
      content: 'https://images.unsplash.com/photo-1589365278144-c9e705f843ba?w=800',
      sender: 'agent',
      sender_id: 'agent1',
      created_at: new Date(Date.now() - 3400000).toISOString(),
      status: 'read',
      type: 'image',
      file_url: 'https://images.unsplash.com/photo-1589365278144-c9e705f843ba?w=800',
      file_name: 'eco-packaging.jpg',
    },
    {
      id: '4',
      conversation_id: '1',
      content: 'Excelente, ¿podrían enviarme una cotización para 1000 cajas?',
      sender: 'client',
      sender_id: '1',
      created_at: new Date(Date.now() - 3300000).toISOString(),
      status: 'read',
      type: 'text',
    },
  ],
  '2': [
    {
      id: '5',
      conversation_id: '2',
      content: 'Adjunto el catálogo actualizado',
      sender: 'agent',
      sender_id: 'agent1',
      created_at: new Date(Date.now() - 7200000).toISOString(),
      status: 'read',
      type: 'file',
      file_url: '#',
      file_name: 'catalogo-2024.pdf',
      file_size: 2500000,
    },
    {
      id: '6',
      conversation_id: '2',
      content: 'Gracias por la información',
      sender: 'client',
      sender_id: '2',
      created_at: new Date(Date.now() - 7100000).toISOString(),
      status: 'read',
      type: 'text',
    },
  ],
  '3': [
    {
      id: '7',
      conversation_id: '3',
      content: 'El pedido llegó en perfectas condiciones',
      sender: 'client',
      sender_id: '3',
      created_at: new Date(Date.now() - 1800000).toISOString(),
      status: 'delivered',
      type: 'text',
    },
  ],
};

const mockAISuggestions = [
  'Con gusto te preparo la cotización. ¿Necesitas algún tamaño específico para las cajas?',
  'Te envío nuestra lista de precios actualizada para cajas ecológicas.',
  '¿Te gustaría programar una llamada para discutir los detalles del pedido?',
];

export function useMockData() {
  const [conversations] = useState<Conversation[]>(mockConversations);
  const [messages] = useState<Record<string, Message[]>>(mockMessages);
  const [aiSuggestions] = useState<string[]>(mockAISuggestions);

  const getConversationMessages = (conversationId: string): Message[] => {
    return messages[conversationId] || [];
  };

  return {
    conversations,
    getConversationMessages,
    aiSuggestions,
  };
}