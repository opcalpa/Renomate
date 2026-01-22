-- Force fix materials status - remove ALL constraints and recreate

-- Step 1: Find and drop ALL constraints on materials table that mention status
DO $$ 
DECLARE
    constraint_name text;
BEGIN
    FOR constraint_name IN 
        SELECT conname 
        FROM pg_constraint 
        WHERE conrelid = 'materials'::regclass 
        AND conname LIKE '%status%'
    LOOP
        EXECUTE 'ALTER TABLE materials DROP CONSTRAINT IF EXISTS ' || constraint_name;
        RAISE NOTICE 'Dropped constraint: %', constraint_name;
    END LOOP;
END $$;

-- Step 2: Also try dropping by exact names (backup)
ALTER TABLE materials DROP CONSTRAINT IF EXISTS materials_status_check;
ALTER TABLE materials DROP CONSTRAINT IF EXISTS materials_status_check1;
ALTER TABLE materials DROP CONSTRAINT IF EXISTS materials_status_check2;

-- Step 3: Make status column nullable temporarily
ALTER TABLE materials ALTER COLUMN status DROP NOT NULL;

-- Step 4: Set default value
ALTER TABLE materials ALTER COLUMN status SET DEFAULT 'pending';

-- Step 5: Update all NULL values to 'pending'
UPDATE materials SET status = 'pending' WHERE status IS NULL;

-- Step 6: Update any invalid statuses to 'pending'
UPDATE materials 
SET status = 'pending' 
WHERE status NOT IN ('pending', 'ordered', 'delivered', 'installed', 'cancelled');

-- Step 7: NOW add the constraint
ALTER TABLE materials 
ADD CONSTRAINT materials_status_check 
CHECK (status IN ('pending', 'ordered', 'delivered', 'installed', 'cancelled'));

-- Step 8: Make it NOT NULL again
ALTER TABLE materials ALTER COLUMN status SET NOT NULL;

-- Step 9: Verify
SELECT 
  conname as constraint_name,
  pg_get_constraintdef(oid) as definition
FROM pg_constraint
WHERE conrelid = 'materials'::regclass
  AND conname LIKE '%status%';

-- Also verify column
SELECT 
  column_name,
  is_nullable,
  column_default,
  data_type
FROM information_schema.columns
WHERE table_name = 'materials'
  AND column_name = 'status';
