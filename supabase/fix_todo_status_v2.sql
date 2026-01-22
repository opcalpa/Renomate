-- Fix "todo" status issue - Step by step approach

-- STEP 1: First, let's see what statuses currently exist
SELECT DISTINCT status, COUNT(*) as count
FROM tasks 
GROUP BY status
ORDER BY status;

-- STEP 2: Drop ALL existing status constraints
ALTER TABLE tasks DROP CONSTRAINT IF EXISTS tasks_status_check;
ALTER TABLE tasks DROP CONSTRAINT IF EXISTS tasks_status_check1;
ALTER TABLE tasks DROP CONSTRAINT IF EXISTS tasks_status_check2;

-- STEP 3: Now update all tasks to use correct status values
UPDATE tasks SET status = 'to_do' WHERE status = 'todo' OR status = 'Todo';
UPDATE tasks SET status = 'in_progress' WHERE status = 'in-progress' OR status = 'inprogress';
UPDATE tasks SET status = 'on_hold' WHERE status = 'on-hold' OR status = 'onhold';

-- STEP 4: Set any NULL or invalid statuses to 'to_do'
UPDATE tasks 
SET status = 'to_do' 
WHERE status IS NULL 
   OR status NOT IN ('discovery', 'to_do', 'in_progress', 'on_hold', 'doing', 'blocked', 'completed', 'done', 'scrapped');

-- STEP 5: Now add the new constraint with all valid statuses
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

-- STEP 6: Change default status from 'todo' to 'to_do'
ALTER TABLE tasks 
ALTER COLUMN status SET DEFAULT 'to_do';

-- STEP 7: Verify all tasks have valid statuses
SELECT status, COUNT(*) as count
FROM tasks 
GROUP BY status
ORDER BY status;
