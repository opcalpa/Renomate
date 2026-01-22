-- Add color column to rooms table for room appearance on canvas
-- This version is completely safe to run even if columns already exist

-- Add color column to rooms if it doesn't exist
DO $$ 
BEGIN
  -- Check and add color to rooms
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' 
    AND table_name = 'rooms' 
    AND column_name = 'color'
  ) THEN
    ALTER TABLE rooms ADD COLUMN color TEXT DEFAULT 'rgba(59, 130, 246, 0.2)';
    RAISE NOTICE 'Added color column to rooms table';
  ELSE
    RAISE NOTICE 'Color column already exists in rooms table - skipping';
  END IF;
END $$;

-- Add color and stroke_color columns to floor_map_shapes if they don't exist
DO $$ 
BEGIN
  -- Check and add color
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public'
    AND table_name = 'floor_map_shapes' 
    AND column_name = 'color'
  ) THEN
    ALTER TABLE floor_map_shapes ADD COLUMN color TEXT;
    RAISE NOTICE 'Added color column to floor_map_shapes table';
  ELSE
    RAISE NOTICE 'Color column already exists in floor_map_shapes table - skipping';
  END IF;
  
  -- Check and add stroke_color
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public'
    AND table_name = 'floor_map_shapes' 
    AND column_name = 'stroke_color'
  ) THEN
    ALTER TABLE floor_map_shapes ADD COLUMN stroke_color TEXT;
    RAISE NOTICE 'Added stroke_color column to floor_map_shapes table';
  ELSE
    RAISE NOTICE 'Stroke_color column already exists in floor_map_shapes table - skipping';
  END IF;
END $$;

-- Verify columns exist
DO $$
DECLARE
  rooms_color_exists BOOLEAN;
  shapes_color_exists BOOLEAN;
  shapes_stroke_exists BOOLEAN;
BEGIN
  -- Check rooms.color
  SELECT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' 
    AND table_name = 'rooms' 
    AND column_name = 'color'
  ) INTO rooms_color_exists;
  
  -- Check floor_map_shapes.color
  SELECT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public'
    AND table_name = 'floor_map_shapes' 
    AND column_name = 'color'
  ) INTO shapes_color_exists;
  
  -- Check floor_map_shapes.stroke_color
  SELECT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public'
    AND table_name = 'floor_map_shapes' 
    AND column_name = 'stroke_color'
  ) INTO shapes_stroke_exists;
  
  -- Report results
  RAISE NOTICE '=== VERIFICATION RESULTS ===';
  RAISE NOTICE 'rooms.color exists: %', rooms_color_exists;
  RAISE NOTICE 'floor_map_shapes.color exists: %', shapes_color_exists;
  RAISE NOTICE 'floor_map_shapes.stroke_color exists: %', shapes_stroke_exists;
  
  IF rooms_color_exists AND shapes_color_exists AND shapes_stroke_exists THEN
    RAISE NOTICE '✅ All columns exist! Room color feature is ready to use.';
  ELSE
    RAISE WARNING '⚠️ Some columns are missing. Please check the results above.';
  END IF;
END $$;
