-- Add project_id to materials table for project-level purchase orders
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
);