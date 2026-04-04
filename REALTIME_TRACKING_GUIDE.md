# 📦 Sistema de Acompanhamento em Tempo Real

## Visão Geral

O sistema agora possui acompanhamento em tempo real de pedidos para os clientes, permitindo que eles vejam o status atualizado automaticamente sem precisar recarregar a página.

## Como Funciona

### 1. Fluxo do Cliente

#### Após Fazer o Pedido
1. Cliente finaliza o pedido na página da loja (`/:slug`)
2. Na tela de confirmação, aparece:
   - Detalhes completos do pedido
   - Total calculado (itens por peso)
   - Aviso sobre itens que precisam ser pesados
   - **Botão "Acompanhar Pedido em Tempo Real"**
   - Telefone usado no pedido (para rastreamento)

#### Acompanhamento em Tempo Real
1. Cliente clica em "Acompanhar Pedido em Tempo Real"
2. É redirecionado para `/:slug/pedido/:orderId?phone=xxx`
3. Vê seu pedido específico com status atual
4. **Status atualiza automaticamente** quando o admin muda no sistema

### 2. Timeline de Status

O sistema mostra 4 etapas visuais:

```
📦 Recebido → 🧑‍🍳 Separando → 🛵 Na Rota → ✅ Entregue
```

#### Status Disponíveis:
- **pending** (Recebido): Pedido foi recebido, aguardando confirmação
- **preparing** (Separando): Loja está separando os produtos
- **delivering** (Na Rota): Entregador está a caminho
- **delivered** (Entregue): Pedido foi entregue

### 3. Atualização em Tempo Real

#### Tecnologia: Supabase Realtime
```typescript
const channel = supabase
  .channel(`customer-orders-${phone}`)
  .on(
    "postgres_changes",
    { 
      event: "UPDATE", 
      schema: "public", 
      table: "orders", 
      filter: `phone=eq.${phone}` 
    },
    (payload) => {
      // Atualiza o pedido na lista
      setOrders(prev =>
        prev.map(o => o.id === payload.new.id ? { ...o, ...payload.new } : o)
      );
      // Mostra notificação
      toast.success(`Pedido atualizado: ${step.label}!`);
    }
  )
  .subscribe();
```

#### O que acontece:
1. Cliente está na página de rastreamento
2. Admin muda o status do pedido no painel admin
3. **Instantaneamente** o status é atualizado na tela do cliente
4. Cliente recebe uma notificação toast
5. Timeline visual é atualizada automaticamente

### 4. Indicador Visual de Conexão

Na lista de pedidos, aparece um indicador verde pulsante:
```
🟢 Atualização automática
```

Isso mostra ao cliente que a conexão em tempo real está ativa.

## Rotas Configuradas

### Rastreamento do Cliente (Público)
- `/:slug/pedido/:orderId?phone=xxx` - Página de rastreamento individual do pedido
  - Acesso direto ao pedido específico
  - Mostra nome e logo da loja no cabeçalho
  - Atualização em tempo real do status
  - Lista completa de itens do pedido
  - Botão para voltar à loja
  - **Sem barreiras** (link direto após fazer pedido)

### Rastreamento Admin (Busca por Telefone)
- `/:slug/rastrear` - Página de busca de pedidos por telefone
  - Requer apenas o telefone
  - Mostra todos os pedidos daquele telefone
  - Usado quando cliente perde o link direto

### Rastreamento Global
- `/track` - Página de rastreamento sem contexto de loja (legado)

## Segurança

### Filtro por Telefone
- Clientes só veem pedidos do próprio telefone
- Não é possível ver pedidos de outros clientes
- Validação no backend via RLS (Row Level Security)
- Busca simples e direta sem barreiras adicionais

## Informações Exibidas

Para cada pedido, o cliente vê:

### Cabeçalho
- ID do pedido (primeiros caracteres)
- Nome do cliente
- Valor total

### Detalhes
- 📍 Endereço de entrega
- 🕐 Data e hora do pedido
- 📦 Status atual (timeline visual)
- 📝 Observações (se houver)

### Timeline Interativa
- Barra de progresso visual
- Ícones coloridos para cada etapa
- Etapa atual destacada com animação
- Mensagem contextual do status

## Fluxo Completo

```
1. Cliente faz pedido
   ↓
2. Tela de confirmação (mostra detalhes do pedido)
   ↓
3. Clica "Acompanhar Pedido em Tempo Real"
   ↓
4. Redirecionado para /:slug/pedido/:orderId?phone=xxx
   ↓
5. Vê pedido específico com status atual
   ↓
6. Admin atualiza status no painel
   ↓
7. Cliente vê atualização INSTANTÂNEA
   ↓
8. Recebe notificação visual da mudança
```

### Diferença entre as Páginas

#### CustomerTracking (/:slug/pedido/:orderId)
- ✅ Acesso direto ao pedido específico
- ✅ Sem barreiras de segurança
- ✅ Link é fornecido após fazer o pedido
- ✅ Mostra itens completos do pedido
- ✅ Atualização em tempo real
- ✅ Experiência focada no cliente

#### OrderTracking (/:slug/rastrear)
- ✅ Busca por telefone
- ✅ Mostra todos os pedidos do telefone
- ✅ Usado quando cliente perde o link
- ✅ Mais genérico

## Benefícios

### Para o Cliente
- ✅ Transparência total do processo
- ✅ Sem necessidade de ligar para a loja
- ✅ Atualizações instantâneas
- ✅ Interface visual clara e intuitiva
- ✅ Histórico de todos os pedidos

### Para a Loja
- ✅ Reduz ligações de clientes perguntando sobre status
- ✅ Melhora a experiência do cliente
- ✅ Aumenta a confiança na loja
- ✅ Profissionaliza o atendimento

## Próximos Passos (Opcional)

### Melhorias Futuras
1. **Notificações Push**: Avisar cliente quando status mudar (mesmo fora da página)
2. **Estimativa de Tempo**: Mostrar tempo estimado para cada etapa
3. **Localização do Entregador**: Mapa em tempo real (quando "Na Rota")
4. **Chat com a Loja**: Comunicação direta na página de rastreamento
5. **Histórico de Mudanças**: Log de quando cada status foi alterado

## Troubleshooting

### Cliente não vê atualizações
1. Verificar se o telefone está correto
2. Verificar conexão com internet
3. Recarregar a página
4. Verificar se o Supabase Realtime está habilitado

### Status não atualiza
1. Verificar se o admin realmente salvou a mudança
2. Verificar logs do Supabase
3. Verificar se a tabela `orders` tem RLS configurado corretamente

## Código Relevante

### Arquivos Principais
- `src/pages/Index.tsx` - Tela de confirmação com botão de rastreamento
- `src/pages/CustomerTracking.tsx` - **Página de rastreamento individual do cliente** (NOVA)
- `src/pages/OrderTracking.tsx` - Página de busca por telefone (admin/genérica)
- `src/App.tsx` - Configuração de rotas
- `src/hooks/useStoreInfo.ts` - Hook para buscar informações da loja

### Hook de Realtime (CustomerTracking)
```typescript
function useRealtimeOrder(orderId: string, phone: string) {
  const [order, setOrder] = useState<Order | null>(null);

  useEffect(() => {
    // Busca inicial com itens
    supabase.from("orders")
      .select(`*, order_items(*, product:products(name))`)
      .eq("id", orderId)
      .eq("phone", phone)
      .single()
      .then(({ data }) => setOrder(data));

    // Realtime - atualiza status
    const channel = supabase
      .channel(`customer-order-${orderId}`)
      .on("postgres_changes", { 
        event: "UPDATE", 
        table: "orders", 
        filter: `id=eq.${orderId}` 
      }, (payload) => {
        setOrder(prev => ({ ...prev, ...payload.new }));
      })
      .on("postgres_changes", { 
        event: "*", 
        table: "order_items", 
        filter: `order_id=eq.${orderId}` 
      }, () => {
        // Recarrega itens quando houver mudança (pesagem)
      })
      .subscribe();

    return () => { supabase.removeChannel(channel); };
  }, [orderId, phone]);

  return { order };
}
```

## Conclusão

O sistema de acompanhamento em tempo real oferece uma experiência moderna e profissional para os clientes, reduzindo a necessidade de contato telefônico e aumentando a transparência do processo de entrega. A tecnologia Supabase Realtime garante atualizações instantâneas sem necessidade de polling ou recarregamento de página.
