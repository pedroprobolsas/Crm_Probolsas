# Solución al Problema de Duplicación de Clientes

## Diagnóstico del Problema

Después de analizar el código y las imágenes proporcionadas, he identificado que el problema de duplicación de clientes está relacionado con el manejo incorrecto de los webhooks y las Edge Functions. Específicamente:

1. **Procesamiento Duplicado**: Los mensajes con `asistente_ia_activado=true` estaban siendo procesados tanto por el trigger SQL como por las Edge Functions, lo que resultaba en múltiples inserciones o actualizaciones.

2. **Falta de Control de Estado**: No había un mecanismo para rastrear qué mensajes ya habían sido enviados al webhook de IA, lo que podía resultar en envíos duplicados.

3. **Interferencia entre Sistemas**: Las Edge Functions `messages-incoming` y `messages-outgoing` no estaban correctamente coordinadas con el trigger SQL `notify_message_webhook`, causando condiciones de carrera y procesamiento duplicado.

## Cómo la Solución Resuelve el Problema

La solución implementada aborda estos problemas de la siguiente manera:

### 1. Adición de la Columna `ia_webhook_sent`

```sql
ALTER TABLE messages ADD COLUMN ia_webhook_sent BOOLEAN DEFAULT FALSE;
```

Esta columna permite rastrear qué mensajes ya han sido enviados al webhook de IA, evitando el procesamiento duplicado.

### 2. Mejora del Trigger SQL

```sql
-- Ignorar mensajes que ya han sido enviados al webhook
IF NEW.ia_webhook_sent = TRUE THEN
  RAISE NOTICE 'Mensaje ya enviado al webhook de IA, ignorando: %', NEW.id;
  RETURN NEW;
END IF;

-- Solo procesar mensajes con asistente_ia_activado=true
IF NEW.asistente_ia_activado IS NOT TRUE THEN
  RETURN NEW;
END IF;

-- Ignorar mensajes con prefijo [IA] para evitar duplicados
IF NEW.content LIKE '[IA]%' THEN
  RAISE NOTICE 'Mensaje con prefijo [IA] detectado, ignorando: %', NEW.id;
  RETURN NEW;
END IF;
```

Estas verificaciones aseguran que:
- No se procesen mensajes que ya han sido enviados al webhook
- Solo se procesen mensajes con `asistente_ia_activado=true`
- Se ignoren mensajes con prefijo `[IA]` (que son respuestas de la IA)

### 3. Actualización de la Edge Function `messages-incoming`

```javascript
// MODIFICACIÓN IMPORTANTE: Verificar si ya fue enviado al webhook de IA
if (message.sender === 'client' && message.asistente_ia_activado === true && message.ia_webhook_sent !== true) {
  console.log('Procesando mensaje con asistente_ia_activado=true que no ha sido enviado al webhook:', message.id);
  
  // ... procesamiento del mensaje ...
  
  // Actualizar el mensaje para indicar que se envió al webhook de IA
  const { error: updateError } = await supabaseClient
    .from('messages')
    .update({ ia_webhook_sent: true })
    .eq('id', message.id);
}
```

Esta modificación asegura que la Edge Function solo procese mensajes que:
- Son de clientes (`sender === 'client'`)
- Tienen el asistente de IA activado (`asistente_ia_activado === true`)
- No han sido enviados previamente al webhook (`ia_webhook_sent !== true`)

### 4. Actualización de la Edge Function `messages-outgoing`

```javascript
// MODIFICACIÓN IMPORTANTE: Verificación adicional para asegurarse de que no interfiera con el webhook de IA
if (record.asistente_ia_activado === true) {
  console.log('Mensaje con asistente_ia_activado=true, dejando que el trigger SQL lo maneje:', record.id);
  return new Response(JSON.stringify({
    success: false,
    message: 'Mensaje con asistente_ia_activado=true, dejando que el trigger SQL lo maneje'
  }), {
    headers: {
      'Content-Type': 'application/json'
    },
    status: 200
  });
}
```

Esta modificación hace que la Edge Function `messages-outgoing` ignore completamente los mensajes con `asistente_ia_activado=true`, dejando que sean manejados exclusivamente por el trigger SQL.

## Explicación de la Duplicación de Clientes

La duplicación de clientes ocurría porque:

1. Cuando un mensaje con `asistente_ia_activado=true` era insertado, tanto el trigger SQL como las Edge Functions intentaban procesarlo.

2. Ambos sistemas enviaban el mensaje al webhook de IA, lo que resultaba en múltiples llamadas con los mismos datos.

3. El sistema de IA (n8n) procesaba estas llamadas duplicadas como si fueran mensajes diferentes, lo que podía resultar en:
   - Múltiples respuestas para el mismo mensaje
   - Creación de conversaciones duplicadas
   - Creación de registros de clientes duplicados

4. Al no haber un mecanismo para rastrear qué mensajes ya habían sido procesados, el sistema no podía detectar ni prevenir estas duplicaciones.

## Verificación de la Solución

Para verificar que la solución funciona correctamente:

1. Envía un mensaje con el asistente de IA activado.
2. Verifica en los logs de Supabase que:
   - Solo uno de los sistemas (trigger SQL o Edge Function) procesa el mensaje
   - El mensaje se marca como enviado al webhook (`ia_webhook_sent=true`)
3. Verifica que no aparecen clientes duplicados en el módulo de clientes ni en las conversaciones.

## Recomendaciones Adicionales

Para evitar problemas similares en el futuro:

1. **Implementar Idempotencia**: Asegúrate de que todas las operaciones sean idempotentes (pueden ejecutarse múltiples veces sin efectos secundarios).

2. **Usar Identificadores Únicos**: Utiliza identificadores únicos para rastrear el procesamiento de mensajes y evitar duplicaciones.

3. **Centralizar la Lógica**: Considera centralizar la lógica de procesamiento de mensajes en un solo lugar (trigger SQL o Edge Function, pero no ambos).

4. **Mejorar el Logging**: Implementa un sistema de logging más detallado para facilitar la detección y diagnóstico de problemas similares en el futuro.
