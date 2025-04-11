import { createClient } from '@supabase/supabase-js';
import dotenv from 'dotenv';

// Load environment variables
dotenv.config();

const supabaseUrl = process.env.VITE_SUPABASE_URL;
const supabaseServiceKey = process.env.VITE_SUPABASE_SERVICE_ROLE_KEY || process.env.VITE_SUPABASE_ANON_KEY;

if (!supabaseUrl || !supabaseServiceKey) {
  console.error('Missing Supabase environment variables');
  process.exit(1);
}

// Create Supabase client with admin privileges
const supabase = createClient(supabaseUrl, supabaseServiceKey, {
  auth: {
    autoRefreshToken: false,
    persistSession: false
  }
});

async function applyMigration() {
  try {
    // SQL to disable the trigger
    const { data, error } = await supabase.rpc('disable_webhook_trigger');
    
    if (error) {
      console.error('Error applying migration:', error);
      
      // Try alternative approach if RPC fails
      console.log('Trying direct SQL execution...');
      const { error: sqlError } = await supabase.from('_sqlquery').rpc('execute', {
        query: `
          ALTER TABLE messages DISABLE TRIGGER agent_message_webhook_trigger;
          DO $$
          BEGIN
            RAISE NOTICE 'Webhook trigger for agent messages has been temporarily disabled';
          END;
          $$;
        `
      });
      
      if (sqlError) {
        console.error('Error executing direct SQL:', sqlError);
      } else {
        console.log('Migration applied successfully via direct SQL');
      }
    } else {
      console.log('Migration applied successfully:', data);
    }
  } catch (err) {
    console.error('Unexpected error:', err);
  }
}

// Execute the migration
applyMigration();
