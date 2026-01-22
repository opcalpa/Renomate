-- Add cost_center column to tasks table
ALTER TABLE tasks ADD COLUMN cost_center text;

-- Add comment documenting valid cost center values
COMMENT ON COLUMN tasks.cost_center IS 'Cost center category: floor, paint, construction, kitchen, bathrooms, plumbing, tiles, windows, doors, electricity, carpentry, or custom values';
