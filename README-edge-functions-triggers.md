# Relación entre Edge Functions y Triggers de Base de Datos

Este documento explica cómo se relacionan las Edge Functions y los triggers de base de datos en la aplicación.

## ¿Qué son los Triggers de Base de Datos?

Los triggers de base de datos son procedimientos almacenados que se ejecutan automáticamente en respuesta a eventos específicos en una tabla de la base de datos, como inserciones, actualizaciones o eliminaciones de registros.

Los triggers pueden realizar diversas acciones, como:

- Validar datos antes de insertarlos o actualizarlos
- Actualizar otros registros en la misma tabla o en otras tablas
- Enviar notificaciones o alertas
- Registrar cambios en tablas de auditoría
- Llamar a funciones externas o webhooks

## ¿Qué son las Edge Functions?

Las Edge Functions son funciones serverless que se ejecutan en el borde de la red, cerca de los usuarios. Están basadas en Deno, un entorno de ejecución seguro para JavaScript y TypeScript.

Las Edge Functions permiten ejecutar código en respuesta a eventos, como solicitudes HTTP, cambios en la base de datos, o eventos programados.

## Diferencias entre Triggers de Base de Datos y Edge Functions

| Característica | Triggers de Base de Datos | Edge Functions |
|----------------|---------------------------|----------------|
| Ubicación | Se ejecutan dentro de la base de datos | Se ejecutan en el borde de la red |
| Lenguaje | SQL, PL/pgSQL | JavaScript, TypeScript |
| Activación | Eventos de base de datos (INSERT, UPDATE, DELETE) | Solicitudes HTTP, webhooks de base de datos, eventos programados |
| Acceso a datos | Acceso directo a la base de datos | Acceso a través de la API de Supabase |
| Latencia | Baja (se ejecutan dentro de la base de datos) | Mayor (se ejecutan en el borde de la red) |
| Escalabilidad | Limitada por la capacidad de la base de datos | Alta (serverless) |
| Capacidades | Limitadas a las funciones de la base de datos | Amplias (acceso a servicios externos, procesamiento de datos, etc.) |

## Relación entre Triggers de Base de Datos y Edge Functions

En nuestra aplicación, los triggers de base de datos y las Edge Functions trabajan juntos para procesar los mensajes y enviarlos a los destinatarios correspondientes:

1. **Trigger `message_webhook_trigger`**: Se activa cuando se inserta un nuevo mensaje en la tabla `messages` con `asistente_ia_activado = true`. Llama a la función `notify_message_webhook`, que envía el mensaje al webhook de IA.

2. **Edge Function `messages-outgoing`**: Se activa cuando se inserta un nuevo mensaje en la tabla `messages` con `sender = 'agent'`. Envía el mensaje al cliente a través de WhatsApp.

3. **Edge Function `messages-incoming`**: Se activa cuando se inserta un nuevo mensaje en la tabla `messages` con `sender = 'client'` y `asistente_ia_activado = true`. Envía el mensaje al webhook de IA.

## Problema de Interferencia

El problema que se identificó es que las Edge Functions estaban interfiriendo con los triggers de base de datos:

1. La Edge Function `messages-outgoing` estaba actualizando los mensajes en la base de datos, lo que podría estar causando que los mensajes se procesen incorrectamente.
2. La función `notify_message_webhook` no estaba procesando correctamente los mensajes con `asistente_ia_activado = true`.

## Solución al Problema de Interferencia

La solución implementada:

1. **Recreación de la función `notify_message_webhook`**: Se ha recreado la función para asegurar que procese correctamente los mensajes con `asistente_ia_activado = true`.

2. **Modificación de las Edge Functions**: Se han modificado las Edge Functions para que no interfieran con el procesamiento de mensajes.

3. **Creación de la tabla `message_whatsapp_status`**: Se ha creado una tabla para rastrear el estado de envío de mensajes a WhatsApp sin modificar directamente los mensajes en la tabla `messages`.

## Mejores Prácticas para Evitar Interferencias

Para evitar interferencias entre triggers de base de datos y Edge Functions:

1. **Separación de Responsabilidades**: Cada componente debe tener una responsabilidad claramente definida.
   - Los triggers de base de datos deben encargarse de la lógica de negocio relacionada con la base de datos.
   - Las Edge Functions deben encargarse de la integración con servicios externos y el procesamiento de datos.

2. **Evitar Actualizaciones Duplicadas**: Evitar que tanto los triggers de base de datos como las Edge Functions actualicen los mismos datos.
   - Utilizar tablas separadas para rastrear el estado de los mensajes.
   - Utilizar campos específicos para cada componente.

3. **Coordinación de Eventos**: Asegurarse de que los eventos se procesen en el orden correcto.
   - Utilizar campos de estado para indicar el progreso del procesamiento.
   - Utilizar transacciones para asegurar la consistencia de los datos.

4. **Monitoreo y Logging**: Monitorear y registrar los eventos para detectar problemas.
   - Utilizar logs detallados para rastrear el flujo de los mensajes.
   - Verificar periódicamente los logs para detectar errores.

## Ejemplo de Flujo de Trabajo Correcto

Un ejemplo de flujo de trabajo correcto para el procesamiento de mensajes:

1. **Cliente envía un mensaje**:
   - El mensaje se inserta en la tabla `messages` con `sender = 'client'` y `asistente_ia_activado = true`.
   - El trigger `message_webhook_trigger` se activa y llama a la función `notify_message_webhook`.
   - La función `notify_message_webhook` envía el mensaje al webhook de IA y actualiza el campo `ia_webhook_sent` a `true`.

2. **Webhook de IA procesa el mensaje**:
   - El webhook de IA procesa el mensaje y genera una respuesta.
   - La respuesta se inserta en la tabla `messages` como un mensaje del agente.

3. **Agente envía un mensaje**:
   - El mensaje se inserta en la tabla `messages` con `sender = 'agent'`.
   - La Edge Function `messages-outgoing` se activa y envía el mensaje al cliente a través de WhatsApp.
   - La Edge Function `messages-outgoing` registra el estado de envío en la tabla `message_whatsapp_status`.

## Conclusión

La relación entre los triggers de base de datos y las Edge Functions es fundamental para el correcto funcionamiento de la aplicación. Al separar claramente las responsabilidades y evitar interferencias, se puede lograr un flujo de trabajo eficiente y confiable.

La solución implementada corrige el problema del webhook de IA y establece una base sólida para el futuro. Al separar claramente las responsabilidades entre las Edge Functions y los triggers de base de datos, se evita que este problema vuelva a ocurrir.
