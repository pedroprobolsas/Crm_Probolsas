import React from 'react';
import { Bot } from 'lucide-react';

interface AISuggestionsProps {
  suggestions: string[];
  onSelect: (suggestion: string) => void;
  isLoading?: boolean;
}

export function AISuggestions({ suggestions, onSelect, isLoading }: AISuggestionsProps) {
  if (isLoading) {
    return (
      <div className="bg-blue-50 p-4 rounded-lg mb-4">
        <div className="flex items-center mb-2">
          <Bot className="w-5 h-5 text-blue-600 mr-2" />
          <p className="text-sm font-medium text-blue-900">Generando sugerencias...</p>
        </div>
      </div>
    );
  }

  if (!suggestions.length) return null;

  return (
    <div className="bg-blue-50 p-4 rounded-lg mb-4">
      <div className="flex items-center mb-2">
        <Bot className="w-5 h-5 text-blue-600 mr-2" />
        <p className="text-sm font-medium text-blue-900">Sugerencias de IA</p>
      </div>
      <div className="space-y-2">
        {suggestions.map((suggestion, index) => (
          <button
            key={index}
            onClick={() => onSelect(suggestion)}
            className="block w-full text-left text-sm bg-white p-2 rounded border border-blue-200 hover:bg-blue-50 transition-colors"
          >
            {suggestion}
          </button>
        ))}
      </div>
    </div>
  );
}