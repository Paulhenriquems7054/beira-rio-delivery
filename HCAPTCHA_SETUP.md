# Configuração do hCaptcha - Guia Completo

O hCaptcha é usado na página "Rastrear Pedido" para proteger contra bots e abusos. Atualmente está configurado com uma chave de TESTE que funciona apenas localmente.

## 📋 Passo a Passo

### 1. Criar Conta no hCaptcha

1. Acesse: https://www.hcaptcha.com/
2. Clique em "Sign Up" (Cadastrar)
3. Preencha seus dados e confirme o email

### 2. Obter as Chaves (Site Key e Secret Key)

1. Faça login em: https://dashboard.hcaptcha.com/
2. Clique em "New Site" (Novo Site)
3. Preencha as informações:
   - **Hostname**: `horti-delivery-lite.vercel.app` (ou seu domínio)
   - **Site Name**: `HortiDelivery - Rastreamento`
   - **Passing Threshold**: Deixe o padrão (Easy)
4. Clique em "Save"
5. Você receberá duas chaves:
   - **Site Key** (pública) - usada no frontend
   - **Secret Key** (privada) - usada no backend (se necessário)

### 3. Configurar no Projeto Local

Edite o arquivo `.env` na raiz do projeto:

```env
# hCaptcha — substitua pela sua chave real
VITE_HCAPTCHA_SITE_KEY=sua-site-key-aqui
```

**Exemplo:**
```env
VITE_HCAPTCHA_SITE_KEY=a1b2c3d4-e5f6-7890-abcd-ef1234567890
```

### 4. Configurar no Vercel (Produção)

1. Acesse: https://vercel.com/
2. Vá no seu projeto
3. Clique em "Settings" > "Environment Variables"
4. Adicione a variável:
   - **Name**: `VITE_HCAPTCHA_SITE_KEY`
   - **Value**: `sua-site-key-aqui`
   - **Environment**: Marque "Production", "Preview" e "Development"
5. Clique em "Save"
6. Faça um novo deploy para aplicar as mudanças

### 5. Testar

1. Acesse a página de rastreamento: `/track`
2. Digite um telefone
3. Você verá o widget do hCaptcha
4. Complete o desafio
5. Clique em "Buscar"

## 🔑 Chaves Atuais

### Desenvolvimento (Local)
```
VITE_HCAPTCHA_SITE_KEY=10000000-ffff-ffff-ffff-000000000001
```
⚠️ Esta é uma chave de TESTE fornecida pelo hCaptcha. Funciona apenas em `localhost`.

### Produção
⚠️ **AÇÃO NECESSÁRIA**: Você precisa configurar uma chave real para produção.

## 📝 Onde o hCaptcha é Usado

**Arquivo**: `src/pages/OrderTracking.tsx`

```typescript
const HCAPTCHA_SITE_KEY = (import.meta as any).env?.VITE_HCAPTCHA_SITE_KEY ?? "10000000-ffff-ffff-ffff-000000000001";

<HCaptcha
  ref={captchaRef}
  sitekey={HCAPTCHA_SITE_KEY}
  onVerify={(token) => setCaptchaToken(token)}
  onExpire={() => setCaptchaToken(null)}
  size="normal"
/>
```

## 🎨 Personalização (Opcional)

Você pode personalizar o hCaptcha no dashboard:

1. **Tema**: Light ou Dark
2. **Idioma**: Português (pt-BR)
3. **Tamanho**: Normal, Compact ou Invisible
4. **Dificuldade**: Easy, Moderate ou Difficult

Para aplicar no código:

```typescript
<HCaptcha
  sitekey={HCAPTCHA_SITE_KEY}
  onVerify={(token) => setCaptchaToken(token)}
  onExpire={() => setCaptchaToken(null)}
  size="normal"
  theme="light"
  languageOverride="pt-BR"
/>
```

## 🔒 Segurança

### Boas Práticas

1. **Nunca exponha a Secret Key** no frontend
2. **Use variáveis de ambiente** para as chaves
3. **Configure domínios permitidos** no dashboard do hCaptcha
4. **Monitore o uso** no dashboard para detectar abusos

### Validação Backend (Opcional)

Se quiser validar o token no backend (recomendado para maior segurança):

```typescript
// Backend (Supabase Edge Function ou API)
const response = await fetch('https://hcaptcha.com/siteverify', {
  method: 'POST',
  headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
  body: `secret=${SECRET_KEY}&response=${captchaToken}`
});

const data = await response.json();
if (data.success) {
  // Token válido, prosseguir
} else {
  // Token inválido, rejeitar
}
```

## 🆓 Planos do hCaptcha

- **Free**: 1 milhão de solicitações/mês (suficiente para maioria dos projetos)
- **Pro**: Recursos avançados e mais solicitações
- **Enterprise**: Personalização completa

Para a maioria dos casos, o plano Free é suficiente.

## 🐛 Troubleshooting

### Erro: "Invalid site key"
- Verifique se a chave está correta no `.env`
- Confirme que o domínio está configurado no dashboard do hCaptcha
- Reinicie o servidor de desenvolvimento após alterar o `.env`

### hCaptcha não aparece
- Verifique se o pacote `@hcaptcha/react-hcaptcha` está instalado
- Confirme que a variável de ambiente está sendo lida corretamente
- Verifique o console do navegador para erros

### Erro: "Network error"
- Verifique sua conexão com a internet
- Confirme que o firewall não está bloqueando hcaptcha.com
- Tente limpar o cache do navegador

## 📚 Recursos Adicionais

- **Dashboard**: https://dashboard.hcaptcha.com/
- **Documentação**: https://docs.hcaptcha.com/
- **React Integration**: https://docs.hcaptcha.com/configuration#react
- **Suporte**: https://www.hcaptcha.com/support

## ✅ Checklist de Configuração

- [ ] Criar conta no hCaptcha
- [ ] Obter Site Key
- [ ] Adicionar `VITE_HCAPTCHA_SITE_KEY` no `.env` local
- [ ] Adicionar `VITE_HCAPTCHA_SITE_KEY` nas variáveis de ambiente do Vercel
- [ ] Configurar domínio permitido no dashboard do hCaptcha
- [ ] Testar localmente
- [ ] Fazer deploy e testar em produção
- [ ] (Opcional) Configurar validação backend

## 🚀 Próximos Passos

Após configurar o hCaptcha:

1. Teste a página de rastreamento em produção
2. Monitore o uso no dashboard do hCaptcha
3. Ajuste a dificuldade se necessário
4. Considere implementar validação backend para maior segurança
