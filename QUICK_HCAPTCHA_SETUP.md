# ⚡ Configuração Rápida do hCaptcha

## 🎯 O que é?

O hCaptcha protege a página "Rastrear Pedido" contra bots e abusos.

## 🚀 Configuração em 3 Passos

### 1️⃣ Criar Conta e Obter Chave

1. Acesse: https://dashboard.hcaptcha.com/signup
2. Crie sua conta
3. Clique em "New Site"
4. Configure:
   - **Hostname**: `horti-delivery-lite.vercel.app`
   - **Site Name**: `HortiDelivery`
5. Copie a **Site Key** (algo como: `a1b2c3d4-e5f6-7890-abcd-ef1234567890`)

### 2️⃣ Configurar Localmente

Edite o arquivo `.env`:

```env
VITE_HCAPTCHA_SITE_KEY=cole-sua-site-key-aqui
```

### 3️⃣ Configurar no Vercel

1. Vá em: https://vercel.com/seu-projeto/settings/environment-variables
2. Adicione:
   - **Name**: `VITE_HCAPTCHA_SITE_KEY`
   - **Value**: `sua-site-key`
3. Marque: Production, Preview, Development
4. Salve e faça redeploy

## ✅ Pronto!

Acesse `/track` e você verá o hCaptcha funcionando.

## 📝 Nota

A chave atual (`10000000-ffff-ffff-ffff-000000000001`) é de TESTE e só funciona em localhost.

## 🆓 É Grátis?

Sim! O plano Free oferece 1 milhão de solicitações/mês.

## 🔗 Links Úteis

- Dashboard: https://dashboard.hcaptcha.com/
- Documentação: https://docs.hcaptcha.com/
- Guia Completo: Veja `HCAPTCHA_SETUP.md`
