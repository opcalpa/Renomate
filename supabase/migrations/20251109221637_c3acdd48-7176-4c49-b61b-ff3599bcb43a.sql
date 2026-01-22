-- Add start_date and finish_date to tasks table
ALTER TABLE public.tasks 
ADD COLUMN start_date DATE,
ADD COLUMN finish_date DATE;

-- Add a check constraint to ensure finish_date is after start_date
ALTER TABLE public.tasks
ADD CONSTRAINT tasks_dates_check 
CHECK (finish_date IS NULL OR start_date IS NULL OR finish_date >= start_date);

-- Add an index for better query performance on date filtering
CREATE INDEX idx_tasks_dates ON public.tasks(start_date, finish_date);