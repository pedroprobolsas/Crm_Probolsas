/*
  # Agregar campos organizacionales
  
  1. Nuevos Campos
    - Información organizacional básica
    - Contactos y ubicaciones
    - Capacidad y certificaciones
    
  2. Índices
    - Para búsqueda eficiente
    - Para campos frecuentemente consultados
    
  3. Validaciones
    - Estructura de datos JSON
    - Integridad de datos
*/

-- Agregar campos organizacionales a la tabla clients
ALTER TABLE clients
ADD COLUMN IF NOT EXISTS total_employees INTEGER,
ADD COLUMN IF NOT EXISTS departments JSONB DEFAULT '[]'::jsonb,
ADD COLUMN IF NOT EXISTS organizational_structure JSONB DEFAULT '{}'::jsonb,
ADD COLUMN IF NOT EXISTS locations JSONB DEFAULT '[]'::jsonb,
ADD COLUMN IF NOT EXISTS primary_contact JSONB DEFAULT '{}'::jsonb,
ADD COLUMN IF NOT EXISTS certifications TEXT[] DEFAULT '{}',
ADD COLUMN IF NOT EXISTS quality_systems TEXT[] DEFAULT '{}',
ADD COLUMN IF NOT EXISTS production_capacity JSONB DEFAULT '{}'::jsonb,
ADD COLUMN IF NOT EXISTS shifts INTEGER DEFAULT 1,
ADD COLUMN IF NOT EXISTS production_days TEXT[] DEFAULT '{}',
ADD COLUMN IF NOT EXISTS key_equipment JSONB DEFAULT '[]'::jsonb;

-- Crear función de validación para la estructura organizacional
CREATE OR REPLACE FUNCTION validate_organizational_data()
RETURNS TRIGGER AS $$
BEGIN
  -- Validar estructura de departamentos
  IF NEW.departments IS NOT NULL AND jsonb_typeof(NEW.departments) != 'array' THEN
    RAISE EXCEPTION 'departments must be an array';
  END IF;

  -- Validar estructura organizacional
  IF NEW.organizational_structure IS NOT NULL AND jsonb_typeof(NEW.organizational_structure) != 'object' THEN
    RAISE EXCEPTION 'organizational_structure must be an object';
  END IF;

  -- Validar ubicaciones
  IF NEW.locations IS NOT NULL AND jsonb_typeof(NEW.locations) != 'array' THEN
    RAISE EXCEPTION 'locations must be an array';
  END IF;

  -- Validar contacto principal
  IF NEW.primary_contact IS NOT NULL AND jsonb_typeof(NEW.primary_contact) != 'object' THEN
    RAISE EXCEPTION 'primary_contact must be an object';
  END IF;

  -- Validar capacidad de producción
  IF NEW.production_capacity IS NOT NULL AND jsonb_typeof(NEW.production_capacity) != 'object' THEN
    RAISE EXCEPTION 'production_capacity must be an object';
  END IF;

  -- Validar equipo clave
  IF NEW.key_equipment IS NOT NULL AND jsonb_typeof(NEW.key_equipment) != 'array' THEN
    RAISE EXCEPTION 'key_equipment must be an array';
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Crear trigger para la validación organizacional
DROP TRIGGER IF EXISTS validate_organizational_data_trigger ON clients;
CREATE TRIGGER validate_organizational_data_trigger
  BEFORE INSERT OR UPDATE ON clients
  FOR EACH ROW
  EXECUTE FUNCTION validate_organizational_data();

-- Crear índices para búsqueda eficiente
CREATE INDEX IF NOT EXISTS idx_clients_total_employees ON clients(total_employees);
CREATE INDEX IF NOT EXISTS idx_clients_departments ON clients USING gin (departments);
CREATE INDEX IF NOT EXISTS idx_clients_locations ON clients USING gin (locations);
CREATE INDEX IF NOT EXISTS idx_clients_certifications ON clients USING gin (certifications);