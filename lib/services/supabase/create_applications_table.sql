-- Script para crear la tabla applications en Supabase
-- Esta tabla maneja las postulaciones de estudiantes a programas

CREATE TABLE applications (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    student_id UUID REFERENCES users(id) ON DELETE CASCADE NOT NULL,
    student_name VARCHAR(255) NOT NULL,
    student_email VARCHAR(255) NOT NULL,
    program_id UUID REFERENCES programs_opportunities(id) ON DELETE CASCADE NOT NULL,
    program_title VARCHAR(255) NOT NULL,
    institution_id UUID REFERENCES institutions(id) ON DELETE CASCADE NOT NULL,
    institution_name VARCHAR(255) NOT NULL,
    status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'under_review', 'approved', 'rejected', 'withdrawn')),
    cv_url TEXT,
    cv_file_name VARCHAR(255),
    selected_certificates TEXT[] DEFAULT '{}',
    certificate_details JSONB DEFAULT '[]'::jsonb,
    motivation_letter TEXT,
    motivation_pdf_data TEXT,
    motivation_pdf_file_name VARCHAR(255),
    additional_documents JSONB DEFAULT '{}',
    submitted_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    reviewed_by UUID REFERENCES users(id) ON DELETE SET NULL,
    reviewed_by_name VARCHAR(255),
    reviewed_at TIMESTAMP WITH TIME ZONE,
    notes TEXT,
    rejection_reason TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Índices para mejorar el rendimiento
CREATE INDEX idx_applications_student_id ON applications(student_id);
CREATE INDEX idx_applications_program_id ON applications(program_id);
CREATE INDEX idx_applications_institution_id ON applications(institution_id);
CREATE INDEX idx_applications_status ON applications(status);
CREATE INDEX idx_applications_submitted_at ON applications(submitted_at);
CREATE INDEX idx_applications_reviewed_by ON applications(reviewed_by);

-- Comentarios en la tabla
COMMENT ON TABLE applications IS 'Tabla para gestionar postulaciones de estudiantes a programas de oportunidad';
COMMENT ON COLUMN applications.student_id IS 'ID del estudiante que postula';
COMMENT ON COLUMN applications.student_name IS 'Nombre completo del estudiante';
COMMENT ON COLUMN applications.student_email IS 'Correo electrónico del estudiante';
COMMENT ON COLUMN applications.program_id IS 'ID del programa al que postula';
COMMENT ON COLUMN applications.program_title IS 'Título del programa';
COMMENT ON COLUMN applications.institution_id IS 'ID de la institución del programa';
COMMENT ON COLUMN applications.institution_name IS 'Nombre de la institución';
COMMENT ON COLUMN applications.status IS 'Estado de la postulación: pending, under_review, approved, rejected, withdrawn';
COMMENT ON COLUMN applications.cv_url IS 'URL del CV subido';
COMMENT ON COLUMN applications.cv_file_name IS 'Nombre del archivo CV';
COMMENT ON COLUMN applications.selected_certificates IS 'Array de IDs de certificados seleccionados';
COMMENT ON COLUMN applications.certificate_details IS 'Detalles de los certificados seleccionados en formato JSON';
COMMENT ON COLUMN applications.motivation_letter IS 'Carta de motivación del estudiante';
COMMENT ON COLUMN applications.submitted_at IS 'Fecha y hora en que se envió la postulación';
COMMENT ON COLUMN applications.reviewed_by IS 'ID del usuario que revisó la postulación';
COMMENT ON COLUMN applications.reviewed_by_name IS 'Nombre del usuario que revisó la postulación';
COMMENT ON COLUMN applications.reviewed_at IS 'Fecha y hora en que se revisó la postulación';
COMMENT ON COLUMN applications.notes IS 'Notas adicionales de la revisión';
COMMENT ON COLUMN applications.rejection_reason IS 'Razón del rechazo (si aplica)';

-- Trigger para actualizar updated_at
CREATE TRIGGER update_applications_updated_at 
BEFORE UPDATE ON applications 
FOR EACH ROW 
EXECUTE FUNCTION update_updated_at_column();


