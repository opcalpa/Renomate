-- Enable realtime for purchase_requests table
ALTER TABLE public.purchase_requests REPLICA IDENTITY FULL;
ALTER PUBLICATION supabase_realtime ADD TABLE public.purchase_requests;