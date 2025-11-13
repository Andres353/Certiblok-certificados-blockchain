-- Consulta SQL para verificar certificados emitidos en blockchain
-- Ejecutar en Supabase SQL Editor

-- Ver todos los certificados con información de blockchain
SELECT 
    id,
    unique_hash,
    blockchain_hash,
    blockchain_network,
    student_name,
    institution_name,
    title,
    certificate_type,
    issued_at,
    created_at,
    CASE 
        WHEN blockchain_hash IS NOT NULL THEN '✅ En Blockchain'
        ELSE '❌ Solo en BD'
    END as estado_blockchain
FROM certificates
ORDER BY created_at DESC
LIMIT 50;

-- Ver solo certificados que están en blockchain
SELECT 
    id,
    unique_hash,
    blockchain_hash,
    blockchain_network,
    student_name,
    institution_name,
    title,
    certificate_type,
    issued_at,
    'https://polygonscan.com/tx/' || blockchain_hash as enlace_polygonscan
FROM certificates
WHERE blockchain_hash IS NOT NULL
ORDER BY created_at DESC;

-- Estadísticas de certificados en blockchain
SELECT 
    COUNT(*) as total_certificados,
    COUNT(blockchain_hash) as en_blockchain,
    COUNT(*) - COUNT(blockchain_hash) as solo_en_bd,
    ROUND(COUNT(blockchain_hash)::numeric / COUNT(*)::numeric * 100, 2) as porcentaje_en_blockchain
FROM certificates;

-- Ver el último certificado emitido (el que acabas de crear)
SELECT 
    id,
    unique_hash,
    blockchain_hash,
    blockchain_network,
    student_name,
    institution_name,
    title,
    certificate_type,
    issued_at,
    created_at,
    'https://polygonscan.com/tx/' || blockchain_hash as verificar_en_polygonscan
FROM certificates
WHERE id = 'e8111ffe-38c8-4b70-8bd5-676e53d62091';  -- Reemplaza con el ID de tu certificado

-- Ver certificados por institución con blockchain
SELECT 
    institution_name,
    COUNT(*) as total_certificados,
    COUNT(blockchain_hash) as en_blockchain,
    COUNT(*) - COUNT(blockchain_hash) as solo_en_bd
FROM certificates
GROUP BY institution_name
ORDER BY total_certificados DESC;


