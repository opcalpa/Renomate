-- First, drop the existing check constraint on status
ALTER TABLE tasks DROP CONSTRAINT IF EXISTS tasks_status_check;

-- Update existing status values
UPDATE tasks 
SET status = 'to_do' 
WHERE status = 'todo';

UPDATE tasks 
SET status = 'done' 
WHERE status = 'completed';

-- Add new check constraint with updated valid status values
ALTER TABLE tasks 
ADD CONSTRAINT tasks_status_check 
CHECK (status IN ('discovery', 'to_do', 'on_hold', 'doing', 'done', 'scrapped'));

-- Add comment documenting valid status values
COMMENT ON COLUMN tasks.status IS 'Valid values: discovery, to_do, on_hold, doing, done, scrapped';