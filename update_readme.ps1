# Script para actualizar el README-solucion-final.md con la información de los nuevos scripts
# Este script actualiza el README-solucion-final.md con la información de los nuevos scripts

# Verificar si el archivo README-solucion-final-actualizado.md existe
if (Test-Path "README-solucion-final-actualizado.md") {
    # Copiar el archivo README-solucion-final-actualizado.md a README-solucion-final.md
    Copy-Item "README-solucion-final-actualizado.md" "README-solucion-final.md" -Force
    
    Write-Host "README-solucion-final.md actualizado correctamente." -ForegroundColor Green
} else {
    Write-Host "El archivo README-solucion-final-actualizado.md no existe." -ForegroundColor Red
    exit 1
}

# Mostrar información
Write-Host ""
Write-Host "README-solucion-final.md actualizado correctamente." -ForegroundColor Green
Write-Host ""
Write-Host "Pasos para verificar:" -ForegroundColor Cyan
Write-Host "1. Abre el archivo README-solucion-final.md" -ForegroundColor Cyan
Write-Host "2. Verifica que la información de los nuevos scripts esté incluida" -ForegroundColor Cyan
Write-Host "3. Verifica que la información sea correcta" -ForegroundColor Cyan
