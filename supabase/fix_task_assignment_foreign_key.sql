-- Fix task assignment foreign key issue
-- Remove old contractor_id column and constraint, ensure stakeholder_id is correct

-- Step 1: Check current state
SELECT 
  column_name, 
  data_type, 
  is_nullable
FROM information_schema.columns 
WHERE table_name = 'tasks' 
  AND column_name IN ('assigned_to_contractor_id', 'assigned_to_stakeholder_id');

-- Step 2: Drop old foreign key constraint if it exists
ALTER TABLE tasks 
DROP CONSTRAINT IF EXISTS tasks_assigned_to_contractor_id_fkey;

-- Step 3: Drop the old contractor_id column if it exists
ALTER TABLE tasks 
DROP COLUMN IF EXISTS assigned_to_contractor_id;

-- Step 4: Ensure assigned_to_stakeholder_id column exists with correct constraint
DO $$ 
BEGIN
  -- Add column if it doesn't exist
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'tasks' AND column_name = 'assigned_to_stakeholder_id'
  ) THEN
    ALTER TABLE tasks 
    ADD COLUMN assigned_to_stakeholder_id UUID;
  END IF;
END $$;

-- Step 5: Drop existing stakeholder foreign key to recreate it properly
ALTER TABLE tasks 
DROP CONSTRAINT IF EXISTS tasks_assigned_to_stakeholder_id_fkey;

-- Step 6: Add correct foreign key constraint to stakeholders table
ALTER TABLE tasks 
ADD CONSTRAINT tasks_assigned_to_stakeholder_id_fkey 
FOREIGN KEY (assigned_to_stakeholder_id) 
REFERENCES stakeholders(id) 
ON DELETE SET NULL;

-- Step 7: Create index for performance
CREATE INDEX IF NOT EXISTS idx_tasks_assigned_to_stakeholder 
ON tasks(assigned_to_stakeholder_id);

-- Step 8: Verify the fix
SELECT 
  tc.constraint_name,
  tc.table_name,
  kcu.column_name,
  ccu.table_name AS foreign_table_name,
  ccu.column_name AS foreign_column_name
FROM information_schema.table_constraints AS tc
JOIN information_schema.key_column_usage AS kcu
  ON tc.constraint_name = kcu.constraint_name
  AND tc.table_schema = kcu.table_schema
JOIN information_schema.constraint_column_usage AS ccu
  ON ccu.constraint_name = tc.constraint_name
  AND ccu.table_schema = tc.table_schema
WHERE tc.constraint_type = 'FOREIGN KEY' 
  AND tc.table_name = 'tasks'
  AND kcu.column_name LIKE '%assigned%';

-- Step 9: Show current task assignments
SELECT 
  id,
  title,
  assigned_to_stakeholder_id,
  status
FROM tasks
LIMIT 5;
