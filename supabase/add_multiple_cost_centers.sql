-- Add support for multiple cost centers per task
-- Change cost_center from single string to text array

-- Step 1: Add new column for multiple cost centers
ALTER TABLE tasks ADD COLUMN IF NOT EXISTS cost_centers text[] DEFAULT '{}';

-- Step 2: Migrate existing single cost_center data to array
UPDATE tasks 
SET cost_centers = ARRAY[cost_center]
WHERE cost_center IS NOT NULL AND cost_center != '';

-- Step 3: Keep old column for backward compatibility (or drop it later)
-- ALTER TABLE tasks DROP COLUMN cost_center;

-- Add comment
COMMENT ON COLUMN tasks.cost_centers IS 'Array of cost center categories for this task';
