import React, { useState, useRef } from 'react';
import { Send, Paperclip, Smile } from 'lucide-react';
import { FileUploader } from './FileUploader';

interface ChatInputProps {
  onSend: (message: string) => void;
  onSendFile?: (file: File) => void;
  isLoading?: boolean;
}

export function ChatInput({ onSend, onSendFile, isLoading }: ChatInputProps) {
  const [message, setMessage] = useState('');
  const [showFileUploader, setShowFileUploader] = useState(false);
  const inputRef = useRef<HTMLInputElement>(null);

  const handleSend = () => {
    if (message.trim() && !isLoading) {
      onSend(message.trim());
      setMessage('');
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
            placeholder="Escribe un mensaje"
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
