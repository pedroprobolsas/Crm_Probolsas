const express = require('express');
const compression = require('compression');
const path = require('path');
const fs = require('fs');

// Configuración de la aplicación
const app = express();
const PORT = process.env.PORT || 3000;

// Middleware para compresión
app.use(compression());

// Verificar si el directorio dist existe
const distPath = path.join(__dirname, 'dist');
if (!fs.existsSync(distPath)) {
  // Si no existe, crear un archivo index.html básico para que la aplicación funcione
  console.warn('ADVERTENCIA: El directorio dist/ no existe. Creando un archivo index.html básico...');
  
  try {
    fs.mkdirSync(distPath, { recursive: true });
    
    const htmlContent = `
    <!DOCTYPE html>
    <html lang="es">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>CRM Probolsas</title>
        <style>
            body { font-family: Arial, sans-serif; line-height: 1.6; margin: 0; padding: 20px; color: #333; }
            .container { max-width: 800px; margin: 0 auto; background-color: white; padding: 30px; border-radius: 8px; box-shadow: 0 2px 10px rgba(0, 0, 0, 0.1); }
            h1 { color: #0066cc; margin-top: 0; border-bottom: 2px solid #eee; padding-bottom: 10px; }
            .success { background-color: #d4edda; color: #155724; padding: 15px; border-radius: 4px; margin-bottom: 20px; }
            .warning { background-color: #fff3cd; color: #856404; padding: 15px; border-radius: 4px; margin-bottom: 20px; }
        </style>
    </head>
    <body>
        <div class="container">
            <h1>CRM Probolsas</h1>
            
            <div class="success">
                ¡El servidor Express está funcionando correctamente!
            </div>
            
            <div class="warning">
                No se encontró el directorio dist/ con los archivos compilados de la aplicación.
                Por favor, compila la aplicación y vuelve a desplegar el stack.
            </div>
            
            <p>Esta es una página de respaldo generada por el servidor.</p>
            <p>Fecha y hora del servidor: ${new Date().toISOString()}</p>
            
            <h2>Información del Servidor</h2>
            <ul>
                <li>Node.js: ${process.version}</li>
                <li>Express: ${require('express/package.json').version}</li>
            </ul>
        </div>
    </body>
    </html>
    `;
    
    fs.writeFileSync(path.join(distPath, 'index.html'), htmlContent);
    console.log('Archivo index.html básico creado correctamente');
  } catch (error) {
    console.error('Error al crear el archivo index.html básico:', error.message);
    process.exit(1);
  }
}

// Servir archivos estáticos desde la carpeta dist
app.use(express.static(distPath));

// Endpoint simple para verificar el estado del servidor
app.get('/health', (req, res) => {
  res.status(200).json({ 
    status: 'ok', 
    timestamp: new Date().toISOString() 
  });
});

// Manejar todas las rutas para SPA (Single Page Application)
app.get('*', (req, res) => {
  res.sendFile(path.join(distPath, 'index.html'));
});

// Iniciar el servidor
const server = app.listen(PORT, () => {
  console.log(`
========================================
  CRM Probolsas - Servidor Iniciado
========================================
- Puerto: ${PORT}
- Fecha y hora: ${new Date().toISOString()}
- Directorio estático: ${distPath}
========================================
  `);
  
  // Listar archivos en el directorio dist para diagnóstico
  try {
    const files = fs.readdirSync(distPath);
    console.log('Archivos en el directorio dist:');
    files.forEach(file => {
      console.log(`- ${file}`);
    });
  } catch (error) {
    console.error('Error al listar archivos:', error.message);
  }
});

// Manejar señales de terminación
process.on('SIGTERM', () => {
  console.log('Recibida señal SIGTERM, cerrando servidor...');
  server.close(() => {
    console.log('Servidor cerrado correctamente');
    process.exit(0);
  });
});

process.on('SIGINT', () => {
  console.log('Recibida señal SIGINT, cerrando servidor...');
  server.close(() => {
    console.log('Servidor cerrado correctamente');
    process.exit(0);
  });
});
