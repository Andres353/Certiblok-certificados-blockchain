-- ============================================
-- POLÍTICAS RLS PARA SUPABASE STORAGE
-- ============================================
-- Este archivo configura todas las políticas necesarias
-- para que la aplicación pueda subir y leer archivos
-- ============================================

-- IMPORTANTE: Deshabilitar RLS temporalmente si es necesario
-- ALTER TABLE storage.objects DISABLE ROW LEVEL SECURITY; -- NO RECOMENDADO PARA PRODUCCIÓN

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
-- BUCKET: images (Público)
-- ============================================

-- Eliminar políticas existentes si las hay
DROP POLICY IF EXISTS "Authenticated users can upload images" ON storage.objects;
DROP POLICY IF EXISTS "Anyone can read images" ON storage.objects;
DROP POLICY IF EXISTS "Authenticated users can update images" ON storage.objects;
DROP POLICY IF EXISTS "Authenticated users can delete images" ON storage.objects;

-- Permitir a usuarios autenticados subir imágenes (POLÍTICA MÁS PERMISIVA)
CREATE POLICY "Authenticated users can upload images"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'images' AND
  (auth.role() = 'authenticated' OR auth.role() = 'service_role')
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
-- BUCKET: signatures (Público)
-- ============================================

-- Eliminar políticas existentes si las hay
DROP POLICY IF EXISTS "Authenticated users can upload signatures" ON storage.objects;
DROP POLICY IF EXISTS "Anyone can read signatures" ON storage.objects;
DROP POLICY IF EXISTS "Authenticated users can update signatures" ON storage.objects;
DROP POLICY IF EXISTS "Authenticated users can delete signatures" ON storage.objects;

-- Permitir a usuarios autenticados subir firmas (POLÍTICA MÁS PERMISIVA)
CREATE POLICY "Authenticated users can upload signatures"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'signatures' AND
  (auth.role() = 'authenticated' OR auth.role() = 'service_role')
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
DROP POLICY IF EXISTS "Authenticated users can read PDFs" ON storage.objects;
DROP POLICY IF EXISTS "Authenticated users can update PDFs" ON storage.objects;
DROP POLICY IF EXISTS "Authenticated users can delete PDFs" ON storage.objects;

-- Permitir a usuarios autenticados subir PDFs (POLÍTICA MÁS PERMISIVA)
CREATE POLICY "Authenticated users can upload PDFs"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'pdfs' AND
  (auth.role() = 'authenticated' OR auth.role() = 'service_role')
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
