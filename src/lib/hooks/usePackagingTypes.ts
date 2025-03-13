import { useQuery } from '@tanstack/react-query';
import { supabase } from '../supabase';

export interface PackagingType {
  id: string;
  code: string;
  name: string;
  description: string;
  typical_features: {
    name: string;
    options: string[];
  }[];
  common_uses: string[];
}

export function usePackagingTypes() {
  const query = useQuery({
    queryKey: ['packaging-types'],
    queryFn: async () => {
      const { data, error } = await supabase
        .from('packaging_types')
        .select('*')
        .order('name');

      if (error) throw error;
      return data as PackagingType[];
    },
  });

  return {
    packagingTypes: query.data ?? [],
    isLoading: query.isLoading,
    error: query.error,
  };
}