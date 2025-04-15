/*
  # Verificación de la Extensión pg_net y Prueba de HTTP POST

  Este script verifica que la extensión pg_net esté instalada correctamente
  y prueba la funcionalidad de net.http_post con un endpoint de prueba.
*/

-- 1. Verificar que la extensión pg_net esté instalada
SELECT extname, extversion 
FROM pg_extension 
WHERE extname = 'pg_net';

-- 2. Verificar que la función net.http_post exista
SELECT 
  p.proname AS function_name,
  n.nspname AS schema_name,
  pg_get_function_result(p.oid) AS result_type
FROM pg_proc p
JOIN pg_namespace n ON p.pronamespace = n.oid
WHERE p.proname = 'http_post' AND n.nspname = 'net';

-- 3. Verificar permisos para la función net.http_post
SELECT 
  n.nspname AS schema_name,
  p.proname AS function_name,
  pg_get_userbyid(p.proowner) AS function_owner,
  CASE WHEN p.prosecdef THEN 'SECURITY DEFINER' ELSE 'SECURITY INVOKER' END AS security
FROM pg_proc p
JOIN pg_namespace n ON p.pronamespace = n.oid
WHERE p.proname = 'http_post' AND n.nspname = 'net';

-- 4. Probar net.http_post con un endpoint de prueba (httpbin.org)
DO $$
DECLARE
  result JSONB;
BEGIN
  -- Usar httpbin.org como endpoint de prueba
  BEGIN
    SELECT content::jsonb INTO result
    FROM net.http_post(
      url := 'https://httpbin.org/post',
      body := '{"test": "data"}',
      headers := '{"Content-Type": "application/json"}'
    );
    
    -- Mostrar el resultado
    RAISE NOTICE 'Resultado de la prueba con httpbin.org: %', result;
    
    -- Verificar si la respuesta contiene los datos enviados
    IF result->'json'->>'test' = 'data' THEN
      RAISE NOTICE 'La prueba fue exitosa. net.http_post funciona correctamente.';
    ELSE
      RAISE WARNING 'La prueba falló. La respuesta no contiene los datos esperados.';
    END IF;
  EXCEPTION WHEN OTHERS THEN
    RAISE WARNING 'Error al probar net.http_post: %', SQLERRM;
  END;
END;
$$;

-- 5. Probar net.http_post con la URL del webhook para clientes
DO $$
DECLARE
  webhook_url TEXT;
  result JSONB;
BEGIN
  -- Obtener la URL del webhook para clientes en producción
  SELECT value INTO webhook_url 
  FROM app_settings 
  WHERE key = 'webhook_url_client_production';
  
  -- Mostrar la URL
  RAISE NOTICE 'URL del webhook para clientes en producción: %', webhook_url;
  
  -- Probar el webhook con un payload mínimo
  BEGIN
    SELECT content::jsonb INTO result
    FROM net.http_post(
      url := webhook_url,
      body := '{"test": "webhook_test"}',
      headers := '{"Content-Type": "application/json"}'
    );
    
    -- Mostrar el resultado
    RAISE NOTICE 'Resultado de la prueba con el webhook: %', result;
  EXCEPTION WHEN OTHERS THEN
    RAISE WARNING 'Error al probar el webhook: %', SQLERRM;
  END;
END;
$$;

-- 6. Verificar si hay restricciones de red para conexiones salientes
-- Nota: Esto solo muestra información, no puede verificar directamente las restricciones
RAISE NOTICE '
Posibles restricciones de red:
1. Firewall bloqueando conexiones salientes
2. Configuración de red de Supabase limitando conexiones
3. Problemas de DNS para resolver la URL del webhook
4. Problemas de certificados SSL/TLS
5. Timeout en la conexión

Para verificar estas restricciones, revisa los logs de Supabase y la configuración de red.
';

-- 7. Verificar si hay errores recientes relacionados con net.http_post en los logs
-- Nota: Esto depende de la configuración de logging de Supabase
RAISE NOTICE '
Para verificar errores en los logs:
1. Accede a la consola de Supabase
2. Ve a la sección de Logs
3. Busca errores relacionados con "net.http_post", "pg_net" o "webhook"
';

-- 8. Solución alternativa: Usar http_post en lugar de net.http_post
CREATE OR REPLACE FUNCTION test_http_post()
RETURNS JSONB AS $$
DECLARE
  webhook_url TEXT;
  result JSONB;
BEGIN
  -- Obtener la URL del webhook para clientes en producción
  SELECT value INTO webhook_url 
  FROM app_settings 
  WHERE key = 'webhook_url_client_production';
  
  -- Usar la extensión http para hacer la solicitud
  SELECT content::jsonb INTO result
  FROM http((
    'POST',
    webhook_url,
    ARRAY[http_header('Content-Type', 'application/json')],
    'application/json',
    '{"test": "http_extension_test"}'
  )::http_request);
  
  RETURN result;
EXCEPTION WHEN OTHERS THEN
  RETURN jsonb_build_object('error', SQLERRM);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Ejecutar la función de prueba
SELECT test_http_post();

-- 9. Verificar si la extensión http está instalada
SELECT extname, extversion 
FROM pg_extension 
WHERE extname = 'http';
