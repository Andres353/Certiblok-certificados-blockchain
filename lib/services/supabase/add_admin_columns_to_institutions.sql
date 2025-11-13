-- Agregar columnas de administrador a la tabla institutions
-- Ejecutar este script en el SQL Editor de Supabase

ALTER TABLE institutions 
ADD COLUMN IF NOT EXISTS admin_email VARCHAR(255),
ADD COLUMN IF NOT EXISTS admin_password_hash VARCHAR(255),
ADD COLUMN IF NOT EXISTS admin_must_change_password BOOLEAN DEFAULT false,
ADD COLUMN IF NOT EXISTS admin_is_temporary_password BOOLEAN DEFAULT false,
ADD COLUMN IF NOT EXISTS admin_name VARCHAR(255),
ADD COLUMN IF NOT EXISTS admin_user_id UUID REFERENCES users(id);

-- Agregar comentarios para documentar las columnas
COMMENT ON COLUMN institutions.admin_email IS 'Email del administrador de la institución';
COMMENT ON COLUMN institutions.admin_password_hash IS 'Hash de la contraseña temporal del administrador';
COMMENT ON COLUMN institutions.admin_must_change_password IS 'Indica si el admin debe cambiar su contraseña';
COMMENT ON COLUMN institutions.admin_is_temporary_password IS 'Indica si la contraseña es temporal';
COMMENT ON COLUMN institutions.admin_name IS 'Nombre del administrador de la institución';
COMMENT ON COLUMN institutions.admin_user_id IS 'ID del usuario administrador en la tabla users';

-- Crear índices para mejorar el rendimiento
CREATE INDEX IF NOT EXISTS idx_institutions_admin_email ON institutions(admin_email);
CREATE INDEX IF NOT EXISTS idx_institutions_admin_user_id ON institutions(admin_user_id);
