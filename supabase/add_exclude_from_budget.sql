-- Add exclude_from_budget column to materials table
-- For purchase orders that are ongoing costs not part of project budget

ALTER TABLE public.materials 
ADD COLUMN IF NOT EXISTS exclude_from_budget BOOLEAN NOT NULL DEFAULT false;

COMMENT ON COLUMN public.materials.exclude_from_budget IS 'If true, this purchase order is excluded from budget calculations (ongoing operational cost)';

-- Verify
SELECT column_name, data_type, column_default
FROM information_schema.columns 
WHERE table_name = 'materials' 
AND column_name = 'exclude_from_budget';
