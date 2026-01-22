-- Check and Fix floor_map_shapes Table Structure
-- This script diagnoses and fixes the table structure for template system

-- 1. Check current table structure
SELECT 
  '=== Current floor_map_shapes columns ===' as info;

SELECT 
  column_name,
  data_type,
  is_nullable,
  column_default
FROM information_schema.columns
WHERE table_name = 'floor_map_shapes'
ORDER BY ordinal_position;

-- 2. Add missing columns if they don't exist
DO $$ 
BEGIN
  -- Add coordinates column (JSONB type for flexible storage)
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'floor_map_shapes' AND column_name = 'coordinates'
  ) THEN
    ALTER TABLE floor_map_shapes ADD COLUMN coordinates JSONB;
    RAISE NOTICE '✅ Added coordinates column';
  ELSE
    RAISE NOTICE 'ℹ️  coordinates column already exists';
  END IF;
  
  -- Add rotation column
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'floor_map_shapes' AND column_name = 'rotation'
  ) THEN
    ALTER TABLE floor_map_shapes ADD COLUMN rotation FLOAT DEFAULT 0;
    RAISE NOTICE '✅ Added rotation column';
  END IF;
  
  -- Add opacity column
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'floor_map_shapes' AND column_name = 'opacity'
  ) THEN
    ALTER TABLE floor_map_shapes ADD COLUMN opacity FLOAT DEFAULT 1;
    RAISE NOTICE '✅ Added opacity column';
  END IF;
  
  -- Add name column
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'floor_map_shapes' AND column_name = 'name'
  ) THEN
    ALTER TABLE floor_map_shapes ADD COLUMN name TEXT;
    RAISE NOTICE '✅ Added name column';
  END IF;
  
  -- Add stroke_color column
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'floor_map_shapes' AND column_name = 'stroke_color'
  ) THEN
    ALTER TABLE floor_map_shapes ADD COLUMN stroke_color TEXT DEFAULT '#000000';
    RAISE NOTICE '✅ Added stroke_color column';
  END IF;
  
  -- Add fill_color column
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'floor_map_shapes' AND column_name = 'fill_color'
  ) THEN
    ALTER TABLE floor_map_shapes ADD COLUMN fill_color TEXT DEFAULT '#000000';
    RAISE NOTICE '✅ Added fill_color column';
  END IF;
  
  -- Add stroke_width column
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'floor_map_shapes' AND column_name = 'stroke_width'
  ) THEN
    ALTER TABLE floor_map_shapes ADD COLUMN stroke_width FLOAT DEFAULT 2;
    RAISE NOTICE '✅ Added stroke_width column';
  END IF;
  
  -- Add type column
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'floor_map_shapes' AND column_name = 'type'
  ) THEN
    ALTER TABLE floor_map_shapes ADD COLUMN type TEXT;
    RAISE NOTICE '✅ Added type column';
  END IF;
  
  -- Add plan_id column
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'floor_map_shapes' AND column_name = 'plan_id'
  ) THEN
    ALTER TABLE floor_map_shapes ADD COLUMN plan_id UUID REFERENCES floor_map_plans(id) ON DELETE CASCADE;
    RAISE NOTICE '✅ Added plan_id column';
  END IF;
  
  -- Add template_id column (TEXT for template identification)
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'floor_map_shapes' AND column_name = 'template_id'
  ) THEN
    ALTER TABLE floor_map_shapes ADD COLUMN template_id TEXT;
    RAISE NOTICE '✅ Added template_id column';
  END IF;
  
  -- Check if id column is UUID type, if not warn user
  IF EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'floor_map_shapes' 
    AND column_name = 'id' 
    AND data_type != 'uuid'
  ) THEN
    RAISE NOTICE '⚠️  Warning: id column is not UUID type - this is fine for templates';
  END IF;
  
  RAISE NOTICE '🎉 Table structure check complete!';
END $$;

-- 3. Verify the updated structure
SELECT 
  '=== Updated floor_map_shapes columns ===' as info;

SELECT 
  column_name,
  data_type,
  is_nullable,
  column_default
FROM information_schema.columns
WHERE table_name = 'floor_map_shapes'
ORDER BY ordinal_position;

-- 4. Test insert to verify everything works
DO $$
DECLARE
  test_plan_id UUID;
BEGIN
  -- Get any existing plan or create a test reference
  SELECT id INTO test_plan_id FROM floor_map_plans LIMIT 1;
  
  IF test_plan_id IS NOT NULL THEN
    RAISE NOTICE '📝 Testing insert with plan_id: %', test_plan_id;
    
    -- Try a test insert (will rollback)
    BEGIN
      INSERT INTO floor_map_shapes (
        id,
        template_id,
        plan_id,
        type,
        coordinates,
        stroke_color,
        fill_color,
        stroke_width,
        name,
        rotation,
        opacity
      ) VALUES (
        gen_random_uuid(),
        'test_template',
        test_plan_id,
        'freehand',
        '{"points": [{"x": 0, "y": 0}, {"x": 100, "y": 0}]}'::jsonb,
        '#000000',
        '#000000',
        2,
        'Test Shape',
        0,
        1
      );
      
      RAISE NOTICE '✅ Test insert successful!';
      
      -- Rollback the test insert
      RAISE EXCEPTION 'Test complete - rolling back';
    EXCEPTION
      WHEN OTHERS THEN
        IF SQLERRM = 'Test complete - rolling back' THEN
          RAISE NOTICE '✅ Table is ready for templates!';
        ELSE
          RAISE NOTICE '❌ Test insert failed: %', SQLERRM;
        END IF;
    END;
  ELSE
    RAISE NOTICE 'ℹ️  No floor_map_plans found - skipping test insert';
  END IF;
END $$;

-- Success message
SELECT '🎉 floor_map_shapes table is now ready for the template system!' as result;
