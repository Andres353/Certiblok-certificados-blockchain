-- Migración para agregar las nuevas columnas a la tabla institution_requests
-- Ejecutar este SQL en el SQL Editor de Supabase

-- Agregar columna 'department' (texto)
ALTER TABLE institution_requests 
ADD COLUMN IF NOT EXISTS department TEXT;

-- Agregar columna 'ruc' (texto)
ALTER TABLE institution_requests 
ADD COLUMN IF NOT EXISTS ruc TEXT;

-- Agregar columna 'ministerial_resolution' (texto)
ALTER TABLE institution_requests 
ADD COLUMN IF NOT EXISTS ministerial_resolution TEXT;

-- Comentarios opcionales para documentar las columnas
COMMENT ON COLUMN institution_requests.department IS 'Departamento de Bolivia donde se encuentra la institución';
COMMENT ON COLUMN institution_requests.ruc IS 'Registro Único de Contribuyente de la institución';
COMMENT ON COLUMN institution_requests.ministerial_resolution IS 'Número de Resolución Ministerial que autoriza el funcionamiento';

