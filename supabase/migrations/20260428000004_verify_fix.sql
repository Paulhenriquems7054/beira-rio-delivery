-- ============================================
-- VERIFY: Test if anonymous access is working
-- Run this AFTER applying the quick fix
-- ============================================

-- Test 1: Check RLS status on all tables
SELECT 
  c.relname as table_name,
  c.relrowsecurity as rls_enabled,
  COUNT(p.policyname) as policy_count,
  CASE 
    WHEN c.relrowsecurity AND COUNT(p.policyname) = 0 THEN '⚠️ NO POLICIES!'
    WHEN c.relrowsecurity AND COUNT(p.policyname) > 0 THEN '✅ OK'
    ELSE '❌ RLS disabled'
  END as status
FROM pg_class c
LEFT JOIN pg_policies p ON p.tablename = c.relname
JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE n.nspname = 'public' AND c.relkind = 'r'
GROUP BY c.relname, c.relrowsecurity
ORDER BY 
  CASE WHEN c.relrowsecurity AND COUNT(p.policyname) = 0 THEN 0 ELSE 1 END,
  c.relname;

-- Test 2: Check specific policies for key tables
SELECT 
  tablename,
  policyname,
  cmd,
  permissive
FROM pg_policies 
WHERE tablename IN ('orders', 'order_items', 'products', 'stores', 'baskets')
ORDER BY tablename, cmd;

-- Test 3: Count rows in main tables (should return numbers > 0)
SELECT 'stores' as table_name, COUNT(*) as row_count FROM public.stores
UNION ALL
SELECT 'orders', COUNT(*) FROM public.orders
UNION ALL
SELECT 'products', COUNT(*) FROM public.products
UNION ALL
SELECT 'baskets', COUNT(*) FROM public.baskets
UNION ALL
SELECT 'order_items', COUNT(*) FROM public.order_items;
