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
CREATE TRIGGER update_purchase_requests_updated_at BEFORE UPDATE ON public.purchase_requests FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();