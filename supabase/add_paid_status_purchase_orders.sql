-- Add "paid" status to purchase orders (materials table)
-- This allows tracking when purchase orders have been paid

-- Step 1: Drop the existing CHECK constraint
ALTER TABLE public.materials 
DROP CONSTRAINT IF EXISTS materials_status_check;

-- Step 2: Add new CHECK constraint with "paid" status included
ALTER TABLE public.materials
ADD CONSTRAINT materials_status_check 
CHECK (status IN ('pending', 'ordered', 'delivered', 'installed', 'paid', 'new', 'done', 'declined'));

-- Note: We include both old statuses (new, done, declined) and new statuses
-- (pending, ordered, delivered, installed, paid) for backward compatibility

-- Step 3: Add comment to document the status field
COMMENT ON COLUMN public.materials.status IS 'Purchase order status: pending (not ordered yet), ordered (order placed), delivered (received), installed (used/installed), paid (payment completed), or legacy statuses: new, done, declined';

-- Step 4: Verify the change
DO $$
BEGIN
  RAISE NOTICE '✅ "paid" status added to purchase orders!';
  RAISE NOTICE '';
  RAISE NOTICE 'Valid statuses now:';
  RAISE NOTICE '  - pending: Not ordered yet';
  RAISE NOTICE '  - ordered: Order has been placed';
  RAISE NOTICE '  - delivered: Items received';
  RAISE NOTICE '  - installed: Items used/installed';
  RAISE NOTICE '  - paid: Payment completed ⭐ NEW!';
  RAISE NOTICE '  - new, done, declined: Legacy statuses (still supported)';
  RAISE NOTICE '';
END $$;

-- Step 5: Show current constraint
SELECT 
  conname as constraint_name,
  pg_get_constraintdef(oid) as constraint_definition
FROM pg_constraint
WHERE conname = 'materials_status_check';
