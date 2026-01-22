# Configuración de Supabase Storage

## Buckets Necesarios

Para que la migración funcione correctamente, necesitas crear los siguientes buckets en Supabase Storage:

### 1. **institution-logos**
   - **Propósito**: Logos de instituciones educativas
   - **Público**: Sí (para que las imágenes se puedan ver)
   - **Límite de tamaño**: 5MB por archivo

### 2. **images**
   - **Propósito**: Imágenes generales (programas, etc.)
   - **Público**: Sí
   - **Límite de tamaño**: 5MB por archivo

### 3. **pdfs**
   - **Propósito**: PDFs (CVs, cartas de motivación, documentos de programas)
   - **Público**: No (privado, solo accesible con autenticación)
   - **Límite de tamaño**: 50MB por archivo (plan gratuito) o 5GB (plan Pro)

### 4. **signatures**
   - **Propósito**: Firmas digitales para certificados
   - **Público**: Sí
   - **Límite de tamaño**: 1MB por archivo

## Pasos para Crear los Buckets

### Opción 1: Desde el Dashboard de Supabase

1. Ve a tu proyecto en [Supabase Dashboard](https://app.supabase.com)
2. Navega a **Storage** en el menú lateral
3. Haz clic en **New bucket**
4. Crea cada bucket con las siguientes configuraciones:

#### Bucket: `institution-logos`
- **Name**: `institution-logos`
- **Public bucket**: ✅ Activado
- **File size limit**: `5 MB`
- **Allowed MIME types**: `image/jpeg, image/png, image/webp`

#### Bucket: `images`
- **Name**: `images`
- **Public bucket**: ✅ Activado
- **File size limit**: `5 MB`
- **Allowed MIME types**: `image/jpeg, image/png, image/webp`

#### Bucket: `pdfs`
- **Name**: `pdfs`
- **Public bucket**: ❌ Desactivado (privado)
- **File size limit**: `50 MB` (o `5 GB` si tienes plan Pro)
- **Allowed MIME types**: `application/pdf`

#### Bucket: `signatures`
- **Name**: `signatures`
- **Public bucket**: ✅ Activado
- **File size limit**: `1 MB`
- **Allowed MIME types**: `image/jpeg, image/png, image/webp`

### Opción 2: Usando SQL (más rápido)

Ejecuta este SQL en el **SQL Editor** de Supabase:

```sql
-- Crear bucket para logos de instituciones
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'institution-logos',
  'institution-logos',
  true,
  5242880, -- 5MB
  ARRAY['image/jpeg', 'image/png', 'image/webp']
)
ON CONFLICT (id) DO NOTHING;

-- Crear bucket para imágenes generales
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'images',
  'images',
  true,
  5242880, -- 5MB
  ARRAY['image/jpeg', 'image/png', 'image/webp']
)
ON CONFLICT (id) DO NOTHING;

-- Crear bucket para PDFs
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'pdfs',
  'pdfs',
  false, -- Privado
  52428800, -- 50MB (cambiar a 5368709120 para 5GB si tienes plan Pro)
  ARRAY['application/pdf']
)
ON CONFLICT (id) DO NOTHING;

-- Crear bucket para firmas
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'signatures',
  'signatures',
  true,
  1048576, -- 1MB
  ARRAY['image/jpeg', 'image/png', 'image/webp']
)
ON CONFLICT (id) DO NOTHING;
```

## ⚠️ IMPORTANTE: Configurar Políticas de Seguridad (RLS)

**Aunque los buckets sean públicos, necesitas configurar políticas RLS para permitir subir archivos.**

### ✅ SOLUCIÓN RÁPIDA

**Ejecuta el archivo `supabase_storage_policies.sql` completo en el SQL Editor de Supabase.** Este archivo contiene todas las políticas necesarias para todos los buckets.

### Configurar Políticas Manualmente

Si prefieres hacerlo paso a paso, aquí están las políticas para cada bucket:

#### Políticas para Buckets Públicos (institution-logos, images, signatures)

```sql
-- ============================================
-- BUCKET: institution-logos (Público)
-- ============================================

-- Permitir a usuarios autenticados subir logos
CREATE POLICY "Authenticated users can upload logos"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'institution-logos');

-- Permitir a todos leer logos (público)
CREATE POLICY "Anyone can read logos"
ON storage.objects FOR SELECT
TO public
USING (bucket_id = 'institution-logos');

-- Permitir a usuarios autenticados eliminar logos
CREATE POLICY "Authenticated users can delete logos"
ON storage.objects FOR DELETE
TO authenticated
USING (bucket_id = 'institution-logos');

-- ============================================
-- BUCKET: images (Público)
-- ============================================

-- Permitir a usuarios autenticados subir imágenes
CREATE POLICY "Authenticated users can upload images"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'images');

-- Permitir a todos leer imágenes (público)
CREATE POLICY "Anyone can read images"
ON storage.objects FOR SELECT
TO public
USING (bucket_id = 'images');

-- Permitir a usuarios autenticados eliminar imágenes
CREATE POLICY "Authenticated users can delete images"
ON storage.objects FOR DELETE
TO authenticated
USING (bucket_id = 'images');

-- ============================================
-- BUCKET: signatures (Público)
-- ============================================

-- Permitir a usuarios autenticados subir firmas
CREATE POLICY "Authenticated users can upload signatures"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'signatures');

-- Permitir a todos leer firmas (público)
CREATE POLICY "Anyone can read signatures"
ON storage.objects FOR SELECT
TO public
USING (bucket_id = 'signatures');

-- Permitir a usuarios autenticados eliminar firmas
CREATE POLICY "Authenticated users can delete signatures"
ON storage.objects FOR DELETE
TO authenticated
USING (bucket_id = 'signatures');
```

#### Políticas para Bucket Privado (pdfs)

```sql
-- ============================================
-- BUCKET: pdfs (Privado)
-- ============================================

-- Permitir a usuarios autenticados subir PDFs
CREATE POLICY "Authenticated users can upload PDFs"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'pdfs');

-- Permitir a usuarios autenticados leer PDFs
CREATE POLICY "Authenticated users can read PDFs"
ON storage.objects FOR SELECT
TO authenticated
USING (bucket_id = 'pdfs');

-- Permitir a usuarios autenticados eliminar PDFs
CREATE POLICY "Authenticated users can delete PDFs"
ON storage.objects FOR DELETE
TO authenticated
USING (bucket_id = 'pdfs');
```

## Verificación

Después de crear los buckets, verifica que estén creados correctamente:

1. Ve a **Storage** en el dashboard
2. Deberías ver los 4 buckets listados
3. Prueba subir un archivo de prueba desde la aplicación

## Notas Importantes

- **Espacio disponible**: Plan gratuito = 1GB, Plan Pro = 100GB
- **Límite por archivo**: Plan gratuito = 50MB, Plan Pro = 5GB
- **Compresión automática**: Las imágenes se comprimen automáticamente antes de subir
- **Organización**: Los archivos se organizan en carpetas dentro de cada bucket

