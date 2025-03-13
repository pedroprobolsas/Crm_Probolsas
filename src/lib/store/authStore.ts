import { create } from 'zustand';
import { supabase } from '../supabase';
import type { User } from '@supabase/supabase-js';

interface UserProfile {
  id: string;
  role: 'admin' | 'agent';
  name: string;
  email: string;
  status: 'online' | 'busy' | 'offline' | 'inactive';
}

interface AuthState {
  user: User | null;
  profile: UserProfile | null;
  isLoading: boolean;
  signIn: (email: string, password: string) => Promise<void>;
  signOut: () => Promise<void>;
  checkAuth: () => Promise<void>;
  isAdmin: () => boolean;
}

export const useAuthStore = create<AuthState>((set, get) => ({
  user: null,
  profile: null,
  isLoading: true,
  signIn: async (email: string, password: string) => {
    const { error } = await supabase.auth.signInWithPassword({
      email,
      password,
    });
    if (error) throw error;

    // Fetch agent profile after successful login
    const { data: profile, error: profileError } = await supabase
      .from('agents')
      .select('*')
      .eq('email', email)
      .single();

    if (profileError) throw profileError;

    set({ 
      profile: {
        id: profile.id,
        role: profile.role,
        name: profile.name,
        email: profile.email,
        status: profile.status
      }
    });
  },
  signOut: async () => {
    const { error } = await supabase.auth.signOut();
    if (error) throw error;
    set({ user: null, profile: null });
  },
  checkAuth: async () => {
    try {
      const { data: { user } } = await supabase.auth.getUser();
      
      if (user) {
        // Fetch agent profile
        const { data: profile, error: profileError } = await supabase
          .from('agents')
          .select('*')
          .eq('email', user.email)
          .single();

        if (profileError) throw profileError;

        set({ 
          user,
          profile: {
            id: profile.id,
            role: profile.role,
            name: profile.name,
            email: profile.email,
            status: profile.status
          }
        });
      }
      
      set({ isLoading: false });
    } catch (error) {
      set({ user: null, profile: null, isLoading: false });
    }
  },
  isAdmin: () => {
    const { profile } = get();
    return profile?.role === 'admin';
  }
}));