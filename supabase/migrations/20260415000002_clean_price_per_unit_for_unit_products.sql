-- Limpa price_per_unit legado de produtos vendidos por unidade (UN)
-- Evita que valores antigos (ex: 0,50) interfiram no preço correto do cadastro

UPDATE public.products
SET
  price_per_unit = NULL,
  average_weight = NULL,
  price_per_kg = NULL
WHERE LOWER(COALESCE(unit, '')) IN ('un', 'und', 'unidade');
