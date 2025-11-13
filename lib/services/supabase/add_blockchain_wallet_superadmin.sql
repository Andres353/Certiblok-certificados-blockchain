-- Script para agregar tabla de configuración blockchain del sistema (Super Admin)
-- Ejecutar este script en el SQL Editor de Supabase

-- Crear tabla para configuración blockchain del sistema
CREATE TABLE IF NOT EXISTS system_blockchain_config (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    blockchain_private_key_encrypted TEXT NOT NULL,
    blockchain_wallet_address VARCHAR(42) NOT NULL UNIQUE,
    blockchain_network VARCHAR(50) DEFAULT 'polygon_mainnet' NOT NULL,
    configured_by UUID REFERENCES users(id) ON DELETE SET NULL,
    configured_by_name VARCHAR(255),
    configured_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    is_active BOOLEAN DEFAULT true,
    notes TEXT
);

-- Crear índices para mejorar el rendimiento
CREATE INDEX IF NOT EXISTS idx_system_blockchain_config_wallet_address 
ON system_blockchain_config(blockchain_wallet_address);

CREATE INDEX IF NOT EXISTS idx_system_blockchain_config_active 
ON system_blockchain_config(is_active) 
WHERE is_active = true;

CREATE INDEX IF NOT EXISTS idx_system_blockchain_config_network 
ON system_blockchain_config(blockchain_network);

-- Agregar comentarios para documentar la tabla
COMMENT ON TABLE system_blockchain_config IS 'Configuración de wallet blockchain del sistema (configurada por Super Admin)';
COMMENT ON COLUMN system_blockchain_config.blockchain_private_key_encrypted IS 'Clave privada de la wallet blockchain (encriptada) - Solo una wallet activa por red';
COMMENT ON COLUMN system_blockchain_config.blockchain_wallet_address IS 'Dirección pública de la wallet blockchain';
COMMENT ON COLUMN system_blockchain_config.blockchain_network IS 'Red blockchain utilizada (polygon_mainnet, polygon_testnet, etc.)';
COMMENT ON COLUMN system_blockchain_config.configured_by IS 'ID del usuario Super Admin que configuró la wallet';
COMMENT ON COLUMN system_blockchain_config.configured_by_name IS 'Nombre del usuario Super Admin que configuró la wallet';
COMMENT ON COLUMN system_blockchain_config.configured_at IS 'Fecha y hora en que se configuró la wallet blockchain';
COMMENT ON COLUMN system_blockchain_config.is_active IS 'Indica si esta configuración está activa (solo una activa por red)';
COMMENT ON COLUMN system_blockchain_config.notes IS 'Notas adicionales sobre la configuración';

-- Crear función para actualizar updated_at automáticamente
CREATE OR REPLACE FUNCTION update_system_blockchain_config_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Crear trigger para actualizar updated_at
DROP TRIGGER IF EXISTS trigger_update_system_blockchain_config_updated_at ON system_blockchain_config;
CREATE TRIGGER trigger_update_system_blockchain_config_updated_at
    BEFORE UPDATE ON system_blockchain_config
    FOR EACH ROW
    EXECUTE FUNCTION update_system_blockchain_config_updated_at();

-- Crear función para desactivar otras configuraciones cuando se activa una nueva
CREATE OR REPLACE FUNCTION deactivate_other_blockchain_configs()
RETURNS TRIGGER AS $$
BEGIN
    -- Si se está activando una nueva configuración, desactivar las demás de la misma red
    IF NEW.is_active = true THEN
        UPDATE system_blockchain_config
        SET is_active = false
        WHERE blockchain_network = NEW.blockchain_network
        AND id != NEW.id
        AND is_active = true;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Crear trigger para desactivar otras configuraciones
DROP TRIGGER IF EXISTS trigger_deactivate_other_blockchain_configs ON system_blockchain_config;
CREATE TRIGGER trigger_deactivate_other_blockchain_configs
    BEFORE INSERT OR UPDATE ON system_blockchain_config
    FOR EACH ROW
    EXECUTE FUNCTION deactivate_other_blockchain_configs();

-- Crear función para obtener la configuración activa
CREATE OR REPLACE FUNCTION get_active_blockchain_config(network_name VARCHAR DEFAULT 'polygon_mainnet')
RETURNS TABLE (
    id UUID,
    blockchain_wallet_address VARCHAR,
    blockchain_network VARCHAR,
    configured_by_name VARCHAR,
    configured_at TIMESTAMP WITH TIME ZONE
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        sbc.id,
        sbc.blockchain_wallet_address,
        sbc.blockchain_network,
        sbc.configured_by_name,
        sbc.configured_at
    FROM system_blockchain_config sbc
    WHERE sbc.is_active = true
    AND sbc.blockchain_network = network_name
    ORDER BY sbc.configured_at DESC
    LIMIT 1;
END;
$$ LANGUAGE plpgsql;

-- Verificar que la tabla fue creada correctamente
SELECT 
    column_name, 
    data_type, 
    is_nullable, 
    column_default
FROM information_schema.columns 
WHERE table_name = 'system_blockchain_config'
ORDER BY ordinal_position;

-- Verificar índices creados
SELECT 
    indexname,
    indexdef
FROM pg_indexes
WHERE tablename = 'system_blockchain_config';

