## Favorites API Edge Function

Endpoint base: `/functions/v1/favorites-api`

### Segurança

- JWT obrigatório (`Authorization: Bearer <token>`)
- `tenant_id` resolvido por:
  - header `x-tenant-id` (prioridade)
  - `app_metadata.tenant_id` ou `user_metadata.tenant_id` no token
- bloqueio de acesso cross-tenant via validação em `stores.user_id`
- auditoria por request em `public.audit_logs`

### Rotas

- `GET /favorites?customerPhone=+5511999999999`
- `POST /favorites`
  - body: `{ "customerPhone": "+5511999999999", "productId": "uuid" }`
- `DELETE /favorites/:favoriteId`

### Deploy

```bash
supabase functions deploy favorites-api
```

### Teste rápido

```bash
curl -X POST "https://<project-ref>.supabase.co/functions/v1/favorites-api/favorites" \
  -H "Authorization: Bearer <JWT>" \
  -H "x-tenant-id: <tenant-uuid>" \
  -H "Content-Type: application/json" \
  -d '{"customerPhone":"+5511999999999","productId":"550e8400-e29b-41d4-a716-446655440000"}'
```
