-- Actualizar nombres de tipos de empaque
UPDATE packaging_types
SET 
  name = 'Bolsa Stand-Up con Zipper',
  description = 'Bolsa stand-up premium con cierre tipo zipper para fácil apertura y resellado'
WHERE code = 'SUZ';

UPDATE packaging_types
SET 
  name = 'Bolsa con Fuelle Lateral',
  description = 'Bolsa con fuelles laterales para mayor capacidad y estabilidad vertical'
WHERE code = 'BF';

UPDATE packaging_types
SET 
  name = 'Flow Pack con Zipper Premium',
  description = 'Empaque flow pack con sistema de cierre resellable integrado de alta calidad'
WHERE code = 'FPZ';

UPDATE packaging_types
SET 
  name = 'Bolsa Tipo Almohada Premium',
  description = 'Bolsa tradicional con sellado tipo almohada y acabados premium'
WHERE code = 'BA';

UPDATE packaging_types
SET 
  name = 'Bolsa Base Cuadrada Reforzada',
  description = 'Bolsa con base cuadrada reforzada para máxima estabilidad y resistencia'
WHERE code = 'BFC';

UPDATE packaging_types
SET 
  name = 'Pouch con Válvula Desgasificadora',
  description = 'Bolsa tipo pouch con válvula de desgasificación unidireccional'
WHERE code = 'PV';