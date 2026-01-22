-- Update purchase orders to use "price_per_unit" and "price_total"
-- This provides clearer pricing structure with automatic total calculation

-- Step 1: Rename 'cost' column to 'price_per_unit'
DO $$
BEGIN
  -- Check if cost column exists
  IF EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' 
    AND table_name = 'materials' 
    AND column_name = 'cost'
  ) THEN
    ALTER TABLE public.materials RENAME COLUMN cost TO price_per_unit;
    RAISE NOTICE '✅ Renamed cost → price_per_unit';
  ELSE
    RAISE NOTICE 'ℹ️  cost column does not exist (already renamed or never existed)';
  END IF;
END $$;

-- Step 2: Add price_total as a GENERATED column (automatic calculation)
DO $$
BEGIN
  -- Check if price_total column already exists
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' 
    AND table_name = 'materials' 
    AND column_name = 'price_total'
  ) THEN
    -- Add generated column that calculates quantity * price_per_unit
    ALTER TABLE public.materials 
    ADD COLUMN price_total DECIMAL(12, 2) 
    GENERATED ALWAYS AS (
      CASE 
        WHEN quantity IS NOT NULL AND price_per_unit IS NOT NULL 
        THEN quantity * price_per_unit 
        ELSE NULL 
      END
    ) STORED;
    RAISE NOTICE '✅ Added price_total column (auto-calculated)';
  ELSE
    RAISE NOTICE 'ℹ️  price_total column already exists';
  END IF;
END $$;

-- Step 3: Add comments for documentation
COMMENT ON COLUMN public.materials.price_per_unit IS 'Price per unit (e.g., $10 per gallon, $50 per sqm)';
COMMENT ON COLUMN public.materials.price_total IS 'Total price (automatically calculated: quantity × price_per_unit)';

-- Step 4: Create index for performance on price_total
CREATE INDEX IF NOT EXISTS materials_price_total_idx ON materials(price_total);

-- Step 5: Verify the changes
DO $$
DECLARE
  col_record RECORD;
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '📋 Updated columns in materials table:';
  FOR col_record IN 
    SELECT 
      column_name, 
      data_type, 
      is_nullable,
      column_default,
      is_generated
    FROM information_schema.columns 
    WHERE table_name = 'materials'
    AND column_name IN ('price_per_unit', 'price_total', 'quantity')
    ORDER BY 
      CASE column_name
        WHEN 'quantity' THEN 1
        WHEN 'price_per_unit' THEN 2
        WHEN 'price_total' THEN 3
      END
  LOOP
    RAISE NOTICE '  - % (%, nullable: %, generated: %)', 
      col_record.column_name, 
      col_record.data_type, 
      col_record.is_nullable,
      COALESCE(col_record.is_generated, 'NEVER');
  END LOOP;
END $$;

-- Step 6: Test the calculation with example data (read-only)
DO $$
DECLARE
  test_record RECORD;
  test_count INTEGER;
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '🧪 Testing price_total calculation:';
  
  SELECT COUNT(*) INTO test_count FROM materials WHERE quantity IS NOT NULL AND price_per_unit IS NOT NULL;
  
  IF test_count > 0 THEN
    FOR test_record IN 
      SELECT 
        name,
        quantity,
        unit,
        price_per_unit,
        price_total
      FROM materials
      WHERE quantity IS NOT NULL AND price_per_unit IS NOT NULL
      LIMIT 3
    LOOP
      RAISE NOTICE '  % × % %: $% per unit = $% total',
        test_record.quantity,
        test_record.name,
        test_record.unit,
        test_record.price_per_unit,
        test_record.price_total;
    END LOOP;
  ELSE
    RAISE NOTICE '  No existing materials with quantity and price to test';
    RAISE NOTICE '  Create a new purchase order to test the calculation!';
  END IF;
END $$;

-- Success message
DO $$
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '✅✅✅ PURCHASE ORDER PRICING UPDATED! ✅✅✅';
  RAISE NOTICE '';
  RAISE NOTICE 'Changes:';
  RAISE NOTICE '  1. cost → price_per_unit (renamed)';
  RAISE NOTICE '  2. price_total (new, auto-calculated)';
  RAISE NOTICE '';
  RAISE NOTICE 'Formula: price_total = quantity × price_per_unit';
  RAISE NOTICE '';
  RAISE NOTICE 'Example:';
  RAISE NOTICE '  10 gallons × $50/gallon = $500 total ✅';
  RAISE NOTICE '';
  RAISE NOTICE 'The UI will now show:';
  RAISE NOTICE '  - Price per unit: $50';
  RAISE NOTICE '  - Price Total: $500 (auto-calculated)';
  RAISE NOTICE '';
END $$;
