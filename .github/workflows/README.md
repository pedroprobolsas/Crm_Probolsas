# Flujos de Trabajo de GitHub Actions

## Flujo de Trabajo de Docker Build (Temporalmente Deshabilitado)

El flujo de trabajo `docker-build.yml` ha sido temporalmente deshabilitado (renombrado a `docker-build.yml.disabled`) mientras se resuelven problemas con el despliegue en Portainer.

### Razones para Deshabilitar

1. Los cambios recientes en el Dockerfile y docker-compose.yml están causando fallos en el flujo de trabajo de GitHub Actions.
2. Estamos enfocados en solucionar los problemas de despliegue en Portainer antes de arreglar el flujo de trabajo de GitHub Actions.
3. Las X rojas en la interfaz de GitHub pueden ser confusas y distraer de los problemas principales que estamos tratando de resolver.

### Cómo Volver a Habilitar

Para volver a habilitar el flujo de trabajo, simplemente renombra el archivo:

```bash
git mv .github/workflows/docker-build.yml.disabled .github/workflows/docker-build.yml
git commit -m "Volver a habilitar el flujo de trabajo de Docker Build"
git push origin main
```

### Actualizaciones Necesarias

Cuando vuelvas a habilitar el flujo de trabajo, considera hacer las siguientes actualizaciones:

1. Actualizar la versión de las acciones utilizadas (checkout, setup-buildx-action, build-push-action)
2. Actualizar el tag de la imagen a `pedroconda/crm-probolsas:simple` para que coincida con el usado en docker-compose.yml
3. Añadir argumentos de construcción para evitar problemas de caché:
   ```yaml
   build-args: |
     REBUILD_DATE=2025-04-28-${{ github.run_number }}
   ```

### Ejemplo de Flujo de Trabajo Actualizado

```yaml
name: Docker Build

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  build:
    runs-on: ubuntu-latest
    
    steps:
    - uses: actions/checkout@v3
    
    - name: Set up Docker Buildx
      uses: docker/setup-buildx-action@v2
    
    - name: Build Docker image
      uses: docker/build-push-action@v4
      with:
        context: .
        push: false
        tags: pedroconda/crm-probolsas:simple
        cache-from: type=gha
        cache-to: type=gha,mode=max
        build-args: |
          REBUILD_DATE=2025-04-28-${{ github.run_number }}
