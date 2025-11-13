-- Script para agregar columnas faltantes a la tabla 'programs'
-- Ejecutar en el SQL Editor de Supabase

-- Agregar columna 'status' a la tabla programs
ALTER TABLE programs 
ADD COLUMN IF NOT EXISTS status VARCHAR(20) DEFAULT 'active';

-- Agregar columna 'is_global' a la tabla programs
ALTER TABLE programs 
ADD COLUMN IF NOT EXISTS is_global BOOLEAN DEFAULT false;

-- Agregar columna 'deleted_at' a la tabla programs
ALTER TABLE programs 
ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMP WITH TIME ZONE;

-- Agregar columna 'updated_at' a la tabla programs
ALTER TABLE programs 
ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();

-- Agregar columna 'created_at' a la tabla programs
ALTER TABLE programs 
ADD COLUMN IF NOT EXISTS created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();

-- Agregar columna 'modality' a la tabla programs
ALTER TABLE programs 
ADD COLUMN IF NOT EXISTS modality VARCHAR(50) DEFAULT 'presencial';

-- Agregar columna 'duration' a la tabla programs
ALTER TABLE programs 
ADD COLUMN IF NOT EXISTS duration INTEGER DEFAULT 10;

-- Agregar columna 'description' a la tabla programs
ALTER TABLE programs 
ADD COLUMN IF NOT EXISTS description TEXT;

-- Agregar índices para mejorar rendimiento
CREATE INDEX IF NOT EXISTS idx_programs_status ON programs(status);
CREATE INDEX IF NOT EXISTS idx_programs_institution_id ON programs(institution_id);
CREATE INDEX IF NOT EXISTS idx_programs_faculty_id ON programs(faculty_id);
CREATE INDEX IF NOT EXISTS idx_programs_is_global ON programs(is_global);

-- Agregar comentarios a las columnas
COMMENT ON COLUMN programs.status IS 'Estado del programa: active, inactive';
COMMENT ON COLUMN programs.is_global IS 'Indica si es un programa global disponible para todas las instituciones';
COMMENT ON COLUMN programs.deleted_at IS 'Fecha de eliminación (soft delete)';
COMMENT ON COLUMN programs.modality IS 'Modalidad del programa: presencial, virtual, mixta';
COMMENT ON COLUMN programs.duration IS 'Duración del programa en semestres';
COMMENT ON COLUMN programs.description IS 'Descripción detallada del programa';

-- Verificar que las columnas se agregaron correctamente
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns 
WHERE table_name = 'programs' 
ORDER BY ordinal_position;
