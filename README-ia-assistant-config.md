# Configuración del Asistente IA por Conversación

Este documento describe la implementación de la configuración del Asistente IA por conversación, que permite controlar el estado del botón de Asistente IA de forma independiente para cada conversación.

## Descripción de la Funcionalidad

La funcionalidad implementada permite:

1. Guardar el estado del botón de Asistente IA en la base de datos para cada conversación
2. Controlar el estado del botón desde sistemas externos como n8n
3. Sincronizar el estado entre múltiples usuarios y dispositivos
4. Registrar cambios en el estado para auditoría
5. Mostrar notificaciones cuando el estado cambia externamente

## Componentes Implementados

### 1. Base de Datos

- **Tabla `conversation_settings`**: Almacena la configuración del Asistente IA por conversación
- **Tabla `conversation_settings_audit`**: Registra todos los cambios en la configuración
- **Funciones SQL**:
  - `get_conversation_ia_state(conversation_uuid)`: Consulta el estado actual para una conversación
  - `update_conversation_ia_state(conversation_uuid, new_state, reason)`: Actualiza el estado para una conversación
- **Políticas RLS**: Controlan el acceso a la configuración

### 2. Frontend

- **Hook `useIAAssistantState`**: Gestiona el estado del Asistente IA para una conversación específica
- **Componente `IAAssistantButton`**: Muestra el estado actual y permite cambiarlo
- **Componente `ChatInputWithIA`**: Utiliza el estado de la conversación para enviar mensajes

## Integración con n8n

Para integrar con n8n, se pueden utilizar las funciones SQL creadas:

### Consultar el estado actual para una conversación

```sql
SELECT * FROM get_conversation_ia_state('ID_DE_CONVERSACION_AQUÍ');
```

Retorna:
```json
{
  "success": true,
  "state": true,
  "conversation_id": "ID_DE_CONVERSACION_AQUÍ",
  "timestamp": "2025-04-18T09:00:00Z"
}
```

### Actualizar el estado para una conversación

```sql
SELECT * FROM update_conversation_ia_state('ID_DE_CONVERSACION_AQUÍ', false, 'Desactivado por inactividad');
```

Retorna:
```json
{
  "success": true,
  "message": "Estado del Asistente IA actualizado correctamente",
  "new_state": false,
  "conversation_id": "ID_DE_CONVERSACION_AQUÍ",
  "timestamp": "2025-04-18T09:00:00Z"
}
```

## Flujo de Trabajo en n8n

Un flujo de trabajo típico en n8n podría ser:

1. **Trigger**: Un evento que inicia el flujo (programado, webhook, etc.)
2. **Obtener conversaciones**: Consultar las conversaciones activas
3. **Decisión**: Lógica para determinar si el Asistente IA debe estar activado o desactivado para cada conversación
4. **Acción**: Llamada a la función `update_conversation_ia_state` con el nuevo estado para cada conversación

Ejemplo de casos de uso:

- Desactivar el Asistente IA para conversaciones inactivas por más de 24 horas
- Activar el Asistente IA para conversaciones con clientes prioritarios
- Desactivar temporalmente durante mantenimiento del sistema para todas las conversaciones

## Consideraciones de Seguridad

- Las políticas RLS permiten que cualquier usuario autenticado lea y actualice la configuración
- Se ha creado una política especial para permitir actualizaciones desde servicios externos
- Todos los cambios se registran en la tabla de auditoría con el ID de la conversación

## Recuperación ante Fallos

- Si la consulta a la base de datos falla, se utiliza un valor predeterminado (true)
- Si no existe un registro para una conversación, se crea automáticamente con el valor predeterminado
- Se implementan reintentos para actualizaciones fallidas
- Se muestra un indicador de carga durante las operaciones

## Experiencia de Usuario

- El botón muestra claramente si el Asistente IA está activado o desactivado para la conversación actual
- Se muestra un indicador de carga durante las actualizaciones
- Se muestran notificaciones cuando el estado cambia externamente
- El estado se sincroniza automáticamente entre múltiples pestañas/dispositivos
- Cada conversación mantiene su propio estado independiente

## Aplicación de la Migración

Para aplicar la migración que implementa esta funcionalidad:

1. Ejecute el script `apply_conversation_ia_settings.ps1`
2. Siga las instrucciones para aplicar la migración SQL
3. Verifique la instalación con el script `test_conversation_ia_settings.sql`

## Solución de Problemas

Si el estado del Asistente IA no se actualiza correctamente:

1. Verifique que la migración se haya aplicado correctamente
2. Compruebe los logs de Supabase para ver si hay errores
3. Verifique que las políticas RLS permitan el acceso adecuado
4. Compruebe la tabla de auditoría para ver los últimos cambios para la conversación específica
5. Verifique que el ID de conversación sea válido y exista en la base de datos
