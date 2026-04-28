## admin-delete-store

Edge Function administrativa para excluir loja com privilégios de service role.

### Segurança

- JWT obrigatório
- autorização por:
  - `app_metadata.role = "superadmin"` OU
  - email no allowlist (`SUPERADMIN_ALLOWLIST_EMAILS`)

### Variáveis obrigatórias

- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`
- `SUPABASE_SERVICE_ROLE_KEY`
- `SUPERADMIN_ALLOWLIST_EMAILS` (lista separada por vírgula)

Exemplo:

```bash
supabase secrets set SUPERADMIN_ALLOWLIST_EMAILS="dev@empresa.com,admin@empresa.com"
```

### Deploy

```bash
supabase functions deploy admin-delete-store
```
