-- Add material and color fields to rooms table
-- These fields store information about room finishes and materials

-- Add columns if they don't exist
DO $$
BEGIN
  -- Material field (general materials description)
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' 
    AND table_name = 'rooms' 
    AND column_name = 'material'
  ) THEN
    ALTER TABLE public.rooms ADD COLUMN material TEXT;
    RAISE NOTICE '✅ Added material column to rooms table';
  ELSE
    RAISE NOTICE 'ℹ️  material column already exists in rooms table';
  END IF;

  -- Wall color field
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' 
    AND table_name = 'rooms' 
    AND column_name = 'wall_color'
  ) THEN
    ALTER TABLE public.rooms ADD COLUMN wall_color TEXT;
    RAISE NOTICE '✅ Added wall_color column to rooms table';
  ELSE
    RAISE NOTICE 'ℹ️  wall_color column already exists in rooms table';
  END IF;

  -- Ceiling color field
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' 
    AND table_name = 'rooms' 
    AND column_name = 'ceiling_color'
  ) THEN
    ALTER TABLE public.rooms ADD COLUMN ceiling_color TEXT;
    RAISE NOTICE '✅ Added ceiling_color column to rooms table';
  ELSE
    RAISE NOTICE 'ℹ️  ceiling_color column already exists in rooms table';
  END IF;

  -- Trim/woodwork color field
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' 
    AND table_name = 'rooms' 
    AND column_name = 'trim_color'
  ) THEN
    ALTER TABLE public.rooms ADD COLUMN trim_color TEXT;
    RAISE NOTICE '✅ Added trim_color column to rooms table';
  ELSE
    RAISE NOTICE 'ℹ️  trim_color column already exists in rooms table';
  END IF;
END $$;

-- Add comments for documentation
COMMENT ON COLUMN public.rooms.material IS 'General materials description for the room (flooring, walls, etc.)';
COMMENT ON COLUMN public.rooms.wall_color IS 'Wall paint color or finish';
COMMENT ON COLUMN public.rooms.ceiling_color IS 'Ceiling paint color or finish';
COMMENT ON COLUMN public.rooms.trim_color IS 'Trim/woodwork/snickerier paint color or finish';

-- Verify columns
DO $$
DECLARE
  col_record RECORD;
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '📋 New columns in rooms table:';
  FOR col_record IN 
    SELECT column_name, data_type, is_nullable
    FROM information_schema.columns 
    WHERE table_name = 'rooms'
    AND column_name IN ('material', 'wall_color', 'ceiling_color', 'trim_color')
    ORDER BY column_name
  LOOP
    RAISE NOTICE '  - % (%, nullable: %)', col_record.column_name, col_record.data_type, col_record.is_nullable;
  END LOOP;
END $$;

-- Success message
DO $$
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '✅✅✅ ROOM MATERIAL FIELDS ADDED! ✅✅✅';
  RAISE NOTICE '';
  RAISE NOTICE 'New fields available in rooms table:';
  RAISE NOTICE '  1. material - General materials description';
  RAISE NOTICE '  2. wall_color - Wall paint color';
  RAISE NOTICE '  3. ceiling_color - Ceiling paint color';
  RAISE NOTICE '  4. trim_color - Trim/woodwork color';
  RAISE NOTICE '';
  RAISE NOTICE 'Users can now specify these details in Room Details dialog.';
  RAISE NOTICE '';
END $$;
