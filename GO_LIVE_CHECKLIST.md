## Go-Live Checklist (Produção)

### 1) Rollback de migrations

- Gerar backup lógico antes de aplicar migrations:
  - `supabase db dump --linked --schema public --file backup_pre_go_live.sql`
- Aplicar migrations:
  - `supabase db push`
- Em caso de rollback, restaurar backup:
  - `supabase db reset --linked`
  - `psql "<connection-string>" -f backup_pre_go_live.sql`

### 2) Backup e restauração

- Backup diário automático (recomendado no provedor).
- Backup manual pré-release (obrigatório).
- Teste de restauração em ambiente de homologação (amostra de dados real anonimizada).

### 3) Validação de dados legados

- Executar migration:
  - `supabase/migrations/20260428000008_fix_legacy_needs_weighing_consistency.sql`
- Verificar inconsistência:
  - `supabase/verify_legacy_needs_weighing.sql`
- Critério de aceite:
  - `inconsistent_items = 0`

### 4) Testes automatizados

- Unit/integration:
  - `npm run test`
- E2E funcional crítico (cliente -> checkout -> admin -> entregador):
  - Definir variáveis:
    - `E2E_BASE_URL`
    - `E2E_STORE_SLUG`
    - `E2E_ADMIN_URL`
    - `E2E_ADMIN_EMAIL`
    - `E2E_ADMIN_PASSWORD`
  - Rodar:
    - `npm run test:e2e`

### 5) Observabilidade

- `favorites-api` retorna `x-request-id` para rastreio ponta a ponta.
- Configurar alerta de erro em produção:
  - Variável da Edge Function: `ALERT_WEBHOOK_URL`
- Confirmar ingestão de `audit_logs` e retenção mínima de 30 dias.

### 6) Performance em horário pico

- Rodar teste de carga com 3 níveis:
  - leve: 10 req/s por 5 min
  - médio: 30 req/s por 10 min
  - pico: 60 req/s por 15 min
- Monitorar:
  - p95 de latência
  - taxa de erro (4xx/5xx)
  - uso de CPU/memória
- Critério:
  - p95 < 800ms em APIs críticas
  - erro 5xx < 0.5%

### 7) Hardening de rotas não usadas

- Removidas rotas e páginas de entrega direta:
  - `/admin/direct-delivery`
  - `/delivery-tracking`
- Verificar se não há links quebrados no menu/admin.

### 8) Janela de release

- Janela recomendada: fora de horário de pico.
- Plano de comunicação com lojas.
- Plano de rollback pronto antes do deploy.
