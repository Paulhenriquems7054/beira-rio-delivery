# 🛒 Venda Dual para TODOS os Produtos

## ✅ Configuração Aplicada

Agora TODOS os produtos do sistema têm a opção de venda dual:
- **Por Unidade**: Cliente escolhe quantidade (6 tomates, 4 cebolas)
- **Por Peso**: Cliente escolhe peso (500g, 1kg, 1.5kg)

## 📋 Migrações Atualizadas

### 1. `20260404000001_add_dual_selling.sql` (ATUALIZADA)

Agora configura TODOS os produtos com `sell_by = 'both'`:

```sql
-- Configura TODOS os produtos para venda dual
UPDATE public.products SET
  sell_by = 'both',
  price_per_unit = [calculado automaticamente],
  price_per_kg = [usa o preço existente],
  min_weight = 0.25,
  step_weight = 0.25
WHERE sell_by IS NOT NULL;
```

### 2. `20260404000002_adjust_unit_prices.sql` (NOVA)

Ajusta os preços por unidade baseado no peso médio real de cada tipo de produto:

**Exemplos de cálculo:**

| Produto | Peso Médio | Preço/kg | Cálculo | Preço/un |
|---------|------------|----------|---------|----------|
| Tomate | 150g | R$ 8,90 | 0.15 × 8.90 × 1.15 | R$ 1,54 |
| Batata | 120g | R$ 5,90 | 0.12 × 5.90 × 1.15 | R$ 0,81 |
| Cebola | 170g | R$ 6,50 | 0.17 × 6.50 × 1.15 | R$ 1,27 |
| Pepino | 250g | R$ 6,90 | 0.25 × 6.90 × 1.15 | R$ 1,98 |
| Abacaxi | 1.5kg | R$ 4,60 | 1.5 × 4.60 × 1.10 | R$ 7,59 |
| Alface | 250g | R$ 12,00 | 0.25 × 12.00 × 1.20 | R$ 3,60 |

## 🚀 Como Executar

### Passo 1: Executar Migração Principal

```sql
-- Via Supabase Dashboard ou CLI
-- Arquivo: supabase/migrations/20260404000001_add_dual_selling.sql
```

### Passo 2: Ajustar Preços por Unidade (Opcional mas Recomendado)

```sql
-- Via Supabase Dashboard ou CLI
-- Arquivo: supabase/migrations/20260404000002_adjust_unit_prices.sql
```

### Passo 3: Verificar

```sql
-- Ver todos os produtos configurados
SELECT 
  name,
  sell_by,
  price_per_kg,
  price_per_unit,
  ROUND((price_per_unit / price_per_kg)::numeric, 2) as peso_medio_kg
FROM products
WHERE sell_by = 'both'
ORDER BY name
LIMIT 20;
```

## 📱 Experiência do Cliente

### Antes (apenas 1 produto)
```
🍍 Abacaxi
[Por Unidade] [Por Peso]
```

### Depois (TODOS os produtos)
```
🍅 Tomate
[Por Unidade] [Por Peso]

🧅 Cebola
[Por Unidade] [Por Peso]

🥔 Batata
[Por Unidade] [Por Peso]

🥕 Cenoura
[Por Unidade] [Por Peso]

... e assim por diante
```

## 💰 Estratégia de Precificação

### Fórmula Geral

```
Preço por unidade = (Peso médio em kg) × (Preço por kg) × (Margem)
```

### Margens Aplicadas

| Categoria | Margem | Motivo |
|-----------|--------|--------|
| Legumes/Verduras | 15% | Peso mais uniforme |
| Frutas pequenas | 15% | Peso mais uniforme |
| Frutas grandes | 10% | Peso mais variável |
| Folhas/Maços | 20% | Peso muito variável |
| Ervas/Temperos | 25% | Peso muito variável |

### Pesos Médios Usados

| Categoria | Peso Médio | Exemplos |
|-----------|------------|----------|
| Muito pequeno | 80g | Alho, ervas |
| Pequeno | 120g | Limão, batata |
| Médio | 170g | Maçã, laranja, cebola |
| Grande | 250g | Pepino, abobrinha, alface |
| Muito grande | 400g | Manga, mamão |
| Extra grande | 1-2kg | Abacaxi, melancia |

## 🔧 Ajustes Manuais (Se Necessário)

Se quiser ajustar preços específicos:

```sql
-- Exemplo: Ajustar tomate
UPDATE products SET
  price_per_unit = 1.80  -- Preço desejado
WHERE name ILIKE '%tomate%';

-- Exemplo: Ajustar todos os produtos de uma categoria
UPDATE products SET
  price_per_unit = ROUND((0.20 * price_per_kg * 1.15)::numeric, 2)
WHERE name ILIKE ANY(ARRAY['%tomate%', '%pimentão%', '%pepino%']);
```

## 📊 Relatório de Produtos

Após executar as migrações, você pode gerar um relatório:

```sql
-- Relatório completo de preços
SELECT 
  name as produto,
  sell_by as modo_venda,
  CONCAT('R$ ', ROUND(price_per_kg::numeric, 2)) as preco_kg,
  CONCAT('R$ ', ROUND(price_per_unit::numeric, 2)) as preco_un,
  CONCAT(ROUND((price_per_unit / price_per_kg * 1000)::numeric, 0), 'g') as peso_medio_estimado
FROM products
WHERE sell_by = 'both'
ORDER BY name;
```

## ✅ Validações Aplicadas

A migração inclui validações automáticas:

1. **Preço mínimo por unidade**: R$ 0,50
   - Evita preços muito baixos que não compensam

2. **Preço máximo por unidade**: R$ 50,00
   - Para produtos muito grandes, limita a 2× o preço por kg

3. **Preços arredondados**: 2 casas decimais
   - Facilita cálculos e exibição

## 🎯 Casos de Uso

### Cliente 1: Compra Rápida (Por Unidade)
```
6 tomates → R$ 9,24
4 cebolas → R$ 5,08
2 pepinos → R$ 3,96
Total: R$ 18,28
```

### Cliente 2: Compra Econômica (Por Peso)
```
1kg tomate → R$ 8,90
500g cebola → R$ 3,25
300g pepino → R$ 2,07
Total: R$ 14,22
```

### Cliente 3: Misto
```
6 tomates (unidade) → R$ 9,24
1kg batata (peso) → R$ 5,90
4 cebolas (unidade) → R$ 5,08
Total: R$ 20,22
```

## 🔄 Reverter (Se Necessário)

Se quiser voltar alguns produtos para venda apenas por peso:

```sql
-- Exemplo: Voltar folhas para apenas peso
UPDATE products SET
  sell_by = 'weight'
WHERE name ILIKE ANY(ARRAY['%alface%', '%rúcula%', '%couve%']);
```

## 📝 Notas Importantes

1. **Preços calculados automaticamente**: Baseados no peso médio de cada categoria
2. **Ajustes recomendados**: Revise os preços e ajuste conforme sua realidade
3. **Teste antes de produção**: Verifique se os preços fazem sentido
4. **Margem de lucro**: Já incluída nos cálculos (10-25% dependendo do produto)

## 🎉 Resultado Final

Após executar as migrações:

✅ TODOS os produtos têm opção de venda dual
✅ Preços por unidade calculados automaticamente
✅ Preços ajustados por categoria de produto
✅ Cliente escolhe como prefere comprar
✅ Sistema funciona como hortifruti real

**Pronto para uso!** 🌟
