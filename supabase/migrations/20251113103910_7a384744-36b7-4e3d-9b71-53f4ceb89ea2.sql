-- Add 'material_requester' role to project_shares
-- This role allows users to view space plans and manage purchase requests

-- First, let's check if we need to update any constraints or if we can add the role directly
-- The role column in project_shares appears to use text type, so we can add the new role

-- Update RLS policies for floor_map_plans to allow material_requesters to view
DROP POLICY IF EXISTS "Users can view plans in accessible projects" ON public.floor_map_plans;

CREATE POLICY "Users can view plans in accessible projects" 
ON public.floor_map_plans 
FOR SELECT 
USING (
  project_id IN (
    SELECT projects.id
    FROM projects
    WHERE (
      projects.owner_id = get_user_profile_id() 
      OR user_has_project_access(projects.id)
    )
  )
);

-- Update RLS policies for floor_map_shapes to allow material_requesters to view
DROP POLICY IF EXISTS "Users can view shapes in accessible projects" ON public.floor_map_shapes;

CREATE POLICY "Users can view shapes in accessible projects" 
ON public.floor_map_shapes 
FOR SELECT 
USING (
  project_id IN (
    SELECT projects.id
    FROM projects
    WHERE (
      projects.owner_id = get_user_profile_id() 
      OR user_has_project_access(projects.id)
    )
  )
);

-- Update purchase_requests policies to allow material_requesters to manage their own requests
DROP POLICY IF EXISTS "Users with access can create purchase requests" ON public.purchase_requests;

CREATE POLICY "Users with access can create purchase requests" 
ON public.purchase_requests 
FOR INSERT 
WITH CHECK (
  material_id IN (
    SELECT materials.id
    FROM materials
    WHERE materials.task_id IN (
      SELECT tasks.id
      FROM tasks
      WHERE tasks.project_id IN (
        SELECT projects.id
        FROM projects
        WHERE (
          projects.owner_id = get_user_profile_id()
          OR projects.id IN (
            SELECT project_shares.project_id
            FROM project_shares
            WHERE (
              project_shares.shared_with_user_id = get_user_profile_id()
              AND (
                project_shares.can_create_purchase_requests = true
                OR project_shares.role IN ('admin', 'editor', 'material_requester')
              )
            )
          )
        )
      )
    )
  )
);

-- Allow material_requesters to update their own purchase requests
DROP POLICY IF EXISTS "Users can update their own purchase requests" ON public.purchase_requests;

CREATE POLICY "Users can update their own purchase requests" 
ON public.purchase_requests 
FOR UPDATE 
USING (
  requested_by_user_id = get_user_profile_id()
  OR material_id IN (
    SELECT materials.id
    FROM materials
    WHERE materials.task_id IN (
      SELECT tasks.id
      FROM tasks
      WHERE tasks.project_id IN (
        SELECT projects.id
        FROM projects
        WHERE (
          projects.owner_id = get_user_profile_id()
          OR projects.id IN (
            SELECT project_shares.project_id
            FROM project_shares
            WHERE (
              project_shares.shared_with_user_id = get_user_profile_id()
              AND project_shares.role IN ('admin', 'editor')
            )
          )
        )
      )
    )
  )
);

COMMENT ON COLUMN public.project_shares.role IS 'Access role: viewer, editor, admin, or material_requester';