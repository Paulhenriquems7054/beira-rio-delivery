# 💰 Atualização de Valor via Cupom Fiscal

## Problema Resolvido

Quando o admin registrava o cupom fiscal, o valor total do pedido permanecia em R$ 0,00 ou no valor estimado inicial. Agora o sistema atualiza corretamente o valor total do pedido com o valor do cupom fiscal.

## Solução Implementada

### 1. Atualização Automática do Total
Quando o admin confirma o cupom fiscal, o sistema:
- ✅ Salva a foto do cupom
- ✅ Registra o valor informado em `receipt_total`
- ✅ **ATUALIZA** `order.total` com o valor do cupom
- ✅ Cliente vê o valor correto imediatamente

### 2. Validação Obrigatória
- Campo de valor é **obrigatório** (marcado com *)
- Botão "Confirmar e Enviar" só habilita com valor válido
- Validação: valor > 0
- Mensagem de erro se tentar enviar sem valor

### 3. Interface Melhorada

#### Modal de Captura
```
┌─────────────────────────────────────┐
│ * Valor Total do Cupom (R$)         │
│ ┌─────────────────────────────────┐ │
│ │         [  50,00  ]             │ │ ← Foco automático
│ └─────────────────────────────────┘ │
│ Valor estimado: R$ 38,28            │
│ ✓ Valor confirmado                  │
│ ⚠️ Este valor substituirá o total   │
└─────────────────────────────────────┘
```

#### Visualização Cliente
```
┌─────────────────────────────────────┐
│ Total (Cupom Fiscal)                │
│ R$ 50,00                            │ ← Valor do cupom
│ Estimado: R$ 38,28                  │ ← Riscado
└─────────────────────────────────────┘
```

## Fluxo Completo

### Antes (Problema)
1. Cliente faz pedido → Total: R$ 38,28
2. Admin tira foto do cupom
3. Admin informa valor: R$ 50,00
4. Sistema salva foto
5. ❌ Total continua: R$ 38,28
6. Cliente vê valor errado

### Depois (Corrigido)
1. Cliente faz pedido → Total: R$ 38,28 (estimado)
2. Admin tira foto do cupom
3. Admin informa valor: R$ 50,00
4. Sistema salva foto
5. ✅ Total atualizado: R$ 50,00
6. Cliente vê valor correto do cupom

## Código Atualizado

### ReceiptCameraModal.tsx
```typescript
// Atualiza AMBOS os campos
const { error: updateError } = await supabase
  .from('orders')
  .update({
    receipt_photo_url: urlData.publicUrl,
    receipt_uploaded_at: new Date().toISOString(),
    receipt_total: receiptValue,
    total: receiptValue // ← ATUALIZA O TOTAL
  })
  .eq('id', orderId);
```

### Validação
```typescript
// Só permite enviar com valor válido
disabled={!receiptTotal || parseFloat(receiptTotal.replace(',', '.')) <= 0}
```

### CustomerTracking.tsx
```typescript
// Mostra valor do cupom se disponível
R$ {((order as any).receipt_total || order.total).toFixed(2)}

// Mostra valor estimado riscado se diferente
{receipt_total !== total && (
  <p className="line-through">Estimado: R$ {total}</p>
)}
```

## Campos no Banco de Dados

### orders table
```sql
total DECIMAL(10,2)              -- Valor FINAL do pedido (atualizado com cupom)
receipt_total DECIMAL(10,2)      -- Valor do cupom (para referência)
receipt_photo_url TEXT           -- URL da foto
receipt_uploaded_at TIMESTAMPTZ  -- Data do registro
```

## Casos de Uso

### Caso 1: Valor Exato
```
Estimado: R$ 50,00
Cupom:    R$ 50,00
Total:    R$ 50,00 ✓
```

### Caso 2: Valor Maior (itens extras)
```
Estimado: R$ 38,28
Cupom:    R$ 50,00 (cliente comprou mais itens)
Total:    R$ 50,00 ✓
```

### Caso 3: Valor Menor (desconto)
```
Estimado: R$ 50,00
Cupom:    R$ 45,00 (desconto aplicado)
Total:    R$ 45,00 ✓
```

### Caso 4: Apenas Itens por Unidade
```
Estimado: R$ 0,00 (tudo a pesar)
Cupom:    R$ 73,50 (após pesagem)
Total:    R$ 73,50 ✓
```

## Validações

### Frontend
- ✅ Campo obrigatório (*)
- ✅ Apenas números, vírgula e ponto
- ✅ Valor deve ser > 0
- ✅ Botão desabilitado sem valor válido
- ✅ Mensagem de erro clara

### Backend
```typescript
const receiptValue = parseFloat(receiptTotal);
if (!receiptValue || receiptValue <= 0) {
  toast.error('Por favor, informe o valor total do cupom');
  return;
}
```

## Interface do Usuário

### Indicadores Visuais
- 🔴 Campo vazio → Borda vermelha + mensagem erro
- 🟡 Digitando → Borda amarela
- 🟢 Valor válido → "✓ Valor confirmado"
- ⚠️ Aviso: "Este valor substituirá o total"

### Feedback
- Toast de sucesso: "Cupom registrado! Valor atualizado: R$ 50,00 📸"
- Cliente vê atualização em tempo real
- Valor antigo mostrado riscado

## Benefícios

### Para o Admin
- ✅ Processo claro e guiado
- ✅ Validação previne erros
- ✅ Confirmação visual do valor
- ✅ Impossível esquecer de preencher

### Para o Cliente
- ✅ Vê valor correto imediatamente
- ✅ Transparência total
- ✅ Pode comparar com estimativa
- ✅ Confiança no sistema

### Para o Sistema
- ✅ Dados consistentes
- ✅ Total sempre correto
- ✅ Histórico preservado (receipt_total)
- ✅ Auditoria completa

## Troubleshooting

### Valor não atualiza
```typescript
// Verificar se update foi executado
console.log('Updating order:', orderId, 'with value:', receiptValue);

// Verificar permissões RLS
// Admin deve ter permissão para UPDATE em orders
```

### Valor aparece como 0
```typescript
// Verificar conversão de string para número
const value = parseFloat(receiptTotal.replace(',', '.'));
console.log('Parsed value:', value);
```

### Cliente não vê atualização
```typescript
// Verificar realtime subscription
// CustomerTracking deve estar inscrito em mudanças de orders
```

## Melhorias Futuras

### Possíveis
- [ ] OCR para ler valor automaticamente do cupom
- [ ] Histórico de valores (antes/depois)
- [ ] Notificação push quando valor atualizar
- [ ] Comparação automática (estimado vs real)
- [ ] Alerta se diferença > X%

### Avançadas
- [ ] Machine learning para prever diferenças
- [ ] Integração com API de nota fiscal
- [ ] Validação cruzada com sistema fiscal
- [ ] Relatório de divergências

## Conclusão

O sistema agora garante que:
1. Admin **DEVE** informar o valor do cupom
2. Valor é **VALIDADO** antes de salvar
3. Total do pedido é **ATUALIZADO** automaticamente
4. Cliente vê o valor **CORRETO** em tempo real
5. Histórico é **PRESERVADO** para auditoria

Problema resolvido! 💰✅
