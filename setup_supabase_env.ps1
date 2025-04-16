# Script para configurar las variables de entorno necesarias para conectarse a Supabase
# Este script configura las variables de entorno que se utilizan en los scripts PowerShell
# para conectarse a la base de datos Supabase.

# Función para solicitar un valor al usuario
function Get-UserInput {
    param (
        [string]$prompt,
        [string]$defaultValue = ""
    )
    
    if ($defaultValue -ne "") {
        $userInput = Read-Host "$prompt [default: $defaultValue]"
        if ([string]::IsNullOrWhiteSpace($userInput)) {
            return $defaultValue
        }
        return $userInput
    }
    else {
        return Read-Host $prompt
    }
}

# Función para guardar las variables de entorno
function Save-EnvironmentVariables {
    param (
        [string]$host,
        [string]$port,
        [string]$user,
        [string]$password,
        [string]$database
    )
    
    # Guardar las variables de entorno para la sesión actual
    $env:SUPABASE_DB_HOST = $host
    $env:SUPABASE_DB_PORT = $port
    $env:SUPABASE_DB_USER = $user
    $env:SUPABASE_DB_PASSWORD = $password
    $env:SUPABASE_DB_NAME = $database
    
    # Mostrar las variables configuradas
    Write-Host ""
    Write-Host "Variables de entorno configuradas:" -ForegroundColor Green
    Write-Host "SUPABASE_DB_HOST = $env:SUPABASE_DB_HOST" -ForegroundColor Cyan
    Write-Host "SUPABASE_DB_PORT = $env:SUPABASE_DB_PORT" -ForegroundColor Cyan
    Write-Host "SUPABASE_DB_USER = $env:SUPABASE_DB_USER" -ForegroundColor Cyan
    Write-Host "SUPABASE_DB_NAME = $env:SUPABASE_DB_NAME" -ForegroundColor Cyan
    Write-Host "SUPABASE_DB_PASSWORD = ********" -ForegroundColor Cyan
    
    # Preguntar si se desea guardar las variables de entorno permanentemente
    $savePermantly = Get-UserInput "¿Deseas guardar estas variables de entorno permanentemente? (S/N)" "N"
    
    if ($savePermantly -eq "S" -or $savePermantly -eq "s") {
        try {
            # Guardar las variables de entorno permanentemente (solo para el usuario actual)
            [System.Environment]::SetEnvironmentVariable("SUPABASE_DB_HOST", $host, [System.EnvironmentVariableTarget]::User)
            [System.Environment]::SetEnvironmentVariable("SUPABASE_DB_PORT", $port, [System.EnvironmentVariableTarget]::User)
            [System.Environment]::SetEnvironmentVariable("SUPABASE_DB_USER", $user, [System.EnvironmentVariableTarget]::User)
            [System.Environment]::SetEnvironmentVariable("SUPABASE_DB_PASSWORD", $password, [System.EnvironmentVariableTarget]::User)
            [System.Environment]::SetEnvironmentVariable("SUPABASE_DB_NAME", $database, [System.EnvironmentVariableTarget]::User)
            
            Write-Host "Variables de entorno guardadas permanentemente para el usuario actual." -ForegroundColor Green
        }
        catch {
            Write-Host "Error al guardar las variables de entorno permanentemente: $_" -ForegroundColor Red
            Write-Host "Las variables de entorno solo estarán disponibles en la sesión actual de PowerShell." -ForegroundColor Yellow
        }
    }
    else {
        Write-Host "Las variables de entorno solo estarán disponibles en la sesión actual de PowerShell." -ForegroundColor Yellow
    }
}

# Función para probar la conexión a Supabase
function Test-SupabaseConnection {
    try {
        Write-Host "Probando conexión a Supabase..." -ForegroundColor Yellow
        
        # Ejecutar una consulta simple para verificar la conexión
        $env:PGPASSWORD = $env:SUPABASE_DB_PASSWORD
        $result = psql -h $env:SUPABASE_DB_HOST -p $env:SUPABASE_DB_PORT -U $env:SUPABASE_DB_USER -d $env:SUPABASE_DB_NAME -c "SELECT 1 as connection_test;" -t 2>&1
        
        if ($result -match "connection_test") {
            Write-Host "Conexión exitosa a Supabase." -ForegroundColor Green
            return $true
        }
        else {
            Write-Host "Error al conectar a Supabase: $result" -ForegroundColor Red
            return $false
        }
    }
    catch {
        Write-Host "Error al probar la conexión a Supabase: $_" -ForegroundColor Red
        return $false
    }
}

# Función principal
function Main {
    # Mostrar encabezado
    Write-Host "====================================================" -ForegroundColor Cyan
    Write-Host "  CONFIGURACIÓN DE VARIABLES DE ENTORNO PARA SUPABASE" -ForegroundColor Cyan
    Write-Host "====================================================" -ForegroundColor Cyan
    Write-Host ""
    
    # Verificar si psql está instalado
    try {
        $psqlVersion = psql --version 2>&1
        Write-Host "psql está instalado: $psqlVersion" -ForegroundColor Green
    }
    catch {
        Write-Host "Error: psql no está instalado o no está en el PATH." -ForegroundColor Red
        Write-Host "Por favor, instala PostgreSQL o asegúrate de que psql esté en el PATH." -ForegroundColor Red
        exit 1
    }
    
    # Verificar si ya existen variables de entorno
    $existingHost = $env:SUPABASE_DB_HOST
    $existingPort = $env:SUPABASE_DB_PORT
    $existingUser = $env:SUPABASE_DB_USER
    $existingPassword = $env:SUPABASE_DB_PASSWORD
    $existingDatabase = $env:SUPABASE_DB_NAME
    
    if ($existingHost -and $existingPort -and $existingUser -and $existingPassword -and $existingDatabase) {
        Write-Host "Se encontraron variables de entorno existentes:" -ForegroundColor Yellow
        Write-Host "SUPABASE_DB_HOST = $existingHost" -ForegroundColor Cyan
        Write-Host "SUPABASE_DB_PORT = $existingPort" -ForegroundColor Cyan
        Write-Host "SUPABASE_DB_USER = $existingUser" -ForegroundColor Cyan
        Write-Host "SUPABASE_DB_NAME = $existingDatabase" -ForegroundColor Cyan
        Write-Host "SUPABASE_DB_PASSWORD = ********" -ForegroundColor Cyan
        
        $useExisting = Get-UserInput "¿Deseas usar estas variables de entorno existentes? (S/N)" "S"
        
        if ($useExisting -eq "S" -or $useExisting -eq "s") {
            # Probar la conexión con las variables existentes
            $connectionSuccess = Test-SupabaseConnection
            
            if ($connectionSuccess) {
                Write-Host ""
                Write-Host "====================================================" -ForegroundColor Green
                Write-Host "  CONFIGURACIÓN COMPLETADA" -ForegroundColor Green
                Write-Host "====================================================" -ForegroundColor Green
                Write-Host ""
                Write-Host "Las variables de entorno están configuradas y la conexión a Supabase es exitosa." -ForegroundColor Green
                Write-Host ""
                Write-Host "Ahora puedes ejecutar los scripts SQL directamente:" -ForegroundColor Cyan
                Write-Host "1. Para aplicar la corrección:" -ForegroundColor Cyan
                Write-Host "   psql -h $env:SUPABASE_DB_HOST -p $env:SUPABASE_DB_PORT -U $env:SUPABASE_DB_USER -d $env:SUPABASE_DB_NAME -f fix_ia_webhook_format.sql" -ForegroundColor Cyan
                Write-Host ""
                Write-Host "2. Para probar la corrección:" -ForegroundColor Cyan
                Write-Host "   psql -h $env:SUPABASE_DB_HOST -p $env:SUPABASE_DB_PORT -U $env:SUPABASE_DB_USER -d $env:SUPABASE_DB_NAME -f test_ia_webhook_format.sql" -ForegroundColor Cyan
                return
            }
            else {
                Write-Host "No se pudo conectar a Supabase con las variables de entorno existentes." -ForegroundColor Red
                Write-Host "Por favor, proporciona nuevos valores." -ForegroundColor Yellow
            }
        }
    }
    
    # Solicitar los valores al usuario
    Write-Host "Por favor, proporciona los siguientes datos para conectarte a Supabase:" -ForegroundColor Yellow
    
    $host = Get-UserInput "Host de Supabase (ej. db.abcdefghijkl.supabase.co)" $existingHost
    $port = Get-UserInput "Puerto de Supabase (ej. 5432)" $existingPort
    if ([string]::IsNullOrWhiteSpace($port)) { $port = "5432" }
    $user = Get-UserInput "Usuario de Supabase (ej. postgres)" $existingUser
    if ([string]::IsNullOrWhiteSpace($user)) { $user = "postgres" }
    $password = Get-UserInput "Contraseña de Supabase" $existingPassword
    $database = Get-UserInput "Nombre de la base de datos (ej. postgres)" $existingDatabase
    if ([string]::IsNullOrWhiteSpace($database)) { $database = "postgres" }
    
    # Guardar las variables de entorno
    Save-EnvironmentVariables -host $host -port $port -user $user -password $password -database $database
    
    # Probar la conexión
    $connectionSuccess = Test-SupabaseConnection
    
    if ($connectionSuccess) {
        Write-Host ""
        Write-Host "====================================================" -ForegroundColor Green
        Write-Host "  CONFIGURACIÓN COMPLETADA" -ForegroundColor Green
        Write-Host "====================================================" -ForegroundColor Green
        Write-Host ""
        Write-Host "Las variables de entorno están configuradas y la conexión a Supabase es exitosa." -ForegroundColor Green
        Write-Host ""
        Write-Host "Ahora puedes ejecutar los scripts SQL directamente:" -ForegroundColor Cyan
        Write-Host "1. Para aplicar la corrección:" -ForegroundColor Cyan
        Write-Host "   psql -h $env:SUPABASE_DB_HOST -p $env:SUPABASE_DB_PORT -U $env:SUPABASE_DB_USER -d $env:SUPABASE_DB_NAME -f fix_ia_webhook_format.sql" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "2. Para probar la corrección:" -ForegroundColor Cyan
        Write-Host "   psql -h $env:SUPABASE_DB_HOST -p $env:SUPABASE_DB_PORT -U $env:SUPABASE_DB_USER -d $env:SUPABASE_DB_NAME -f test_ia_webhook_format.sql" -ForegroundColor Cyan
    }
    else {
        Write-Host ""
        Write-Host "====================================================" -ForegroundColor Red
        Write-Host "  ERROR DE CONFIGURACIÓN" -ForegroundColor Red
        Write-Host "====================================================" -ForegroundColor Red
        Write-Host ""
        Write-Host "No se pudo conectar a Supabase con las variables de entorno proporcionadas." -ForegroundColor Red
        Write-Host "Por favor, verifica los datos e intenta nuevamente." -ForegroundColor Red
    }
}

# Ejecutar la función principal
Main
