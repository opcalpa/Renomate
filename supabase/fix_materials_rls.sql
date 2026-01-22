-- Fix RLS policies for materials table to allow purchase order creation

-- Step 1: Drop existing policies
DROP POLICY IF EXISTS "Users can view materials in their projects" ON public.materials;
DROP POLICY IF EXISTS "Users can create materials in their projects" ON public.materials;
DROP POLICY IF EXISTS "Users can update materials in their projects" ON public.materials;
DROP POLICY IF EXISTS "Users can delete materials in their projects" ON public.materials;

-- Step 2: Check if created_by_user_id exists, if not add it
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT FROM information_schema.columns 
    WHERE table_name = 'materials' AND column_name = 'created_by_user_id'
  ) THEN
    ALTER TABLE materials 
    ADD COLUMN created_by_user_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL;
  END IF;
END $$;

-- Step 3: Create new RLS policies that work properly

-- Allow viewing materials in projects user has access to
CREATE POLICY "Users can view materials in their projects" ON public.materials
FOR SELECT USING (
  task_id IN (
    SELECT t.id FROM tasks t
    WHERE t.project_id IN (
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
  )
  OR project_id IN (
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

-- Allow creating materials if user has access to the project
CREATE POLICY "Users can create materials in their projects" ON public.materials
FOR INSERT WITH CHECK (
  (task_id IS NOT NULL AND task_id IN (
    SELECT t.id FROM tasks t
    WHERE t.project_id IN (
      SELECT id FROM projects 
      WHERE owner_id IN (
        SELECT id FROM profiles WHERE user_id = auth.uid()
      )
      OR id IN (
        SELECT project_id FROM project_shares 
        WHERE shared_with_user_id IN (
          SELECT id FROM profiles WHERE user_id = auth.uid()
        )
        AND (purchases_access IN ('create', 'edit') OR role IN ('admin', 'editor'))
      )
    )
  ))
  OR
  (project_id IS NOT NULL AND project_id IN (
    SELECT id FROM projects 
    WHERE owner_id IN (
      SELECT id FROM profiles WHERE user_id = auth.uid()
    )
    OR id IN (
      SELECT project_id FROM project_shares 
      WHERE shared_with_user_id IN (
        SELECT id FROM profiles WHERE user_id = auth.uid()
      )
      AND (purchases_access IN ('create', 'edit') OR role IN ('admin', 'editor'))
    )
  ))
);

-- Allow updating materials if user has edit access
CREATE POLICY "Users can update materials in their projects" ON public.materials
FOR UPDATE USING (
  (task_id IN (
    SELECT t.id FROM tasks t
    WHERE t.project_id IN (
      SELECT id FROM projects 
      WHERE owner_id IN (
        SELECT id FROM profiles WHERE user_id = auth.uid()
      )
      OR id IN (
        SELECT project_id FROM project_shares 
        WHERE shared_with_user_id IN (
          SELECT id FROM profiles WHERE user_id = auth.uid()
        )
        AND (purchases_access = 'edit' OR role IN ('admin', 'editor'))
      )
    )
  ))
  OR
  (project_id IN (
    SELECT id FROM projects 
    WHERE owner_id IN (
      SELECT id FROM profiles WHERE user_id = auth.uid()
    )
    OR id IN (
      SELECT project_id FROM project_shares 
      WHERE shared_with_user_id IN (
        SELECT id FROM profiles WHERE user_id = auth.uid()
      )
      AND (purchases_access = 'edit' OR role IN ('admin', 'editor'))
    )
  ))
);

-- Allow deleting materials if user is admin/editor
CREATE POLICY "Users can delete materials in their projects" ON public.materials
FOR DELETE USING (
  (task_id IN (
    SELECT t.id FROM tasks t
    WHERE t.project_id IN (
      SELECT id FROM projects 
      WHERE owner_id IN (
        SELECT id FROM profiles WHERE user_id = auth.uid()
      )
      OR id IN (
        SELECT project_id FROM project_shares 
        WHERE shared_with_user_id IN (
          SELECT id FROM profiles WHERE user_id = auth.uid()
        )
        AND role IN ('admin', 'editor')
      )
    )
  ))
  OR
  (project_id IN (
    SELECT id FROM projects 
    WHERE owner_id IN (
      SELECT id FROM profiles WHERE user_id = auth.uid()
    )
    OR id IN (
      SELECT project_id FROM project_shares 
      WHERE shared_with_user_id IN (
        SELECT id FROM profiles WHERE user_id = auth.uid()
      )
      AND role IN ('admin', 'editor')
    )
  ))
);

-- Step 4: Verify policies are created
SELECT 
  schemaname,
  tablename,
  policyname,
  cmd
FROM pg_policies
WHERE tablename = 'materials'
ORDER BY policyname;
