-- Fix Template System Permissions
-- This script ensures that users can create and manage template objects

-- 1. Ensure floor_map_shapes table has all required columns
DO $$ 
BEGIN
  -- Check if rotation column exists, add if not
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'floor_map_shapes' AND column_name = 'rotation'
  ) THEN
    ALTER TABLE floor_map_shapes ADD COLUMN rotation FLOAT DEFAULT 0;
  END IF;
  
  -- Check if opacity column exists, add if not
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'floor_map_shapes' AND column_name = 'opacity'
  ) THEN
    ALTER TABLE floor_map_shapes ADD COLUMN opacity FLOAT DEFAULT 1;
  END IF;
  
  -- Check if name column exists, add if not
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'floor_map_shapes' AND column_name = 'name'
  ) THEN
    ALTER TABLE floor_map_shapes ADD COLUMN name TEXT;
  END IF;
END $$;

-- 2. Fix RLS policies for floor_map_shapes
-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Users can insert shapes" ON floor_map_shapes;
DROP POLICY IF EXISTS "Users can view shapes" ON floor_map_shapes;
DROP POLICY IF EXISTS "Users can update shapes" ON floor_map_shapes;
DROP POLICY IF EXISTS "Users can delete shapes" ON floor_map_shapes;

-- Create new comprehensive policies (simplified - no team_members dependency)
CREATE POLICY "Users can insert shapes"
  ON floor_map_shapes
  FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM floor_map_plans
      JOIN projects ON projects.id = floor_map_plans.project_id
      WHERE floor_map_plans.id = floor_map_shapes.plan_id
      AND projects.owner_id = auth.uid()
    )
  );

CREATE POLICY "Users can view shapes"
  ON floor_map_shapes
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM floor_map_plans
      JOIN projects ON projects.id = floor_map_plans.project_id
      WHERE floor_map_plans.id = floor_map_shapes.plan_id
      AND projects.owner_id = auth.uid()
    )
  );

CREATE POLICY "Users can update shapes"
  ON floor_map_shapes
  FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM floor_map_plans
      JOIN projects ON projects.id = floor_map_plans.project_id
      WHERE floor_map_plans.id = floor_map_shapes.plan_id
      AND projects.owner_id = auth.uid()
    )
  );

CREATE POLICY "Users can delete shapes"
  ON floor_map_shapes
  FOR DELETE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM floor_map_plans
      JOIN projects ON projects.id = floor_map_plans.project_id
      WHERE floor_map_plans.id = floor_map_shapes.plan_id
      AND projects.owner_id = auth.uid()
    )
  );

-- 3. Verify the fixes
SELECT 
  'floor_map_shapes columns:' as info,
  column_name,
  data_type,
  is_nullable
FROM information_schema.columns
WHERE table_name = 'floor_map_shapes'
ORDER BY ordinal_position;

SELECT 
  'RLS policies:' as info,
  policyname,
  cmd,
  permissive
FROM pg_policies
WHERE tablename = 'floor_map_shapes';

-- Success message
DO $$
BEGIN
  RAISE NOTICE '✅ Template system permissions fixed!';
  RAISE NOTICE '📝 You can now create and manage object templates';
END $$;
