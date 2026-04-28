-- HARD LOCK: validation + tenant isolation for favorites

ALTER TABLE public.favorites
  ALTER COLUMN customer_phone SET NOT NULL,
  ALTER COLUMN product_id SET NOT NULL,
  ALTER COLUMN store_id SET NOT NULL;

-- Defensive constraint for normalized phone-like value
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'favorites_customer_phone_format_check'
  ) THEN
    ALTER TABLE public.favorites
      ADD CONSTRAINT favorites_customer_phone_format_check
      CHECK (customer_phone ~ '^\+?[1-9][0-9]{7,14}$');
  END IF;
END $$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'favorites_store_phone_product_unique'
  ) THEN
    ALTER TABLE public.favorites
      ADD CONSTRAINT favorites_store_phone_product_unique
      UNIQUE (store_id, customer_phone, product_id);
  END IF;
END $$;

CREATE INDEX IF NOT EXISTS idx_favorites_store_phone ON public.favorites (store_id, customer_phone);

ALTER TABLE public.favorites ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "favorites_public_read" ON public.favorites;
DROP POLICY IF EXISTS "favorites_public_insert" ON public.favorites;
DROP POLICY IF EXISTS "favorites_public_delete" ON public.favorites;
DROP POLICY IF EXISTS "favorites_owner_select" ON public.favorites;
DROP POLICY IF EXISTS "favorites_owner_insert" ON public.favorites;
DROP POLICY IF EXISTS "favorites_owner_delete" ON public.favorites;

CREATE POLICY "favorites_owner_select" ON public.favorites
  FOR SELECT USING (
    auth.uid() IS NOT NULL
    AND auth.uid() IN (SELECT user_id FROM public.stores WHERE id = store_id)
  );

CREATE POLICY "favorites_owner_insert" ON public.favorites
  FOR INSERT WITH CHECK (
    auth.uid() IS NOT NULL
    AND auth.uid() IN (SELECT user_id FROM public.stores WHERE id = store_id)
  );

CREATE POLICY "favorites_owner_delete" ON public.favorites
  FOR DELETE USING (
    auth.uid() IS NOT NULL
    AND auth.uid() IN (SELECT user_id FROM public.stores WHERE id = store_id)
  );
