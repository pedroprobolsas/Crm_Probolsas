import React, { useState, useRef, useEffect } from 'react';
import { Send, Paperclip, Smile } from 'lucide-react';
import { FileUploader } from './FileUploader';
import IAAssistantButton from './IAAssistantButton';
import { useIAAssistantState } from '../../lib/hooks/useIAAssistantState';

interface ChatInputWithIAProps {
  onSend: (message: string, iaAssistantActive: boolean) => void;
  onSendFile?: (file: File) => void;
  isLoading?: boolean;
  conversationId: string; // Añadir ID de conversación como prop
}

/**
 * Componente de entrada de chat con soporte para el asistente de IA
 * 
 * Este componente extiende el ChatInput original para incluir un botón
 * que permite activar/desactivar el asistente de IA antes de enviar un mensaje.
 * 
 * @param onSend Función que se llama cuando el usuario envía un mensaje
 * @param onSendFile Función que se llama cuando el usuario envía un archivo
 * @param isLoading Indica si se está procesando una acción
 */
export function ChatInputWithIA({ onSend, onSendFile, isLoading, conversationId }: ChatInputWithIAProps) {
  const [message, setMessage] = useState('');
  const [showFileUploader, setShowFileUploader] = useState(false);
  const [localIaAssistantActive, setLocalIaAssistantActive] = useState(true);
  const inputRef = useRef<HTMLInputElement>(null);
  
  // Obtener el estado del Asistente IA para esta conversación
  const { 
    isEnabled: conversationIaAssistantEnabled, 
    setEnabled: setConversationIaAssistantEnabled,
    isLoading: isIaStateLoading 
  } = useIAAssistantState(conversationId);
  
  // Sincronizar el estado local con el de la conversación
  useEffect(() => {
    setLocalIaAssistantActive(conversationIaAssistantEnabled);
  }, [conversationIaAssistantEnabled]);
  
  // Manejar cambios en el estado del botón
  const handleIaAssistantChange = (active: boolean) => {
    setLocalIaAssistantActive(active);
    // Actualizar el estado de la conversación si el usuario lo cambia manualmente
    setConversationIaAssistantEnabled(active);
  };

  const handleSend = () => {
    if (message.trim() && !isLoading) {
      // Usar el estado local para enviar el mensaje
      onSend(message.trim(), localIaAssistantActive);
      setMessage('');
      // No reseteamos el estado del asistente IA para que permanezca activado
      // hasta que el usuario decida desactivarlo manualmente
    }
  };

  const handleKeyPress = (e: React.KeyboardEvent) => {
    if (e.key === 'Enter' && !e.shiftKey) {
      e.preventDefault();
      handleSend();
    }
  };

  const handleAttach = () => {
    setShowFileUploader(true);
  };

  const handleFileUpload = (files: File[]) => {
    if (files.length > 0 && onSendFile) {
      // Solo enviamos el primer archivo seleccionado
      onSendFile(files[0]);
    }
    setShowFileUploader(false);
  };

  const handleCloseUploader = () => {
    setShowFileUploader(false);
  };

  return (
    <div className="relative">
      {showFileUploader && (
        <FileUploader 
          onUpload={handleFileUpload} 
          onClose={handleCloseUploader} 
        />
      )}
      
      <div className="bg-white border-t border-gray-200 p-4">
        {/* Botón de Asistente IA */}
        <div className="mb-3">
          <IAAssistantButton 
            isActive={localIaAssistantActive} 
            onChange={handleIaAssistantChange}
            isLoading={isIaStateLoading}
          />
        </div>
        
        <div className="flex items-center space-x-4">
          {onSendFile && (
            <button 
              onClick={handleAttach}
              className="text-gray-500 hover:text-gray-700"
              disabled={isLoading}
            >
              <Paperclip className="w-5 h-5" />
            </button>
          )}
          
          <input
            ref={inputRef}
            type="text"
            value={message}
            onChange={(e) => setMessage(e.target.value)}
            onKeyPress={handleKeyPress}
            placeholder={localIaAssistantActive ? "Escribe un mensaje (Asistente IA activado)" : "Escribe un mensaje"}
            className="flex-1 border-0 focus:ring-0 text-sm"
            disabled={isLoading}
          />
          
          <button 
            className="text-gray-500 hover:text-gray-700"
          >
            <Smile className="w-5 h-5" />
          </button>
          
          <button
            onClick={handleSend}
            disabled={!message.trim() || isLoading}
            className="bg-blue-600 text-white p-2 rounded-full hover:bg-blue-700 disabled:opacity-50 disabled:hover:bg-blue-600"
          >
            <Send className="w-5 h-5" />
          </button>
        </div>
      </div>
    </div>
  );
}
