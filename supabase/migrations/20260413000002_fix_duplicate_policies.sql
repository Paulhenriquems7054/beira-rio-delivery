-- ============================================================
-- FIX: Prevent duplicate policy errors
-- Uses DO $$ blocks to check if policies exist before creating
-- ============================================================

-- 1. STORES policies
DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE schemaname = 'public' AND tablename = 'stores' AND policyname = 'stores_public_read'
  ) THEN
    CREATE POLICY "stores_public_read" ON public.stores FOR SELECT USING (true);
  END IF;
END $$;

DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE schemaname = 'public' AND tablename = 'stores' AND policyname = 'stores_auth_insert'
  ) THEN
    CREATE POLICY "stores_auth_insert" ON public.stores FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);
  END IF;
END $$;

DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE schemaname = 'public' AND tablename = 'stores' AND policyname = 'stores_owner_update'
  ) THEN
    CREATE POLICY "stores_owner_update" ON public.stores FOR UPDATE USING (auth.uid() = user_id);
  END IF;
END $$;

DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE schemaname = 'public' AND tablename = 'stores' AND policyname = 'stores_owner_delete'
  ) THEN
    CREATE POLICY "stores_owner_delete" ON public.stores FOR DELETE USING (auth.uid() = user_id);
  END IF;
END $$;

-- 2. PRODUCTS policies
DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE schemaname = 'public' AND tablename = 'products' AND policyname = 'products_public_read'
  ) THEN
    CREATE POLICY "products_public_read" ON public.products FOR SELECT USING (active = true);
  END IF;
END $$;

DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE schemaname = 'public' AND tablename = 'products' AND policyname = 'products_owner_insert'
  ) THEN
    CREATE POLICY "products_owner_insert" ON public.products
      FOR INSERT WITH CHECK (auth.uid() IN (SELECT user_id FROM public.stores WHERE id = store_id));
  END IF;
END $$;

DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE schemaname = 'public' AND tablename = 'products' AND policyname = 'products_owner_update'
  ) THEN
    CREATE POLICY "products_owner_update" ON public.products
      FOR UPDATE USING (auth.uid() IN (SELECT user_id FROM public.stores WHERE id = store_id));
  END IF;
END $$;

DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE schemaname = 'public' AND tablename = 'products' AND policyname = 'products_owner_delete'
  ) THEN
    CREATE POLICY "products_owner_delete" ON public.products
      FOR DELETE USING (auth.uid() IN (SELECT user_id FROM public.stores WHERE id = store_id));
  END IF;
END $$;

-- 3. BASKETS policies
DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE schemaname = 'public' AND tablename = 'baskets' AND policyname = 'baskets_public_read'
  ) THEN
    CREATE POLICY "baskets_public_read" ON public.baskets FOR SELECT USING (active = true);
  END IF;
END $$;

DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE schemaname = 'public' AND tablename = 'baskets' AND policyname = 'baskets_owner_manage'
  ) THEN
    CREATE POLICY "baskets_owner_manage" ON public.baskets
      FOR ALL USING (auth.uid() IN (SELECT user_id FROM public.stores WHERE id = store_id))
      WITH CHECK (auth.uid() IN (SELECT user_id FROM public.stores WHERE id = store_id));
  END IF;
END $$;

-- 4. BASKET_ITEMS policies  
DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE schemaname = 'public' AND tablename = 'basket_items' AND policyname = 'basket_items_public_read'
  ) THEN
    CREATE POLICY "basket_items_public_read" ON public.basket_items FOR SELECT USING (true);
  END IF;
END $$;

DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE schemaname = 'public' AND tablename = 'basket_items' AND policyname = 'basket_items_owner_manage'
  ) THEN
    CREATE POLICY "basket_items_owner_manage" ON public.basket_items
      FOR ALL USING (
        store_id IS NULL OR
        auth.uid() IN (SELECT user_id FROM public.stores WHERE id = store_id)
      )
      WITH CHECK (
        store_id IS NULL OR
        auth.uid() IN (SELECT user_id FROM public.stores WHERE id = store_id)
      );
  END IF;
END $$;

-- 5. ORDERS policies
DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE schemaname = 'public' AND tablename = 'orders' AND policyname = 'orders_public_insert'
  ) THEN
    CREATE POLICY "orders_public_insert" ON public.orders FOR INSERT WITH CHECK (true);
  END IF;
END $$;

DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE schemaname = 'public' AND tablename = 'orders' AND policyname = 'orders_owner_read'
  ) THEN
    CREATE POLICY "orders_owner_read" ON public.orders
      FOR SELECT USING (
        auth.uid() IN (SELECT user_id FROM public.stores WHERE id = store_id)
        OR auth.uid() IS NULL
      );
  END IF;
END $$;

DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE schemaname = 'public' AND tablename = 'orders' AND policyname = 'orders_owner_update'
  ) THEN
    CREATE POLICY "orders_owner_update" ON public.orders
      FOR UPDATE USING (auth.uid() IN (SELECT user_id FROM public.stores WHERE id = store_id));
  END IF;
END $$;

-- 6. ORDER_ITEMS policies
DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE schemaname = 'public' AND tablename = 'order_items' AND policyname = 'order_items_public_insert'
  ) THEN
    CREATE POLICY "order_items_public_insert" ON public.order_items FOR INSERT WITH CHECK (true);
  END IF;
END $$;

DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE schemaname = 'public' AND tablename = 'order_items' AND policyname = 'order_items_owner_read'
  ) THEN
    CREATE POLICY "order_items_owner_read" ON public.order_items FOR SELECT USING (true);
  END IF;
END $$;

-- 7. DELIVERY_ZONES policies
DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE schemaname = 'public' AND tablename = 'delivery_zones' AND policyname = 'zones_public_read'
  ) THEN
    CREATE POLICY "zones_public_read" ON public.delivery_zones FOR SELECT USING (active = true);
  END IF;
END $$;

DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE schemaname = 'public' AND tablename = 'delivery_zones' AND policyname = 'zones_owner_manage'
  ) THEN
    CREATE POLICY "zones_owner_manage" ON public.delivery_zones
      FOR ALL USING (auth.uid() IN (SELECT user_id FROM public.stores WHERE id = store_id))
      WITH CHECK (auth.uid() IN (SELECT user_id FROM public.stores WHERE id = store_id));
  END IF;
END $$;

-- 8. COUPONS policies
DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE schemaname = 'public' AND tablename = 'coupons' AND policyname = 'coupons_public_read'
  ) THEN
    CREATE POLICY "coupons_public_read" ON public.coupons FOR SELECT USING (active = true);
  END IF;
END $$;

DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE schemaname = 'public' AND tablename = 'coupons' AND policyname = 'coupons_owner_manage'
  ) THEN
    CREATE POLICY "coupons_owner_manage" ON public.coupons
      FOR ALL USING (
        store_id IS NULL OR
        auth.uid() IN (SELECT user_id FROM public.stores WHERE id = store_id)
      )
      WITH CHECK (
        store_id IS NULL OR
        auth.uid() IN (SELECT user_id FROM public.stores WHERE id = store_id)
      );
  END IF;
END $$;

-- 9. ORDER_TRACKING policies
DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE schemaname = 'public' AND tablename = 'order_tracking' AND policyname = 'order_tracking_public_read'
  ) THEN
    CREATE POLICY "order_tracking_public_read" ON public.order_tracking FOR SELECT USING (true);
  END IF;
END $$;

DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE schemaname = 'public' AND tablename = 'order_tracking' AND policyname = 'order_tracking_insert'
  ) THEN
    CREATE POLICY "order_tracking_insert" ON public.order_tracking FOR INSERT WITH CHECK (true);
  END IF;
END $$;

-- 10. FAVORITES policies
DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE schemaname = 'public' AND tablename = 'favorites' AND policyname = 'favorites_read'
  ) THEN
    CREATE POLICY "favorites_read" ON public.favorites FOR SELECT USING (true);
  END IF;
END $$;

DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE schemaname = 'public' AND tablename = 'favorites' AND policyname = 'favorites_insert'
  ) THEN
    CREATE POLICY "favorites_insert" ON public.favorites FOR INSERT WITH CHECK (true);
  END IF;
END $$;

DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE schemaname = 'public' AND tablename = 'favorites' AND policyname = 'favorites_delete'
  ) THEN
    CREATE POLICY "favorites_delete" ON public.favorites FOR DELETE USING (true);
  END IF;
END $$;

-- 11. DIRECT_DELIVERIES policies
DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE schemaname = 'public' AND tablename = 'direct_deliveries' AND policyname = 'direct_deliveries_owner_manage'
  ) THEN
    CREATE POLICY "direct_deliveries_owner_manage" ON public.direct_deliveries
      FOR ALL USING (
        auth.uid() IN (SELECT user_id FROM public.stores WHERE id = store_id)
        OR auth.uid() IS NULL
      )
      WITH CHECK (
        auth.uid() IN (SELECT user_id FROM public.stores WHERE id = store_id)
        OR auth.uid() IS NULL
      );
  END IF;
END $$;

-- 12. CATEGORIES policies (if table exists)
DO $$ BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'categories') THEN
    IF NOT EXISTS (
      SELECT 1 FROM pg_policies 
      WHERE schemaname = 'public' AND tablename = 'categories' AND policyname = 'categories_public_read'
    ) THEN
      CREATE POLICY "categories_public_read" ON public.categories FOR SELECT USING (active = true);
    END IF;
    
    IF NOT EXISTS (
      SELECT 1 FROM pg_policies 
      WHERE schemaname = 'public' AND tablename = 'categories' AND policyname = 'categories_owner_manage'
    ) THEN
      CREATE POLICY "categories_owner_manage" ON public.categories
        FOR ALL USING (auth.uid() IN (SELECT user_id FROM public.stores WHERE id = store_id))
        WITH CHECK (auth.uid() IN (SELECT user_id FROM public.stores WHERE id = store_id));
    END IF;
  END IF;
END $$;
