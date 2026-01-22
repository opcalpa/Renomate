-- Add granular permission columns to project_invitations

-- Step 1: Add all missing columns
ALTER TABLE project_invitations 
ADD COLUMN IF NOT EXISTS timeline_access TEXT CHECK (timeline_access IN ('none', 'view', 'edit')) DEFAULT 'view',
ADD COLUMN IF NOT EXISTS tasks_access TEXT CHECK (tasks_access IN ('none', 'view', 'edit')) DEFAULT 'view',
ADD COLUMN IF NOT EXISTS tasks_scope TEXT CHECK (tasks_scope IN ('all', 'assigned')) DEFAULT 'assigned',
ADD COLUMN IF NOT EXISTS space_planner_access TEXT CHECK (space_planner_access IN ('none', 'view', 'edit')) DEFAULT 'view',
ADD COLUMN IF NOT EXISTS purchases_access TEXT CHECK (purchases_access IN ('none', 'view', 'create', 'edit')) DEFAULT 'view',
ADD COLUMN IF NOT EXISTS purchases_scope TEXT CHECK (purchases_scope IN ('all', 'assigned')) DEFAULT 'assigned',
ADD COLUMN IF NOT EXISTS overview_access TEXT CHECK (overview_access IN ('none', 'view', 'edit')) DEFAULT 'view';

-- Step 2: Verify the columns
SELECT 
  column_name,
  data_type,
  is_nullable,
  column_default
FROM information_schema.columns
WHERE table_name = 'project_invitations'
  AND column_name IN ('timeline_access', 'tasks_access', 'tasks_scope', 'space_planner_access', 'purchases_access', 'purchases_scope', 'overview_access')
ORDER BY column_name;
