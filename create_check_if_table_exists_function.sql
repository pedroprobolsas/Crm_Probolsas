/*
  # Creación de la función check_if_table_exists
  
  Esta función permite verificar si una tabla existe en la base de datos.
  Es utilizada por las Edge Functions para verificar si la tabla message_whatsapp_status existe.
*/

-- Crear la función check_if_table_exists
CREATE OR REPLACE FUNCTION check_if_table_exists(table_name text)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  table_exists boolean;
BEGIN
  SELECT EXISTS (
    SELECT FROM information_schema.tables 
    WHERE table_schema = 'public'
    AND table_name = $1
  ) INTO table_exists;
  
  RETURN table_exists;
END;
$$;

-- Comentario para explicar la función
COMMENT ON FUNCTION check_if_table_exists(text) IS 
'Verifica si una tabla existe en el esquema public. Retorna true si la tabla existe, false en caso contrario.';

-- Conceder permisos para que la función pueda ser ejecutada por las Edge Functions
GRANT EXECUTE ON FUNCTION check_if_table_exists(text) TO authenticated;
GRANT EXECUTE ON FUNCTION check_if_table_exists(text) TO service_role;
