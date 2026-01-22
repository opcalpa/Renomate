-- Create Stakeholders system - Safe version that handles existing objects

-- Step 1: Drop existing policies if they exist
DROP POLICY IF EXISTS "Users can view stakeholders in their projects" ON public.stakeholders;
DROP POLICY IF EXISTS "Users can create stakeholders in their projects" ON public.stakeholders;
DROP POLICY IF EXISTS "Users can update stakeholders in their projects" ON public.stakeholders;
DROP POLICY IF EXISTS "Users can delete stakeholders in their projects" ON public.stakeholders;

-- Step 2: Create stakeholders table if not exists
CREATE TABLE IF NOT EXISTS public.stakeholders (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  project_id UUID REFERENCES public.projects(id) ON DELETE CASCADE NOT NULL,
  name TEXT NOT NULL,
  email TEXT,
  phone TEXT,
  company TEXT,
  role TEXT NOT NULL CHECK (role IN ('contractor', 'client', 'other')),
  contractor_category TEXT CHECK (contractor_category IN (
    'plumber',
    'electrician', 
    'painter',
    'carpenter',
    'general_renovator',
    'flooring_specialist',
    'hvac_technician',
    'mason',
    'roofer',
    'tiler',
    'glazier',
    'landscaper',
    'architect',
    'interior_designer',
    'other'
  )),
  notes TEXT,
  created_by_user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
  updated_at TIMESTAMPTZ DEFAULT now() NOT NULL
);

-- Step 3: Enable RLS
ALTER TABLE public.stakeholders ENABLE ROW LEVEL SECURITY;

-- Step 4: Create RLS policies (fresh)
CREATE POLICY "Users can view stakeholders in their projects" ON public.stakeholders
FOR SELECT USING (
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
    )
  )
);

CREATE POLICY "Users can create stakeholders in their projects" ON public.stakeholders
FOR INSERT WITH CHECK (
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
      AND role IN ('editor', 'admin')
    )
  )
);

CREATE POLICY "Users can update stakeholders in their projects" ON public.stakeholders
FOR UPDATE USING (
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
      AND role IN ('editor', 'admin')
    )
  )
);

CREATE POLICY "Users can delete stakeholders in their projects" ON public.stakeholders
FOR DELETE USING (
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

-- Step 5: Drop old trigger if exists and create new one
DROP TRIGGER IF EXISTS update_stakeholders_updated_at ON public.stakeholders;
CREATE TRIGGER update_stakeholders_updated_at
  BEFORE UPDATE ON public.stakeholders
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Step 6: Add indexes for performance
CREATE INDEX IF NOT EXISTS stakeholders_project_id_idx ON public.stakeholders(project_id);
CREATE INDEX IF NOT EXISTS stakeholders_role_idx ON public.stakeholders(role);
CREATE INDEX IF NOT EXISTS stakeholders_contractor_category_idx ON public.stakeholders(contractor_category);

-- Step 7: Add new column to tasks for stakeholder assignment
ALTER TABLE tasks ADD COLUMN IF NOT EXISTS assigned_to_stakeholder_id UUID REFERENCES public.stakeholders(id) ON DELETE SET NULL;

-- Step 8: Create index on new column
CREATE INDEX IF NOT EXISTS tasks_assigned_to_stakeholder_id_idx ON tasks(assigned_to_stakeholder_id);

-- Step 9: Verify the setup
SELECT 
  'Tasks' as table_name,
  COUNT(*) as total,
  COUNT(assigned_to_stakeholder_id) as assigned_count
FROM tasks
UNION ALL
SELECT 
  'Stakeholders' as table_name,
  COUNT(*) as total,
  COUNT(CASE WHEN role = 'contractor' THEN 1 END) as contractor_count
FROM stakeholders;
