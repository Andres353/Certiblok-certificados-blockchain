-- Script para crear todos los buckets necesarios en Supabase Storage
-- Ejecuta este script en el SQL Editor de Supabase

-- ============================================
-- CREAR BUCKETS
-- ============================================

-- 1. Bucket: institution-logos (Público)
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'institution-logos',
  'institution-logos',
  true,
  5242880, -- 5MB
  ARRAY['image/jpeg', 'image/png', 'image/webp']
)
ON CONFLICT (id) DO NOTHING;

-- 2. Bucket: images (Público)
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'images',
  'images',
  true,
  5242880, -- 5MB
  ARRAY['image/jpeg', 'image/png', 'image/webp']
)
ON CONFLICT (id) DO NOTHING;

-- 3. Bucket: pdfs (Privado)
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'pdfs',
  'pdfs',
  false, -- Privado
  52428800, -- 50MB (cambiar a 5368709120 para 5GB si tienes plan Pro)
  ARRAY['application/pdf']
)
ON CONFLICT (id) DO NOTHING;

-- 4. Bucket: signatures (Público)
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'signatures',
  'signatures',
  true,
  1048576, -- 1MB
  ARRAY['image/jpeg', 'image/png', 'image/webp']
)
ON CONFLICT (id) DO NOTHING;

-- ============================================
-- VERIFICAR QUE SE CREARON CORRECTAMENTE
-- ============================================
SELECT id, name, public, file_size_limit, allowed_mime_types 
FROM storage.buckets 
WHERE id IN ('institution-logos', 'images', 'pdfs', 'signatures')
ORDER BY id;

