-- Fix old status values in materials table to match new dropdown options
-- Old values: new, done, declined
-- New values: pending, ordered, delivered, installed, cancelled

-- Step 1: Show current status values
SELECT DISTINCT status, COUNT(*) as count
FROM materials
GROUP BY status
ORDER BY status;

-- Step 2: Update old status values to new ones
UPDATE materials
SET status = CASE
  WHEN status = 'new' THEN 'pending'
  WHEN status = 'done' THEN 'delivered'
  WHEN status = 'declined' THEN 'cancelled'
  ELSE status
END
WHERE status IN ('new', 'done', 'declined');

-- Step 3: Verify the changes
SELECT DISTINCT status, COUNT(*) as count
FROM materials
GROUP BY status
ORDER BY status;

-- Step 4: Set default for future inserts
ALTER TABLE materials 
ALTER COLUMN status SET DEFAULT 'pending';
