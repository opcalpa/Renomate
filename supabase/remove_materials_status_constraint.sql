-- Remove status constraint completely and just use default value

-- Step 1: List all constraints first (for debugging)
SELECT 
  conname,
  contype,
  pg_get_constraintdef(oid) as definition
FROM pg_constraint
WHERE conrelid = 'materials'::regclass;

-- Step 2: Drop constraint by finding it dynamically
DO $$ 
DECLARE
    r RECORD;
BEGIN
    FOR r IN 
        SELECT conname
        FROM pg_constraint
        WHERE conrelid = 'materials'::regclass 
        AND contype = 'c'  -- check constraints
        AND pg_get_constraintdef(oid) LIKE '%status%'
    LOOP
        EXECUTE format('ALTER TABLE materials DROP CONSTRAINT %I', r.conname);
        RAISE NOTICE 'Dropped constraint: %', r.conname;
    END LOOP;
END $$;

-- Step 3: Make sure status is nullable and has default
ALTER TABLE materials ALTER COLUMN status DROP NOT NULL;
ALTER TABLE materials ALTER COLUMN status SET DEFAULT 'pending';

-- Step 4: Clean up any NULL or invalid data
UPDATE materials 
SET status = 'pending' 
WHERE status IS NULL OR status = '';

-- Step 5: Verify - should show NO check constraints on status
SELECT 
  conname,
  pg_get_constraintdef(oid) as definition
FROM pg_constraint
WHERE conrelid = 'materials'::regclass
  AND contype = 'c'
  AND pg_get_constraintdef(oid) LIKE '%status%';

-- Step 6: Verify column
SELECT 
  column_name,
  is_nullable,
  column_default
FROM information_schema.columns
WHERE table_name = 'materials'
  AND column_name = 'status';
