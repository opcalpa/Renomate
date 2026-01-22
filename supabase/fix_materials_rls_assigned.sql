-- Fix RLS policies for materials to properly handle assigned users and scope filtering

-- Step 1: Drop existing policies
DROP POLICY IF EXISTS "Users can view materials in their projects" ON materials;
DROP POLICY IF EXISTS "Users can update materials in their projects" ON materials;

-- Step 2: Create FIXED VIEW policy
-- Users can see materials if:
-- 1. Project owner (sees everything)
-- 2. Has purchases_access='view'/'create'/'edit' AND:
--    - scope='all' → sees everything
--    - scope='assigned' → sees only created_by OR assigned_to them
-- 3. Assigned to them (even if purchases_access='none')
CREATE POLICY "Users can view materials in their projects"
ON materials
FOR SELECT
USING (
  -- Project owner sees everything
  project_id IN (
    SELECT id FROM projects 
    WHERE owner_id IN (
      SELECT id FROM profiles WHERE user_id = auth.uid()
    )
  )
  OR
  -- Has purchases_access with appropriate scope
  (
    EXISTS (
      SELECT 1 FROM project_shares ps
      WHERE ps.project_id = materials.project_id
        AND ps.shared_with_user_id IN (
          SELECT id FROM profiles WHERE user_id = auth.uid()
        )
        AND ps.purchases_access IN ('view', 'create', 'edit')
        AND (
          -- Scope 'all' → sees everything
          ps.purchases_scope = 'all'
          OR
          -- Scope 'assigned' → sees only created_by OR assigned_to them
          (
            ps.purchases_scope = 'assigned'
            AND (
              materials.created_by_user_id IN (
                SELECT id FROM profiles WHERE user_id = auth.uid()
              )
              OR
              materials.assigned_to_user_id IN (
                SELECT id FROM profiles WHERE user_id = auth.uid()
              )
            )
          )
        )
    )
  )
  OR
  -- Assigned to this user (even with purchases_access='none' or no access)
  assigned_to_user_id IN (
    SELECT id FROM profiles WHERE user_id = auth.uid()
  )
);

-- Step 3: Create FIXED UPDATE policy
-- Users can update materials if:
-- 1. Project owner
-- 2. Created by them AND has purchases_access='create'/'edit'
-- 3. Assigned to them AND has purchases_access='create'/'edit'
-- 4. Has purchases_access='edit' with scope='all'
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
    AND EXISTS (
      SELECT 1 FROM project_shares ps
      WHERE ps.project_id = materials.project_id
        AND ps.shared_with_user_id IN (
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
    AND EXISTS (
      SELECT 1 FROM project_shares ps
      WHERE ps.project_id = materials.project_id
        AND ps.shared_with_user_id IN (
          SELECT id FROM profiles WHERE user_id = auth.uid()
        )
        AND ps.purchases_access IN ('create', 'edit')
    )
  )
  OR
  -- Has edit access with all scope
  EXISTS (
    SELECT 1 FROM project_shares ps
    WHERE ps.project_id = materials.project_id
      AND ps.shared_with_user_id IN (
        SELECT id FROM profiles WHERE user_id = auth.uid()
      )
      AND ps.purchases_access = 'edit'
      AND ps.purchases_scope = 'all'
  )
);

-- Step 4: Verify policies
SELECT 
  schemaname,
  tablename,
  policyname,
  cmd,
  qual
FROM pg_policies
WHERE tablename = 'materials'
ORDER BY policyname;
