/*
  # Agregar campos organizacionales

  1. Nuevos Campos
    - total_employees: Número total de empleados
    - departments: Array JSON de departamentos
    - organizational_structure: Estructura jerárquica
    - locations: Array JSON de ubicaciones
    - primary_contact: Información del contacto principal
    - certifications: Array de certificaciones
    - quality_systems: Array de sistemas de calidad
    - production_capacity: Información de capacidad productiva
    - shifts: Número de turnos
    - production_days: Días de producción
    - key_equipment: Equipamiento clave

  2. Validaciones
    - Trigger para validar estructura de datos JSON
    - Índices para búsqueda eficiente

  3. Seguridad
    - Mantiene las políticas RLS existentes
*/

-- Primero eliminamos la vista existente
DROP VIEW IF EXISTS client_details;

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

-- Recrear la vista client_details
CREATE VIEW client_details AS
SELECT
  c.*,
  COALESCE(c.total_employees, 0) as employee_count,
  jsonb_array_length(c.departments) as department_count,
  jsonb_array_length(c.locations) as location_count,
  CASE
    WHEN c.last_year_sales > 0 AND c.last_year_ebitda > 0 
    THEN ROUND((c.last_year_ebitda / c.last_year_sales * 100)::numeric, 2)
    ELSE NULL
  END as ebitda_margin,
  array_length(c.key_markets, 1) as markets_count,
  array_length(c.key_clients, 1) as key_clients_count,
  array_length(c.competitors, 1) as competitors_count,
  jsonb_array_length(c.current_projects) as active_projects_count,
  jsonb_array_length(c.packaging_types) as packaging_types_count,
  array_length(c.certifications, 1) as certification_count,
  array_length(c.quality_systems, 1) as quality_system_count,
  jsonb_array_length(c.key_equipment) as equipment_count,
  (
    SELECT COALESCE(SUM((value->>'monthly_volume')::numeric), 0)
    FROM jsonb_array_elements(c.packaging_types)
  ) as total_monthly_volume
FROM clients c;

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