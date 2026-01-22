-- ============================================
-- POLÍTICAS RLS PARA SUPABASE STORAGE
-- CON AUTENTICACIÓN PERSONALIZADA (tabla users)
-- ============================================
-- Este archivo configura políticas que funcionan con
-- el sistema de autenticación personalizado que usa
-- la tabla 'users' en lugar de Supabase Auth
-- ============================================

-- ============================================
-- BUCKET: institution-logos (Público)
-- ============================================

-- Eliminar políticas existentes si las hay
DROP POLICY IF EXISTS "Authenticated users can upload logos" ON storage.objects;
DROP POLICY IF EXISTS "Anyone can upload logos" ON storage.objects;
DROP POLICY IF EXISTS "Anyone can read logos" ON storage.objects;
DROP POLICY IF EXISTS "Authenticated users can update logos" ON storage.objects;
DROP POLICY IF EXISTS "Authenticated users can delete logos" ON storage.objects;

-- Permitir a TODOS (autenticados y anónimos) subir logos
-- Esto es necesario para el registro de instituciones (no requiere autenticación)
CREATE POLICY "Anyone can upload logos"
ON storage.objects FOR INSERT
TO public
WITH CHECK (bucket_id = 'institution-logos');

-- Permitir a todos leer logos (público)
CREATE POLICY "Anyone can read logos"
ON storage.objects FOR SELECT
TO public
USING (bucket_id = 'institution-logos');

-- Permitir a usuarios autenticados actualizar logos
CREATE POLICY "Authenticated users can update logos"
ON storage.objects FOR UPDATE
TO authenticated
USING (bucket_id = 'institution-logos')
WITH CHECK (bucket_id = 'institution-logos');

-- Permitir a usuarios autenticados eliminar logos
CREATE POLICY "Authenticated users can delete logos"
ON storage.objects FOR DELETE
TO authenticated
USING (bucket_id = 'institution-logos');

-- ============================================
-- BUCKET: images (Público para lectura, autenticado para escritura)
-- ============================================

-- Eliminar políticas existentes si las hay
DROP POLICY IF EXISTS "Authenticated users can upload images" ON storage.objects;
DROP POLICY IF EXISTS "Users can upload images" ON storage.objects;
DROP POLICY IF EXISTS "Anyone can read images" ON storage.objects;
DROP POLICY IF EXISTS "Authenticated users can update images" ON storage.objects;
DROP POLICY IF EXISTS "Authenticated users can delete images" ON storage.objects;

-- POLÍTICA PERMISIVA: Permitir a usuarios autenticados en Supabase Auth O usuarios en tabla 'users'
-- Esta política permite subir imágenes si:
-- 1. El usuario está autenticado en Supabase Auth (auth.role() = 'authenticated')
-- 2. O si el usuario existe en la tabla 'users' (para autenticación personalizada)
CREATE POLICY "Users can upload images"
ON storage.objects FOR INSERT
TO public
WITH CHECK (
  bucket_id = 'images' AND (
    -- Usuario autenticado en Supabase Auth
    auth.role() = 'authenticated' OR
    auth.role() = 'service_role' OR
    -- O usuario existe en tabla users (autenticación personalizada)
    -- Verificamos que el email del usuario autenticado exista en la tabla users
    EXISTS (
      SELECT 1 FROM users 
      WHERE users.email = auth.jwt() ->> 'email'
      AND users.is_verified = true
    )
  )
);

-- Permitir a todos leer imágenes (público)
CREATE POLICY "Anyone can read images"
ON storage.objects FOR SELECT
TO public
USING (bucket_id = 'images');

-- Permitir a usuarios autenticados actualizar imágenes
CREATE POLICY "Authenticated users can update images"
ON storage.objects FOR UPDATE
TO authenticated
USING (bucket_id = 'images')
WITH CHECK (bucket_id = 'images');

-- Permitir a usuarios autenticados eliminar imágenes
CREATE POLICY "Authenticated users can delete images"
ON storage.objects FOR DELETE
TO authenticated
USING (bucket_id = 'images');

-- ============================================
-- BUCKET: signatures (Público para lectura, autenticado para escritura)
-- ============================================

-- Eliminar políticas existentes si las hay
DROP POLICY IF EXISTS "Authenticated users can upload signatures" ON storage.objects;
DROP POLICY IF EXISTS "Users can upload signatures" ON storage.objects;
DROP POLICY IF EXISTS "Anyone can read signatures" ON storage.objects;
DROP POLICY IF EXISTS "Authenticated users can update signatures" ON storage.objects;
DROP POLICY IF EXISTS "Authenticated users can delete signatures" ON storage.objects;

-- POLÍTICA PERMISIVA: Similar a images
CREATE POLICY "Users can upload signatures"
ON storage.objects FOR INSERT
TO public
WITH CHECK (
  bucket_id = 'signatures' AND (
    auth.role() = 'authenticated' OR
    auth.role() = 'service_role' OR
    EXISTS (
      SELECT 1 FROM users 
      WHERE users.email = auth.jwt() ->> 'email'
      AND users.is_verified = true
    )
  )
);

-- Permitir a todos leer firmas (público)
CREATE POLICY "Anyone can read signatures"
ON storage.objects FOR SELECT
TO public
USING (bucket_id = 'signatures');

-- Permitir a usuarios autenticados actualizar firmas
CREATE POLICY "Authenticated users can update signatures"
ON storage.objects FOR UPDATE
TO authenticated
USING (bucket_id = 'signatures')
WITH CHECK (bucket_id = 'signatures');

-- Permitir a usuarios autenticados eliminar firmas
CREATE POLICY "Authenticated users can delete signatures"
ON storage.objects FOR DELETE
TO authenticated
USING (bucket_id = 'signatures');

-- ============================================
-- BUCKET: pdfs (Privado)
-- ============================================

-- Eliminar políticas existentes si las hay
DROP POLICY IF EXISTS "Authenticated users can upload PDFs" ON storage.objects;
DROP POLICY IF EXISTS "Users can upload PDFs" ON storage.objects;
DROP POLICY IF EXISTS "Authenticated users can read PDFs" ON storage.objects;
DROP POLICY IF EXISTS "Authenticated users can update PDFs" ON storage.objects;
DROP POLICY IF EXISTS "Authenticated users can delete PDFs" ON storage.objects;

-- POLÍTICA PERMISIVA: Similar a images y signatures
CREATE POLICY "Users can upload PDFs"
ON storage.objects FOR INSERT
TO public
WITH CHECK (
  bucket_id = 'pdfs' AND (
    auth.role() = 'authenticated' OR
    auth.role() = 'service_role' OR
    EXISTS (
      SELECT 1 FROM users 
      WHERE users.email = auth.jwt() ->> 'email'
      AND users.is_verified = true
    )
  )
);

-- Permitir a usuarios autenticados leer PDFs
CREATE POLICY "Authenticated users can read PDFs"
ON storage.objects FOR SELECT
TO authenticated
USING (bucket_id = 'pdfs');

-- Permitir a usuarios autenticados actualizar PDFs
CREATE POLICY "Authenticated users can update PDFs"
ON storage.objects FOR UPDATE
TO authenticated
USING (bucket_id = 'pdfs')
WITH CHECK (bucket_id = 'pdfs');

-- Permitir a usuarios autenticados eliminar PDFs
CREATE POLICY "Authenticated users can delete PDFs"
ON storage.objects FOR DELETE
TO authenticated
USING (bucket_id = 'pdfs');

