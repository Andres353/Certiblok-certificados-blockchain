-- Script para agregar columnas faltantes a la tabla 'programs'
-- Basado en el uso del SupabaseCareersService

-- Agregar columna 'code' si no existe
ALTER TABLE programs 
ADD COLUMN IF NOT EXISTS code VARCHAR(50);

-- Agregar columna 'faculty_name' si no existe
ALTER TABLE programs 
ADD COLUMN IF NOT EXISTS faculty_name VARCHAR(255);

-- Agregar columna 'institution_name' si no existe
ALTER TABLE programs 
ADD COLUMN IF NOT EXISTS institution_name VARCHAR(255);

-- Crear índices para mejorar rendimiento
CREATE UNIQUE INDEX IF NOT EXISTS idx_programs_code ON programs(code);
CREATE INDEX IF NOT EXISTS idx_programs_faculty_name ON programs(faculty_name);
CREATE INDEX IF NOT EXISTS idx_programs_institution_name ON programs(institution_name);

-- Agregar comentarios a las columnas
COMMENT ON COLUMN programs.code IS 'Código único del programa (ej: ING-SIS-001)';
COMMENT ON COLUMN programs.faculty_name IS 'Nombre de la facultad a la que pertenece el programa';
COMMENT ON COLUMN programs.institution_name IS 'Nombre de la institución a la que pertenece el programa';

-- Verificar que las columnas fueron creadas correctamente
SELECT column_name, data_type, is_nullable 
FROM information_schema.columns 
WHERE table_name = 'programs' 
AND column_name IN ('code', 'faculty_name', 'institution_name')
ORDER BY column_name;
