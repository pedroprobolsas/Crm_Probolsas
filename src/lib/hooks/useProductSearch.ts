import { useState, useCallback, useMemo } from 'react';
import type { ProductPrice } from '../types/product';

export function useProductSearch(products: ProductPrice[]) {
  const [searchTerm, setSearchTerm] = useState('');
  const [selectedCategories, setSelectedCategories] = useState<string[]>([]);

  // Get unique categories from products
  const categories = useMemo(() => {
    const allCategories = products.flatMap(p => p.categories);
    return Array.from(new Set(allCategories)).sort();
  }, [products]);

  // Filter products based on search term and categories
  const filteredProducts = useMemo(() => {
    return products.filter(product => {
      const matchesSearch = !searchTerm || (
        product.name.toLowerCase().includes(searchTerm.toLowerCase()) ||
        product.sku.toLowerCase().includes(searchTerm.toLowerCase()) ||
        product.categories.some(cat => cat.toLowerCase().includes(searchTerm.toLowerCase()))
      );

      const matchesCategories = selectedCategories.length === 0 || 
        selectedCategories.some(cat => product.categories.includes(cat));

      return matchesSearch && matchesCategories;
    });
  }, [products, searchTerm, selectedCategories]);

  const handleSearchChange = useCallback((term: string) => {
    setSearchTerm(term);
  }, []);

  const handleCategoryChange = useCallback((categories: string[]) => {
    setSelectedCategories(categories);
  }, []);

  return {
    searchTerm,
    selectedCategories,
    categories,
    filteredProducts,
    handleSearchChange,
    handleCategoryChange
  };
}