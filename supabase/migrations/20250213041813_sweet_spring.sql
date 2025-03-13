/*
  # Agregar campos organizacionales adicionales
  
  1. Nuevos Campos
    - Información de empleados y departamentos
    - Estructura organizacional
    - Procesos y certificaciones
    
  2. Índices
    - Para búsqueda eficiente
    - Para campos frecuentemente consultados
    
  3. Validaciones
    - Estructura de datos JSON
    - Integridad de datos
*/

-- Agregar campos organizacionales adicionales
ALTER TABLE clients
ADD COLUMN IF NOT EXISTS org_chart JSONB DEFAULT '[]'::jsonb,
ADD COLUMN IF NOT EXISTS department_heads JSONB DEFAULT '[]'::jsonb,
ADD COLUMN IF NOT EXISTS work_shifts TEXT[] DEFAULT '{}',
ADD COLUMN IF NOT EXISTS employee_benefits TEXT[] DEFAULT '{}',
ADD COLUMN IF NOT EXISTS training_programs JSONB DEFAULT '[]'::jsonb,
ADD COLUMN IF NOT EXISTS safety_metrics JSONB DEFAULT '{}'::jsonb,
ADD COLUMN IF NOT EXISTS iso_certifications TEXT[] DEFAULT '{}',
ADD COLUMN IF NOT EXISTS environmental_certifications TEXT[] DEFAULT '{}',
ADD COLUMN IF NOT EXISTS quality_procedures JSONB DEFAULT '[]'::jsonb,
ADD COLUMN IF NOT EXISTS maintenance_schedule JSONB DEFAULT '{}'::jsonb;

-- Actualizar la función de validación organizacional
CREATE OR REPLACE FUNCTION validate_organizational_data()
RETURNS TRIGGER AS $$
BEGIN
  -- Validar estructura del organigrama
  IF NEW.org_chart IS NOT NULL AND jsonb_typeof(NEW.org_chart) != 'array' THEN
    RAISE EXCEPTION 'org_chart must be an array';
  END IF;

  -- Validar jefes de departamento
  IF NEW.department_heads IS NOT NULL AND jsonb_typeof(NEW.department_heads) != 'array' THEN
    RAISE EXCEPTION 'department_heads must be an array';
  END IF;

  -- Validar programas de capacitación
  IF NEW.training_programs IS NOT NULL AND jsonb_typeof(NEW.training_programs) != 'array' THEN
    RAISE EXCEPTION 'training_programs must be an array';
  END IF;

  -- Validar métricas de seguridad
  IF NEW.safety_metrics IS NOT NULL AND jsonb_typeof(NEW.safety_metrics) != 'object' THEN
    RAISE EXCEPTION 'safety_metrics must be an object';
  END IF;

  -- Validar procedimientos de calidad
  IF NEW.quality_procedures IS NOT NULL AND jsonb_typeof(NEW.quality_procedures) != 'array' THEN
    RAISE EXCEPTION 'quality_procedures must be an array';
  END IF;

  -- Validar calendario de mantenimiento
  IF NEW.maintenance_schedule IS NOT NULL AND jsonb_typeof(NEW.maintenance_schedule) != 'object' THEN
    RAISE EXCEPTION 'maintenance_schedule must be an object';
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Crear índices adicionales
CREATE INDEX IF NOT EXISTS idx_clients_iso_certifications ON clients USING gin (iso_certifications);
CREATE INDEX IF NOT EXISTS idx_clients_environmental_certifications ON clients USING gin (environmental_certifications);
CREATE INDEX IF NOT EXISTS idx_clients_work_shifts ON clients USING gin (work_shifts);