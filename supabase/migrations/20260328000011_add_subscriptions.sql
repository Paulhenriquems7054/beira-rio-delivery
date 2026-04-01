-- Add subscription control to stores
ALTER TABLE public.stores ADD COLUMN IF NOT EXISTS subscription_status TEXT DEFAULT 'active'
  CHECK (subscription_status IN ('active', 'blocked', 'trial', 'cancelled'));
ALTER TABLE public.stores ADD COLUMN IF NOT EXISTS subscription_plan TEXT DEFAULT 'basic';
ALTER TABLE public.stores ADD COLUMN IF NOT EXISTS subscription_expires_at TIMESTAMP WITH TIME ZONE;
ALTER TABLE public.stores ADD COLUMN IF NOT EXISTS blocked_reason TEXT;
ALTER TABLE public.stores ADD COLUMN IF NOT EXISTS blocked_at TIMESTAMP WITH TIME ZONE;
ALTER TABLE public.stores ADD COLUMN IF NOT EXISTS trial_ends_at TIMESTAMP WITH TIME ZONE DEFAULT (now() + INTERVAL '14 days');

-- Subscription events log
CREATE TABLE IF NOT EXISTS public.subscription_events (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  store_id UUID NOT NULL REFERENCES public.stores(id) ON DELETE CASCADE,
  event_type TEXT NOT NULL CHECK (event_type IN ('activated','blocked','unblocked','plan_changed','payment_received','trial_started','cancelled')),
  notes TEXT,
  created_by TEXT,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

ALTER TABLE public.subscription_events ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Public all subscription_events" ON public.subscription_events;
CREATE POLICY "Public all subscription_events" ON public.subscription_events FOR ALL USING (true) WITH CHECK (true);

CREATE INDEX IF NOT EXISTS idx_sub_events_store ON public.subscription_events(store_id);

-- Set all existing stores as active
UPDATE public.stores SET subscription_status = 'active' WHERE subscription_status IS NULL;
