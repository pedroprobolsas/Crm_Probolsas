import { createClient } from '@supabase/supabase-js';

// Definir directamente las variables de Supabase
const supabaseUrl = 'https://egiyffxvnknfehlfnovf.supabase.co';
const supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImVnaXlmZnh2bmtuZmVobGZub3ZmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzkzODg4OTAsImV4cCI6MjA1NDk2NDg5MH0.qW2THTMrJ7k8mKnQd24g8paHcAe6SQy0SQRp_pLEfbs';

const supabase = createClient(supabaseUrl, supabaseAnonKey);

// Datos del usuario administrador
const adminUser = {
  email: 'admin@probolsas.com',
  password: 'admin123',
  name: 'Administrador',
  role: 'admin',
  status: 'online'
};

async function createAdminUser() {
  try {
    console.log('Creando usuario administrador...');
    
// 1. Registrar el usuario en la autenticación de Supabase
    console.log('Paso 1: Registrando usuario en autenticación...');
    const { data: authData, error: authError } = await supabase.auth.signUp({
      email: adminUser.email,
      password: adminUser.password,
      options: {
        emailRedirectTo: `${process.env.SITE_URL || 'http://localhost:5174'}/login`,
        data: {
          name: adminUser.name,
          role: adminUser.role
        }
      }
    });
    
    if (authError) {
      throw authError;
    }
    
    console.log('Usuario registrado en autenticación:', authData.user.id);
    
    // 2. Crear el registro en la tabla agents
    console.log('Paso 2: Creando registro en la tabla agents...');
    const { data: agentData, error: agentError } = await supabase
      .from('agents')
      .insert([
        {
          id: authData.user.id,
          email: adminUser.email,
          name: adminUser.name,
          role: adminUser.role,
          status: adminUser.status,
          created_at: new Date().toISOString(),
          updated_at: new Date().toISOString()
        }
      ])
      .select();
    
    if (agentError) {
      throw agentError;
    }
    
    console.log('Registro creado en la tabla agents:', agentData);
    console.log('\n¡Usuario administrador creado con éxito!');
    console.log('Email:', adminUser.email);
    console.log('Contraseña:', adminUser.password);
    console.log('\nAhora puedes iniciar sesión en la aplicación con estas credenciales.');
    
  } catch (error) {
    console.error('Error al crear el usuario administrador:', error.message);
    
    // Verificar si el error es porque el usuario ya existe
    if (error.message.includes('already exists')) {
      console.log('\nEl usuario ya existe. Intenta iniciar sesión con:');
      console.log('Email:', adminUser.email);
      console.log('Contraseña:', adminUser.password);
    }
  }
}

// Ejecutar la función
createAdminUser();
