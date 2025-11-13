-- Script para agregar columnas faltantes a la tabla 'certificates'
-- Necesario para la emisión de certificados

-- Agregar columna 'data' para datos adicionales del certificado
ALTER TABLE certificates 
ADD COLUMN IF NOT EXISTS data JSONB;

-- Agregar columna 'faculty_id' para ID de la facultad
ALTER TABLE certificates 
ADD COLUMN IF NOT EXISTS faculty_id VARCHAR(255);

-- Agregar columna 'faculty_name' para nombre de la facultad
ALTER TABLE certificates 
ADD COLUMN IF NOT EXISTS faculty_name VARCHAR(255);

-- Agregar columna 'program_id' para ID del programa
ALTER TABLE certificates 
ADD COLUMN IF NOT EXISTS program_id VARCHAR(255);

-- Agregar columna 'program_name' para nombre del programa
ALTER TABLE certificates 
ADD COLUMN IF NOT EXISTS program_name VARCHAR(255);

-- Agregar columna 'student_id_in_institution' para ID del estudiante en la institución
ALTER TABLE certificates 
ADD COLUMN IF NOT EXISTS student_id_in_institution VARCHAR(255);

-- Agregar columna 'issued_by_name' para nombre del emisor
ALTER TABLE certificates 
ADD COLUMN IF NOT EXISTS issued_by_name VARCHAR(255);

-- Agregar columna 'issued_by_role' para rol del emisor
ALTER TABLE certificates 
ADD COLUMN IF NOT EXISTS issued_by_role VARCHAR(50);

-- Agregar columna 'template_id' para ID de la plantilla
ALTER TABLE certificates 
ADD COLUMN IF NOT EXISTS template_id VARCHAR(255);

-- Agregar columna 'template_data' para datos de la plantilla
ALTER TABLE certificates 
ADD COLUMN IF NOT EXISTS template_data JSONB;

-- Agregar columna 'custom_certificate_data' para certificado personalizado
ALTER TABLE certificates 
ADD COLUMN IF NOT EXISTS custom_certificate_data TEXT;

-- Agregar columna 'custom_certificate_filename' para nombre del archivo personalizado
ALTER TABLE certificates 
ADD COLUMN IF NOT EXISTS custom_certificate_filename VARCHAR(255);

-- Agregar columna 'custom_certificate_mimetype' para tipo MIME del archivo
ALTER TABLE certificates 
ADD COLUMN IF NOT EXISTS custom_certificate_mimetype VARCHAR(100);

-- Agregar columna 'is_pdf' para indicar si es PDF
ALTER TABLE certificates 
ADD COLUMN IF NOT EXISTS is_pdf BOOLEAN DEFAULT false;

-- Agregar columna 'institution_code' para código de la institución
ALTER TABLE certificates 
ADD COLUMN IF NOT EXISTS institution_code VARCHAR(50);

-- Agregar columna 'institution_name' para nombre de la institución
ALTER TABLE certificates 
ADD COLUMN IF NOT EXISTS institution_name VARCHAR(255);

-- Agregar columna 'issued_by' para ID de quien emitió el certificado
ALTER TABLE certificates 
ADD COLUMN IF NOT EXISTS issued_by VARCHAR(255);

-- Agregar columna 'student_email' para email del estudiante
ALTER TABLE certificates 
ADD COLUMN IF NOT EXISTS student_email VARCHAR(255);

-- Agregar columna 'student_name' para nombre del estudiante
ALTER TABLE certificates 
ADD COLUMN IF NOT EXISTS student_name VARCHAR(255);

-- Crear índices para mejorar rendimiento
CREATE INDEX IF NOT EXISTS idx_certificates_data ON certificates USING GIN (data);
CREATE INDEX IF NOT EXISTS idx_certificates_template_data ON certificates USING GIN (template_data);
CREATE INDEX IF NOT EXISTS idx_certificates_faculty_id ON certificates (faculty_id);
CREATE INDEX IF NOT EXISTS idx_certificates_program_id ON certificates (program_id);
CREATE INDEX IF NOT EXISTS idx_certificates_template_id ON certificates (template_id);
CREATE INDEX IF NOT EXISTS idx_certificates_institution_code ON certificates (institution_code);
CREATE INDEX IF NOT EXISTS idx_certificates_institution_name ON certificates (institution_name);
CREATE INDEX IF NOT EXISTS idx_certificates_issued_by ON certificates (issued_by);
CREATE INDEX IF NOT EXISTS idx_certificates_student_email ON certificates (student_email);
CREATE INDEX IF NOT EXISTS idx_certificates_student_name ON certificates (student_name);

-- Agregar comentarios a las columnas
COMMENT ON COLUMN certificates.data IS 'Datos adicionales del certificado (JSON)';
COMMENT ON COLUMN certificates.faculty_id IS 'ID de la facultad del estudiante';
COMMENT ON COLUMN certificates.faculty_name IS 'Nombre de la facultad del estudiante';
COMMENT ON COLUMN certificates.program_id IS 'ID del programa de estudios';
COMMENT ON COLUMN certificates.program_name IS 'Nombre del programa de estudios';
COMMENT ON COLUMN certificates.student_id_in_institution IS 'ID del estudiante en la institución';
COMMENT ON COLUMN certificates.issued_by_name IS 'Nombre de quien emitió el certificado';
COMMENT ON COLUMN certificates.issued_by_role IS 'Rol de quien emitió el certificado';
COMMENT ON COLUMN certificates.template_id IS 'ID de la plantilla utilizada';
COMMENT ON COLUMN certificates.template_data IS 'Datos de la plantilla utilizada (JSON)';
COMMENT ON COLUMN certificates.custom_certificate_data IS 'Datos del certificado personalizado (base64)';
COMMENT ON COLUMN certificates.custom_certificate_filename IS 'Nombre del archivo del certificado personalizado';
COMMENT ON COLUMN certificates.custom_certificate_mimetype IS 'Tipo MIME del certificado personalizado';
COMMENT ON COLUMN certificates.is_pdf IS 'Indica si el certificado personalizado es PDF';
COMMENT ON COLUMN certificates.institution_code IS 'Código de la institución que emitió el certificado';
COMMENT ON COLUMN certificates.institution_name IS 'Nombre de la institución que emitió el certificado';
COMMENT ON COLUMN certificates.issued_by IS 'ID de quien emitió el certificado';
COMMENT ON COLUMN certificates.student_email IS 'Email del estudiante que recibió el certificado';
COMMENT ON COLUMN certificates.student_name IS 'Nombre del estudiante que recibió el certificado';
