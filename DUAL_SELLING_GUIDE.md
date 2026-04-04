# 🛒 Guia de Venda Dual (Peso e Unidade)

## 📋 O que é?

O sistema agora suporta três modos de venda para produtos:

1. **`unit`** - Apenas por unidade (ex: 1 alface, 2 alfaces)
2. **`weight`** - Apenas por peso (ex: 500g de tomate, 1kg de banana)
3. **`both`** - Cliente escolhe entre peso OU unidade (ex: 1 abacaxi inteiro OU 500g de abacaxi)

## 🎯 Quando usar cada modo?

### Apenas Unidade (`unit`)
Produtos que fazem sentido vender apenas por unidade:
- Alface (1 pé)
- Repolho pequeno
- Pimentão
- Pepino
- Ovos (dúzia)

### Apenas Peso (`weight`)
Produtos que fazem sentido vender apenas por peso:
- Tomate
- Batata
- Cebola
- Cenoura
- Banana (cacho)

### Dual - Peso OU Unidade (`both`)
Produtos que o cliente pode querer comprar inteiro OU por peso:
- **Abacaxi**: 1 unidade inteira OU 500g fatiado
- **Melancia**: 1 unidade inteira OU 2kg em pedaços
- **Repolho**: 1 unidade inteira OU 300g picado
- **Couve-flor**: 1 unidade inteira OU 400g
- **Melão**: 1 unidade inteira OU 1kg em pedaços

## 🔧 Como Configurar

### 1. Aplicar a Migração

Execute a migração no Supabase:

```bash
# A migração já foi criada em:
supabase/migrations/20260404000001_add_dual_selling.sql
```

Ou aplique manualmente no SQL Editor do Supabase:

```sql
-- Atualizar constraint
ALTER TABLE public.products DROP CONSTRAINT IF EXISTS products_sell_by_check;
ALTER TABLE public.products ADD CONSTRAINT products_sell_by_check 
  CHECK (sell_by IN ('unit', 'weight', 'both'));

-- Adicionar coluna para preço por unidade
ALTER TABLE public.products ADD COLUMN IF NOT EXISTS price_per_unit NUMERIC;
```

### 2. Configurar Produtos no Admin

No painel admin (`/admin/basket`), ao editar um produto:

#### Para Modo Dual (`both`):

1. Defina `sell_by = 'both'`
2. Configure **dois preços**:
   - `price_per_kg`: Preço por kg (ex: R$ 4,60/kg)
   - `price_per_unit`: Preço por unidade (ex: R$ 6,90/un)

**Exemplo - Abacaxi:**
```
Nome: Abacaxi
sell_by: both
price_per_kg: 4.60
price_per_unit: 6.90
min_weight: 0.5
step_weight: 0.25
```

#### Para Modo Unidade (`unit`):

```
Nome: Alface
sell_by: unit
price: 3.50
```

#### Para Modo Peso (`weight`):

```
Nome: Tomate
sell_by: weight
price_per_kg: 8.90
min_weight: 0.25
step_weight: 0.25
```

### 3. Atualizar via SQL (Rápido)

Para configurar vários produtos de uma vez:

```sql
-- Configurar abacaxi, melancia, repolho como dual
UPDATE public.products SET
  sell_by = 'both',
  price_per_unit = price * 1.5,  -- Ajuste o multiplicador conforme necessário
  price_per_kg = price
WHERE name ILIKE ANY(ARRAY[
  '%abacaxi%',
  '%melancia%',
  '%repolho%',
  '%couve-flor%',
  '%melão%'
]);
```

## 🎨 Como Funciona para o Cliente

### Produto com `sell_by = 'both'`

O cliente verá dois botões de seleção:

```
┌─────────────────────────────────┐
│ 🍍 Abacaxi                      │
│                                 │
│ [Por Unidade] [Por Peso]       │
│                                 │
│ R$ 6,90 / unidade              │
│                                 │
│ [Adicionar]                     │
└─────────────────────────────────┘
```

Se clicar em "Por Peso":

```
┌─────────────────────────────────┐
│ 🍍 Abacaxi                      │
│                                 │
│ [Por Unidade] [Por Peso] ✓     │
│                                 │
│ R$ 4,60 / kg                   │
│                                 │
│ [⚖️ Selecionar]                 │
└─────────────────────────────────┘
```

## 💡 Dicas de Precificação

### Estratégia Recomendada

Para produtos `both`, o preço por unidade geralmente é:

```
price_per_unit = (peso_médio_kg × price_per_kg) × 1.1 a 1.2
```

**Exemplo - Abacaxi:**
- Peso médio: 1.5kg
- Preço por kg: R$ 4,60
- Preço por unidade: 1.5 × 4.60 × 1.15 = R$ 7,94 (arredonde para R$ 7,90)

**Por que cobrar mais por unidade?**
- Conveniência para o cliente
- Produto inteiro (sem cortes)
- Facilita logística

## 📊 Exemplos Práticos

### Abacaxi
```sql
UPDATE products SET
  sell_by = 'both',
  price_per_kg = 4.60,
  price_per_unit = 7.90,
  min_weight = 0.5,
  step_weight = 0.25
WHERE name ILIKE '%abacaxi%';
```

Cliente pode escolher:
- 1 abacaxi inteiro por R$ 7,90
- 500g de abacaxi por R$ 2,30

### Melancia
```sql
UPDATE products SET
  sell_by = 'both',
  price_per_kg = 3.20,
  price_per_unit = 15.90,
  min_weight = 1.0,
  step_weight = 0.5
WHERE name ILIKE '%melancia%';
```

Cliente pode escolher:
- 1 melancia inteira por R$ 15,90
- 2kg de melancia por R$ 6,40

### Repolho
```sql
UPDATE products SET
  sell_by = 'both',
  price_per_kg = 5.90,
  price_per_unit = 4.50,
  min_weight = 0.25,
  step_weight = 0.25
WHERE name ILIKE '%repolho%';
```

Cliente pode escolher:
- 1 repolho inteiro por R$ 4,50
- 500g de repolho por R$ 2,95

## 🔄 Alterando Produtos Existentes

### De `weight` para `both`:

```sql
UPDATE products SET
  sell_by = 'both',
  price_per_unit = 6.90  -- Defina o preço por unidade
WHERE id = 'product-id-aqui';
```

### De `unit` para `both`:

```sql
UPDATE products SET
  sell_by = 'both',
  price_per_kg = 4.60,   -- Defina o preço por kg
  min_weight = 0.5,
  step_weight = 0.25
WHERE id = 'product-id-aqui';
```

### De `both` para `unit`:

```sql
UPDATE products SET
  sell_by = 'unit',
  price = price_per_unit
WHERE id = 'product-id-aqui';
```

## 📱 Interface do Cliente

### Fluxo de Compra

1. Cliente vê o produto
2. Se `sell_by = 'both'`, vê dois botões: "Por Unidade" | "Por Peso"
3. Cliente escolhe o modo preferido
4. Interface se adapta:
   - **Unidade**: Botões +/- para quantidade
   - **Peso**: Botão "Selecionar" que abre modal de peso
5. Produto é adicionado ao carrinho no modo escolhido

### Trocar de Modo

Se o cliente mudar de ideia:
1. Clica no outro botão (Por Unidade ↔ Por Peso)
2. O carrinho é limpo para esse produto
3. Cliente pode adicionar novamente no novo modo

## ⚠️ Observações Importantes

1. **Não é possível misturar modos**: O cliente não pode comprar o mesmo produto por peso E por unidade no mesmo pedido
2. **Trocar de modo limpa o carrinho**: Ao alternar entre peso/unidade, a quantidade anterior é removida
3. **Preços independentes**: `price_per_unit` e `price_per_kg` são configurados separadamente
4. **Pedidos salvam o modo**: O campo `sold_by` em `orders_items` registra como o item foi vendido

## 🐛 Troubleshooting

### Botões de modo não aparecem
- Verifique se `sell_by = 'both'` no banco
- Confirme que a migração foi aplicada

### Preço errado
- Verifique `price_per_unit` e `price_per_kg` no banco
- Confirme que ambos estão preenchidos

### Erro ao criar pedido
- Verifique se a coluna `sold_by` existe em `orders_items`
- Aplique a migração completa

## ✅ Checklist de Implementação

- [ ] Aplicar migração `20260404000001_add_dual_selling.sql`
- [ ] Configurar produtos com `sell_by = 'both'`
- [ ] Definir `price_per_unit` para produtos dual
- [ ] Definir `price_per_kg` para produtos dual
- [ ] Testar compra por unidade
- [ ] Testar compra por peso
- [ ] Testar alternância entre modos
- [ ] Verificar cálculo de total no carrinho
- [ ] Confirmar pedido salva `sold_by` corretamente
