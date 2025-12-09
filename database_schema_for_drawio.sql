-- Esquema SQL para importar en Draw.io
-- En Draw.io: Insert > Advanced > From Database > SQL

CREATE TABLE institutions (
    id UUID PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    short_name VARCHAR(50),
    description TEXT,
    logo_url TEXT,
    institution_code VARCHAR(10) UNIQUE NOT NULL,
    colors JSONB,
    settings JSONB,
    status VARCHAR(20) DEFAULT 'active',
    admin_email VARCHAR(255),
    admin_name VARCHAR(255),
    admin_password_hash VARCHAR(255),
    admin_must_change_password BOOLEAN DEFAULT false,
    admin_is_temporary_password BOOLEAN DEFAULT false,
    created_by UUID REFERENCES users(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE users (
    id UUID PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    salt VARCHAR(255),
    full_name VARCHAR(255) NOT NULL,
    role VARCHAR(50) NOT NULL,
    institution_id UUID REFERENCES institutions(id) ON DELETE SET NULL,
    student_id VARCHAR(50),
    program_id VARCHAR(50),
    faculty_id VARCHAR(50),
    program VARCHAR(255),
    faculty VARCHAR(255),
    phone VARCHAR(20),
    document VARCHAR(50),
    birth_date VARCHAR(20),
    address TEXT,
    assignments JSONB DEFAULT '[]',
    emisor_type VARCHAR(50),
    institution_name VARCHAR(255),
    is_verified BOOLEAN DEFAULT false,
    must_change_password BOOLEAN DEFAULT false,
    is_temporary_password BOOLEAN DEFAULT false,
    is_active BOOLEAN DEFAULT true,
    verification_code VARCHAR(10) DEFAULT '000000',
    login_attempts INTEGER DEFAULT 0,
    locked_until TIMESTAMP WITH TIME ZONE,
    last_login TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE faculties (
    id UUID PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    institution_id UUID REFERENCES institutions(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE programs (
    id UUID PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    faculty_id UUID REFERENCES faculties(id) ON DELETE CASCADE,
    institution_id UUID REFERENCES institutions(id) ON DELETE CASCADE,
    program_code VARCHAR(50) UNIQUE NOT NULL,
    is_global BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE certificates (
    id UUID PRIMARY KEY,
    unique_hash VARCHAR(255) UNIQUE NOT NULL,
    institution_id UUID REFERENCES institutions(id) ON DELETE CASCADE,
    student_id UUID REFERENCES users(id) ON DELETE CASCADE,
    certificate_type VARCHAR(50) NOT NULL,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    qr_code TEXT,
    status VARCHAR(20) DEFAULT 'active',
    issued_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    revoked_at TIMESTAMP WITH TIME ZONE,
    expires_at TIMESTAMP WITH TIME ZONE,
    validation_history JSONB DEFAULT '[]',
    pdf_url TEXT,
    template_id UUID REFERENCES certificate_templates(id),
    data JSONB,
    faculty_id VARCHAR(255),
    faculty_name VARCHAR(255),
    program_id VARCHAR(255),
    program_name VARCHAR(255),
    student_id_in_institution VARCHAR(255),
    issued_by_name VARCHAR(255),
    issued_by_role VARCHAR(50),
    template_data JSONB,
    custom_certificate_data TEXT,
    custom_certificate_filename VARCHAR(255),
    custom_certificate_mimetype VARCHAR(100),
    is_pdf BOOLEAN DEFAULT false,
    institution_code VARCHAR(50),
    institution_name VARCHAR(255),
    issued_by VARCHAR(255),
    student_email VARCHAR(255),
    student_name VARCHAR(255),
    blockchain_hash TEXT,
    blockchain_network VARCHAR(50),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE certificate_templates (
    id UUID PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    institution_id UUID REFERENCES institutions(id) ON DELETE CASCADE,
    template_design JSONB NOT NULL,
    template_layout JSONB NOT NULL,
    template_fields JSONB NOT NULL,
    is_active BOOLEAN DEFAULT true,
    created_by UUID REFERENCES users(id) ON DELETE SET NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE student_institutions (
    id UUID PRIMARY KEY,
    student_id UUID REFERENCES users(id) ON DELETE CASCADE,
    institution_id UUID REFERENCES institutions(id) ON DELETE CASCADE,
    program_id UUID REFERENCES programs(id) ON DELETE CASCADE,
    status VARCHAR(20) DEFAULT 'active',
    joined_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    left_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(student_id, institution_id)
);

CREATE TABLE institution_requests (
    id UUID PRIMARY KEY,
    institution_name VARCHAR(255) NOT NULL,
    short_name VARCHAR(50),
    institution_type VARCHAR(50),
    contact_name VARCHAR(255) NOT NULL,
    contact_email VARCHAR(255) NOT NULL,
    contact_phone VARCHAR(20),
    address TEXT,
    city VARCHAR(100),
    country VARCHAR(100),
    website VARCHAR(255),
    description TEXT,
    logo_url TEXT,
    documents TEXT,
    status VARCHAR(20) DEFAULT 'pending',
    requested_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    reviewed_by UUID REFERENCES users(id) ON DELETE SET NULL,
    reviewed_at TIMESTAMP WITH TIME ZONE,
    rejection_reason TEXT,
    institution_id UUID REFERENCES institutions(id) ON DELETE SET NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE password_reset_codes (
    id UUID PRIMARY KEY,
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    code VARCHAR(10) NOT NULL,
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    used BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE security_logs (
    id UUID PRIMARY KEY,
    user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    event VARCHAR(50) NOT NULL,
    description TEXT,
    ip_address VARCHAR(45),
    user_agent TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE page_content (
    id UUID PRIMARY KEY,
    page_name VARCHAR(50) UNIQUE NOT NULL,
    content JSONB NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE grouped_qrs (
    id UUID PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    qr_url TEXT NOT NULL,
    certificate_ids TEXT[] NOT NULL,
    certificate_titles TEXT[] NOT NULL,
    student_id UUID REFERENCES users(id) ON DELETE CASCADE,
    student_name VARCHAR(255) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE programs_opportunities (
    id UUID PRIMARY KEY,
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

CREATE TABLE applications (
    id UUID PRIMARY KEY,
    student_id UUID REFERENCES users(id) ON DELETE CASCADE NOT NULL,
    student_name VARCHAR(255) NOT NULL,
    student_email VARCHAR(255) NOT NULL,
    program_id UUID REFERENCES programs_opportunities(id) ON DELETE CASCADE NOT NULL,
    program_title VARCHAR(255) NOT NULL,
    institution_id UUID REFERENCES institutions(id) ON DELETE CASCADE NOT NULL,
    institution_name VARCHAR(255) NOT NULL,
    status VARCHAR(20) DEFAULT 'pending',
    cv_url TEXT,
    cv_file_name VARCHAR(255),
    selected_certificates TEXT[] DEFAULT '{}',
    certificate_details JSONB DEFAULT '[]',
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


