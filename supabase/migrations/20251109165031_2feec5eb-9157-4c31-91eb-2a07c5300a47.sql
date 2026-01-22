-- Create comprehensive security definer functions to avoid recursion

-- Function to check if user owns a project
CREATE OR REPLACE FUNCTION public.user_owns_project(project_id uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.projects 
    WHERE id = project_id 
    AND owner_id = (SELECT id FROM public.profiles WHERE user_id = auth.uid() LIMIT 1)
  );
$$;

-- Function to check if user has access to project via shares
CREATE OR REPLACE FUNCTION public.user_has_project_access(project_id uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.project_shares 
    WHERE project_shares.project_id = $1
    AND shared_with_user_id = (SELECT id FROM public.profiles WHERE user_id = auth.uid() LIMIT 1)
  );
$$;

-- Drop and recreate project_shares policies first
DROP POLICY IF EXISTS "Project owners can manage shares" ON public.project_shares;
DROP POLICY IF EXISTS "Users can view shares for their projects" ON public.project_shares;

CREATE POLICY "Project owners can manage shares" 
ON public.project_shares 
FOR ALL 
USING (public.user_owns_project(project_id));

CREATE POLICY "Users can view shares for their projects" 
ON public.project_shares 
FOR SELECT 
USING (
  public.user_owns_project(project_id) 
  OR shared_with_user_id = public.get_user_profile_id()
);

-- Now update projects policies to use the new functions
DROP POLICY IF EXISTS "Users can view projects they own or have access to" ON public.projects;

CREATE POLICY "Users can view projects they own or have access to" 
ON public.projects 
FOR SELECT 
USING (
  owner_id = public.get_user_profile_id() 
  OR public.user_has_project_access(id)
);