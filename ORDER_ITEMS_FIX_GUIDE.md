# 🔧 Correção de Constraints em order_items

## Problema Identificado

### Erro Original
```
ERROR: 23503: update or delete on table "products" violates foreign key constraint 
"order_items_product_id_fkey" on table "order_items"
DETAIL: Key (id)=(47993931-63ed-4194-8073-83ea42a97d49) is still referenced from table "order_items".
```

### Causa
A tabela `order_items` tinha uma foreign key para `products` sem especificar o comportamento `ON DELETE`. Isso causava erro ao tentar deletar produtos que já estavam em pedidos.

### Estrutura Original (Problemática)
```sql
CREATE TABLE public.order_items (
  id UUID PRIMARY KEY,
  order_id UUID REFERENCES orders(id) ON DELETE CASCADE,
  product_id UUID REFERENCES products(id),  -- ❌ SEM ON DELETE
  quantity INTEGER DEFAULT 1
);
```

## Solução Implementada

### Migração: `20260404000004_fix_order_items_constraints.sql`

Esta migração faz 4 coisas importantes:

#### 1. Remove a Constraint Antiga
```sql
ALTER TABLE public.order_items 
  DROP CONSTRAINT IF EXISTS order_items_product_id_fkey;
```

#### 2. Adiciona Campos Faltantes
```sql
-- price: preço do item no momento do pedido (snapshot)
ALTER TABLE public.order_items ADD COLUMN price NUMERIC NOT NULL DEFAULT 0;

-- weight_kg: peso em kg para itens vendidos por peso
ALTER TABLE public.order_items ADD COLUMN weight_kg NUMERIC;

-- sold_by: modo de venda (unit ou weight)
ALTER TABLE public.order_items ADD COLUMN sold_by TEXT DEFAULT 'unit';
```

#### 3. Recria a Constraint com ON DELETE RESTRICT
```sql
ALTER TABLE public.order_items 
  ADD CONSTRAINT order_items_product_id_fkey 
  FOREIGN KEY (product_id) 
  REFERENCES public.products(id) 
  ON DELETE RESTRICT;  -- ✅ Impede deletar produto se estiver em pedido
```

#### 4. Cria Índices para Performance
```sql
CREATE INDEX idx_order_items_order_id ON public.order_items(order_id);
CREATE INDEX idx_order_items_product_id ON public.order_items(product_id);
```

## Por que ON DELETE RESTRICT?

### Opções Disponíveis

1. **CASCADE**: Deletaria os itens do pedido quando o produto for deletado
   - ❌ Ruim: Perde histórico de pedidos
   - ❌ Ruim: Pode causar inconsistências em pedidos antigos

2. **SET NULL**: Colocaria NULL no product_id
   - ❌ Ruim: Perde a referência do produto
   - ❌ Ruim: Não saberia qual produto foi pedido

3. **RESTRICT** (escolhido): Impede deletar o produto se estiver em pedidos
   - ✅ Bom: Preserva histórico completo
   - ✅ Bom: Força desativar produto ao invés de deletar
   - ✅ Bom: Mantém integridade referencial

### Comportamento Correto

```sql
-- ❌ Tentar deletar produto que está em pedido
DELETE FROM products WHERE id = 'xxx';
-- Resultado: ERRO (produto está em pedidos)

-- ✅ Desativar produto ao invés de deletar
UPDATE products SET active = false WHERE id = 'xxx';
-- Resultado: OK (produto fica inativo mas histórico preservado)
```

## Campos Adicionados

### 1. price (NUMERIC)
- **Propósito**: Armazena o preço do item no momento do pedido
- **Por quê**: Preços podem mudar, mas pedidos antigos devem manter o preço original
- **Exemplo**: Cliente comprou tomate a R$ 8,50/kg, mesmo que hoje esteja R$ 10,00/kg

### 2. weight_kg (NUMERIC, nullable)
- **Propósito**: Armazena o peso em kg para itens vendidos por peso
- **Por quê**: Sistema de venda dual (peso e unidade)
- **Exemplo**: Cliente comprou 0.5kg de tomate

### 3. sold_by (TEXT)
- **Propósito**: Indica se o item foi vendido por unidade ou peso
- **Valores**: 'unit' ou 'weight'
- **Por quê**: Sistema precisa saber como calcular o preço

## Estrutura Final

```sql
CREATE TABLE public.order_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id UUID NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
  product_id UUID NOT NULL REFERENCES products(id) ON DELETE RESTRICT,
  quantity INTEGER NOT NULL DEFAULT 1,
  price NUMERIC NOT NULL DEFAULT 0,
  weight_kg NUMERIC,
  sold_by TEXT DEFAULT 'unit',
  needs_weighing BOOLEAN DEFAULT false,
  actual_weight_kg NUMERIC,
  final_price NUMERIC
);
```

## Como Executar a Migração

### Opção 1: Via Supabase Dashboard
1. Acesse o Supabase Dashboard
2. Vá em SQL Editor
3. Cole o conteúdo de `20260404000004_fix_order_items_constraints.sql`
4. Execute

### Opção 2: Via CLI
```bash
supabase db push
```

### Opção 3: Via Migration
```bash
supabase migration up
```

## Verificação Pós-Migração

### 1. Verificar Constraint
```sql
SELECT 
  conname AS constraint_name,
  confdeltype AS on_delete_action
FROM pg_constraint
WHERE conname = 'order_items_product_id_fkey';

-- Resultado esperado:
-- constraint_name: order_items_product_id_fkey
-- on_delete_action: r (RESTRICT)
```

### 2. Verificar Campos
```sql
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_name = 'order_items'
ORDER BY ordinal_position;

-- Deve incluir: price, weight_kg, sold_by
```

### 3. Testar Comportamento
```sql
-- Tentar deletar produto em pedido (deve falhar)
DELETE FROM products WHERE id IN (
  SELECT DISTINCT product_id FROM order_items LIMIT 1
);
-- Esperado: ERROR (constraint violation)

-- Desativar produto (deve funcionar)
UPDATE products SET active = false WHERE id IN (
  SELECT DISTINCT product_id FROM order_items LIMIT 1
);
-- Esperado: SUCCESS
```

## Impacto no Sistema

### Backend
- ✅ Queries de order_items agora incluem price, weight_kg, sold_by
- ✅ Não é mais possível deletar produtos em pedidos
- ✅ Histórico de pedidos preservado

### Frontend
- ✅ CustomerTracking.tsx pode buscar detalhes completos dos itens
- ✅ Preços históricos são mantidos
- ✅ Sistema de peso funciona corretamente

### Admin
- ⚠️ Admin não pode mais deletar produtos em pedidos
- ✅ Admin deve desativar produtos ao invés de deletar
- ✅ Produtos inativos não aparecem para clientes novos

## Boas Práticas

### Para Admins
1. **Nunca delete produtos**, sempre desative:
   ```sql
   UPDATE products SET active = false WHERE id = 'xxx';
   ```

2. **Para "limpar" produtos antigos**:
   ```sql
   -- Desativa produtos sem pedidos nos últimos 6 meses
   UPDATE products SET active = false
   WHERE id NOT IN (
     SELECT DISTINCT product_id FROM order_items oi
     JOIN orders o ON o.id = oi.order_id
     WHERE o.created_at > NOW() - INTERVAL '6 months'
   );
   ```

### Para Desenvolvedores
1. **Sempre use snapshot de preço**:
   ```typescript
   // ✅ Correto
   order_items.insert({
     product_id: product.id,
     price: product.price,  // snapshot do preço atual
     quantity: 2
   });
   
   // ❌ Errado
   order_items.insert({
     product_id: product.id,
     // sem price, vai buscar do produto (pode mudar)
   });
   ```

2. **Sempre especifique sold_by**:
   ```typescript
   order_items.insert({
     product_id: product.id,
     sold_by: 'weight',
     weight_kg: 0.5,
     price: product.price_per_kg * 0.5
   });
   ```

## Troubleshooting

### Erro: "constraint violation" ao deletar produto
**Causa**: Produto está em pedidos existentes
**Solução**: Desative o produto ao invés de deletar
```sql
UPDATE products SET active = false WHERE id = 'xxx';
```

### Erro: "column does not exist" ao buscar order_items
**Causa**: Migração não foi executada
**Solução**: Execute a migração `20260404000004_fix_order_items_constraints.sql`

### Preços de pedidos antigos estão errados
**Causa**: Campo `price` não foi populado corretamente
**Solução**: Popule preços históricos (se possível)
```sql
-- Atualiza preços faltantes com preço atual do produto
UPDATE order_items oi
SET price = p.price
FROM products p
WHERE oi.product_id = p.id
AND oi.price = 0;
```

## Conclusão

Esta migração resolve o problema de foreign key e adiciona os campos necessários para o sistema de venda dual (peso e unidade) funcionar corretamente. O uso de `ON DELETE RESTRICT` garante que o histórico de pedidos seja preservado, enquanto os novos campos permitem armazenar todas as informações necessárias sobre cada item do pedido.
