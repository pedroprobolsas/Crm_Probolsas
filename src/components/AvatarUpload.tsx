import React, { useState } from 'react';
import { Upload, X, Camera } from 'lucide-react';
import { supabase } from '../lib/supabase';
import { toast } from 'sonner';

interface AvatarUploadProps {
  agentId: string;
  currentAvatar?: string | null;
  onUpload: (avatarUrl: string) => void;
  onClose: () => void;
}

export function AvatarUpload({ agentId, currentAvatar, onUpload, onClose }: AvatarUploadProps) {
  const [uploading, setUploading] = useState(false);
  const [preview, setPreview] = useState<string | null>(currentAvatar || null);

  const uploadAvatar = async (file: File) => {
    try {
      setUploading(true);

      // Delete existing avatar if any
      if (currentAvatar) {
        const oldPath = currentAvatar.split('/').pop();
        if (oldPath) {
          await supabase.storage
            .from('agent-avatars')
            .remove([oldPath]);
        }
      }

      // Create a unique file name
      const fileExt = file.name.split('.').pop();
      const fileName = `${agentId}-${Math.random().toString(36).substring(2)}.${fileExt}`;

      // Upload the file
      const { error: uploadError } = await supabase.storage
        .from('agent-avatars')
        .upload(fileName, file, {
          cacheControl: '3600',
          upsert: true
        });

      if (uploadError) throw uploadError;

      // Get the public URL
      const { data: { publicUrl } } = supabase.storage
        .from('agent-avatars')
        .getPublicUrl(fileName);

      // Update the agent's avatar URL in the database
      const { error: updateError } = await supabase
        .from('agents')
        .update({ avatar: publicUrl })
        .eq('id', agentId);

      if (updateError) throw updateError;

      onUpload(publicUrl);
      toast.success('Avatar actualizado exitosamente');
      onClose();
    } catch (error) {
      console.error('Error uploading avatar:', error);
      toast.error('Error al subir el avatar');
    } finally {
      setUploading(false);
    }
  };

  const handleFileChange = async (e: React.ChangeEvent<HTMLInputElement>) => {
    if (!e.target.files || e.target.files.length === 0) return;

    const file = e.target.files[0];
    if (!file.type.startsWith('image/')) {
      toast.error('Por favor selecciona una imagen');
      return;
    }

    if (file.size > 5 * 1024 * 1024) { // 5MB limit
      toast.error('La imagen debe ser menor a 5MB');
      return;
    }

    // Show preview
    const reader = new FileReader();
    reader.onloadend = () => {
      setPreview(reader.result as string);
    };
    reader.readAsDataURL(file);

    await uploadAvatar(file);
  };

  return (
    <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
      <div className="bg-white rounded-lg p-6 w-full max-w-md">
        <div className="flex justify-between items-center mb-4">
          <h3 className="text-lg font-semibold text-gray-900">
            Actualizar Avatar
          </h3>
          <button
            onClick={onClose}
            className="text-gray-400 hover:text-gray-500"
          >
            <X className="w-6 h-6" />
          </button>
        </div>

        <div className="space-y-4">
          {/* Avatar Preview */}
          <div className="flex flex-col items-center">
            <div className="relative w-32 h-32 mb-4">
              {preview ? (
                <img
                  src={preview}
                  alt="Avatar preview"
                  className="w-full h-full rounded-full object-cover"
                />
              ) : (
                <div className="w-full h-full rounded-full bg-gray-200 flex items-center justify-center">
                  <Camera className="w-8 h-8 text-gray-400" />
                </div>
              )}
            </div>

            {/* Upload Button */}
            <label className="cursor-pointer inline-flex items-center px-4 py-2 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-blue-600 hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 disabled:opacity-50">
              <Upload className="w-5 h-5 mr-2" />
              {uploading ? 'Subiendo...' : 'Seleccionar Imagen'}
              <input
                type="file"
                className="hidden"
                accept="image/*"
                onChange={handleFileChange}
                disabled={uploading}
              />
            </label>
          </div>

          <div className="text-sm text-gray-500 text-center">
            <p>Formatos permitidos: JPG, PNG, GIF</p>
            <p>Tamaño máximo: 5MB</p>
          </div>
        </div>
      </div>
    </div>
  );
}