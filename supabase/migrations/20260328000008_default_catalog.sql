-- Tabela de produtos padrão (template para novas lojas)
CREATE TABLE IF NOT EXISTS public.default_products (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  name TEXT NOT NULL,
  price NUMERIC NOT NULL,
  image_url TEXT,
  unit TEXT DEFAULT 'kg',
  active BOOLEAN NOT NULL DEFAULT true
);

-- Insere o catálogo padrão
INSERT INTO public.default_products (name, price, image_url, unit) VALUES
  ('Abacaxi',        4.60,  'https://images.unsplash.com/photo-1550258987-190a2d41a8ba?w=400&q=80', 'kg'),
  ('Abacate',        4.90,  'https://images.unsplash.com/photo-1523049673857-eb18f1d7b578?w=400&q=80', 'kg'),
  ('Alface Crespa',  3.50,  'https://images.unsplash.com/photo-1622206151226-18ca2c9ab4a1?w=400&q=80', 'un'),
  ('Banana Nanica',  4.90,  'https://images.unsplash.com/photo-1571771894821-ce9b6c11b08e?w=400&q=80', 'un'),
  ('Banana Prata',   8.90,  'https://images.unsplash.com/photo-1571771894821-ce9b6c11b08e?w=400&q=80', 'un'),
  ('Batata Doce',    3.75,  'https://images.unsplash.com/photo-1518977676601-b53f82aba655?w=400&q=80', 'kg'),
  ('Batata Inglesa', 6.90,  'https://images.unsplash.com/photo-1518977676601-b53f82aba655?w=400&q=80', 'kg'),
  ('Batata Lavada',  7.50,  'https://images.unsplash.com/photo-1518977676601-b53f82aba655?w=400&q=80', 'kg'),
  ('Cebola Branca',  4.50,  'https://images.unsplash.com/photo-1508747703725-719777637510?w=400&q=80', 'kg'),
  ('Cebola Nacional',6.80,  'https://images.unsplash.com/photo-1508747703725-719777637510?w=400&q=80', 'kg'),
  ('Cebola Roxa',    5.20,  'https://images.unsplash.com/photo-1508747703725-719777637510?w=400&q=80', 'kg'),
  ('Cenoura',        5.90,  'https://images.unsplash.com/photo-1598170845058-32b9d6a5da37?w=400&q=80', 'kg'),
  ('Cheiro Verde',   2.50,  'https://images.unsplash.com/photo-1599909533731-0e90fb8e3e5e?w=400&q=80', 'un'),
  ('Couve',          1.50,  'https://images.unsplash.com/photo-1524179091875-bf99a9a6af57?w=400&q=80', 'un'),
  ('Laranja Pera',   5.50,  'https://images.unsplash.com/photo-1547514701-42782101795e?w=400&q=80', 'kg'),
  ('Maçã Gala',      11.50, 'https://images.unsplash.com/photo-1567306226416-28f0efdc88ce?w=400&q=80', 'kg'),
  ('Manga Espada',   5.60,  'https://images.unsplash.com/photo-1553279768-865429fa0078?w=400&q=80', 'kg'),
  ('Melão',          4.80,  'https://images.unsplash.com/photo-1571575173700-afb9492e6a50?w=400&q=80', 'kg'),
  ('Pepino',         3.60,  'https://images.unsplash.com/photo-1449300079323-02e209d9d3a6?w=400&q=80', 'kg'),
  ('Pimentão Verde', 8.90,  'https://images.unsplash.com/photo-1563565375-f3fdfdbefa83?w=400&q=80', 'kg'),
  ('Tomate Carmem',  8.50,  'https://images.unsplash.com/photo-1546094096-0df4bcaaa337?w=400&q=80', 'kg'),
  ('Tomate Italiano',8.50,  'https://images.unsplash.com/photo-1546094096-0df4bcaaa337?w=400&q=80', 'kg'),
  ('Batata Doce',    3.75,  'https://images.unsplash.com/photo-1518977676601-b53f82aba655?w=400&q=80', 'kg'),
  ('Papino',         3.60,  'https://images.unsplash.com/photo-1449300079323-02e209d9d3a6?w=400&q=80', 'kg')
ON CONFLICT DO NOTHING;

-- RLS
ALTER TABLE public.default_products ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Anyone can read default_products" ON public.default_products FOR SELECT USING (true);

-- Função que copia o catálogo padrão para uma nova loja
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
    -- Cria o produto para a loja
    INSERT INTO public.products (name, price, image_url, unit, active, store_id)
    VALUES (dp.name, dp.price, dp.image_url, dp.unit, true, p_store_id)
    RETURNING id INTO new_product_id;

    -- Adiciona à cesta
    INSERT INTO public.basket_items (basket_id, product_id, quantity)
    VALUES (p_basket_id, new_product_id, 1);
  END LOOP;
END;
$$;
