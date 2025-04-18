import { supabase } from '../supabase';
import { Message, Client } from '../types';

// URL de respaldo del webhook de IA
const IA_WEBHOOK_URL_FALLBACK = 'https://ippwebhookn8n.probolsas.co/webhook/d2d918c0-7132-43fe-9e8c-e07b033f2e6b';

/**
 * Servicio para enviar mensajes directamente al webhook de IA
 * 
 * Este servicio proporciona funciones para enviar mensajes al webhook de IA
 * directamente desde el frontend, sin depender de los triggers de la base de datos.
 */
export const iaWebhookService = {
  /**
   * Obtiene la URL del webhook de IA desde la configuración
   * @returns La URL del webhook de IA o una URL de respaldo si no se encuentra
   */
  async getWebhookUrl(): Promise<string> {
    try {
      const { data, error } = await supabase
        .from('app_settings')
        .select('value')
        .eq('key', 'webhook_url_ia_production')
        .single();
      
      if (error || !data) {
        console.warn('No se pudo obtener la URL del webhook de IA, usando URL de respaldo:', error);
        return IA_WEBHOOK_URL_FALLBACK;
      }
      
      return data.value;
    } catch (error) {
      console.error('Error al obtener la URL del webhook de IA:', error);
      return IA_WEBHOOK_URL_FALLBACK;
    }
  },
  
  /**
   * Envía un mensaje directamente al webhook de IA
   * @param message El mensaje a enviar
   * @param client Datos del cliente
   * @returns Resultado de la operación
   */
  async sendMessageToWebhook(message: Message, client: Client): Promise<{ success: boolean; error?: any }> {
    try {
      // Obtener la URL del webhook
      const webhookUrl = await this.getWebhookUrl();
      
      // Preparar el payload para el webhook
      const payload = {
        id: message.id,
        conversation_id: message.conversation_id,
        content: message.content,
        sender: message.sender,
        sender_id: message.sender_id,
        type: message.type || 'text',
        status: message.status,
        created_at: message.created_at,
        asistente_ia_activado: message.asistente_ia_activado,
        phone: client.phone,
        client: client,
        source: 'frontend_direct' // Añadir fuente para depuración
      };
      
      console.log('Enviando mensaje directamente al webhook de IA:', payload);
      
      // Enviar al webhook de IA
      const response = await fetch(webhookUrl, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json'
        },
        body: JSON.stringify(payload)
      });
      
      if (!response.ok) {
        const errorText = await response.text();
        throw new Error(`Error al enviar al webhook de IA: ${response.status} ${errorText}`);
      }
      
      console.log('Mensaje enviado correctamente al webhook de IA desde el frontend');
      
      // Marcar el mensaje como enviado al webhook
      await this.markMessageAsSent(message.id);
      
      return { success: true };
    } catch (error) {
      console.error('Error al enviar mensaje al webhook de IA:', error);
      return { success: false, error };
    }
  },
  
  /**
   * Marca un mensaje como enviado al webhook de IA
   * @param messageId ID del mensaje
   */
  async markMessageAsSent(messageId: string): Promise<void> {
    try {
      const { error } = await supabase
        .from('messages')
        .update({ ia_webhook_sent: true })
        .eq('id', messageId);
      
      if (error) {
        console.error('Error al marcar el mensaje como enviado al webhook:', error);
      }
    } catch (error) {
      console.error('Error al actualizar el estado del mensaje:', error);
    }
  }
};
