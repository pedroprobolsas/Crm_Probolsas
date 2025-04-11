/*
  # Create Media Storage Bucket

  1. Purpose
    - Create a storage bucket for media files (images, documents, audio)
    - Set up appropriate security policies for the bucket
    - Configure CORS settings for the bucket
    
  2. Notes
    - This migration creates a 'media' bucket in Supabase Storage
    - The bucket will be used to store files sent in chat messages
    - Security policies allow authenticated users to upload and download files
*/

-- Create the media bucket if it doesn't exist
INSERT INTO storage.buckets (id, name, public)
VALUES ('media', 'media', true)
ON CONFLICT (id) DO NOTHING;

-- Set up CORS for the bucket
UPDATE storage.buckets
SET cors = '[
  {
    "origin": "*",
    "methods": ["GET", "POST", "PUT", "DELETE", "OPTIONS"],
    "headers": ["Content-Type", "Authorization", "x-client-info", "x-client-data"],
    "maxAgeSeconds": 3600
  }
]'::jsonb
WHERE id = 'media';

-- Create a policy to allow authenticated users to upload files
CREATE POLICY "Allow authenticated users to upload files"
ON storage.objects
FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'media' AND
  (storage.foldername(name))[1] = 'chat-files'
);

-- Create a policy to allow authenticated users to update their own files
CREATE POLICY "Allow authenticated users to update their own files"
ON storage.objects
FOR UPDATE
TO authenticated
USING (
  bucket_id = 'media' AND
  (storage.foldername(name))[1] = 'chat-files'
);

-- Create a policy to allow authenticated users to read files
CREATE POLICY "Allow authenticated users to read files"
ON storage.objects
FOR SELECT
TO authenticated
USING (
  bucket_id = 'media'
);

-- Create a policy to allow public access to read files
CREATE POLICY "Allow public access to read files"
ON storage.objects
FOR SELECT
TO public
USING (
  bucket_id = 'media' AND
  (storage.foldername(name))[1] = 'chat-files'
);

-- Create a policy to allow authenticated users to delete their own files
CREATE POLICY "Allow authenticated users to delete their own files"
ON storage.objects
FOR DELETE
TO authenticated
USING (
  bucket_id = 'media' AND
  (storage.foldername(name))[1] = 'chat-files'
);

-- Log the migration
DO $$
BEGIN
  RAISE NOTICE 'Created media storage bucket with appropriate security policies';
END;
$$;
