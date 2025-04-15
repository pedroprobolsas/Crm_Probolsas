import { createClient } from '@supabase/supabase-js';

// Definir directamente las variables de Supabase
const supabaseUrl = 'https://egiyffxvnknfehlfnovf.supabase.co';
const supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImVnaXlmZnh2bmtuZmVobGZub3ZmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzkzODg4OTAsImV4cCI6MjA1NDk2NDg5MH0.qW2THTMrJ7k8mKnQd24g8paHcAe6SQy0SQRp_pLEfbs';

// Crear cliente de Supabase
const supabase = createClient(supabaseUrl, supabaseAnonKey);

// Credenciales del usuario administrador
const adminUser = {
  email: 'admin@probolsas.com',
  password: 'admin123'
};

async function testLogin() {
  try {
    console.log('Probando inicio de sesión con credenciales de administrador...');
    
    // Intentar iniciar sesión
    const { data, error } = await supabase.auth.signInWithPassword({
      email: adminUser.email,
      password: adminUser.password
    });
    
    if (error) {
      throw error;
    }
    
    console.log('Inicio de sesión exitoso!');
    console.log('Usuario:', data.user);
    console.log('Sesión:', data.session);
    
    // Obtener el perfil del agente
    const { data: agentData, error: agentError } = await supabase
      .from('agents')
      .select('*')
      .eq('email', adminUser.email)
      .single();
    
    if (agentError) {
      throw agentError;
    }
    
    console.log('Perfil del agente:', agentData);
    
  } catch (error) {
    console.error('Error al iniciar sesión:', error.message);
  }
}

// Ejecutar la función
testLogin();
