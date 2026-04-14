-- Garante política de DELETE para produtos
DROP POLICY IF EXISTS "products_owner_delete" ON public.products;

CREATE POLICY "products_owner_delete" ON public.products
  FOR DELETE USING (
    auth.uid() IS NOT NULL
    AND (
      store_id IS NULL
      OR auth.uid() IN (SELECT user_id FROM public.stores WHERE id = store_id)
    )
  );
