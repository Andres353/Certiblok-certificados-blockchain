-- Script para actualizar el email de un administrador en Supabase
-- 
-- IMPORTANTE: 
-- - El email debe ser único en la tabla users
-- - Si el nuevo email ya existe, la consulta fallará
-- - Se actualizará automáticamente el campo updated_at
--
-- INSTRUCCIONES DE USO:
-- 1. Reemplaza 'NUEVO_EMAIL@ejemplo.com' con el nuevo email deseado
-- 2. Elige una de las opciones siguientes según cómo quieras identificar al administrador:
--    - OPCIÓN 1: Por email actual del administrador
--    - OPCIÓN 2: Por ID (UUID) del administrador
-- 3. Ejecuta este script en el SQL Editor de Supabase

-- ============================================================
-- OPCIÓN 1: Actualizar por EMAIL ACTUAL del administrador
-- ============================================================

UPDATE users 
SET 
    email = 'NUEVO_EMAIL@ejemplo.com',  -- ⚠️ CAMBIA ESTE EMAIL
    updated_at = NOW()
WHERE 
    email = 'EMAIL_ACTUAL@ejemplo.com'  -- ⚠️ CAMBIA ESTE EMAIL
    AND role = 'admin_institution';

-- Verificar que se actualizó correctamente
SELECT 
    id,
    email,
    full_name,
    institution_id,
    role,
    updated_at
FROM users
WHERE email = 'NUEVO_EMAIL@ejemplo.com'  -- ⚠️ CAMBIA ESTE EMAIL
    AND role = 'admin_institution';

-- ============================================================
-- OPCIÓN 2: Actualizar por ID (UUID) del administrador
-- ============================================================

-- UPDATE users 
-- SET 
--     email = 'NUEVO_EMAIL@ejemplo.com',  -- ⚠️ CAMBIA ESTE EMAIL
--     updated_at = NOW()
-- WHERE 
--     id = 'UUID_DEL_ADMINISTRADOR_AQUI'::uuid  -- ⚠️ CAMBIA ESTE UUID
--     AND role = 'admin_institution';

-- Verificar que se actualizó correctamente
-- SELECT 
--     id,
--     email,
--     full_name,
--     institution_id,
--     role,
--     updated_at
-- FROM users
-- WHERE id = 'UUID_DEL_ADMINISTRADOR_AQUI'::uuid  -- ⚠️ CAMBIA ESTE UUID
--     AND role = 'admin_institution';

-- ============================================================
-- OPCIÓN 3: Actualizar con validación previa (RECOMENDADO)
-- ============================================================

-- Este bloque verifica que el nuevo email no exista antes de actualizar
-- DO $$
-- DECLARE
--     old_email VARCHAR := 'EMAIL_ACTUAL@ejemplo.com';  -- ⚠️ CAMBIA ESTE EMAIL
--     new_email VARCHAR := 'NUEVO_EMAIL@ejemplo.com';   -- ⚠️ CAMBIA ESTE EMAIL
--     admin_exists BOOLEAN;
--     email_taken BOOLEAN;
-- BEGIN
--     -- Verificar que el administrador existe
--     SELECT EXISTS(
--         SELECT 1 FROM users 
--         WHERE email = old_email AND role = 'admin_institution'
--     ) INTO admin_exists;
--     
--     -- Verificar que el nuevo email no esté en uso
--     SELECT EXISTS(
--         SELECT 1 FROM users 
--         WHERE email = new_email
--     ) INTO email_taken;
--     
--     IF NOT admin_exists THEN
--         RAISE EXCEPTION 'No se encontró un administrador con el email: %', old_email;
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
--         AND role = 'admin_institution';
--     
--     RAISE NOTICE 'Email actualizado exitosamente de % a %', old_email, new_email;
-- END $$;

-- Verificar el resultado
-- SELECT 
--     id,
--     email,
--     full_name,
--     institution_id,
--     role,
--     updated_at
-- FROM users
-- WHERE email = 'NUEVO_EMAIL@ejemplo.com'  -- ⚠️ CAMBIA ESTE EMAIL
--     AND role = 'admin_institution';


