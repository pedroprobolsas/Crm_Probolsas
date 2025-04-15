import React, { useState } from 'react';

interface IAAssistantButtonProps {
  isActive: boolean;
  onChange: (active: boolean) => void;
  className?: string;
  isLoading?: boolean;
}

/**
 * Botón para activar/desactivar el asistente de IA en el chat
 * 
 * Este componente muestra un botón que permite al usuario activar o desactivar
 * el asistente de IA antes de enviar un mensaje. Cuando está activado, el mensaje
 * se enviará con asistente_ia_activado=true, lo que hará que el backend envíe
 * el mensaje al webhook de IA.
 * 
 * @param isActive Estado actual del botón (activado/desactivado)
 * @param onChange Función que se llama cuando el usuario cambia el estado del botón
 * @param className Clases CSS adicionales para el botón
 */
const IAAssistantButton: React.FC<IAAssistantButtonProps> = ({
  isActive,
  onChange,
  className = '',
  isLoading = false,
}) => {
  // Determinar las clases CSS según el estado
  const baseClasses = 'flex items-center px-3 py-2 rounded-md text-sm font-medium transition-colors';
  const activeClasses = 'bg-blue-600 text-white hover:bg-blue-700';
  const inactiveClasses = 'bg-gray-200 text-gray-700 hover:bg-gray-300';
  const loadingClasses = 'opacity-75 cursor-wait';
  
  const buttonClasses = `${baseClasses} ${isActive ? activeClasses : inactiveClasses} ${isLoading ? loadingClasses : ''} ${className}`;

  return (
    <button
      type="button"
      className={buttonClasses}
      onClick={() => !isLoading && onChange(!isActive)}
      aria-pressed={isActive}
      disabled={isLoading}
      title={isLoading ? "Actualizando estado del Asistente IA..." : isActive ? "Desactivar Asistente IA" : "Activar Asistente IA"}
    >
      {isLoading ? (
        // Indicador de carga
        <svg 
          className="animate-spin h-5 w-5 mr-2 text-current" 
          xmlns="http://www.w3.org/2000/svg" 
          fill="none" 
          viewBox="0 0 24 24"
        >
          <circle 
            className="opacity-25" 
            cx="12" 
            cy="12" 
            r="10" 
            stroke="currentColor" 
            strokeWidth="4"
          ></circle>
          <path 
            className="opacity-75" 
            fill="currentColor" 
            d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"
          ></path>
        </svg>
      ) : (
        // Icono normal
        <svg 
          xmlns="http://www.w3.org/2000/svg" 
          className={`h-5 w-5 mr-2 ${isActive ? 'text-white' : 'text-gray-600'}`} 
          fill="none" 
          viewBox="0 0 24 24" 
          stroke="currentColor"
        >
          <path 
            strokeLinecap="round" 
            strokeLinejoin="round" 
            strokeWidth={2} 
            d="M9.663 17h4.673M12 3v1m6.364 1.636l-.707.707M21 12h-1M4 12H3m3.343-5.657l-.707-.707m2.828 9.9a5 5 0 117.072 0l-.548.547A3.374 3.374 0 0014 18.469V19a2 2 0 11-4 0v-.531c0-.895-.356-1.754-.988-2.386l-.548-.547z" 
          />
        </svg>
      )}
      {isActive ? 'Asistente IA Activado' : 'Activar Asistente IA'}
    </button>
  );
};

export default IAAssistantButton;
