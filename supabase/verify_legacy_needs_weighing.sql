-- Should return 0 after migration 20260428000008
SELECT COUNT(*) AS inconsistent_items
FROM public.order_items oi
JOIN public.products p ON p.id = oi.product_id
WHERE oi.sold_by = 'unit'
  AND oi.needs_weighing = true
  AND (
    p.sell_by = 'unit'
    OR LOWER(COALESCE(p.unit, '')) IN ('un', 'und', 'unidade')
  );
