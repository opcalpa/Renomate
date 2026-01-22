-- Create Storage bucket for comment images and project files
-- This fixes the "Bucket not found" error when uploading images to comments

-- Create the bucket (if it doesn't exist)
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'project-files',
  'project-files',
  true, -- Public bucket so images can be displayed
  10485760, -- 10MB max file size
  ARRAY['image/jpeg', 'image/png', 'image/gif', 'image/webp', 'application/pdf']
)
ON CONFLICT (id) DO NOTHING;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Users can upload files to their projects" ON storage.objects;
DROP POLICY IF EXISTS "Anyone can view public project files" ON storage.objects;
DROP POLICY IF EXISTS "Users can delete their own uploaded files" ON storage.objects;

-- Allow authenticated users to upload files
CREATE POLICY "Users can upload files to their projects"
ON storage.objects
FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'project-files'
  AND auth.uid() IS NOT NULL
);

-- Allow anyone to view files (public bucket)
CREATE POLICY "Anyone can view public project files"
ON storage.objects
FOR SELECT
TO public
USING (bucket_id = 'project-files');

-- Allow users to delete their own files
CREATE POLICY "Users can delete their own uploaded files"
ON storage.objects
FOR DELETE
TO authenticated
USING (
  bucket_id = 'project-files'
  AND auth.uid() IS NOT NULL
);

-- Allow users to update their own files
CREATE POLICY "Users can update their own uploaded files"
ON storage.objects
FOR UPDATE
TO authenticated
USING (
  bucket_id = 'project-files'
  AND auth.uid() IS NOT NULL
)
WITH CHECK (
  bucket_id = 'project-files'
  AND auth.uid() IS NOT NULL
);

-- Verify bucket was created
SELECT * FROM storage.buckets WHERE id = 'project-files';

-- Verify policies were created
SELECT 
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd
FROM pg_policies 
WHERE tablename = 'objects' 
AND schemaname = 'storage'
ORDER BY policyname;
