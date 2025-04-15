import { createClient } from '@supabase/supabase-js';

// Definir directamente las variables de Supabase
const supabaseUrl = 'https://egiyffxvnknfehlfnovf.supabase.co';
const supabaseServiceKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImVnaXlmZnh2bmtuZmVobGZub3ZmIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTczOTM4ODg5MCwiZXhwIjoyMDU0OTY0ODkwfQ.AtQnAMcszWn2LEn-Em2lI6dnrdEZ8a4urtRpXgR9Yl8';

// Crear cliente de Supabase con la clave de servicio
const supabase = createClient(supabaseUrl, supabaseServiceKey);

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
    console.log('Creando usuario administrador con clave de servicio...');
    
    // 1. Crear usuario con la API de administración (usando service_role)
    console.log('Paso 1: Creando usuario en autenticación...');
    const { data: userData, error: userError } = await supabase.auth.admin.createUser({
      email: adminUser.email,
      password: adminUser.password,
      email_confirm: true, // Confirmar automáticamente el correo electrónico
      user_metadata: {
        name: adminUser.name,
        role: adminUser.role
      }
    });
    
    if (userError) {
      throw userError;
    }
    
    console.log('Usuario creado en autenticación:', userData.user.id);
    
    // 2. Crear el registro en la tabla agents
    console.log('Paso 2: Creando registro en la tabla agents...');
    const { data: agentData, error: agentError } = await supabase
      .from('agents')
      .upsert([
        {
          id: userData.user.id,
          email: adminUser.email,
          name: adminUser.name,
          role: adminUser.role,
          status: adminUser.status,
          created_at: new Date().toISOString(),
          updated_at: new Date().toISOString()
        }
      ], { onConflict: 'id' })
      .select();
    
    if (agentError) {
      throw agentError;
    }
    
    console.log('Registro creado/actualizado en la tabla agents:', agentData);
    console.log('\n¡Usuario administrador creado con éxito!');
    console.log('Email:', adminUser.email);
    console.log('Contraseña:', adminUser.password);
    console.log('\nAhora puedes iniciar sesión en la aplicación con estas credenciales.');
    
  } catch (error) {
    console.error('Error al crear el usuario administrador:', error.message);
    
    // Verificar si el error es porque el usuario ya existe
    if (error.message.includes('already been registered')) {
      console.log('\nEl usuario ya existe. Intentando actualizar...');
      
      // Intentar actualizar el usuario existente
      try {
        // Buscar el usuario por email
        const { data: { users }, error: findError } = await supabase.auth.admin.listUsers();
        
        if (findError) throw findError;
        
        const existingUser = users.find(u => u.email === adminUser.email);
        
        if (existingUser) {
          console.log('Usuario encontrado, actualizando...');
          
          // Actualizar la contraseña del usuario
          const { error: updateError } = await supabase.auth.admin.updateUserById(
            existingUser.id,
            { password: adminUser.password, email_confirm: true }
          );
          
          if (updateError) throw updateError;
          
          console.log('Usuario actualizado correctamente.');
          console.log('Email:', adminUser.email);
          console.log('Contraseña:', adminUser.password);
          console.log('\nAhora puedes iniciar sesión en la aplicación con estas credenciales.');
        }
      } catch (updateError) {
        console.error('Error al actualizar el usuario:', updateError.message);
      }
    }
  }
}

// Ejecutar la función
createAdminUser();
