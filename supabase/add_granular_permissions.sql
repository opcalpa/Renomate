-- Add granular feature-based permissions to project_shares

-- Step 1: Add columns for feature access
ALTER TABLE project_shares 
ADD COLUMN IF NOT EXISTS timeline_access TEXT CHECK (timeline_access IN ('none', 'view', 'edit')) DEFAULT 'none',
ADD COLUMN IF NOT EXISTS tasks_access TEXT CHECK (tasks_access IN ('none', 'view', 'edit')) DEFAULT 'none',
ADD COLUMN IF NOT EXISTS tasks_scope TEXT CHECK (tasks_scope IN ('all', 'assigned')) DEFAULT 'all',
ADD COLUMN IF NOT EXISTS space_planner_access TEXT CHECK (space_planner_access IN ('none', 'view', 'edit')) DEFAULT 'none',
ADD COLUMN IF NOT EXISTS purchases_access TEXT CHECK (purchases_access IN ('none', 'view', 'edit')) DEFAULT 'none',
ADD COLUMN IF NOT EXISTS overview_access TEXT CHECK (overview_access IN ('none', 'view', 'edit')) DEFAULT 'none';

-- Step 2: Set default access for existing members based on their role
UPDATE project_shares
SET 
  timeline_access = CASE 
    WHEN role = 'admin' THEN 'edit'
    WHEN role = 'editor' THEN 'edit'
    WHEN role = 'viewer' THEN 'view'
    WHEN role = 'material_requester' THEN 'view'
    ELSE 'none'
  END,
  tasks_access = CASE 
    WHEN role = 'admin' THEN 'edit'
    WHEN role = 'editor' THEN 'edit'
    WHEN role = 'viewer' THEN 'view'
    WHEN role = 'material_requester' THEN 'view'
    ELSE 'none'
  END,
  tasks_scope = CASE
    WHEN role IN ('admin', 'editor') THEN 'all'
    ELSE 'assigned'
  END,
  space_planner_access = CASE 
    WHEN role = 'admin' THEN 'edit'
    WHEN role = 'editor' THEN 'edit'
    WHEN role = 'viewer' THEN 'view'
    ELSE 'none'
  END,
  purchases_access = CASE 
    WHEN role = 'admin' THEN 'edit'
    WHEN role = 'editor' THEN 'edit'
    WHEN role = 'material_requester' THEN 'edit'
    WHEN role = 'viewer' THEN 'view'
    ELSE 'none'
  END,
  overview_access = CASE 
    WHEN role = 'admin' THEN 'edit'
    WHEN role = 'editor' THEN 'edit'
    WHEN role = 'viewer' THEN 'view'
    WHEN role = 'material_requester' THEN 'view'
    ELSE 'none'
  END
WHERE timeline_access IS NULL OR timeline_access = 'none';

-- Step 3: Create indexes for performance
CREATE INDEX IF NOT EXISTS project_shares_timeline_access_idx ON project_shares(timeline_access);
CREATE INDEX IF NOT EXISTS project_shares_tasks_access_idx ON project_shares(tasks_access);
CREATE INDEX IF NOT EXISTS project_shares_purchases_access_idx ON project_shares(purchases_access);

-- Step 4: Add same columns to project_invitations for pre-defining access
ALTER TABLE project_invitations
ADD COLUMN IF NOT EXISTS timeline_access TEXT CHECK (timeline_access IN ('none', 'view', 'edit')) DEFAULT 'view',
ADD COLUMN IF NOT EXISTS tasks_access TEXT CHECK (tasks_access IN ('none', 'view', 'edit')) DEFAULT 'view',
ADD COLUMN IF NOT EXISTS tasks_scope TEXT CHECK (tasks_scope IN ('all', 'assigned')) DEFAULT 'assigned',
ADD COLUMN IF NOT EXISTS space_planner_access TEXT CHECK (space_planner_access IN ('none', 'view', 'edit')) DEFAULT 'view',
ADD COLUMN IF NOT EXISTS purchases_access TEXT CHECK (purchases_access IN ('none', 'view', 'edit')) DEFAULT 'view',
ADD COLUMN IF NOT EXISTS overview_access TEXT CHECK (overview_access IN ('none', 'view', 'edit')) DEFAULT 'view';

-- Step 5: Verify the changes
SELECT 
  id,
  role,
  timeline_access,
  tasks_access,
  tasks_scope,
  space_planner_access,
  purchases_access,
  overview_access
FROM project_shares
LIMIT 5;
