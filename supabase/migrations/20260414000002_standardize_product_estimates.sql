-- Padroniza todos os produtos com estimativa e modo dual
ALTER TABLE public.products
  ALTER COLUMN sell_by SET DEFAULT 'both';

ALTER TABLE public.products
  ALTER COLUMN average_weight SET DEFAULT 0.3;

ALTER TABLE public.products
  ALTER COLUMN weight_variance SET DEFAULT 0.15;

-- Atualiza produtos existentes para o padrão "Estimativa"
UPDATE public.products
SET
  sell_by = 'both',
  price_per_kg = COALESCE(price_per_kg, price),
  average_weight = COALESCE(average_weight, 0.3),
  weight_variance = COALESCE(weight_variance, 0.15)
WHERE sell_by IS DISTINCT FROM 'both'
   OR price_per_kg IS NULL
   OR average_weight IS NULL
   OR weight_variance IS NULL;
