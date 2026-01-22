-- Make task_id nullable in materials table for project-level purchase orders

-- Step 1: Drop the NOT NULL constraint on task_id
ALTER TABLE materials 
ALTER COLUMN task_id DROP NOT NULL;

-- Step 2: Ensure project_id exists and is required when task_id is null
-- Add a check constraint to ensure either task_id OR project_id is set
ALTER TABLE materials 
DROP CONSTRAINT IF EXISTS materials_task_or_project_check;

ALTER TABLE materials 
ADD CONSTRAINT materials_task_or_project_check 
CHECK (task_id IS NOT NULL OR project_id IS NOT NULL);

-- Step 3: Verify the change
SELECT 
  column_name,
  is_nullable,
  data_type
FROM information_schema.columns
WHERE table_name = 'materials'
  AND column_name IN ('task_id', 'project_id');
