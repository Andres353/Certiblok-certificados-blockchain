-- Consulta para cambiar el email de una institución
-- Ejecutar en el SQL Editor de Supabase

-- 1. VER INSTITUCIONES ACTUALES CON SUS EMAILS
SELECT 
    id,
    name,
    admin_email,
    contact_email,
    created_at
FROM institutions 
ORDER BY created_at DESC;

-- 2. ACTUALIZAR EMAIL DE ADMIN DE UNA INSTITUCIÓN ESPECÍFICA
-- Reemplaza 'ID_DE_LA_INSTITUCION' con el ID real de la institución
-- Reemplaza 'nuevo_email@ejemplo.com' con el nuevo email

UPDATE institutions 
SET 
    admin_email = 'nuevo_email@ejemplo.com',
    updated_at = NOW()
WHERE id = 'ID_DE_LA_INSTITUCION';

-- 3. ACTUALIZAR EMAIL DE CONTACTO DE UNA INSTITUCIÓN ESPECÍFICA
UPDATE institutions 
SET 
    contact_email = 'nuevo_contacto@ejemplo.com',
    updated_at = NOW()
WHERE id = 'ID_DE_LA_INSTITUCION';

-- 4. ACTUALIZAR AMBOS EMAILS A LA VEZ
UPDATE institutions 
SET 
    admin_email = 'nuevo_admin@ejemplo.com',
    contact_email = 'nuevo_contacto@ejemplo.com',
    updated_at = NOW()
WHERE id = 'ID_DE_LA_INSTITUCION';

-- 5. ACTUALIZAR EMAIL POR NOMBRE DE INSTITUCIÓN (si conoces el nombre)
UPDATE institutions 
SET 
    admin_email = 'nuevo_email@ejemplo.com',
    updated_at = NOW()
WHERE name = 'NOMBRE_DE_LA_INSTITUCION';

-- 6. VERIFICAR EL CAMBIO
SELECT 
    id,
    name,
    admin_email,
    contact_email,
    updated_at
FROM institutions 
WHERE id = 'ID_DE_LA_INSTITUCION';

-- 7. ACTUALIZAR EMAIL EN TABLA USERS SI EXISTE USUARIO ASOCIADO
-- (Esto actualiza el email del usuario admin en la tabla users)
UPDATE users 
SET 
    email = 'nuevo_email@ejemplo.com',
    updated_at = NOW()
WHERE id = (
    SELECT admin_user_id 
    FROM institutions 
    WHERE id = 'ID_DE_LA_INSTITUCION'
);

-- 8. CONSULTA COMPLETA PARA VER TODA LA INFORMACIÓN
SELECT 
    i.id,
    i.name,
    i.admin_email,
    i.contact_email,
    i.admin_name,
    i.admin_user_id,
    u.email as user_email,
    u.full_name as user_full_name,
    i.updated_at
FROM institutions i
LEFT JOIN users u ON i.admin_user_id = u.id
WHERE i.id = 'ID_DE_LA_INSTITUCION';
