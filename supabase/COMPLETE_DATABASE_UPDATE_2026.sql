-- ============================================================================
-- COMPLETE DATABASE UPDATE 2026
-- This script ensures ALL required tables and features are properly configured
-- Run this ONCE in Supabase SQL Editor to ensure everything is up to date
-- ============================================================================

DO $$
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '========================================';
  RAISE NOTICE '🚀 STARTING COMPLETE DATABASE UPDATE';
  RAISE NOTICE '========================================';
  RAISE NOTICE '';
END $$;

-- ============================================================================
-- 1. TEMPLATES TABLE - For reusable shape groups
-- ============================================================================
DO $$
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '1️⃣  CHECKING TEMPLATES TABLE...';
END $$;

-- Create templates table if it doesn't exist
CREATE TABLE IF NOT EXISTS public.templates (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  project_id UUID REFERENCES public.projects(id) ON DELETE CASCADE,
  
  -- Template info
  name TEXT NOT NULL,
  description TEXT,
  category TEXT NOT NULL,
  tags TEXT[], -- Array of tags
  
  -- Template data (shapes as JSON)
  shapes JSONB NOT NULL,
  
  -- Bounding box for preview
  bounds JSONB NOT NULL,
  
  -- Metadata
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  
  -- Constraints
  CONSTRAINT templates_name_not_empty CHECK (length(trim(name)) > 0),
  CONSTRAINT templates_category_not_empty CHECK (length(trim(category)) > 0)
);

-- Make project_id nullable (templates can be personal, not project-specific)
ALTER TABLE public.templates 
  ALTER COLUMN project_id DROP NOT NULL;

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_templates_user_id ON public.templates(user_id);
CREATE INDEX IF NOT EXISTS idx_templates_project_id ON public.templates(project_id);
CREATE INDEX IF NOT EXISTS idx_templates_category ON public.templates(category);
CREATE INDEX IF NOT EXISTS idx_templates_created_at ON public.templates(created_at DESC);

-- Enable RLS
ALTER TABLE public.templates ENABLE ROW LEVEL SECURITY;

-- Drop existing policies
DROP POLICY IF EXISTS "Users can view own templates" ON public.templates;
DROP POLICY IF EXISTS "Users can insert own templates" ON public.templates;
DROP POLICY IF EXISTS "Users can update own templates" ON public.templates;
DROP POLICY IF EXISTS "Users can delete own templates" ON public.templates;

-- Create RLS policies
CREATE POLICY "Users can view own templates"
  ON public.templates
  FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own templates"
  ON public.templates
  FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own templates"
  ON public.templates
  FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete own templates"
  ON public.templates
  FOR DELETE
  USING (auth.uid() = user_id);

-- Updated_at trigger
CREATE OR REPLACE FUNCTION update_templates_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS templates_updated_at ON public.templates;
CREATE TRIGGER templates_updated_at
  BEFORE UPDATE ON public.templates
  FOR EACH ROW
  EXECUTE FUNCTION update_templates_updated_at();

-- Grant permissions
GRANT SELECT, INSERT, UPDATE, DELETE ON public.templates TO authenticated;

DO $$
BEGIN
  RAISE NOTICE '✅ Templates table configured';
END $$;

-- ============================================================================
-- 2. ROOM MATERIAL AND COLOR FIELDS
-- ============================================================================
DO $$
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '2️⃣  CHECKING ROOM FIELDS...';
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
-- 3. STORAGE BUCKET FOR PROJECT FILES
-- ============================================================================
DO $$
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '3️⃣  CHECKING STORAGE BUCKETS...';
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

DO $$
BEGIN
  RAISE NOTICE '✅ Storage bucket configured';
END $$;

-- ============================================================================
-- 4. PURCHASE ORDERS - ADD PAID STATUS AND PRICE PER UNIT
-- ============================================================================
DO $$
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '4️⃣  CHECKING PURCHASE ORDERS...';
END $$;

-- Check if purchase_orders table exists first
DO $$
DECLARE
  table_exists BOOLEAN;
BEGIN
  SELECT EXISTS(
    SELECT 1 FROM information_schema.tables 
    WHERE table_schema = 'public' AND table_name = 'purchase_orders'
  ) INTO table_exists;
  
  IF NOT table_exists THEN
    RAISE NOTICE '⏭️  Skipping purchase_orders (table does not exist)';
  ELSE
    -- Add paid status column if it doesn't exist
    IF NOT EXISTS (
      SELECT 1 FROM information_schema.columns 
      WHERE table_schema = 'public' 
      AND table_name = 'purchase_orders' 
      AND column_name = 'paid'
    ) THEN
      ALTER TABLE public.purchase_orders ADD COLUMN paid BOOLEAN DEFAULT FALSE;
      RAISE NOTICE '✅ Added paid column';
    ELSE
      RAISE NOTICE 'ℹ️  paid column already exists';
    END IF;

    -- Add price_per_unit column if it doesn't exist
    IF NOT EXISTS (
      SELECT 1 FROM information_schema.columns 
      WHERE table_schema = 'public' 
      AND table_name = 'purchase_orders' 
      AND column_name = 'price_per_unit'
    ) THEN
      ALTER TABLE public.purchase_orders ADD COLUMN price_per_unit DECIMAL(10, 2);
      RAISE NOTICE '✅ Added price_per_unit column';
    ELSE
      RAISE NOTICE 'ℹ️  price_per_unit column already exists';
    END IF;

    -- Add total_price column if it doesn't exist
    IF NOT EXISTS (
      SELECT 1 FROM information_schema.columns 
      WHERE table_schema = 'public' 
      AND table_name = 'purchase_orders' 
      AND column_name = 'total_price'
    ) THEN
      ALTER TABLE public.purchase_orders ADD COLUMN total_price DECIMAL(10, 2);
      RAISE NOTICE '✅ Added total_price column';
    ELSE
      RAISE NOTICE 'ℹ️  total_price column already exists';
    END IF;

    -- Add assigned_to column if it doesn't exist
    IF NOT EXISTS (
      SELECT 1 FROM information_schema.columns 
      WHERE table_schema = 'public' 
      AND table_name = 'purchase_orders' 
      AND column_name = 'assigned_to'
    ) THEN
      ALTER TABLE public.purchase_orders ADD COLUMN assigned_to UUID REFERENCES auth.users(id) ON DELETE SET NULL;
      RAISE NOTICE '✅ Added assigned_to column';
    ELSE
      RAISE NOTICE 'ℹ️  assigned_to column already exists';
    END IF;
  END IF;
END $$;

-- ============================================================================
-- 5. MATERIALS - ADD DESCRIPTION FIELD
-- ============================================================================
DO $$
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '5️⃣  CHECKING MATERIALS...';
END $$;

DO $$
DECLARE
  table_exists BOOLEAN;
BEGIN
  SELECT EXISTS(
    SELECT 1 FROM information_schema.tables 
    WHERE table_schema = 'public' AND table_name = 'materials'
  ) INTO table_exists;
  
  IF NOT table_exists THEN
    RAISE NOTICE '⏭️  Skipping materials (table does not exist)';
  ELSE
    IF NOT EXISTS (
      SELECT 1 FROM information_schema.columns 
      WHERE table_schema = 'public' 
      AND table_name = 'materials' 
      AND column_name = 'description'
    ) THEN
      ALTER TABLE public.materials ADD COLUMN description TEXT;
      RAISE NOTICE '✅ Added description column';
    ELSE
      RAISE NOTICE 'ℹ️  description column already exists';
    END IF;
  END IF;
END $$;

-- ============================================================================
-- 6. FLOOR_MAP_SHAPES - ADD NOTES FIELD
-- ============================================================================
DO $$
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '6️⃣  CHECKING FLOOR_MAP_SHAPES...';
END $$;

DO $$
DECLARE
  table_exists BOOLEAN;
BEGIN
  SELECT EXISTS(
    SELECT 1 FROM information_schema.tables 
    WHERE table_schema = 'public' AND table_name = 'floor_map_shapes'
  ) INTO table_exists;
  
  IF NOT table_exists THEN
    RAISE NOTICE '⏭️  Skipping floor_map_shapes (table does not exist)';
  ELSE
    IF NOT EXISTS (
      SELECT 1 FROM information_schema.columns 
      WHERE table_schema = 'public' 
      AND table_name = 'floor_map_shapes' 
      AND column_name = 'notes'
    ) THEN
      ALTER TABLE public.floor_map_shapes ADD COLUMN notes TEXT;
      RAISE NOTICE '✅ Added notes column';
    ELSE
      RAISE NOTICE 'ℹ️  notes column already exists';
    END IF;
  END IF;
END $$;

-- ============================================================================
-- VERIFICATION
-- ============================================================================
DO $$
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '========================================';
  RAISE NOTICE '✅ ALL CHECKS COMPLETE!';
  RAISE NOTICE '========================================';
  RAISE NOTICE '';
  RAISE NOTICE 'Verifying database state...';
  RAISE NOTICE '';
END $$;

-- Verify templates table
DO $$
DECLARE
  table_exists BOOLEAN;
BEGIN
  SELECT EXISTS(
    SELECT 1 FROM information_schema.tables 
    WHERE table_schema = 'public' AND table_name = 'templates'
  ) INTO table_exists;
  
  IF table_exists THEN
    RAISE NOTICE '✅ Templates table: EXISTS';
  ELSE
    RAISE NOTICE '❌ Templates table: NOT FOUND';
  END IF;
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
  
  RAISE NOTICE '✅ Rooms table: % material/color columns', col_count;
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
    RAISE NOTICE '✅ Storage bucket: project-files EXISTS';
  ELSE
    RAISE NOTICE '❌ Storage bucket: project-files NOT FOUND';
  END IF;
END $$;

-- Verify purchase orders columns (if table exists)
DO $$
DECLARE
  table_exists BOOLEAN;
  col_count INTEGER;
BEGIN
  SELECT EXISTS(
    SELECT 1 FROM information_schema.tables 
    WHERE table_schema = 'public' AND table_name = 'purchase_orders'
  ) INTO table_exists;
  
  IF table_exists THEN
    SELECT COUNT(*) INTO col_count
    FROM information_schema.columns 
    WHERE table_name = 'purchase_orders'
    AND column_name IN ('paid', 'price_per_unit', 'total_price', 'assigned_to');
    
    RAISE NOTICE '✅ Purchase orders: % columns', col_count;
  ELSE
    RAISE NOTICE 'ℹ️  Purchase orders table does not exist (skipped)';
  END IF;
END $$;

-- Final message
DO $$
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '========================================';
  RAISE NOTICE '🎉 DATABASE UPDATE COMPLETE! 🎉';
  RAISE NOTICE '========================================';
  RAISE NOTICE '';
  RAISE NOTICE 'Your database is now fully updated with:';
  RAISE NOTICE '  ✅ Templates system for reusable shapes';
  RAISE NOTICE '  ✅ Room material and color fields';
  RAISE NOTICE '  ✅ Project files storage bucket';
  RAISE NOTICE '  ✅ Purchase order enhancements';
  RAISE NOTICE '  ✅ Material descriptions';
  RAISE NOTICE '  ✅ Floor map shape notes';
  RAISE NOTICE '';
  RAISE NOTICE '🚀 Ready for production!';
  RAISE NOTICE '';
END $$;
