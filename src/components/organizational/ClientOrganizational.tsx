import React, { useState, useEffect } from 'react';
import { Users, Building, UserPlus, Edit2, Trash2, Save, X, AlertTriangle } from 'lucide-react';
import { supabase } from '../../lib/supabase';
import { toast } from 'sonner';

interface Department {
  id: string;
  client_id: string;
  name: string;
  description?: string;
  parent_department_id?: string;
  head_contact_id?: string;
  head_contact_name?: string;
  employee_count?: number;
  created_at: string;
  updated_at: string;
}

interface ClientOrganizationalProps {
  clientId: string;
  isEditing: boolean;
}

export function ClientOrganizational({ clientId, isEditing }: ClientOrganizationalProps) {
  const [departments, setDepartments] = useState<Department[]>([]);
  const [loading, setLoading] = useState(true);
  const [showForm, setShowForm] = useState(false);
  const [formData, setFormData] = useState<Partial<Department>>({
    client_id: clientId,
    name: '',
    description: '',
    parent_department_id: '',
    head_contact_id: '',
    employee_count: undefined
  });
  const [editingDepartmentId, setEditingDepartmentId] = useState<string | null>(null);
  const [errors, setErrors] = useState<Record<string, string>>({});
  const [contacts, setContacts] = useState<{ id: string; name: string }[]>([]);
  const [parentDepartments, setParentDepartments] = useState<{ id: string; name: string }[]>([]);

  useEffect(() => {
    fetchDepartments();
    fetchContacts();
  }, [clientId]);

  const fetchDepartments = async () => {
    try {
      setLoading(true);
      const { data, error } = await supabase
        .from('client_departments')
        .select(`
          *,
          head_contact:client_contacts(name)
        `)
        .eq('client_id', clientId)
        .order('name');

      if (error) throw error;
      
      // Transformar los datos para incluir el nombre del contacto
      const transformedData = data.map(dept => ({
        ...dept,
        head_contact_name: dept.head_contact ? dept.head_contact.name : undefined
      }));
      
      setDepartments(transformedData);
      
      // Preparar lista de departamentos padres
      const parentDeptOptions = transformedData.map(dept => ({
        id: dept.id,
        name: dept.name
      }));
      
      setParentDepartments(parentDeptOptions);
    } catch (error) {
      console.error('Error fetching departments:', error);
      toast.error('Error al cargar los departamentos');
    } finally {
      setLoading(false);
    }
  };

  const fetchContacts = async () => {
    try {
      const { data, error } = await supabase
        .from('client_contacts')
        .select('id, name')
        .eq('client_id', clientId)
        .order('name');

      if (error) throw error;
      setContacts(data || []);
    } catch (error) {
      console.error('Error fetching contacts:', error);
      toast.error('Error al cargar los contactos');
    }
  };

  const validateForm = () => {
    const newErrors: Record<string, string> = {};
    
    if (!formData.name?.trim()) {
      newErrors.name = 'El nombre del departamento es requerido';
    }
    
    if (formData.employee_count !== undefined && formData.employee_count < 0) {
      newErrors.employee_count = 'El número de empleados no puede ser negativo';
    }
    
    setErrors(newErrors);
    return Object.keys(newErrors).length === 0;
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    
    if (!validateForm()) return;
    
    try {
      if (editingDepartmentId) {
        // Actualizar departamento existente
        const { error } = await supabase
          .from('client_departments')
          .update({
            name: formData.name,
            description: formData.description,
            parent_department_id: formData.parent_department_id || null,
            head_contact_id: formData.head_contact_id || null,
            employee_count: formData.employee_count,
            updated_at: new Date().toISOString()
          })
          .eq('id', editingDepartmentId);

        if (error) throw error;
        toast.success('Departamento actualizado exitosamente');
      } else {
        // Crear nuevo departamento
        const { error } = await supabase
          .from('client_departments')
          .insert({
            client_id: clientId,
            name: formData.name,
            description: formData.description,
            parent_department_id: formData.parent_department_id || null,
            head_contact_id: formData.head_contact_id || null,
            employee_count: formData.employee_count
          });

        if (error) throw error;
        toast.success('Departamento creado exitosamente');
      }
      
      resetForm();
      fetchDepartments();
    } catch (error) {
      console.error('Error saving department:', error);
      toast.error('Error al guardar el departamento');
    }
  };

  const handleEdit = (department: Department) => {
    setFormData({
      client_id: department.client_id,
      name: department.name,
      description: department.description || '',
      parent_department_id: department.parent_department_id || '',
      head_contact_id: department.head_contact_id || '',
      employee_count: department.employee_count
    });
    setEditingDepartmentId(department.id);
    setShowForm(true);
  };

  const handleDelete = async (departmentId: string) => {
    if (!window.confirm('¿Está seguro de eliminar este departamento?')) return;
    
    try {
      // Verificar si hay departamentos hijos
      const { data: childDepts, error: checkError } = await supabase
        .from('client_departments')
        .select('id')
        .eq('parent_department_id', departmentId);
      
      if (checkError) throw checkError;
      
      if (childDepts && childDepts.length > 0) {
        toast.error('No se puede eliminar un departamento con subdepartamentos');
        return;
      }
      
      const { error } = await supabase
        .from('client_departments')
        .delete()
        .eq('id', departmentId);

      if (error) throw error;
      
      toast.success('Departamento eliminado exitosamente');
      fetchDepartments();
    } catch (error) {
      console.error('Error deleting department:', error);
      toast.error('Error al eliminar el departamento');
    }
  };

  const resetForm = () => {
    setFormData({
      client_id: clientId,
      name: '',
      description: '',
      parent_department_id: '',
      head_contact_id: '',
      employee_count: undefined
    });
    setEditingDepartmentId(null);
    setShowForm(false);
    setErrors({});
  };

  // Función para construir la jerarquía de departamentos
  const buildDepartmentHierarchy = () => {
    // Crear un mapa de departamentos por ID
    const deptMap = new Map<string, Department & { children: (Department & { children: any[] })[] }>();
    
    // Inicializar el mapa con todos los departamentos
    departments.forEach(dept => {
      deptMap.set(dept.id, { ...dept, children: [] });
    });
    
    // Departamentos de nivel superior
    const rootDepartments: (Department & { children: any[] })[] = [];
    
    // Construir la jerarquía
    departments.forEach(dept => {
      const deptWithChildren = deptMap.get(dept.id);
      if (deptWithChildren) {
        if (dept.parent_department_id && deptMap.has(dept.parent_department_id)) {
          // Añadir como hijo al departamento padre
          const parent = deptMap.get(dept.parent_department_id);
          if (parent) {
            parent.children.push(deptWithChildren);
          }
        } else {
          // Es un departamento de nivel superior
          rootDepartments.push(deptWithChildren);
        }
      }
    });
    
    return rootDepartments;
  };

  // Renderizar un departamento y sus hijos
  const renderDepartment = (dept: Department & { children: any[] }, level = 0) => {
    const paddingLeft = level * 20; // Indentación basada en el nivel
    
    return (
      <React.Fragment key={dept.id}>
        <li className="border-b border-gray-200 last:border-b-0">
          <div 
            className="p-4 sm:px-6 flex items-center justify-between"
            style={{ paddingLeft: `${paddingLeft + 16}px` }}
          >
            <div className="flex items-center">
              <div className="flex-shrink-0">
                <Building className="h-6 w-6 text-blue-500" />
              </div>
              <div className="ml-4">
                <h4 className="text-sm font-medium text-gray-900">{dept.name}</h4>
                {dept.description && (
                  <p className="text-sm text-gray-500">{dept.description}</p>
                )}
                <div className="mt-1 flex flex-wrap items-center text-xs text-gray-500">
                  {dept.head_contact_name && (
                    <span className="flex items-center mr-3">
                      <Users className="w-3 h-3 mr-1" />
                      Responsable: {dept.head_contact_name}
                    </span>
                  )}
                  {dept.employee_count !== undefined && dept.employee_count > 0 && (
                    <span className="flex items-center">
                      <UserPlus className="w-3 h-3 mr-1" />
                      {dept.employee_count} empleados
                    </span>
                  )}
                </div>
              </div>
            </div>
            {isEditing && (
              <div className="flex space-x-2">
                <button
                  onClick={() => handleEdit(dept)}
                  className="text-blue-600 hover:text-blue-900"
                  title="Editar departamento"
                >
                  <Edit2 className="h-5 w-5" />
                </button>
                <button
                  onClick={() => handleDelete(dept.id)}
                  className="text-red-600 hover:text-red-900"
                  title="Eliminar departamento"
                >
                  <Trash2 className="h-5 w-5" />
                </button>
              </div>
            )}
          </div>
        </li>
        {/* Renderizar departamentos hijos */}
        {dept.children.length > 0 && (
          <ul>
            {dept.children.map(child => renderDepartment(child, level + 1))}
          </ul>
        )}
      </React.Fragment>
    );
  };

  if (loading) {
    return (
      <div className="flex justify-center py-8">
        <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600"></div>
      </div>
    );
  }

  const departmentHierarchy = buildDepartmentHierarchy();

  return (
    <div className="space-y-6">
      <div className="bg-white shadow rounded-lg overflow-hidden">
        <div className="p-4 sm:px-6 border-b border-gray-200 flex justify-between items-center">
          <h3 className="text-lg font-medium text-gray-900">Estructura Organizacional</h3>
          {isEditing && (
            <button
              onClick={() => setShowForm(true)}
              className="inline-flex items-center px-3 py-1.5 border border-transparent text-sm font-medium rounded-md shadow-sm text-white bg-blue-600 hover:bg-blue-700"
            >
              <Building className="w-4 h-4 mr-1" />
              Nuevo Departamento
            </button>
          )}
        </div>

        {departments.length === 0 ? (
          <div className="p-6 text-center">
            <Building className="mx-auto h-12 w-12 text-gray-400" />
            <h3 className="mt-2 text-sm font-medium text-gray-900">No hay departamentos</h3>
            <p className="mt-1 text-sm text-gray-500">
              Comience agregando departamentos para este cliente.
            </p>
            {isEditing && (
              <div className="mt-6">
                <button
                  onClick={() => setShowForm(true)}
                  className="inline-flex items-center px-4 py-2 border border-transparent shadow-sm text-sm font-medium rounded-md text-white bg-blue-600 hover:bg-blue-700"
                >
                  <Building className="w-5 h-5 mr-2" />
                  Agregar Departamento
                </button>
              </div>
            )}
          </div>
        ) : (
          <ul className="divide-y divide-gray-200">
            {departmentHierarchy.map(dept => renderDepartment(dept))}
          </ul>
        )}
      </div>

      {/* Formulario de departamento */}
      {showForm && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
          <div className="bg-white rounded-lg w-full max-w-md p-6">
            <div className="flex justify-between items-center mb-4">
              <h2 className="text-xl font-semibold text-gray-900">
                {editingDepartmentId ? 'Editar Departamento' : 'Nuevo Departamento'}
              </h2>
              <button
                onClick={resetForm}
                className="text-gray-400 hover:text-gray-500"
              >
                <X className="w-6 h-6" />
              </button>
            </div>

            <form onSubmit={handleSubmit} className="space-y-4">
              <div>
                <label htmlFor="name" className="block text-sm font-medium text-gray-700">
                  Nombre del Departamento <span className="text-red-500">*</span>
                </label>
                <input
                  type="text"
                  id="name"
                  value={formData.name}
                  onChange={(e) => setFormData({ ...formData, name: e.target.value })}
                  className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
                />
                {errors.name && (
                  <p className="mt-1 text-sm text-red-600 flex items-center">
                    <AlertTriangle className="w-4 h-4 mr-1" />
                    {errors.name}
                  </p>
                )}
              </div>

              <div>
                <label htmlFor="description" className="block text-sm font-medium text-gray-700">
                  Descripción
                </label>
                <textarea
                  id="description"
                  rows={2}
                  value={formData.description || ''}
                  onChange={(e) => setFormData({ ...formData, description: e.target.value })}
                  className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
                />
              </div>

              <div>
                <label htmlFor="parent_department_id" className="block text-sm font-medium text-gray-700">
                  Departamento Superior
                </label>
                <select
                  id="parent_department_id"
                  value={formData.parent_department_id || ''}
                  onChange={(e) => setFormData({ ...formData, parent_department_id: e.target.value || undefined })}
                  className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
                >
                  <option value="">Ninguno (Nivel Superior)</option>
                  {parentDepartments
                    .filter(dept => dept.id !== editingDepartmentId) // Evitar selección circular
                    .map(dept => (
                      <option key={dept.id} value={dept.id}>{dept.name}</option>
                    ))
                  }
                </select>
              </div>

              <div>
                <label htmlFor="head_contact_id" className="block text-sm font-medium text-gray-700">
                  Responsable del Departamento
                </label>
                <select
                  id="head_contact_id"
                  value={formData.head_contact_id || ''}
                  onChange={(e) => setFormData({ ...formData, head_contact_id: e.target.value || undefined })}
                  className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
                >
                  <option value="">Seleccionar responsable</option>
                  {contacts.map(contact => (
                    <option key={contact.id} value={contact.id}>{contact.name}</option>
                  ))}
                </select>
              </div>

              <div>
                <label htmlFor="employee_count" className="block text-sm font-medium text-gray-700">
                  Número de Empleados
                </label>
                <input
                  type="number"
                  id="employee_count"
                  min="0"
                  value={formData.employee_count || ''}
                  onChange={(e) => setFormData({ ...formData, employee_count: parseInt(e.target.value) || undefined })}
                  className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
                />
                {errors.employee_count && (
                  <p className="mt-1 text-sm text-red-600 flex items-center">
                    <AlertTriangle className="w-4 h-4 mr-1" />
                    {errors.employee_count}
                  </p>
                )}
              </div>

              <div className="flex justify-end space-x-3 pt-4">
                <button
                  type="button"
                  onClick={resetForm}
                  className="px-4 py-2 border border-gray-300 rounded-md text-sm font-medium text-gray-700 hover:bg-gray-50"
                >
                  Cancelar
                </button>
                <button
                  type="submit"
                  className="px-4 py-2 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-blue-600 hover:bg-blue-700"
                >
                  <Save className="w-4 h-4 mr-1 inline" />
                  {editingDepartmentId ? 'Actualizar' : 'Guardar'}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
}
