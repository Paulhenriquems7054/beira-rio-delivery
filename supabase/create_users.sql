-- ============================================================
-- Script para criar usuários padrão de acesso ao painel
-- Execute na aba "SQL Editor" do seu painel Supabase
-- ============================================================

-- Habilitar a extensão pgcrypto (para criar senhas seguras localmente)
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- 1. Criar o usuário Admin (admin@admin.com | senha: admin123)
INSERT INTO auth.users (
  instance_id,
  id,
  aud,
  role,
  email,
  encrypted_password,
  email_confirmed_at,
  recovery_sent_at,
  last_sign_in_at,
  raw_app_meta_data,
  raw_user_meta_data,
  created_at,
  updated_at,
  confirmation_token,
  email_change,
  email_change_token_new,
  recovery_token
)
VALUES (
  '00000000-0000-0000-0000-000000000000',
  'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11',
  'authenticated',
  'authenticated',
  'admin@admin.com',
  crypt('admin123', gen_salt('bf')),
  current_timestamp,
  NULL,
  NULL,
  '{"provider":"email","providers":["email"]}',
  '{}',
  current_timestamp,
  current_timestamp,
  '',
  '',
  '',
  ''
)
ON CONFLICT (id) DO NOTHING;

-- 2. Criar o usuário Desenvolvedor (dev@dev.com | senha: dev123)
INSERT INTO auth.users (
  instance_id,
  id,
  aud,
  role,
  email,
  encrypted_password,
  email_confirmed_at,
  recovery_sent_at,
  last_sign_in_at,
  raw_app_meta_data,
  raw_user_meta_data,
  created_at,
  updated_at,
  confirmation_token,
  email_change,
  email_change_token_new,
  recovery_token
)
VALUES (
  '00000000-0000-0000-0000-000000000000',
  'd0eebc99-9c0b-4ef8-bb6d-6bb9bd380a22',
  'authenticated',
  'authenticated',
  'dev@dev.com',
  crypt('dev123', gen_salt('bf')),
  current_timestamp,
  NULL,
  NULL,
  '{"provider":"email","providers":["email"]}',
  '{}',
  current_timestamp,
  current_timestamp,
  '',
  '',
  '',
  ''
)
ON CONFLICT (id) DO NOTHING;

-- 3. Inserir a Identidade do Usuário (obrigatório nas atualizações recentes do Supabase Auth para funcionar o login)
INSERT INTO auth.identities (id, provider_id, user_id, identity_data, provider, last_sign_in_at, created_at, updated_at)
SELECT id, id::text, id, format('{"sub":"%s","email":"%s"}', id::text, email)::jsonb, 'email', current_timestamp, current_timestamp, current_timestamp
FROM auth.users WHERE email IN ('admin@admin.com', 'dev@dev.com')
ON CONFLICT (provider_id, provider) DO NOTHING;
