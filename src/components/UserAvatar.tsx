import React, { useState } from 'react';
import { User } from 'lucide-react';
import { useAuthStore } from '../lib/store/authStore';
import { AvatarUpload } from './AvatarUpload';

interface UserAvatarProps {
  size?: 'sm' | 'md' | 'lg';
  showUpload?: boolean;
}

export function UserAvatar({ size = 'md', showUpload = true }: UserAvatarProps) {
  const [showUploadModal, setShowUploadModal] = useState(false);
  const { user } = useAuthStore();
  const [avatarUrl, setAvatarUrl] = useState<string | null>(null);

  const sizeClasses = {
    sm: 'w-8 h-8',
    md: 'w-10 h-10',
    lg: 'w-12 h-12'
  };

  const handleAvatarClick = () => {
    if (showUpload) {
      setShowUploadModal(true);
    }
  };

  const handleAvatarUpload = (url: string) => {
    setAvatarUrl(url);
  };

  return (
    <>
      <button
        onClick={handleAvatarClick}
        className={`relative rounded-full overflow-hidden bg-gray-100 hover:opacity-90 transition-opacity ${sizeClasses[size]}`}
      >
        {avatarUrl ? (
          <img
            src={avatarUrl}
            alt="User avatar"
            className="w-full h-full object-cover"
          />
        ) : (
          <div className="w-full h-full flex items-center justify-center bg-gray-100">
            <User className={`text-gray-600 ${size === 'sm' ? 'w-4 h-4' : 'w-6 h-6'}`} />
          </div>
        )}
      </button>

      {showUploadModal && user && (
        <AvatarUpload
          agentId={user.id}
          currentAvatar={avatarUrl}
          onUpload={handleAvatarUpload}
          onClose={() => setShowUploadModal(false)}
        />
      )}
    </>
  );
}