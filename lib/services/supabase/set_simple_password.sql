-- Script simple para establecer contraseña en texto plano
-- Ejecutar en el SQL Editor de Supabase

-- 1. VER INSTITUCIONES ACTUALES
SELECT 
    id,
    name,
    admin_email,
    admin_password_hash
FROM institutions 
WHERE admin_email IS NOT NULL;

-- 2. ESTABLECER CONTRASEÑA SIMPLE PARA TRALALA
UPDATE institutions 
SET 
    admin_password_hash = 'VWXYZabcdefg',
    admin_must_change_password = false,
    admin_is_temporary_password = false,
    updated_at = NOW()
WHERE name = 'TRALALA';

-- 3. VERIFICAR EL CAMBIO
SELECT 
    id,
    name,
    admin_email,
    admin_password_hash
FROM institutions 
WHERE name = 'TRALALA';
