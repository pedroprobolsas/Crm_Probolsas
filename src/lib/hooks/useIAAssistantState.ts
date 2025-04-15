import { useState, useEffect } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { supabase } from '../supabase';
import { toast } from 'sonner';

/**
 * Hook para gestionar el estado del Asistente IA por conversación
 * 
 * Este hook permite:
 * - Consultar el estado actual del Asistente IA para una conversación específica
 * - Suscribirse a cambios en tiempo real
 * - Actualizar el estado manualmente
 * - Manejar errores y estados de carga
 * 
 * @param conversationId ID de la conversación para la que se quiere gestionar el estado
 * @returns Un objeto con el estado actual, funciones para actualizarlo y estados de carga/error
 */
export function useIAAssistantState(conversationId: string) {
  const queryClient = useQueryClient();
  const [isSubscribed, setIsSubscribed] = useState(false);

  // Validar que se proporcionó un ID de conversación
  if (!conversationId) {
    console.error('useIAAssistantState: Se requiere un ID de conversación');
  }

  // Consultar el estado actual
  const query = useQuery({
    queryKey: ['iaAssistantState', conversationId],
    queryFn: async () => {
      try {
        if (!conversationId) return true; // Valor predeterminado si no hay ID
        
        // Intentar obtener el estado desde la función personalizada
        const { data: functionData, error: functionError } = await supabase
          .rpc('get_conversation_ia_state', { conversation_uuid: conversationId });
        
        if (!functionError && functionData) {
          console.log('Estado del Asistente IA obtenido desde función:', functionData);
          return functionData.state;
        }
        
        // Si la función falla, intentar consultar directamente la tabla
        console.log('Fallback: consultando directamente conversation_settings');
        const { data, error } = await supabase
          .from('conversation_settings')
          .select('ia_assistant_enabled')
          .eq('conversation_id', conversationId)
          .single();
        
        if (error) {
          console.error('Error al obtener el estado del Asistente IA:', error);
          
          // Si el error es porque no existe el registro, crear uno con valor predeterminado
          if (error.code === 'PGRST116') { // No data found
            console.log('No se encontró configuración para esta conversación, creando una nueva');
            const { data: newData, error: insertError } = await supabase
              .from('conversation_settings')
              .insert({ conversation_id: conversationId, ia_assistant_enabled: true })
              .select('ia_assistant_enabled')
              .single();
              
            if (insertError) {
              console.error('Error al crear configuración:', insertError);
              return true; // Valor predeterminado en caso de error
            }
            
            return newData.ia_assistant_enabled;
          }
          
          // Otro tipo de error
          return true; // Valor predeterminado en caso de error
        }
        
        return data.ia_assistant_enabled;
      } catch (error) {
        console.error('Error inesperado al obtener el estado del Asistente IA:', error);
        // Valor predeterminado en caso de error
        return true;
      }
    },
    // Configuración para actualizaciones
    enabled: !!conversationId, // Solo ejecutar si hay un ID de conversación
    refetchInterval: 30000, // Refrescar cada 30 segundos como respaldo
    refetchOnWindowFocus: true,
    refetchOnMount: true,
    refetchOnReconnect: true,
    retry: 3, // Reintentar 3 veces en caso de error
  });

  // Mutación para actualizar el estado
  const updateState = useMutation({
    mutationFn: async (newState: boolean) => {
      try {
        if (!conversationId) {
          throw new Error('Se requiere un ID de conversación para actualizar el estado');
        }
        
        // Intentar actualizar usando la función personalizada
        const { data: functionData, error: functionError } = await supabase
          .rpc('update_conversation_ia_state', { 
            conversation_uuid: conversationId,
            new_state: newState,
            update_reason: 'Actualización manual desde la aplicación'
          });
        
        if (functionError) {
          throw functionError;
        }
        
        return functionData;
      } catch (error) {
        console.error('Error al actualizar el estado del Asistente IA:', error);
        
        // Intentar actualizar directamente como fallback
        try {
          // Verificar si existe un registro para esta conversación
          const { data: existingData, error: checkError } = await supabase
            .from('conversation_settings')
            .select('id')
            .eq('conversation_id', conversationId)
            .single();
            
          if (checkError && checkError.code === 'PGRST116') { // No data found
            // Si no existe, crear uno
            const { data: insertData, error: insertError } = await supabase
              .from('conversation_settings')
              .insert({ 
                conversation_id: conversationId, 
                ia_assistant_enabled: newState 
              })
              .select();
              
            if (insertError) throw insertError;
            
            return { success: true, new_state: newState, conversation_id: conversationId };
          } else if (checkError) {
            throw checkError;
          }
          
          // Si existe, actualizar
          const { error: updateError } = await supabase
            .from('conversation_settings')
            .update({ 
              ia_assistant_enabled: newState,
              updated_at: new Date().toISOString()
            })
            .eq('conversation_id', conversationId);
          
          if (updateError) throw updateError;
          
          return { success: true, new_state: newState, conversation_id: conversationId };
        } catch (fallbackError) {
          console.error('Error en fallback al actualizar el estado:', fallbackError);
          throw fallbackError;
        }
      }
    },
    onSuccess: (data) => {
      console.log('Estado del Asistente IA actualizado:', data);
      queryClient.invalidateQueries({ queryKey: ['iaAssistantState', conversationId] });
      toast.success(`Asistente IA ${data.new_state ? 'activado' : 'desactivado'} para esta conversación`);
    },
    onError: (error) => {
      console.error('Error en mutación del estado del Asistente IA:', error);
      toast.error('Error al actualizar el estado del Asistente IA');
    },
  });

  // Suscribirse a cambios en tiempo real
  useEffect(() => {
    if (isSubscribed || !conversationId) return;

    try {
      console.log(`Suscribiéndose a cambios en conversation_settings para conversación: ${conversationId}`);
      
      const subscription = supabase
        .channel(`conversation_settings_${conversationId}`)
        .on(
          'postgres_changes',
          {
            event: 'UPDATE',
            schema: 'public',
            table: 'conversation_settings',
            filter: `conversation_id=eq.${conversationId}`,
          },
          (payload) => {
            console.log('Cambio detectado en conversation_settings:', payload);
            
            // Verificar si el valor realmente cambió
            const newValue = payload.new.ia_assistant_enabled;
            const oldValue = payload.old.ia_assistant_enabled;
            
            if (newValue !== oldValue) {
              // Actualizar la caché de React Query
              queryClient.invalidateQueries({ queryKey: ['iaAssistantState', conversationId] });
              
              // Mostrar notificación al usuario
              toast.info(`El estado del Asistente IA ha sido ${newValue ? 'activado' : 'desactivado'} externamente para esta conversación`);
            }
          }
        )
        .subscribe((status) => {
          console.log(`Estado de suscripción a conversation_settings: ${status}`);
          setIsSubscribed(true);
        });

      return () => {
        console.log(`Cancelando suscripción a conversation_settings para conversación: ${conversationId}`);
        subscription.unsubscribe();
        setIsSubscribed(false);
      };
    } catch (error) {
      console.error('Error al suscribirse a cambios en conversation_settings:', error);
      setIsSubscribed(false);
      return undefined;
    }
  }, [queryClient, isSubscribed, conversationId]);

  return {
    isEnabled: query.data ?? true, // Valor predeterminado: true
    setEnabled: updateState.mutate,
    isLoading: query.isLoading || updateState.isPending,
    error: query.error || updateState.error,
    isSubscribed,
    conversationId, // Devolver el ID de conversación para referencia
  };
}
