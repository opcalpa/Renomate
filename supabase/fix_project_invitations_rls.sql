-- Fix RLS policies for project_invitations to allow INSERT

-- Step 1: Drop existing policies
DROP POLICY IF EXISTS "Users can view their own invitations" ON public.project_invitations;
DROP POLICY IF EXISTS "Users can respond to their invitations" ON public.project_invitations;
DROP POLICY IF EXISTS "Project owners can create invitations" ON public.project_invitations;
DROP POLICY IF EXISTS "Project admins can view invitations" ON public.project_invitations;
DROP POLICY IF EXISTS "Project admins can delete invitations" ON public.project_invitations;

-- Step 2: Create SELECT policy - Users can view invitations they received
CREATE POLICY "Users can view their own invitations"
ON public.project_invitations
FOR SELECT
TO authenticated
USING (
  email = (SELECT email FROM public.profiles WHERE user_id = auth.uid())
);

-- Step 3: Create SELECT policy - Project owners/admins can view all invitations for their projects
CREATE POLICY "Project admins can view invitations"
ON public.project_invitations
FOR SELECT
TO authenticated
USING (
  project_id IN (
    SELECT id FROM projects 
    WHERE owner_id IN (
      SELECT id FROM profiles WHERE user_id = auth.uid()
    )
    OR id IN (
      SELECT project_id FROM project_shares 
      WHERE shared_with_user_id IN (
        SELECT id FROM profiles WHERE user_id = auth.uid()
      )
      AND role IN ('admin', 'editor')
    )
  )
);

-- Step 4: Create INSERT policy - Project owners/admins can create invitations
CREATE POLICY "Project owners can create invitations"
ON public.project_invitations
FOR INSERT
TO authenticated
WITH CHECK (
  project_id IN (
    SELECT id FROM projects 
    WHERE owner_id IN (
      SELECT id FROM profiles WHERE user_id = auth.uid()
    )
    OR id IN (
      SELECT project_id FROM project_shares 
      WHERE shared_with_user_id IN (
        SELECT id FROM profiles WHERE user_id = auth.uid()
      )
      AND role = 'admin'
    )
  )
);

-- Step 5: Create UPDATE policy - Users can respond to their invitations
CREATE POLICY "Users can respond to their invitations"
ON public.project_invitations
FOR UPDATE
TO authenticated
USING (
  email = (SELECT email FROM public.profiles WHERE user_id = auth.uid())
)
WITH CHECK (
  email = (SELECT email FROM public.profiles WHERE user_id = auth.uid())
);

-- Step 6: Create DELETE policy - Project owners/admins can cancel invitations
CREATE POLICY "Project admins can delete invitations"
ON public.project_invitations
FOR DELETE
TO authenticated
USING (
  project_id IN (
    SELECT id FROM projects 
    WHERE owner_id IN (
      SELECT id FROM profiles WHERE user_id = auth.uid()
    )
    OR id IN (
      SELECT project_id FROM project_shares 
      WHERE shared_with_user_id IN (
        SELECT id FROM profiles WHERE user_id = auth.uid()
      )
      AND role = 'admin'
    )
  )
);

-- Step 7: Verify policies
SELECT 
  schemaname,
  tablename,
  policyname,
  cmd,
  qual,
  with_check
FROM pg_policies
WHERE tablename = 'project_invitations'
ORDER BY policyname;
