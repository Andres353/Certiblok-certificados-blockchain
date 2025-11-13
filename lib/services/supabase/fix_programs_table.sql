-- Script unificado para corregir la tabla 'programs' en Supabase
-- Este script asegura que todas las columnas necesarias estén presentes

-- 1. Verificar estructura actual de la tabla
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns 
WHERE table_name = 'programs' 
ORDER BY ordinal_position;

-- 2. Agregar columnas faltantes si no existen
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

-- 3. Renombrar 'code' a 'program_code' si existe la columna 'code'
DO $$ 
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'programs' AND column_name = 'code') THEN
        -- Verificar si program_code ya existe
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'programs' AND column_name = 'program_code') THEN
            ALTER TABLE programs RENAME COLUMN code TO program_code;
        ELSE
            -- Si ambas columnas existen, copiar datos de 'code' a 'program_code' y eliminar 'code'
            UPDATE programs SET program_code = code WHERE program_code IS NULL OR program_code = '';
            ALTER TABLE programs DROP COLUMN code;
        END IF;
    END IF;
END $$;

-- 4. Crear índices para mejorar rendimiento
CREATE INDEX IF NOT EXISTS idx_programs_status ON programs(status);
CREATE INDEX IF NOT EXISTS idx_programs_institution_id ON programs(institution_id);
CREATE INDEX IF NOT EXISTS idx_programs_faculty_id ON programs(faculty_id);
CREATE INDEX IF NOT EXISTS idx_programs_is_global ON programs(is_global);
CREATE INDEX IF NOT EXISTS idx_programs_program_code ON programs(program_code);
CREATE INDEX IF NOT EXISTS idx_programs_faculty_name ON programs(faculty_name);
CREATE INDEX IF NOT EXISTS idx_programs_institution_name ON programs(institution_name);

-- 5. Agregar comentarios a las columnas
COMMENT ON COLUMN programs.status IS 'Estado del programa: active, inactive';
COMMENT ON COLUMN programs.is_global IS 'Indica si es un programa global disponible para todas las instituciones';
COMMENT ON COLUMN programs.deleted_at IS 'Fecha de eliminación (soft delete)';
COMMENT ON COLUMN programs.modality IS 'Modalidad del programa: presencial, virtual, mixta';
COMMENT ON COLUMN programs.duration IS 'Duración del programa en semestres';
COMMENT ON COLUMN programs.description IS 'Descripción detallada del programa';
COMMENT ON COLUMN programs.program_code IS 'Código único del programa (ej: ING-SIS-001)';
COMMENT ON COLUMN programs.faculty_name IS 'Nombre de la facultad a la que pertenece el programa';
COMMENT ON COLUMN programs.institution_name IS 'Nombre de la institución a la que pertenece el programa';

-- 6. Verificar estructura final
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns 
WHERE table_name = 'programs' 
ORDER BY ordinal_position;

-- 7. Mostrar datos actuales en la tabla
SELECT id, name, program_code, institution_id, institution_name, faculty_name, status, created_at
FROM programs 
ORDER BY created_at DESC 
LIMIT 10;
