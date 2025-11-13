-- lib/services/supabase/create_grouped_qrs_table.sql
-- Migración para crear la tabla grouped_qrs

-- Crear tabla grouped_qrs
CREATE TABLE IF NOT EXISTS grouped_qrs (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    qr_url TEXT NOT NULL,
    certificate_ids TEXT[] NOT NULL, -- Array de IDs de certificados
    certificate_titles TEXT[] NOT NULL, -- Array de títulos de certificados
    student_id UUID REFERENCES users(id) ON DELETE CASCADE,
    student_name VARCHAR(255) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Crear índice para optimización
CREATE INDEX IF NOT EXISTS idx_grouped_qrs_student_id ON grouped_qrs(student_id);

-- Crear trigger para actualizar updated_at
CREATE TRIGGER update_grouped_qrs_updated_at 
    BEFORE UPDATE ON grouped_qrs 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

-- Comentarios para documentación
COMMENT ON TABLE grouped_qrs IS 'Tabla para almacenar QRs agrupados guardados por los estudiantes';
COMMENT ON COLUMN grouped_qrs.certificate_ids IS 'Array de IDs de certificados incluidos en el QR agrupado';
COMMENT ON COLUMN grouped_qrs.certificate_titles IS 'Array de títulos de certificados para mostrar en la interfaz';
COMMENT ON COLUMN grouped_qrs.qr_url IS 'URL del QR que apunta a la página de verificación con múltiples certificados';
