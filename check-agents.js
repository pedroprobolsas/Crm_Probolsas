import { createClient } from '@supabase/supabase-js';
import fs from 'fs';
import path from 'path';

// Leer el archivo .env manualmente
const envPath = path.resolve('.env');
const envContent = fs.readFileSync(envPath, 'utf8');

// Parsear el contenido del archivo .env
const envVars = {};
envContent.split('\n').forEach(line => {
  const match = line.match(/^([^=]+)=(.*)$/);
  if (match) {
    const key = match[1].trim();
    const value = match[2].trim();
    envVars[key] = value;
  }
});

const supabaseUrl = envVars.VITE_SUPABASE_URL;
const supabaseAnonKey = envVars.VITE_SUPABASE_ANON_KEY;

if (!supabaseUrl || !supabaseAnonKey) {
  console.error('Error: Faltan variables de entorno de Supabase');
  process.exit(1);
}

const supabase = createClient(supabaseUrl, supabaseAnonKey);

async function checkAgents() {
  try {
    console.log('Consultando la tabla agents...');
    const { data, error } = await supabase
      .from('agents')
      .select('*');

    if (error) {
      throw error;
    }

    if (data && data.length > 0) {
      console.log(`Se encontraron ${data.length} agentes:`);
      data.forEach(agent => {
        console.log(`- ${agent.name} (${agent.email}), Rol: ${agent.role}`);
      });
    } else {
      console.log('No se encontraron agentes en la base de datos.');
      console.log('Necesitas crear al menos un agente para poder iniciar sesión.');
    }
  } catch (error) {
    console.error('Error al consultar la tabla agents:', error.message);
  }
}

// Ejecutar la función
checkAgents();
