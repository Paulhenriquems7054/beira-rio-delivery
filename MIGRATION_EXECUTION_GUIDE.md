# 🔧 Guia de Execução das Migrações

## ⚠️ Erro Corrigido

**Erro encontrado:**
```
ERROR: 42P01: relation "public.orders_items" does not exist
```

**Causa:** Nome incorreto da tabela. O correto é `order_items` (não `orders_items`)

**Status:** ✅ Corrigido na migração `20260404000001_add_dual_selling.sql`

## 📋 Migrações Necessárias

Para habilitar a venda por peso e unidade, você precisa executar:

### 1. `20260328000009_add_weight_selling.sql` ✅

**O que faz:**
- Adiciona coluna `sell_by` (unit, weight)
- Adiciona coluna `price_per_kg`
- Adiciona colunas `min_weight` e `step_weight`
- Configura produtos típicos de hortifruti para venda por peso

**Status:** Provavelmente já executada (arquivo antigo)

### 2. `20260404000001_add_dual_selling.sql` ✅ (CORRIGIDA)

**O que faz:**
- Atualiza constraint para aceitar `sell_by = 'both'`
- Adiciona coluna `price_per_unit`
- Adiciona coluna `sold_by` em `order_items`
- Configura alguns produtos para venda dual

**Status:** Pronta para executar (erro corrigido)

## 🚀 Como Executar

### Opção 1: Via Supabase CLI (Recomendado)

```bash
# 1. Verificar status das migrações
supabase migration list

# 2. Aplicar migrações pendentes
supabase db push

# 3. Verificar se foi aplicada
supabase migration list
```

### Opção 2: Via Supabase Dashboard

1. Acesse: https://supabase.com/dashboard/project/[seu-projeto]/sql
2. Abra o arquivo `supabase/migrations/20260404000001_add_dual_selling.sql`
3. Copie todo o conteúdo
4. Cole no SQL Editor
5. Clique em "Run"

### Opção 3: Executar SQL Manualmente

Se preferir executar apenas as alterações necessárias:

```sql
-- 1. Atualizar constraint para aceitar 'both'
ALTER TABLE public.products DROP CONSTRAINT IF EXISTS products_sell_by_check;
ALTER TABLE public.products ADD CONSTRAINT products_sell_by_check 
  CHECK (sell_by IN ('unit', 'weight', 'both'));

-- 2. Adicionar coluna para preço por unidade
ALTER TABLE public.products ADD COLUMN IF NOT EXISTS price_per_unit NUMERIC;

-- 3. Adicionar coluna sold_by em order_items
ALTER TABLE public.order_items ADD COLUMN IF NOT EXISTS sold_by TEXT DEFAULT 'unit';

-- 4. Comentários explicativos
COMMENT ON COLUMN public.products.sell_by IS 'Modo de venda: unit (apenas unidade), weight (apenas peso), both (cliente escolhe)';
COMMENT ON COLUMN public.products.price IS 'Preço base (usado quando sell_by = unit)';
COMMENT ON COLUMN public.products.price_per_kg IS 'Preço por kg (usado quando sell_by = weight ou both)';
COMMENT ON COLUMN public.products.price_per_unit IS 'Preço por unidade (usado quando sell_by = both)';
COMMENT ON COLUMN public.order_items.sold_by IS 'Como o item foi vendido: unit ou weight';
```

## ✅ Verificar se Foi Aplicada

Execute este SQL para verificar:

```sql
-- 1. Verificar colunas em products
SELECT column_name, data_type, column_default
FROM information_schema.columns 
WHERE table_name = 'products' 
  AND column_name IN ('sell_by', 'price_per_kg', 'price_per_unit', 'min_weight', 'step_weight')
ORDER BY column_name;

-- 2. Verificar constraint
SELECT 
  con.conname AS constraint_name,
  pg_get_constraintdef(con.oid) AS constraint_definition
FROM pg_constraint con
JOIN pg_class rel ON rel.oid = con.conrelid
WHERE rel.relname = 'products' 
  AND con.conname LIKE '%sell_by%';

-- 3. Verificar coluna sold_by em order_items
SELECT column_name, data_type, column_default
FROM information_schema.columns 
WHERE table_name = 'order_items' 
  AND column_name = 'sold_by';
```

**Resultado esperado:**

```
column_name      | data_type | column_default
-----------------+-----------+---------------
min_weight       | numeric   | 0.25
price_per_kg     | numeric   | NULL
price_per_unit   | numeric   | NULL
sell_by          | text      | 'unit'::text
step_weight      | numeric   | 0.25

constraint_name           | constraint_definition
--------------------------+-----------------------------------------------
products_sell_by_check    | CHECK ((sell_by = ANY (ARRAY['unit'::text, 'weight'::text, 'both'::text])))

column_name | data_type | column_default
------------+-----------+---------------
sold_by     | text      | 'unit'::text
```

## 🔄 Ordem de Execução

Se você está começando do zero:

1. ✅ Execute todas as migrações anteriores (20260322... até 20260328000015...)
2. ✅ Execute `20260328000009_add_weight_selling.sql` (se ainda não foi)
3. ✅ Execute `20260404000001_add_dual_selling.sql` (corrigida)

## 🐛 Troubleshooting

### Erro: "column already exists"

Se você receber erro dizendo que a coluna já existe:

```sql
-- Verificar se já existe
SELECT column_name FROM information_schema.columns 
WHERE table_name = 'products' AND column_name = 'price_per_unit';

-- Se já existe, pule essa parte da migração
```

### Erro: "constraint already exists"

```sql
-- Remover constraint antiga
ALTER TABLE public.products DROP CONSTRAINT IF EXISTS products_sell_by_check;

-- Adicionar nova
ALTER TABLE public.products ADD CONSTRAINT products_sell_by_check 
  CHECK (sell_by IN ('unit', 'weight', 'both'));
```

### Erro: "relation does not exist"

Certifique-se de que as migrações anteriores foram executadas:

```sql
-- Verificar se a tabela products existe
SELECT table_name FROM information_schema.tables 
WHERE table_schema = 'public' AND table_name = 'products';

-- Verificar se a tabela order_items existe
SELECT table_name FROM information_schema.tables 
WHERE table_schema = 'public' AND table_name = 'order_items';
```

## 📊 Após Executar

Depois de aplicar as migrações, configure seus produtos:

```sql
-- Exemplo: Configurar tomate para venda dual
UPDATE products SET
  sell_by = 'both',
  price_per_kg = 8.90,
  price_per_unit = 1.50,
  min_weight = 0.25,
  step_weight = 0.25
WHERE name ILIKE '%tomate%';
```

Veja o guia completo em: `HORTIFRUTI_REAL_WORLD_GUIDE.md`

## ✅ Checklist Final

- [ ] Migração `20260328000009_add_weight_selling.sql` executada
- [ ] Migração `20260404000001_add_dual_selling.sql` executada (corrigida)
- [ ] Colunas verificadas em `products`
- [ ] Coluna `sold_by` verificada em `order_items`
- [ ] Constraint `sell_by` aceita 'both'
- [ ] Produtos configurados com preços
- [ ] Testado no frontend

## 🎉 Pronto!

Após executar as migrações, o sistema estará pronto para:
- ✅ Venda por peso (kg/g)
- ✅ Venda por unidade (6 tomates, 4 cebolas)
- ✅ Venda dual (cliente escolhe)
