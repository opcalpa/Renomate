-- Fix task assignment foreign key constraint
-- Make it more flexible to allow NULL and handle deletions gracefully

-- Step 1: Drop the existing foreign key constraint
ALTER TABLE tasks 
DROP CONSTRAINT IF EXISTS tasks_assigned_to_contractor_id_fkey;

-- Step 2: Add it back with ON DELETE SET NULL to handle contractor deletions
ALTER TABLE tasks 
ADD CONSTRAINT tasks_assigned_to_contractor_id_fkey 
FOREIGN KEY (assigned_to_contractor_id) 
REFERENCES contractors(id) 
ON DELETE SET NULL;

-- Step 3: Set any invalid contractor IDs to NULL
UPDATE tasks 
SET assigned_to_contractor_id = NULL 
WHERE assigned_to_contractor_id IS NOT NULL 
  AND assigned_to_contractor_id NOT IN (SELECT id FROM contractors);

-- Step 4: Verify the fix
SELECT 
  id, 
  title, 
  assigned_to_contractor_id,
  CASE 
    WHEN assigned_to_contractor_id IS NULL THEN 'Unassigned'
    ELSE 'Assigned'
  END as assignment_status
FROM tasks;
