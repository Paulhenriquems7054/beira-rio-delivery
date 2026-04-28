-- ============================================================
-- FINAL FIX: Comprehensive RLS policies with column checks
-- This migration safely adds policies even if columns are missing
-- ============================================================

-- Helper function to check if column exists
CREATE OR REPLACE FUNCTION column_exists(tbl TEXT, col TEXT)
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = tbl AND column_name = col
  );
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- 1. STORES
-- ============================================
DROP POLICY IF EXISTS "stores_public_read" ON public.stores;
DROP POLICY IF EXISTS "stores_auth_insert" ON public.stores;
DROP POLICY IF EXISTS "stores_owner_update" ON public.stores;
DROP POLICY IF EXISTS "stores_owner_delete" ON public.stores;

CREATE POLICY "stores_public_read" ON public.stores FOR SELECT USING (true);
CREATE POLICY "stores_auth_insert" ON public.stores FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);

-- Only add owner policies if user_id column exists
DO $$ BEGIN
  IF column_exists('stores', 'user_id') THEN
    CREATE POLICY "stores_owner_update" ON public.stores
      FOR UPDATE USING (auth.uid() = user_id);
    CREATE POLICY "stores_owner_delete" ON public.stores
      FOR DELETE USING (auth.uid() = user_id);
  END IF;
END $$;

-- ============================================
-- 2. PRODUCTS
-- ============================================
DROP POLICY IF EXISTS "products_public_read" ON public.products;
DROP POLICY IF EXISTS "products_owner_all" ON public.products;

CREATE POLICY "products_public_read" ON public.products FOR SELECT USING (active = true);

DO $$ BEGIN
  IF column_exists('products', 'store_id') THEN
    CREATE POLICY "products_owner_all" ON public.products
      FOR ALL USING (auth.uid() IN (SELECT user_id FROM public.stores WHERE id = store_id))
      WITH CHECK (auth.uid() IN (SELECT user_id FROM public.stores WHERE id = store_id));
  END IF;
END $$;

-- ============================================
-- 3. CATEGORIES
-- ============================================
DROP POLICY IF EXISTS "categories_public_read" ON public.categories;
DROP POLICY IF EXISTS "categories_owner_manage" ON public.categories;

CREATE POLICY "categories_public_read" ON public.categories FOR SELECT USING (true);

DO $$ BEGIN
  IF column_exists('categories', 'store_id') THEN
    CREATE POLICY "categories_owner_manage" ON public.categories
      FOR ALL USING (auth.uid() IN (SELECT user_id FROM public.stores WHERE id = store_id))
      WITH CHECK (auth.uid() IN (SELECT user_id FROM public.stores WHERE id = store_id));
  END IF;
END $$;

-- ============================================
-- 4. BASKETS
-- ============================================
DROP POLICY IF EXISTS "baskets_public_read" ON public.baskets;
DROP POLICY IF EXISTS "baskets_owner_manage" ON public.baskets;

CREATE POLICY "baskets_public_read" ON public.baskets FOR SELECT USING (active = true);

DO $$ BEGIN
  IF column_exists('baskets', 'store_id') THEN
    CREATE POLICY "baskets_owner_manage" ON public.baskets
      FOR ALL USING (auth.uid() IN (SELECT user_id FROM public.stores WHERE id = store_id))
      WITH CHECK (auth.uid() IN (SELECT user_id FROM public.stores WHERE id = store_id));
  END IF;
END $$;

-- ============================================
-- 5. BASKET_ITEMS
-- ============================================
DROP POLICY IF EXISTS "basket_items_public_read" ON public.basket_items;
DROP POLICY IF EXISTS "basket_items_owner_manage" ON public.basket_items;

CREATE POLICY "basket_items_public_read" ON public.basket_items FOR SELECT USING (true);

DO $$ BEGIN
  IF column_exists('basket_items', 'store_id') OR column_exists('basket_items', 'basket_id') THEN
    CREATE POLICY "basket_items_owner_manage" ON public.basket_items
      FOR ALL USING (
        auth.uid() IN (
          SELECT s.user_id FROM public.stores s
          JOIN public.baskets b ON b.store_id = s.id
          WHERE b.id = basket_id
        )
      )
      WITH CHECK (
        auth.uid() IN (
          SELECT s.user_id FROM public.stores s
          JOIN public.baskets b ON b.store_id = s.id
          WHERE b.id = basket_id
        )
      );
  END IF;
END $$;

-- ============================================
-- 6. ORDERS - Critical for customer access
-- ============================================
DROP POLICY IF EXISTS "orders_public_read" ON public.orders;
DROP POLICY IF EXISTS "orders_public_insert" ON public.orders;
DROP POLICY IF EXISTS "orders_owner_update" ON public.orders;

-- Always allow public read for order tracking
CREATE POLICY "orders_public_read" ON public.orders FOR SELECT USING (true);

-- Always allow public insert for checkout
CREATE POLICY "orders_public_insert" ON public.orders FOR INSERT WITH CHECK (true);

DO $$ BEGIN
  IF column_exists('orders', 'store_id') THEN
    CREATE POLICY "orders_owner_update" ON public.orders
      FOR UPDATE USING (auth.uid() IN (SELECT user_id FROM public.stores WHERE id = store_id));
  END IF;
END $$;

-- ============================================
-- 7. ORDER_ITEMS
-- ============================================
DROP POLICY IF EXISTS "order_items_public_read" ON public.order_items;
DROP POLICY IF EXISTS "order_items_public_insert" ON public.order_items;

CREATE POLICY "order_items_public_read" ON public.order_items FOR SELECT USING (true);
CREATE POLICY "order_items_public_insert" ON public.order_items FOR INSERT WITH CHECK (true);

-- ============================================
-- 8. ORDER_TRACKING
-- ============================================
DROP POLICY IF EXISTS "order_tracking_public_read" ON public.order_tracking;
DROP POLICY IF EXISTS "order_tracking_insert" ON public.order_tracking;

CREATE POLICY "order_tracking_public_read" ON public.order_tracking FOR SELECT USING (true);
CREATE POLICY "order_tracking_insert" ON public.order_tracking FOR INSERT WITH CHECK (true);

-- ============================================
-- 9. DELIVERY_ZONES
-- ============================================
DROP POLICY IF EXISTS "zones_public_read" ON public.delivery_zones;
DROP POLICY IF EXISTS "zones_owner_manage" ON public.delivery_zones;

CREATE POLICY "zones_public_read" ON public.delivery_zones FOR SELECT USING (active = true);

DO $$ BEGIN
  IF column_exists('delivery_zones', 'store_id') THEN
    CREATE POLICY "zones_owner_manage" ON public.delivery_zones
      FOR ALL USING (auth.uid() IN (SELECT user_id FROM public.stores WHERE id = store_id))
      WITH CHECK (auth.uid() IN (SELECT user_id FROM public.stores WHERE id = store_id));
  END IF;
END $$;

-- ============================================
-- 10. COUPONS
-- ============================================
DROP POLICY IF EXISTS "coupons_public_read" ON public.coupons;
DROP POLICY IF EXISTS "coupons_owner_manage" ON public.coupons;

CREATE POLICY "coupons_public_read" ON public.coupons FOR SELECT USING (active = true);

DO $$ BEGIN
  IF column_exists('coupons', 'store_id') THEN
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

-- ============================================
-- 11. FAVORITES - Uses customer_phone
-- ============================================
DROP POLICY IF EXISTS "favorites_public_read" ON public.favorites;
DROP POLICY IF EXISTS "favorites_public_insert" ON public.favorites;
DROP POLICY IF EXISTS "favorites_public_delete" ON public.favorites;

-- Add store_id if not exists
DO $$ BEGIN
  IF NOT column_exists('favorites', 'store_id') THEN
    ALTER TABLE public.favorites ADD COLUMN store_id UUID REFERENCES public.stores(id) ON DELETE CASCADE;
    CREATE INDEX IF NOT EXISTS idx_favorites_store_id ON public.favorites(store_id);
  END IF;
END $$;

-- Simple public policies (filtered by phone in app)
CREATE POLICY "favorites_public_read" ON public.favorites FOR SELECT USING (true);
CREATE POLICY "favorites_public_insert" ON public.favorites FOR INSERT WITH CHECK (true);
CREATE POLICY "favorites_public_delete" ON public.favorites FOR DELETE USING (true);

-- Trigger to auto-fill store_id
CREATE OR REPLACE FUNCTION fill_favorites_store_id()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.store_id IS NULL AND column_exists('products', 'store_id') THEN
    SELECT store_id INTO NEW.store_id FROM public.products WHERE id = NEW.product_id;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_favorites_store_id ON public.favorites;
CREATE TRIGGER trg_favorites_store_id
  BEFORE INSERT ON public.favorites
  FOR EACH ROW EXECUTE FUNCTION fill_favorites_store_id();

-- ============================================
-- 12. DIRECT_DELIVERIES
-- ============================================
DROP POLICY IF EXISTS "direct_deliveries_public_read" ON public.direct_deliveries;
DROP POLICY IF EXISTS "direct_deliveries_owner_manage" ON public.direct_deliveries;

CREATE POLICY "direct_deliveries_public_read" ON public.direct_deliveries FOR SELECT USING (true);

DO $$ BEGIN
  IF column_exists('direct_deliveries', 'store_id') THEN
    CREATE POLICY "direct_deliveries_owner_manage" ON public.direct_deliveries
      FOR ALL USING (auth.uid() IN (SELECT user_id FROM public.stores WHERE id = store_id))
      WITH CHECK (auth.uid() IN (SELECT user_id FROM public.stores WHERE id = store_id));
  END IF;
END $$;

-- ============================================
-- 13. AUDIT_LOGS
-- ============================================
DROP POLICY IF EXISTS "audit_logs_owner_read" ON public.audit_logs;

DO $$ BEGIN
  IF column_exists('audit_logs', 'store_id') THEN
    CREATE POLICY "audit_logs_owner_read" ON public.audit_logs
      FOR SELECT USING (
        auth.uid() IN (SELECT user_id FROM public.stores WHERE id = store_id)
        OR auth.uid()::text = COALESCE(user_id::text, auth.uid()::text)
      );
  ELSE
    CREATE POLICY "audit_logs_owner_read" ON public.audit_logs
      FOR SELECT USING (true);
  END IF;
END $$;

-- ============================================
-- 14. WEIGHING_HISTORY
-- ============================================
DROP POLICY IF EXISTS "weighing_history_owner_read" ON public.weighing_history;
DROP POLICY IF EXISTS "weighing_history_owner_insert" ON public.weighing_history;

DO $$ BEGIN
  IF column_exists('weighing_history', 'store_id') THEN
    CREATE POLICY "weighing_history_owner_read" ON public.weighing_history
      FOR SELECT USING (auth.uid() IN (SELECT user_id FROM public.stores WHERE id = store_id));
    CREATE POLICY "weighing_history_owner_insert" ON public.weighing_history
      FOR INSERT WITH CHECK (auth.uid() IN (SELECT user_id FROM public.stores WHERE id = store_id));
  END IF;
END $$;

-- ============================================
-- 15. SUBSCRIPTION_EVENTS
-- ============================================
DROP POLICY IF EXISTS "subscription_events_read" ON public.subscription_events;
DROP POLICY IF EXISTS "subscription_events_insert" ON public.subscription_events;

CREATE POLICY "subscription_events_read" ON public.subscription_events FOR SELECT USING (true);
CREATE POLICY "subscription_events_insert" ON public.subscription_events FOR INSERT WITH CHECK (true);

-- ============================================
-- 16. RATE_LIMITS
-- ============================================
DROP POLICY IF EXISTS "rate_limits_public" ON public.rate_limits;
CREATE POLICY "rate_limits_public" ON public.rate_limits FOR ALL USING (true) WITH CHECK (true);

-- ============================================
-- CLEANUP
-- ============================================
DROP FUNCTION IF EXISTS column_exists(TEXT, TEXT);

-- ============================================
-- VERIFICATION (run manually to check)
-- ============================================
/*
-- Check policy counts per table
SELECT 
  c.relname as table,
  c.relrowsecurity as rls,
  COUNT(p.policyname) as policies
FROM pg_class c
LEFT JOIN pg_policies p ON p.tablename = c.relname
JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE n.nspname = 'public' AND c.relkind = 'r'
GROUP BY c.relname, c.relrowsecurity
ORDER BY c.relname;

-- Test data access
SELECT 'stores', COUNT(*) FROM public.stores UNION ALL
SELECT 'orders', COUNT(*) FROM public.orders UNION ALL
SELECT 'products', COUNT(*) FROM public.products UNION ALL
SELECT 'favorites', COUNT(*) FROM public.favorites;
*/
