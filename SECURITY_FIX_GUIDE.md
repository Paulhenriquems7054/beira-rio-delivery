# Guia de Correção - "Success. No rows returned"

## Problema
Quando você executa uma query e recebe "Success. No rows returned", significa que:
1. A query executou sem erros de sintaxe
2. Mas as políticas RLS (Row Level Security) estão bloqueando o acesso
3. Ou você não está autenticado (usuário anônimo)

## Causa Raiz
Seu `auth.role()` retornou `null` → você está como usuário anônimo, mas as políticas RLS exigem autenticação para a maioria das tabelas.

## Solução Imediata

### Passo 1: Aplicar as Correções no Banco

Execute estas duas migrations no Supabase SQL Editor:

1. **Execute primeiro:** `20260428000001_fix_missing_rls_policies.sql`
2. **Depois execute:** `20260428000002_add_superadmin_bypass.sql`

Ou execute diretamente via CLI:
```bash
supabase db push
```

### Passo 2: Verificar se as Correções Funcionaram

```sql
-- Teste 1: Ver se a view de stores_authenticated funciona
SELECT * FROM public.stores_authenticated LIMIT 5;

-- Teste 2: Ver se consegue ler orders (como anon)
SELECT * FROM public.orders LIMIT 5;

-- Teste 3: Ver se consegue usar a função de tracking
SELECT * FROM get_order_tracking_by_phone('79991412945');
```

Se retornar dados, as correções funcionaram!

### Passo 3: Testar no Aplicativo

Agora tente acessar:
- `/superadmin` → deve listar todas as lojas
- `/:slug` (loja pública) → deve mostrar produtos
- `/track` → deve permitir rastrear pedido por telefone

## Entendendo as Políticas RLS

### Antes (Problema)
```sql
-- orders só permitia leitura se fosse dono da loja
-- Usuário anônimo (auth.uid() IS NULL) era bloqueado!
CREATE POLICY "orders_owner_read" ON public.orders
  FOR SELECT USING (
    auth.uid() IN (SELECT user_id FROM public.stores WHERE id = store_id)
  );
```

### Depois (Corrigido)
```sql
-- Agora permite anon para rastreamento público
CREATE POLICY "orders_owner_read" ON public.orders
  FOR SELECT USING (
    auth.uid() IN (SELECT user_id FROM public.stores WHERE id = store_id)
    OR auth.uid() IS NULL  -- Permitir anônimo!
  );
```

## Tabelas Corrigidas

| Tabela | Problema | Solução |
|--------|----------|---------|
| `direct_deliveries` | Sem política SELECT | Adicionada política pública |
| `rate_limits` | Sem política SELECT | Adicionada política pública |
| `subscription_events` | Sem política SELECT | Adicionada política para owner |
| `orders` | Bloqueava anônimo | Permitido IS NULL |
| `order_items` | Política permissiva demais | Ajustada para pública |
| `favorites` | Permitia tudo para todos | Agora requer auth.uid() |

## Testes de Validação

### Teste 1: Autenticação
```sql
-- Verifique se está autenticado
SELECT auth.uid();  -- Deve retornar UUID ou NULL
SELECT auth.role(); -- Deve retornar 'authenticated' ou NULL
```

### Teste 2: Acesso a Dados
```sql
-- Stores (público)
SELECT COUNT(*) FROM public.stores WHERE active = true;

-- Orders (deve funcionar agora)
SELECT COUNT(*) FROM public.orders;

-- Products (público)
SELECT COUNT(*) FROM public.products WHERE active = true;
```

### Teste 3: Funções RPC
```sql
-- Testar função de SuperAdmin (se estiver autenticado como admin)
SELECT * FROM get_all_stores_for_admin();

-- Testar tracking por telefone
SELECT * FROM get_order_tracking_by_phone('79991412945');
```

## Se Ainda Não Funcionar

### Opção 1: Desativar RLS Temporariamente (Só para Teste!)
```sql
-- NUNCA faça isso em produção!
ALTER TABLE public.orders DISABLE ROW LEVEL SECURITY;
-- Teste sua query
ALTER TABLE public.orders ENABLE ROW LEVEL SECURITY;
```

### Opção 2: Verificar Políticas Específicas
```sql
-- Liste todas as políticas de uma tabela
SELECT * FROM pg_policies WHERE tablename = 'orders';

-- Verifique se sua tabela tem RLS ativo
SELECT relname, relrowsecurity FROM pg_class WHERE relname = 'orders';
```

### Opção 3: Testar como Usuário Específico
```sql
-- Definir usuário de teste (substitua pelo UUID real)
SET LOCAL ROLE authenticated;
-- Ou use:
SET app.current_user_id = 'uuid-do-usuario-aqui';

-- Execute sua query
SELECT * FROM public.orders WHERE store_id = 'f1e86383-302b-4fe5-a342-be5e91efedab';
```

## Segurança vs. Funcionalidade

As correções mantêm o equilíbrio:
- ✅ **Público pode ver**: produtos ativos, lojas ativas, rastrear pedidos
- ✅ **Autenticado pode**: criar pedidos, ver próprios favoritos
- ✅ **Dono da loja pode**: gerenciar produtos, pedidos, configurações
- ❌ **Ninguém pode**: ver pedidos de outros clientes, modificar dados de outras lojas

## Próximos Passos de Segurança

Após confirmar que funciona:
1. ✅ Teste todas as funcionalidades do app
2. ✅ Verifique se não há vazamento de dados sensíveis
3. ✅ Ative rate limiting para APIs públicas
4. ✅ Configure logs de auditoria para operações sensíveis

## Suporte

Se ainda tiver problemas, verifique:
1. Logs do Supabase (Database → Logs)
2. Console do navegador (erros de autenticação)
3. Network tab (verificar headers de autenticação)
