-- lib/services/supabase/rls_policies.sql
-- Políticas de Row Level Security para multi-tenant

-- Habilitar RLS en todas las tablas
ALTER TABLE institutions ENABLE ROW LEVEL SECURITY;
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE faculties ENABLE ROW LEVEL SECURITY;
ALTER TABLE programs ENABLE ROW LEVEL SECURITY;
ALTER TABLE certificates ENABLE ROW LEVEL SECURITY;
ALTER TABLE certificate_templates ENABLE ROW LEVEL SECURITY;
ALTER TABLE student_institutions ENABLE ROW LEVEL SECURITY;
ALTER TABLE institution_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE password_reset_codes ENABLE ROW LEVEL SECURITY;
ALTER TABLE security_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE page_content ENABLE ROW LEVEL SECURITY;

-- 1. POLÍTICAS PARA INSTITUCIONES
-- Super admin puede ver todas las instituciones
CREATE POLICY "super_admin_all_institutions" ON institutions
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM users 
            WHERE users.id = auth.uid() 
            AND users.role = 'super_admin'
        )
    );

-- Admin de institución puede ver su propia institución
CREATE POLICY "admin_own_institution" ON institutions
    FOR ALL USING (
        id = (
            SELECT institution_id FROM users 
            WHERE users.id = auth.uid() 
            AND users.role = 'admin_institution'
        )
    );

-- 2. POLÍTICAS PARA USUARIOS
-- Super admin puede ver todos los usuarios
CREATE POLICY "super_admin_all_users" ON users
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM users u
            WHERE u.id = auth.uid() 
            AND u.role = 'super_admin'
        )
    );

-- Admin de institución puede ver usuarios de su institución
CREATE POLICY "admin_institution_users" ON users
    FOR ALL USING (
        institution_id = (
            SELECT institution_id FROM users 
            WHERE users.id = auth.uid() 
            AND users.role = 'admin_institution'
        )
    );

-- Emisor puede ver usuarios de su institución
CREATE POLICY "emisor_institution_users" ON users
    FOR ALL USING (
        institution_id = (
            SELECT institution_id FROM users 
            WHERE users.id = auth.uid() 
            AND users.role = 'emisor'
        )
    );

-- Usuarios pueden ver su propia información
CREATE POLICY "users_own_data" ON users
    FOR ALL USING (id = auth.uid());

-- 3. POLÍTICAS PARA FACULTADES
-- Super admin puede ver todas las facultades
CREATE POLICY "super_admin_all_faculties" ON faculties
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM users 
            WHERE users.id = auth.uid() 
            AND users.role = 'super_admin'
        )
    );

-- Usuarios pueden ver facultades de su institución
CREATE POLICY "institution_faculties" ON faculties
    FOR ALL USING (
        institution_id = (
            SELECT institution_id FROM users 
            WHERE users.id = auth.uid()
        )
    );

-- 4. POLÍTICAS PARA PROGRAMAS
-- Super admin puede ver todos los programas
CREATE POLICY "super_admin_all_programs" ON programs
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM users 
            WHERE users.id = auth.uid() 
            AND users.role = 'super_admin'
        )
    );

-- Usuarios pueden ver programas de su institución
CREATE POLICY "institution_programs" ON programs
    FOR ALL USING (
        institution_id = (
            SELECT institution_id FROM users 
            WHERE users.id = auth.uid()
        )
    );

-- 5. POLÍTICAS PARA CERTIFICADOS
-- Super admin puede ver todos los certificados
CREATE POLICY "super_admin_all_certificates" ON certificates
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM users 
            WHERE users.id = auth.uid() 
            AND users.role = 'super_admin'
        )
    );

-- Admin de institución puede ver certificados de su institución
CREATE POLICY "admin_institution_certificates" ON certificates
    FOR ALL USING (
        institution_id = (
            SELECT institution_id FROM users 
            WHERE users.id = auth.uid() 
            AND users.role = 'admin_institution'
        )
    );

-- Emisor puede ver certificados de su institución
CREATE POLICY "emisor_institution_certificates" ON certificates
    FOR ALL USING (
        institution_id = (
            SELECT institution_id FROM users 
            WHERE users.id = auth.uid() 
            AND users.role = 'emisor'
        )
    );

-- Estudiantes pueden ver sus propios certificados
CREATE POLICY "student_own_certificates" ON certificates
    FOR ALL USING (
        student_id = auth.uid()
    );

-- Certificados públicos para verificación (sin autenticación)
CREATE POLICY "public_certificate_verification" ON certificates
    FOR SELECT USING (true);

-- 6. POLÍTICAS PARA PLANTILLAS DE CERTIFICADOS
-- Super admin puede ver todas las plantillas
CREATE POLICY "super_admin_all_templates" ON certificate_templates
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM users 
            WHERE users.id = auth.uid() 
            AND users.role = 'super_admin'
        )
    );

-- Usuarios pueden ver plantillas de su institución
CREATE POLICY "institution_templates" ON certificate_templates
    FOR ALL USING (
        institution_id = (
            SELECT institution_id FROM users 
            WHERE users.id = auth.uid()
        )
    );

-- 7. POLÍTICAS PARA RELACIONES ESTUDIANTE-INSTITUCIÓN
-- Super admin puede ver todas las relaciones
CREATE POLICY "super_admin_all_student_institutions" ON student_institutions
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM users 
            WHERE users.id = auth.uid() 
            AND users.role = 'super_admin'
        )
    );

-- Admin de institución puede ver relaciones de su institución
CREATE POLICY "admin_institution_student_relations" ON student_institutions
    FOR ALL USING (
        institution_id = (
            SELECT institution_id FROM users 
            WHERE users.id = auth.uid() 
            AND users.role = 'admin_institution'
        )
    );

-- Estudiantes pueden ver sus propias relaciones
CREATE POLICY "student_own_relations" ON student_institutions
    FOR ALL USING (
        student_id = auth.uid()
    );

-- 8. POLÍTICAS PARA SOLICITUDES DE INSTITUCIÓN
-- Super admin puede ver todas las solicitudes
CREATE POLICY "super_admin_all_requests" ON institution_requests
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM users 
            WHERE users.id = auth.uid() 
            AND users.role = 'super_admin'
        )
    );

-- Cualquier usuario puede crear solicitudes
CREATE POLICY "anyone_create_requests" ON institution_requests
    FOR INSERT WITH CHECK (true);

-- 9. POLÍTICAS PARA CÓDIGOS DE RESET DE CONTRASEÑA
-- Usuarios pueden ver sus propios códigos
CREATE POLICY "users_own_reset_codes" ON password_reset_codes
    FOR ALL USING (user_id = auth.uid());

-- 10. POLÍTICAS PARA LOGS DE SEGURIDAD
-- Solo super admin puede ver logs de seguridad
CREATE POLICY "super_admin_security_logs" ON security_logs
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM users 
            WHERE users.id = auth.uid() 
            AND users.role = 'super_admin'
        )
    );

-- 11. POLÍTICAS PARA CONTENIDO DE PÁGINA
-- Super admin puede gestionar contenido de página
CREATE POLICY "super_admin_page_content" ON page_content
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM users 
            WHERE users.id = auth.uid() 
            AND users.role = 'super_admin'
        )
    );

-- Contenido de página es público para lectura
CREATE POLICY "public_page_content_read" ON page_content
    FOR SELECT USING (true);

-- 12. FUNCIÓN AUXILIAR PARA OBTENER INSTITUCIÓN DEL USUARIO
CREATE OR REPLACE FUNCTION get_user_institution_id()
RETURNS UUID AS $$
BEGIN
    RETURN (
        SELECT institution_id FROM users 
        WHERE users.id = auth.uid()
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 13. FUNCIÓN AUXILIAR PARA VERIFICAR ROL DE USUARIO
CREATE OR REPLACE FUNCTION has_user_role(role_name TEXT)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM users 
        WHERE users.id = auth.uid() 
        AND users.role = role_name
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
