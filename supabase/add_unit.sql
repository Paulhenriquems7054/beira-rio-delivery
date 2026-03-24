-- Adiciona a coluna unit indicando a unidade de medida do produto
ALTER TABLE public.products ADD COLUMN IF NOT EXISTS unit TEXT NOT NULL DEFAULT 'un';
