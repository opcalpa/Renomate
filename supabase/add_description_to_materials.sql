-- Add description column to materials table for Purchase Orders

-- Step 1: Add description column
ALTER TABLE materials 
ADD COLUMN IF NOT EXISTS description TEXT;

-- Step 2: Add comment
COMMENT ON COLUMN materials.description IS 'Detailed description of the material/purchase order';

-- Step 3: Verify the change
SELECT 
  column_name,
  data_type,
  is_nullable
FROM information_schema.columns
WHERE table_name = 'materials'
  AND column_name = 'description';
