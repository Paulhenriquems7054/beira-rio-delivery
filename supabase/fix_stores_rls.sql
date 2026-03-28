-- Garante que qualquer usuário autenticado (mesmo não confirmado) pode criar loja

-- Remove políticas antigas
DROP POLICY IF EXISTS "Anyone can insert stores" ON public.stores;
DROP POLICY IF EXISTS "Anyone can update stores" ON public.stores;
DROP POLICY IF EXISTS "Anyone can delete stores" ON public.stores;
DROP POLICY IF EXISTS "Anyone can read stores" ON public.stores;

-- Recria com permissão total (MVP sem restrições)
CREATE POLICY "Public read stores" ON public.stores FOR SELECT USING (true);
CREATE POLICY "Public insert stores" ON public.stores FOR INSERT WITH CHECK (true);
CREATE POLICY "Public update stores" ON public.stores FOR UPDATE USING (true);
CREATE POLICY "Public delete stores" ON public.stores FOR DELETE USING (true);

-- Mesma coisa para baskets
DROP POLICY IF EXISTS "Anyone can insert baskets" ON public.baskets;
DROP POLICY IF EXISTS "Anyone can update baskets" ON public.baskets;
DROP POLICY IF EXISTS "Anyone can delete baskets" ON public.baskets;
DROP POLICY IF EXISTS "Anyone can read baskets" ON public.baskets;
DROP POLICY IF EXISTS "Public Select Baskets" ON public.baskets;

CREATE POLICY "Public read baskets" ON public.baskets FOR SELECT USING (true);
CREATE POLICY "Public insert baskets" ON public.baskets FOR INSERT WITH CHECK (true);
CREATE POLICY "Public update baskets" ON public.baskets FOR UPDATE USING (true);
CREATE POLICY "Public delete baskets" ON public.baskets FOR DELETE USING (true);

-- Confirma
SELECT schemaname, tablename, policyname, cmd
FROM pg_policies
WHERE tablename IN ('stores', 'baskets')
ORDER BY tablename, cmd;
