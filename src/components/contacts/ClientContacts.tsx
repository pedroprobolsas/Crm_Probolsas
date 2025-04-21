import React, { useState, useEffect } from 'react';
import { Plus, Edit2, Trash2, Mail, Phone, User, X, Save, AlertTriangle } from 'lucide-react';
import { supabase } from '../../lib/supabase';
import { toast } from 'sonner';

interface Contact {
  id: string;
  client_id: string;
  name: string;
  position?: string;
  email?: string;
  phone?: string;
  is_primary: boolean;
  notes?: string;
  created_at: string;
  updated_at: string;
}

interface ContactFormData {
  id?: string;
  client_id: string;
  name: string;
  position: string;
  email: string;
  phone: string;
  is_primary: boolean;
  notes: string;
}

interface ClientContactsProps {
  clientId: string;
  isEditing: boolean;
}

export function ClientContacts({ clientId, isEditing }: ClientContactsProps) {
  const [contacts, setContacts] = useState<Contact[]>([]);
  const [loading, setLoading] = useState(true);
  const [showForm, setShowForm] = useState(false);
  const [formData, setFormData] = useState<ContactFormData>({
    client_id: clientId,
    name: '',
    position: '',
    email: '',
    phone: '',
    is_primary: false,
    notes: ''
  });
  const [editingContactId, setEditingContactId] = useState<string | null>(null);
  const [errors, setErrors] = useState<Record<string, string>>({});

  useEffect(() => {
    fetchContacts();
  }, [clientId]);

  const fetchContacts = async () => {
    try {
      setLoading(true);
      const { data, error } = await supabase
        .from('client_contacts')
        .select('*')
        .eq('client_id', clientId)
        .order('is_primary', { ascending: false })
        .order('name');

      if (error) throw error;
      setContacts(data || []);
    } catch (error) {
      console.error('Error fetching contacts:', error);
      toast.error('Error al cargar los contactos');
    } finally {
      setLoading(false);
    }
  };

  const validateForm = () => {
    const newErrors: Record<string, string> = {};
    
    if (!formData.name.trim()) {
      newErrors.name = 'El nombre es requerido';
    }
    
    if (formData.email && !/^\S+@\S+\.\S+$/.test(formData.email)) {
      newErrors.email = 'Email inválido';
    }
    
    setErrors(newErrors);
    return Object.keys(newErrors).length === 0;
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    
    if (!validateForm()) return;
    
    try {
      if (editingContactId) {
        // Actualizar contacto existente
        const { error } = await supabase
          .from('client_contacts')
          .update({
            name: formData.name,
            position: formData.position,
            email: formData.email,
            phone: formData.phone,
            is_primary: formData.is_primary,
            notes: formData.notes,
            updated_at: new Date().toISOString()
          })
          .eq('id', editingContactId);

        if (error) throw error;
        toast.success('Contacto actualizado exitosamente');
      } else {
        // Crear nuevo contacto
        const { error } = await supabase
          .from('client_contacts')
          .insert({
            client_id: clientId,
            name: formData.name,
            position: formData.position,
            email: formData.email,
            phone: formData.phone,
            is_primary: formData.is_primary,
            notes: formData.notes
          });

        if (error) throw error;
        toast.success('Contacto creado exitosamente');
      }
      
      // Resetear formulario y recargar contactos
      resetForm();
      fetchContacts();
    } catch (error) {
      console.error('Error saving contact:', error);
      toast.error('Error al guardar el contacto');
    }
  };

  const handleEdit = (contact: Contact) => {
    setFormData({
      client_id: contact.client_id,
      name: contact.name,
      position: contact.position || '',
      email: contact.email || '',
      phone: contact.phone || '',
      is_primary: contact.is_primary,
      notes: contact.notes || ''
    });
    setEditingContactId(contact.id);
    setShowForm(true);
  };

  const handleDelete = async (contactId: string) => {
    if (!window.confirm('¿Está seguro de eliminar este contacto?')) return;
    
    try {
      const { error } = await supabase
        .from('client_contacts')
        .delete()
        .eq('id', contactId);

      if (error) throw error;
      
      toast.success('Contacto eliminado exitosamente');
      fetchContacts();
    } catch (error) {
      console.error('Error deleting contact:', error);
      toast.error('Error al eliminar el contacto');
    }
  };

  const resetForm = () => {
    setFormData({
      client_id: clientId,
      name: '',
      position: '',
      email: '',
      phone: '',
      is_primary: false,
      notes: ''
    });
    setEditingContactId(null);
    setShowForm(false);
    setErrors({});
  };

  if (loading) {
    return (
      <div className="flex justify-center py-8">
        <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600"></div>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      <div className="bg-white shadow rounded-lg overflow-hidden">
        <div className="p-4 sm:px-6 border-b border-gray-200 flex justify-between items-center">
          <h3 className="text-lg font-medium text-gray-900">Contactos</h3>
          {isEditing && (
            <button
              onClick={() => setShowForm(true)}
              className="inline-flex items-center px-3 py-1.5 border border-transparent text-sm font-medium rounded-md shadow-sm text-white bg-blue-600 hover:bg-blue-700"
            >
              <Plus className="w-4 h-4 mr-1" />
              Nuevo Contacto
            </button>
          )}
        </div>

        {contacts.length === 0 ? (
          <div className="p-6 text-center">
            <User className="mx-auto h-12 w-12 text-gray-400" />
            <h3 className="mt-2 text-sm font-medium text-gray-900">No hay contactos</h3>
            <p className="mt-1 text-sm text-gray-500">
              Comience agregando un contacto para este cliente.
            </p>
            {isEditing && (
              <div className="mt-6">
                <button
                  onClick={() => setShowForm(true)}
                  className="inline-flex items-center px-4 py-2 border border-transparent shadow-sm text-sm font-medium rounded-md text-white bg-blue-600 hover:bg-blue-700"
                >
                  <Plus className="w-5 h-5 mr-2" />
                  Agregar Contacto
                </button>
              </div>
            )}
          </div>
        ) : (
          <ul className="divide-y divide-gray-200">
            {contacts.map((contact) => (
              <li key={contact.id} className="p-4 sm:px-6">
                <div className="flex items-center justify-between">
                  <div className="flex items-center">
                    <div className="flex-shrink-0">
                      <div className="h-10 w-10 rounded-full bg-gray-200 flex items-center justify-center">
                        <User className="h-6 w-6 text-gray-500" />
                      </div>
                    </div>
                    <div className="ml-4">
                      <div className="flex items-center">
                        <h4 className="text-sm font-medium text-gray-900">{contact.name}</h4>
                        {contact.is_primary && (
                          <span className="ml-2 inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-blue-100 text-blue-800">
                            Principal
                          </span>
                        )}
                      </div>
                      {contact.position && (
                        <p className="text-sm text-gray-500">{contact.position}</p>
                      )}
                      <div className="mt-2 flex items-center text-sm text-gray-500">
                        {contact.email && (
                          <a 
                            href={`mailto:${contact.email}`} 
                            className="flex items-center mr-4 hover:text-blue-600"
                          >
                            <Mail className="h-4 w-4 mr-1" />
                            {contact.email}
                          </a>
                        )}
                        {contact.phone && (
                          <a 
                            href={`tel:${contact.phone}`} 
                            className="flex items-center hover:text-blue-600"
                          >
                            <Phone className="h-4 w-4 mr-1" />
                            {contact.phone}
                          </a>
                        )}
                      </div>
                      {contact.notes && (
                        <p className="mt-1 text-sm text-gray-500">{contact.notes}</p>
                      )}
                    </div>
                  </div>
                  {isEditing && (
                    <div className="flex space-x-2">
                      <button
                        onClick={() => handleEdit(contact)}
                        className="text-blue-600 hover:text-blue-900"
                      >
                        <Edit2 className="h-5 w-5" />
                      </button>
                      <button
                        onClick={() => handleDelete(contact.id)}
                        className="text-red-600 hover:text-red-900"
                      >
                        <Trash2 className="h-5 w-5" />
                      </button>
                    </div>
                  )}
                </div>
              </li>
            ))}
          </ul>
        )}
      </div>

      {/* Formulario de contacto */}
      {showForm && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
          <div className="bg-white rounded-lg w-full max-w-md p-6">
            <div className="flex justify-between items-center mb-4">
              <h2 className="text-xl font-semibold text-gray-900">
                {editingContactId ? 'Editar Contacto' : 'Nuevo Contacto'}
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
                  Nombre <span className="text-red-500">*</span>
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
                <label htmlFor="position" className="block text-sm font-medium text-gray-700">
                  Cargo
                </label>
                <input
                  type="text"
                  id="position"
                  value={formData.position}
                  onChange={(e) => setFormData({ ...formData, position: e.target.value })}
                  className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
                />
              </div>

              <div>
                <label htmlFor="email" className="block text-sm font-medium text-gray-700">
                  Email
                </label>
                <input
                  type="email"
                  id="email"
                  value={formData.email}
                  onChange={(e) => setFormData({ ...formData, email: e.target.value })}
                  className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
                />
                {errors.email && (
                  <p className="mt-1 text-sm text-red-600 flex items-center">
                    <AlertTriangle className="w-4 h-4 mr-1" />
                    {errors.email}
                  </p>
                )}
              </div>

              <div>
                <label htmlFor="phone" className="block text-sm font-medium text-gray-700">
                  Teléfono
                </label>
                <input
                  type="tel"
                  id="phone"
                  value={formData.phone}
                  onChange={(e) => setFormData({ ...formData, phone: e.target.value })}
                  className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
                />
              </div>

              <div className="flex items-center">
                <input
                  type="checkbox"
                  id="is_primary"
                  checked={formData.is_primary}
                  onChange={(e) => setFormData({ ...formData, is_primary: e.target.checked })}
                  className="h-4 w-4 text-blue-600 focus:ring-blue-500 border-gray-300 rounded"
                />
                <label htmlFor="is_primary" className="ml-2 block text-sm text-gray-900">
                  Contacto Principal
                </label>
              </div>

              <div>
                <label htmlFor="notes" className="block text-sm font-medium text-gray-700">
                  Notas
                </label>
                <textarea
                  id="notes"
                  rows={3}
                  value={formData.notes}
                  onChange={(e) => setFormData({ ...formData, notes: e.target.value })}
                  className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
                />
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
                  {editingContactId ? 'Actualizar' : 'Guardar'}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
}
