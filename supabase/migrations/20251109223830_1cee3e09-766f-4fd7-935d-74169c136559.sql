-- Add phone_number column to project_invitations table
ALTER TABLE public.project_invitations 
ADD COLUMN invited_phone text,
ADD COLUMN delivery_method text DEFAULT 'email' CHECK (delivery_method IN ('email', 'sms'));

-- Update constraint to allow either email or phone
ALTER TABLE public.project_invitations 
DROP CONSTRAINT IF EXISTS project_invitations_invited_email_check;

-- Add check constraint to ensure at least one contact method is provided
ALTER TABLE public.project_invitations 
ADD CONSTRAINT check_contact_method CHECK (
  (invited_email IS NOT NULL AND invited_email != '') OR 
  (invited_phone IS NOT NULL AND invited_phone != '')
);

-- Update RLS policy for users viewing their own invitations to include phone
DROP POLICY IF EXISTS "Users can view their own invitations" ON public.project_invitations;
CREATE POLICY "Users can view their own invitations"
ON public.project_invitations
FOR SELECT
TO authenticated
USING (
  invited_email = (SELECT email FROM public.profiles WHERE user_id = auth.uid())
  OR invited_phone = (SELECT phone FROM public.profiles WHERE user_id = auth.uid())
);

-- Update RLS policy for users responding to invitations to include phone
DROP POLICY IF EXISTS "Users can respond to their invitations" ON public.project_invitations;
CREATE POLICY "Users can respond to their invitations"
ON public.project_invitations
FOR UPDATE
TO authenticated
USING (
  invited_email = (SELECT email FROM public.profiles WHERE user_id = auth.uid())
  OR invited_phone = (SELECT phone FROM public.profiles WHERE user_id = auth.uid())
)
WITH CHECK (
  invited_email = (SELECT email FROM public.profiles WHERE user_id = auth.uid())
  OR invited_phone = (SELECT phone FROM public.profiles WHERE user_id = auth.uid())
);