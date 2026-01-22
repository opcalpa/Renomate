-- Step 1: Update all existing data to use new status values
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
);