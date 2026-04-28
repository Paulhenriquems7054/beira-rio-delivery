-- ============================================================
-- FIX: Add missing RLS policies for tables without SELECT policy
-- ============================================================

-- 1. DIRECT_DELIVERIES - Add SELECT policy for owner and public tracking
DROP POLICY IF EXISTS "direct_deliveries_public_read" ON public.direct_deliveries;
DROP POLICY IF EXISTS "direct_deliveries_owner_read" ON public.direct_deliveries;
DROP POLICY IF EXISTS "direct_deliveries_owner_manage" ON public.direct_deliveries;

CREATE POLICY "direct_deliveries_public_read" ON public.direct_deliveries
  FOR SELECT USING (true);

CREATE POLICY "direct_deliveries_owner_manage" ON public.direct_deliveries
  FOR ALL USING (
    auth.uid() IN (SELECT user_id FROM public.stores WHERE id = store_id)
  ) WITH CHECK (
    auth.uid() IN (SELECT user_id FROM public.stores WHERE id = store_id)
  );

-- 2. RATE_LIMITS - Allow read for debugging/monitoring (restrict as needed)
DROP POLICY IF EXISTS "rate_limits_public" ON public.rate_limits;

CREATE POLICY "rate_limits_public" ON public.rate_limits
  FOR ALL USING (true) WITH CHECK (true);

-- 3. SUBSCRIPTION_EVENTS - Allow read for store owners and superadmin
DROP POLICY IF EXISTS "subscription_events_owner_read" ON public.subscription_events;
DROP POLICY IF EXISTS "subscription_events_insert" ON public.subscription_events;

CREATE POLICY "subscription_events_owner_read" ON public.subscription_events
  FOR SELECT USING (
    auth.uid() IN (SELECT user_id FROM public.stores WHERE id = store_id)
    OR auth.uid() IS NULL  -- Allow anon for system operations
  );

CREATE POLICY "subscription_events_insert" ON public.subscription_events
  FOR INSERT WITH CHECK (true);

-- ============================================================
-- FIX: Orders policy for anonymous access (customer tracking)
-- ============================================================

-- Update orders policy to allow anon read with phone verification context
DROP POLICY IF EXISTS "orders_owner_read" ON public.orders;

CREATE POLICY "orders_owner_read" ON public.orders
  FOR SELECT USING (
    -- Store owner can read their orders
    auth.uid() IN (SELECT user_id FROM public.stores WHERE id = store_id)
    -- Allow public read for order tracking by phone (will be filtered in app)
    OR auth.uid() IS NULL
  );

-- ============================================================
-- FIX: Order items - Allow public read for order tracking
-- ============================================================

DROP POLICY IF EXISTS "order_items_owner_read" ON public.order_items;

CREATE POLICY "order_items_public_read" ON public.order_items
  FOR SELECT USING (true);

-- ============================================================
-- FIX: Favorites - Uses customer_phone (not user_id)
-- ============================================================

DROP POLICY IF EXISTS "favorites_read" ON public.favorites;
DROP POLICY IF EXISTS "favorites_insert" ON public.favorites;
DROP POLICY IF EXISTS "favorites_delete" ON public.favorites;
DROP POLICY IF EXISTS "favorites_owner_read" ON public.favorites;
DROP POLICY IF EXISTS "favorites_owner_insert" ON public.favorites;
DROP POLICY IF EXISTS "favorites_owner_delete" ON public.favorites;

-- Favorites are public - filtering by customer_phone happens in application layer
CREATE POLICY "favorites_public_read" ON public.favorites
  FOR SELECT USING (true);

CREATE POLICY "favorites_public_insert" ON public.favorites
  FOR INSERT WITH CHECK (true);

CREATE POLICY "favorites_public_delete" ON public.favorites
  FOR DELETE USING (true);

-- ============================================================
-- VERIFY: Check all tables have proper policies
-- ============================================================

-- This query will show current status after fixes
-- Run this separately to verify: 
/*
SELECT 
  c.relname as table_name,
  c.relrowsecurity as rls_enabled,
  COUNT(p.policyname) as policy_count,
  STRING_AGG(p.policyname || '(' || p.cmd || ')', ', ') as policies
FROM pg_class c
LEFT JOIN pg_policies p ON p.tablename = c.relname
JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE n.nspname = 'public' 
  AND c.relkind = 'r'
GROUP BY c.relname, c.relrowsecurity
ORDER BY c.relname;
*/
