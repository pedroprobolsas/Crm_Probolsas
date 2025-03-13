/*
  # Crear Tabla Maestra de Tipos de Empaques

  1. Cambios
    - Crear tabla packaging_types para catálogo de tipos de empaques
    - Agregar campos para código, nombre, descripción, características y usos
    - Insertar datos predefinidos
    - Actualizar políticas RLS

  2. Notas
    - Mantiene un catálogo centralizado de tipos de empaques
    - Permite gestionar características y usos comunes
    - Facilita la consistencia en la selección de tipos
*/

-- Crear tabla de tipos de empaques
CREATE TABLE IF NOT EXISTS packaging_types (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  code TEXT UNIQUE NOT NULL,
  name TEXT NOT NULL,
  description TEXT,
  typical_features JSONB DEFAULT '[]'::jsonb,
  common_uses TEXT[],
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Crear índices
CREATE INDEX IF NOT EXISTS idx_packaging_types_code ON packaging_types(code);
CREATE INDEX IF NOT EXISTS idx_packaging_types_name ON packaging_types(name);

-- Habilitar RLS
ALTER TABLE packaging_types ENABLE ROW LEVEL SECURITY;

-- Crear políticas RLS
CREATE POLICY "Usuarios autenticados pueden leer tipos de empaques"
  ON packaging_types FOR SELECT
  TO authenticated
  USING (true);

-- Insertar tipos predefinidos
INSERT INTO packaging_types (code, name, description, typical_features, common_uses) VALUES
  (
    'BAG',
    'Bolsas',
    'Empaques flexibles en forma de bolsa para diversos usos',
    '[
      {"name": "Material", "options": ["PEBD", "PEAD", "PP", "PA"]},
      {"name": "Sellado", "options": ["Lateral", "Fondo", "Tres sellos"]},
      {"name": "Impresión", "options": ["Flexografía", "Rotograbado"]}
    ]'::jsonb,
    ARRAY['Alimentos', 'Productos industriales', 'Comercio minorista']
  ),
  (
    'ROLL',
    'Rollos',
    'Material de empaque en formato de rollo continuo',
    '[
      {"name": "Material", "options": ["PEBD", "PEAD", "PP", "PET"]},
      {"name": "Acabado", "options": ["Brillante", "Mate"]},
      {"name": "Perforación", "options": ["Sin perforar", "Microperforado"]}
    ]'::jsonb,
    ARRAY['Empaque automático', 'Laminación', 'Conversión']
  ),
  (
    'TAPE',
    'Con Cinta',
    'Empaques con sistema de cierre mediante cinta adhesiva',
    '[
      {"name": "Tipo de cinta", "options": ["Adhesiva", "Resellable"]},
      {"name": "Posición", "options": ["Superior", "Lateral"]},
      {"name": "Material base", "options": ["PP", "PET"]}
    ]'::jsonb,
    ARRAY['Productos de consumo', 'Alimentos', 'Productos higiénicos']
  ),
  (
    'LAM',
    'Laminados',
    'Estructuras multicapa para mayor protección',
    '[
      {"name": "Capas", "options": ["Bilaminado", "Trilaminado"]},
      {"name": "Barrera", "options": ["Oxígeno", "Humedad", "UV"]},
      {"name": "Acabado", "options": ["Brillante", "Mate", "Soft touch"]}
    ]'::jsonb,
    ARRAY['Alimentos', 'Productos sensibles', 'Exportación']
  ),
  (
    'FLOW',
    'Flow Pack',
    'Empaque horizontal tipo flow pack',
    '[
      {"name": "Sellado", "options": ["Fin seal", "Lap seal"]},
      {"name": "Velocidad", "options": ["Alta", "Media", "Baja"]},
      {"name": "Estructura", "options": ["Monocapa", "Multicapa"]}
    ]'::jsonb,
    ARRAY['Alimentos', 'Snacks', 'Productos de panadería']
  ),
  (
    'SHRINK',
    'Termoencogibles',
    'Películas que se ajustan al producto con calor',
    '[
      {"name": "Encogimiento", "options": ["Alto", "Medio", "Bajo"]},
      {"name": "Resistencia", "options": ["Estándar", "Alta"]},
      {"name": "Claridad", "options": ["Transparente", "Opaco"]}
    ]'::jsonb,
    ARRAY['Bebidas', 'Agrupación', 'Display']
  ),
  (
    'DPV',
    'Doy Pack con Válvula',
    'Bolsa tipo doy pack con válvula dosificadora',
    '[
      {"name": "Válvula", "options": ["Degasificación", "Dosificación"]},
      {"name": "Posición", "options": ["Superior", "Esquina"]},
      {"name": "Material", "options": ["Laminado", "Metalizado"]}
    ]'::jsonb,
    ARRAY['Café', 'Líquidos', 'Productos químicos']
  ),
  (
    'DPZ',
    'Doy Pack con Zipper',
    'Bolsa tipo doy pack con cierre tipo zipper',
    '[
      {"name": "Zipper", "options": ["Estándar", "Reforzado"]},
      {"name": "Posición", "options": ["Superior", "Lateral"]},
      {"name": "Estructura", "options": ["Laminado", "Metalizado"]}
    ]'::jsonb,
    ARRAY['Alimentos", "Snacks", "Productos resellables']
  ),
  (
    'DP',
    'Doy Pack',
    'Bolsa tipo doy pack estándar',
    '[
      {"name": "Base", "options": ["Ovalada", "Rectangular"]},
      {"name": "Material", "options": ["Laminado", "Metalizado"]},
      {"name": "Acabado", "options": ["Brillante", "Mate"]}
    ]'::jsonb,
    ARRAY['Alimentos', 'Productos líquidos', 'Productos en polvo']
  ),
  (
    'FILM',
    'Películas',
    'Películas flexibles para diversos usos',
    '[
      {"name": "Material", "options": ["BOPP", "PET", "PE"]},
      {"name": "Tratamiento", "options": ["Corona", "Químico"]},
      {"name": "Barrera", "options": ["Estándar", "Alta"]}
    ]'::jsonb,
    ARRAY['Laminación', 'Impresión', 'Empaque']
  ),
  (
    'LABEL',
    'Etiquetas',
    'Etiquetas autoadhesivas y mangas',
    '[
      {"name": "Tipo", "options": ["Autoadhesiva", "Manga"]},
      {"name": "Material", "options": ["PP", "PET", "Paper"]},
      {"name": "Adhesivo", "options": ["Permanente", "Removible"]}
    ]'::jsonb,
    ARRAY['Identificación', 'Decoración', 'Información']
  );

-- Actualizar trigger de validación de packaging_types en clientes
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
        jsonb_typeof(NEW.packaging_types->i->'monthly_volume') = 'number' AND
        jsonb_typeof(NEW.packaging_types->i->'type') = 'string' AND
        jsonb_typeof(NEW.packaging_types->i->'code') = 'string' AND
        jsonb_typeof(NEW.packaging_types->i->'unit') = 'string' AND
        jsonb_typeof(NEW.packaging_types->i->'features') = 'object'
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