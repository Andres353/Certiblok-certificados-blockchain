-- lib/services/supabase/delete_emisor_cascade.sql
-- Script para eliminar completamente un emisor y todos sus datos relacionados
-- 
-- IMPORTANTE: Este script eliminará PERMANENTEMENTE:
-- - El usuario/emisor de la tabla users
-- - Todos los certificados emitidos por el emisor (se mantienen pero se actualiza issued_by)
-- - Todas las relaciones con instituciones (si tiene)
-- - Todos los códigos de reset de contraseña
-- - Sus logs de seguridad (se mantienen pero se pone user_id = NULL)

-- INSTRUCCIONES DE USO:
-- 1. Reemplaza 'EMISOR_EMAIL_HERE' con el email del emisor a eliminar
-- 2. O reemplaza 'EMISOR_ID_UUID_HERE' con el UUID del emisor
-- 3. Ejecuta este script en el SQL Editor de Supabase

-- ============================================================
-- OPCIÓN 1: Eliminar por EMAIL del emisor
-- ============================================================

DO $$
DECLARE
    emisor_uuid UUID;
    emisor_email VARCHAR := 'EMISOR_EMAIL_HERE'; -- ⚠️ CAMBIA ESTE EMAIL
    cert_count INTEGER;
    inst_count INTEGER;
BEGIN
    -- Obtener el UUID del emisor por email
    SELECT id INTO emisor_uuid 
    FROM users 
    WHERE email = emisor_email AND role = 'emisor';
    
    -- Verificar que el emisor existe
    IF emisor_uuid IS NULL THEN
        RAISE EXCEPTION 'No se encontró un emisor con el email: %', emisor_email;
    END IF;
    
    -- Mostrar resumen de lo que se va a eliminar
    SELECT COUNT(*) INTO cert_count FROM certificates WHERE issued_by = emisor_uuid::text;
    SELECT COUNT(*) INTO inst_count FROM student_institutions WHERE student_id = emisor_uuid;
    
    RAISE NOTICE '========================================';
    RAISE NOTICE 'RESUMEN DE ELIMINACIÓN DE EMISOR:';
    RAISE NOTICE 'Email: %', emisor_email;
    RAISE NOTICE 'ID: %', emisor_uuid;
    RAISE NOTICE 'Certificados emitidos: % registros (se mantendrán pero sin issued_by)', cert_count;
    RAISE NOTICE 'Relaciones con Instituciones: % registros', inst_count;
    RAISE NOTICE '========================================';
    
    -- Actualizar institución si el emisor es administrador (poner admin_user_id = NULL)
    UPDATE institutions 
    SET admin_user_id = NULL 
    WHERE admin_user_id = emisor_uuid;
    
    IF FOUND THEN
        RAISE NOTICE '✅ Institución actualizada (admin_user_id = NULL)';
    END IF;
    
    -- Actualizar certificados emitidos por el emisor (poner issued_by = NULL)
    UPDATE certificates 
    SET issued_by = NULL, issued_by_name = NULL, issued_by_role = NULL
    WHERE issued_by = emisor_uuid::text;
    
    RAISE NOTICE '✅ Certificados actualizados (issued_by = NULL)';
    
    -- Eliminar el emisor (CASCADE eliminará automáticamente los relacionados)
    DELETE FROM users WHERE id = emisor_uuid;
    
    RAISE NOTICE '✅ Emisor y todos sus datos relacionados han sido eliminados exitosamente.';
END $$;

-- ============================================================
-- OPCIÓN 2: Eliminar por UUID del emisor (más directo)
-- ============================================================

-- Descomenta y usa esta versión si ya tienes el UUID del emisor:
/*
DO $$
DECLARE
    emisor_uuid UUID := 'EMISOR_ID_UUID_HERE'::UUID; -- ⚠️ CAMBIA ESTE UUID
    cert_count INTEGER;
    inst_count INTEGER;
    emisor_email VARCHAR;
BEGIN
    -- Verificar que el emisor existe
    SELECT email INTO emisor_email 
    FROM users 
    WHERE id = emisor_uuid AND role = 'emisor';
    
    IF emisor_email IS NULL THEN
        RAISE EXCEPTION 'No se encontró un emisor con el ID: %', emisor_uuid;
    END IF;
    
    -- Mostrar resumen de lo que se va a eliminar
    SELECT COUNT(*) INTO cert_count FROM certificates WHERE issued_by = emisor_uuid::text;
    SELECT COUNT(*) INTO inst_count FROM student_institutions WHERE student_id = emisor_uuid;
    
    RAISE NOTICE '========================================';
    RAISE NOTICE 'RESUMEN DE ELIMINACIÓN DE EMISOR:';
    RAISE NOTICE 'Email: %', emisor_email;
    RAISE NOTICE 'ID: %', emisor_uuid;
    RAISE NOTICE 'Certificados emitidos: % registros (se mantendrán pero sin issued_by)', cert_count;
    RAISE NOTICE 'Relaciones con Instituciones: % registros', inst_count;
    RAISE NOTICE '========================================';
    
    -- Actualizar institución si el emisor es administrador (poner admin_user_id = NULL)
    UPDATE institutions 
    SET admin_user_id = NULL 
    WHERE admin_user_id = emisor_uuid;
    
    IF FOUND THEN
        RAISE NOTICE '✅ Institución actualizada (admin_user_id = NULL)';
    END IF;
    
    -- Actualizar certificados emitidos por el emisor (poner issued_by = NULL)
    UPDATE certificates 
    SET issued_by = NULL, issued_by_name = NULL, issued_by_role = NULL
    WHERE issued_by = emisor_uuid::text;
    
    RAISE NOTICE '✅ Certificados actualizados (issued_by = NULL)';
    
    -- Eliminar el emisor (CASCADE eliminará automáticamente los relacionados)
    DELETE FROM users WHERE id = emisor_uuid;
    
    RAISE NOTICE '✅ Emisor y todos sus datos relacionados han sido eliminados exitosamente.';
END $$;
*/

-- ============================================================
-- OPCIÓN 3: Eliminación simple (sin resumen) - MÁS RÁPIDA
-- ============================================================

-- Si solo quieres eliminar directamente sin ver el resumen:
/*
-- Actualizar institución primero (si es administrador)
UPDATE institutions 
SET admin_user_id = NULL 
WHERE admin_user_id IN (
    SELECT id FROM users WHERE email = 'EMISOR_EMAIL_HERE' AND role = 'emisor'
);

-- Actualizar certificados
UPDATE certificates 
SET issued_by = NULL, issued_by_name = NULL, issued_by_role = NULL
WHERE issued_by IN (
    SELECT id::text FROM users WHERE email = 'EMISOR_EMAIL_HERE' AND role = 'emisor'
);

-- Por email:
DELETE FROM users 
WHERE email = 'EMISOR_EMAIL_HERE' AND role = 'emisor';

-- Por UUID:
-- Actualizar institución primero
UPDATE institutions 
SET admin_user_id = NULL 
WHERE admin_user_id = 'EMISOR_ID_UUID_HERE'::UUID;

-- Actualizar certificados
UPDATE certificates 
SET issued_by = NULL, issued_by_name = NULL, issued_by_role = NULL
WHERE issued_by = 'EMISOR_ID_UUID_HERE'::text;

-- Eliminar emisor
DELETE FROM users 
WHERE id = 'EMISOR_ID_UUID_HERE'::UUID AND role = 'emisor';
*/

-- ============================================================
-- NOTAS IMPORTANTES:
-- ============================================================
-- 1. Las siguientes tablas se eliminan AUTOMÁTICAMENTE por CASCADE:
--    - student_institutions (todas las relaciones institucionales del emisor)
--    - password_reset_codes (todos los códigos de reset)
--
-- 2. Las siguientes tablas se ACTUALIZAN (se mantiene el registro):
--    - institutions (se pone admin_user_id = NULL si el emisor es administrador)
--    - certificates (se pone issued_by = NULL en certificados que emitió)
--    - security_logs (se pone user_id = NULL, pero se mantiene el log)
--    - certificate_templates (si el emisor creó plantillas, se pone created_by = NULL)
--    - programs_opportunities (si el emisor creó programas, se pone created_by = NULL)
--    - applications (si el emisor revisó postulaciones, se pone reviewed_by = NULL)
--    - institution_requests (si el emisor revisó solicitudes, se pone reviewed_by = NULL)
--
-- 3. ⚠️ ADVERTENCIA: Esta operación es IRREVERSIBLE. Asegúrate de hacer un backup antes.
--
-- 4. Para hacer backup de los datos antes de eliminar:
--    SELECT * INTO TABLE backup_emisor_data FROM users WHERE id = 'EMISOR_UUID';
--    SELECT * INTO TABLE backup_emisor_certificates FROM certificates WHERE issued_by = 'EMISOR_UUID'::text;

