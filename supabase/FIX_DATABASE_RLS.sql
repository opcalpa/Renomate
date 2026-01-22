-- =============================================================================
-- FIX SUPABASE RLS POLICIES FOR ROOMS TABLE (IMPROVED VERSION)
-- =============================================================================
--
-- Kör detta SQL-script i Supabase SQL Editor:
-- https://app.supabase.com/project/pfyxywuchbakuphxhgec/sql/new
--
-- Detta fixar felet: "new row violates row-level security policy for table 'rooms'"
-- Denna version hanterar befintliga policies bättre
--
-- =============================================================================

-- Step 1: Drop ALL existing policies for rooms table
DO $$
DECLARE
    pol record;
BEGIN
    FOR pol IN
        SELECT policyname
        FROM pg_policies
        WHERE tablename = 'rooms'
    LOOP
        EXECUTE format('DROP POLICY IF EXISTS %I ON rooms', pol.policyname);
    END LOOP;
END $$;

-- Step 2: Create simplified policies for development/testing
-- Allow authenticated users to do everything with rooms
CREATE POLICY "Allow authenticated users to view rooms" ON rooms
  FOR SELECT USING (auth.role() = 'authenticated');

CREATE POLICY "Allow authenticated users to create rooms" ON rooms
  FOR INSERT WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "Allow authenticated users to update rooms" ON rooms
  FOR UPDATE USING (auth.role() = 'authenticated');

CREATE POLICY "Allow authenticated users to delete rooms" ON rooms
  FOR DELETE USING (auth.role() = 'authenticated');

-- Step 3: Verify the policies were created
SELECT
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd,
  qual
FROM pg_policies
WHERE tablename = 'rooms'
ORDER BY policyname;

-- Success message
SELECT '✅ Rooms RLS policies updated! You can now create rooms.' as status;