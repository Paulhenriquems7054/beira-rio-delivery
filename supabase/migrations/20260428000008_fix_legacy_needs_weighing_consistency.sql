-- Fix legacy order_items where fixed unit products were incorrectly marked as needs_weighing

UPDATE public.order_items oi
SET needs_weighing = false
FROM public.products p
WHERE p.id = oi.product_id
  AND oi.sold_by = 'unit'
  AND oi.needs_weighing = true
  AND (
    p.sell_by = 'unit'
    OR LOWER(COALESCE(p.unit, '')) IN ('un', 'und', 'unidade')
  );
