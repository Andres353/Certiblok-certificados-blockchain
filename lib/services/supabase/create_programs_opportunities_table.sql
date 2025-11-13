-- Script para crear la tabla programs_opportunities en Supabase
-- Esta tabla maneja programas de pasantías y oportunidades académicas

CREATE TABLE programs_opportunities (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    institution_id UUID REFERENCES institutions(id) ON DELETE CASCADE,
    institution_name VARCHAR(255) NOT NULL,
    faculty_id UUID REFERENCES faculties(id) ON DELETE SET NULL,
    faculty_name VARCHAR(255),
    career_ids TEXT[] DEFAULT '{}',
    career_names TEXT[] DEFAULT '{}',
    requirements TEXT[] DEFAULT '{}',
    application_deadline TIMESTAMP WITH TIME ZONE NOT NULL,
    max_applications INTEGER DEFAULT 0,
    current_applications INTEGER DEFAULT 0,
    created_by UUID REFERENCES users(id) ON DELETE SET NULL,
    created_by_name VARCHAR(255),
    additional_info JSONB DEFAULT '{}',
    image_url TEXT,
    pdf_url TEXT,
    pdf_file_name VARCHAR(255),
    pdf_data TEXT,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Índices para mejorar el rendimiento
CREATE INDEX idx_programs_opportunities_institution_id ON programs_opportunities(institution_id);
CREATE INDEX idx_programs_opportunities_faculty_id ON programs_opportunities(faculty_id);
CREATE INDEX idx_programs_opportunities_created_by ON programs_opportunities(created_by);
CREATE INDEX idx_programs_opportunities_is_active ON programs_opportunities(is_active);
CREATE INDEX idx_programs_opportunities_application_deadline ON programs_opportunities(application_deadline);
CREATE INDEX idx_programs_opportunities_created_at ON programs_opportunities(created_at);

-- Comentarios en la tabla
COMMENT ON TABLE programs_opportunities IS 'Tabla para gestionar programas de pasantías y oportunidades académicas';
COMMENT ON COLUMN programs_opportunities.title IS 'Título del programa de oportunidad';
COMMENT ON COLUMN programs_opportunities.description IS 'Descripción detallada del programa';
COMMENT ON COLUMN programs_opportunities.institution_id IS 'ID de la institución que ofrece el programa';
COMMENT ON COLUMN programs_opportunities.institution_name IS 'Nombre de la institución';
COMMENT ON COLUMN programs_opportunities.faculty_id IS 'ID de la facultad (opcional)';
COMMENT ON COLUMN programs_opportunities.faculty_name IS 'Nombre de la facultad (opcional)';
COMMENT ON COLUMN programs_opportunities.career_ids IS 'Array de IDs de carreras elegibles';
COMMENT ON COLUMN programs_opportunities.career_names IS 'Array de nombres de carreras elegibles';
COMMENT ON COLUMN programs_opportunities.requirements IS 'Array de requisitos del programa';
COMMENT ON COLUMN programs_opportunities.application_deadline IS 'Fecha límite para postularse';
COMMENT ON COLUMN programs_opportunities.max_applications IS 'Número máximo de aplicaciones permitidas';
COMMENT ON COLUMN programs_opportunities.current_applications IS 'Número actual de aplicaciones';
COMMENT ON COLUMN programs_opportunities.created_by IS 'ID del usuario que creó el programa';
COMMENT ON COLUMN programs_opportunities.created_by_name IS 'Nombre del usuario que creó el programa';
COMMENT ON COLUMN programs_opportunities.additional_info IS 'Información adicional en formato JSON';
COMMENT ON COLUMN programs_opportunities.image_url IS 'URL de la imagen del programa';
COMMENT ON COLUMN programs_opportunities.pdf_url IS 'URL del PDF del programa';
COMMENT ON COLUMN programs_opportunities.pdf_file_name IS 'Nombre del archivo PDF';
COMMENT ON COLUMN programs_opportunities.pdf_data IS 'Datos del PDF en base64';
COMMENT ON COLUMN programs_opportunities.is_active IS 'Indica si el programa está activo';
