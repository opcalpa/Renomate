-- Fix RLS policies for floor_map_shapes to allow INSERT, UPDATE, DELETE
-- Currently only SELECT policy exists, which prevents saving shapes

-- Drop existing policies
DROP POLICY IF EXISTS "Users can view shapes in accessible projects" ON public.floor_map_shapes;
DROP POLICY IF EXISTS "Users can view shapes" ON public.floor_map_shapes;
DROP POLICY IF EXISTS "Users can manage shapes" ON public.floor_map_shapes;
DROP POLICY IF EXISTS "Users can manage shapes in accessible projects" ON public.floor_map_shapes;

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

-- Verify policies
SELECT 
  schemaname,
  tablename,
  policyname,
  cmd,
  permissive
FROM pg_policies
WHERE tablename = 'floor_map_shapes'
ORDER BY cmd, policyname;

-- Success message
DO $$
BEGIN
  RAISE NOTICE '✅ RLS policies for floor_map_shapes updated successfully!';
  RAISE NOTICE 'Users can now: SELECT, INSERT, UPDATE, DELETE shapes in their projects';
END $$;
