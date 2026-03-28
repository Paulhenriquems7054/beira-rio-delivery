-- Aplica o catálogo padrão a todas as lojas que ainda não têm produtos

DO $$
DECLARE
  store RECORD;
  basket_id UUID;
BEGIN
  FOR store IN SELECT id, name FROM public.stores LOOP
    -- Verifica se a loja já tem produtos
    IF NOT EXISTS (SELECT 1 FROM public.products WHERE store_id = store.id) THEN
      RAISE NOTICE 'Aplicando catálogo para loja: %', store.name;

      -- Garante que existe uma cesta ativa
      SELECT id INTO basket_id FROM public.baskets WHERE store_id = store.id AND active = true LIMIT 1;

      IF basket_id IS NULL THEN
        INSERT INTO public.baskets (name, price, active, store_id)
        VALUES ('Catálogo da Semana', 0, true, store.id)
        RETURNING id INTO basket_id;
      END IF;

      -- Copia o catálogo padrão
      PERFORM copy_default_catalog(store.id, basket_id);
    ELSE
      RAISE NOTICE 'Loja % já tem produtos, pulando.', store.name;
    END IF;
  END LOOP;
END $$;

-- Resultado
SELECT s.name as loja, COUNT(p.id) as produtos
FROM public.stores s
LEFT JOIN public.products p ON p.store_id = s.id
GROUP BY s.name
ORDER BY s.name;
