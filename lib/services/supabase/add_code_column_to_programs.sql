-- Script para agregar la columna 'code' a la tabla 'programs'
-- Esta columna es necesaria para el sistema de códigos únicos de programas

-- Agregar la columna 'code' si no existe
ALTER TABLE programs 
ADD COLUMN IF NOT EXISTS code VARCHAR(50);

-- Crear índice único para la columna 'code' para evitar duplicados
CREATE UNIQUE INDEX IF NOT EXISTS idx_programs_code ON programs(code);

-- Agregar comentario a la columna
COMMENT ON COLUMN programs.code IS 'Código único del programa (ej: ING-SIS-001)';

-- Verificar que la columna fue creada correctamente
SELECT column_name, data_type, is_nullable 
FROM information_schema.columns 
WHERE table_name = 'programs' 
AND column_name = 'code';
