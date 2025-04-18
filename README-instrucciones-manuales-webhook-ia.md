# Instrucciones Manuales para Solucionar el Problema del Webhook de IA

Este documento proporciona instrucciones detalladas para aplicar manualmente las soluciones al problema del webhook de IA y la duplicación de clientes.

## Problema Identificado

Se han identificado dos problemas principales:

1. **Los mensajes de clientes no llegan al webhook de IA**: Aunque tienen `asistente_ia_activado = true`, los mensajes de clientes no se envían al webhook de IA, mientras que los mensajes de prueba sí funcionan correctamente.

2. **Duplicación de clientes**: Como consecuencia del problema anterior, se están duplicando clientes en el sistema.

## Soluciones Disponibles

Hemos desarrollado dos soluciones complementarias:

1. **Solución en Base de Datos**: Mejora los triggers y funciones en la base de datos para garantizar que los mensajes se envíen correctamente al webhook.

2. **Solución en Frontend**: Implementa un enfoque directo desde el frontend para enviar los mensajes al webhook, independientemente de los triggers de la base de datos.

## Instrucciones para Aplicar la Solución en Base de Datos

### Paso 1: Ejecutar el Script SQL

1. Abre la consola SQL de Supabase
2. Copia y pega el contenido del archivo `fix_webhook_ia_manual.sql`
3. Ejecuta el script completo

Este script realizará las siguientes acciones:

- Añadirá la columna `ia_webhook_sent` a la tabla `messages` si no existe
- Creará o reemplazará la función `notify_message_webhook` con verificaciones mejoradas
- Creará un nuevo trigger que responde a INSERT y UPDATE
- Creará una función para procesar mensajes pendientes
- Verificará la política RLS para la tabla `message_whatsapp_status`
- Verificará la instalación de la extensión http
- Procesará los mensajes pendientes de los últimos 7 días

### Paso 2: Actualizar la Edge Function

1. Ve a la sección 'Edge Functions' en la consola de Supabase
2. Selecciona la función `messages-incoming` (o créala si no existe)
3. Copia y pega el contenido del archivo `messages-incoming-manual.js`
4. Guarda los cambios
5. Despliega la función

## Instrucciones para Aplicar la Solución en Frontend

### Paso 1: Crear el Servicio de Webhook IA

1. Crea el archivo `src/lib/services/iaWebhookService.ts` con el contenido proporcionado
2. Este servicio se encargará de enviar los mensajes directamente al webhook de IA

### Paso 2: Modificar el Componente de Chat

1. Modifica el archivo `src/components/chat/ChatWithIA.tsx` para utilizar el nuevo servicio
2. Los cambios principales están en la función `handleSendMessage`

### Paso 3: Compilar y Desplegar

1. Ejecuta `npm run build` para compilar el proyecto
2. Despliega los cambios en tu servidor

## Verificación de la Solución

### Para la Solución en Base de Datos

1. Envía un mensaje de prueba con `asistente_ia_activado = true`
2. Verifica en los logs de Supabase que aparece el mensaje "Mensaje enviado al webhook de IA"
3. Verifica que el mensaje se ha marcado como enviado al webhook (`ia_webhook_sent = true`)

### Para la Solución en Frontend

1. Abre la consola del navegador
2. Envía un mensaje con el asistente de IA activado
3. Verifica que aparece el mensaje "Mensaje enviado correctamente al webhook de IA desde el frontend"
4. Verifica que la IA responde al mensaje

## Solución de Problemas

### Si la Extensión HTTP no está Instalada

Si recibes un error indicando que la extensión http no está instalada, ejecuta el siguiente comando en la consola SQL de Supabase:

```sql
CREATE EXTENSION http;
```

### Si los Mensajes Siguen sin Llegar al Webhook

1. Verifica que la URL del webhook está correctamente configurada en la tabla `app_settings` con la clave `webhook_url_ia_production`
2. Verifica que los mensajes tienen `asistente_ia_activado = true`
3. Verifica que los mensajes son de clientes (`sender = 'client'`)
4. Verifica que los mensajes están en estado enviado (`status = 'sent'`)
5. Verifica que los mensajes no son respuestas de la IA (no comienzan con `[IA]`)

### Si Siguen Apareciendo Clientes Duplicados

1. Verifica que la solución en frontend está correctamente implementada
2. Verifica que los mensajes se están marcando como enviados al webhook (`ia_webhook_sent = true`)
3. Verifica que no hay errores en la consola del navegador

## Conclusión

Estas soluciones proporcionan una forma robusta y confiable de enviar mensajes al webhook de IA, tanto desde la base de datos como desde el frontend. Al implementar ambas soluciones, garantizamos que los mensajes lleguen al webhook de forma inmediata, mejorando la experiencia del usuario y evitando la duplicación de clientes.

Si tienes alguna pregunta o problema, consulta la documentación detallada en los archivos README correspondientes o contacta al equipo de desarrollo.
