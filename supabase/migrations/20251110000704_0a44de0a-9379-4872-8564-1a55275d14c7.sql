-- Add room_id to materials table
ALTER TABLE public.materials
ADD COLUMN room_id uuid REFERENCES public.rooms(id) ON DELETE SET NULL;

-- Create index for better query performance
CREATE INDEX idx_materials_room_id ON public.materials(room_id);