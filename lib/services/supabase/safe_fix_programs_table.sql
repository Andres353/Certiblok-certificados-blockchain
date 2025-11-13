-- Script SEGURO para corregir la tabla 'programs' en Supabase
-- Este script NO afecta la funcionalidad de creación de carreras

-- 1. Verificar estructura actual de la tabla
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns 
WHERE table_name = 'programs' 
ORDER BY ordinal_position;

-- 2. Agregar columnas faltantes si no existen (SIN tocar las existentes)
ALTER TABLE programs 
ADD COLUMN IF NOT EXISTS status VARCHAR(20) DEFAULT 'active';

ALTER TABLE programs 
ADD COLUMN IF NOT EXISTS is_global BOOLEAN DEFAULT false;

ALTER TABLE programs 
ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMP WITH TIME ZONE;

ALTER TABLE programs 
ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();

ALTER TABLE programs 
ADD COLUMN IF NOT EXISTS created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();

ALTER TABLE programs 
ADD COLUMN IF NOT EXISTS modality VARCHAR(50) DEFAULT 'presencial';

ALTER TABLE programs 
ADD COLUMN IF NOT EXISTS duration INTEGER DEFAULT 10;

ALTER TABLE programs 
ADD COLUMN IF NOT EXISTS description TEXT;

ALTER TABLE programs 
ADD COLUMN IF NOT EXISTS faculty_name VARCHAR(255);

ALTER TABLE programs 
ADD COLUMN IF NOT EXISTS institution_name VARCHAR(255);

-- 3. Solo agregar program_code si no existe (NO renombrar code)
ALTER TABLE programs 
ADD COLUMN IF NOT EXISTS program_code VARCHAR(50);

-- 4. Si existe la columna 'code' pero no 'program_code', copiar los datos
UPDATE programs 
SET program_code = code 
WHERE program_code IS NULL AND code IS NOT NULL;

-- 5. Crear índices para mejorar rendimiento (solo si no existen)
CREATE INDEX IF NOT EXISTS idx_programs_status ON programs(status);
CREATE INDEX IF NOT EXISTS idx_programs_institution_id ON programs(institution_id);
CREATE INDEX IF NOT EXISTS idx_programs_faculty_id ON programs(faculty_id);
CREATE INDEX IF NOT EXISTS idx_programs_is_global ON programs(is_global);
CREATE INDEX IF NOT EXISTS idx_programs_program_code ON programs(program_code);
CREATE INDEX IF NOT EXISTS idx_programs_faculty_name ON programs(faculty_name);
CREATE INDEX IF NOT EXISTS idx_programs_institution_name ON programs(institution_name);

-- 6. Agregar comentarios a las columnas
COMMENT ON COLUMN programs.status IS 'Estado del programa: active, inactive';
COMMENT ON COLUMN programs.is_global IS 'Indica si es un programa global disponible para todas las instituciones';
COMMENT ON COLUMN programs.deleted_at IS 'Fecha de eliminación (soft delete)';
COMMENT ON COLUMN programs.modality IS 'Modalidad del programa: presencial, virtual, mixta';
COMMENT ON COLUMN programs.duration IS 'Duración del programa en semestres';
COMMENT ON COLUMN programs.description IS 'Descripción detallada del programa';
COMMENT ON COLUMN programs.program_code IS 'Código único del programa (ej: ING-SIS-001)';
COMMENT ON COLUMN programs.faculty_name IS 'Nombre de la facultad a la que pertenece el programa';
COMMENT ON COLUMN programs.institution_name IS 'Nombre de la institución a la que pertenece el programa';

-- 7. Verificar estructura final
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns 
WHERE table_name = 'programs' 
ORDER BY ordinal_position;

-- 8. Mostrar datos actuales en la tabla
SELECT id, name, program_code, code, institution_id, institution_name, faculty_name, status, created_at
FROM programs 
ORDER BY created_at DESC 
LIMIT 10;
