-- Create profiles table for user data
CREATE TABLE public.profiles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL UNIQUE,
  name TEXT NOT NULL,
  email TEXT,
  phone TEXT,
  role TEXT DEFAULT 'homeowner' CHECK (role IN ('homeowner', 'contractor', 'designer', 'family')),
  language_preference TEXT DEFAULT 'en',
  avatar_url TEXT,
  created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
  updated_at TIMESTAMPTZ DEFAULT now() NOT NULL
);

-- Create projects table
CREATE TABLE public.projects (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  description TEXT,
  owner_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  floor_plan_data JSONB,
  status TEXT DEFAULT 'planning' CHECK (status IN ('planning', 'in_progress', 'completed', 'on_hold')),
  total_budget DECIMAL(12, 2),
  spent_amount DECIMAL(12, 2) DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
  updated_at TIMESTAMPTZ DEFAULT now() NOT NULL
);

-- Create rooms table
CREATE TABLE public.rooms (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  project_id UUID REFERENCES public.projects(id) ON DELETE CASCADE NOT NULL,
  name TEXT NOT NULL,
  description TEXT,
  dimensions JSONB,
  floor_plan_position JSONB,
  created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
  updated_at TIMESTAMPTZ DEFAULT now() NOT NULL
);

-- Create contractors table
CREATE TABLE public.contractors (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  created_by_user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  name TEXT NOT NULL,
  category TEXT,
  company TEXT,
  phone TEXT,
  email TEXT,
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
  updated_at TIMESTAMPTZ DEFAULT now() NOT NULL
);

-- Create tasks table
CREATE TABLE public.tasks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  project_id UUID REFERENCES public.projects(id) ON DELETE CASCADE NOT NULL,
  room_id UUID REFERENCES public.rooms(id) ON DELETE SET NULL,
  title TEXT NOT NULL,
  description TEXT,
  status TEXT DEFAULT 'todo' CHECK (status IN ('todo', 'in_progress', 'completed', 'blocked')),
  priority TEXT DEFAULT 'medium' CHECK (priority IN ('low', 'medium', 'high')),
  assigned_to_contractor_id UUID REFERENCES public.contractors(id) ON DELETE SET NULL,
  created_by_user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  due_date DATE,
  floor_plan_position JSONB,
  created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
  updated_at TIMESTAMPTZ DEFAULT now() NOT NULL
);

-- Create materials table
CREATE TABLE public.materials (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  task_id UUID REFERENCES public.tasks(id) ON DELETE CASCADE NOT NULL,
  name TEXT NOT NULL,
  quantity DECIMAL(10, 2),
  unit TEXT,
  cost DECIMAL(12, 2),
  vendor_name TEXT,
  vendor_link TEXT,
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'ordered', 'delivered', 'installed')),
  created_by_user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
  updated_at TIMESTAMPTZ DEFAULT now() NOT NULL
);

-- Create photos table
CREATE TABLE public.photos (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  linked_to_type TEXT NOT NULL CHECK (linked_to_type IN ('project', 'room', 'task')),
  linked_to_id UUID NOT NULL,
  url TEXT NOT NULL,
  caption TEXT,
  uploaded_by_user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  created_at TIMESTAMPTZ DEFAULT now() NOT NULL
);

-- Create notes table
CREATE TABLE public.notes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  linked_to_type TEXT NOT NULL CHECK (linked_to_type IN ('project', 'room', 'task')),
  linked_to_id UUID NOT NULL,
  content TEXT NOT NULL,
  created_by_user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
  updated_at TIMESTAMPTZ DEFAULT now() NOT NULL
);

-- Create project_shares table for collaboration
CREATE TABLE public.project_shares (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  project_id UUID REFERENCES public.projects(id) ON DELETE CASCADE NOT NULL,
  shared_with_user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  role TEXT DEFAULT 'viewer' CHECK (role IN ('viewer', 'editor', 'admin')),
  created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
  UNIQUE(project_id, shared_with_user_id)
);

-- Create purchase_requests table
CREATE TABLE public.purchase_requests (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  material_id UUID REFERENCES public.materials(id) ON DELETE CASCADE NOT NULL,
  requested_by_user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected')),
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
  updated_at TIMESTAMPTZ DEFAULT now() NOT NULL
);

-- Enable Row Level Security
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.projects ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.rooms ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.contractors ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.tasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.materials ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.photos ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.project_shares ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.purchase_requests ENABLE ROW LEVEL SECURITY;

-- RLS Policies for profiles
CREATE POLICY "Users can view all profiles" ON public.profiles FOR SELECT USING (true);
CREATE POLICY "Users can update own profile" ON public.profiles FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own profile" ON public.profiles FOR INSERT WITH CHECK (auth.uid() = user_id);

-- RLS Policies for projects
CREATE POLICY "Users can view projects they own or have access to" ON public.projects FOR SELECT 
  USING (
    owner_id = (SELECT id FROM public.profiles WHERE user_id = auth.uid())
    OR id IN (SELECT project_id FROM public.project_shares WHERE shared_with_user_id = (SELECT id FROM public.profiles WHERE user_id = auth.uid()))
  );
CREATE POLICY "Users can create their own projects" ON public.projects FOR INSERT 
  WITH CHECK (owner_id = (SELECT id FROM public.profiles WHERE user_id = auth.uid()));
CREATE POLICY "Project owners can update their projects" ON public.projects FOR UPDATE 
  USING (owner_id = (SELECT id FROM public.profiles WHERE user_id = auth.uid()));
CREATE POLICY "Project owners can delete their projects" ON public.projects FOR DELETE 
  USING (owner_id = (SELECT id FROM public.profiles WHERE user_id = auth.uid()));

-- RLS Policies for rooms
CREATE POLICY "Users can view rooms in accessible projects" ON public.rooms FOR SELECT 
  USING (
    project_id IN (
      SELECT id FROM public.projects WHERE 
        owner_id = (SELECT id FROM public.profiles WHERE user_id = auth.uid())
        OR id IN (SELECT project_id FROM public.project_shares WHERE shared_with_user_id = (SELECT id FROM public.profiles WHERE user_id = auth.uid()))
    )
  );
CREATE POLICY "Users can manage rooms in accessible projects" ON public.rooms FOR ALL 
  USING (
    project_id IN (
      SELECT id FROM public.projects WHERE 
        owner_id = (SELECT id FROM public.profiles WHERE user_id = auth.uid())
        OR id IN (SELECT project_id FROM public.project_shares WHERE shared_with_user_id = (SELECT id FROM public.profiles WHERE user_id = auth.uid()) AND role IN ('editor', 'admin'))
    )
  );

-- RLS Policies for contractors
CREATE POLICY "Users can view contractors they created" ON public.contractors FOR SELECT 
  USING (created_by_user_id = (SELECT id FROM public.profiles WHERE user_id = auth.uid()));
CREATE POLICY "Users can manage their own contractors" ON public.contractors FOR ALL 
  USING (created_by_user_id = (SELECT id FROM public.profiles WHERE user_id = auth.uid()));

-- RLS Policies for tasks
CREATE POLICY "Users can view tasks in accessible projects" ON public.tasks FOR SELECT 
  USING (
    project_id IN (
      SELECT id FROM public.projects WHERE 
        owner_id = (SELECT id FROM public.profiles WHERE user_id = auth.uid())
        OR id IN (SELECT project_id FROM public.project_shares WHERE shared_with_user_id = (SELECT id FROM public.profiles WHERE user_id = auth.uid()))
    )
  );
CREATE POLICY "Users can manage tasks in accessible projects" ON public.tasks FOR ALL 
  USING (
    project_id IN (
      SELECT id FROM public.projects WHERE 
        owner_id = (SELECT id FROM public.profiles WHERE user_id = auth.uid())
        OR id IN (SELECT project_id FROM public.project_shares WHERE shared_with_user_id = (SELECT id FROM public.profiles WHERE user_id = auth.uid()) AND role IN ('editor', 'admin'))
    )
  );

-- RLS Policies for materials
CREATE POLICY "Users can view materials in accessible tasks" ON public.materials FOR SELECT 
  USING (
    task_id IN (
      SELECT id FROM public.tasks WHERE project_id IN (
        SELECT id FROM public.projects WHERE 
          owner_id = (SELECT id FROM public.profiles WHERE user_id = auth.uid())
          OR id IN (SELECT project_id FROM public.project_shares WHERE shared_with_user_id = (SELECT id FROM public.profiles WHERE user_id = auth.uid()))
      )
    )
  );
CREATE POLICY "Users can manage materials in accessible tasks" ON public.materials FOR ALL 
  USING (
    task_id IN (
      SELECT id FROM public.tasks WHERE project_id IN (
        SELECT id FROM public.projects WHERE 
          owner_id = (SELECT id FROM public.profiles WHERE user_id = auth.uid())
          OR id IN (SELECT project_id FROM public.project_shares WHERE shared_with_user_id = (SELECT id FROM public.profiles WHERE user_id = auth.uid()) AND role IN ('editor', 'admin'))
      )
    )
  );

-- RLS Policies for photos
CREATE POLICY "Users can view photos in accessible entities" ON public.photos FOR SELECT USING (true);
CREATE POLICY "Users can upload photos" ON public.photos FOR INSERT WITH CHECK (uploaded_by_user_id = (SELECT id FROM public.profiles WHERE user_id = auth.uid()));
CREATE POLICY "Users can delete own photos" ON public.photos FOR DELETE USING (uploaded_by_user_id = (SELECT id FROM public.profiles WHERE user_id = auth.uid()));

-- RLS Policies for notes
CREATE POLICY "Users can view notes in accessible entities" ON public.notes FOR SELECT USING (true);
CREATE POLICY "Users can create notes" ON public.notes FOR INSERT WITH CHECK (created_by_user_id = (SELECT id FROM public.profiles WHERE user_id = auth.uid()));
CREATE POLICY "Users can update own notes" ON public.notes FOR UPDATE USING (created_by_user_id = (SELECT id FROM public.profiles WHERE user_id = auth.uid()));
CREATE POLICY "Users can delete own notes" ON public.notes FOR DELETE USING (created_by_user_id = (SELECT id FROM public.profiles WHERE user_id = auth.uid()));

-- RLS Policies for project_shares
CREATE POLICY "Users can view shares for their projects" ON public.project_shares FOR SELECT 
  USING (
    project_id IN (SELECT id FROM public.projects WHERE owner_id = (SELECT id FROM public.profiles WHERE user_id = auth.uid()))
    OR shared_with_user_id = (SELECT id FROM public.profiles WHERE user_id = auth.uid())
  );
CREATE POLICY "Project owners can manage shares" ON public.project_shares FOR ALL 
  USING (project_id IN (SELECT id FROM public.projects WHERE owner_id = (SELECT id FROM public.profiles WHERE user_id = auth.uid())));

-- RLS Policies for purchase_requests
CREATE POLICY "Users can view purchase requests in accessible materials" ON public.purchase_requests FOR SELECT 
  USING (
    material_id IN (
      SELECT id FROM public.materials WHERE task_id IN (
        SELECT id FROM public.tasks WHERE project_id IN (
          SELECT id FROM public.projects WHERE 
            owner_id = (SELECT id FROM public.profiles WHERE user_id = auth.uid())
            OR id IN (SELECT project_id FROM public.project_shares WHERE shared_with_user_id = (SELECT id FROM public.profiles WHERE user_id = auth.uid()))
        )
      )
    )
  );
CREATE POLICY "Users can create purchase requests" ON public.purchase_requests FOR INSERT 
  WITH CHECK (requested_by_user_id = (SELECT id FROM public.profiles WHERE user_id = auth.uid()));
CREATE POLICY "Users can update purchase requests" ON public.purchase_requests FOR UPDATE 
  USING (
    material_id IN (
      SELECT id FROM public.materials WHERE task_id IN (
        SELECT id FROM public.tasks WHERE project_id IN (
          SELECT id FROM public.projects WHERE owner_id = (SELECT id FROM public.profiles WHERE user_id = auth.uid())
        )
      )
    )
  );

-- Create function to handle new user signup
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  INSERT INTO public.profiles (user_id, name, email)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'name', 'User'),
    NEW.email
  );
  RETURN NEW;
END;
$$;

-- Create trigger for new user signup
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Create function to update updated_at timestamp
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$;

-- Create triggers for updated_at
CREATE TRIGGER update_profiles_updated_at BEFORE UPDATE ON public.profiles FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();
CREATE TRIGGER update_projects_updated_at BEFORE UPDATE ON public.projects FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();
CREATE TRIGGER update_rooms_updated_at BEFORE UPDATE ON public.rooms FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();
CREATE TRIGGER update_contractors_updated_at BEFORE UPDATE ON public.contractors FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();
CREATE TRIGGER update_tasks_updated_at BEFORE UPDATE ON public.tasks FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();
CREATE TRIGGER update_materials_updated_at BEFORE UPDATE ON public.materials FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();
CREATE TRIGGER update_notes_updated_at BEFORE UPDATE ON public.notes FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();
CREATE TRIGGER update_purchase_requests_updated_at BEFORE UPDATE ON public.purchase_requests FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();-- Create security definer function to get current user's profile ID
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
USING (owner_id = public.get_user_profile_id());-- Create comprehensive security definer functions to avoid recursion

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
);-- Add start_date and finish_date to tasks table
ALTER TABLE public.tasks 
ADD COLUMN start_date DATE,
ADD COLUMN finish_date DATE;

-- Add a check constraint to ensure finish_date is after start_date
ALTER TABLE public.tasks
ADD CONSTRAINT tasks_dates_check 
CHECK (finish_date IS NULL OR start_date IS NULL OR finish_date >= start_date);

-- Add an index for better query performance on date filtering
CREATE INDEX idx_tasks_dates ON public.tasks(start_date, finish_date);-- Create enum for contractor/guest roles
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
COMMENT ON COLUMN public.project_shares.can_create_purchase_requests IS 'Whether this user can create purchase requests for the project';-- Add phone_number column to project_invitations table
ALTER TABLE public.project_invitations 
ADD COLUMN invited_phone text,
ADD COLUMN delivery_method text DEFAULT 'email' CHECK (delivery_method IN ('email', 'sms'));

-- Update constraint to allow either email or phone
ALTER TABLE public.project_invitations 
DROP CONSTRAINT IF EXISTS project_invitations_invited_email_check;

-- Add check constraint to ensure at least one contact method is provided
ALTER TABLE public.project_invitations 
ADD CONSTRAINT check_contact_method CHECK (
  (invited_email IS NOT NULL AND invited_email != '') OR 
  (invited_phone IS NOT NULL AND invited_phone != '')
);

-- Update RLS policy for users viewing their own invitations to include phone
DROP POLICY IF EXISTS "Users can view their own invitations" ON public.project_invitations;
CREATE POLICY "Users can view their own invitations"
ON public.project_invitations
FOR SELECT
TO authenticated
USING (
  invited_email = (SELECT email FROM public.profiles WHERE user_id = auth.uid())
  OR invited_phone = (SELECT phone FROM public.profiles WHERE user_id = auth.uid())
);

-- Update RLS policy for users responding to invitations to include phone
DROP POLICY IF EXISTS "Users can respond to their invitations" ON public.project_invitations;
CREATE POLICY "Users can respond to their invitations"
ON public.project_invitations
FOR UPDATE
TO authenticated
USING (
  invited_email = (SELECT email FROM public.profiles WHERE user_id = auth.uid())
  OR invited_phone = (SELECT phone FROM public.profiles WHERE user_id = auth.uid())
)
WITH CHECK (
  invited_email = (SELECT email FROM public.profiles WHERE user_id = auth.uid())
  OR invited_phone = (SELECT phone FROM public.profiles WHERE user_id = auth.uid())
);-- Enable realtime for purchase_requests table
ALTER TABLE public.purchase_requests REPLICA IDENTITY FULL;
ALTER PUBLICATION supabase_realtime ADD TABLE public.purchase_requests;-- Add finish_goal_date to projects table
ALTER TABLE public.projects
ADD COLUMN finish_goal_date date;-- Add progress tracking to tasks
ALTER TABLE public.tasks
ADD COLUMN progress integer DEFAULT 0 CHECK (progress >= 0 AND progress <= 100);

-- Create task dependencies table
CREATE TABLE public.task_dependencies (
  id uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  task_id uuid NOT NULL REFERENCES public.tasks(id) ON DELETE CASCADE,
  depends_on_task_id uuid NOT NULL REFERENCES public.tasks(id) ON DELETE CASCADE,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  UNIQUE(task_id, depends_on_task_id),
  CHECK (task_id != depends_on_task_id)
);

-- Enable RLS on task_dependencies
ALTER TABLE public.task_dependencies ENABLE ROW LEVEL SECURITY;

-- RLS policies for task_dependencies
CREATE POLICY "Users can view dependencies in accessible projects"
ON public.task_dependencies
FOR SELECT
USING (
  task_id IN (
    SELECT tasks.id FROM tasks
    WHERE tasks.project_id IN (
      SELECT projects.id FROM projects
      WHERE projects.owner_id = get_user_profile_id()
      OR user_has_project_access(projects.id)
    )
  )
);

CREATE POLICY "Editors can manage dependencies in accessible projects"
ON public.task_dependencies
FOR ALL
USING (
  task_id IN (
    SELECT tasks.id FROM tasks
    WHERE tasks.project_id IN (
      SELECT projects.id FROM projects
      WHERE projects.owner_id = get_user_profile_id()
      OR projects.id IN (
        SELECT project_shares.project_id FROM project_shares
        WHERE project_shares.shared_with_user_id = get_user_profile_id()
        AND project_shares.role IN ('editor', 'admin')
      )
    )
  )
);-- Drop the existing constraint if it exists
ALTER TABLE public.materials 
DROP CONSTRAINT IF EXISTS materials_status_check;

-- Update all existing materials to use new status naming
UPDATE public.materials 
SET status = CASE 
  WHEN status IN ('pending', 'approved') THEN 'new'
  WHEN status = 'rejected' THEN 'declined'
  WHEN status = 'done' THEN 'done'
  ELSE 'new'
END;

-- Change default status to 'new'
ALTER TABLE public.materials 
ALTER COLUMN status SET DEFAULT 'new';

-- Update RLS policies to allow any user with project access to manage materials (purchase orders)
DROP POLICY IF EXISTS "Editors can manage materials in accessible projects" ON public.materials;

CREATE POLICY "Users can add materials in accessible projects"
ON public.materials
FOR INSERT
WITH CHECK (
  task_id IN (
    SELECT tasks.id FROM tasks
    WHERE tasks.project_id IN (
      SELECT projects.id FROM projects
      WHERE projects.owner_id = get_user_profile_id() 
        OR user_has_project_access(projects.id)
    )
  )
);

CREATE POLICY "Users can update materials in accessible projects"
ON public.materials
FOR UPDATE
USING (
  task_id IN (
    SELECT tasks.id FROM tasks
    WHERE tasks.project_id IN (
      SELECT projects.id FROM projects
      WHERE projects.owner_id = get_user_profile_id() 
        OR user_has_project_access(projects.id)
    )
  )
);

CREATE POLICY "Users can delete materials in accessible projects"
ON public.materials
FOR DELETE
USING (
  task_id IN (
    SELECT tasks.id FROM tasks
    WHERE tasks.project_id IN (
      SELECT projects.id FROM projects
      WHERE projects.owner_id = get_user_profile_id() 
        OR user_has_project_access(projects.id)
    )
  )
);-- Step 1: Update all existing data to use new status values
UPDATE public.materials 
  SET status = CASE 
    WHEN status IS NULL OR status = 'pending' THEN 'new'
    WHEN status = 'approved' THEN 'done'
    WHEN status = 'rejected' THEN 'declined'
    ELSE status
  END
  WHERE status IS NULL OR status NOT IN ('new', 'declined', 'done');

-- Step 2: Change default status to 'new'
ALTER TABLE public.materials 
  ALTER COLUMN status SET DEFAULT 'new';

-- Step 3: Make status NOT NULL
ALTER TABLE public.materials 
  ALTER COLUMN status SET NOT NULL;

-- Step 4: Drop existing constraint if any
DO $$ 
BEGIN
  IF EXISTS (
    SELECT 1 FROM pg_constraint 
    WHERE conname = 'materials_status_check'
  ) THEN
    ALTER TABLE public.materials DROP CONSTRAINT materials_status_check;
  END IF;
END $$;

-- Step 5: Add check constraint (NOT VALID to skip existing rows initially)
ALTER TABLE public.materials 
  ADD CONSTRAINT materials_status_check 
  CHECK (status IN ('new', 'declined', 'done')) NOT VALID;

-- Step 6: Validate the constraint (checks existing rows)
ALTER TABLE public.materials 
  VALIDATE CONSTRAINT materials_status_check;

-- Step 7: Drop all existing RLS policies on materials
DROP POLICY IF EXISTS "Users can view materials in accessible projects" ON public.materials;
DROP POLICY IF EXISTS "Editors can manage materials in accessible projects" ON public.materials;
DROP POLICY IF EXISTS "Users can add materials in accessible projects" ON public.materials;
DROP POLICY IF EXISTS "Users can update materials in accessible projects" ON public.materials;
DROP POLICY IF EXISTS "Users can delete materials in accessible projects" ON public.materials;

-- Step 8: Create new RLS policies to allow any user with project access
CREATE POLICY "Users can view materials in accessible projects"
ON public.materials
FOR SELECT
USING (
  task_id IN (
    SELECT tasks.id FROM tasks
    WHERE tasks.project_id IN (
      SELECT projects.id FROM projects
      WHERE projects.owner_id = get_user_profile_id() 
        OR user_has_project_access(projects.id)
    )
  )
);

CREATE POLICY "Users can add materials in accessible projects"
ON public.materials
FOR INSERT
WITH CHECK (
  task_id IN (
    SELECT tasks.id FROM tasks
    WHERE tasks.project_id IN (
      SELECT projects.id FROM projects
      WHERE projects.owner_id = get_user_profile_id() 
        OR user_has_project_access(projects.id)
    )
  )
);

CREATE POLICY "Users can update materials in accessible projects"
ON public.materials
FOR UPDATE
USING (
  task_id IN (
    SELECT tasks.id FROM tasks
    WHERE tasks.project_id IN (
      SELECT projects.id FROM projects
      WHERE projects.owner_id = get_user_profile_id() 
        OR user_has_project_access(projects.id)
    )
  )
);

CREATE POLICY "Users can delete materials in accessible projects"
ON public.materials
FOR DELETE
USING (
  task_id IN (
    SELECT tasks.id FROM tasks
    WHERE tasks.project_id IN (
      SELECT projects.id FROM projects
      WHERE projects.owner_id = get_user_profile_id() 
        OR user_has_project_access(projects.id)
    )
  )
);-- Make task_id optional for materials so purchase orders can be added without a specific task
ALTER TABLE public.materials 
  ALTER COLUMN task_id DROP NOT NULL;

-- Update RLS policies to allow viewing materials at project level
DROP POLICY IF EXISTS "Users can view materials in accessible projects" ON public.materials;

CREATE POLICY "Users can view materials in accessible projects"
ON public.materials
FOR SELECT
USING (
  -- Materials with task_id
  (task_id IS NOT NULL AND task_id IN (
    SELECT tasks.id FROM tasks
    WHERE tasks.project_id IN (
      SELECT projects.id FROM projects
      WHERE projects.owner_id = get_user_profile_id() 
        OR user_has_project_access(projects.id)
    )
  ))
  OR
  -- Materials without task_id (project-level purchase orders)
  (task_id IS NULL AND created_by_user_id IN (
    SELECT ps.shared_with_user_id FROM project_shares ps
    WHERE ps.project_id IN (
      SELECT projects.id FROM projects
      WHERE projects.owner_id = get_user_profile_id() 
        OR user_has_project_access(projects.id)
    )
    UNION
    SELECT projects.owner_id FROM projects
    WHERE projects.owner_id = get_user_profile_id()
  ))
);

-- Update insert policy
DROP POLICY IF EXISTS "Users can add materials in accessible projects" ON public.materials;

CREATE POLICY "Users can add materials in accessible projects"
ON public.materials
FOR INSERT
WITH CHECK (
  -- If task_id is provided, check access through task
  (task_id IS NOT NULL AND task_id IN (
    SELECT tasks.id FROM tasks
    WHERE tasks.project_id IN (
      SELECT projects.id FROM projects
      WHERE projects.owner_id = get_user_profile_id() 
        OR user_has_project_access(projects.id)
    )
  ))
  OR
  -- If no task_id, just check user has any project access
  (task_id IS NULL AND created_by_user_id = get_user_profile_id())
);-- Add project_id to materials table for project-level purchase orders
ALTER TABLE public.materials 
  ADD COLUMN project_id uuid REFERENCES public.projects(id) ON DELETE CASCADE;

-- For existing materials with task_id, populate project_id from task
UPDATE public.materials 
SET project_id = (
  SELECT tasks.project_id 
  FROM tasks 
  WHERE tasks.id = materials.task_id
)
WHERE task_id IS NOT NULL;

-- Add constraint: either task_id OR project_id must be set
ALTER TABLE public.materials 
  ADD CONSTRAINT materials_task_or_project_check 
  CHECK (task_id IS NOT NULL OR project_id IS NOT NULL);

-- Update RLS policies to work with project_id
DROP POLICY IF EXISTS "Users can view materials in accessible projects" ON public.materials;
DROP POLICY IF EXISTS "Users can add materials in accessible projects" ON public.materials;
DROP POLICY IF EXISTS "Users can update materials in accessible projects" ON public.materials;
DROP POLICY IF EXISTS "Users can delete materials in accessible projects" ON public.materials;

CREATE POLICY "Users can view materials in accessible projects"
ON public.materials
FOR SELECT
USING (
  project_id IN (
    SELECT projects.id FROM projects
    WHERE projects.owner_id = get_user_profile_id() 
      OR user_has_project_access(projects.id)
  )
);

CREATE POLICY "Users can add materials in accessible projects"
ON public.materials
FOR INSERT
WITH CHECK (
  project_id IN (
    SELECT projects.id FROM projects
    WHERE projects.owner_id = get_user_profile_id() 
      OR user_has_project_access(projects.id)
  )
);

CREATE POLICY "Users can update materials in accessible projects"
ON public.materials
FOR UPDATE
USING (
  project_id IN (
    SELECT projects.id FROM projects
    WHERE projects.owner_id = get_user_profile_id() 
      OR user_has_project_access(projects.id)
  )
);

CREATE POLICY "Users can delete materials in accessible projects"
ON public.materials
FOR DELETE
USING (
  project_id IN (
    SELECT projects.id FROM projects
    WHERE projects.owner_id = get_user_profile_id() 
      OR user_has_project_access(projects.id)
  )
);-- For existing materials with task_id but no project_id, populate project_id from task
UPDATE public.materials 
SET project_id = (
  SELECT tasks.project_id 
  FROM tasks 
  WHERE tasks.id = materials.task_id
)
WHERE task_id IS NOT NULL AND project_id IS NULL;

-- Drop existing constraint if it exists
DO $$ 
BEGIN
  IF EXISTS (
    SELECT 1 FROM pg_constraint 
    WHERE conname = 'materials_task_or_project_check'
  ) THEN
    ALTER TABLE public.materials DROP CONSTRAINT materials_task_or_project_check;
  END IF;
END $$;

-- Add constraint: either task_id OR project_id must be set
ALTER TABLE public.materials 
  ADD CONSTRAINT materials_task_or_project_check 
  CHECK (task_id IS NOT NULL OR project_id IS NOT NULL);

-- Update RLS policies to work with project_id
DROP POLICY IF EXISTS "Users can view materials in accessible projects" ON public.materials;
DROP POLICY IF EXISTS "Users can add materials in accessible projects" ON public.materials;
DROP POLICY IF EXISTS "Users can update materials in accessible projects" ON public.materials;
DROP POLICY IF EXISTS "Users can delete materials in accessible projects" ON public.materials;

CREATE POLICY "Users can view materials in accessible projects"
ON public.materials
FOR SELECT
USING (
  project_id IN (
    SELECT projects.id FROM projects
    WHERE projects.owner_id = get_user_profile_id() 
      OR user_has_project_access(projects.id)
  )
);

CREATE POLICY "Users can add materials in accessible projects"
ON public.materials
FOR INSERT
WITH CHECK (
  project_id IN (
    SELECT projects.id FROM projects
    WHERE projects.owner_id = get_user_profile_id() 
      OR user_has_project_access(projects.id)
  )
);

CREATE POLICY "Users can update materials in accessible projects"
ON public.materials
FOR UPDATE
USING (
  project_id IN (
    SELECT projects.id FROM projects
    WHERE projects.owner_id = get_user_profile_id() 
      OR user_has_project_access(projects.id)
  )
);

CREATE POLICY "Users can delete materials in accessible projects"
ON public.materials
FOR DELETE
USING (
  project_id IN (
    SELECT projects.id FROM projects
    WHERE projects.owner_id = get_user_profile_id() 
      OR user_has_project_access(projects.id)
  )
);-- Add room_id to materials table
ALTER TABLE public.materials
ADD COLUMN room_id uuid REFERENCES public.rooms(id) ON DELETE SET NULL;

-- Create index for better query performance
CREATE INDEX idx_materials_room_id ON public.materials(room_id);-- Create floor_map_plans table for managing multiple floor plans per project
CREATE TABLE public.floor_map_plans (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  project_id UUID NOT NULL,
  name TEXT NOT NULL DEFAULT 'Untitled Plan',
  is_default BOOLEAN NOT NULL DEFAULT false,
  view_settings JSONB NOT NULL DEFAULT '{
    "cameraX": 0,
    "cameraY": 0,
    "zoom": 1,
    "rotation": 0,
    "mode": "floor"
  }'::jsonb,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- Enable Row Level Security
ALTER TABLE public.floor_map_plans ENABLE ROW LEVEL SECURITY;

-- Create policies for floor_map_plans
CREATE POLICY "Users can view plans in accessible projects"
ON public.floor_map_plans
FOR SELECT
USING (
  project_id IN (
    SELECT id FROM projects
    WHERE owner_id = get_user_profile_id()
    OR user_has_project_access(id)
  )
);

CREATE POLICY "Users can manage plans in accessible projects"
ON public.floor_map_plans
FOR ALL
USING (
  project_id IN (
    SELECT id FROM projects
    WHERE owner_id = get_user_profile_id()
    OR user_can_manage_project(id)
  )
);

-- Add trigger for updated_at
CREATE TRIGGER update_floor_map_plans_updated_at
BEFORE UPDATE ON public.floor_map_plans
FOR EACH ROW
EXECUTE FUNCTION public.update_updated_at_column();

-- Add plan_id to floor_map_shapes to associate shapes with specific plans
ALTER TABLE public.floor_map_shapes
ADD COLUMN plan_id UUID REFERENCES public.floor_map_plans(id) ON DELETE CASCADE;

-- Create index for better query performance
CREATE INDEX idx_floor_map_plans_project_id ON public.floor_map_plans(project_id);
CREATE INDEX idx_floor_map_shapes_plan_id ON public.floor_map_shapes(plan_id);-- Enable realtime for rooms table
ALTER PUBLICATION supabase_realtime ADD TABLE public.rooms;-- Add start_date column to projects table
ALTER TABLE public.projects 
ADD COLUMN start_date date;-- Add budget column to tasks table
ALTER TABLE public.tasks 
ADD COLUMN budget numeric DEFAULT 0;-- Add payment status fields to tasks table
ALTER TABLE public.tasks 
ADD COLUMN payment_status text DEFAULT 'not_paid',
ADD COLUMN paid_amount numeric DEFAULT 0;-- First, drop the existing check constraint on status
ALTER TABLE tasks DROP CONSTRAINT IF EXISTS tasks_status_check;

-- Update existing status values
UPDATE tasks 
SET status = 'to_do' 
WHERE status = 'todo';

UPDATE tasks 
SET status = 'done' 
WHERE status = 'completed';

-- Add new check constraint with updated valid status values
ALTER TABLE tasks 
ADD CONSTRAINT tasks_status_check 
CHECK (status IN ('discovery', 'to_do', 'on_hold', 'doing', 'done', 'scrapped'));

-- Add comment documenting valid status values
COMMENT ON COLUMN tasks.status IS 'Valid values: discovery, to_do, on_hold, doing, done, scrapped';-- Add cost_center column to tasks table
ALTER TABLE tasks ADD COLUMN cost_center text;

-- Add comment documenting valid cost center values
COMMENT ON COLUMN tasks.cost_center IS 'Cost center category: floor, paint, construction, kitchen, bathrooms, plumbing, tiles, windows, doors, electricity, carpentry, or custom values';
-- Add 'material_requester' role to project_shares
-- This role allows users to view space plans and manage purchase requests

-- First, let's check if we need to update any constraints or if we can add the role directly
-- The role column in project_shares appears to use text type, so we can add the new role

-- Update RLS policies for floor_map_plans to allow material_requesters to view
DROP POLICY IF EXISTS "Users can view plans in accessible projects" ON public.floor_map_plans;

CREATE POLICY "Users can view plans in accessible projects" 
ON public.floor_map_plans 
FOR SELECT 
USING (
  project_id IN (
    SELECT projects.id
    FROM projects
    WHERE (
      projects.owner_id = get_user_profile_id() 
      OR user_has_project_access(projects.id)
    )
  )
);

-- Update RLS policies for floor_map_shapes to allow material_requesters to view
DROP POLICY IF EXISTS "Users can view shapes in accessible projects" ON public.floor_map_shapes;

CREATE POLICY "Users can view shapes in accessible projects" 
ON public.floor_map_shapes 
FOR SELECT 
USING (
  project_id IN (
    SELECT projects.id
    FROM projects
    WHERE (
      projects.owner_id = get_user_profile_id() 
      OR user_has_project_access(projects.id)
    )
  )
);

-- Update purchase_requests policies to allow material_requesters to manage their own requests
DROP POLICY IF EXISTS "Users with access can create purchase requests" ON public.purchase_requests;

CREATE POLICY "Users with access can create purchase requests" 
ON public.purchase_requests 
FOR INSERT 
WITH CHECK (
  material_id IN (
    SELECT materials.id
    FROM materials
    WHERE materials.task_id IN (
      SELECT tasks.id
      FROM tasks
      WHERE tasks.project_id IN (
        SELECT projects.id
        FROM projects
        WHERE (
          projects.owner_id = get_user_profile_id()
          OR projects.id IN (
            SELECT project_shares.project_id
            FROM project_shares
            WHERE (
              project_shares.shared_with_user_id = get_user_profile_id()
              AND (
                project_shares.can_create_purchase_requests = true
                OR project_shares.role IN ('admin', 'editor', 'material_requester')
              )
            )
          )
        )
      )
    )
  )
);

-- Allow material_requesters to update their own purchase requests
DROP POLICY IF EXISTS "Users can update their own purchase requests" ON public.purchase_requests;

CREATE POLICY "Users can update their own purchase requests" 
ON public.purchase_requests 
FOR UPDATE 
USING (
  requested_by_user_id = get_user_profile_id()
  OR material_id IN (
    SELECT materials.id
    FROM materials
    WHERE materials.task_id IN (
      SELECT tasks.id
      FROM tasks
      WHERE tasks.project_id IN (
        SELECT projects.id
        FROM projects
        WHERE (
          projects.owner_id = get_user_profile_id()
          OR projects.id IN (
            SELECT project_shares.project_id
            FROM project_shares
            WHERE (
              project_shares.shared_with_user_id = get_user_profile_id()
              AND project_shares.role IN ('admin', 'editor')
            )
          )
        )
      )
    )
  )
);

COMMENT ON COLUMN public.project_shares.role IS 'Access role: viewer, editor, admin, or material_requester';