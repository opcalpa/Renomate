-- ============================================================================
-- DATABASE DIAGNOSTIC SCRIPT
-- Run this to see what tables and columns exist in your database
-- ============================================================================

DO $$
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '========================================';
  RAISE NOTICE '🔍 DATABASE DIAGNOSTIC REPORT';
  RAISE NOTICE '========================================';
  RAISE NOTICE '';
END $$;

-- ============================================================================
-- 1. LIST ALL TABLES
-- ============================================================================
DO $$
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '📊 ALL TABLES IN PUBLIC SCHEMA:';
  RAISE NOTICE '--------------------------------';
END $$;

SELECT 
  schemaname as schema,
  tablename as table_name,
  tableowner as owner
FROM pg_tables 
WHERE schemaname = 'public'
ORDER BY tablename;

-- ============================================================================
-- 2. CHECK CRITICAL TABLES
-- ============================================================================
DO $$
DECLARE
  tables_to_check TEXT[] := ARRAY[
    'profiles',
    'projects', 
    'project_shares',
    'project_invitations',
    'team_members',
    'tasks',
    'task_assignments',
    'materials',
    'purchase_orders',
    'rooms',
    'floor_plans',
    'floor_map_shapes',
    'templates',
    'comments',
    'todos',
    'cost_centers'
  ];
  tbl_name TEXT;
  tbl_exists BOOLEAN;
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '🎯 CRITICAL TABLES CHECK:';
  RAISE NOTICE '--------------------------------';
  
  FOREACH tbl_name IN ARRAY tables_to_check
  LOOP
    SELECT EXISTS(
      SELECT 1 FROM information_schema.tables t
      WHERE t.table_schema = 'public' AND t.table_name = tbl_name
    ) INTO tbl_exists;
    
    IF tbl_exists THEN
      RAISE NOTICE '✅ % exists', tbl_name;
    ELSE
      RAISE NOTICE '❌ % MISSING', tbl_name;
    END IF;
  END LOOP;
END $$;

-- ============================================================================
-- 3. TEMPLATES TABLE DETAILS (if exists)
-- ============================================================================
DO $$
DECLARE
  table_exists BOOLEAN;
BEGIN
  SELECT EXISTS(
    SELECT 1 FROM information_schema.tables 
    WHERE table_schema = 'public' AND table_name = 'templates'
  ) INTO table_exists;
  
  RAISE NOTICE '';
  RAISE NOTICE '📋 TEMPLATES TABLE:';
  RAISE NOTICE '--------------------------------';
  
  IF table_exists THEN
    RAISE NOTICE '✅ Templates table exists';
    RAISE NOTICE 'Columns:';
  ELSE
    RAISE NOTICE '❌ Templates table does NOT exist';
  END IF;
END $$;

-- Show templates columns if table exists
SELECT 
  column_name,
  data_type,
  is_nullable,
  column_default
FROM information_schema.columns
WHERE table_schema = 'public' 
  AND table_name = 'templates'
ORDER BY ordinal_position;

-- ============================================================================
-- 4. ROOMS TABLE DETAILS (if exists)
-- ============================================================================
DO $$
DECLARE
  table_exists BOOLEAN;
  has_material BOOLEAN;
  has_wall_color BOOLEAN;
  has_ceiling_color BOOLEAN;
  has_trim_color BOOLEAN;
BEGIN
  SELECT EXISTS(
    SELECT 1 FROM information_schema.tables 
    WHERE table_schema = 'public' AND table_name = 'rooms'
  ) INTO table_exists;
  
  RAISE NOTICE '';
  RAISE NOTICE '🏠 ROOMS TABLE:';
  RAISE NOTICE '--------------------------------';
  
  IF table_exists THEN
    RAISE NOTICE '✅ Rooms table exists';
    
    -- Check for specific columns
    SELECT EXISTS(
      SELECT 1 FROM information_schema.columns 
      WHERE table_name = 'rooms' AND column_name = 'material'
    ) INTO has_material;
    
    SELECT EXISTS(
      SELECT 1 FROM information_schema.columns 
      WHERE table_name = 'rooms' AND column_name = 'wall_color'
    ) INTO has_wall_color;
    
    SELECT EXISTS(
      SELECT 1 FROM information_schema.columns 
      WHERE table_name = 'rooms' AND column_name = 'ceiling_color'
    ) INTO has_ceiling_color;
    
    SELECT EXISTS(
      SELECT 1 FROM information_schema.columns 
      WHERE table_name = 'rooms' AND column_name = 'trim_color'
    ) INTO has_trim_color;
    
    RAISE NOTICE '';
    RAISE NOTICE 'Material/Color columns:';
    IF has_material THEN
      RAISE NOTICE '  ✅ material';
    ELSE
      RAISE NOTICE '  ❌ material (missing)';
    END IF;
    
    IF has_wall_color THEN
      RAISE NOTICE '  ✅ wall_color';
    ELSE
      RAISE NOTICE '  ❌ wall_color (missing)';
    END IF;
    
    IF has_ceiling_color THEN
      RAISE NOTICE '  ✅ ceiling_color';
    ELSE
      RAISE NOTICE '  ❌ ceiling_color (missing)';
    END IF;
    
    IF has_trim_color THEN
      RAISE NOTICE '  ✅ trim_color';
    ELSE
      RAISE NOTICE '  ❌ trim_color (missing)';
    END IF;
  ELSE
    RAISE NOTICE '❌ Rooms table does NOT exist';
  END IF;
END $$;

-- ============================================================================
-- 5. STORAGE BUCKETS
-- ============================================================================
DO $$
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '📦 STORAGE BUCKETS:';
  RAISE NOTICE '--------------------------------';
END $$;

SELECT 
  id as bucket_id,
  name,
  public,
  file_size_limit,
  allowed_mime_types
FROM storage.buckets
ORDER BY id;

-- ============================================================================
-- 6. RLS POLICIES COUNT
-- ============================================================================
DO $$
DECLARE
  total_policies INTEGER;
BEGIN
  SELECT COUNT(*) INTO total_policies
  FROM pg_policies
  WHERE schemaname = 'public';
  
  RAISE NOTICE '';
  RAISE NOTICE '🔒 SECURITY:';
  RAISE NOTICE '--------------------------------';
  RAISE NOTICE 'Total RLS policies: %', total_policies;
END $$;

-- Show policies per table
SELECT 
  tablename,
  COUNT(*) as policy_count
FROM pg_policies
WHERE schemaname = 'public'
GROUP BY tablename
ORDER BY tablename;

-- ============================================================================
-- 7. SUMMARY
-- ============================================================================
DO $$
DECLARE
  total_tables INTEGER;
  total_columns INTEGER;
BEGIN
  SELECT COUNT(*) INTO total_tables
  FROM information_schema.tables
  WHERE table_schema = 'public';
  
  SELECT COUNT(*) INTO total_columns
  FROM information_schema.columns
  WHERE table_schema = 'public';
  
  RAISE NOTICE '';
  RAISE NOTICE '========================================';
  RAISE NOTICE '📊 SUMMARY';
  RAISE NOTICE '========================================';
  RAISE NOTICE 'Total tables: %', total_tables;
  RAISE NOTICE 'Total columns: %', total_columns;
  RAISE NOTICE '';
  RAISE NOTICE '✅ Diagnostic complete!';
  RAISE NOTICE '';
END $$;
