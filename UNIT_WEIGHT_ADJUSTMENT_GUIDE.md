# 🎯 Ajuste de Peso para Compra por Unidade

## 📋 Cenário

**Problema:**
- Cliente escolhe "6 tomates" (por unidade)
- Sistema calcula: 6 × R$ 1,54 = R$ 9,24
- Mas o peso real dos 6 tomates pode ser diferente
- Admin precisa pesar e ajustar o valor final

**Solução:**
- Cliente faz pedido por unidade (quantidade)
- Pedido fica com status "pending" (aguardando pesagem)
- Admin pesa os produtos e atualiza o peso real
- Sistema recalcula o valor baseado no peso real
- Cliente vê o valor final atualizado

## 🔧 Implementação

### 1. Adicionar Campos na Tabela order_items

```sql
-- Adicionar campos para controle de pesagem
ALTER TABLE public.order_items ADD COLUMN IF NOT EXISTS needs_weighing BOOLEAN DEFAULT false;
ALTER TABLE public.order_items ADD COLUMN IF NOT EXISTS actual_weight_kg NUMERIC;
ALTER TABLE public.order_items ADD COLUMN IF NOT EXISTS estimated_price NUMERIC;
ALTER TABLE public.order_items ADD COLUMN IF NOT EXISTS final_price NUMERIC;

COMMENT ON COLUMN public.order_items.needs_weighing IS 'Se true, produto precisa ser pesado pelo admin';
COMMENT ON COLUMN public.order_items.actual_weight_kg IS 'Peso real após pesagem (preenchido pelo admin)';
COMMENT ON COLUMN public.order_items.estimated_price IS 'Preço estimado (quando cliente compra por unidade)';
COMMENT ON COLUMN public.order_items.final_price IS 'Preço final após pesagem';
```

### 2. Lógica de Criação do Pedido

Quando cliente compra por unidade:

```typescript
// Cliente escolhe: 6 tomates (por unidade)
const orderItem = {
  product_id: 'tomate-123',
  quantity: 6,
  sold_by: 'unit',
  needs_weighing: true,              // ← Marca que precisa pesar
  estimated_price: 6 * 1.54,         // R$ 9,24 (estimado)
  final_price: null,                 // ← Será preenchido após pesagem
  actual_weight_kg: null             // ← Será preenchido após pesagem
};
```

Quando cliente compra por peso:

```typescript
// Cliente escolhe: 1kg de tomate (por peso)
const orderItem = {
  product_id: 'tomate-123',
  quantity: 1,
  sold_by: 'weight',
  needs_weighing: false,             // ← Não precisa pesar (já selecionou peso)
  weight_kg: 1.0,
  estimated_price: 8.90,
  final_price: 8.90,                 // ← Já é o preço final
  actual_weight_kg: 1.0
};
```

### 3. Interface do Admin - Painel de Pesagem

Criar uma nova seção no painel admin para pesar produtos:

```typescript
// AdminWeighing.tsx
function AdminWeighing() {
  const pendingOrders = useOrdersNeedingWeighing();
  
  return (
    <div>
      <h2>Pedidos Aguardando Pesagem</h2>
      
      {pendingOrders.map(order => (
        <OrderWeighingCard 
          order={order}
          onWeigh={(itemId, weight) => updateItemWeight(itemId, weight)}
        />
      ))}
    </div>
  );
}
```

### 4. Card de Pesagem

```typescript
function OrderWeighingCard({ order, onWeigh }) {
  const itemsNeedingWeighing = order.items.filter(item => item.needs_weighing);
  
  return (
    <div className="border rounded-lg p-4">
      <h3>Pedido #{order.id}</h3>
      <p>Cliente: {order.customer_name}</p>
      
      {itemsNeedingWeighing.map(item => (
        <div key={item.id} className="mt-4 border-t pt-4">
          <p className="font-bold">{item.product_name}</p>
          <p className="text-sm text-gray-600">
            Quantidade: {item.quantity} unidades
          </p>
          <p className="text-sm text-gray-600">
            Preço estimado: R$ {item.estimated_price.toFixed(2)}
          </p>
          
          {/* Input de peso */}
          <div className="mt-2">
            <label>Peso real (kg):</label>
            <input 
              type="number" 
              step="0.01"
              placeholder="Ex: 0.85"
              onChange={(e) => {
                const weight = parseFloat(e.target.value);
                const finalPrice = weight * item.price_per_kg;
                onWeigh(item.id, weight, finalPrice);
              }}
            />
          </div>
          
          {item.actual_weight_kg && (
            <div className="mt-2 bg-green-50 p-2 rounded">
              <p className="text-sm">
                ✓ Peso: {item.actual_weight_kg}kg
              </p>
              <p className="text-sm font-bold">
                Valor final: R$ {item.final_price.toFixed(2)}
              </p>
            </div>
          )}
        </div>
      ))}
      
      {/* Botão para confirmar pesagem */}
      <button 
        onClick={() => confirmWeighing(order.id)}
        disabled={itemsNeedingWeighing.some(i => !i.actual_weight_kg)}
        className="mt-4 w-full bg-green-600 text-white py-2 rounded"
      >
        Confirmar Pesagem e Atualizar Pedido
      </button>
    </div>
  );
}
```

### 5. Função de Atualização

```typescript
async function updateItemWeight(itemId: string, weight: number, finalPrice: number) {
  const { error } = await supabase
    .from('order_items')
    .update({
      actual_weight_kg: weight,
      final_price: finalPrice,
      needs_weighing: false
    })
    .eq('id', itemId);
    
  if (!error) {
    // Recalcular total do pedido
    await recalculateOrderTotal(orderId);
  }
}

async function recalculateOrderTotal(orderId: string) {
  // Buscar todos os itens do pedido
  const { data: items } = await supabase
    .from('order_items')
    .select('final_price, estimated_price')
    .eq('order_id', orderId);
  
  // Somar preços finais (ou estimados se ainda não pesou)
  const total = items.reduce((sum, item) => {
    return sum + (item.final_price || item.estimated_price);
  }, 0);
  
  // Atualizar total do pedido
  await supabase
    .from('orders')
    .update({ total })
    .eq('id', orderId);
}
```

## 📱 Fluxo Completo

### Passo 1: Cliente Faz Pedido

```
Cliente escolhe:
- 6 tomates (por unidade)
- 4 cebolas (por unidade)
- 1kg batata (por peso)

Sistema cria pedido:
- Status: "pending"
- Total estimado: R$ 25,00
- Itens marcados com needs_weighing: true
```

### Passo 2: Admin Vê Pedido

```
Painel Admin > Pedidos Aguardando Pesagem

Pedido #1234
Cliente: João Silva

[ ] 6 tomates
    Estimado: R$ 9,24
    Peso real: [____] kg
    
[ ] 4 cebolas
    Estimado: R$ 6,00
    Peso real: [____] kg
    
[✓] 1kg batata (já pesado)
    Final: R$ 5,90
```

### Passo 3: Admin Pesa Produtos

```
Admin pesa:
- 6 tomates = 0.92kg
  Cálculo: 0.92 × R$ 8,90 = R$ 8,19
  
- 4 cebolas = 0.68kg
  Cálculo: 0.68 × R$ 6,50 = R$ 4,42
```

### Passo 4: Sistema Atualiza

```
Pedido #1234 atualizado:
- 6 tomates: R$ 8,19 (era R$ 9,24)
- 4 cebolas: R$ 4,42 (era R$ 6,00)
- 1kg batata: R$ 5,90
Total: R$ 18,51 (era R$ 25,00)
```

### Passo 5: Cliente Vê Atualização

```
Cliente acessa rastreamento:

Seu Pedido #1234
Status: Preparando

6 tomates - R$ 8,19 (0.92kg)
4 cebolas - R$ 4,42 (0.68kg)
1kg batata - R$ 5,90

Total: R$ 18,51
```

## 🎨 Interface do Cliente

### Antes da Pesagem

```
┌─────────────────────────────────┐
│ Pedido #1234                    │
│ Status: Aguardando Pesagem      │
│                                 │
│ 6 tomates                       │
│ Valor estimado: R$ 9,24         │
│ ⚖️ Aguardando pesagem           │
│                                 │
│ Total estimado: R$ 25,00        │
│ ⚠️ Valor pode variar            │
└─────────────────────────────────┘
```

### Após a Pesagem

```
┌─────────────────────────────────┐
│ Pedido #1234                    │
│ Status: Preparando              │
│                                 │
│ 6 tomates (0.92kg)              │
│ R$ 8,19                         │
│ ✓ Pesado                        │
│                                 │
│ Total: R$ 18,51                 │
└─────────────────────────────────┘
```

## 💡 Melhorias Adicionais

### 1. Notificação ao Cliente

```typescript
// Quando admin termina de pesar
async function notifyCustomerWeighingComplete(orderId: string) {
  const order = await getOrder(orderId);
  
  // Enviar notificação (WhatsApp, SMS, etc)
  await sendNotification(order.phone, 
    `Seu pedido #${orderId} foi pesado! ` +
    `Valor final: R$ ${order.total.toFixed(2)}`
  );
}
```

### 2. Tolerância de Variação

```typescript
// Alertar admin se variação for muito grande
function checkPriceVariation(estimated: number, final: number) {
  const variation = Math.abs((final - estimated) / estimated);
  
  if (variation > 0.15) { // 15% de variação
    return {
      alert: true,
      message: `Atenção: Variação de ${(variation * 100).toFixed(0)}%`
    };
  }
  
  return { alert: false };
}
```

### 3. Histórico de Pesagens

```sql
-- Tabela para auditoria
CREATE TABLE weighing_history (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_item_id UUID REFERENCES order_items(id),
  estimated_weight NUMERIC,
  actual_weight NUMERIC,
  estimated_price NUMERIC,
  final_price NUMERIC,
  weighed_by UUID REFERENCES auth.users(id),
  weighed_at TIMESTAMP DEFAULT NOW()
);
```

## ✅ Vantagens

1. **Transparência**: Cliente vê valor estimado e final
2. **Precisão**: Valor baseado no peso real
3. **Controle**: Admin confirma cada pesagem
4. **Rastreabilidade**: Histórico de ajustes
5. **Flexibilidade**: Cliente escolhe unidade, paga pelo peso real

## 🚀 Implementação Rápida

Para implementar rapidamente:

1. Execute a migração SQL (adicionar colunas)
2. Atualize a lógica de criação de pedidos
3. Crie a tela de pesagem no admin
4. Adicione notificação ao cliente (opcional)

## 📊 Exemplo Real

**Cliente pede:**
- 6 tomates (estimado: R$ 9,24)
- 4 cebolas (estimado: R$ 6,00)

**Admin pesa:**
- 6 tomates = 0.92kg → R$ 8,19 (economizou R$ 1,05)
- 4 cebolas = 0.75kg → R$ 4,88 (economizou R$ 1,12)

**Total:**
- Estimado: R$ 15,24
- Final: R$ 13,07
- Diferença: -R$ 2,17 (cliente pagou menos!)

Isso cria confiança e transparência! 🎉
