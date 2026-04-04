# 🛒 Guia Completo - Venda de Hortifruti (Mundo Real)

## 🎯 Cenário Real

No estabelecimento físico:
1. Cliente vê os preços (ex: Tomate R$ 8,90/kg)
2. Cliente pega os produtos e coloca em sacolas
3. No caixa, cada sacola é pesada
4. Cliente paga pelo peso real de cada item

**Mas alguns clientes preferem comprar por unidade:**
- "Quero 6 tomates" (não quer pesar)
- "Quero 4 cebolas" (não quer pesar)
- "Quero 8 chuchus" (não quer pesar)

## ✅ Solução: Sistema Dual

O sistema suporta AMBAS as formas de venda para o mesmo produto!

### Configuração Recomendada

```sql
-- Produtos que podem ser vendidos POR PESO ou POR UNIDADE
UPDATE products SET
  sell_by = 'both',              -- Cliente escolhe: peso OU unidade
  price_per_kg = 8.90,           -- Preço por kg (para venda por peso)
  price_per_unit = 1.50,         -- Preço por unidade (para venda por unidade)
  min_weight = 0.25,             -- Mínimo 250g (para venda por peso)
  step_weight = 0.25             -- Incremento de 250g (para venda por peso)
WHERE name IN (
  'Tomate', 'Cebola', 'Batata', 'Cenoura', 
  'Pimentão', 'Pepino', 'Chuchu', 'Abobrinha'
);
```

## 📱 Experiência do Cliente

### Opção 1: Comprar por PESO (como no caixa físico)

```
┌─────────────────────────────────┐
│ 🍅 Tomate                       │
│                                 │
│ [Por Unidade] [Por Peso] ✓     │
│                                 │
│ R$ 8,90 / kg                   │
│                                 │
│ [⚖️ Selecionar]                 │
└─────────────────────────────────┘
```

Cliente clica em "Selecionar" e escolhe:
- 500g → R$ 4,45
- 1kg → R$ 8,90
- 1.5kg → R$ 13,35

### Opção 2: Comprar por UNIDADE (mais prático)

```
┌─────────────────────────────────┐
│ 🍅 Tomate                       │
│                                 │
│ [Por Unidade] ✓ [Por Peso]     │
│                                 │
│ R$ 1,50 / unidade              │
│                                 │
│ [-] 6 [+]                      │
└─────────────────────────────────┘
```

Cliente escolhe:
- 6 tomates → R$ 9,00
- 4 cebolas → R$ 6,00
- 8 chuchus → R$ 12,00

## 💰 Estratégia de Precificação

### Como Definir os Preços

**Preço por kg (base):**
- Tomate: R$ 8,90/kg
- Cebola: R$ 6,50/kg
- Chuchu: R$ 4,90/kg

**Preço por unidade (calculado):**

```
Preço por unidade = (Peso médio em kg) × (Preço por kg) × (Margem)
```

**Exemplos:**

**Tomate:**
- Peso médio: 150g (0.15kg)
- Preço/kg: R$ 8,90
- Cálculo: 0.15 × 8.90 × 1.1 = R$ 1,47
- **Preço por unidade: R$ 1,50**

**Cebola:**
- Peso médio: 200g (0.20kg)
- Preço/kg: R$ 6,50
- Cálculo: 0.20 × 6.50 × 1.1 = R$ 1,43
- **Preço por unidade: R$ 1,50**

**Chuchu:**
- Peso médio: 250g (0.25kg)
- Preço/kg: R$ 4,90
- Cálculo: 0.25 × 4.90 × 1.1 = R$ 1,35
- **Preço por unidade: R$ 1,40**

**Batata:**
- Peso médio: 120g (0.12kg)
- Preço/kg: R$ 5,90
- Cálculo: 0.12 × 5.90 × 1.1 = R$ 0,78
- **Preço por unidade: R$ 0,80**

### Por que cobrar margem na unidade?

1. **Conveniência**: Cliente não precisa pesar
2. **Praticidade**: Mais rápido no checkout
3. **Risco**: Produto pode ser maior que a média

## 🔧 Configuração Completa

### Script SQL para Configurar Todos os Produtos

```sql
-- 1. TOMATE
UPDATE products SET
  sell_by = 'both',
  price_per_kg = 8.90,
  price_per_unit = 1.50,
  min_weight = 0.25,
  step_weight = 0.25
WHERE name ILIKE '%tomate%';

-- 2. CEBOLA
UPDATE products SET
  sell_by = 'both',
  price_per_kg = 6.50,
  price_per_unit = 1.50,
  min_weight = 0.25,
  step_weight = 0.25
WHERE name ILIKE '%cebola%';

-- 3. BATATA
UPDATE products SET
  sell_by = 'both',
  price_per_kg = 5.90,
  price_per_unit = 0.80,
  min_weight = 0.25,
  step_weight = 0.25
WHERE name ILIKE '%batata%';

-- 4. CENOURA
UPDATE products SET
  sell_by = 'both',
  price_per_kg = 7.50,
  price_per_unit = 1.20,
  min_weight = 0.25,
  step_weight = 0.25
WHERE name ILIKE '%cenoura%';

-- 5. PIMENTÃO
UPDATE products SET
  sell_by = 'both',
  price_per_kg = 12.90,
  price_per_unit = 2.50,
  min_weight = 0.25,
  step_weight = 0.25
WHERE name ILIKE '%pimentão%' OR name ILIKE '%pimentao%';

-- 6. PEPINO
UPDATE products SET
  sell_by = 'both',
  price_per_kg = 6.90,
  price_per_unit = 1.80,
  min_weight = 0.25,
  step_weight = 0.25
WHERE name ILIKE '%pepino%';

-- 7. CHUCHU
UPDATE products SET
  sell_by = 'both',
  price_per_kg = 4.90,
  price_per_unit = 1.40,
  min_weight = 0.25,
  step_weight = 0.25
WHERE name ILIKE '%chuchu%';

-- 8. ABOBRINHA
UPDATE products SET
  sell_by = 'both',
  price_per_kg = 8.50,
  price_per_unit = 2.20,
  min_weight = 0.25,
  step_weight = 0.25
WHERE name ILIKE '%abobrinha%';

-- 9. BERINJELA
UPDATE products SET
  sell_by = 'both',
  price_per_kg = 9.90,
  price_per_unit = 2.80,
  min_weight = 0.25,
  step_weight = 0.25
WHERE name ILIKE '%berinjela%';

-- 10. BETERRABA
UPDATE products SET
  sell_by = 'both',
  price_per_kg = 6.90,
  price_per_unit = 1.50,
  min_weight = 0.25,
  step_weight = 0.25
WHERE name ILIKE '%beterraba%';
```

## 📊 Tabela de Referência

| Produto | Peso Médio | Preço/kg | Preço/un | Venda |
|---------|------------|----------|----------|-------|
| Tomate | 150g | R$ 8,90 | R$ 1,50 | Peso ou Unidade |
| Cebola | 200g | R$ 6,50 | R$ 1,50 | Peso ou Unidade |
| Batata | 120g | R$ 5,90 | R$ 0,80 | Peso ou Unidade |
| Cenoura | 150g | R$ 7,50 | R$ 1,20 | Peso ou Unidade |
| Pimentão | 180g | R$ 12,90 | R$ 2,50 | Peso ou Unidade |
| Pepino | 250g | R$ 6,90 | R$ 1,80 | Peso ou Unidade |
| Chuchu | 250g | R$ 4,90 | R$ 1,40 | Peso ou Unidade |
| Abobrinha | 250g | R$ 8,50 | R$ 2,20 | Peso ou Unidade |
| Berinjela | 280g | R$ 9,90 | R$ 2,80 | Peso ou Unidade |
| Beterraba | 200g | R$ 6,90 | R$ 1,50 | Peso ou Unidade |

## 🎯 Casos de Uso

### Caso 1: Cliente Quer Fazer Salada

**Compra por unidade (mais prático):**
- 6 tomates → R$ 9,00
- 2 pepinos → R$ 3,60
- 1 alface → R$ 3,50
- **Total: R$ 16,10**

### Caso 2: Cliente Quer Fazer Molho

**Compra por peso (mais econômico):**
- 2kg de tomate → R$ 17,80
- 500g de cebola → R$ 3,25
- **Total: R$ 21,05**

### Caso 3: Cliente Misto

**Combina peso e unidade:**
- 1kg de batata (peso) → R$ 5,90
- 4 cebolas (unidade) → R$ 6,00
- 500g de cenoura (peso) → R$ 3,75
- **Total: R$ 15,65**

## 🔄 Fluxo Completo

### 1. Cliente Acessa a Loja

```
http://localhost:8080/minha-loja
```

### 2. Vê os Produtos

```
🍅 Tomate
[Por Unidade] [Por Peso]
R$ 1,50 / unidade
[Adicionar]

🧅 Cebola
[Por Unidade] [Por Peso]
R$ 1,50 / unidade
[Adicionar]
```

### 3. Escolhe o Modo

**Opção A - Por Unidade:**
- Clica em "Por Unidade"
- Usa botões +/- para quantidade
- 6 tomates → R$ 9,00

**Opção B - Por Peso:**
- Clica em "Por Peso"
- Abre modal de seleção
- Escolhe 1kg → R$ 8,90

### 4. Finaliza Pedido

Carrinho mostra:
```
🍅 Tomate (6 unidades) → R$ 9,00
🧅 Cebola (1kg) → R$ 6,50
Total: R$ 15,50
```

## ⚙️ Aplicar Migração

Execute a migração para habilitar o modo dual:

```bash
# A migração já existe em:
supabase/migrations/20260404000001_add_dual_selling.sql
```

Ou aplique manualmente no Supabase SQL Editor:

```sql
-- Permitir sell_by = 'both'
ALTER TABLE public.products DROP CONSTRAINT IF EXISTS products_sell_by_check;
ALTER TABLE public.products ADD CONSTRAINT products_sell_by_check 
  CHECK (sell_by IN ('unit', 'weight', 'both'));

-- Adicionar coluna price_per_unit
ALTER TABLE public.products ADD COLUMN IF NOT EXISTS price_per_unit NUMERIC;

-- Adicionar coluna sold_by em orders_items
ALTER TABLE public.orders_items ADD COLUMN IF NOT EXISTS sold_by TEXT DEFAULT 'unit';
```

## ✅ Checklist de Implementação

- [ ] Aplicar migração `20260404000001_add_dual_selling.sql`
- [ ] Configurar produtos com `sell_by = 'both'`
- [ ] Definir `price_per_kg` (preço por kg)
- [ ] Definir `price_per_unit` (preço por unidade)
- [ ] Testar compra por peso
- [ ] Testar compra por unidade
- [ ] Testar alternância entre modos
- [ ] Verificar cálculo de total
- [ ] Fazer pedido de teste

## 🎉 Resultado Final

Com essa configuração, seu sistema replica EXATAMENTE o funcionamento de um hortifruti físico:

✅ Cliente vê o preço por kg (como na placa do estabelecimento)
✅ Cliente pode comprar por peso (como pesar no caixa)
✅ Cliente pode comprar por unidade (6 tomates, 4 cebolas)
✅ Sistema calcula automaticamente
✅ Cliente paga pelo que escolheu

**Melhor dos dois mundos!** 🌟
