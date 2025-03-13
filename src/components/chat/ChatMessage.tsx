import React from 'react';
import { format } from 'date-fns';
import { Check, CheckCheck } from 'lucide-react';
import type { Message } from '../../lib/types';

interface ChatMessageProps {
  message: Message;
  isOwn: boolean;
}

export function ChatMessage({ message, isOwn }: ChatMessageProps) {
  return (
    <div className={`flex ${isOwn ? 'justify-end' : 'justify-start'} mb-4`}>
      <div
        className={`max-w-[70%] rounded-2xl px-4 py-2 ${
          isOwn
            ? 'bg-[#dcf8c6] text-gray-800'
            : 'bg-white text-gray-800'
        }`}
      >
        <p className="text-sm">{message.content}</p>
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