-- Migrate Stakeholder fields to project_shares (Team Members)
-- This allows Team Members to have role type, contractor category, etc.

-- Step 1: Add stakeholder fields to project_shares
ALTER TABLE project_shares 
ADD COLUMN IF NOT EXISTS role_type TEXT CHECK (role_type IN ('contractor', 'client', 'other')),
ADD COLUMN IF NOT EXISTS contractor_category TEXT CHECK (contractor_category IN (
  'plumber',
  'electrician', 
  'painter',
  'carpenter',
  'general_renovator',
  'flooring_specialist',
  'hvac_technician',
  'mason',
  'roofer',
  'tiler',
  'glazier',
  'landscaper',
  'architect',
  'interior_designer',
  'supplier',
  'other'
)),
ADD COLUMN IF NOT EXISTS phone TEXT,
ADD COLUMN IF NOT EXISTS company TEXT,
ADD COLUMN IF NOT EXISTS notes TEXT;

-- Step 2: Add comments
COMMENT ON COLUMN project_shares.role_type IS 'Role type: contractor, client, or other';
COMMENT ON COLUMN project_shares.contractor_category IS 'Contractor category if role_type is contractor';
COMMENT ON COLUMN project_shares.phone IS 'Phone number for the team member';
COMMENT ON COLUMN project_shares.company IS 'Company name';
COMMENT ON COLUMN project_shares.notes IS 'Additional notes about the team member';

-- Step 3: Create indexes
CREATE INDEX IF NOT EXISTS project_shares_role_type_idx ON project_shares(role_type);
CREATE INDEX IF NOT EXISTS project_shares_contractor_category_idx ON project_shares(contractor_category);

-- Step 4: Migrate existing stakeholder data to project_shares where email matches
-- This matches stakeholders to team members by email
UPDATE project_shares ps
SET 
  role_type = s.role,
  contractor_category = CASE 
    WHEN s.role = 'contractor' THEN s.contractor_category 
    ELSE NULL 
  END,
  phone = s.phone,
  company = s.company,
  notes = s.notes
FROM stakeholders s
WHERE ps.project_id = s.project_id
  AND EXISTS (
    SELECT 1 FROM profiles p
    WHERE p.id = ps.shared_with_user_id
      AND LOWER(TRIM(p.email)) = LOWER(TRIM(s.email))
  )
  AND s.email IS NOT NULL
  AND s.email != '';

-- Step 5: Verify migration
SELECT 
  ps.id,
  p.name,
  p.email,
  ps.role_type,
  ps.contractor_category,
  ps.phone,
  ps.company
FROM project_shares ps
JOIN profiles p ON p.id = ps.shared_with_user_id
WHERE ps.role_type IS NOT NULL
LIMIT 10;

-- Step 6: Show remaining stakeholders (not matched to team members)
SELECT 
  s.id,
  s.name,
  s.email,
  s.role,
  s.contractor_category
FROM stakeholders s
WHERE NOT EXISTS (
  SELECT 1 FROM project_shares ps
  JOIN profiles p ON p.id = ps.shared_with_user_id
  WHERE ps.project_id = s.project_id
    AND LOWER(TRIM(p.email)) = LOWER(TRIM(s.email))
    AND s.email IS NOT NULL
    AND s.email != ''
)
LIMIT 10;
