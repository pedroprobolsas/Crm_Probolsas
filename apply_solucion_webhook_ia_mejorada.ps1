# Script para aplicar la solución mejorada del webhook de IA
# Este script aplica todas las soluciones necesarias para resolver el problema del webhook de IA y la duplicación de clientes

# Configuración
$supabaseUrl = $env:SUPABASE_URL
$supabaseKey = $env:SUPABASE_SERVICE_ROLE_KEY
$supabaseCli = "supabase"

# Función para mostrar mensajes con colores
function Write-ColorOutput {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Message,
        
        [Parameter(Mandatory=$false)]
        [string]$ForegroundColor = "White"
    )
    
    Write-Host $Message -ForegroundColor $ForegroundColor
}

# Verificar si las variables de entorno están configuradas
if (-not $supabaseUrl -or -not $supabaseKey) {
    Write-ColorOutput "ERROR: Las variables de entorno SUPABASE_URL y SUPABASE_SERVICE_ROLE_KEY deben estar configuradas." -ForegroundColor "Red"
    Write-ColorOutput "Puedes configurarlas ejecutando:" -ForegroundColor "Yellow"
    Write-ColorOutput '$env:SUPABASE_URL = "tu-url-de-supabase"' -ForegroundColor "Yellow"
    Write-ColorOutput '$env:SUPABASE_SERVICE_ROLE_KEY = "tu-service-role-key"' -ForegroundColor "Yellow"
    exit 1
}

# Verificar si el CLI de Supabase está instalado
try {
    $supabaseVersion = & $supabaseCli --version
    Write-ColorOutput "Supabase CLI detectado: $supabaseVersion" -ForegroundColor "Green"
} catch {
    Write-ColorOutput "ADVERTENCIA: No se pudo detectar Supabase CLI. Se intentará aplicar la solución sin él." -ForegroundColor "Yellow"
    Write-ColorOutput "Para instalar Supabase CLI, sigue las instrucciones en: https://supabase.com/docs/guides/cli" -ForegroundColor "Yellow"
}

# Paso 1: Aplicar el script SQL mejorado
Write-ColorOutput "Paso 1: Aplicando el script SQL mejorado..." -ForegroundColor "Cyan"

try {
    # Verificar si el archivo existe
    if (-not (Test-Path "fix_webhook_ia_mejorado.sql")) {
        Write-ColorOutput "ERROR: No se encontró el archivo fix_webhook_ia_mejorado.sql" -ForegroundColor "Red"
        exit 1
    }
    
    # Ejecutar el script SQL usando Supabase CLI si está disponible
    try {
        & $supabaseCli db execute --file fix_webhook_ia_mejorado.sql
        Write-ColorOutput "Script SQL ejecutado correctamente mediante Supabase CLI" -ForegroundColor "Green"
    } catch {
        Write-ColorOutput "No se pudo ejecutar el script SQL mediante Supabase CLI. Por favor, ejecuta el script manualmente en la consola SQL de Supabase." -ForegroundColor "Yellow"
        Write-ColorOutput "Archivo: fix_webhook_ia_mejorado.sql" -ForegroundColor "Yellow"
    }
} catch {
    Write-ColorOutput "ERROR al aplicar el script SQL: $_" -ForegroundColor "Red"
    Write-ColorOutput "Por favor, ejecuta el script manualmente en la consola SQL de Supabase." -ForegroundColor "Yellow"
    Write-ColorOutput "Archivo: fix_webhook_ia_mejorado.sql" -ForegroundColor "Yellow"
}

# Paso 2: Actualizar la Edge Function messages-incoming
Write-ColorOutput "Paso 2: Actualizando la Edge Function messages-incoming..." -ForegroundColor "Cyan"

try {
    # Verificar si el archivo existe
    if (-not (Test-Path "messages-incoming-mejorado.js")) {
        Write-ColorOutput "ERROR: No se encontró el archivo messages-incoming-mejorado.js" -ForegroundColor "Red"
        exit 1
    }
    
    # Crear directorio temporal para la Edge Function
    $tempDir = "temp_edge_function"
    if (-not (Test-Path $tempDir)) {
        New-Item -ItemType Directory -Path $tempDir | Out-Null
    }
    
    # Copiar el archivo a la estructura correcta
    Copy-Item "messages-incoming-mejorado.js" -Destination "$tempDir/index.js"
    
    # Actualizar la Edge Function usando Supabase CLI si está disponible
    try {
        & $supabaseCli functions deploy messages-incoming --project-ref (Split-Path -Leaf $supabaseUrl) --no-verify-jwt
        Write-ColorOutput "Edge Function messages-incoming actualizada correctamente mediante Supabase CLI" -ForegroundColor "Green"
    } catch {
        Write-ColorOutput "No se pudo actualizar la Edge Function mediante Supabase CLI. Por favor, actualiza la función manualmente en la consola de Supabase." -ForegroundColor "Yellow"
        Write-ColorOutput "Archivo: messages-incoming-mejorado.js" -ForegroundColor "Yellow"
    }
    
    # Limpiar directorio temporal
    Remove-Item -Recurse -Force $tempDir
} catch {
    Write-ColorOutput "ERROR al actualizar la Edge Function: $_" -ForegroundColor "Red"
    Write-ColorOutput "Por favor, actualiza la función manualmente en la consola de Supabase." -ForegroundColor "Yellow"
    Write-ColorOutput "Archivo: messages-incoming-mejorado.js" -ForegroundColor "Yellow"
}

# Paso 3: Verificar la solución
Write-ColorOutput "Paso 3: Verificando la solución..." -ForegroundColor "Cyan"

try {
    # Verificar si el archivo existe
    if (-not (Test-Path "verify_webhook_ia_solucion_mejorada.sql")) {
        Write-ColorOutput "ERROR: No se encontró el archivo verify_webhook_ia_solucion_mejorada.sql" -ForegroundColor "Red"
        exit 1
    }
    
    # Ejecutar el script SQL usando Supabase CLI si está disponible
    try {
        & $supabaseCli db execute --file verify_webhook_ia_solucion_mejorada.sql
        Write-ColorOutput "Script de verificación ejecutado correctamente mediante Supabase CLI" -ForegroundColor "Green"
    } catch {
        Write-ColorOutput "No se pudo ejecutar el script de verificación mediante Supabase CLI. Por favor, ejecuta el script manualmente en la consola SQL de Supabase." -ForegroundColor "Yellow"
        Write-ColorOutput "Archivo: verify_webhook_ia_solucion_mejorada.sql" -ForegroundColor "Yellow"
    }
} catch {
    Write-ColorOutput "ERROR al ejecutar el script de verificación: $_" -ForegroundColor "Red"
    Write-ColorOutput "Por favor, ejecuta el script manualmente en la consola SQL de Supabase." -ForegroundColor "Yellow"
    Write-ColorOutput "Archivo: verify_webhook_ia_solucion_mejorada.sql" -ForegroundColor "Yellow"
}

# Resumen final
Write-ColorOutput "------------------------------------------------------------" -ForegroundColor "White"
Write-ColorOutput "RESUMEN DE LA APLICACIÓN DE LA SOLUCIÓN MEJORADA" -ForegroundColor "Green"
Write-ColorOutput "------------------------------------------------------------" -ForegroundColor "White"
Write-ColorOutput "1. Script SQL mejorado aplicado (o instrucciones proporcionadas)" -ForegroundColor "White"
Write-ColorOutput "2. Edge Function messages-incoming actualizada (o instrucciones proporcionadas)" -ForegroundColor "White"
Write-ColorOutput "3. Verificación ejecutada (o instrucciones proporcionadas)" -ForegroundColor "White"
Write-ColorOutput "------------------------------------------------------------" -ForegroundColor "White"
Write-ColorOutput "Para más detalles sobre la solución, consulta:" -ForegroundColor "White"
Write-ColorOutput "README-solucion-webhook-ia-actualizada.md" -ForegroundColor "Cyan"
Write-ColorOutput "------------------------------------------------------------" -ForegroundColor "White"
Write-ColorOutput "Si encuentras algún problema, ejecuta los scripts manualmente siguiendo las instrucciones en:" -ForegroundColor "White"
Write-ColorOutput "README-solucion-webhook-ia-actualizada.md" -ForegroundColor "Cyan"
Write-ColorOutput "------------------------------------------------------------" -ForegroundColor "White"
