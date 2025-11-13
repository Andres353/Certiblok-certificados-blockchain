-- lib/services/supabase/delete_admin_cascade.sql
-- Script para eliminar completamente un administrador de institución y todos sus datos relacionados
-- 
-- IMPORTANTE: Este script eliminará PERMANENTEMENTE:
-- - El usuario/administrador de la tabla users
-- - La relación admin_user_id en la tabla institutions (se pone NULL)
-- - Todos los certificados creados por el admin (se mantienen pero se actualiza created_by)
-- - Todas las relaciones con instituciones
-- - Todos los códigos de reset de contraseña
-- - Sus logs de seguridad (se mantienen pero se pone user_id = NULL)

-- INSTRUCCIONES DE USO:
-- 1. Reemplaza 'ADMIN_EMAIL_HERE' con el email del administrador a eliminar
-- 2. O reemplaza 'ADMIN_ID_UUID_HERE' con el UUID del administrador
-- 3. Ejecuta este script en el SQL Editor de Supabase

-- ============================================================
-- OPCIÓN 1: Eliminar por EMAIL del administrador
-- ============================================================

DO $$
DECLARE
    admin_uuid UUID;
    admin_email VARCHAR := 'ADMIN_EMAIL_HERE'; -- ⚠️ CAMBIA ESTE EMAIL
    cert_count INTEGER;
    template_count INTEGER;
    program_count INTEGER;
    app_count INTEGER;
    inst_count INTEGER;
BEGIN
    -- Obtener el UUID del administrador por email
    SELECT id INTO admin_uuid 
    FROM users 
    WHERE email = admin_email AND role = 'admin_institution';
    
    -- Verificar que el administrador existe
    IF admin_uuid IS NULL THEN
        RAISE EXCEPTION 'No se encontró un administrador con el email: %', admin_email;
    END IF;
    
    -- Mostrar resumen de lo que se va a eliminar
    SELECT COUNT(*) INTO cert_count FROM certificates WHERE created_by = admin_uuid::text OR issued_by = admin_uuid::text;
    SELECT COUNT(*) INTO template_count FROM certificate_templates WHERE created_by = admin_uuid;
    SELECT COUNT(*) INTO program_count FROM programs_opportunities WHERE created_by = admin_uuid;
    SELECT COUNT(*) INTO app_count FROM applications WHERE reviewed_by = admin_uuid;
    SELECT COUNT(*) INTO inst_count FROM student_institutions WHERE student_id = admin_uuid;
    
    RAISE NOTICE '========================================';
    RAISE NOTICE 'RESUMEN DE ELIMINACIÓN DE ADMINISTRADOR:';
    RAISE NOTICE 'Email: %', admin_email;
    RAISE NOTICE 'ID: %', admin_uuid;
    RAISE NOTICE 'Certificados: % registros (se mantendrán pero sin created_by/issued_by)', cert_count;
    RAISE NOTICE 'Plantillas creadas: % registros (se mantendrán pero sin created_by)', template_count;
    RAISE NOTICE 'Programas creados: % registros (se mantendrán pero sin created_by)', program_count;
    RAISE NOTICE 'Postulaciones revisadas: % registros (se mantendrán pero sin reviewed_by)', app_count;
    RAISE NOTICE 'Relaciones con Instituciones: % registros', inst_count;
    RAISE NOTICE '========================================';
    
    -- Actualizar institución (poner admin_user_id = NULL)
    UPDATE institutions 
    SET admin_user_id = NULL 
    WHERE admin_user_id = admin_uuid;
    
    RAISE NOTICE '✅ Institución actualizada (admin_user_id = NULL)';
    
    -- Actualizar certificados (poner created_by/issued_by = NULL)
    UPDATE certificates 
    SET created_by = NULL, issued_by = NULL, issued_by_name = NULL, issued_by_role = NULL
    WHERE created_by = admin_uuid::text OR issued_by = admin_uuid::text;
    
    RAISE NOTICE '✅ Certificados actualizados';
    
    -- Actualizar plantillas (poner created_by = NULL)
    UPDATE certificate_templates 
    SET created_by = NULL
    WHERE created_by = admin_uuid;
    
    RAISE NOTICE '✅ Plantillas actualizadas';
    
    -- Actualizar programas (poner created_by = NULL)
    UPDATE programs_opportunities 
    SET created_by = NULL
    WHERE created_by = admin_uuid;
    
    RAISE NOTICE '✅ Programas actualizados';
    
    -- Actualizar postulaciones (poner reviewed_by = NULL)
    UPDATE applications 
    SET reviewed_by = NULL, reviewed_by_name = NULL
    WHERE reviewed_by = admin_uuid;
    
    RAISE NOTICE '✅ Postulaciones actualizadas';
    
    -- Actualizar solicitudes de instituciones (poner reviewed_by = NULL)
    UPDATE institution_requests 
    SET reviewed_by = NULL
    WHERE reviewed_by = admin_uuid;
    
    RAISE NOTICE '✅ Solicitudes de instituciones actualizadas';
    
    -- Eliminar el administrador (CASCADE eliminará automáticamente los relacionados)
    DELETE FROM users WHERE id = admin_uuid;
    
    RAISE NOTICE '✅ Administrador y todos sus datos relacionados han sido eliminados exitosamente.';
END $$;

-- ============================================================
-- OPCIÓN 2: Eliminar por UUID del administrador (más directo)
-- ============================================================

-- Descomenta y usa esta versión si ya tienes el UUID del administrador:
/*
DO $$
DECLARE
    admin_uuid UUID := 'ADMIN_ID_UUID_HERE'::UUID; -- ⚠️ CAMBIA ESTE UUID
    cert_count INTEGER;
    template_count INTEGER;
    program_count INTEGER;
    app_count INTEGER;
    inst_count INTEGER;
    admin_email VARCHAR;
BEGIN
    -- Verificar que el administrador existe
    SELECT email INTO admin_email 
    FROM users 
    WHERE id = admin_uuid AND role = 'admin_institution';
    
    IF admin_email IS NULL THEN
        RAISE EXCEPTION 'No se encontró un administrador con el ID: %', admin_uuid;
    END IF;
    
    -- Mostrar resumen de lo que se va a eliminar
    SELECT COUNT(*) INTO cert_count FROM certificates WHERE created_by = admin_uuid::text OR issued_by = admin_uuid::text;
    SELECT COUNT(*) INTO template_count FROM certificate_templates WHERE created_by = admin_uuid;
    SELECT COUNT(*) INTO program_count FROM programs_opportunities WHERE created_by = admin_uuid;
    SELECT COUNT(*) INTO app_count FROM applications WHERE reviewed_by = admin_uuid;
    SELECT COUNT(*) INTO inst_count FROM student_institutions WHERE student_id = admin_uuid;
    
    RAISE NOTICE '========================================';
    RAISE NOTICE 'RESUMEN DE ELIMINACIÓN DE ADMINISTRADOR:';
    RAISE NOTICE 'Email: %', admin_email;
    RAISE NOTICE 'ID: %', admin_uuid;
    RAISE NOTICE 'Certificados: % registros (se mantendrán pero sin created_by/issued_by)', cert_count;
    RAISE NOTICE 'Plantillas creadas: % registros (se mantendrán pero sin created_by)', template_count;
    RAISE NOTICE 'Programas creados: % registros (se mantendrán pero sin created_by)', program_count;
    RAISE NOTICE 'Postulaciones revisadas: % registros (se mantendrán pero sin reviewed_by)', app_count;
    RAISE NOTICE 'Relaciones con Instituciones: % registros', inst_count;
    RAISE NOTICE '========================================';
    
    -- Actualizar institución (poner admin_user_id = NULL)
    UPDATE institutions 
    SET admin_user_id = NULL 
    WHERE admin_user_id = admin_uuid;
    
    -- Actualizar certificados
    UPDATE certificates 
    SET created_by = NULL, issued_by = NULL, issued_by_name = NULL, issued_by_role = NULL
    WHERE created_by = admin_uuid::text OR issued_by = admin_uuid::text;
    
    -- Actualizar plantillas
    UPDATE certificate_templates 
    SET created_by = NULL
    WHERE created_by = admin_uuid;
    
    -- Actualizar programas
    UPDATE programs_opportunities 
    SET created_by = NULL
    WHERE created_by = admin_uuid;
    
    -- Actualizar postulaciones
    UPDATE applications 
    SET reviewed_by = NULL, reviewed_by_name = NULL
    WHERE reviewed_by = admin_uuid;
    
    -- Actualizar solicitudes de instituciones
    UPDATE institution_requests 
    SET reviewed_by = NULL
    WHERE reviewed_by = admin_uuid;
    
    -- Eliminar el administrador
    DELETE FROM users WHERE id = admin_uuid;
    
    RAISE NOTICE '✅ Administrador y todos sus datos relacionados han sido eliminados exitosamente.';
END $$;
*/

-- ============================================================
-- OPCIÓN 3: Eliminación simple (sin resumen) - MÁS RÁPIDA
-- ============================================================

-- Si solo quieres eliminar directamente sin ver el resumen:
/*
-- Actualizar todas las referencias primero
UPDATE institutions SET admin_user_id = NULL WHERE admin_user_id = 'ADMIN_UUID'::UUID;
UPDATE certificates SET created_by = NULL, issued_by = NULL, issued_by_name = NULL, issued_by_role = NULL 
WHERE created_by = 'ADMIN_UUID'::text OR issued_by = 'ADMIN_UUID'::text;
UPDATE certificate_templates SET created_by = NULL WHERE created_by = 'ADMIN_UUID'::UUID;
UPDATE programs_opportunities SET created_by = NULL WHERE created_by = 'ADMIN_UUID'::UUID;
UPDATE applications SET reviewed_by = NULL, reviewed_by_name = NULL WHERE reviewed_by = 'ADMIN_UUID'::UUID;
UPDATE institution_requests SET reviewed_by = NULL WHERE reviewed_by = 'ADMIN_UUID'::UUID;

-- Por email:
DELETE FROM users 
WHERE email = 'ADMIN_EMAIL_HERE' AND role = 'admin_institution';

-- Por UUID:
DELETE FROM users 
WHERE id = 'ADMIN_ID_UUID_HERE'::UUID AND role = 'admin_institution';
*/

-- ============================================================
-- NOTAS IMPORTANTES:
-- ============================================================
-- 1. Las siguientes tablas se eliminan AUTOMÁTICAMENTE por CASCADE:
--    - student_institutions (todas las relaciones institucionales)
--    - password_reset_codes (todos los códigos de reset)
--
-- 2. Las siguientes tablas se ACTUALIZAN (se mantiene el registro):
--    - institutions (se pone admin_user_id = NULL)
--    - certificates (se pone created_by/issued_by = NULL en certificados que creó/emitió)
--    - certificate_templates (se pone created_by = NULL)
--    - programs_opportunities (se pone created_by = NULL)
--    - applications (se pone reviewed_by = NULL)
--    - institution_requests (se pone reviewed_by = NULL)
--    - security_logs (se pone user_id = NULL, pero se mantiene el log)
--
-- 3. ⚠️ ADVERTENCIA: Esta operación es IRREVERSIBLE. Asegúrate de hacer un backup antes.
--
-- 4. Para hacer backup de los datos antes de eliminar:
--    SELECT * INTO TABLE backup_admin_data FROM users WHERE id = 'ADMIN_UUID';
--    SELECT * INTO TABLE backup_admin_certificates FROM certificates WHERE created_by = 'ADMIN_UUID'::text OR issued_by = 'ADMIN_UUID'::text;
--    SELECT * INTO TABLE backup_admin_templates FROM certificate_templates WHERE created_by = 'ADMIN_UUID';
--    SELECT * INTO TABLE backup_admin_programs FROM programs_opportunities WHERE created_by = 'ADMIN_UUID';

