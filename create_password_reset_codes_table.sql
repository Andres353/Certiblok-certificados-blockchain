-- Script para crear la tabla password_reset_codes en Supabase
-- Esta tabla almacena los códigos de verificación para restablecer contraseñas

-- Primero, eliminar la tabla si existe (para empezar desde cero)
DROP TABLE IF EXISTS password_reset_codes CASCADE;

-- Crear la tabla con la estructura correcta
CREATE TABLE password_reset_codes (
  email TEXT PRIMARY KEY,
  code TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  used BOOLEAN DEFAULT FALSE,
  expires_at TIMESTAMPTZ NOT NULL,
  used_at TIMESTAMPTZ
);

-- Índice para búsquedas rápidas por email
CREATE INDEX IF NOT EXISTS idx_password_reset_codes_email ON password_reset_codes(email);

-- Índice para limpiar códigos expirados
CREATE INDEX IF NOT EXISTS idx_password_reset_codes_expires_at ON password_reset_codes(expires_at);

-- Comentarios en la tabla
COMMENT ON TABLE password_reset_codes IS 'Almacena códigos de verificación para restablecer contraseñas';
COMMENT ON COLUMN password_reset_codes.email IS 'Email del usuario que solicita el restablecimiento';
COMMENT ON COLUMN password_reset_codes.code IS 'Código de verificación de 6 dígitos';
COMMENT ON COLUMN password_reset_codes.created_at IS 'Fecha y hora de creación del código';
COMMENT ON COLUMN password_reset_codes.used IS 'Indica si el código ya fue utilizado';
COMMENT ON COLUMN password_reset_codes.expires_at IS 'Fecha y hora de expiración del código (15 minutos después de la creación)';
COMMENT ON COLUMN password_reset_codes.used_at IS 'Fecha y hora en que se utilizó el código';

-- Política RLS: Permitir que cualquier usuario pueda insertar y leer sus propios códigos
-- (En producción, podrías querer restringir esto más)
ALTER TABLE password_reset_codes ENABLE ROW LEVEL SECURITY;

-- Eliminar políticas existentes si las hay (por si acaso)
DROP POLICY IF EXISTS "Anyone can insert password reset codes" ON password_reset_codes;
DROP POLICY IF EXISTS "Anyone can read password reset codes" ON password_reset_codes;
DROP POLICY IF EXISTS "Anyone can update password reset codes" ON password_reset_codes;
DROP POLICY IF EXISTS "Anyone can delete password reset codes" ON password_reset_codes;

-- Política para permitir insertar códigos (cualquiera puede solicitar un código)
CREATE POLICY "Anyone can insert password reset codes"
ON password_reset_codes
FOR INSERT
TO public
WITH CHECK (true);

-- Política para permitir leer códigos (cualquiera puede verificar su código)
CREATE POLICY "Anyone can read password reset codes"
ON password_reset_codes
FOR SELECT
TO public
USING (true);

-- Política para permitir actualizar códigos (marcar como usado)
CREATE POLICY "Anyone can update password reset codes"
ON password_reset_codes
FOR UPDATE
TO public
USING (true);

-- Política para permitir eliminar códigos expirados (para limpieza)
CREATE POLICY "Anyone can delete password reset codes"
ON password_reset_codes
FOR DELETE
TO public
USING (true);

