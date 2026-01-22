-- Create security definer function to get current user's profile ID
CREATE OR REPLACE FUNCTION public.get_user_profile_id()
RETURNS uuid
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT id FROM public.profiles WHERE user_id = auth.uid() LIMIT 1;
$$;

-- Drop existing policies on projects table
DROP POLICY IF EXISTS "Users can view projects they own or have access to" ON public.projects;
DROP POLICY IF EXISTS "Users can create their own projects" ON public.projects;
DROP POLICY IF EXISTS "Project owners can update their projects" ON public.projects;
DROP POLICY IF EXISTS "Project owners can delete their projects" ON public.projects;

-- Recreate policies using the security definer function
CREATE POLICY "Users can view projects they own or have access to" 
ON public.projects 
FOR SELECT 
USING (
  owner_id = public.get_user_profile_id() 
  OR id IN (
    SELECT project_id 
    FROM project_shares 
    WHERE shared_with_user_id = public.get_user_profile_id()
  )
);

CREATE POLICY "Users can create their own projects" 
ON public.projects 
FOR INSERT 
WITH CHECK (owner_id = public.get_user_profile_id());

CREATE POLICY "Project owners can update their projects" 
ON public.projects 
FOR UPDATE 
USING (owner_id = public.get_user_profile_id());

CREATE POLICY "Project owners can delete their projects" 
ON public.projects 
FOR DELETE 
USING (owner_id = public.get_user_profile_id());