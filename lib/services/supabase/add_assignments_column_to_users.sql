-- Script para agregar la columna 'assignments' a la tabla 'users'
-- Esta columna es necesaria para el sistema de emisores

-- Agregar la columna 'assignments' si no existe
ALTER TABLE users 
ADD COLUMN IF NOT EXISTS assignments JSONB DEFAULT '[]'::jsonb;

-- Crear índice para mejorar rendimiento en consultas de assignments
CREATE INDEX IF NOT EXISTS idx_users_assignments ON users USING GIN (assignments);

-- Agregar comentario a la columna
COMMENT ON COLUMN users.assignments IS 'Array de asignaciones de carreras para emisores';

-- Verificar que la columna fue creada correctamente
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns 
WHERE table_name = 'users' 
AND column_name = 'assignments';

