import React, { useState, useEffect } from 'react';
import { supabase } from '../../lib/supabase';
import { ChatMessage } from './ChatMessage';
import { ChatInputWithIA } from './ChatInputWithIA';
import type { Message } from '../../lib/types';
import { useIAAssistantState } from '../../lib/hooks/useIAAssistantState';
import { toast } from 'sonner';

interface ChatWithIAProps {
  conversationId: string;
  clientId: string;
}

/**
 * Componente de chat con soporte para el asistente de IA
 * 
 * Este componente muestra un chat completo con soporte para el asistente de IA.
 * Permite al usuario enviar mensajes con el asistente de IA activado, lo que
 * hará que el backend envíe el mensaje al webhook de IA.
 * 
 * @param conversationId ID de la conversación
 * @param clientId ID del cliente
 */
export function ChatWithIA({ conversationId, clientId }: ChatWithIAProps) {
  const [messages, setMessages] = useState<Message[]>([]);
  const [isLoading, setIsLoading] = useState(false);
  
  // Obtener el estado del Asistente IA para esta conversación
  const { isEnabled: iaAssistantEnabled } = useIAAssistantState(conversationId);

  // Cargar mensajes al montar el componente
  useEffect(() => {
    loadMessages();
    
    // Suscribirse a nuevos mensajes
    const subscription = supabase
      .channel('messages')
      .on('postgres_changes', {
        event: 'INSERT',
        schema: 'public',
        table: 'messages',
        filter: `conversation_id=eq.${conversationId}`
      }, (payload) => {
        const newMessage = payload.new as Message;
        setMessages(prev => [...prev, newMessage]);
      })
      .subscribe();
    
    return () => {
      subscription.unsubscribe();
    };
  }, [conversationId]);

  // Cargar mensajes de la conversación
  const loadMessages = async () => {
    try {
      const { data, error } = await supabase
        .from('messages')
        .select('*')
        .eq('conversation_id', conversationId)
        .order('created_at', { ascending: true });
      
      if (error) throw error;
      setMessages(data || []);
    } catch (error) {
      console.error('Error loading messages:', error);
    }
  };

  // Enviar un mensaje de texto
  const handleSendMessage = async (content: string, iaAssistantActive: boolean) => {
    if (!content.trim()) return;
    
    setIsLoading(true);
    
    try {
      // Verificar si ya existe un mensaje idéntico para evitar duplicados
      const { data: existingMessages } = await supabase
        .from('messages')
        .select('id')
        .eq('conversation_id', conversationId)
        .eq('content', content.trim())
        .eq('sender', 'client')
        .eq('sender_id', clientId)
        .gte('created_at', new Date(Date.now() - 5000).toISOString()) // Mensajes de los últimos 5 segundos
        .order('created_at', { ascending: false });
      
      if (existingMessages && existingMessages.length > 0) {
        console.log('Mensaje duplicado detectado, no se enviará de nuevo:', existingMessages[0].id);
        return;
      }
      
      // Usar el estado local proporcionado por el componente ChatInputWithIA,
      // pero verificar si el estado global está desactivado
      if (!iaAssistantEnabled && iaAssistantActive) {
        toast.info('El Asistente IA ha sido desactivado globalmente');
        iaAssistantActive = false;
      }
      
      const newMessage = {
        conversation_id: conversationId,
        content,
        sender: 'client',
        sender_id: clientId,
        type: 'text',
        status: 'sent',
        asistente_ia_activado: iaAssistantActive
      };
      
      const { error } = await supabase
        .from('messages')
        .insert(newMessage);
      
      if (error) throw error;
      
      // No necesitamos añadir el mensaje manualmente aquí
      // porque la suscripción lo hará automáticamente
    } catch (error) {
      console.error('Error sending message:', error);
    } finally {
      setIsLoading(false);
    }
  };

  // Enviar un archivo
  const handleSendFile = async (file: File) => {
    setIsLoading(true);
    
    try {
      // Determinar el tipo de mensaje basado en el tipo de archivo
      let messageType = 'file';
      if (file.type.startsWith('image/')) {
        messageType = 'image';
      } else if (file.type === 'application/pdf') {
        messageType = 'pdf';
      } else if (file.type.startsWith('audio/')) {
        messageType = 'audio';
      }
      
      // Subir el archivo a Supabase Storage
      const fileName = `${Date.now()}_${file.name}`;
      const { data: fileData, error: uploadError } = await supabase
        .storage
        .from('media')
        .upload(`conversations/${conversationId}/${fileName}`, file);
      
      if (uploadError) throw uploadError;
      
      // Obtener la URL pública del archivo
      const { data: urlData } = await supabase
        .storage
        .from('media')
        .getPublicUrl(`conversations/${conversationId}/${fileName}`);
      
      // Crear el mensaje con la URL del archivo
      const newMessage = {
        conversation_id: conversationId,
        content: urlData.publicUrl,
        sender: 'client',
        sender_id: clientId,
        type: messageType,
        status: 'sent',
        file_name: file.name,
        file_size: file.size,
        asistente_ia_activado: false // Los archivos no usan el asistente de IA
      };
      
      const { error: messageError } = await supabase
        .from('messages')
        .insert(newMessage);
      
      if (messageError) throw messageError;
    } catch (error) {
      console.error('Error sending file:', error);
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <div className="flex flex-col h-full">
      <div className="flex-1 overflow-y-auto p-4">
        {messages.map((message) => (
          <ChatMessage
            key={message.id}
            message={message}
            isOwn={message.sender === 'client'}
          />
        ))}
      </div>
      
      <ChatInputWithIA
        onSend={handleSendMessage}
        onSendFile={handleSendFile}
        isLoading={isLoading}
        conversationId={conversationId}
      />
    </div>
  );
}
