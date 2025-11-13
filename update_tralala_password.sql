-- Consulta para actualizar la contraseña del administrador de la institución TRALALA
-- Ejecutar esta consulta en el SQL Editor de Supabase

UPDATE institutions 
SET 
    admin_password_hash = crypt('Andy6803924', gen_salt('bf')),
    updated_at = NOW()
WHERE name = 'TRALALA';

-- Verificar que se actualizó correctamente
SELECT id, name, admin_email, updated_at 
FROM institutions 
WHERE name = 'TRALALA';

