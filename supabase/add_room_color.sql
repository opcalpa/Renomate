-- Add color column to rooms table for room appearance on canvas
-- This allows users to customize the fill color of rooms in the floor plan editor

-- Add color column if it doesn't exist
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'rooms' AND column_name = 'color'
  ) THEN
    ALTER TABLE rooms ADD COLUMN color TEXT DEFAULT 'rgba(59, 130, 246, 0.2)';
    COMMENT ON COLUMN rooms.color IS 'RGBA color string for room fill on canvas';
  END IF;
END $$;

-- Add color and stroke_color columns to floor_map_shapes if they don't exist
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'floor_map_shapes' AND column_name = 'color'
  ) THEN
    ALTER TABLE floor_map_shapes ADD COLUMN color TEXT;
    COMMENT ON COLUMN floor_map_shapes.color IS 'Fill color for shapes on canvas';
  END IF;
  
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'floor_map_shapes' AND column_name = 'stroke_color'
  ) THEN
    ALTER TABLE floor_map_shapes ADD COLUMN stroke_color TEXT;
    COMMENT ON COLUMN floor_map_shapes.stroke_color IS 'Stroke/border color for shapes on canvas';
  END IF;
END $$;
