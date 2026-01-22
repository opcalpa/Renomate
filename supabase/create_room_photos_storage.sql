-- Create storage bucket for room photos
INSERT INTO storage.buckets (id, name, public)
VALUES ('room-photos', 'room-photos', true)
ON CONFLICT (id) DO NOTHING;

-- Set up storage policies for room-photos bucket

-- Policy: Allow authenticated users to upload
CREATE POLICY "Authenticated users can upload room photos"
ON storage.objects
FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'room-photos');

-- Policy: Allow public read access (since bucket is public)
CREATE POLICY "Anyone can view room photos"
ON storage.objects
FOR SELECT
TO public
USING (bucket_id = 'room-photos');

-- Policy: Allow users to delete their own uploads
CREATE POLICY "Users can delete their own room photos"
ON storage.objects
FOR DELETE
TO authenticated
USING (bucket_id = 'room-photos' AND auth.uid()::text = (storage.foldername(name))[1]);

-- Success message
DO $$
BEGIN
  RAISE NOTICE '✅ Storage bucket "room-photos" created successfully!';
  RAISE NOTICE 'Users can now upload images to rooms.';
END $$;
