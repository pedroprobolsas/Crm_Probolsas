const express = require('express');
const compression = require('compression');
const path = require('path');

const app = express();
const PORT = process.env.PORT || 5173;

// Enable gzip compression
app.use(compression());

// Serve static files from the src directory for development
app.use(express.static(path.join(__dirname, 'src')));
app.use(express.static(__dirname));

// Handle client-side routing
app.get('*', (req, res) => {
  res.sendFile(path.join(__dirname, 'index.html'));
});

app.listen(PORT, '0.0.0.0', () => {
  console.log(`Development server running on port ${PORT}`);
  console.log(`Access it from your network at http://localhost:${PORT}`);
});
