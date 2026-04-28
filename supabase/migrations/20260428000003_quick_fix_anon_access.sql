-- ============================================================
-- QUICK FIX: Enable anonymous access for customer-facing tables
-- Execute this if you're getting "Success. No rows returned"
-- ============================================================

-- 1. Fix ORDERS - Allow anonymous read for order tracking
DROP POLICY IF EXISTS "orders_owner_read" ON public.orders;
DROP POLICY IF EXISTS "orders_public_read" ON public.orders;
DROP POLICY IF EXISTS "orders_owner_update" ON public.orders;
DROP POLICY IF EXISTS "orders_public_insert" ON public.orders;

-- Allow anyone to read orders (for tracking purposes)
-- Data filtering happens in the application layer
CREATE POLICY "orders_public_read" ON public.orders
  FOR SELECT USING (true);

-- Allow anyone to create orders (checkout)
CREATE POLICY "orders_public_insert" ON public.orders
  FOR INSERT WITH CHECK (true);

-- Only store owners can update orders
CREATE POLICY "orders_owner_update" ON public.orders
  FOR UPDATE USING (
    auth.uid() IN (SELECT user_id FROM public.stores WHERE id = store_id)
  );

-- 2. Fix ORDER_ITEMS - Allow public read
DROP POLICY IF EXISTS "order_items_public_read" ON public.order_items;
DROP POLICY IF EXISTS "order_items_owner_read" ON public.order_items;
DROP POLICY IF EXISTS "order_items_public_insert" ON public.order_items;

CREATE POLICY "order_items_public_read" ON public.order_items
  FOR SELECT USING (true);

CREATE POLICY "order_items_public_insert" ON public.order_items
  FOR INSERT WITH CHECK (true);

-- 3. Fix ORDER_TRACKING - Allow public read
DROP POLICY IF EXISTS "order_tracking_public_read" ON public.order_tracking;
DROP POLICY IF EXISTS "order_tracking_insert" ON public.order_tracking;

CREATE POLICY "order_tracking_public_read" ON public.order_tracking
  FOR SELECT USING (true);

CREATE POLICY "order_tracking_insert" ON public.order_tracking
  FOR INSERT WITH CHECK (true);

-- 4. Fix PRODUCTS - Ensure public can read active products
DROP POLICY IF EXISTS "products_public_read" ON public.products;
DROP POLICY IF EXISTS "products_owner_all" ON public.products;

CREATE POLICY "products_public_read" ON public.products
  FOR SELECT USING (active = true);

CREATE POLICY "products_owner_all" ON public.products
  FOR ALL USING (
    auth.uid() IN (SELECT user_id FROM public.stores WHERE id = store_id)
  ) WITH CHECK (
    auth.uid() IN (SELECT user_id FROM public.stores WHERE id = store_id)
  );

-- 5. Fix BASKETS - Public read active baskets
DROP POLICY IF EXISTS "baskets_public_read" ON public.baskets;
DROP POLICY IF EXISTS "baskets_owner_manage" ON public.baskets;

CREATE POLICY "baskets_public_read" ON public.baskets
  FOR SELECT USING (active = true);

CREATE POLICY "baskets_owner_manage" ON public.baskets
  FOR ALL USING (
    auth.uid() IN (SELECT user_id FROM public.stores WHERE id = store_id)
  ) WITH CHECK (
    auth.uid() IN (SELECT user_id FROM public.stores WHERE id = store_id)
  );

-- 6. Fix BASKET_ITEMS - Public read
DROP POLICY IF EXISTS "basket_items_public_read" ON public.basket_items;
DROP POLICY IF EXISTS "basket_items_owner_manage" ON public.basket_items;

CREATE POLICY "basket_items_public_read" ON public.basket_items
  FOR SELECT USING (true);

CREATE POLICY "basket_items_owner_manage" ON public.basket_items
  FOR ALL USING (
    auth.uid() IN (
      SELECT s.user_id FROM public.stores s
      JOIN public.baskets b ON b.store_id = s.id
      WHERE b.id = basket_id
    )
  ) WITH CHECK (
    auth.uid() IN (
      SELECT s.user_id FROM public.stores s
      JOIN public.baskets b ON b.store_id = s.id
      WHERE b.id = basket_id
    )
  );

-- 7. Fix DELIVERY_ZONES - Public read active
DROP POLICY IF EXISTS "zones_public_read" ON public.delivery_zones;
DROP POLICY IF EXISTS "zones_owner_manage" ON public.delivery_zones;

CREATE POLICY "zones_public_read" ON public.delivery_zones
  FOR SELECT USING (active = true);

CREATE POLICY "zones_owner_manage" ON public.delivery_zones
  FOR ALL USING (
    auth.uid() IN (SELECT user_id FROM public.stores WHERE id = store_id)
  ) WITH CHECK (
    auth.uid() IN (SELECT user_id FROM public.stores WHERE id = store_id)
  );

-- 8. Fix COUPONS - Public read active
DROP POLICY IF EXISTS "coupons_public_read" ON public.coupons;
DROP POLICY IF EXISTS "coupons_owner_manage" ON public.coupons;

CREATE POLICY "coupons_public_read" ON public.coupons
  FOR SELECT USING (active = true);

CREATE POLICY "coupons_owner_manage" ON public.coupons
  FOR ALL USING (
    store_id IS NULL OR
    auth.uid() IN (SELECT user_id FROM public.stores WHERE id = store_id)
  ) WITH CHECK (
    store_id IS NULL OR
    auth.uid() IN (SELECT user_id FROM public.stores WHERE id = store_id)
  );

-- 9. Fix STORES - Public read (needed for store lookup by slug)
DROP POLICY IF EXISTS "stores_public_read" ON public.stores;
DROP POLICY IF EXISTS "stores_auth_insert" ON public.stores;
DROP POLICY IF EXISTS "stores_owner_update" ON public.stores;
DROP POLICY IF EXISTS "stores_owner_delete" ON public.stores;

CREATE POLICY "stores_public_read" ON public.stores
  FOR SELECT USING (true);

CREATE POLICY "stores_auth_insert" ON public.stores
  FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);

CREATE POLICY "stores_owner_update" ON public.stores
  FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "stores_owner_delete" ON public.stores
  FOR DELETE USING (auth.uid() = user_id);

-- 10. Fix DIRECT_DELIVERIES
DROP POLICY IF EXISTS "direct_deliveries_public_read" ON public.direct_deliveries;
DROP POLICY IF EXISTS "direct_deliveries_owner_manage" ON public.direct_deliveries;

CREATE POLICY "direct_deliveries_public_read" ON public.direct_deliveries
  FOR SELECT USING (true);

CREATE POLICY "direct_deliveries_owner_manage" ON public.direct_deliveries
  FOR ALL USING (
    auth.uid() IN (SELECT user_id FROM public.stores WHERE id = store_id)
  ) WITH CHECK (
    auth.uid() IN (SELECT user_id FROM public.stores WHERE id = store_id)
  );

-- 11. Fix CATEGORIES
DROP POLICY IF EXISTS "categories_public_read" ON public.categories;
DROP POLICY IF EXISTS "categories_owner_manage" ON public.categories;

CREATE POLICY "categories_public_read" ON public.categories
  FOR SELECT USING (true);

CREATE POLICY "categories_owner_manage" ON public.categories
  FOR ALL USING (
    auth.uid() IN (SELECT user_id FROM public.stores WHERE id = store_id)
  ) WITH CHECK (
    auth.uid() IN (SELECT user_id FROM public.stores WHERE id = store_id)
  );

-- 12. Fix RATE_LIMITS (internal table, allow all for now)
DROP POLICY IF EXISTS "rate_limits_public" ON public.rate_limits;

CREATE POLICY "rate_limits_public" ON public.rate_limits
  FOR ALL USING (true) WITH CHECK (true);

-- 13. Fix SUBSCRIPTION_EVENTS
DROP POLICY IF EXISTS "subscription_events_read" ON public.subscription_events;
DROP POLICY IF EXISTS "subscription_events_insert" ON public.subscription_events;

CREATE POLICY "subscription_events_read" ON public.subscription_events
  FOR SELECT USING (true);

CREATE POLICY "subscription_events_insert" ON public.subscription_events
  FOR INSERT WITH CHECK (true);

-- 14. Fix AUDIT_LOGS (keep restricted to store owners)
DROP POLICY IF EXISTS "audit_logs_owner_read" ON public.audit_logs;

CREATE POLICY "audit_logs_owner_read" ON public.audit_logs
  FOR SELECT USING (
    auth.uid() IN (SELECT user_id FROM public.stores WHERE id = store_id)
    OR auth.uid()::text = user_id::text
  );

-- 15. Fix FAVORITES (uses customer_phone, not user_id)
DROP POLICY IF EXISTS "favorites_owner_read" ON public.favorites;
DROP POLICY IF EXISTS "favorites_owner_insert" ON public.favorites;
DROP POLICY IF EXISTS "favorites_owner_delete" ON public.favorites;
DROP POLICY IF EXISTS "favorites_public_read" ON public.favorites;
DROP POLICY IF EXISTS "favorites_public_insert" ON public.favorites;
DROP POLICY IF EXISTS "favorites_public_delete" ON public.favorites;

-- Favorites are public - filtering by phone happens in the app
CREATE POLICY "favorites_public_read" ON public.favorites
  FOR SELECT USING (true);

CREATE POLICY "favorites_public_insert" ON public.favorites
  FOR INSERT WITH CHECK (true);

CREATE POLICY "favorites_public_delete" ON public.favorites
  FOR DELETE USING (true);

-- 16. Fix WEIGHING_HISTORY
DROP POLICY IF EXISTS "weighing_history_owner_read" ON public.weighing_history;
DROP POLICY IF EXISTS "weighing_history_owner_insert" ON public.weighing_history;

CREATE POLICY "weighing_history_owner_read" ON public.weighing_history
  FOR SELECT USING (
    auth.uid() IN (SELECT user_id FROM public.stores WHERE id = store_id)
  );

CREATE POLICY "weighing_history_owner_insert" ON public.weighing_history
  FOR INSERT WITH CHECK (
    auth.uid() IN (SELECT user_id FROM public.stores WHERE id = store_id)
  );

-- ============================================
-- Verification queries (run separately after)
-- ============================================
/*
-- Check all tables have policies
SELECT 
  c.relname as table_name,
  c.relrowsecurity as rls_enabled,
  COUNT(p.policyname) as policy_count
FROM pg_class c
LEFT JOIN pg_policies p ON p.tablename = c.relname
JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE n.nspname = 'public' AND c.relkind = 'r'
GROUP BY c.relname, c.relrowsecurity
ORDER BY c.relname;

-- Test access (should return data now)
SELECT COUNT(*) FROM public.orders;
SELECT COUNT(*) FROM public.products WHERE active = true;
SELECT COUNT(*) FROM public.stores;
*/
