-- Script para agregar columnas necesarias para emisores en la tabla 'users'
-- Basado en el uso del SupabaseEmisorService

-- Agregar columna 'assignments' si no existe
ALTER TABLE users 
ADD COLUMN IF NOT EXISTS assignments JSONB DEFAULT '[]'::jsonb;

-- Agregar columna 'emisor_type' si no existe
ALTER TABLE users 
ADD COLUMN IF NOT EXISTS emisor_type VARCHAR(50);

-- Agregar columna 'institution_name' si no existe
ALTER TABLE users 
ADD COLUMN IF NOT EXISTS institution_name VARCHAR(255);

-- Agregar columna 'is_active' si no existe
ALTER TABLE users 
ADD COLUMN IF NOT EXISTS is_active BOOLEAN DEFAULT true;

-- Agregar columna 'verification_code' si no existe
ALTER TABLE users 
ADD COLUMN IF NOT EXISTS verification_code VARCHAR(10);

-- Crear índices para mejorar rendimiento
CREATE INDEX IF NOT EXISTS idx_users_assignments ON users USING GIN (assignments);
CREATE INDEX IF NOT EXISTS idx_users_emisor_type ON users (emisor_type);
CREATE INDEX IF NOT EXISTS idx_users_is_active ON users (is_active);
CREATE INDEX IF NOT EXISTS idx_users_role ON users (role);

-- Agregar comentarios a las columnas
COMMENT ON COLUMN users.assignments IS 'Array de asignaciones de carreras para emisores';
COMMENT ON COLUMN users.emisor_type IS 'Tipo de emisor: general o carrera';
COMMENT ON COLUMN users.institution_name IS 'Nombre de la institución del usuario';
COMMENT ON COLUMN users.is_active IS 'Indica si el usuario está activo';
COMMENT ON COLUMN users.verification_code IS 'Código de verificación del usuario';

-- Verificar que las columnas fueron creadas correctamente
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns 
WHERE table_name = 'users' 
AND column_name IN ('assignments', 'emisor_type', 'institution_name', 'is_active', 'verification_code')
ORDER BY column_name;

