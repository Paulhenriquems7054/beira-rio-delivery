-- Migration: Create storage bucket for receipt photos
-- Cria bucket público para armazenar fotos de cupons fiscais

-- Cria o bucket se não existir
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'order-receipts',
  'order-receipts',
  true, -- público para clientes visualizarem
  5242880, -- 5MB limit
  ARRAY['image/jpeg', 'image/jpg', 'image/png', 'image/webp']
)
ON CONFLICT (id) DO NOTHING;

-- Política: Admin pode fazer upload
CREATE POLICY "Admin can upload receipt photos"
ON storage.objects
FOR INSERT
WITH CHECK (
  bucket_id = 'order-receipts'
  AND auth.role() = 'authenticated'
  AND (storage.foldername(name))[1] = 'receipts'
);

-- Política: Todos podem visualizar (bucket público)
CREATE POLICY "Anyone can view receipt photos"
ON storage.objects
FOR SELECT
USING (bucket_id = 'order-receipts');

-- Política: Admin pode deletar suas fotos
CREATE POLICY "Admin can delete their receipt photos"
ON storage.objects
FOR DELETE
USING (
  bucket_id = 'order-receipts'
  AND auth.role() = 'authenticated'
);
