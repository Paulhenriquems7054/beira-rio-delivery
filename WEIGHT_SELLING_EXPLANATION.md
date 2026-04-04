# ✅ Sistema de Venda por Peso - Como Funciona

## 🎯 Resumo

O sistema JÁ SUPORTA completamente a lógica que você descreveu:

1. ✅ Cliente vê o preço por kg de cada item
2. ✅ Cliente escolhe a quantidade desejada (250g, 500g, 1kg, etc.)
3. ✅ Sistema calcula automaticamente o valor total
4. ✅ Cliente paga pelo peso escolhido

## 📱 Fluxo do Cliente

### Passo 1: Visualizar Produto

O cliente vê o card do produto:

```
┌─────────────────────────────────┐
│ 🍅 Tomate                       │
│ R$ 8,90 / kg                   │
│                                 │
│ [⚖️ Selecionar]                 │
└─────────────────────────────────┘
```

### Passo 2: Clicar em "Selecionar"

Abre um modal interativo com:

```
┌─────────────────────────────────┐
│ ⚖️ Tomate                       │
│                                 │
│ R$ 8,90 / kg                   │
│                                 │
│     [-]    500g    [+]         │
│         peso estimado           │
│                                 │
│ [250g] [500g] [750g] [1kg]     │
│ [1.5kg] [2kg]                  │
│                                 │
│ ┌─────────────────────────┐   │
│ │ Total estimado          │   │
│ │ R$ 4,45                 │   │
│ │ ⚠️ Valor pode variar    │   │
│ └─────────────────────────┘   │
│                                 │
│ [Adicionar ao Carrinho]        │
└─────────────────────────────────┘
```

### Passo 3: Escolher Quantidade

O cliente pode:

**Opção A - Usar botões +/-:**
- Clica em `+` para aumentar (incremento de 250g)
- Clica em `-` para diminuir (incremento de 250g)

**Opção B - Atalhos rápidos:**
- Clica direto em `250g`, `500g`, `750g`, `1kg`, `1.5kg` ou `2kg`

**Cálculo automático:**
- Peso escolhido: 500g (0.5kg)
- Preço por kg: R$ 8,90
- Total: 0.5 × 8.90 = R$ 4,45

### Passo 4: Adicionar ao Carrinho

Cliente clica em "Adicionar ao Carrinho" e o produto é adicionado com:
- Peso selecionado: 500g
- Valor calculado: R$ 4,45

### Passo 5: Carrinho

No carrinho, o cliente vê:

```
┌─────────────────────────────────┐
│ 🍅 Tomate                       │
│ R$ 8,90 / kg                   │
│ 500g ≈ R$ 4,45                 │
│                                 │
│ [⚖️ Alterar]                    │
└─────────────────────────────────┘
```

Se quiser mudar a quantidade, clica em "Alterar" e o modal abre novamente.

## 🔧 Configuração Técnica

### Campos do Produto

Para venda por peso, configure:

```sql
-- Exemplo: Tomate
UPDATE products SET
  sell_by = 'weight',           -- Modo de venda por peso
  price_per_kg = 8.90,          -- Preço por kg
  min_weight = 0.25,            -- Peso mínimo (250g)
  step_weight = 0.25            -- Incremento (250g)
WHERE name = 'Tomate';
```

### Campos Explicados

- **`sell_by = 'weight'`**: Ativa o modo de venda por peso
- **`price_per_kg`**: Preço por quilograma (R$ 8,90/kg)
- **`min_weight`**: Peso mínimo que o cliente pode comprar (0.25 = 250g)
- **`step_weight`**: Incremento dos botões +/- (0.25 = 250g por clique)

### Atalhos Rápidos

Os botões de atalho são fixos no código:

```typescript
const QUICK_WEIGHTS = [0.25, 0.5, 0.75, 1, 1.5, 2];
// Equivale a: 250g, 500g, 750g, 1kg, 1.5kg, 2kg
```

## 💰 Cálculo de Preço

### Fórmula

```
Total = Peso (kg) × Preço por kg
```

### Exemplos

**Tomate - R$ 8,90/kg:**
- 250g (0.25kg): 0.25 × 8.90 = R$ 2,23
- 500g (0.50kg): 0.50 × 8.90 = R$ 4,45
- 1kg (1.00kg): 1.00 × 8.90 = R$ 8,90
- 1.5kg (1.50kg): 1.50 × 8.90 = R$ 13,35

**Banana - R$ 5,60/kg:**
- 500g: 0.50 × 5.60 = R$ 2,80
- 1kg: 1.00 × 5.60 = R$ 5,60
- 2kg: 2.00 × 5.60 = R$ 11,20

## ⚠️ Aviso de Peso Estimado

O modal mostra:

> ⚠️ Valor pode variar conforme peso real na balança

**Por quê?**
- Cliente escolhe peso estimado (ex: 500g)
- Na hora de separar, o peso real pode ser 480g ou 520g
- O valor final será ajustado pelo peso real na balança

**Exemplo:**
- Cliente pediu: 500g de tomate (R$ 4,45)
- Peso real na balança: 520g
- Valor cobrado: 0.52 × 8.90 = R$ 4,63

## 📊 Produtos Recomendados para Venda por Peso

### Verduras e Legumes
```sql
UPDATE products SET
  sell_by = 'weight',
  price_per_kg = [preço],
  min_weight = 0.25,
  step_weight = 0.25
WHERE name IN (
  'Tomate', 'Batata', 'Cebola', 'Cenoura', 
  'Pimentão', 'Pepino', 'Abobrinha', 'Berinjela',
  'Beterraba', 'Mandioca', 'Batata Doce'
);
```

### Frutas
```sql
UPDATE products SET
  sell_by = 'weight',
  price_per_kg = [preço],
  min_weight = 0.25,
  step_weight = 0.25
WHERE name IN (
  'Banana', 'Maçã', 'Laranja', 'Limão', 'Uva',
  'Manga', 'Mamão', 'Pera', 'Kiwi', 'Morango'
);
```

### Folhas (peso menor)
```sql
UPDATE products SET
  sell_by = 'weight',
  price_per_kg = [preço],
  min_weight = 0.1,    -- 100g mínimo
  step_weight = 0.1    -- Incremento de 100g
WHERE name IN (
  'Rúcula', 'Agrião', 'Espinafre', 'Couve'
);
```

## 🎨 Personalização

### Alterar Incremento

Para produtos mais leves, use incremento menor:

```sql
-- Rúcula: incremento de 100g
UPDATE products SET
  min_weight = 0.1,
  step_weight = 0.1
WHERE name = 'Rúcula';
```

### Alterar Atalhos Rápidos

Edite o arquivo `src/components/WeightPickerModal.tsx`:

```typescript
// Para produtos leves (folhas)
const QUICK_WEIGHTS = [0.1, 0.2, 0.3, 0.5, 0.75, 1];

// Para produtos pesados (batata, cebola)
const QUICK_WEIGHTS = [0.5, 1, 1.5, 2, 3, 5];
```

## 📦 Pedido Final

Quando o cliente finaliza o pedido, o sistema salva:

```json
{
  "product_id": "tomate-123",
  "product_name": "Tomate",
  "quantity": 1,
  "weight_kg": 0.5,
  "price_per_kg": 8.90,
  "price": 4.45,
  "sold_by": "weight"
}
```

## ✅ Resumo - Sistema Atual

| Funcionalidade | Status | Descrição |
|----------------|--------|-----------|
| Ver preço/kg | ✅ | Cliente vê R$ X,XX / kg |
| Escolher quantidade | ✅ | Botões +/- e atalhos rápidos |
| Cálculo automático | ✅ | Total = peso × preço/kg |
| Pagar pelo peso | ✅ | Valor calculado automaticamente |
| Alterar quantidade | ✅ | Botão "Alterar" no carrinho |
| Peso estimado | ✅ | Aviso de variação na balança |
| Múltiplos produtos | ✅ | Cada produto com seu peso |
| Total do carrinho | ✅ | Soma todos os itens |

## 🎯 Conclusão

**O sistema JÁ FUNCIONA exatamente como você descreveu!**

O cliente:
1. ✅ Vê o valor por kg
2. ✅ Escolhe a quantidade desejada
3. ✅ Sistema calcula o valor automaticamente
4. ✅ Paga pelo peso escolhido

Não é necessário nenhuma alteração adicional. O sistema está completo e funcional para venda por peso!

## 🧪 Como Testar

1. Acesse a loja: `http://localhost:8080/[slug-da-loja]`
2. Encontre um produto com `sell_by = 'weight'`
3. Clique em "Selecionar"
4. Escolha a quantidade (ex: 500g)
5. Veja o total calculado automaticamente
6. Clique em "Adicionar ao Carrinho"
7. Verifique o carrinho com o valor correto
8. Finalize o pedido

Tudo funcionando! 🎉
