-- Fix "todo" status issue - Remove constraint FIRST, then update

-- STEP 1: Check current statuses
SELECT DISTINCT status, COUNT(*) as count
FROM tasks 
GROUP BY status
ORDER BY status;

-- STEP 2: Drop ALL constraints FIRST (run this separately if needed)
DO $$ 
DECLARE
    constraint_name text;
BEGIN
    FOR constraint_name IN 
        SELECT conname 
        FROM pg_constraint 
        WHERE conrelid = 'tasks'::regclass 
        AND conname LIKE '%status%'
    LOOP
        EXECUTE 'ALTER TABLE tasks DROP CONSTRAINT IF EXISTS ' || constraint_name;
    END LOOP;
END $$;

-- STEP 3: Remove the default value temporarily
ALTER TABLE tasks ALTER COLUMN status DROP DEFAULT;

-- STEP 4: Now update all tasks to use correct status values (no constraint blocking)
UPDATE tasks SET status = 'to_do' WHERE status IN ('todo', 'Todo');
UPDATE tasks SET status = 'in_progress' WHERE status IN ('in-progress', 'inprogress', 'in_progress');
UPDATE tasks SET status = 'on_hold' WHERE status IN ('on-hold', 'onhold', 'on_hold');

-- STEP 5: Fix any remaining invalid statuses
UPDATE tasks 
SET status = 'to_do' 
WHERE status IS NULL 
   OR status NOT IN ('discovery', 'to_do', 'in_progress', 'on_hold', 'doing', 'blocked', 'completed', 'done', 'scrapped');

-- STEP 6: Set the new default
ALTER TABLE tasks ALTER COLUMN status SET DEFAULT 'to_do';

-- STEP 7: Add the NEW constraint with all valid statuses
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

-- STEP 8: Verify the fix
SELECT status, COUNT(*) as count
FROM tasks 
GROUP BY status
ORDER BY status;
