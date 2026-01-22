-- Add start_date column to projects table
ALTER TABLE public.projects 
ADD COLUMN start_date date;