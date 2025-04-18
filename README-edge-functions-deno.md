# Edge Functions en Deno

Este documento explica cómo funcionan las Edge Functions en Deno y cómo se relacionan con la aplicación.

## ¿Qué es Deno?

Deno es un entorno de ejecución seguro para JavaScript y TypeScript, creado por Ryan Dahl, el creador original de Node.js. Deno está diseñado para ser seguro por defecto, con un sistema de permisos que limita el acceso a recursos como el sistema de archivos, la red y el entorno.

Algunas características de Deno:

- Seguridad por defecto: No tiene acceso al sistema de archivos, la red o el entorno a menos que se le otorguen permisos explícitamente.
- Soporte nativo para TypeScript: No requiere configuración adicional para ejecutar código TypeScript.
- Módulos ES: Utiliza módulos ES en lugar de CommonJS.
- Importaciones por URL: Los módulos se importan directamente desde URLs.
- Compatibilidad con navegadores: API similar a la de los navegadores.
- Herramientas integradas: Incluye herramientas como un formateador de código, un linter y un generador de documentación.

## ¿Qué son las Edge Functions en Supabase?

Las Edge Functions en Supabase son funciones serverless que se ejecutan en el borde de la red, cerca de los usuarios. Están basadas en Deno, lo que les proporciona un entorno de ejecución seguro y moderno.

Las Edge Functions en Supabase permiten ejecutar código en respuesta a eventos, como solicitudes HTTP, cambios en la base de datos, o eventos programados.

## Estructura de una Edge Function en Deno

Las Edge Functions en Supabase tienen la siguiente estructura:

```typescript
import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "npm:@supabase/supabase-js@2";

// Configuración
const SOME_API_URL = 'https://api.example.com';
const SOME_API_KEY = 'your-api-key';

Deno.serve(async (req)=>{
  try {
    // Procesar la solicitud
    const { record, type } = await req.json();
    
    // Verificar condiciones
    if (type !== 'INSERT' || record.some_field !== 'some_value') {
      return new Response(JSON.stringify({
        success: false,
        message: 'Condición no cumplida'
      }), {
        headers: {
          'Content-Type': 'application/json'
        },
        status: 200
      });
    }
    
    // Crear cliente de Supabase
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '', 
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    );
    
    // Obtener datos de la base de datos
    const { data, error } = await supabaseClient
      .from('some_table')
      .select('*')
      .eq('id', record.some_id)
      .single();
    
    if (error) {
      throw new Error(`Error al obtener datos: ${error.message}`);
    }
    
    // Procesar datos
    // ...
    
    // Enviar datos a un servicio externo
    const response = await fetch(SOME_API_URL, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${SOME_API_KEY}`
      },
      body: JSON.stringify(data)
    });
    
    if (!response.ok) {
      throw new Error(`Error al enviar datos: ${response.statusText}`);
    }
    
    // Actualizar la base de datos
    const { error: updateError } = await supabaseClient
      .from('some_table')
      .update({ some_field: 'some_value' })
      .eq('id', record.some_id);
    
    if (updateError) {
      throw new Error(`Error al actualizar datos: ${updateError.message}`);
    }
    
    return new Response(JSON.stringify({
      success: true
    }), {
      headers: {
        'Content-Type': 'application/json'
      },
      status: 200
    });
  } catch (error) {
    console.error('Error:', error.message);
    return new Response(JSON.stringify({
      success: false,
      error: error.message
    }), {
      headers: {
        'Content-Type': 'application/json'
      },
      status: 500
    });
  }
});
```

## Importaciones en Deno

Deno utiliza importaciones por URL, lo que significa que los módulos se importan directamente desde URLs. En las Edge Functions de Supabase, se utilizan dos tipos de importaciones:

1. **Importaciones JSR**: JSR (JavaScript Registry) es un registro de paquetes para Deno. Se utiliza para importar tipos y definiciones.

   ```typescript
   import "jsr:@supabase/functions-js/edge-runtime.d.ts";
   ```

2. **Importaciones NPM**: Deno puede importar paquetes de NPM utilizando el prefijo `npm:`.

   ```typescript
   import { createClient } from "npm:@supabase/supabase-js@2";
   ```

## Deno.serve

`Deno.serve` es una función que crea un servidor HTTP en Deno. En las Edge Functions de Supabase, se utiliza para manejar las solicitudes HTTP.

```typescript
Deno.serve(async (req)=>{
  // Manejar la solicitud
});
```

La función `Deno.serve` recibe un callback que se ejecuta cada vez que se recibe una solicitud HTTP. El callback recibe un objeto `Request` y debe devolver un objeto `Response`.

## Request y Response

Deno utiliza la API Fetch, que es similar a la API Fetch de los navegadores. Esto incluye los objetos `Request` y `Response`.

### Request

El objeto `Request` representa una solicitud HTTP. Tiene propiedades y métodos para acceder a la información de la solicitud, como el método, las cabeceras, la URL y el cuerpo.

```typescript
const { record, type } = await req.json();
```

### Response

El objeto `Response` representa una respuesta HTTP. Se utiliza para devolver una respuesta al cliente.

```typescript
return new Response(JSON.stringify({
  success: true
}), {
  headers: {
    'Content-Type': 'application/json'
  },
  status: 200
});
```

## Variables de Entorno

Deno proporciona acceso a las variables de entorno a través del objeto `Deno.env`. En las Edge Functions de Supabase, se utilizan variables de entorno para almacenar información sensible, como las credenciales de Supabase.

```typescript
const supabaseClient = createClient(
  Deno.env.get('SUPABASE_URL') ?? '', 
  Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
);
```

## Manejo de Errores

Deno utiliza el manejo de errores estándar de JavaScript, con bloques `try/catch`.

```typescript
try {
  // Código que puede lanzar errores
} catch (error) {
  console.error('Error:', error.message);
  return new Response(JSON.stringify({
    success: false,
    error: error.message
  }), {
    headers: {
      'Content-Type': 'application/json'
    },
    status: 500
  });
}
```

## Despliegue de Edge Functions

Para desplegar una Edge Function en Supabase, se utiliza el comando `supabase functions deploy`:

```bash
supabase functions deploy <nombre-de-la-funcion>
```

Por ejemplo:

```bash
supabase functions deploy messages-outgoing
```

También puedes utilizar el script `update_edge_functions.ps1` para actualizar las Edge Functions:

```powershell
.\update_edge_functions.ps1
```

## Verificación de Edge Functions

Para verificar si las Edge Functions están correctamente desplegadas en Supabase, puedes utilizar el script `verify_edge_functions.ps1`:

```powershell
.\verify_edge_functions.ps1
```

## Conclusión

Las Edge Functions en Deno proporcionan un entorno de ejecución seguro y moderno para ejecutar código en el borde de la red. Supabase utiliza Deno para sus Edge Functions, lo que permite a los desarrolladores crear funciones serverless que se ejecutan cerca de los usuarios.

La combinación de Deno y Supabase proporciona una plataforma poderosa para crear aplicaciones web modernas y seguras. Las Edge Functions en Deno son una parte fundamental de la arquitectura de la aplicación, ya que permiten extender la funcionalidad de Supabase y crear integraciones con servicios externos.
