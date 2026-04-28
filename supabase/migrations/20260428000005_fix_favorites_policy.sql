-- ============================================================
-- FIX: Favorites policy using correct column (customer_phone, not user_id)
-- ============================================================

-- Check if store_id column exists and add it if needed
DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name='favorites' AND column_name='store_id'
  ) THEN
    ALTER TABLE public.favorites ADD COLUMN store_id UUID REFERENCES public.stores(id) ON DELETE CASCADE;
  END IF;
END $$;

CREATE INDEX IF NOT EXISTS idx_favorites_store_id ON public.favorites(store_id);

-- Drop all existing favorites policies
DROP POLICY IF EXISTS "favorites_read" ON public.favorites;
DROP POLICY IF EXISTS "favorites_insert" ON public.favorites;
DROP POLICY IF EXISTS "favorites_delete" ON public.favorites;
DROP POLICY IF EXISTS "favorites_owner_read" ON public.favorites;
DROP POLICY IF EXISTS "favorites_owner_insert" ON public.favorites;
DROP POLICY IF EXISTS "favorites_owner_delete" ON public.favorites;
DROP POLICY IF EXISTS "Anyone can read favorites" ON public.favorites;
DROP POLICY IF EXISTS "Anyone can insert favorites" ON public.favorites;
DROP POLICY IF EXISTS "Anyone can delete favorites" ON public.favorites;

-- Create simplified policies for favorites
-- Favorites are identified by customer_phone, not user_id

-- Allow anyone to read favorites (public access by phone)
CREATE POLICY "favorites_public_read" ON public.favorites
  FOR SELECT USING (true);

-- Allow anyone to add favorites (will be filtered by phone in app)
CREATE POLICY "favorites_public_insert" ON public.favorites
  FOR INSERT WITH CHECK (true);

-- Allow anyone to delete favorites (filtered by phone in WHERE clause)
CREATE POLICY "favorites_public_delete" ON public.favorites
  FOR DELETE USING (true);

-- Add store_id management trigger if not exists
CREATE OR REPLACE FUNCTION fill_favorites_store_id()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  IF NEW.store_id IS NULL THEN
    SELECT store_id INTO NEW.store_id FROM public.products WHERE id = NEW.product_id;
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_favorites_store_id ON public.favorites;
CREATE TRIGGER trg_favorites_store_id
  BEFORE INSERT ON public.favorites
  FOR EACH ROW EXECUTE FUNCTION fill_favorites_store_id();

-- ============================================================
-- VERIFY
-- ============================================================
/*
-- Check favorites columns
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'favorites';

-- Check favorites policies
SELECT * FROM pg_policies WHERE tablename = 'favorites';

-- Test favorites access
SELECT COUNT(*) FROM public.favorites;
*/
