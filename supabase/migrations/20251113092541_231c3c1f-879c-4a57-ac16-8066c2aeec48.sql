-- Add budget column to tasks table
ALTER TABLE public.tasks 
ADD COLUMN budget numeric DEFAULT 0;