# Integración de n8n con el Asistente IA por Conversación

Este documento proporciona instrucciones detalladas sobre cómo integrar n8n con la configuración del Asistente IA por conversación para automatizar su activación y desactivación.

## Requisitos Previos

1. Instancia de n8n configurada y funcionando
2. Credenciales de acceso a la base de datos de Supabase
3. Migración `20250418000000_conversation_ia_settings.sql` aplicada

## Configuración de Credenciales en n8n

### 1. Configurar Credenciales de Supabase

1. En n8n, ve a **Credenciales** > **Nuevo**
2. Selecciona el tipo **Postgres**
3. Completa los siguientes campos:
   - **Nombre**: Supabase
   - **Host**: [URL de tu base de datos Supabase]
   - **Puerto**: 5432 (o el puerto configurado)
   - **Base de datos**: postgres
   - **Usuario**: postgres (o el usuario configurado)
   - **Contraseña**: [Contraseña de la base de datos]
   - **SSL**: Activado
4. Haz clic en **Guardar**

### 2. Configurar Credenciales de Slack (opcional)

Si deseas recibir notificaciones en Slack:

1. En n8n, ve a **Credenciales** > **Nuevo**
2. Selecciona el tipo **Slack API**
3. Completa los campos con la información de tu Webhook de Slack
4. Haz clic en **Guardar**

## Creación del Flujo de Trabajo

Puedes crear el flujo de trabajo manualmente siguiendo estos pasos, o importar el archivo `n8n-ia-assistant-workflow.json` proporcionado.

### Opción 1: Importar el Flujo de Trabajo

1. En n8n, ve a **Flujos de Trabajo** > **Importar desde archivo**
2. Selecciona el archivo `n8n-ia-assistant-workflow.json`
3. Haz clic en **Importar**
4. Configura las credenciales para los nodos que lo requieran
5. Guarda el flujo de trabajo

### Opción 2: Crear el Flujo de Trabajo Manualmente

#### 1. Crear un Nuevo Flujo de Trabajo

1. En n8n, ve a **Flujos de Trabajo** > **Nuevo**
2. Nombra el flujo como "Control Automático del Asistente IA por Conversación"

#### 2. Configurar el Trigger

1. Añade un nodo **Schedule Trigger**
2. Configúralo para que se ejecute cada 5 minutos (o el intervalo deseado)

#### 3. Obtener Conversaciones Activas

1. Añade un nodo **Postgres**
2. Configúralo con las credenciales de Supabase
3. Selecciona la operación **Execute Query**
4. Ingresa la siguiente consulta para obtener las conversaciones activas:

```sql
SELECT id FROM conversations 
WHERE updated_at > NOW() - INTERVAL '7 days'
ORDER BY updated_at DESC
LIMIT 50;
```

#### 4. Determinar el Estado del Asistente IA

1. Añade un nodo **Code**
2. Copia el siguiente código:

```javascript
// Obtener la hora actual en la zona horaria de México
const now = new Date();
const mexicoTime = new Intl.DateTimeFormat('es-MX', {
  timeZone: 'America/Mexico_City',
  hour: 'numeric',
  minute: 'numeric',
  hour12: false
}).format(now);

// Obtener día de la semana (0 = domingo, 6 = sábado)
const dayOfWeek = now.getDay();

// Extraer hora y minutos
const [hours, minutes] = mexicoTime.split(':').map(Number);

// Determinar si estamos en horario laboral
// Lunes a viernes (1-5) de 8:00 a 18:00
const isBusinessDay = dayOfWeek >= 1 && dayOfWeek <= 5;
const isBusinessHours = hours >= 8 && hours < 18;
const isBusinessTime = isBusinessDay && isBusinessHours;

// Verificar si hay alguna alerta de mantenimiento activa
// Esto podría venir de otra fuente de datos en un flujo real
const maintenanceMode = false;

// Determinar si el Asistente IA debe estar activado
const shouldBeEnabled = isBusinessTime && !maintenanceMode;

// Añadir razón para el cambio de estado
let reason = '';
if (!isBusinessDay) {
  reason = 'Fuera de días laborales (fin de semana)';
} else if (!isBusinessHours) {
  reason = `Fuera de horario laboral (${hours}:${minutes.toString().padStart(2, '0')})`;
} else if (maintenanceMode) {
  reason = 'Modo de mantenimiento activo';
} else {
  reason = 'Dentro de horario laboral';
}

// Obtener las conversaciones del nodo anterior
const conversations = $input.all();
const items = [];

// Preparar los datos para cada conversación
conversations.forEach(conv => {
  items.push({
    conversation_id: conv.json.id,
    shouldBeEnabled,
    reason
  });
});

return items;
```

#### 5. Procesar Cada Conversación

1. Añade un nodo **Split In Batches**
2. Configúralo para procesar cada conversación individualmente

#### 6. Verificar el Estado Actual de la Conversación

1. Añade un nodo **Postgres**
2. Configúralo con las credenciales de Supabase
3. Selecciona la operación **Execute Query**
4. Ingresa la siguiente consulta:

```sql
SELECT * FROM get_conversation_ia_state('{{$node["Split In Batches"].json["conversation_id"]}}');
```

#### 7. Verificar si se Necesita un Cambio

1. Añade un nodo **IF**
2. Configura la condición para comparar el estado actual con el estado deseado:
   - `{{$node["Verificar Estado Actual"].json["state"]}}` igual a `{{$node["Split In Batches"].json["shouldBeEnabled"]}}`

#### 8. Activar o Desactivar el Asistente IA para la Conversación

Para la rama "true" (no se necesita cambio):
1. Añade un nodo **Code** para registrar que no se requiere cambio

Para la rama "false" (se necesita cambio):
1. Añade un nodo **IF** para determinar si se debe activar o desactivar
2. Configura la condición:
   - `{{$node["Split In Batches"].json["shouldBeEnabled"]}}` igual a `true`

Para la rama "true" (activar):
1. Añade un nodo **Postgres**
2. Configúralo con las credenciales de Supabase
3. Selecciona la operación **Execute Query**
4. Ingresa la siguiente consulta:

```sql
SELECT * FROM update_conversation_ia_state(
  '{{$node["Split In Batches"].json["conversation_id"]}}',
  true,
  '{{$node["Split In Batches"].json["reason"]}}'
);
```

Para la rama "false" (desactivar):
1. Añade un nodo **Postgres**
2. Configúralo con las credenciales de Supabase
3. Selecciona la operación **Execute Query**
4. Ingresa la siguiente consulta:

```sql
SELECT * FROM update_conversation_ia_state(
  '{{$node["Split In Batches"].json["conversation_id"]}}',
  false,
  '{{$node["Split In Batches"].json["reason"]}}'
);
```

#### 9. Notificar el Cambio (opcional)

1. Añade un nodo **HTTP Request** o **Slack**
2. Configúralo para enviar una notificación con el nuevo estado y la razón del cambio

#### 10. Conectar los Nodos

Conecta los nodos según el flujo lógico descrito anteriormente.

## Personalización del Flujo de Trabajo

### Modificar las Reglas de Horario

Puedes modificar las reglas de horario en el nodo **Determinar Estado**:

```javascript
// Ejemplo: Cambiar el horario laboral a 9:00-17:00
const isBusinessHours = hours >= 9 && hours < 17;
```

### Añadir Condiciones Específicas por Conversación

Puedes añadir condiciones específicas para cada conversación:

```javascript
// Ejemplo: Verificar la prioridad del cliente
const getClientPriority = (conversationId) => {
  // Aquí podrías consultar la prioridad del cliente asociado a la conversación
  // Por simplicidad, usamos un valor aleatorio
  return Math.random() > 0.5 ? 'high' : 'normal';
};

// Preparar los datos para cada conversación
conversations.forEach(conv => {
  const conversationId = conv.json.id;
  const clientPriority = getClientPriority(conversationId);
  
  // Los clientes de alta prioridad siempre tienen el Asistente IA activado
  const conversationShouldBeEnabled = clientPriority === 'high' ? true : shouldBeEnabled;
  
  items.push({
    conversation_id: conversationId,
    shouldBeEnabled: conversationShouldBeEnabled,
    reason: clientPriority === 'high' ? 'Cliente prioritario' : reason
  });
});
```

### Integrar con Otras Fuentes de Datos

Puedes integrar el flujo de trabajo con otras fuentes de datos para tomar decisiones más informadas:

1. Añade nodos adicionales para obtener datos de otras fuentes (API, bases de datos, etc.)
2. Modifica el nodo **Determinar Estado** para utilizar estos datos

## Pruebas y Depuración

### Probar el Flujo de Trabajo

1. Haz clic en **Ejecutar** para probar el flujo de trabajo
2. Verifica los resultados de cada nodo
3. Asegúrate de que el estado del Asistente IA se actualice correctamente para cada conversación

### Depurar Problemas

Si encuentras problemas:

1. Verifica las credenciales de Supabase
2. Asegúrate de que la migración se haya aplicado correctamente
3. Revisa los logs de n8n para ver errores específicos
4. Verifica la tabla `conversation_settings_audit` para ver los cambios realizados

## Ejemplos de Casos de Uso Adicionales

### Desactivar el Asistente IA para Conversaciones Inactivas

Puedes crear un flujo de trabajo que desactive el Asistente IA para conversaciones que no han tenido actividad en un tiempo determinado:

1. Crea un nuevo flujo de trabajo
2. Configura un trigger programado (por ejemplo, cada día)
3. Añade un nodo **Postgres** para obtener conversaciones inactivas:

```sql
SELECT id FROM conversations 
WHERE updated_at < NOW() - INTERVAL '3 days'
AND id IN (
  SELECT conversation_id FROM conversation_settings
  WHERE ia_assistant_enabled = true
);
```

4. Procesa cada conversación y desactiva el Asistente IA:

```sql
SELECT * FROM update_conversation_ia_state(
  '{{$node["Split In Batches"].json["id"]}}',
  false,
  'Conversación inactiva por más de 3 días'
);
```

### Activar el Asistente IA para Clientes Prioritarios

Puedes crear un flujo de trabajo que active el Asistente IA para conversaciones con clientes prioritarios:

1. Crea un nuevo flujo de trabajo
2. Configura un trigger programado
3. Añade un nodo **Postgres** para obtener conversaciones de clientes prioritarios:

```sql
SELECT c.id FROM conversations c
JOIN clients cl ON c.client_id = cl.id
WHERE cl.priority = 'high'
AND c.id NOT IN (
  SELECT conversation_id FROM conversation_settings
  WHERE ia_assistant_enabled = true
);
```

4. Procesa cada conversación y activa el Asistente IA:

```sql
SELECT * FROM update_conversation_ia_state(
  '{{$node["Split In Batches"].json["id"]}}',
  true,
  'Cliente prioritario'
);
```

## Conclusión

Con esta integración, puedes automatizar la activación y desactivación del Asistente IA por conversación basado en diversas condiciones, como horario laboral, prioridad del cliente, actividad de la conversación, etc. Esto te permite optimizar el uso del Asistente IA y proporcionar una mejor experiencia a los usuarios.
