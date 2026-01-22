-- Add teams_access permission to project_shares and project_invitations
--
-- This migration adds the ability for project admins to grant team members
-- view access to the Teams management page.

-- Add teams_access to project_shares
ALTER TABLE public.project_shares 
ADD COLUMN IF NOT EXISTS teams_access TEXT DEFAULT 'none';

-- Add teams_access to project_invitations  
ALTER TABLE public.project_invitations 
ADD COLUMN IF NOT EXISTS teams_access TEXT DEFAULT 'none';

-- Add comments for documentation
COMMENT ON COLUMN public.project_shares.teams_access IS 'Access level for Teams management page (none, view)';
COMMENT ON COLUMN public.project_invitations.teams_access IS 'Access level for Teams management page (none, view)';

-- Verify the additions
SELECT 
  'project_shares' as table_name,
  COUNT(*) as total_rows,
  COUNT(teams_access) as rows_with_teams_access,
  COUNT(CASE WHEN teams_access = 'none' THEN 1 END) as none_access,
  COUNT(CASE WHEN teams_access = 'view' THEN 1 END) as view_access
FROM public.project_shares
UNION ALL
SELECT 
  'project_invitations' as table_name,
  COUNT(*) as total_rows,
  COUNT(teams_access) as rows_with_teams_access,
  COUNT(CASE WHEN teams_access = 'none' THEN 1 END) as none_access,
  COUNT(CASE WHEN teams_access = 'view' THEN 1 END) as view_access
FROM public.project_invitations;
