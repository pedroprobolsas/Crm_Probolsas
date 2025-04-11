import { supabase } from '../supabase';

// Function to generate a unique ID using Web Crypto API
function generateUniqueId() {
  // Create a random array of 16 bytes (128 bits)
  const array = new Uint8Array(16);
  window.crypto.getRandomValues(array);
  
  // Convert to hex string
  return Array.from(array, byte => byte.toString(16).padStart(2, '0')).join('');
}

/**
 * Sube un archivo a Supabase Storage y devuelve la información del archivo
 * @param file Archivo a subir
 * @param conversationId ID de la conversación
 * @returns Información del archivo subido (url, nombre, tamaño, tipo)
 */
export async function uploadFileToSupabase(file: File, conversationId: string) {
  try {
    // Validar el tamaño del archivo (máximo 10MB)
    if (file.size > 10 * 1024 * 1024) {
      throw new Error('El archivo excede el tamaño máximo permitido (10MB)');
    }

    // Generar un nombre único para el archivo
    const fileExt = file.name.split('.').pop();
    const uniqueId = generateUniqueId();
    const fileName = `${uniqueId}-${Date.now()}.${fileExt}`;
    const filePath = `chat-files/${conversationId}/${fileName}`;
    
    // Subir el archivo a Supabase Storage
    const { data, error } = await supabase.storage
      .from('media')
      .upload(filePath, file, {
        cacheControl: '3600',
        upsert: false
      });
      
    if (error) throw error;
    
    // Obtener la URL pública del archivo
    const { data: { publicUrl } } = supabase.storage
      .from('media')
      .getPublicUrl(filePath);
      
    return {
      url: publicUrl,
      name: file.name,
      size: file.size,
      type: file.type
    };
  } catch (error) {
    console.error('Error al subir archivo:', error);
    throw error;
  }
}

/**
 * Determina el tipo de mensaje basado en el MIME type del archivo
 * @param fileType MIME type del archivo
 * @returns Tipo de mensaje ('image', 'audio', 'pdf', 'file')
 */
export function getMessageTypeFromFile(fileType: string): 'image' | 'audio' | 'pdf' | 'file' {
  if (fileType.startsWith('image/')) return 'image';
  if (fileType.startsWith('audio/')) return 'audio';
  if (fileType === 'application/pdf') return 'pdf';
  return 'file';
}

/**
 * Formatea el tamaño del archivo en unidades legibles
 * @param bytes Tamaño en bytes
 * @returns Tamaño formateado (ej: "2.5 MB")
 */
export function formatFileSize(bytes?: number): string {
  if (!bytes) return '0 B';
  
  const units = ['B', 'KB', 'MB', 'GB'];
  let size = bytes;
  let unitIndex = 0;
  
  while (size >= 1024 && unitIndex < units.length - 1) {
    size /= 1024;
    unitIndex++;
  }
  
  return `${size.toFixed(1)} ${units[unitIndex]}`;
}
