const express = require('express');
const compression = require('compression');
const path = require('path');
const fs = require('fs');

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware para compresión
app.use(compression());

// Verificar si el directorio dist existe
const distPath = path.join(__dirname, 'dist');
if (!fs.existsSync(distPath)) {
  console.error('ERROR: El directorio dist/ no existe. Asegúrate de compilar la aplicación antes de iniciar el servidor.');
  process.exit(1);
}

// Servir archivos estáticos desde la carpeta dist
app.use(express.static(distPath));

// Ruta para verificar que el servidor está funcionando
app.get('/health', (req, res) => {
  res.status(200).json({ status: 'ok', timestamp: new Date().toISOString() });
});

// Manejar todas las rutas para SPA (Single Page Application)
app.get('*', (req, res) => {
  res.sendFile(path.join(distPath, 'index.html'));
});

// Iniciar el servidor
app.listen(PORT, () => {
  console.log(`Servidor iniciado en el puerto ${PORT}`);
  console.log(`Fecha y hora: ${new Date().toISOString()}`);
  console.log(`Directorio de archivos estáticos: ${distPath}`);
  
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
  process.exit(0);
});

process.on('SIGINT', () => {
  console.log('Recibida señal SIGINT, cerrando servidor...');
  process.exit(0);
});
