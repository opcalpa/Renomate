-- Add finish_goal_date to projects table
ALTER TABLE public.projects
ADD COLUMN finish_goal_date date;