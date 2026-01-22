-- Make task_id optional for materials so purchase orders can be added without a specific task
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
);