-- ============================================================================
-- FIX CANVAS SAVE PROBLEM
-- ============================================================================
-- This script fixes the issue where objects drawn on canvas don't persist
-- after page refresh, even when clicking Save.
--
-- Run this in Supabase SQL Editor or via psql
-- ============================================================================

BEGIN;

-- ============================================================================
-- STEP 1: Add missing columns to floor_map_shapes
-- ============================================================================

DO $$
BEGIN
  -- Check and add color column
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' 
    AND table_name = 'floor_map_shapes' 
    AND column_name = 'color'
  ) THEN
    ALTER TABLE public.floor_map_shapes ADD COLUMN color TEXT;
    RAISE NOTICE '✅ Added color column to floor_map_shapes';
  ELSE
    RAISE NOTICE 'ℹ️ color column already exists in floor_map_shapes';
  END IF;

  -- Check and add stroke_color column
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' 
    AND table_name = 'floor_map_shapes' 
    AND column_name = 'stroke_color'
  ) THEN
    ALTER TABLE public.floor_map_shapes ADD COLUMN stroke_color TEXT;
    RAISE NOTICE '✅ Added stroke_color column to floor_map_shapes';
  ELSE
    RAISE NOTICE 'ℹ️ stroke_color column already exists in floor_map_shapes';
  END IF;
END $$;

-- ============================================================================
-- STEP 2: Fix RLS policies for floor_map_shapes
-- ============================================================================

-- Drop existing policies
DROP POLICY IF EXISTS "Users can view shapes in accessible projects" ON public.floor_map_shapes;
DROP POLICY IF EXISTS "Users can view shapes" ON public.floor_map_shapes;
DROP POLICY IF EXISTS "Users can manage shapes" ON public.floor_map_shapes;
DROP POLICY IF EXISTS "Users can manage shapes in accessible projects" ON public.floor_map_shapes;
DROP POLICY IF EXISTS "Users can create shapes in manageable projects" ON public.floor_map_shapes;
DROP POLICY IF EXISTS "Users can update shapes in manageable projects" ON public.floor_map_shapes;
DROP POLICY IF EXISTS "Users can delete shapes in manageable projects" ON public.floor_map_shapes;

-- CREATE COMPREHENSIVE POLICIES FOR ALL OPERATIONS

-- SELECT: Users can view shapes in projects they have access to
CREATE POLICY "Users can view shapes in accessible projects"
ON public.floor_map_shapes
FOR SELECT
USING (
  project_id IN (
    SELECT id FROM projects
    WHERE owner_id = get_user_profile_id()
    OR user_has_project_access(id)
  )
);

-- INSERT: Users can create shapes in projects they can manage
CREATE POLICY "Users can create shapes in manageable projects"
ON public.floor_map_shapes
FOR INSERT
WITH CHECK (
  project_id IN (
    SELECT id FROM projects
    WHERE owner_id = get_user_profile_id()
    OR user_can_manage_project(id)
  )
);

-- UPDATE: Users can update shapes in projects they can manage
CREATE POLICY "Users can update shapes in manageable projects"
ON public.floor_map_shapes
FOR UPDATE
USING (
  project_id IN (
    SELECT id FROM projects
    WHERE owner_id = get_user_profile_id()
    OR user_can_manage_project(id)
  )
)
WITH CHECK (
  project_id IN (
    SELECT id FROM projects
    WHERE owner_id = get_user_profile_id()
    OR user_can_manage_project(id)
  )
);

-- DELETE: Users can delete shapes in projects they can manage
CREATE POLICY "Users can delete shapes in manageable projects"
ON public.floor_map_shapes
FOR DELETE
USING (
  project_id IN (
    SELECT id FROM projects
    WHERE owner_id = get_user_profile_id()
    OR user_can_manage_project(id)
  )
);

-- ============================================================================
-- STEP 3: Verify the fixes
-- ============================================================================

-- Show all policies
DO $$
DECLARE
  policy_record RECORD;
BEGIN
  RAISE NOTICE '📋 Current RLS policies for floor_map_shapes:';
  FOR policy_record IN 
    SELECT policyname, cmd
    FROM pg_policies
    WHERE tablename = 'floor_map_shapes'
    ORDER BY cmd, policyname
  LOOP
    RAISE NOTICE '  - % (%)' , policy_record.policyname, policy_record.cmd;
  END LOOP;
END $$;

-- Show all columns
DO $$
DECLARE
  col_record RECORD;
BEGIN
  RAISE NOTICE '📋 Columns in floor_map_shapes:';
  FOR col_record IN 
    SELECT column_name, data_type
    FROM information_schema.columns 
    WHERE table_name = 'floor_map_shapes'
    ORDER BY ordinal_position
  LOOP
    RAISE NOTICE '  - % (%)' , col_record.column_name, col_record.data_type;
  END LOOP;
END $$;

COMMIT;

-- ============================================================================
-- Success message
-- ============================================================================

DO $$
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '✅✅✅ CANVAS SAVE FIX COMPLETED! ✅✅✅';
  RAISE NOTICE '';
  RAISE NOTICE 'Changes made:';
  RAISE NOTICE '  1. Added color and stroke_color columns (if missing)';
  RAISE NOTICE '  2. Created comprehensive RLS policies for SELECT, INSERT, UPDATE, DELETE';
  RAISE NOTICE '';
  RAISE NOTICE 'Next steps:';
  RAISE NOTICE '  1. Draw an object on the canvas';
  RAISE NOTICE '  2. Click Save (or press Cmd/Ctrl+S)';
  RAISE NOTICE '  3. Check Developer Console for: ✅ Successfully inserted X shapes to database';
  RAISE NOTICE '  4. Refresh the page (F5)';
  RAISE NOTICE '  5. The object should persist!';
  RAISE NOTICE '';
END $$;
