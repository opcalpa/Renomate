-- Fix RLS policy to ensure project owners ALWAYS see all materials
-- This is a simplified and more reliable version

-- Step 1: Drop existing VIEW policy
DROP POLICY IF EXISTS "Users can view materials in their projects" ON materials;

-- Step 2: Create SIMPLIFIED and RELIABLE VIEW policy
-- Priority order:
-- 1. Project owner → sees EVERYTHING (no conditions)
-- 2. Assigned to user → sees it (even with no purchases_access)
-- 3. Has purchases_access with appropriate scope
CREATE POLICY "Users can view materials in their projects"
ON materials
FOR SELECT
USING (
  -- PRIORITY 1: Project owner sees EVERYTHING (no other conditions needed)
  EXISTS (
    SELECT 1 FROM projects p
    WHERE p.id = materials.project_id
      AND p.owner_id IN (
        SELECT id FROM profiles WHERE user_id = auth.uid()
      )
  )
  OR
  -- PRIORITY 2: Assigned to this user (even with purchases_access='none')
  assigned_to_user_id IN (
    SELECT id FROM profiles WHERE user_id = auth.uid()
  )
  OR
  -- PRIORITY 3: Has purchases_access with appropriate scope
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
);

-- Step 3: Verify the policy
SELECT 
  schemaname,
  tablename,
  policyname,
  cmd
FROM pg_policies
WHERE tablename = 'materials'
  AND policyname = 'Users can view materials in their projects';

-- Step 4: Test query (run as project owner to verify)
-- This should return ALL materials for the project
-- SELECT COUNT(*) FROM materials WHERE project_id = 'YOUR_PROJECT_ID';
