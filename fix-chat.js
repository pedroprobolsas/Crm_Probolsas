import { createClient } from '@supabase/supabase-js';
import dotenv from 'dotenv';

// Load environment variables
dotenv.config();

const supabaseUrl = process.env.VITE_SUPABASE_URL;
const supabaseAnonKey = process.env.VITE_SUPABASE_ANON_KEY;

if (!supabaseUrl || !supabaseAnonKey) {
  console.error('Missing Supabase environment variables');
  process.exit(1);
}

// Create Supabase client
const supabase = createClient(supabaseUrl, supabaseAnonKey, {
  auth: {
    autoRefreshToken: true,
    persistSession: true
  }
});

async function fixChatIssue() {
  try {
    console.log('Attempting to fix chat issue by disabling webhook trigger...');
    
    // Call the function to disable the webhook trigger
    const { data, error } = await supabase.rpc('disable_webhook_trigger');
    
    if (error) {
      console.error('Error disabling webhook trigger:', error);
      return;
    }
    
    console.log('Result:', data);
    console.log('Chat issue should be fixed. Please try sending a message again.');
    
    // Test inserting a message directly
    console.log('Testing message insertion...');
    
    // Get a conversation ID to use for testing
    const { data: conversations, error: convError } = await supabase
      .from('conversations')
      .select('id')
      .limit(1);
    
    if (convError || !conversations || conversations.length === 0) {
      console.error('Error getting conversation for testing:', convError);
      return;
    }
    
    const testConversationId = conversations[0].id;
    
    // Insert a test message
    const { data: messageData, error: messageError } = await supabase
      .from('messages')
      .insert({
        conversation_id: testConversationId,
        content: 'Test message after fixing webhook trigger',
        sender: 'agent',
        sender_id: 'system',
        type: 'text',
        status: 'sent'
      })
      .select();
    
    if (messageError) {
      console.error('Error inserting test message:', messageError);
      console.log('The issue may not be fully resolved.');
    } else {
      console.log('Test message inserted successfully:', messageData);
      console.log('The chat functionality should now be working correctly.');
    }
    
  } catch (err) {
    console.error('Unexpected error:', err);
  }
}

// Execute the fix
fixChatIssue();
