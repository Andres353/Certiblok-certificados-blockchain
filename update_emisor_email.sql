-- Script para actualizar el email de un emisor en Supabase
-- 
-- IMPORTANTE: 
-- - El email debe ser único en la tabla users
-- - Si el nuevo email ya existe, la consulta fallará
-- - Se actualizará automáticamente el campo updated_at
--
-- INSTRUCCIONES DE USO:
-- 1. Reemplaza 'NUEVO_EMAIL@ejemplo.com' con el nuevo email deseado
-- 2. Elige una de las opciones siguientes según cómo quieras identificar al emisor:
--    - OPCIÓN 1: Por email actual del emisor
--    - OPCIÓN 2: Por ID (UUID) del emisor
-- 3. Ejecuta este script en el SQL Editor de Supabase

-- ============================================================
-- OPCIÓN 1: Actualizar por EMAIL ACTUAL del emisor
-- ============================================================

UPDATE users 
SET 
    email = 'NUEVO_EMAIL@ejemplo.com',  -- ⚠️ CAMBIA ESTE EMAIL
    updated_at = NOW()
WHERE 
    email = 'EMAIL_ACTUAL@ejemplo.com'  -- ⚠️ CAMBIA ESTE EMAIL
    AND role = 'emisor';

-- Verificar que se actualizó correctamente
SELECT 
    id,
    email,
    full_name,
    emisor_type,
    institution_id,
    role,
    updated_at
FROM users
WHERE email = 'NUEVO_EMAIL@ejemplo.com'  -- ⚠️ CAMBIA ESTE EMAIL
    AND role = 'emisor';

-- ============================================================
-- OPCIÓN 2: Actualizar por ID (UUID) del emisor
-- ============================================================

-- UPDATE users 
-- SET 
--     email = 'NUEVO_EMAIL@ejemplo.com',  -- ⚠️ CAMBIA ESTE EMAIL
--     updated_at = NOW()
-- WHERE 
--     id = 'UUID_DEL_EMISOR_AQUI'::uuid  -- ⚠️ CAMBIA ESTE UUID
--     AND role = 'emisor';

-- Verificar que se actualizó correctamente
-- SELECT 
--     id,
--     email,
--     full_name,
--     emisor_type,
--     institution_id,
--     role,
--     updated_at
-- FROM users
-- WHERE id = 'UUID_DEL_EMISOR_AQUI'::uuid  -- ⚠️ CAMBIA ESTE UUID
--     AND role = 'emisor';

-- ============================================================
-- OPCIÓN 3: Actualizar con validación previa (RECOMENDADO)
-- ============================================================

-- Este bloque verifica que el nuevo email no exista antes de actualizar
-- DO $$
-- DECLARE
--     old_email VARCHAR := 'EMAIL_ACTUAL@ejemplo.com';  -- ⚠️ CAMBIA ESTE EMAIL
--     new_email VARCHAR := 'NUEVO_EMAIL@ejemplo.com';   -- ⚠️ CAMBIA ESTE EMAIL
--     emisor_exists BOOLEAN;
--     email_taken BOOLEAN;
-- BEGIN
--     -- Verificar que el emisor existe
--     SELECT EXISTS(
--         SELECT 1 FROM users 
--         WHERE email = old_email AND role = 'emisor'
--     ) INTO emisor_exists;
--     
--     -- Verificar que el nuevo email no esté en uso
--     SELECT EXISTS(
--         SELECT 1 FROM users 
--         WHERE email = new_email
--     ) INTO email_taken;
--     
--     IF NOT emisor_exists THEN
--         RAISE EXCEPTION 'No se encontró un emisor con el email: %', old_email;
--     END IF;
--     
--     IF email_taken THEN
--         RAISE EXCEPTION 'El email % ya está en uso por otro usuario', new_email;
--     END IF;
--     
--     -- Actualizar el email
--     UPDATE users 
--     SET 
--         email = new_email,
--         updated_at = NOW()
--     WHERE 
--         email = old_email
--         AND role = 'emisor';
--     
--     RAISE NOTICE 'Email actualizado exitosamente de % a %', old_email, new_email;
-- END $$;

-- Verificar el resultado
-- SELECT 
--     id,
--     email,
--     full_name,
--     emisor_type,
--     institution_id,
--     role,
--     updated_at
-- FROM users
-- WHERE email = 'NUEVO_EMAIL@ejemplo.com'  -- ⚠️ CAMBIA ESTE EMAIL
--     AND role = 'emisor';


