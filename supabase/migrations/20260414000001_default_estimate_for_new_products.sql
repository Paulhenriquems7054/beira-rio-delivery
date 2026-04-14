-- Padroniza estimativa para novos produtos
ALTER TABLE public.products
  ALTER COLUMN average_weight SET DEFAULT 0.3;

ALTER TABLE public.products
  ALTER COLUMN weight_variance SET DEFAULT 0.15;

-- Atualiza a função do catálogo padrão para incluir estimativa
CREATE OR REPLACE FUNCTION copy_default_catalog(p_store_id UUID, p_basket_id UUID)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  new_product_id UUID;
  dp RECORD;
BEGIN
  FOR dp IN SELECT * FROM public.default_products WHERE active = true LOOP
    -- Cria o produto para a loja com estimativa padrão
    INSERT INTO public.products (
      name,
      price,
      image_url,
      unit,
      active,
      store_id,
      average_weight,
      weight_variance
    )
    VALUES (
      dp.name,
      dp.price,
      dp.image_url,
      dp.unit,
      true,
      p_store_id,
      0.3,
      0.15
    )
    RETURNING id INTO new_product_id;

    -- Adiciona à cesta
    INSERT INTO public.basket_items (basket_id, product_id, quantity)
    VALUES (p_basket_id, new_product_id, 1);
  END LOOP;
END;
$$;
