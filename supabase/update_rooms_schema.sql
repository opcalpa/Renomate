-- Update rooms table to add area_sqm column and improve dimensions structure
-- This makes it easier to store and query room measurements

-- Step 1: Check current schema
SELECT 
  column_name, 
  data_type, 
  is_nullable
FROM information_schema.columns 
WHERE table_name = 'rooms' 
ORDER BY ordinal_position;

-- Step 2: Rooms table already has dimensions as JSONB
-- We'll ensure the structure supports the following fields in JSONB:
-- - area_sqm: area in square meters
-- - perimeter_mm: perimeter in millimeters
-- - width_mm: width in millimeters (optional)
-- - height_mm: height in millimeters (optional)

-- Add comment to clarify dimensions structure
COMMENT ON COLUMN rooms.dimensions IS 'JSONB object containing: area_sqm (number), perimeter_mm (number), width_mm (number, optional), height_mm (number, optional)';

-- Add comment for floor_plan_position
COMMENT ON COLUMN rooms.floor_plan_position IS 'JSONB object containing: points (array of {x, y} coordinates in mm)';

-- Step 3: Create index on project_id for better performance
CREATE INDEX IF NOT EXISTS idx_rooms_project_id ON rooms(project_id);

-- Step 4: Add RLS policies if they don't exist
ALTER TABLE rooms ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Users can view rooms in their projects" ON rooms;
DROP POLICY IF EXISTS "Users can create rooms in their projects" ON rooms;
DROP POLICY IF EXISTS "Users can update rooms in their projects" ON rooms;
DROP POLICY IF EXISTS "Users can delete rooms in their projects" ON rooms;

-- Create RLS policies
CREATE POLICY "Users can view rooms in their projects" ON rooms
FOR SELECT USING (
  project_id IN (
    SELECT id FROM projects 
    WHERE owner_id IN (
      SELECT id FROM profiles WHERE user_id = auth.uid()
    )
    OR id IN (
      SELECT project_id FROM project_shares 
      WHERE shared_with_user_id IN (
        SELECT id FROM profiles WHERE user_id = auth.uid()
      )
    )
  )
);

CREATE POLICY "Users can create rooms in their projects" ON rooms
FOR INSERT WITH CHECK (
  project_id IN (
    SELECT id FROM projects 
    WHERE owner_id IN (
      SELECT id FROM profiles WHERE user_id = auth.uid()
    )
    OR id IN (
      SELECT project_id FROM project_shares 
      WHERE shared_with_user_id IN (
        SELECT id FROM profiles WHERE user_id = auth.uid()
      )
      AND (role = 'admin' OR role = 'editor' OR space_planner_access IN ('edit', 'create'))
    )
  )
);

CREATE POLICY "Users can update rooms in their projects" ON rooms
FOR UPDATE USING (
  project_id IN (
    SELECT id FROM projects 
    WHERE owner_id IN (
      SELECT id FROM profiles WHERE user_id = auth.uid()
    )
    OR id IN (
      SELECT project_id FROM project_shares 
      WHERE shared_with_user_id IN (
        SELECT id FROM profiles WHERE user_id = auth.uid()
      )
      AND (role = 'admin' OR role = 'editor' OR space_planner_access IN ('edit', 'create'))
    )
  )
);

CREATE POLICY "Users can delete rooms in their projects" ON rooms
FOR DELETE USING (
  project_id IN (
    SELECT id FROM projects 
    WHERE owner_id IN (
      SELECT id FROM profiles WHERE user_id = auth.uid()
    )
    OR id IN (
      SELECT project_id FROM project_shares 
      WHERE shared_with_user_id IN (
        SELECT id FROM profiles WHERE user_id = auth.uid()
      )
      AND (role = 'admin' OR space_planner_access = 'edit')
    )
  )
);

-- Step 5: Verify the setup
SELECT 
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd,
  qual
FROM pg_policies
WHERE tablename = 'rooms';

-- Step 6: Show example of room data structure
-- Example data structure for dimensions JSONB:
-- {
--   "area_sqm": 25.5,
--   "perimeter_mm": 20000,
--   "width_mm": 5000,
--   "height_mm": 5000
-- }

-- Example data structure for floor_plan_position JSONB:
-- {
--   "points": [
--     {"x": 0, "y": 0},
--     {"x": 5000, "y": 0},
--     {"x": 5000, "y": 5000},
--     {"x": 0, "y": 5000}
--   ]
-- }

SELECT 'Rooms schema updated successfully!' as status;
