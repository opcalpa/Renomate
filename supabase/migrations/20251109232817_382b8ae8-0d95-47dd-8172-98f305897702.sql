-- Add progress tracking to tasks
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
);