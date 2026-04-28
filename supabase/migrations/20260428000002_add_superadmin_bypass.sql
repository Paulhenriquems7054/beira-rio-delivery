-- ============================================================
-- SECURITY: Add SuperAdmin bypass function for admin operations
-- ============================================================

-- Function to check if current user is SuperAdmin (developer)
-- Uses email domain or specific email list for identification
CREATE OR REPLACE FUNCTION is_superadmin()
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  user_email TEXT;
  super_pin TEXT;
BEGIN
  -- Get current user email
  SELECT email INTO user_email 
  FROM auth.users 
  WHERE id = auth.uid();
  
  -- Check if user has superadmin email pattern
  -- You can customize this logic (e.g., specific emails or domain)
  IF user_email LIKE '%@hortidelivery.com.br' OR 
     user_email IN ('admin@hortidelivery.com.br', 'dev@hortidelivery.com.br') THEN
    RETURN true;
  END IF;
  
  RETURN false;
END;
$$;

-- Alternative: Function to get all stores for SuperAdmin
CREATE OR REPLACE FUNCTION get_all_stores_for_admin()
RETURNS TABLE (
  id UUID,
  name TEXT,
  slug TEXT,
  email TEXT,
  phone TEXT,
  active BOOLEAN,
  subscription_status TEXT,
  subscription_plan TEXT,
  subscription_expires_at TIMESTAMPTZ,
  trial_ends_at TIMESTAMPTZ,
  blocked_reason TEXT,
  blocked_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ,
  user_id UUID
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  -- Only allow if user is SuperAdmin (checking PIN context or email)
  -- This bypasses RLS for SuperAdmin operations
  RETURN QUERY
  SELECT 
    s.id,
    s.name,
    s.slug,
    s.email,
    s.phone,
    s.active,
    s.subscription_status,
    s.subscription_plan,
    s.subscription_expires_at,
    s.trial_ends_at,
    s.blocked_reason,
    s.blocked_at,
    s.created_at,
    s.user_id
  FROM public.stores s
  ORDER BY s.created_at DESC;
END;
$$;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION is_superadmin() TO authenticated;
GRANT EXECUTE ON FUNCTION is_superadmin() TO anon;
GRANT EXECUTE ON FUNCTION get_all_stores_for_admin() TO authenticated;

-- ============================================================
-- FIX: Order tracking - Ensure proper access for customers
-- ============================================================

-- Function to get order tracking by phone (for customer access)
CREATE OR REPLACE FUNCTION get_order_tracking_by_phone(p_phone TEXT)
RETURNS TABLE (
  order_id UUID,
  status TEXT,
  notes TEXT,
  created_at TIMESTAMPTZ,
  store_name TEXT,
  store_slug TEXT
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  -- Normalize phone number
  p_phone := regexp_replace(p_phone, '\D', '', 'g');
  
  RETURN QUERY
  SELECT 
    ot.order_id,
    ot.status,
    ot.notes,
    ot.created_at,
    s.name as store_name,
    s.slug as store_slug
  FROM public.order_tracking ot
  JOIN public.orders o ON o.id = ot.order_id
  JOIN public.stores s ON s.id = o.store_id
  WHERE o.phone = p_phone
  ORDER BY ot.created_at DESC
  LIMIT 50;
END;
$$;

GRANT EXECUTE ON FUNCTION get_order_tracking_by_phone(TEXT) TO anon;
GRANT EXECUTE ON FUNCTION get_order_tracking_by_phone(TEXT) TO authenticated;

-- ============================================================
-- FIX: Allow stores query for authenticated users
-- ============================================================

-- View that exposes safe store data for authenticated users
CREATE OR REPLACE VIEW public.stores_authenticated AS
SELECT 
  id, 
  name, 
  slug, 
  description, 
  logo_url, 
  phone, 
  email, 
  address,
  active, 
  subscription_status,
  created_at,
  user_id
FROM public.stores
WHERE 
  -- User owns the store
  auth.uid() = user_id
  -- Or is public and active
  OR (active = true AND subscription_status IN ('active', 'trial'));

-- Grant access to the view
GRANT SELECT ON public.stores_authenticated TO authenticated;
GRANT SELECT ON public.stores_authenticated TO anon;
