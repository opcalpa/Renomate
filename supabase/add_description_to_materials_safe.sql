-- SAFE: Add description column to materials table for Purchase Orders
-- This script can be run multiple times without errors

-- Step 1: Check if column exists, then add it
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 
        FROM information_schema.columns 
        WHERE table_name = 'materials' 
        AND column_name = 'description'
    ) THEN
        ALTER TABLE materials ADD COLUMN description TEXT;
        RAISE NOTICE 'Column "description" added to materials table';
    ELSE
        RAISE NOTICE 'Column "description" already exists in materials table';
    END IF;
END $$;

-- Step 2: Add comment
COMMENT ON COLUMN materials.description IS 'Detailed description of the material/purchase order';

-- Step 3: Verify the change
SELECT 
  column_name,
  data_type,
  is_nullable,
  column_default
FROM information_schema.columns
WHERE table_name = 'materials'
  AND column_name = 'description';

-- Step 4: Show all columns in materials table for verification
SELECT 
  column_name,
  data_type,
  is_nullable
FROM information_schema.columns
WHERE table_name = 'materials'
ORDER BY ordinal_position;
