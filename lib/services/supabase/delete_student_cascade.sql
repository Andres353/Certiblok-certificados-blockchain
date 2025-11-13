-- lib/services/supabase/delete_student_cascade.sql
-- Script para eliminar completamente un estudiante y todos sus datos relacionados
-- 
-- IMPORTANTE: Este script eliminará PERMANENTEMENTE:
-- - El usuario/estudiante de la tabla users
-- - Todos sus certificados (tabla certificates)
-- - Todas sus postulaciones (tabla applications)
-- - Todas sus relaciones con instituciones (tabla student_institutions)
-- - Todos sus QRs agrupados guardados (tabla grouped_qrs)
-- - Todos sus códigos de reset de contraseña (tabla password_reset_codes)
-- - Sus logs de seguridad (tabla security_logs) - se mantienen pero se pone user_id = NULL

-- INSTRUCCIONES DE USO:
-- 1. Reemplaza 'STUDENT_EMAIL_HERE' con el email del estudiante a eliminar
-- 2. O reemplaza 'STUDENT_ID_UUID_HERE' con el UUID del estudiante
-- 3. Ejecuta este script en el SQL Editor de Supabase

-- ============================================================
-- OPCIÓN 1: Eliminar por EMAIL del estudiante
-- ============================================================

DO $$
DECLARE
    student_uuid UUID;
    student_email VARCHAR := 'STUDENT_EMAIL_HERE'; -- ⚠️ CAMBIA ESTE EMAIL
    cert_count INTEGER;
    app_count INTEGER;
    qr_count INTEGER;
    inst_count INTEGER;
BEGIN
    -- Obtener el UUID del estudiante por email
    SELECT id INTO student_uuid 
    FROM users 
    WHERE email = student_email AND role = 'student';
    
    -- Verificar que el estudiante existe
    IF student_uuid IS NULL THEN
        RAISE EXCEPTION 'No se encontró un estudiante con el email: %', student_email;
    END IF;
    
    -- Mostrar resumen de lo que se va a eliminar
    SELECT COUNT(*) INTO cert_count FROM certificates WHERE student_id = student_uuid;
    SELECT COUNT(*) INTO app_count FROM applications WHERE student_id = student_uuid;
    SELECT COUNT(*) INTO qr_count FROM grouped_qrs WHERE student_id = student_uuid;
    SELECT COUNT(*) INTO inst_count FROM student_institutions WHERE student_id = student_uuid;
    
    RAISE NOTICE '========================================';
    RAISE NOTICE 'RESUMEN DE ELIMINACIÓN:';
    RAISE NOTICE 'Email: %', student_email;
    RAISE NOTICE 'ID: %', student_uuid;
    RAISE NOTICE 'Certificados: % registros', cert_count;
    RAISE NOTICE 'Postulaciones: % registros', app_count;
    RAISE NOTICE 'QRs Agrupados: % registros', qr_count;
    RAISE NOTICE 'Relaciones con Instituciones: % registros', inst_count;
    RAISE NOTICE '========================================';
    
    -- Eliminar el estudiante (CASCADE eliminará automáticamente los relacionados)
    DELETE FROM users WHERE id = student_uuid;
    
    RAISE NOTICE '✅ Estudiante y todos sus datos relacionados han sido eliminados exitosamente.';
END $$;

-- ============================================================
-- OPCIÓN 2: Eliminar por UUID del estudiante (más directo)
-- ============================================================

-- Descomenta y usa esta versión si ya tienes el UUID del estudiante:
/*
DO $$
DECLARE
    student_uuid UUID := 'STUDENT_ID_UUID_HERE'::UUID; -- ⚠️ CAMBIA ESTE UUID
    cert_count INTEGER;
    app_count INTEGER;
    qr_count INTEGER;
    inst_count INTEGER;
    student_email VARCHAR;
BEGIN
    -- Verificar que el estudiante existe
    SELECT email INTO student_email 
    FROM users 
    WHERE id = student_uuid AND role = 'student';
    
    IF student_email IS NULL THEN
        RAISE EXCEPTION 'No se encontró un estudiante con el ID: %', student_uuid;
    END IF;
    
    -- Mostrar resumen de lo que se va a eliminar
    SELECT COUNT(*) INTO cert_count FROM certificates WHERE student_id = student_uuid;
    SELECT COUNT(*) INTO app_count FROM applications WHERE student_id = student_uuid;
    SELECT COUNT(*) INTO qr_count FROM grouped_qrs WHERE student_id = student_uuid;
    SELECT COUNT(*) INTO inst_count FROM student_institutions WHERE student_id = student_uuid;
    
    RAISE NOTICE '========================================';
    RAISE NOTICE 'RESUMEN DE ELIMINACIÓN:';
    RAISE NOTICE 'Email: %', student_email;
    RAISE NOTICE 'ID: %', student_uuid;
    RAISE NOTICE 'Certificados: % registros', cert_count;
    RAISE NOTICE 'Postulaciones: % registros', app_count;
    RAISE NOTICE 'QRs Agrupados: % registros', qr_count;
    RAISE NOTICE 'Relaciones con Instituciones: % registros', inst_count;
    RAISE NOTICE '========================================';
    
    -- Eliminar el estudiante (CASCADE eliminará automáticamente los relacionados)
    DELETE FROM users WHERE id = student_uuid;
    
    RAISE NOTICE '✅ Estudiante y todos sus datos relacionados han sido eliminados exitosamente.';
END $$;
*/

-- ============================================================
-- OPCIÓN 3: Eliminación simple (sin resumen) - MÁS RÁPIDA
-- ============================================================

-- Si solo quieres eliminar directamente sin ver el resumen:
/*
-- Por email:
DELETE FROM users 
WHERE email = 'STUDENT_EMAIL_HERE' AND role = 'student';

-- Por UUID:
DELETE FROM users 
WHERE id = 'STUDENT_ID_UUID_HERE'::UUID AND role = 'student';
*/

-- ============================================================
-- NOTAS IMPORTANTES:
-- ============================================================
-- 1. Las siguientes tablas se eliminan AUTOMÁTICAMENTE por CASCADE:
--    - certificates (todos los certificados del estudiante)
--    - applications (todas las postulaciones del estudiante)
--    - student_institutions (todas las relaciones institucionales)
--    - grouped_qrs (todos los QRs agrupados guardados)
--    - password_reset_codes (todos los códigos de reset)
--
-- 2. Las siguientes tablas NO se eliminan (se mantiene el registro):
--    - security_logs (se pone user_id = NULL, pero se mantiene el log)
--    - certificate_templates (si el estudiante creó plantillas, se pone created_by = NULL)
--    - institution_requests (si el estudiante revisó solicitudes, se pone reviewed_by = NULL)
--
-- 3. ⚠️ ADVERTENCIA: Esta operación es IRREVERSIBLE. Asegúrate de hacer un backup antes.
--
-- 4. Para hacer backup de los datos antes de eliminar:
--    SELECT * INTO TABLE backup_student_data FROM users WHERE id = 'STUDENT_UUID';
--    SELECT * INTO TABLE backup_student_certificates FROM certificates WHERE student_id = 'STUDENT_UUID';
--    SELECT * INTO TABLE backup_student_applications FROM applications WHERE student_id = 'STUDENT_UUID';

