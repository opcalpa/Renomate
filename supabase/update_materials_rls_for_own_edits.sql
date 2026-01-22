-- Allow users to edit their own created purchase orders
-- Even if they only have 'create' access (not 'edit')

-- Drop existing UPDATE policy
DROP POLICY IF EXISTS "Users can update materials in their projects" ON materials;

-- Create new UPDATE policy that allows:
-- 1. Users with 'edit' access (all or assigned scope)
-- 2. Users with 'create' access can edit their OWN materials
CREATE POLICY "Users can update materials in their projects"
ON materials
FOR UPDATE
USING (
  -- User created this material (for 'create' access users)
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
  -- User has 'edit' access with 'all' scope
  (
    EXISTS (
      SELECT 1 FROM project_shares ps
      WHERE ps.project_id = materials.project_id
        AND ps.shared_with_user_id IN (
          SELECT id FROM profiles WHERE user_id = auth.uid()
        )
        AND ps.purchases_access = 'edit'
        AND ps.purchases_scope = 'all'
    )
  )
  OR
  -- User has 'edit' access with 'assigned' scope and created this material
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
        AND ps.purchases_access = 'edit'
        AND ps.purchases_scope = 'assigned'
    )
  )
  OR
  -- Project owner can edit everything
  (
    project_id IN (
      SELECT id FROM projects 
      WHERE owner_id IN (
        SELECT id FROM profiles WHERE user_id = auth.uid()
      )
    )
  )
);

-- Verify the policy
SELECT 
  policyname,
  cmd,
  pg_get_expr(qual, 'materials'::regclass) as using_expression
FROM pg_policies
WHERE tablename = 'materials'
  AND cmd = 'UPDATE';
