-- Create floor_map_plans table for managing multiple floor plans per project
CREATE TABLE public.floor_map_plans (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  project_id UUID NOT NULL,
  name TEXT NOT NULL DEFAULT 'Untitled Plan',
  is_default BOOLEAN NOT NULL DEFAULT false,
  view_settings JSONB NOT NULL DEFAULT '{
    "cameraX": 0,
    "cameraY": 0,
    "zoom": 1,
    "rotation": 0,
    "mode": "floor"
  }'::jsonb,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- Enable Row Level Security
ALTER TABLE public.floor_map_plans ENABLE ROW LEVEL SECURITY;

-- Create policies for floor_map_plans
CREATE POLICY "Users can view plans in accessible projects"
ON public.floor_map_plans
FOR SELECT
USING (
  project_id IN (
    SELECT id FROM projects
    WHERE owner_id = get_user_profile_id()
    OR user_has_project_access(id)
  )
);

CREATE POLICY "Users can manage plans in accessible projects"
ON public.floor_map_plans
FOR ALL
USING (
  project_id IN (
    SELECT id FROM projects
    WHERE owner_id = get_user_profile_id()
    OR user_can_manage_project(id)
  )
);

-- Add trigger for updated_at
CREATE TRIGGER update_floor_map_plans_updated_at
BEFORE UPDATE ON public.floor_map_plans
FOR EACH ROW
EXECUTE FUNCTION public.update_updated_at_column();

-- Add plan_id to floor_map_shapes to associate shapes with specific plans
ALTER TABLE public.floor_map_shapes
ADD COLUMN plan_id UUID REFERENCES public.floor_map_plans(id) ON DELETE CASCADE;

-- Create index for better query performance
CREATE INDEX idx_floor_map_plans_project_id ON public.floor_map_plans(project_id);
CREATE INDEX idx_floor_map_shapes_plan_id ON public.floor_map_shapes(plan_id);