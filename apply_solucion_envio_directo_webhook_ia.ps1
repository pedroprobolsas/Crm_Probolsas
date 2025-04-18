# Script para aplicar la solución de envío directo al webhook de IA
# Este script compila y despliega los cambios necesarios para implementar la solución

# Configuración
$projectRoot = Get-Location
$buildCommand = "npm run build"
$deployCommand = "npm run deploy"

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

# Mostrar encabezado
Write-ColorOutput "============================================================" -ForegroundColor "Cyan"
Write-ColorOutput "  APLICACIÓN DE SOLUCIÓN DE ENVÍO DIRECTO AL WEBHOOK DE IA  " -ForegroundColor "Cyan"
Write-ColorOutput "============================================================" -ForegroundColor "Cyan"
Write-ColorOutput ""

# Verificar que estamos en el directorio correcto
if (-not (Test-Path "src/components/chat/ChatWithIA.tsx")) {
    Write-ColorOutput "ERROR: No se encontró el archivo ChatWithIA.tsx. Asegúrate de ejecutar este script desde el directorio raíz del proyecto." -ForegroundColor "Red"
    exit 1
}

# Paso 1: Verificar que los archivos existen
Write-ColorOutput "Paso 1: Verificando archivos..." -ForegroundColor "Yellow"

$requiredFiles = @(
    "src/lib/services/iaWebhookService.ts",
    "src/components/chat/ChatWithIA.tsx"
)

$allFilesExist = $true
foreach ($file in $requiredFiles) {
    if (Test-Path $file) {
        Write-ColorOutput "  ✓ $file existe" -ForegroundColor "Green"
    } else {
        Write-ColorOutput "  ✗ $file no existe" -ForegroundColor "Red"
        $allFilesExist = $false
    }
}

if (-not $allFilesExist) {
    Write-ColorOutput "ERROR: Faltan archivos necesarios. Asegúrate de que todos los archivos existan antes de continuar." -ForegroundColor "Red"
    exit 1
}

Write-ColorOutput "  ✓ Todos los archivos necesarios existen" -ForegroundColor "Green"
Write-ColorOutput ""

# Paso 2: Instalar dependencias si es necesario
Write-ColorOutput "Paso 2: Verificando dependencias..." -ForegroundColor "Yellow"

try {
    # Verificar si node_modules existe
    if (-not (Test-Path "node_modules")) {
        Write-ColorOutput "  ⚠ No se encontró el directorio node_modules. Instalando dependencias..." -ForegroundColor "Yellow"
        
        # Ejecutar npm install
        Write-ColorOutput "  Ejecutando: npm install" -ForegroundColor "Cyan"
        npm install
        
        if ($LASTEXITCODE -ne 0) {
            throw "Error al instalar dependencias"
        }
        
        Write-ColorOutput "  ✓ Dependencias instaladas correctamente" -ForegroundColor "Green"
    } else {
        Write-ColorOutput "  ✓ El directorio node_modules existe" -ForegroundColor "Green"
    }
} catch {
    Write-ColorOutput "ERROR: No se pudieron instalar las dependencias: $_" -ForegroundColor "Red"
    Write-ColorOutput "Intenta ejecutar 'npm install' manualmente y luego vuelve a ejecutar este script." -ForegroundColor "Yellow"
    exit 1
}

Write-ColorOutput ""

# Paso 3: Compilar el proyecto
Write-ColorOutput "Paso 3: Compilando el proyecto..." -ForegroundColor "Yellow"

try {
    # Ejecutar el comando de compilación
    Write-ColorOutput "  Ejecutando: $buildCommand" -ForegroundColor "Cyan"
    Invoke-Expression $buildCommand
    
    if ($LASTEXITCODE -ne 0) {
        throw "Error al compilar el proyecto"
    }
    
    Write-ColorOutput "  ✓ Proyecto compilado correctamente" -ForegroundColor "Green"
} catch {
    Write-ColorOutput "ERROR: No se pudo compilar el proyecto: $_" -ForegroundColor "Red"
    Write-ColorOutput "Intenta compilar manualmente con '$buildCommand' y luego despliega con '$deployCommand'." -ForegroundColor "Yellow"
    exit 1
}

Write-ColorOutput ""

# Paso 4: Desplegar el proyecto (opcional)
Write-ColorOutput "Paso 4: ¿Deseas desplegar el proyecto ahora? (S/N)" -ForegroundColor "Yellow"
$deployNow = Read-Host

if ($deployNow -eq "S" -or $deployNow -eq "s") {
    try {
        # Ejecutar el comando de despliegue
        Write-ColorOutput "  Ejecutando: $deployCommand" -ForegroundColor "Cyan"
        Invoke-Expression $deployCommand
        
        if ($LASTEXITCODE -ne 0) {
            throw "Error al desplegar el proyecto"
        }
        
        Write-ColorOutput "  ✓ Proyecto desplegado correctamente" -ForegroundColor "Green"
    } catch {
        Write-ColorOutput "ERROR: No se pudo desplegar el proyecto: $_" -ForegroundColor "Red"
        Write-ColorOutput "Intenta desplegar manualmente con '$deployCommand'." -ForegroundColor "Yellow"
        exit 1
    }
} else {
    Write-ColorOutput "  ℹ Despliegue omitido. Puedes desplegar manualmente con '$deployCommand'." -ForegroundColor "Cyan"
}

Write-ColorOutput ""

# Resumen final
Write-ColorOutput "============================================================" -ForegroundColor "Cyan"
Write-ColorOutput "                  RESUMEN DE LA APLICACIÓN                  " -ForegroundColor "Cyan"
Write-ColorOutput "============================================================" -ForegroundColor "Cyan"
Write-ColorOutput ""
Write-ColorOutput "La solución de envío directo al webhook de IA ha sido aplicada correctamente." -ForegroundColor "Green"
Write-ColorOutput ""
Write-ColorOutput "Archivos modificados:" -ForegroundColor "White"
Write-ColorOutput "  - src/lib/services/iaWebhookService.ts (nuevo)" -ForegroundColor "White"
Write-ColorOutput "  - src/components/chat/ChatWithIA.tsx (modificado)" -ForegroundColor "White"
Write-ColorOutput ""
Write-ColorOutput "Para más detalles sobre la solución, consulta:" -ForegroundColor "White"
Write-ColorOutput "  README-solucion-envio-directo-webhook-ia.md" -ForegroundColor "Cyan"
Write-ColorOutput ""
Write-ColorOutput "Para verificar que la solución funciona correctamente:" -ForegroundColor "White"
Write-ColorOutput "  1. Envía un mensaje con el asistente de IA activado" -ForegroundColor "White"
Write-ColorOutput "  2. Verifica en la consola del navegador que aparece el mensaje" -ForegroundColor "White"
Write-ColorOutput "     'Mensaje enviado correctamente al webhook de IA desde el frontend'" -ForegroundColor "White"
Write-ColorOutput "  3. Verifica que la IA responde al mensaje" -ForegroundColor "White"
Write-ColorOutput ""
Write-ColorOutput "============================================================" -ForegroundColor "Cyan"
