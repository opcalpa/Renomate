-- Add support for comments on drawing objects (walls, rooms, etc.)
-- This extends the existing comments system

-- ===================================
-- STEP 1: Add new columns for different comment types
-- ===================================

-- First, check and fix entity_id if it exists with wrong type
DO $$ 
BEGIN
  -- Check if entity_id exists as TEXT
  IF EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'comments' 
    AND column_name = 'entity_id' 
    AND data_type = 'text'
  ) THEN
    -- Drop the TEXT version
    ALTER TABLE public.comments DROP COLUMN entity_id;
    RAISE NOTICE 'Dropped existing TEXT entity_id column';
  END IF;
END $$;

-- Add drawing_object_id for canvas objects (walls, shapes, etc.)
ALTER TABLE public.comments 
ADD COLUMN IF NOT EXISTS drawing_object_id UUID;

-- Add entity_id as UUID (not TEXT!) for generic entities (rooms, stakeholders, etc.)
ALTER TABLE public.comments 
ADD COLUMN IF NOT EXISTS entity_id UUID;

-- Add entity_type for categorizing entities
ALTER TABLE public.comments 
ADD COLUMN IF NOT EXISTS entity_type TEXT;

-- Add indexes for performance
CREATE INDEX IF NOT EXISTS comments_drawing_object_id_idx ON public.comments(drawing_object_id);
CREATE INDEX IF NOT EXISTS comments_entity_id_idx ON public.comments(entity_id);
CREATE INDEX IF NOT EXISTS comments_entity_type_idx ON public.comments(entity_type);

-- ===================================
-- STEP 2: Drop ALL old constraints and create new one
-- ===================================
-- Drop ALL possible constraint names (handling typos and variations)
DO $$ 
BEGIN
  -- Drop the correctly spelled constraint
  ALTER TABLE public.comments DROP CONSTRAINT IF EXISTS comments_target_check;
  
  -- Drop the typo version
  ALTER TABLE public.comments DROP CONSTRAINT IF EXISTS cpomments_target_check;
  
  -- Drop any other variations that might exist
  EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'Some constraints may not exist, continuing...';
END $$;

-- Verify no constraint exists before creating new one
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.table_constraints 
    WHERE constraint_name = 'comments_target_check' 
    AND table_name = 'comments'
  ) THEN
    RAISE EXCEPTION 'Constraint still exists! Please manually drop it.';
  END IF;
END $$;

-- Create new constraint that allows task_id, material_id, drawing_object_id, OR entity_id+entity_type
ALTER TABLE public.comments 
ADD CONSTRAINT comments_target_check CHECK (
  -- Exactly one must be set
  (
    (task_id IS NOT NULL AND material_id IS NULL AND drawing_object_id IS NULL AND entity_id IS NULL) OR 
    (task_id IS NULL AND material_id IS NOT NULL AND drawing_object_id IS NULL AND entity_id IS NULL) OR
    (task_id IS NULL AND material_id IS NULL AND drawing_object_id IS NOT NULL AND entity_id IS NULL) OR
    (task_id IS NULL AND material_id IS NULL AND drawing_object_id IS NULL AND entity_id IS NOT NULL)
  )
);

-- ===================================
-- STEP 3: Update RLS policies
-- ===================================

-- Drop existing policies
DROP POLICY IF EXISTS "Users can view comments" ON public.comments;
DROP POLICY IF EXISTS "Users can create comments" ON public.comments;
DROP POLICY IF EXISTS "Users can update own comments" ON public.comments;
DROP POLICY IF EXISTS "Users can delete own comments" ON public.comments;

-- SELECT: Users can view comments on tasks/materials/drawings/rooms they have access to
CREATE POLICY "Users can view comments"
ON public.comments
FOR SELECT
USING (
  -- Comments on tasks in accessible projects
  (task_id IS NOT NULL AND task_id IN (
    SELECT t.id FROM tasks t
    WHERE user_has_project_access(t.project_id)
  ))
  OR
  -- Comments on materials in accessible projects
  (material_id IS NOT NULL AND material_id IN (
    SELECT m.id FROM materials m
    WHERE user_has_project_access(m.project_id)
  ))
  OR
  -- Comments on rooms in accessible projects
  (entity_id IS NOT NULL AND entity_type = 'room' AND entity_id::uuid IN (
    SELECT r.id FROM rooms r
    WHERE user_has_project_access(r.project_id)
  ))
  OR
  -- Comments on drawing objects (allow all authenticated users for now)
  -- Note: Drawing objects don't have direct project_id, so we allow all authenticated
  (drawing_object_id IS NOT NULL AND auth.uid() IS NOT NULL)
);

-- INSERT: Users can comment on tasks/materials/rooms/drawings they have access to
CREATE POLICY "Users can create comments"
ON public.comments
FOR INSERT
WITH CHECK (
  -- Can comment on tasks in accessible projects
  (task_id IS NOT NULL AND task_id IN (
    SELECT t.id FROM tasks t
    WHERE user_has_project_access(t.project_id)
  ))
  OR
  -- Can comment on materials in accessible projects
  (material_id IS NOT NULL AND material_id IN (
    SELECT m.id FROM materials m
    WHERE user_has_project_access(m.project_id)
  ))
  OR
  -- Can comment on rooms in accessible projects
  (entity_id IS NOT NULL AND entity_type = 'room' AND entity_id::uuid IN (
    SELECT r.id FROM rooms r
    WHERE user_has_project_access(r.project_id)
  ))
  OR
  -- Can comment on drawing objects (authenticated users)
  (drawing_object_id IS NOT NULL AND auth.uid() IS NOT NULL)
);

-- UPDATE: Users can only edit their own comments
CREATE POLICY "Users can update own comments"
ON public.comments
FOR UPDATE
USING (
  created_by_user_id IN (
    SELECT id FROM profiles WHERE user_id = auth.uid()
  )
);

-- DELETE: Users can only delete their own comments
CREATE POLICY "Users can delete own comments"
ON public.comments
FOR DELETE
USING (
  created_by_user_id IN (
    SELECT id FROM profiles WHERE user_id = auth.uid()
  )
);

-- ===================================
-- STEP 4: Add comments to document the new columns
-- ===================================
COMMENT ON COLUMN public.comments.drawing_object_id IS 'ID of drawing object (wall, shape, etc.) from canvas - stored in local state, not in database';
COMMENT ON COLUMN public.comments.entity_id IS 'Generic entity ID (for rooms, stakeholders, etc.) - references actual database records';
COMMENT ON COLUMN public.comments.entity_type IS 'Type of entity (e.g., "room", "stakeholder") - used with entity_id';

-- ===================================
-- STEP 5: Verify
-- ===================================
SELECT 'Drawing object comments support added' as status;

-- Success message
DO $$
BEGIN
  RAISE NOTICE '✅ Drawing object comments support added successfully!';
  RAISE NOTICE 'Comments can now be added to: tasks, materials, rooms, and drawing_objects';
END $$;
