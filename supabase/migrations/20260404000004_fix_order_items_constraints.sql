-- Migração para ajustar constraints e adicionar campos faltantes em order_items
-- Esta migração resolve o problema de foreign key e adiciona campos necessários para o sistema

-- 1. Remover a constraint antiga que impede deletar produtos
ALTER TABLE public.order_items 
  DROP CONSTRAINT IF EXISTS order_items_product_id_fkey;

-- 2. Adicionar campos que faltam na tabela order_items (se não existirem)
DO $$ 
BEGIN
  -- Adiciona price se não existir
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' 
    AND table_name = 'order_items' 
    AND column_name = 'price'
  ) THEN
    ALTER TABLE public.order_items ADD COLUMN price NUMERIC NOT NULL DEFAULT 0;
  END IF;

  -- Adiciona weight_kg se não existir
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' 
    AND table_name = 'order_items' 
    AND column_name = 'weight_kg'
  ) THEN
    ALTER TABLE public.order_items ADD COLUMN weight_kg NUMERIC;
  END IF;

  -- Adiciona sold_by se não existir
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' 
    AND table_name = 'order_items' 
    AND column_name = 'sold_by'
  ) THEN
    ALTER TABLE public.order_items ADD COLUMN sold_by TEXT DEFAULT 'unit';
  END IF;
END $$;

-- 3. Recriar a constraint com ON DELETE RESTRICT (não permite deletar produto se estiver em pedido)
-- Isso é mais seguro que CASCADE pois preserva o histórico de pedidos
ALTER TABLE public.order_items 
  ADD CONSTRAINT order_items_product_id_fkey 
  FOREIGN KEY (product_id) 
  REFERENCES public.products(id) 
  ON DELETE RESTRICT;

-- 4. Criar índices para melhorar performance
CREATE INDEX IF NOT EXISTS idx_order_items_order_id ON public.order_items(order_id);
CREATE INDEX IF NOT EXISTS idx_order_items_product_id ON public.order_items(product_id);

-- 5. Comentários explicativos
COMMENT ON CONSTRAINT order_items_product_id_fkey ON public.order_items IS 
  'Impede deletar produtos que estão em pedidos (preserva histórico)';

COMMENT ON COLUMN public.order_items.price IS 
  'Preço do item no momento do pedido (snapshot)';

COMMENT ON COLUMN public.order_items.weight_kg IS 
  'Peso em kg para itens vendidos por peso';

COMMENT ON COLUMN public.order_items.sold_by IS 
  'Modo de venda: unit (unidade) ou weight (peso)';
