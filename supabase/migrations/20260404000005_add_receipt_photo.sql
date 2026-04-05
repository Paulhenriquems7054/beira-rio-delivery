-- Migration: Add receipt photo support to orders
-- Permite que o admin tire foto do cupom/nota fiscal e o cliente visualize

-- Adiciona coluna para armazenar URL da foto do cupom
ALTER TABLE orders
ADD COLUMN receipt_photo_url TEXT,
ADD COLUMN receipt_uploaded_at TIMESTAMPTZ,
ADD COLUMN receipt_total DECIMAL(10,2); -- Total do cupom para conferência

-- Comentários
COMMENT ON COLUMN orders.receipt_photo_url IS 'URL da foto do cupom/nota fiscal tirada pelo admin';
COMMENT ON COLUMN orders.receipt_uploaded_at IS 'Data/hora do upload da foto do cupom';
COMMENT ON COLUMN orders.receipt_total IS 'Valor total do cupom fiscal para conferência';

-- Índice para buscar pedidos com cupom
CREATE INDEX idx_orders_receipt_photo ON orders(receipt_photo_url) WHERE receipt_photo_url IS NOT NULL;

-- RLS: Admin pode fazer upload de fotos
CREATE POLICY "Admin can upload receipt photos"
ON orders
FOR UPDATE
USING (
  EXISTS (
    SELECT 1 FROM stores
    WHERE stores.id = orders.store_id
    AND stores.user_id = auth.uid()
  )
);

-- RLS: Cliente pode ver foto do seu cupom
CREATE POLICY "Customer can view their receipt photo"
ON orders
FOR SELECT
USING (
  receipt_photo_url IS NOT NULL
);
