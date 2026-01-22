-- Create Stakeholders system
-- Fixed version without project_id reference in contractors

-- Step 1: Create stakeholders table
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

-- Step 2: Enable RLS
ALTER TABLE public.stakeholders ENABLE ROW LEVEL SECURITY;

-- Step 3: Create RLS policies
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

-- Step 4: Create updated_at trigger
CREATE TRIGGER update_stakeholders_updated_at
  BEFORE UPDATE ON public.stakeholders
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Step 5: Add indexes for performance
CREATE INDEX IF NOT EXISTS stakeholders_project_id_idx ON public.stakeholders(project_id);
CREATE INDEX IF NOT EXISTS stakeholders_role_idx ON public.stakeholders(role);
CREATE INDEX IF NOT EXISTS stakeholders_contractor_category_idx ON public.stakeholders(contractor_category);

-- Step 6: Add new column to tasks for stakeholder assignment
ALTER TABLE tasks ADD COLUMN IF NOT EXISTS assigned_to_stakeholder_id UUID REFERENCES public.stakeholders(id) ON DELETE SET NULL;

-- Step 7: Create index on new column
CREATE INDEX IF NOT EXISTS tasks_assigned_to_stakeholder_id_idx ON tasks(assigned_to_stakeholder_id);

-- Step 8: Migrate existing contractor assignments (if contractors table exists and has data)
-- Simplified migration - create stakeholders from tasks with contractors assigned
DO $$ 
BEGIN
  IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'contractors') THEN
    INSERT INTO public.stakeholders (project_id, name, email, phone, company, role, contractor_category, created_by_user_id)
    SELECT DISTINCT 
      t.project_id,
      COALESCE(c.name, 'Contractor'),
      c.email,
      c.phone,
      c.company,
      'contractor',
      'general_renovator',
      t.created_by_user_id
    FROM tasks t
    INNER JOIN contractors c ON c.id = t.assigned_to_contractor_id
    WHERE t.assigned_to_contractor_id IS NOT NULL
    ON CONFLICT DO NOTHING;
    
    -- Update tasks to use new stakeholder IDs (match by name only since contractors don't have project_id)
    UPDATE tasks t
    SET assigned_to_stakeholder_id = s.id
    FROM stakeholders s
    INNER JOIN contractors c ON c.name = s.name
    WHERE t.assigned_to_contractor_id = c.id
    AND t.project_id = s.project_id;
  END IF;
END $$;

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
