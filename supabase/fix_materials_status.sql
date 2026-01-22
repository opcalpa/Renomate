-- Fix materials status constraint

-- Step 1: Drop the old status constraint
ALTER TABLE materials DROP CONSTRAINT IF EXISTS materials_status_check;

-- Step 2: Add updated status constraint with all valid statuses
ALTER TABLE materials 
ADD CONSTRAINT materials_status_check 
CHECK (status IN ('pending', 'ordered', 'delivered', 'installed', 'cancelled'));

-- Step 3: Set default status
ALTER TABLE materials 
ALTER COLUMN status SET DEFAULT 'pending';

-- Step 4: Update any NULL statuses to 'pending'
UPDATE materials 
SET status = 'pending' 
WHERE status IS NULL;

-- Step 5: Make status NOT NULL if it isn't already
ALTER TABLE materials 
ALTER COLUMN status SET NOT NULL;

-- Step 6: Verify the change
SELECT 
  column_name,
  is_nullable,
  column_default
FROM information_schema.columns
WHERE table_name = 'materials'
  AND column_name = 'status';
