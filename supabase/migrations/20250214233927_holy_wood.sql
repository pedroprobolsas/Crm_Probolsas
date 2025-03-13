-- Create storage bucket for agent avatars
INSERT INTO storage.buckets (id, name, public)
VALUES ('agent-avatars', 'agent-avatars', true)
ON CONFLICT (id) DO NOTHING;

-- Create storage policy to allow authenticated users to upload
CREATE POLICY "Authenticated users can upload avatars"
ON storage.objects FOR INSERT TO authenticated
WITH CHECK (
  bucket_id = 'agent-avatars' AND
  auth.role() = 'authenticated'
);

-- Create storage policy to allow public access to avatars
CREATE POLICY "Public access to avatars"
ON storage.objects FOR SELECT TO public
USING (bucket_id = 'agent-avatars');

-- Create storage policy to allow users to update their own avatars
CREATE POLICY "Users can update their own avatars"
ON storage.objects FOR UPDATE TO authenticated
USING (bucket_id = 'agent-avatars');

-- Create storage policy to allow users to delete their own avatars
CREATE POLICY "Users can delete their own avatars"
ON storage.objects FOR DELETE TO authenticated
USING (bucket_id = 'agent-avatars');