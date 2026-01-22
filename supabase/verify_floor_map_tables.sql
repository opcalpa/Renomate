-- Verification script for floor_map tables
-- Run this to check if all necessary tables exist and have correct structure

-- ============================================================================
-- CHECK IF TABLES EXIST
-- ============================================================================

DO $$
DECLARE
  plans_exists BOOLEAN;
  shapes_exists BOOLEAN;
BEGIN
  -- Check if floor_map_plans exists
  SELECT EXISTS (
    SELECT FROM information_schema.tables 
    WHERE table_schema = 'public' 
    AND table_name = 'floor_map_plans'
  ) INTO plans_exists;
  
  -- Check if floor_map_shapes exists
  SELECT EXISTS (
    SELECT FROM information_schema.tables 
    WHERE table_schema = 'public' 
    AND table_name = 'floor_map_shapes'
  ) INTO shapes_exists;
  
  RAISE NOTICE '===========================================';
  RAISE NOTICE 'FLOOR MAP TABLES VERIFICATION';
  RAISE NOTICE '===========================================';
  RAISE NOTICE 'floor_map_plans exists: %', plans_exists;
  RAISE NOTICE 'floor_map_shapes exists: %', shapes_exists;
  RAISE NOTICE '';
  
  IF NOT plans_exists OR NOT shapes_exists THEN
    RAISE NOTICE '❌ MISSING TABLES! Run complete_schema_fixed.sql';
    RAISE NOTICE '';
  ELSE
    RAISE NOTICE '✅ All tables exist';
    RAISE NOTICE '';
  END IF;
END $$;

-- ============================================================================
-- CHECK COLUMN STRUCTURE
-- ============================================================================

-- Check floor_map_plans columns
SELECT 
  'floor_map_plans' as table_name,
  column_name,
  data_type,
  is_nullable
FROM information_schema.columns
WHERE table_schema = 'public' 
  AND table_name = 'floor_map_plans'
ORDER BY ordinal_position;

-- Check floor_map_shapes columns
SELECT 
  'floor_map_shapes' as table_name,
  column_name,
  data_type,
  is_nullable
FROM information_schema.columns
WHERE table_schema = 'public' 
  AND table_name = 'floor_map_shapes'
ORDER BY ordinal_position;

-- ============================================================================
-- CHECK RLS POLICIES
-- ============================================================================

-- Check RLS enabled
DO $$
DECLARE
  plans_rls BOOLEAN;
  shapes_rls BOOLEAN;
BEGIN
  SELECT relrowsecurity INTO plans_rls
  FROM pg_class
  WHERE relname = 'floor_map_plans' AND relnamespace = 'public'::regnamespace;
  
  SELECT relrowsecurity INTO shapes_rls
  FROM pg_class
  WHERE relname = 'floor_map_shapes' AND relnamespace = 'public'::regnamespace;
  
  RAISE NOTICE '===========================================';
  RAISE NOTICE 'RLS STATUS';
  RAISE NOTICE '===========================================';
  RAISE NOTICE 'floor_map_plans RLS enabled: %', COALESCE(plans_rls, false);
  RAISE NOTICE 'floor_map_shapes RLS enabled: %', COALESCE(shapes_rls, false);
  RAISE NOTICE '';
END $$;

-- List RLS policies
SELECT 
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd,
  qual
FROM pg_policies
WHERE schemaname = 'public'
  AND tablename IN ('floor_map_plans', 'floor_map_shapes')
ORDER BY tablename, policyname;

-- ============================================================================
-- CHECK INDEXES
-- ============================================================================

SELECT 
  schemaname,
  tablename,
  indexname,
  indexdef
FROM pg_indexes
WHERE schemaname = 'public'
  AND tablename IN ('floor_map_plans', 'floor_map_shapes')
ORDER BY tablename, indexname;

-- ============================================================================
-- CHECK FOREIGN KEYS
-- ============================================================================

SELECT
  tc.table_name,
  kcu.column_name,
  ccu.table_name AS foreign_table_name,
  ccu.column_name AS foreign_column_name
FROM information_schema.table_constraints AS tc
JOIN information_schema.key_column_usage AS kcu
  ON tc.constraint_name = kcu.constraint_name
  AND tc.table_schema = kcu.table_schema
JOIN information_schema.constraint_column_usage AS ccu
  ON ccu.constraint_name = tc.constraint_name
  AND ccu.table_schema = tc.table_schema
WHERE tc.constraint_type = 'FOREIGN KEY'
  AND tc.table_schema = 'public'
  AND tc.table_name IN ('floor_map_plans', 'floor_map_shapes');

-- ============================================================================
-- CHECK DATA (Sample)
-- ============================================================================

-- Count plans
SELECT 
  'floor_map_plans' as table_name,
  COUNT(*) as row_count
FROM public.floor_map_plans;

-- Count shapes
SELECT 
  'floor_map_shapes' as table_name,
  COUNT(*) as row_count
FROM public.floor_map_shapes;

-- Sample plans (if any)
SELECT 
  id,
  project_id,
  name,
  created_at,
  (SELECT COUNT(*) FROM public.floor_map_shapes WHERE plan_id = fp.id) as shape_count
FROM public.floor_map_plans fp
ORDER BY created_at DESC
LIMIT 5;

-- ============================================================================
-- SUMMARY
-- ============================================================================

DO $$
DECLARE
  plans_count INTEGER;
  shapes_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO plans_count FROM public.floor_map_plans;
  SELECT COUNT(*) INTO shapes_count FROM public.floor_map_shapes;
  
  RAISE NOTICE '===========================================';
  RAISE NOTICE 'DATABASE SUMMARY';
  RAISE NOTICE '===========================================';
  RAISE NOTICE 'Total floor plans: %', plans_count;
  RAISE NOTICE 'Total shapes: %', shapes_count;
  RAISE NOTICE '';
  
  IF plans_count = 0 THEN
    RAISE NOTICE 'ℹ️  No floor plans created yet';
  END IF;
  
  IF shapes_count = 0 AND plans_count > 0 THEN
    RAISE NOTICE '⚠️  Plans exist but no shapes - expected if newly created';
  END IF;
  
  RAISE NOTICE '===========================================';
  RAISE NOTICE 'VERIFICATION COMPLETE';
  RAISE NOTICE '===========================================';
END $$;
