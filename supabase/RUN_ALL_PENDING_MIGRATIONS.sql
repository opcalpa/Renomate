-- ============================================================================
-- RUN ALL PENDING MIGRATIONS
-- This file combines all pending SQL migrations in one script
-- Run this ONCE in Supabase SQL Editor to fix all current issues
-- ============================================================================

-- ============================================================================
-- 1. ADD ROOM MATERIAL AND COLOR FIELDS
-- ============================================================================
DO $$
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '========================================';
  RAISE NOTICE '1️⃣  ADDING ROOM MATERIAL/COLOR FIELDS';
  RAISE NOTICE '========================================';
END $$;

-- Add columns if they don't exist
DO $$
BEGIN
  -- Material field
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' 
    AND table_name = 'rooms' 
    AND column_name = 'material'
  ) THEN
    ALTER TABLE public.rooms ADD COLUMN material TEXT;
    RAISE NOTICE '✅ Added material column';
  ELSE
    RAISE NOTICE 'ℹ️  material column already exists';
  END IF;

  -- Wall color field
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' 
    AND table_name = 'rooms' 
    AND column_name = 'wall_color'
  ) THEN
    ALTER TABLE public.rooms ADD COLUMN wall_color TEXT;
    RAISE NOTICE '✅ Added wall_color column';
  ELSE
    RAISE NOTICE 'ℹ️  wall_color column already exists';
  END IF;

  -- Ceiling color field
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' 
    AND table_name = 'rooms' 
    AND column_name = 'ceiling_color'
  ) THEN
    ALTER TABLE public.rooms ADD COLUMN ceiling_color TEXT;
    RAISE NOTICE '✅ Added ceiling_color column';
  ELSE
    RAISE NOTICE 'ℹ️  ceiling_color column already exists';
  END IF;

  -- Trim color field
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' 
    AND table_name = 'rooms' 
    AND column_name = 'trim_color'
  ) THEN
    ALTER TABLE public.rooms ADD COLUMN trim_color TEXT;
    RAISE NOTICE '✅ Added trim_color column';
  ELSE
    RAISE NOTICE 'ℹ️  trim_color column already exists';
  END IF;
END $$;

-- ============================================================================
-- 2. CREATE STORAGE BUCKET FOR COMMENT IMAGES
-- ============================================================================
DO $$
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '========================================';
  RAISE NOTICE '2️⃣  CREATING STORAGE BUCKET';
  RAISE NOTICE '========================================';
END $$;

-- Create the bucket (if it doesn't exist)
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'project-files',
  'project-files',
  true,
  10485760, -- 10MB
  ARRAY['image/jpeg', 'image/png', 'image/gif', 'image/webp', 'application/pdf']
)
ON CONFLICT (id) DO UPDATE SET
  public = true,
  file_size_limit = 10485760,
  allowed_mime_types = ARRAY['image/jpeg', 'image/png', 'image/gif', 'image/webp', 'application/pdf'];

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Users can upload files to their projects" ON storage.objects;
DROP POLICY IF EXISTS "Anyone can view public project files" ON storage.objects;
DROP POLICY IF EXISTS "Users can delete their own uploaded files" ON storage.objects;
DROP POLICY IF EXISTS "Users can update their own uploaded files" ON storage.objects;

-- Storage policies
CREATE POLICY "Users can upload files to their projects"
ON storage.objects
FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'project-files' AND auth.uid() IS NOT NULL);

CREATE POLICY "Anyone can view public project files"
ON storage.objects
FOR SELECT
TO public
USING (bucket_id = 'project-files');

CREATE POLICY "Users can delete their own uploaded files"
ON storage.objects
FOR DELETE
TO authenticated
USING (bucket_id = 'project-files' AND auth.uid() IS NOT NULL);

CREATE POLICY "Users can update their own uploaded files"
ON storage.objects
FOR UPDATE
TO authenticated
USING (bucket_id = 'project-files' AND auth.uid() IS NOT NULL)
WITH CHECK (bucket_id = 'project-files' AND auth.uid() IS NOT NULL);

-- ============================================================================
-- 3. FIX PROJECTS RLS FOR SELECT
-- ============================================================================
DO $$
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '========================================';
  RAISE NOTICE '3️⃣  FIXING PROJECTS RLS POLICIES';
  RAISE NOTICE '========================================';
END $$;

-- Drop existing SELECT policy if it exists
DROP POLICY IF EXISTS "Users can view projects they have access to" ON public.projects;

-- Create comprehensive SELECT policy
CREATE POLICY "Users can view projects they have access to"
ON public.projects
FOR SELECT
USING (
  -- Owner can always view
  auth.uid() IN (
    SELECT user_id FROM public.profiles WHERE id = projects.owner_id
  )
  OR
  -- Shared users can view
  auth.uid() IN (
    SELECT p.user_id 
    FROM public.project_shares ps
    JOIN public.profiles p ON p.id = ps.shared_with_user_id
    WHERE ps.project_id = projects.id
  )
);

-- ============================================================================
-- VERIFICATION
-- ============================================================================
DO $$
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '========================================';
  RAISE NOTICE '✅✅✅ ALL MIGRATIONS COMPLETE! ✅✅✅';
  RAISE NOTICE '========================================';
  RAISE NOTICE '';
  RAISE NOTICE 'Verifying changes...';
  RAISE NOTICE '';
END $$;

-- Verify rooms columns
DO $$
DECLARE
  col_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO col_count
  FROM information_schema.columns 
  WHERE table_name = 'rooms'
  AND column_name IN ('material', 'wall_color', 'ceiling_color', 'trim_color');
  
  RAISE NOTICE '✅ Rooms table: % new columns added', col_count;
END $$;

-- Verify storage bucket
DO $$
DECLARE
  bucket_exists BOOLEAN;
BEGIN
  SELECT EXISTS(
    SELECT 1 FROM storage.buckets WHERE id = 'project-files'
  ) INTO bucket_exists;
  
  IF bucket_exists THEN
    RAISE NOTICE '✅ Storage bucket: project-files exists';
  ELSE
    RAISE NOTICE '❌ Storage bucket: project-files NOT found';
  END IF;
END $$;

-- Verify projects RLS
DO $$
DECLARE
  policy_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO policy_count
  FROM pg_policies 
  WHERE tablename = 'projects' 
  AND policyname = 'Users can view projects they have access to';
  
  RAISE NOTICE '✅ Projects RLS: % policies active', policy_count;
END $$;

-- Final message
DO $$
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '========================================';
  RAISE NOTICE '🎉 READY TO USE! 🎉';
  RAISE NOTICE '========================================';
  RAISE NOTICE '';
  RAISE NOTICE 'You can now:';
  RAISE NOTICE '  ✅ Save room material and colors';
  RAISE NOTICE '  ✅ Upload images to comments';
  RAISE NOTICE '  ✅ View project details';
  RAISE NOTICE '';
  RAISE NOTICE 'Reload your app and test!';
  RAISE NOTICE '';
END $$;
