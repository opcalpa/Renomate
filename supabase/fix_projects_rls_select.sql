-- Fix RLS policies for projects table to allow SELECT for team members
-- This fixes the 406 Not Acceptable error when fetching project owner

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

-- Verify the policy was created
SELECT 
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd,
  qual
FROM pg_policies 
WHERE tablename = 'projects' 
AND policyname = 'Users can view projects they have access to';
