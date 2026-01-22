-- Update Purchase Orders permissions with Create option and Scope

-- Step 1: Drop old constraint and add new one with 'create' option
ALTER TABLE project_shares DROP CONSTRAINT IF EXISTS project_shares_purchases_access_check;

ALTER TABLE project_shares 
ADD CONSTRAINT project_shares_purchases_access_check 
CHECK (purchases_access IN ('none', 'view', 'create', 'edit'));

-- Step 2: Add scope for purchase orders
ALTER TABLE project_shares 
ADD COLUMN IF NOT EXISTS purchases_scope TEXT CHECK (purchases_scope IN ('all', 'assigned')) DEFAULT 'assigned';

-- Step 3: Set default scope for existing members
UPDATE project_shares
SET purchases_scope = CASE
  WHEN role IN ('admin', 'editor') THEN 'all'
  ELSE 'assigned'
END
WHERE purchases_scope IS NULL;

-- Step 4: Update project_invitations table
ALTER TABLE project_invitations DROP CONSTRAINT IF EXISTS project_invitations_purchases_access_check;

ALTER TABLE project_invitations
ADD CONSTRAINT project_invitations_purchases_access_check
CHECK (purchases_access IN ('none', 'view', 'create', 'edit'));

ALTER TABLE project_invitations
ADD COLUMN IF NOT EXISTS purchases_scope TEXT CHECK (purchases_scope IN ('all', 'assigned')) DEFAULT 'assigned';

-- Step 5: Migrate existing 'edit' to 'create' for material_requester role
UPDATE project_shares
SET purchases_access = 'create'
WHERE role = 'material_requester' AND purchases_access = 'edit';

-- Step 6: Create index for purchases_scope
CREATE INDEX IF NOT EXISTS project_shares_purchases_scope_idx ON project_shares(purchases_scope);

-- Step 7: Verify the changes
SELECT 
  id,
  role,
  purchases_access,
  purchases_scope,
  tasks_access,
  tasks_scope
FROM project_shares
ORDER BY created_at DESC
LIMIT 5;
