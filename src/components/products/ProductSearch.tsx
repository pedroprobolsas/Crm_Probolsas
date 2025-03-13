import React from 'react';
import { Search, Filter } from 'lucide-react';

interface ProductSearchProps {
  searchTerm: string;
  onSearchChange: (term: string) => void;
  selectedCategories: string[];
  onCategoryChange: (categories: string[]) => void;
  categories: string[];
  isLoading?: boolean;
}

export function ProductSearch({
  searchTerm,
  onSearchChange,
  selectedCategories,
  onCategoryChange,
  categories,
  isLoading
}: ProductSearchProps) {
  return (
    <div className="flex flex-col sm:flex-row gap-4 mb-6">
      <div className="flex-1 relative">
        <input
          type="text"
          placeholder="Buscar por nombre, SKU o categoría..."
          value={searchTerm}
          onChange={(e) => onSearchChange(e.target.value)}
          className="w-full pl-10 pr-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
          disabled={isLoading}
        />
        <Search className="w-5 h-5 text-gray-400 absolute left-3 top-2.5" />
      </div>
      
      <div className="flex items-center space-x-2">
        <Filter className="w-5 h-5 text-gray-400" />
        <select
          multiple
          value={selectedCategories}
          onChange={(e) => {
            const selected = Array.from(e.target.selectedOptions, option => option.value);
            onCategoryChange(selected);
          }}
          className="px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
          disabled={isLoading}
        >
          {categories.map(category => (
            <option key={category} value={category}>{category}</option>
          ))}
        </select>
      </div>
    </div>
  );
}