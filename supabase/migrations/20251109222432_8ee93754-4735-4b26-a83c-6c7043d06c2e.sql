-- Create enum for contractor/guest roles
CREATE TYPE public.contractor_role AS ENUM (
  'painter',
  'electrician',
  'plumber',
  'carpenter',
  'designer',
  'architect',
  'general_contractor',
  'supplier',
  'other'
);

-- Create project invitations table
CREATE TABLE public.project_invitations (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  project_id UUID NOT NULL REFERENCES public.projects(id) ON DELETE CASCADE,
  invited_by_user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  invited_email TEXT NOT NULL,
  contractor_role contractor_role NOT NULL,
  access_level TEXT NOT NULL DEFAULT 'viewer',
  status TEXT NOT NULL DEFAULT 'pending',
  invitation_token UUID NOT NULL DEFAULT gen_random_uuid() UNIQUE,
  expires_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT (now() + INTERVAL '7 days'),
  accepted_at TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  CONSTRAINT valid_status CHECK (status IN ('pending', 'accepted', 'declined', 'expired')),
  CONSTRAINT valid_access_level CHECK (access_level IN ('viewer', 'editor', 'admin'))
);

-- Add contractor_role to project_shares table
ALTER TABLE public.project_shares 
ADD COLUMN contractor_role contractor_role,
ADD COLUMN can_create_purchase_requests BOOLEAN DEFAULT false;

-- Update project_shares to have more specific access levels
ALTER TABLE public.project_shares
DROP CONSTRAINT IF EXISTS project_shares_role_check;

ALTER TABLE public.project_shares
ADD CONSTRAINT project_shares_role_check 
CHECK (role IN ('viewer', 'editor', 'admin'));

-- Enable RLS on project_invitations
ALTER TABLE public.project_invitations ENABLE ROW LEVEL SECURITY;

-- Create indexes for better performance
CREATE INDEX idx_project_invitations_project_id ON public.project_invitations(project_id);
CREATE INDEX idx_project_invitations_email ON public.project_invitations(invited_email);
CREATE INDEX idx_project_invitations_token ON public.project_invitations(invitation_token);
CREATE INDEX idx_project_invitations_status ON public.project_invitations(status);
CREATE INDEX idx_project_shares_contractor_role ON public.project_shares(contractor_role);

-- Create trigger for updating project_invitations updated_at
CREATE TRIGGER update_project_invitations_updated_at
BEFORE UPDATE ON public.project_invitations
FOR EACH ROW
EXECUTE FUNCTION public.update_updated_at_column();

-- RLS Policies for project_invitations

-- Project owners can create invitations for their projects
CREATE POLICY "Project owners can create invitations"
ON public.project_invitations
FOR INSERT
WITH CHECK (
  project_id IN (
    SELECT id FROM public.projects 
    WHERE owner_id = get_user_profile_id()
  )
);

-- Project owners can view invitations for their projects
CREATE POLICY "Project owners can view invitations"
ON public.project_invitations
FOR SELECT
USING (
  project_id IN (
    SELECT id FROM public.projects 
    WHERE owner_id = get_user_profile_id()
  )
);

-- Users can view invitations sent to their email
CREATE POLICY "Users can view their own invitations"
ON public.project_invitations
FOR SELECT
USING (
  invited_email = (
    SELECT email FROM public.profiles 
    WHERE user_id = auth.uid()
  )
);

-- Users can update invitations sent to their email (accept/decline)
CREATE POLICY "Users can respond to their invitations"
ON public.project_invitations
FOR UPDATE
USING (
  invited_email = (
    SELECT email FROM public.profiles 
    WHERE user_id = auth.uid()
  )
)
WITH CHECK (
  invited_email = (
    SELECT email FROM public.profiles 
    WHERE user_id = auth.uid()
  )
);

-- Project owners can delete invitations
CREATE POLICY "Project owners can delete invitations"
ON public.project_invitations
FOR DELETE
USING (
  project_id IN (
    SELECT id FROM public.projects 
    WHERE owner_id = get_user_profile_id()
  )
);

-- Update RLS policies for materials to support guest access

-- Drop existing material policies
DROP POLICY IF EXISTS "Users can manage materials in accessible tasks" ON public.materials;
DROP POLICY IF EXISTS "Users can view materials in accessible tasks" ON public.materials;

-- Recreate with guest support
CREATE POLICY "Users can view materials in accessible projects"
ON public.materials
FOR SELECT
USING (
  task_id IN (
    SELECT id FROM public.tasks
    WHERE project_id IN (
      SELECT id FROM public.projects
      WHERE owner_id = get_user_profile_id()
      OR user_has_project_access(id)
    )
  )
);

CREATE POLICY "Editors can manage materials in accessible projects"
ON public.materials
FOR ALL
USING (
  task_id IN (
    SELECT id FROM public.tasks
    WHERE project_id IN (
      SELECT id FROM public.projects
      WHERE owner_id = get_user_profile_id()
      OR id IN (
        SELECT project_id FROM public.project_shares
        WHERE shared_with_user_id = get_user_profile_id()
        AND role IN ('editor', 'admin')
      )
    )
  )
);

-- Update RLS policies for purchase_requests to allow guests to create them

-- Drop existing purchase request policies
DROP POLICY IF EXISTS "Users can create purchase requests" ON public.purchase_requests;
DROP POLICY IF EXISTS "Users can update purchase requests" ON public.purchase_requests;
DROP POLICY IF EXISTS "Users can view purchase requests in accessible materials" ON public.purchase_requests;

-- Recreate with guest support
CREATE POLICY "Users with access can create purchase requests"
ON public.purchase_requests
FOR INSERT
WITH CHECK (
  material_id IN (
    SELECT id FROM public.materials
    WHERE task_id IN (
      SELECT id FROM public.tasks
      WHERE project_id IN (
        SELECT id FROM public.projects
        WHERE owner_id = get_user_profile_id()
        OR id IN (
          SELECT project_id FROM public.project_shares
          WHERE shared_with_user_id = get_user_profile_id()
          AND can_create_purchase_requests = true
        )
      )
    )
  )
);

CREATE POLICY "Project owners and admins can update purchase requests"
ON public.purchase_requests
FOR UPDATE
USING (
  material_id IN (
    SELECT id FROM public.materials
    WHERE task_id IN (
      SELECT id FROM public.tasks
      WHERE project_id IN (
        SELECT id FROM public.projects
        WHERE owner_id = get_user_profile_id()
        OR id IN (
          SELECT project_id FROM public.project_shares
          WHERE shared_with_user_id = get_user_profile_id()
          AND role IN ('admin', 'editor')
        )
      )
    )
  )
);

CREATE POLICY "Users can view purchase requests in accessible projects"
ON public.purchase_requests
FOR SELECT
USING (
  material_id IN (
    SELECT id FROM public.materials
    WHERE task_id IN (
      SELECT id FROM public.tasks
      WHERE project_id IN (
        SELECT id FROM public.projects
        WHERE owner_id = get_user_profile_id()
        OR user_has_project_access(id)
      )
    )
  )
);

-- Create helper function to check if user can manage a project
CREATE OR REPLACE FUNCTION public.user_can_manage_project(project_id uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.projects 
    WHERE id = project_id 
    AND owner_id = get_user_profile_id()
  ) OR EXISTS (
    SELECT 1 FROM public.project_shares
    WHERE project_shares.project_id = $1
    AND shared_with_user_id = get_user_profile_id()
    AND role IN ('admin', 'editor')
  );
$$;

-- Add comment explaining the schema
COMMENT ON TABLE public.project_invitations IS 'Stores pending and accepted project invitations with contractor role assignments';
COMMENT ON COLUMN public.project_shares.contractor_role IS 'Specific trade/role of the contractor (painter, electrician, etc.)';
COMMENT ON COLUMN public.project_shares.can_create_purchase_requests IS 'Whether this user can create purchase requests for the project';