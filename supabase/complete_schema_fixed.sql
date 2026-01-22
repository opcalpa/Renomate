-- FIXED VERSION: Creates floor_map_shapes table before it's referenced

-- Create profiles table for user data
CREATE TABLE IF NOT EXISTS public.profiles (
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
CREATE TABLE IF NOT EXISTS public.projects (
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
CREATE TABLE IF NOT EXISTS public.rooms (
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
CREATE TABLE IF NOT EXISTS public.contractors (
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
CREATE TABLE IF NOT EXISTS public.tasks (
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
  cost_center TEXT,
  created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
  updated_at TIMESTAMPTZ DEFAULT now() NOT NULL
);

-- Create materials table
CREATE TABLE IF NOT EXISTS public.materials (
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
CREATE TABLE IF NOT EXISTS public.photos (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  linked_to_type TEXT NOT NULL CHECK (linked_to_type IN ('project', 'room', 'task')),
  linked_to_id UUID NOT NULL,
  url TEXT NOT NULL,
  caption TEXT,
  uploaded_by_user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  created_at TIMESTAMPTZ DEFAULT now() NOT NULL
);

-- Create notes table
CREATE TABLE IF NOT EXISTS public.notes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  linked_to_type TEXT NOT NULL CHECK (linked_to_type IN ('project', 'room', 'task')),
  linked_to_id UUID NOT NULL,
  content TEXT NOT NULL,
  created_by_user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
  updated_at TIMESTAMPTZ DEFAULT now() NOT NULL
);

-- Create project_shares table for collaboration
CREATE TABLE IF NOT EXISTS public.project_shares (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  project_id UUID REFERENCES public.projects(id) ON DELETE CASCADE NOT NULL,
  shared_with_user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  role TEXT DEFAULT 'viewer' CHECK (role IN ('viewer', 'editor', 'admin', 'material_requester')),
  created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
  UNIQUE(project_id, shared_with_user_id)
);

-- Create purchase_requests table
CREATE TABLE IF NOT EXISTS public.purchase_requests (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  material_id UUID REFERENCES public.materials(id) ON DELETE CASCADE NOT NULL,
  requested_by_user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected')),
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
  updated_at TIMESTAMPTZ DEFAULT now() NOT NULL
);

-- Create project_invitations table
CREATE TABLE IF NOT EXISTS public.project_invitations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  project_id UUID REFERENCES public.projects(id) ON DELETE CASCADE NOT NULL,
  email TEXT NOT NULL,
  role TEXT DEFAULT 'viewer' CHECK (role IN ('viewer', 'editor', 'admin', 'material_requester')),
  token UUID NOT NULL DEFAULT gen_random_uuid() UNIQUE,
  invited_by_user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'rejected')),
  created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
  expires_at TIMESTAMPTZ DEFAULT (now() + INTERVAL '7 days') NOT NULL
);

-- Create task_dependencies table
CREATE TABLE IF NOT EXISTS public.task_dependencies (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  task_id UUID REFERENCES public.tasks(id) ON DELETE CASCADE NOT NULL,
  depends_on_task_id UUID REFERENCES public.tasks(id) ON DELETE CASCADE NOT NULL,
  created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
  UNIQUE(task_id, depends_on_task_id),
  CHECK (task_id != depends_on_task_id)
);

-- Create floor_map_plans table
CREATE TABLE IF NOT EXISTS public.floor_map_plans (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  project_id UUID REFERENCES public.projects(id) ON DELETE CASCADE NOT NULL,
  name TEXT NOT NULL DEFAULT 'Untitled Plan',
  is_default BOOLEAN NOT NULL DEFAULT false,
  view_settings JSONB NOT NULL DEFAULT '{
    "cameraX": 0,
    "cameraY": 0,
    "zoom": 1,
    "rotation": 0,
    "mode": "floor"
  }'::jsonb,
  created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
  updated_at TIMESTAMPTZ DEFAULT now() NOT NULL
);

-- Create floor_map_shapes table (MISSING TABLE - NOW ADDED)
CREATE TABLE IF NOT EXISTS public.floor_map_shapes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  project_id UUID REFERENCES public.projects(id) ON DELETE CASCADE NOT NULL,
  plan_id UUID REFERENCES public.floor_map_plans(id) ON DELETE CASCADE,
  shape_type TEXT NOT NULL,
  shape_data JSONB NOT NULL,
  room_id UUID REFERENCES public.rooms(id) ON DELETE SET NULL,
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
ALTER TABLE public.project_invitations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.task_dependencies ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.floor_map_plans ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.floor_map_shapes ENABLE ROW LEVEL SECURITY;

-- Helper functions
CREATE OR REPLACE FUNCTION public.get_user_profile_id()
RETURNS UUID
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
  SELECT id FROM public.profiles WHERE user_id = auth.uid() LIMIT 1;
$$;

CREATE OR REPLACE FUNCTION public.user_has_project_access(project_uuid UUID)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.project_shares
    WHERE project_id = project_uuid
    AND shared_with_user_id = get_user_profile_id()
  );
$$;

CREATE OR REPLACE FUNCTION public.user_can_manage_project(project_uuid UUID)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.project_shares
    WHERE project_id = project_uuid
    AND shared_with_user_id = get_user_profile_id()
    AND role IN ('editor', 'admin')
  );
$$;

-- RLS Policies for profiles
CREATE POLICY "Users can view all profiles" ON public.profiles FOR SELECT USING (true);
CREATE POLICY "Users can update own profile" ON public.profiles FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own profile" ON public.profiles FOR INSERT WITH CHECK (auth.uid() = user_id);

-- RLS Policies for projects
CREATE POLICY "Users can view accessible projects" ON public.projects FOR SELECT 
  USING (
    owner_id = get_user_profile_id()
    OR user_has_project_access(id)
  );
CREATE POLICY "Users can create projects" ON public.projects FOR INSERT 
  WITH CHECK (owner_id = get_user_profile_id());
CREATE POLICY "Owners can update projects" ON public.projects FOR UPDATE 
  USING (owner_id = get_user_profile_id());
CREATE POLICY "Owners can delete projects" ON public.projects FOR DELETE 
  USING (owner_id = get_user_profile_id());

-- RLS Policies for rooms
CREATE POLICY "Users can view rooms" ON public.rooms FOR SELECT 
  USING (
    project_id IN (
      SELECT id FROM public.projects WHERE 
        owner_id = get_user_profile_id()
        OR user_has_project_access(id)
    )
  );
CREATE POLICY "Users can manage rooms" ON public.rooms FOR ALL 
  USING (
    project_id IN (
      SELECT id FROM public.projects WHERE 
        owner_id = get_user_profile_id()
        OR user_can_manage_project(id)
    )
  );

-- RLS Policies for tasks
CREATE POLICY "Users can view tasks" ON public.tasks FOR SELECT 
  USING (
    project_id IN (
      SELECT id FROM public.projects WHERE 
        owner_id = get_user_profile_id()
        OR user_has_project_access(id)
    )
  );
CREATE POLICY "Users can manage tasks" ON public.tasks FOR ALL 
  USING (
    project_id IN (
      SELECT id FROM public.projects WHERE 
        owner_id = get_user_profile_id()
        OR user_can_manage_project(id)
    )
  );

-- RLS Policies for materials
CREATE POLICY "Users can view materials" ON public.materials FOR SELECT 
  USING (
    task_id IN (
      SELECT id FROM public.tasks WHERE project_id IN (
        SELECT id FROM public.projects WHERE 
          owner_id = get_user_profile_id()
          OR user_has_project_access(id)
      )
    )
  );
CREATE POLICY "Users can manage materials" ON public.materials FOR ALL 
  USING (
    task_id IN (
      SELECT id FROM public.tasks WHERE project_id IN (
        SELECT id FROM public.projects WHERE 
          owner_id = get_user_profile_id()
          OR user_can_manage_project(id)
      )
    )
  );

-- RLS Policies for floor_map_plans
CREATE POLICY "Users can view plans" ON public.floor_map_plans FOR SELECT 
  USING (
    project_id IN (
      SELECT id FROM public.projects WHERE 
        owner_id = get_user_profile_id()
        OR user_has_project_access(id)
    )
  );
CREATE POLICY "Users can manage plans" ON public.floor_map_plans FOR ALL 
  USING (
    project_id IN (
      SELECT id FROM public.projects WHERE 
        owner_id = get_user_profile_id()
        OR user_can_manage_project(id)
    )
  );

-- RLS Policies for floor_map_shapes
CREATE POLICY "Users can view shapes" ON public.floor_map_shapes FOR SELECT 
  USING (
    project_id IN (
      SELECT id FROM public.projects WHERE 
        owner_id = get_user_profile_id()
        OR user_has_project_access(id)
    )
  );
CREATE POLICY "Users can manage shapes" ON public.floor_map_shapes FOR ALL 
  USING (
    project_id IN (
      SELECT id FROM public.projects WHERE 
        owner_id = get_user_profile_id()
        OR user_can_manage_project(id)
    )
  );

-- RLS Policies for other tables
CREATE POLICY "Users can view contractors" ON public.contractors FOR SELECT 
  USING (created_by_user_id = get_user_profile_id());
CREATE POLICY "Users can manage contractors" ON public.contractors FOR ALL 
  USING (created_by_user_id = get_user_profile_id());

CREATE POLICY "Users can view photos" ON public.photos FOR SELECT USING (true);
CREATE POLICY "Users can upload photos" ON public.photos FOR INSERT 
  WITH CHECK (uploaded_by_user_id = get_user_profile_id());
CREATE POLICY "Users can delete own photos" ON public.photos FOR DELETE 
  USING (uploaded_by_user_id = get_user_profile_id());

CREATE POLICY "Users can view notes" ON public.notes FOR SELECT USING (true);
CREATE POLICY "Users can create notes" ON public.notes FOR INSERT 
  WITH CHECK (created_by_user_id = get_user_profile_id());
CREATE POLICY "Users can update own notes" ON public.notes FOR UPDATE 
  USING (created_by_user_id = get_user_profile_id());
CREATE POLICY "Users can delete own notes" ON public.notes FOR DELETE 
  USING (created_by_user_id = get_user_profile_id());

CREATE POLICY "Users can view project shares" ON public.project_shares FOR SELECT 
  USING (
    project_id IN (SELECT id FROM public.projects WHERE owner_id = get_user_profile_id())
    OR shared_with_user_id = get_user_profile_id()
  );
CREATE POLICY "Owners can manage shares" ON public.project_shares FOR ALL 
  USING (project_id IN (SELECT id FROM public.projects WHERE owner_id = get_user_profile_id()));

CREATE POLICY "Users can view purchase requests" ON public.purchase_requests FOR SELECT 
  USING (
    material_id IN (
      SELECT id FROM public.materials WHERE task_id IN (
        SELECT id FROM public.tasks WHERE project_id IN (
          SELECT id FROM public.projects WHERE 
            owner_id = get_user_profile_id()
            OR user_has_project_access(id)
        )
      )
    )
  );
CREATE POLICY "Users can create purchase requests" ON public.purchase_requests FOR INSERT 
  WITH CHECK (requested_by_user_id = get_user_profile_id());
CREATE POLICY "Owners can update purchase requests" ON public.purchase_requests FOR UPDATE 
  USING (
    material_id IN (
      SELECT id FROM public.materials WHERE task_id IN (
        SELECT id FROM public.tasks WHERE project_id IN (
          SELECT id FROM public.projects WHERE owner_id = get_user_profile_id()
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

-- Drop trigger if exists and create new one
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
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
DROP TRIGGER IF EXISTS update_profiles_updated_at ON public.profiles;
CREATE TRIGGER update_profiles_updated_at 
  BEFORE UPDATE ON public.profiles 
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

DROP TRIGGER IF EXISTS update_projects_updated_at ON public.projects;
CREATE TRIGGER update_projects_updated_at 
  BEFORE UPDATE ON public.projects 
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

DROP TRIGGER IF EXISTS update_rooms_updated_at ON public.rooms;
CREATE TRIGGER update_rooms_updated_at 
  BEFORE UPDATE ON public.rooms 
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

DROP TRIGGER IF EXISTS update_contractors_updated_at ON public.contractors;
CREATE TRIGGER update_contractors_updated_at 
  BEFORE UPDATE ON public.contractors 
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

DROP TRIGGER IF EXISTS update_tasks_updated_at ON public.tasks;
CREATE TRIGGER update_tasks_updated_at 
  BEFORE UPDATE ON public.tasks 
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

DROP TRIGGER IF EXISTS update_materials_updated_at ON public.materials;
CREATE TRIGGER update_materials_updated_at 
  BEFORE UPDATE ON public.materials 
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

DROP TRIGGER IF EXISTS update_notes_updated_at ON public.notes;
CREATE TRIGGER update_notes_updated_at 
  BEFORE UPDATE ON public.notes 
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

DROP TRIGGER IF EXISTS update_purchase_requests_updated_at ON public.purchase_requests;
CREATE TRIGGER update_purchase_requests_updated_at 
  BEFORE UPDATE ON public.purchase_requests 
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

DROP TRIGGER IF EXISTS update_floor_map_plans_updated_at ON public.floor_map_plans;
CREATE TRIGGER update_floor_map_plans_updated_at 
  BEFORE UPDATE ON public.floor_map_plans 
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

DROP TRIGGER IF EXISTS update_floor_map_shapes_updated_at ON public.floor_map_shapes;
CREATE TRIGGER update_floor_map_shapes_updated_at 
  BEFORE UPDATE ON public.floor_map_shapes 
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_floor_map_plans_project_id ON public.floor_map_plans(project_id);
CREATE INDEX IF NOT EXISTS idx_floor_map_shapes_plan_id ON public.floor_map_shapes(plan_id);
CREATE INDEX IF NOT EXISTS idx_floor_map_shapes_project_id ON public.floor_map_shapes(project_id);
CREATE INDEX IF NOT EXISTS idx_tasks_project_id ON public.tasks(project_id);
CREATE INDEX IF NOT EXISTS idx_rooms_project_id ON public.rooms(project_id);
CREATE INDEX IF NOT EXISTS idx_materials_task_id ON public.materials(task_id);
