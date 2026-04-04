-- Add support for dual selling (both weight and unit)
-- Permite que produtos sejam vendidos tanto por peso quanto por unidade

-- 1. Atualizar constraint para aceitar 'both'
ALTER TABLE public.products DROP CONSTRAINT IF EXISTS products_sell_by_check;
ALTER TABLE public.products ADD CONSTRAINT products_sell_by_check 
  CHECK (sell_by IN ('unit', 'weight', 'both'));

-- 2. Adicionar coluna para preço por unidade (quando sell_by = 'both')
ALTER TABLE public.products ADD COLUMN IF NOT EXISTS price_per_unit NUMERIC;

-- 3. Comentários explicativos
COMMENT ON COLUMN public.products.sell_by IS 'Modo de venda: unit (apenas unidade), weight (apenas peso), both (cliente escolhe)';
COMMENT ON COLUMN public.products.price IS 'Preço base (usado quando sell_by = unit)';
COMMENT ON COLUMN public.products.price_per_kg IS 'Preço por kg (usado quando sell_by = weight ou both)';
COMMENT ON COLUMN public.products.price_per_unit IS 'Preço por unidade (usado quando sell_by = both)';

-- 4. Configurar TODOS os produtos para venda dual (both)
-- Isso permite que o cliente escolha entre peso ou unidade para qualquer produto

-- Primeiro, calcular price_per_unit baseado no price_per_kg existente
-- Fórmula: price_per_unit = (peso_médio_estimado) × price_per_kg × margem
-- Usando peso médio de 150g (0.15kg) e margem de 1.2 (20%)

UPDATE public.products SET
  sell_by = 'both',
  price_per_unit = CASE 
    WHEN price_per_kg IS NOT NULL AND price_per_kg > 0 
    THEN ROUND((0.15 * price_per_kg * 1.2)::numeric, 2)
    ELSE ROUND((price * 1.2)::numeric, 2)
  END,
  price_per_kg = CASE 
    WHEN price_per_kg IS NULL OR price_per_kg = 0 
    THEN price
    ELSE price_per_kg
  END,
  min_weight = COALESCE(min_weight, 0.25),
  step_weight = COALESCE(step_weight, 0.25)
WHERE sell_by IS NOT NULL;

-- Garantir que produtos sem sell_by também sejam configurados
UPDATE public.products SET
  sell_by = 'both',
  price_per_kg = price,
  price_per_unit = ROUND((0.15 * price * 1.2)::numeric, 2),
  min_weight = 0.25,
  step_weight = 0.25
WHERE sell_by IS NULL;

-- 5. Atualizar order_items para suportar modo de venda
ALTER TABLE public.order_items ADD COLUMN IF NOT EXISTS sold_by TEXT DEFAULT 'unit';
COMMENT ON COLUMN public.order_items.sold_by IS 'Como o item foi vendido: unit ou weight';
