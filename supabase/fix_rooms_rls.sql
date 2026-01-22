-- Fix RLS policies for rooms table to allow room creation during development
-- This allows all authenticated users to create rooms (simplified for development)

-- Drop existing restrictive policies
DROP POLICY IF EXISTS "Users can view rooms in their projects" ON rooms;
DROP POLICY IF EXISTS "Users can create rooms in their projects" ON rooms;
DROP POLICY IF EXISTS "Users can update rooms in their projects" ON rooms;
DROP POLICY IF EXISTS "Users can delete rooms in their projects" ON rooms;

-- Create simplified policies for development
-- Allow all authenticated users to do everything with rooms
CREATE POLICY "Allow authenticated users to view rooms" ON rooms
  FOR SELECT USING (auth.role() = 'authenticated');

CREATE POLICY "Allow authenticated users to create rooms" ON rooms
  FOR INSERT WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "Allow authenticated users to update rooms" ON rooms
  FOR UPDATE USING (auth.role() = 'authenticated');

CREATE POLICY "Allow authenticated users to delete rooms" ON rooms
  FOR DELETE USING (auth.role() = 'authenticated');

-- Alternative: Allow everything for development (less secure but easier)
-- Uncomment these lines instead if you want completely open access:
--
-- CREATE POLICY "Allow all operations on rooms" ON rooms
--   FOR ALL USING (true) WITH CHECK (true);

SELECT 'Rooms RLS policies updated for development!' as status;