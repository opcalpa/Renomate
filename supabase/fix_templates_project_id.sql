-- ============================================================================
-- FIX TEMPLATES - Make project_id nullable
-- ============================================================================
-- Templates should be user-specific and optionally project-specific
-- This allows users to create personal template libraries that can be used
-- across multiple projects

-- Drop the NOT NULL constraint on project_id if it exists
ALTER TABLE public.templates 
  ALTER COLUMN project_id DROP NOT NULL;

-- Update RLS policies to include templates without project_id
DROP POLICY IF EXISTS "Users can view own templates" ON public.templates;
DROP POLICY IF EXISTS "Users can insert own templates" ON public.templates;
DROP POLICY IF EXISTS "Users can update own templates" ON public.templates;
DROP POLICY IF EXISTS "Users can delete own templates" ON public.templates;

-- Users can view their own templates (regardless of project)
CREATE POLICY "Users can view own templates"
  ON public.templates
  FOR SELECT
  USING (auth.uid() = user_id);

-- Users can insert their own templates
CREATE POLICY "Users can insert own templates"
  ON public.templates
  FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Users can update their own templates
CREATE POLICY "Users can update own templates"
  ON public.templates
  FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Users can delete their own templates
CREATE POLICY "Users can delete own templates"
  ON public.templates
  FOR DELETE
  USING (auth.uid() = user_id);
