-- ============================================
-- SCRIPT DE DIAGNÓSTICO PARA SUPABASE STORAGE
-- ============================================
-- Ejecuta este script para verificar la configuración
-- ============================================

-- 1. Verificar que los buckets existen
SELECT id, name, public, file_size_limit, allowed_mime_types
FROM storage.buckets
WHERE id IN ('institution-logos', 'images', 'signatures', 'pdfs')
ORDER BY id;

-- 2. Verificar políticas RLS existentes
SELECT 
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd,
  qual,
  with_check
FROM pg_policies
WHERE tablename = 'objects' AND schemaname = 'storage'
ORDER BY policyname;

-- 3. Verificar si RLS está habilitado en storage.objects
SELECT 
  schemaname,
  tablename,
  rowsecurity
FROM pg_tables
WHERE schemaname = 'storage' AND tablename = 'objects';

-- 4. Verificar usuario actual
SELECT 
  auth.uid() as current_user_id,
  auth.role() as current_role;

-- 5. Contar políticas por bucket
SELECT 
  policyname,
  cmd as operation,
  CASE 
    WHEN qual::text LIKE '%institution-logos%' THEN 'institution-logos'
    WHEN qual::text LIKE '%images%' THEN 'images'
    WHEN qual::text LIKE '%signatures%' THEN 'signatures'
    WHEN qual::text LIKE '%pdfs%' THEN 'pdfs'
    ELSE 'other'
  END as bucket
FROM pg_policies
WHERE tablename = 'objects' AND schemaname = 'storage'
ORDER BY bucket, operation;

