-- Drop the existing constraint if it exists
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
);