-- Add contractor_category and company address fields to profiles
-- for marketplace discovery and contractor identity

ALTER TABLE public.profiles
ADD COLUMN IF NOT EXISTS contractor_category TEXT,
ADD COLUMN IF NOT EXISTS company_name TEXT,
ADD COLUMN IF NOT EXISTS company_address TEXT,
ADD COLUMN IF NOT EXISTS company_city TEXT,
ADD COLUMN IF NOT EXISTS company_postal_code TEXT,
ADD COLUMN IF NOT EXISTS company_country TEXT DEFAULT 'SE';

COMMENT ON COLUMN public.profiles.contractor_category IS 'Contractor specialty (painter, electrician, etc.) — set when accepting a contractor invitation';
COMMENT ON COLUMN public.profiles.company_name IS 'Company name for contractor marketplace';
COMMENT ON COLUMN public.profiles.company_address IS 'Street address for contractor marketplace';
COMMENT ON COLUMN public.profiles.company_city IS 'City for contractor marketplace';
COMMENT ON COLUMN public.profiles.company_postal_code IS 'Postal code for contractor marketplace';
COMMENT ON COLUMN public.profiles.company_country IS 'Country ISO code for contractor marketplace';
