/*
  # Actualización de Tipos de Empaques

  1. Cambios
    - Agregar campos adicionales a packaging_types
    - Actualizar tipos existentes con nueva información
    - Agregar nuevos tipos de empaques
    - Actualizar estructura de validación

  2. Notas
    - Mantiene compatibilidad con datos existentes
    - Agrega información técnica detallada
    - Incluye nuevos tipos específicos
*/

-- Agregar nuevos campos a la tabla packaging_types
ALTER TABLE packaging_types
ADD COLUMN IF NOT EXISTS materials TEXT[] DEFAULT '{}',
ADD COLUMN IF NOT EXISTS thicknesses TEXT[] DEFAULT '{}',
ADD COLUMN IF NOT EXISTS min_width INTEGER,
ADD COLUMN IF NOT EXISTS max_width INTEGER,
ADD COLUMN IF NOT EXISTS presentation TEXT[] DEFAULT '{}',
ADD COLUMN IF NOT EXISTS processes TEXT[] DEFAULT '{}',
ADD COLUMN IF NOT EXISTS certifications TEXT[] DEFAULT '{}';

-- Actualizar tipos existentes y agregar nuevos
WITH packaging_data (
  code, name, description, materials, thicknesses, min_width, max_width,
  presentation, processes, certifications, typical_features, common_uses
) AS (
  VALUES
    (
      'SUZ', 'Stand Up con Zipper',
      'Bolsa stand up con cierre tipo zipper para fácil apertura y resellado',
      ARRAY['PET', 'BOPP', 'PE', 'FOIL'],
      ARRAY['80μ', '90μ', '100μ', '120μ'],
      80, 400,
      ARRAY['bolsa'],
      ARRAY['impresión flexográfica', 'sin impresión', 'laminación', 'corte'],
      ARRAY['FDA', 'HACCP', 'BRC'],
      '[
        {"name": "Zipper", "options": ["Estándar", "Reforzado", "Doble pista"]},
        {"name": "Base", "options": ["Ovalada", "Rectangular", "K-Seal"]},
        {"name": "Estructura", "options": ["Trilaminado", "Cuatrilaminado"]},
        {"name": "Barrera", "options": ["Alta", "Media", "Estándar"]}
      ]'::jsonb,
      ARRAY['Alimentos', 'Café', 'Snacks', 'Productos premium']
    ),
    (
      'BF', 'Bolsa con Fuelle',
      'Bolsa con fuelles laterales para mayor capacidad y estabilidad',
      ARRAY['PEBD', 'PP', 'PET'],
      ARRAY['70μ', '80μ', '100μ'],
      100, 600,
      ARRAY['bolsa'],
      ARRAY['impresión flexográfica', 'sellado lateral', 'corte'],
      ARRAY['ISO 9001', 'FSSC 22000'],
      '[
        {"name": "Tipo Fuelle", "options": ["Lateral", "Inferior", "Ambos"]},
        {"name": "Sellado", "options": ["Recto","Reforzado"]},
        {"name": "Material", "options": ["Monomaterial", "Coextruido"]}
      ]'::jsonb,
      ARRAY['Productos industriales', 'Alimentos a granel', 'Fertilizantes']
    ),
    (
      'FPZ', 'Flow Pack con Zipper',
      'Empaque flow pack con cierre resellable integrado',
      ARRAY['BOPP', 'CPP', 'PET'],
      ARRAY['35μ', '40μ', '50μ'],
      60, 300,
      ARRAY['rollo'],
      ARRAY['impresión flexográfica', 'laminación', 'aplicación de zipper'],
      ARRAY['FDA', 'EU Food Contact'],
      '[
        {"name": "Tipo Zipper", "options": ["Lineal", "Curvo"]},
        {"name": "Sellado", "options": ["Fin seal", "Lap seal"]},
        {"name": "Estructura", "options": ["Bilaminado", "Trilaminado"]}
      ]'::jsonb,
      ARRAY['Snacks', 'Galletas', 'Productos de panadería']
    ),
    (
      'BA', 'Bolsa Tipo Almohada',
      'Bolsa tradicional con sellado tipo almohada',
      ARRAY['PE', 'PP', 'BOPP'],
      ARRAY['30μ', '40μ', '50μ'],
      50, 400,
      ARRAY['bolsa', 'rollo'],
      ARRAY['impresión flexográfica', 'sellado'],
      ARRAY['ISO 9001'],
      '[
        {"name": "Sellado", "options": ["Simple", "Reforzado"]},
        {"name": "Acabado", "options": ["Mate", "Brillante"]},
        {"name": "Perforación", "options": ["Sin perforar", "Microperforado"]}
      ]'::jsonb,
      ARRAY['Pan', 'Snacks', 'Productos ligeros']
    ),
    (
      'BFC', 'Bolsa Fondo Cuadrado',
      'Bolsa con base cuadrada para mejor estabilidad',
      ARRAY['Kraft', 'PE', 'PET'],
      ARRAY['100μ', '120μ', '150μ'],
      100, 500,
      ARRAY['bolsa'],
      ARRAY['impresión flexográfica', 'laminación', 'formado especial'],
      ARRAY['ISO 9001', 'FSSC 22000'],
      '[
        {"name": "Base", "options": ["Simple", "Reforzada"]},
        {"name": "Cierre", "options": ["Pliegue", "Costura", "Termosellado"]},
        {"name": "Material", "options": ["Mono material", "Laminado"]}
      ]'::jsonb,
      ARRAY['Alimentos', 'Productos químicos', 'Fertilizantes']
    ),
    (
      'PV', 'Con Válvula',
      'Bolsa tipo pouch con válvula de desgasificación',
      ARRAY['PET', 'FOIL', 'PE'],
      ARRAY['100μ', '120μ', '140μ'],
      80, 300,
      ARRAY['bolsa'],
      ARRAY['impresión rotograbado', 'laminación', 'aplicación de válvula'],
      ARRAY['FDA', 'HACCP'],
      '[
        {"name": "Válvula", "options": ["Unidireccional", "Bidireccional"]},
        {"name": "Posición", "options": ["Superior", "Lateral"]},
        {"name": "Material", "options": ["Alta barrera", "Ultra barrera"]}
      ]'::jsonb,
      ARRAY['Café', 'Productos en polvo', 'Químicos']
    )
) 
INSERT INTO packaging_types (
  code, name, description, materials, thicknesses, min_width, max_width,
  presentation, processes, certifications, typical_features, common_uses
)
SELECT 
  d.code, d.name, d.description, d.materials, d.thicknesses, d.min_width, d.max_width,
  d.presentation, d.processes, d.certifications, d.typical_features, d.common_uses
FROM packaging_data d
ON CONFLICT (code) DO UPDATE SET
  name = EXCLUDED.name,
  description = EXCLUDED.description,
  materials = EXCLUDED.materials,
  thicknesses = EXCLUDED.thicknesses,
  min_width = EXCLUDED.min_width,
  max_width = EXCLUDED.max_width,
  presentation = EXCLUDED.presentation,
  processes = EXCLUDED.processes,
  certifications = EXCLUDED.certifications,
  typical_features = EXCLUDED.typical_features,
  common_uses = EXCLUDED.common_uses,
  updated_at = NOW();

-- Actualizar la función de validación
CREATE OR REPLACE FUNCTION validate_packaging_types()
RETURNS TRIGGER AS $$
BEGIN
  -- Check if it's an array
  IF jsonb_typeof(NEW.packaging_types) != 'array' THEN
    RAISE EXCEPTION 'packaging_types must be an array';
  END IF;

  -- Check each element's structure
  IF jsonb_array_length(NEW.packaging_types) > 0 THEN
    FOR i IN 0..jsonb_array_length(NEW.packaging_types) - 1 LOOP
      IF NOT (
        (NEW.packaging_types->i) ? 'type' AND
        (NEW.packaging_types->i) ? 'code' AND
        (NEW.packaging_types->i) ? 'monthly_volume' AND
        (NEW.packaging_types->i) ? 'unit' AND
        (NEW.packaging_types->i) ? 'features' AND
        (NEW.packaging_types->i) ? 'material' AND
        (NEW.packaging_types->i) ? 'thickness' AND
        (NEW.packaging_types->i) ? 'width' AND
        (NEW.packaging_types->i) ? 'processes' AND
        (NEW.packaging_types->i) ? 'certifications' AND
        jsonb_typeof(NEW.packaging_types->i->'monthly_volume') = 'number' AND
        jsonb_typeof(NEW.packaging_types->i->'type') = 'string' AND
        jsonb_typeof(NEW.packaging_types->i->'code') = 'string' AND
        jsonb_typeof(NEW.packaging_types->i->'unit') = 'string' AND
        jsonb_typeof(NEW.packaging_types->i->'features') = 'object' AND
        jsonb_typeof(NEW.packaging_types->i->'material') = 'string' AND
        jsonb_typeof(NEW.packaging_types->i->'thickness') = 'string' AND
        jsonb_typeof(NEW.packaging_types->i->'width') = 'number' AND
        jsonb_typeof(NEW.packaging_types->i->'processes') = 'array' AND
        jsonb_typeof(NEW.packaging_types->i->'certifications') = 'array'
      ) THEN
        RAISE EXCEPTION 'Invalid packaging type structure at index %', i;
      END IF;

      -- Verify code exists in packaging_types table
      IF NOT EXISTS (
        SELECT 1 FROM packaging_types
        WHERE code = (NEW.packaging_types->i->>'code')
      ) THEN
        RAISE EXCEPTION 'Invalid packaging type code at index %', i;
      END IF;
    END LOOP;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;