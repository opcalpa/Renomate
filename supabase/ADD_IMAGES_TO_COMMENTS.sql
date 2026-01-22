-- Add images column to comments table
ALTER TABLE comments ADD COLUMN IF NOT EXISTS images JSONB;

-- Optional: Add index for better performance when querying images
CREATE INDEX IF NOT EXISTS idx_comments_images ON comments USING GIN (images);

-- Optional: Add constraint to ensure images is an array of objects with required fields
-- This is just for documentation, Supabase doesn't enforce JSON schema constraints
COMMENT ON COLUMN comments.images IS 'Array of image objects with id, url, and filename properties';