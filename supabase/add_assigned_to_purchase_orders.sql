-- Add Assigned To functionality for Purchase Orders with proper RLS

-- Step 1: Add assigned_to_user_id column to materials table
ALTER TABLE materials 
ADD COLUMN IF NOT EXISTS assigned_to_user_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL;

-- Step 2: Add index for performance
CREATE INDEX IF NOT EXISTS materials_assigned_to_user_id_idx ON materials(assigned_to_user_id);

-- Step 3: Add comment
COMMENT ON COLUMN materials.assigned_to_user_id IS 'User assigned to this purchase order';

-- Step 4: Drop existing RLS policies for materials
DROP POLICY IF EXISTS "Users can view materials in their projects" ON materials;
DROP POLICY IF EXISTS "Users can create materials in their projects" ON materials;
DROP POLICY IF EXISTS "Users can update materials in their projects" ON materials;
DROP POLICY IF EXISTS "Users can delete materials in their projects" ON materials;

-- Step 5: Create new RLS policies with assigned_to support

-- VIEW: Can see if:
-- 1. Project owner
-- 2. Has purchases_access AND (scope is 'all' OR created by them OR assigned to them)
-- 3. Assigned to them (even with limited access)
CREATE POLICY "Users can view materials in their projects"
ON materials
FOR SELECT
USING (
  -- Project owner
  project_id IN (
    SELECT id FROM projects 
    WHERE owner_id IN (
      SELECT id FROM profiles WHERE user_id = auth.uid()
    )
  )
  OR
  -- Has purchases_access with appropriate scope
  (
    project_id IN (
      SELECT ps.project_id FROM project_shares ps
      WHERE ps.shared_with_user_id IN (
        SELECT id FROM profiles WHERE user_id = auth.uid()
      )
      AND ps.purchases_access IN ('view', 'create', 'edit')
      AND (
        ps.purchases_scope = 'all'
        OR (ps.purchases_scope = 'assigned' AND (
          created_by_user_id IN (SELECT id FROM profiles WHERE user_id = auth.uid())
          OR assigned_to_user_id IN (SELECT id FROM profiles WHERE user_id = auth.uid())
        ))
      )
    )
  )
  OR
  -- Assigned to this user (even with limited access)
  assigned_to_user_id IN (
    SELECT id FROM profiles WHERE user_id = auth.uid()
  )
);

-- CREATE: Can create if has purchases_access 'create' or 'edit'
CREATE POLICY "Users can create materials in their projects"
ON materials
FOR INSERT
WITH CHECK (
  project_id IN (
    SELECT id FROM projects 
    WHERE owner_id IN (
      SELECT id FROM profiles WHERE user_id = auth.uid()
    )
  )
  OR
  project_id IN (
    SELECT ps.project_id FROM project_shares ps
    WHERE ps.shared_with_user_id IN (
      SELECT id FROM profiles WHERE user_id = auth.uid()
    )
    AND ps.purchases_access IN ('create', 'edit')
  )
);

-- UPDATE: Can update if:
-- 1. Project owner
-- 2. Created by them (with 'create' or 'edit' access)
-- 3. Assigned to them (with 'create' or 'edit' access)
-- 4. Has 'edit' access with 'all' scope
CREATE POLICY "Users can update materials in their projects"
ON materials
FOR UPDATE
USING (
  -- Project owner
  project_id IN (
    SELECT id FROM projects 
    WHERE owner_id IN (
      SELECT id FROM profiles WHERE user_id = auth.uid()
    )
  )
  OR
  -- Created by user with create/edit access
  (
    created_by_user_id IN (
      SELECT id FROM profiles WHERE user_id = auth.uid()
    )
    AND project_id IN (
      SELECT ps.project_id FROM project_shares ps
      WHERE ps.shared_with_user_id IN (
        SELECT id FROM profiles WHERE user_id = auth.uid()
      )
      AND ps.purchases_access IN ('create', 'edit')
    )
  )
  OR
  -- Assigned to user with create/edit access
  (
    assigned_to_user_id IN (
      SELECT id FROM profiles WHERE user_id = auth.uid()
    )
    AND project_id IN (
      SELECT ps.project_id FROM project_shares ps
      WHERE ps.shared_with_user_id IN (
        SELECT id FROM profiles WHERE user_id = auth.uid()
      )
      AND ps.purchases_access IN ('create', 'edit')
    )
  )
  OR
  -- Has edit access with all scope
  project_id IN (
    SELECT ps.project_id FROM project_shares ps
    WHERE ps.shared_with_user_id IN (
      SELECT id FROM profiles WHERE user_id = auth.uid()
    )
    AND ps.purchases_access = 'edit'
    AND ps.purchases_scope = 'all'
  )
);

-- DELETE: Only project owner or admin/editor role
CREATE POLICY "Users can delete materials in their projects"
ON materials
FOR DELETE
USING (
  project_id IN (
    SELECT id FROM projects 
    WHERE owner_id IN (
      SELECT id FROM profiles WHERE user_id = auth.uid()
    )
  )
  OR
  project_id IN (
    SELECT ps.project_id FROM project_shares ps
    WHERE ps.shared_with_user_id IN (
      SELECT id FROM profiles WHERE user_id = auth.uid()
    )
    AND ps.role IN ('admin', 'editor')
  )
);

-- Step 6: Verify the changes
SELECT 
  column_name,
  data_type,
  is_nullable
FROM information_schema.columns
WHERE table_name = 'materials'
  AND column_name = 'assigned_to_user_id';

-- Step 7: Verify RLS policies
SELECT 
  schemaname,
  tablename,
  policyname,
  cmd
FROM pg_policies
WHERE tablename = 'materials'
ORDER BY policyname;
