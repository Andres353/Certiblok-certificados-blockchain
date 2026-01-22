-- ============================================
-- FIX: Permitir usuarios anónimos para registro de instituciones
-- ============================================
-- El registro de instituciones NO requiere autenticación
-- Necesitamos permitir que usuarios anónimos suban logos
-- ============================================

-- Eliminar y recrear la política de INSERT para institution-logos
-- Permitir tanto a usuarios autenticados como anónimos
DROP POLICY IF EXISTS "Authenticated users can upload logos" ON storage.objects;
DROP POLICY IF EXISTS "Anyone can upload logos" ON storage.objects;

-- Permitir a TODOS (autenticados y anónimos) subir logos
-- Esto es necesario para el registro de instituciones
CREATE POLICY "Anyone can upload logos"
ON storage.objects FOR INSERT
TO public
WITH CHECK (bucket_id = 'institution-logos');

-- Mantener las otras políticas como están
-- (lectura, actualización, eliminación solo para autenticados)

-- Eliminar y recrear la política de INSERT para images
DROP POLICY IF EXISTS "Authenticated users can upload images" ON storage.objects;

CREATE POLICY "Authenticated users can upload images"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'images');

-- Eliminar y recrear la política de INSERT para signatures
DROP POLICY IF EXISTS "Authenticated users can upload signatures" ON storage.objects;

CREATE POLICY "Authenticated users can upload signatures"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'signatures');

-- Eliminar y recrear la política de INSERT para pdfs
DROP POLICY IF EXISTS "Authenticated users can upload PDFs" ON storage.objects;

CREATE POLICY "Authenticated users can upload PDFs"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'pdfs');
