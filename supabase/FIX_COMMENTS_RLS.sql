-- =============================================================================
-- FIX SUPABASE RLS POLICIES FOR COMMENTS TABLE
-- =============================================================================
--
-- Kör detta SQL-script i Supabase SQL Editor:
-- https://app.supabase.com/project/[PROJECT-ID]/sql/new
--
-- Detta fixar felet: "new row violates row-level security policy for table 'comments'"
--
-- =============================================================================

-- Step 1: Add entity_id and entity_type columns if they don't exist
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                 WHERE table_name = 'comments' AND column_name = 'entity_id') THEN
    ALTER TABLE comments ADD COLUMN entity_id TEXT;
  END IF;

  IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                 WHERE table_name = 'comments' AND column_name = 'entity_type') THEN
    ALTER TABLE comments ADD COLUMN entity_type TEXT;
  END IF;
END $$;

-- Step 2: Drop ALL existing policies for comments table
DO $$
DECLARE
    pol record;
BEGIN
    FOR pol IN
        SELECT policyname
        FROM pg_policies
        WHERE tablename = 'comments'
    LOOP
        EXECUTE format('DROP POLICY IF EXISTS %I ON comments', pol.policyname);
    END LOOP;
END $$;

-- Step 3: Create simplified policies for development/testing
-- Allow authenticated users to do everything with comments
CREATE POLICY "Allow authenticated users to view comments" ON comments
  FOR SELECT USING (auth.role() = 'authenticated');

CREATE POLICY "Allow authenticated users to create comments" ON comments
  FOR INSERT WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "Allow authenticated users to update comments" ON comments
  FOR UPDATE USING (auth.role() = 'authenticated');

CREATE POLICY "Allow authenticated users to delete comments" ON comments
  FOR DELETE USING (auth.role() = 'authenticated');

-- Step 4: Verify the table structure
SELECT
  column_name,
  data_type,
  is_nullable
FROM information_schema.columns
WHERE table_name = 'comments'
ORDER BY ordinal_position;

-- Step 5: Verify the policies were created
SELECT
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd,
  qual
FROM pg_policies
WHERE tablename = 'comments';

-- Success message
SELECT '✅ Comments table updated with entity_id/entity_type columns and RLS policies fixed! You can now create comments on drawing objects.' as status;