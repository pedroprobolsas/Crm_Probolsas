import { createClient } from '@supabase/supabase-js';

// Definir directamente las variables de Supabase
const supabaseUrl = 'https://egiyffxvnknfehlfnovf.supabase.co';
const supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImVnaXlmZnh2bmtuZmVobGZub3ZmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MTM5MjA5NjcsImV4cCI6MjAyOTQ5Njk2N30.Nh8F_3CXuYpVXRVE8_gJdXKRD7Y2VdPr9JTcIhN-68s';

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
      
      // Si no hay agentes, sugerir crear uno
      console.log('\nPara crear un agente, primero debes registrar un usuario en Supabase Auth:');
      console.log('1. Ve a https://app.supabase.io');
      console.log('2. Selecciona tu proyecto');
      console.log('3. Ve a Authentication > Users');
      console.log('4. Haz clic en "Add User" y crea un usuario');
      console.log('5. Luego, inserta un registro en la tabla "agents" con el mismo email');
    }
  } catch (error) {
    console.error('Error al consultar la tabla agents:', error.message);
  }
}

// Ejecutar la función
checkAgents();
