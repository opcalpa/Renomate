-- Add payment status fields to tasks table
ALTER TABLE public.tasks 
ADD COLUMN payment_status text DEFAULT 'not_paid',
ADD COLUMN paid_amount numeric DEFAULT 0;