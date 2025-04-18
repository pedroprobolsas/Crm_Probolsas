# Edge Functions en Supabase y su Relación con la Aplicación

Este documento explica cómo funcionan las Edge Functions en Supabase y cómo se relacionan con la aplicación.

## ¿Qué son las Edge Functions en Supabase?

Las Edge Functions en Supabase son funciones serverless que se ejecutan en el borde de la red, cerca de los usuarios. Están basadas en Deno, un entorno de ejecución seguro para JavaScript y TypeScript.

Las Edge Functions permiten ejecutar código en respuesta a eventos, como solicitudes HTTP, cambios en la base de datos, o eventos programados. Son ideales para:

- Procesamiento de datos en tiempo real
- Integración con servicios externos
- Lógica de negocio personalizada
- Webhooks y notificaciones

## Edge Functions en la Aplicación

En nuestra aplicación, utilizamos varias Edge Functions para extender la funcionalidad de Supabase:

1. **messages-outgoing**: Procesa los mensajes salientes (de agentes a clientes) y los envía a WhatsApp a través de Evolution API.
2. **messages-incoming**: Procesa los mensajes entrantes (de clientes a agentes) y los envía al webhook de IA cuando `asistente_ia_activado = true`.
3. **get-woo-products**: Obtiene los productos de WooCommerce.
4. **sync-woo-products**: Sincroniza los productos de WooCommerce con la base de datos.
5. **test-woo-connection**: Prueba la conexión con WooCommerce.
6. **update-woo-product**: Actualiza un producto en WooCommerce.

## Estructura de una Edge Function

Las Edge Functions en Supabase tienen la siguiente estructura:

```javascript
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

## Activación de Edge Functions

Las Edge Functions pueden activarse de varias formas:

1. **Solicitudes HTTP**: Puedes hacer una solicitud HTTP a la URL de la Edge Function.
2. **Webhooks de Base de Datos**: Puedes configurar un webhook de base de datos para activar la Edge Function cuando ocurre un evento en la base de datos.
3. **Eventos Programados**: Puedes configurar un evento programado para activar la Edge Function en un horario específico.

En nuestra aplicación, utilizamos webhooks de base de datos para activar las Edge Functions `messages-outgoing` y `messages-incoming` cuando se insertan nuevos mensajes en la tabla `messages`.

## Configuración de Webhooks de Base de Datos

Para configurar un webhook de base de datos en Supabase:

1. Accede a la consola de Supabase.
2. Ve a la sección de Database.
3. Selecciona la pestaña de Webhooks.
4. Haz clic en "Create Webhook".
5. Configura el webhook:
   - Nombre: Un nombre descriptivo para el webhook.
   - Tabla: La tabla que activará el webhook.
   - Eventos: Los eventos que activarán el webhook (INSERT, UPDATE, DELETE).
   - URL: La URL de la Edge Function.

## Problemas Comunes con Edge Functions

Algunos problemas comunes con Edge Functions son:

1. **Interferencia con Triggers de Base de Datos**: Las Edge Functions pueden interferir con los triggers de base de datos si ambos intentan actualizar los mismos datos.
2. **Límites de Tiempo de Ejecución**: Las Edge Functions tienen un límite de tiempo de ejecución de 60 segundos.
3. **Límites de Memoria**: Las Edge Functions tienen un límite de memoria de 1 GB.
4. **Límites de Tamaño de Respuesta**: Las Edge Functions tienen un límite de tamaño de respuesta de 6 MB.
5. **Límites de Concurrencia**: Las Edge Functions tienen un límite de concurrencia de 50 solicitudes por segundo.

## Solución a Problemas con Edge Functions

Para solucionar problemas con Edge Functions:

1. **Verificar los Logs**: Verifica los logs de las Edge Functions en la consola de Supabase.
2. **Verificar la Configuración**: Verifica la configuración de las Edge Functions y los webhooks de base de datos.
3. **Verificar las Variables de Entorno**: Verifica que las variables de entorno estén correctamente configuradas.
4. **Verificar las Dependencias**: Verifica que las dependencias estén correctamente instaladas.
5. **Verificar los Permisos**: Verifica que las Edge Functions tengan los permisos necesarios para acceder a los recursos que necesitan.

## Conclusión

Las Edge Functions en Supabase son una herramienta poderosa para extender la funcionalidad de la aplicación. Sin embargo, es importante asegurarse de que no interfieran con los triggers de base de datos y otros componentes de la aplicación.

La solución implementada corrige el problema del webhook de IA y establece una base sólida para el futuro. Al separar claramente las responsabilidades entre las Edge Functions y los triggers de base de datos, se evita que este problema vuelva a ocurrir.
