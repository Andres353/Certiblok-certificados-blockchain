-- Consulta para verificar dónde está el hash del certificado
-- Ejecutar en Supabase SQL Editor

-- 1. Ver todos los campos relacionados con hashes de un certificado específico
-- Reemplaza 'TU_CERTIFICATE_ID' con el ID del certificado que quieres verificar
SELECT 
    id,
    title,
    student_name,
    -- Hash único generado internamente
    unique_hash,
    LENGTH(unique_hash) as unique_hash_length,
    -- Hash SHA-256 del certificado (el que se usa en blockchain)
    blockchain_hash,
    LENGTH(blockchain_hash) as blockchain_hash_length,
    -- Red blockchain
    blockchain_network,
    -- Hash de transacción (puede estar en el campo data)
    data->>'blockchain_transaction_hash' as transaction_hash,
    LENGTH(data->>'blockchain_transaction_hash') as transaction_hash_length,
    -- Fecha de emisión
    issued_at,
    -- Estado
    status
FROM certificates
WHERE id = 'TU_CERTIFICATE_ID'  -- Reemplaza con el ID real
   OR title ILIKE '%TU_TITULO%'  -- O busca por título
ORDER BY issued_at DESC;

-- 2. Ver todos los certificados con sus hashes (últimos 10)
SELECT 
    id,
    title,
    student_name,
    unique_hash,
    blockchain_hash,
    blockchain_network,
    data->>'blockchain_transaction_hash' as transaction_hash,
    issued_at,
    status
FROM certificates
ORDER BY issued_at DESC
LIMIT 10;

-- 3. Buscar certificado por blockchain_hash (el SHA-256)
-- Reemplaza 'TU_HASH_AQUI' con el hash que quieres buscar
SELECT 
    id,
    title,
    student_name,
    unique_hash,
    blockchain_hash,
    blockchain_network,
    data->>'blockchain_transaction_hash' as transaction_hash,
    issued_at,
    status
FROM certificates
WHERE blockchain_hash = 'TU_HASH_AQUI'  -- El hash SHA-256 del certificado
   OR unique_hash = 'TU_HASH_AQUI';     -- O busca por unique_hash

-- 4. Ver certificados que NO tienen blockchain_hash (no están en blockchain)
SELECT 
    id,
    title,
    student_name,
    unique_hash,
    blockchain_hash,
    issued_at,
    status
FROM certificates
WHERE blockchain_hash IS NULL
   OR blockchain_hash = ''
ORDER BY issued_at DESC;

-- 5. Ver certificados que SÍ tienen blockchain_hash (están en blockchain)
SELECT 
    id,
    title,
    student_name,
    unique_hash,
    blockchain_hash,
    blockchain_network,
    data->>'blockchain_transaction_hash' as transaction_hash,
    issued_at,
    status
FROM certificates
WHERE blockchain_hash IS NOT NULL
  AND blockchain_hash != ''
ORDER BY issued_at DESC;

-- 6. Ver estructura completa del campo data (para ver si hay más hashes)
SELECT 
    id,
    title,
    data,
    blockchain_hash,
    unique_hash
FROM certificates
WHERE id = 'TU_CERTIFICATE_ID'  -- Reemplaza con el ID real
LIMIT 1;

