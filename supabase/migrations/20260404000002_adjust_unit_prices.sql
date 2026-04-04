-- Ajustar preços por unidade de forma mais precisa
-- Baseado no peso médio real de cada tipo de produto

-- LEGUMES E VERDURAS (peso médio: 150-250g)
UPDATE public.products SET
  price_per_unit = ROUND((0.15 * price_per_kg * 1.15)::numeric, 2)
WHERE name ILIKE ANY(ARRAY[
  '%tomate%', '%pimentão%', '%pimentao%', '%cenoura%', 
  '%beterraba%', '%rabanete%'
]) AND price_per_kg IS NOT NULL;

-- TUBÉRCULOS (peso médio: 100-150g)
UPDATE public.products SET
  price_per_unit = ROUND((0.12 * price_per_kg * 1.15)::numeric, 2)
WHERE name ILIKE ANY(ARRAY[
  '%batata%', '%mandioca%', '%inhame%', '%cará%'
]) AND price_per_kg IS NOT NULL;

-- CEBOLA E ALHO (peso médio: 150-200g)
UPDATE public.products SET
  price_per_unit = ROUND((0.17 * price_per_kg * 1.15)::numeric, 2)
WHERE name ILIKE ANY(ARRAY[
  '%cebola%', '%alho%'
]) AND price_per_kg IS NOT NULL;

-- PEPINO, ABOBRINHA, CHUCHU (peso médio: 200-300g)
UPDATE public.products SET
  price_per_unit = ROUND((0.25 * price_per_kg * 1.15)::numeric, 2)
WHERE name ILIKE ANY(ARRAY[
  '%pepino%', '%abobrinha%', '%chuchu%', '%berinjela%'
]) AND price_per_kg IS NOT NULL;

-- FRUTAS PEQUENAS (peso médio: 100-150g)
UPDATE public.products SET
  price_per_unit = ROUND((0.12 * price_per_kg * 1.15)::numeric, 2)
WHERE name ILIKE ANY(ARRAY[
  '%limão%', '%limao%', '%kiwi%', '%maracujá%', '%maracuja%'
]) AND price_per_kg IS NOT NULL;

-- FRUTAS MÉDIAS (peso médio: 150-200g)
UPDATE public.products SET
  price_per_unit = ROUND((0.17 * price_per_kg * 1.15)::numeric, 2)
WHERE name ILIKE ANY(ARRAY[
  '%maçã%', '%maca%', '%pera%', '%laranja%', '%tangerina%',
  '%mexerica%', '%bergamota%'
]) AND price_per_kg IS NOT NULL;

-- FRUTAS GRANDES (peso médio: 300-500g)
UPDATE public.products SET
  price_per_unit = ROUND((0.40 * price_per_kg * 1.15)::numeric, 2)
WHERE name ILIKE ANY(ARRAY[
  '%manga%', '%mamão%', '%mamao%', '%abacate%'
]) AND price_per_kg IS NOT NULL;

-- FRUTAS MUITO GRANDES (peso médio: 1-2kg)
UPDATE public.products SET
  price_per_unit = ROUND((1.5 * price_per_kg * 1.10)::numeric, 2)
WHERE name ILIKE ANY(ARRAY[
  '%abacaxi%', '%melancia%', '%melão%', '%melao%', '%jaca%'
]) AND price_per_kg IS NOT NULL;

-- BANANA (cacho médio: 800g-1kg)
UPDATE public.products SET
  price_per_unit = ROUND((0.9 * price_per_kg * 1.10)::numeric, 2)
WHERE name ILIKE '%banana%' AND price_per_kg IS NOT NULL;

-- UVA (cacho médio: 500g)
UPDATE public.products SET
  price_per_unit = ROUND((0.5 * price_per_kg * 1.15)::numeric, 2)
WHERE name ILIKE '%uva%' AND price_per_kg IS NOT NULL;

-- FOLHAS E VERDURAS (maço/pé: 200-300g)
UPDATE public.products SET
  price_per_unit = ROUND((0.25 * price_per_kg * 1.20)::numeric, 2)
WHERE name ILIKE ANY(ARRAY[
  '%alface%', '%rúcula%', '%rucula%', '%agrião%', '%agriao%',
  '%couve%', '%espinafre%', '%acelga%', '%almeirão%', '%almeirao%',
  '%chicória%', '%chicoria%', '%escarola%'
]) AND price_per_kg IS NOT NULL;

-- REPOLHO E COUVE-FLOR (unidade média: 800g-1kg)
UPDATE public.products SET
  price_per_unit = ROUND((0.9 * price_per_kg * 1.10)::numeric, 2)
WHERE name ILIKE ANY(ARRAY[
  '%repolho%', '%couve-flor%', '%couve flor%', '%brócolis%', '%brocolis%'
]) AND price_per_kg IS NOT NULL;

-- ERVAS E TEMPEROS (maço pequeno: 50-100g)
UPDATE public.products SET
  price_per_unit = ROUND((0.08 * price_per_kg * 1.25)::numeric, 2)
WHERE name ILIKE ANY(ARRAY[
  '%salsinha%', '%cebolinha%', '%coentro%', '%hortelã%', '%hortela%',
  '%manjericão%', '%manjericao%', '%alecrim%', '%tomilho%'
]) AND price_per_kg IS NOT NULL;

-- Garantir que nenhum preço por unidade seja menor que R$ 0,50
UPDATE public.products SET
  price_per_unit = 0.50
WHERE price_per_unit < 0.50 AND price_per_unit IS NOT NULL;

-- Garantir que nenhum preço por unidade seja maior que R$ 50,00 (produtos muito grandes)
UPDATE public.products SET
  price_per_unit = ROUND((price_per_kg * 2)::numeric, 2)
WHERE price_per_unit > 50.00 AND price_per_kg IS NOT NULL;
