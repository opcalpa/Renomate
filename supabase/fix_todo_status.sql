-- Fix incorrect "todo" status to correct "to_do" status
-- The correct status values should use underscores, not single words

-- Step 1: Update all tasks with "todo" status to "to_do"
UPDATE tasks 
SET status = 'to_do' 
WHERE status = 'todo' OR status = 'Todo';

-- Step 2: Drop old status constraint that includes 'todo'
ALTER TABLE tasks DROP CONSTRAINT IF EXISTS tasks_status_check;

-- Step 3: Add new status constraint with correct values
ALTER TABLE tasks 
ADD CONSTRAINT tasks_status_check 
CHECK (status IN (
  'discovery', 
  'to_do', 
  'in_progress', 
  'on_hold', 
  'doing', 
  'blocked', 
  'completed', 
  'done', 
  'scrapped'
));

-- Step 4: Change default status from 'todo' to 'to_do'
ALTER TABLE tasks 
ALTER COLUMN status SET DEFAULT 'to_do';

-- Step 5: Verify the changes
SELECT id, title, status 
FROM tasks 
ORDER BY created_at DESC;
