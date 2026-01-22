-- ============================================
-- POLÍTICAS RLS PARA SUPABASE STORAGE - SIN AUTENTICACIÓN
-- ============================================
-- Esta versión permite subir archivos SIN autenticación
-- Todas las subidas son públicas (TO public)
-- ============================================

-- ============================================
-- BUCKET: institution-logos (Público)
-- ============================================

DROP POLICY IF EXISTS "Authenticated users can upload logos" ON storage.objects;
DROP POLICY IF EXISTS "Anyone can upload logos" ON storage.objects;
DROP POLICY IF EXISTS "Anyone can read logos" ON storage.objects;
DROP POLICY IF EXISTS "Authenticated users can update logos" ON storage.objects;
DROP POLICY IF EXISTS "Authenticated users can delete logos" ON storage.objects;

-- Permitir a TODOS subir logos (para registro de instituciones)
CREATE POLICY "Anyone can upload logos"
ON storage.objects FOR INSERT
TO public
WITH CHECK (bucket_id = 'institution-logos');

-- Permitir a todos leer logos
CREATE POLICY "Anyone can read logos"
ON storage.objects FOR SELECT
TO public
USING (bucket_id = 'institution-logos');

-- Permitir a usuarios autenticados actualizar/eliminar logos
CREATE POLICY "Authenticated users can update logos"
ON storage.objects FOR UPDATE
TO authenticated
USING (bucket_id = 'institution-logos')
WITH CHECK (bucket_id = 'institution-logos');

CREATE POLICY "Authenticated users can delete logos"
ON storage.objects FOR DELETE
TO authenticated
USING (bucket_id = 'institution-logos');

-- ============================================
-- BUCKET: images (Público para lectura y escritura de program_images)
-- ============================================

DROP POLICY IF EXISTS "Authenticated users can upload images" ON storage.objects;
DROP POLICY IF EXISTS "Users can upload images" ON storage.objects;
DROP POLICY IF EXISTS "Anyone can upload program images" ON storage.objects;
DROP POLICY IF EXISTS "Anyone can upload images" ON storage.objects;
DROP POLICY IF EXISTS "Anyone can read images" ON storage.objects;
DROP POLICY IF EXISTS "Authenticated users can update images" ON storage.objects;
DROP POLICY IF EXISTS "Authenticated users can delete images" ON storage.objects;

-- Permitir a TODOS subir cualquier imagen (sin autenticación)
CREATE POLICY "Anyone can upload images"
ON storage.objects FOR INSERT
TO public
WITH CHECK (bucket_id = 'images');

-- Permitir a todos leer imágenes
CREATE POLICY "Anyone can read images"
ON storage.objects FOR SELECT
TO public
USING (bucket_id = 'images');

-- Permitir a usuarios autenticados actualizar/eliminar imágenes
CREATE POLICY "Authenticated users can update images"
ON storage.objects FOR UPDATE
TO authenticated
USING (bucket_id = 'images')
WITH CHECK (bucket_id = 'images');

CREATE POLICY "Authenticated users can delete images"
ON storage.objects FOR DELETE
TO authenticated
USING (bucket_id = 'images');

-- ============================================
-- BUCKET: signatures (Público para lectura, autenticado para escritura)
-- ============================================

DROP POLICY IF EXISTS "Authenticated users can upload signatures" ON storage.objects;
DROP POLICY IF EXISTS "Users can upload signatures" ON storage.objects;
DROP POLICY IF EXISTS "Anyone can upload signatures" ON storage.objects;
DROP POLICY IF EXISTS "Anyone can read signatures" ON storage.objects;
DROP POLICY IF EXISTS "Authenticated users can update signatures" ON storage.objects;
DROP POLICY IF EXISTS "Authenticated users can delete signatures" ON storage.objects;

-- Permitir a TODOS subir firmas (sin autenticación)
CREATE POLICY "Anyone can upload signatures"
ON storage.objects FOR INSERT
TO public
WITH CHECK (bucket_id = 'signatures');

-- Permitir a todos leer firmas
CREATE POLICY "Anyone can read signatures"
ON storage.objects FOR SELECT
TO public
USING (bucket_id = 'signatures');

-- Permitir a usuarios autenticados actualizar/eliminar firmas
CREATE POLICY "Authenticated users can update signatures"
ON storage.objects FOR UPDATE
TO authenticated
USING (bucket_id = 'signatures')
WITH CHECK (bucket_id = 'signatures');

CREATE POLICY "Authenticated users can delete signatures"
ON storage.objects FOR DELETE
TO authenticated
USING (bucket_id = 'signatures');

-- ============================================
-- BUCKET: pdfs (Público para programs/, privado para otros)
-- ============================================

DROP POLICY IF EXISTS "Authenticated users can upload PDFs" ON storage.objects;
DROP POLICY IF EXISTS "Users can upload PDFs" ON storage.objects;
DROP POLICY IF EXISTS "Anyone can upload program PDFs" ON storage.objects;
DROP POLICY IF EXISTS "Anyone can upload PDFs" ON storage.objects;
DROP POLICY IF EXISTS "Authenticated users can read PDFs" ON storage.objects;
DROP POLICY IF EXISTS "Anyone can read PDFs" ON storage.objects;
DROP POLICY IF EXISTS "Authenticated users can update PDFs" ON storage.objects;
DROP POLICY IF EXISTS "Authenticated users can delete PDFs" ON storage.objects;

-- Permitir a TODOS subir cualquier PDF (sin autenticación)
CREATE POLICY "Anyone can upload PDFs"
ON storage.objects FOR INSERT
TO public
WITH CHECK (bucket_id = 'pdfs');

-- Permitir a TODOS leer PDFs (público)
CREATE POLICY "Anyone can read PDFs"
ON storage.objects FOR SELECT
TO public
USING (bucket_id = 'pdfs');

-- Permitir a usuarios autenticados actualizar/eliminar PDFs
CREATE POLICY "Authenticated users can update PDFs"
ON storage.objects FOR UPDATE
TO authenticated
USING (bucket_id = 'pdfs')
WITH CHECK (bucket_id = 'pdfs');

CREATE POLICY "Authenticated users can delete PDFs"
ON storage.objects FOR DELETE
TO authenticated
USING (bucket_id = 'pdfs');

