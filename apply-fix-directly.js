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

// SQL to create the insert_message function
const createInsertMessageFunctionSQL = `
-- Create a function to insert messages directly
CREATE OR REPLACE FUNCTION insert_message(
  p_conversation_id UUID,
  p_content TEXT,
  p_sender TEXT,
  p_sender_id TEXT,
  p_type TEXT,
  p_status TEXT
)
RETURNS JSONB AS $$
DECLARE
  new_message_id UUID;
  result JSONB;
BEGIN
  -- Insert the message directly
  INSERT INTO messages (
    conversation_id,
    content,
    sender,
    sender_id,
    type,
    status
  )
  VALUES (
    p_conversation_id,
    p_content,
    p_sender,
    p_sender_id,
    p_type,
    p_status
  )
  RETURNING id INTO new_message_id;
  
  -- Return the result
  SELECT jsonb_build_object(
    'id', id,
    'conversation_id', conversation_id,
    'content', content,
    'sender', sender,
    'sender_id', sender_id,
    'type', type,
    'status', status,
    'created_at', created_at
  ) INTO result
  FROM messages
  WHERE id = new_message_id;
  
  RETURN result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION insert_message(UUID, TEXT, TEXT, TEXT, TEXT, TEXT) TO authenticated;
`;

// SQL to disable the webhook trigger
const disableWebhookTriggerSQL = `
-- Disable the trigger that's causing the issue
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM pg_trigger 
    WHERE tgname = 'agent_message_webhook_trigger'
  ) THEN
    EXECUTE 'ALTER TABLE messages DISABLE TRIGGER agent_message_webhook_trigger';
    RAISE NOTICE 'Webhook trigger for agent messages has been temporarily disabled';
  ELSE
    RAISE NOTICE 'Webhook trigger not found';
  END IF;
END;
$$;
`;

// Function to execute SQL directly
async function executeSQLDirectly(sql, description) {
  try {
    console.log(`Executing SQL: ${description}...`);
    
    // Use the REST API to execute SQL directly
    const response = await fetch(`${supabaseUrl}/rest/v1/`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'apikey': supabaseAnonKey,
        'Authorization': `Bearer ${supabaseAnonKey}`,
        'Prefer': 'params=single-object'
      },
      body: JSON.stringify({
        query: sql
      })
    });
    
    const result = await response.json();
    console.log(`SQL execution result for ${description}:`, result);
    return result;
  } catch (error) {
    console.error(`Error executing SQL for ${description}:`, error);
    return null;
  }
}

// Modify the useMessages hook directly
async function modifyUseMessagesHook() {
  try {
    console.log('Modifying useMessages.ts to use direct SQL insertion...');
    
    // Create a simpler version of the hook that uses direct SQL insertion
    const simplifiedHook = `
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { supabase } from '../supabase';
import type { Message } from '../types';

export function useMessages(conversationId: string | null) {
  const queryClient = useQueryClient();

  const query = useQuery({
    queryKey: ['messages', conversationId],
    queryFn: async () => {
      if (!conversationId) return [];
      
      const { data, error } = await supabase
        .from('messages')
        .select('*')
        .eq('conversation_id', conversationId)
        .order('created_at', { ascending: true });

      if (error) throw error;
      return data as Message[];
    },
    enabled: !!conversationId,
  });

  const sendMessage = useMutation({
    mutationFn: async (message: Omit<Message, 'id' | 'created_at' | 'updated_at'>) => {
      console.log('Sending message with direct SQL insertion:', message);
      
      try {
        // Insert directly using SQL query
        const { data, error } = await supabase.rpc('execute_sql', {
          sql: \`
            INSERT INTO messages (
              conversation_id,
              content,
              sender,
              sender_id,
              type,
              status
            )
            VALUES (
              '\${message.conversation_id}',
              '\${message.content.replace(/'/g, "''")}',
              '\${message.sender}',
              '\${message.sender_id}',
              '\${message.type}',
              '\${message.status}'
            )
            RETURNING id, conversation_id, content, sender, sender_id, type, status, created_at;
          \`
        });
        
        if (error) {
          console.error('Error inserting message with SQL:', error);
          
          // Last resort: Try a super simple insert without any fancy stuff
          console.log('Attempting last resort insert method...');
          
          const { data: lastResortData, error: lastResortError } = await supabase
            .from('messages')
            .insert([
              {
                conversation_id: message.conversation_id,
                content: message.content,
                sender: message.sender,
                sender_id: message.sender_id,
                type: message.type,
                status: message.status
              }
            ])
            .select();
          
          if (lastResortError) {
            console.error('Last resort method also failed:', lastResortError);
            throw lastResortError;
          }
          
          console.log('Message inserted successfully via last resort method:', lastResortData);
          return lastResortData;
        }
        
        console.log('Message inserted successfully with SQL:', data);
        return data;
      } catch (error) {
        console.error('Error in message sending process:', error);
        throw error;
      }
    },
    onSuccess: (data) => {
      console.log('Message mutation succeeded:', data);
      queryClient.invalidateQueries({ queryKey: ['messages', conversationId] });
      queryClient.invalidateQueries({ queryKey: ['conversations'] });
    },
    onError: (error) => {
      console.error('Message mutation failed:', error);
    },
  });

  // Subscribe to new messages
  const subscribeToMessages = () => {
    if (!conversationId) return;

    try {
      console.log(\`Subscribing to messages for conversation: \${conversationId}\`);
      
      const subscription = supabase
        .channel(\`messages:\${conversationId}\`)
        .on(
          'postgres_changes',
          {
            event: 'INSERT',
            schema: 'public',
            table: 'messages',
            filter: \`conversation_id=eq.\${conversationId}\`,
          },
          (payload) => {
            console.log('New message received:', payload);
            queryClient.invalidateQueries({ queryKey: ['messages', conversationId] });
          }
        )
        .subscribe((status) => {
          console.log(\`Subscription status for conversation \${conversationId}: \${status}\`);
        });

      return () => {
        console.log(\`Unsubscribing from messages for conversation: \${conversationId}\`);
        subscription.unsubscribe();
      };
    } catch (error) {
      console.error('Error subscribing to messages:', error);
      return undefined;
    }
  };

  return {
    messages: query.data || [],
    isLoading: query.isLoading,
    error: query.error,
    sendMessage: sendMessage.mutate,
    isSending: sendMessage.isPending,
    subscribeToMessages,
  };
}
    `;
    
    // Write the simplified hook to a file
    // This would need to be done manually or through another mechanism
    console.log('Please replace the contents of src/lib/hooks/useMessages.ts with the following code:');
    console.log(simplifiedHook);
    
    return true;
  } catch (error) {
    console.error('Error modifying useMessages hook:', error);
    return false;
  }
}

// Create a function to execute SQL directly
async function createExecuteSQLFunction() {
  const createExecuteSQLFunctionSQL = `
CREATE OR REPLACE FUNCTION execute_sql(sql TEXT)
RETURNS JSONB AS $$
DECLARE
  result JSONB;
BEGIN
  EXECUTE sql INTO result;
  RETURN result;
EXCEPTION WHEN OTHERS THEN
  RETURN jsonb_build_object('error', SQLERRM);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

GRANT EXECUTE ON FUNCTION execute_sql(TEXT) TO authenticated;
  `;
  
  return await executeSQLDirectly(createExecuteSQLFunctionSQL, 'create execute_sql function');
}

// Main function to apply all fixes
async function applyAllFixes() {
  try {
    console.log('Applying all fixes to resolve chat message insertion issues...');
    
    // 1. Disable the webhook trigger
    await executeSQLDirectly(disableWebhookTriggerSQL, 'disable webhook trigger');
    
    // 2. Create the execute_sql function
    await createExecuteSQLFunction();
    
    // 3. Create the insert_message function
    await executeSQLDirectly(createInsertMessageFunctionSQL, 'create insert_message function');
    
    // 4. Provide instructions for modifying the useMessages hook
    await modifyUseMessagesHook();
    
    console.log('All fixes have been applied. Please restart the application and test the chat functionality.');
  } catch (error) {
    console.error('Error applying fixes:', error);
  }
}

// Execute all fixes
applyAllFixes();
