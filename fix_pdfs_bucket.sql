-- Script para hacer el bucket pdfs público
-- Ejecuta esto en el SQL Editor de Supabase

-- Verificar si el bucket existe
SELECT id, name, public, file_size_limit 
FROM storage.buckets 
WHERE id = 'pdfs';

-- Si el bucket existe pero es privado, hacerlo público
UPDATE storage.buckets
SET public = true
WHERE id = 'pdfs';

-- Verificar el cambio
SELECT id, name, public, file_size_limit 
FROM storage.buckets 
WHERE id = 'pdfs';

-- Si el bucket NO existe, créalo como público
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'pdfs',
  'pdfs',
  true, -- PÚBLICO (cambiar a false si quieres privado)
  52428800, -- 50MB
  ARRAY['application/pdf']
)
ON CONFLICT (id) DO UPDATE SET public = true;

