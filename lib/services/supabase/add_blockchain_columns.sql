-- Script para agregar columnas blockchain a la tabla certificates
-- Ejecutar en Supabase SQL Editor

-- Agregar columnas blockchain
ALTER TABLE certificates 
ADD COLUMN IF NOT EXISTS blockchain_hash TEXT,
ADD COLUMN IF NOT EXISTS blockchain_network VARCHAR(50);

-- Crear índice para búsquedas rápidas por blockchain hash
CREATE INDEX IF NOT EXISTS idx_certificates_blockchain_hash 
ON certificates(blockchain_hash) 
WHERE blockchain_hash IS NOT NULL;

-- Comentarios para documentación
COMMENT ON COLUMN certificates.blockchain_hash IS 'Hash de transacción blockchain (Polygon)';
COMMENT ON COLUMN certificates.blockchain_network IS 'Red blockchain usada (polygon-mumbai o polygon-mainnet)';

