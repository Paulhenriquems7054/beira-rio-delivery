-- Add delivery_pin to stores table
ALTER TABLE public.stores ADD COLUMN IF NOT EXISTS delivery_pin TEXT DEFAULT '1234';
