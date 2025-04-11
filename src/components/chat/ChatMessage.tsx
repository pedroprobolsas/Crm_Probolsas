import React from 'react';
import { format } from 'date-fns';
import { Check, CheckCheck, FileText, Download, File } from 'lucide-react';
import type { Message } from '../../lib/types';

interface ChatMessageProps {
  message: Message;
  isOwn: boolean;
}

// Función para formatear el tamaño del archivo
const formatFileSize = (bytes?: number): string => {
  if (!bytes) return '0 B';
  
  const units = ['B', 'KB', 'MB', 'GB'];
  let size = bytes;
  let unitIndex = 0;
  
  while (size >= 1024 && unitIndex < units.length - 1) {
    size /= 1024;
    unitIndex++;
  }
  
  return `${size.toFixed(1)} ${units[unitIndex]}`;
};

export function ChatMessage({ message, isOwn }: ChatMessageProps) {
  // Renderiza el contenido según el tipo de mensaje
  const renderContent = () => {
    switch (message.type) {
      case 'image':
        return (
          <div className="message-image">
            <img 
              src={message.content} 
              alt={message.file_name || 'Image'} 
              className="max-w-full rounded-lg cursor-pointer"
              onClick={() => window.open(message.content, '_blank')}
            />
            {message.file_name && (
              <div className="text-xs text-gray-500 mt-1">
                {message.file_name}
              </div>
            )}
          </div>
        );
        
      case 'pdf':
        return (
          <div className="message-pdf">
            <div className="flex items-center bg-gray-100 p-2 rounded-lg">
              <FileText className="w-8 h-8 text-red-500" />
              <div className="ml-2">
                <div className="text-sm font-medium">{message.file_name || 'PDF Document'}</div>
                {message.file_size && (
                  <div className="text-xs text-gray-500">
                    {formatFileSize(message.file_size)}
                  </div>
                )}
              </div>
            </div>
            <a 
              href={message.content} 
              target="_blank" 
              rel="noopener noreferrer"
              className="text-blue-500 text-xs mt-1 block"
            >
              Ver PDF
            </a>
          </div>
        );
        
      case 'audio':
        return (
          <div className="message-audio">
            <audio controls className="w-full max-w-[250px]">
              <source src={message.content} type="audio/mpeg" />
              Tu navegador no soporta el elemento de audio.
            </audio>
            {message.file_name && (
              <div className="text-xs text-gray-500 mt-1">
                {message.file_name}
              </div>
            )}
          </div>
        );
        
      case 'file':
        return (
          <div className="message-file">
            <div className="flex items-center bg-gray-100 p-2 rounded-lg">
              <File className="w-8 h-8 text-blue-500" />
              <div className="ml-2">
                <div className="text-sm font-medium">{message.file_name || 'Document'}</div>
                {message.file_size && (
                  <div className="text-xs text-gray-500">
                    {formatFileSize(message.file_size)}
                  </div>
                )}
              </div>
            </div>
            <a 
              href={message.content} 
              download={message.file_name}
              className="text-blue-500 text-xs mt-1 block"
            >
              <Download className="w-3 h-3 inline mr-1" />
              Descargar
            </a>
          </div>
        );
        
      default: // text
        return <p className="text-sm">{message.content}</p>;
    }
  };

  return (
    <div className={`flex ${isOwn ? 'justify-end' : 'justify-start'} mb-4`}>
      <div
        className={`max-w-[70%] rounded-2xl px-4 py-2 ${
          isOwn
            ? 'bg-[#dcf8c6] text-gray-800'
            : 'bg-white text-gray-800'
        }`}
      >
        {renderContent()}
        <div className={`flex items-center justify-end mt-1 text-xs text-gray-500`}>
          <span className="mr-1">
            {format(new Date(message.created_at), 'HH:mm')}
          </span>
          {isOwn && (
            message.status === 'read' ? (
              <CheckCheck className="w-3 h-3 text-blue-500" />
            ) : (
              <Check className="w-3 h-3" />
            )
          )}
        </div>
      </div>
    </div>
  );
}
