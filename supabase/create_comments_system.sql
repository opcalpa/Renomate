-- Create Comments System for Tasks and Purchase Orders
-- With @mention support

-- ===================================
-- STEP 1: Create comments table
-- ===================================
CREATE TABLE IF NOT EXISTS public.comments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  content TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
  updated_at TIMESTAMPTZ DEFAULT now() NOT NULL,
  created_by_user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  
  -- Either task_id OR material_id must be set (not both)
  task_id UUID REFERENCES public.tasks(id) ON DELETE CASCADE,
  material_id UUID REFERENCES public.materials(id) ON DELETE CASCADE,
  
  -- Ensure at least one is set
  CONSTRAINT comments_target_check CHECK (
    (task_id IS NOT NULL AND material_id IS NULL) OR 
    (task_id IS NULL AND material_id IS NOT NULL)
  )
);

-- ===================================
-- STEP 2: Create comment_mentions table
-- ===================================
CREATE TABLE IF NOT EXISTS public.comment_mentions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  comment_id UUID REFERENCES public.comments(id) ON DELETE CASCADE NOT NULL,
  mentioned_user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
  
  UNIQUE(comment_id, mentioned_user_id)
);

-- ===================================
-- STEP 3: Create indexes
-- ===================================
CREATE INDEX IF NOT EXISTS comments_task_id_idx ON public.comments(task_id);
CREATE INDEX IF NOT EXISTS comments_material_id_idx ON public.comments(material_id);
CREATE INDEX IF NOT EXISTS comments_created_by_idx ON public.comments(created_by_user_id);
CREATE INDEX IF NOT EXISTS comments_created_at_idx ON public.comments(created_at DESC);
CREATE INDEX IF NOT EXISTS comment_mentions_comment_idx ON public.comment_mentions(comment_id);
CREATE INDEX IF NOT EXISTS comment_mentions_user_idx ON public.comment_mentions(mentioned_user_id);

-- ===================================
-- STEP 4: Enable RLS
-- ===================================
ALTER TABLE public.comments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.comment_mentions ENABLE ROW LEVEL SECURITY;

-- ===================================
-- STEP 5: Create RLS policies for comments
-- ===================================

-- SELECT: Users can view comments on tasks/materials they have access to
CREATE POLICY "Users can view comments"
ON public.comments
FOR SELECT
USING (
  -- Comments on tasks in accessible projects
  (task_id IS NOT NULL AND task_id IN (
    SELECT t.id FROM tasks t
    WHERE user_has_project_access(t.project_id)
  ))
  OR
  -- Comments on materials in accessible projects
  (material_id IS NOT NULL AND material_id IN (
    SELECT m.id FROM materials m
    WHERE user_has_project_access(m.project_id)
  ))
);

-- INSERT: Users can comment on tasks/materials they have access to
CREATE POLICY "Users can create comments"
ON public.comments
FOR INSERT
WITH CHECK (
  -- Can comment on tasks in accessible projects
  (task_id IS NOT NULL AND task_id IN (
    SELECT t.id FROM tasks t
    WHERE user_has_project_access(t.project_id)
  ))
  OR
  -- Can comment on materials in accessible projects
  (material_id IS NOT NULL AND material_id IN (
    SELECT m.id FROM materials m
    WHERE user_has_project_access(m.project_id)
  ))
);

-- UPDATE: Users can only edit their own comments
CREATE POLICY "Users can update own comments"
ON public.comments
FOR UPDATE
USING (
  created_by_user_id IN (
    SELECT id FROM profiles WHERE user_id = auth.uid()
  )
);

-- DELETE: Users can only delete their own comments
CREATE POLICY "Users can delete own comments"
ON public.comments
FOR DELETE
USING (
  created_by_user_id IN (
    SELECT id FROM profiles WHERE user_id = auth.uid()
  )
);

-- ===================================
-- STEP 6: Create RLS policies for mentions
-- ===================================

-- SELECT: Users can view mentions on comments they can see
CREATE POLICY "Users can view mentions"
ON public.comment_mentions
FOR SELECT
USING (
  comment_id IN (
    SELECT id FROM comments WHERE user_has_project_access(
      COALESCE(
        (SELECT project_id FROM tasks WHERE id = comments.task_id),
        (SELECT project_id FROM materials WHERE id = comments.material_id)
      )
    )
  )
);

-- INSERT: Users can create mentions when creating comments
CREATE POLICY "Users can create mentions"
ON public.comment_mentions
FOR INSERT
WITH CHECK (
  comment_id IN (
    SELECT id FROM comments 
    WHERE created_by_user_id IN (
      SELECT id FROM profiles WHERE user_id = auth.uid()
    )
  )
);

-- DELETE: Users can delete mentions on their own comments
CREATE POLICY "Users can delete mentions"
ON public.comment_mentions
FOR DELETE
USING (
  comment_id IN (
    SELECT id FROM comments 
    WHERE created_by_user_id IN (
      SELECT id FROM profiles WHERE user_id = auth.uid()
    )
  )
);

-- ===================================
-- STEP 7: Create updated_at trigger
-- ===================================
DROP TRIGGER IF EXISTS update_comments_updated_at ON public.comments;
CREATE TRIGGER update_comments_updated_at
  BEFORE UPDATE ON public.comments
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- ===================================
-- STEP 8: Verify
-- ===================================
SELECT 'Comments table created' as status, COUNT(*) as column_count
FROM information_schema.columns
WHERE table_name = 'comments';

SELECT 'Comment mentions table created' as status, COUNT(*) as column_count
FROM information_schema.columns
WHERE table_name = 'comment_mentions';

SELECT 'RLS policies created' as status, COUNT(*) as policy_count
FROM pg_policies
WHERE tablename IN ('comments', 'comment_mentions');

-- Success message
DO $$
BEGIN
  RAISE NOTICE '✅ Comments system created successfully!';
  RAISE NOTICE '📝 Tables: comments, comment_mentions';
  RAISE NOTICE '🔒 RLS policies enabled';
  RAISE NOTICE '👉 Ready to implement frontend!';
END $$;
