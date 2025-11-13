-- lib/services/supabase/add_student_fields.sql
-- Migración para agregar campos adicionales a la tabla users para estudiantes

-- Agregar campos adicionales para estudiantes
ALTER TABLE users 
ADD COLUMN IF NOT EXISTS document VARCHAR(50),
ADD COLUMN IF NOT EXISTS birth_date VARCHAR(20),
ADD COLUMN IF NOT EXISTS address TEXT;

-- Agregar comentarios para documentación
COMMENT ON COLUMN users.document IS 'Documento de identidad del estudiante';
COMMENT ON COLUMN users.birth_date IS 'Fecha de nacimiento del estudiante (formato DD/MM/AAAA)';
COMMENT ON COLUMN users.address IS 'Dirección de residencia del estudiante';

-- Crear índices para optimización (opcional)
CREATE INDEX IF NOT EXISTS idx_users_document ON users(document);
CREATE INDEX IF NOT EXISTS idx_users_birth_date ON users(birth_date);

