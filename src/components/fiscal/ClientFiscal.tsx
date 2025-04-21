import React, { useState, useEffect } from 'react';
import { FileText, Upload, Download, Trash2, AlertTriangle, Save, X } from 'lucide-react';
import { supabase } from '../../lib/supabase';
import { toast } from 'sonner';

interface FiscalData {
  id: string;
  client_id: string;
  tax_id: string;
  tax_regime: string;
  fiscal_address: string;
  legal_representative: string;
  incorporation_date?: string;
  tax_status: 'active' | 'inactive' | 'pending';
  created_at: string;
  updated_at: string;
}

interface FiscalDocument {
  id: string;
  client_id: string;
  fiscal_id: string;
  name: string;
  file_url: string;
  file_type: string;
  file_size: number;
  expiration_date?: string;
  document_type: 'tax_id' | 'incorporation' | 'power_of_attorney' | 'other';
  notes?: string;
  created_at: string;
  updated_at: string;
}

interface ClientFiscalProps {
  clientId: string;
  isEditing: boolean;
}

export function ClientFiscal({ clientId, isEditing }: ClientFiscalProps) {
  const [fiscalData, setFiscalData] = useState<FiscalData | null>(null);
  const [documents, setDocuments] = useState<FiscalDocument[]>([]);
  const [loading, setLoading] = useState(true);
  const [formData, setFormData] = useState<Partial<FiscalData>>({
    client_id: clientId,
    tax_id: '',
    tax_regime: '',
    fiscal_address: '',
    legal_representative: '',
    tax_status: 'active'
  });
  const [errors, setErrors] = useState<Record<string, string>>({});
  const [uploading, setUploading] = useState(false);
  const [showDocumentForm, setShowDocumentForm] = useState(false);
  const [documentFormData, setDocumentFormData] = useState({
    name: '',
    document_type: 'tax_id',
    expiration_date: '',
    notes: ''
  });
  const [selectedFile, setSelectedFile] = useState<File | null>(null);

  useEffect(() => {
    fetchFiscalData();
    fetchDocuments();
  }, [clientId]);

  const fetchFiscalData = async () => {
    try {
      setLoading(true);
      const { data, error } = await supabase
        .from('client_fiscal')
        .select('*')
        .eq('client_id', clientId)
        .single();

      if (error && error.code !== 'PGRST116') {
        // PGRST116 es el código para "no se encontraron resultados"
        throw error;
      }

      if (data) {
        setFiscalData(data);
        setFormData({
          client_id: data.client_id,
          tax_id: data.tax_id,
          tax_regime: data.tax_regime,
          fiscal_address: data.fiscal_address,
          legal_representative: data.legal_representative,
          incorporation_date: data.incorporation_date,
          tax_status: data.tax_status
        });
      }
    } catch (error) {
      console.error('Error fetching fiscal data:', error);
      toast.error('Error al cargar los datos fiscales');
    } finally {
      setLoading(false);
    }
  };

  const fetchDocuments = async () => {
    try {
      const { data, error } = await supabase
        .from('client_fiscal_documents')
        .select('*')
        .eq('client_id', clientId)
        .order('created_at', { ascending: false });

      if (error) throw error;
      setDocuments(data || []);
    } catch (error) {
      console.error('Error fetching documents:', error);
      toast.error('Error al cargar los documentos');
    }
  };

  const validateForm = () => {
    const newErrors: Record<string, string> = {};
    
    if (!formData.tax_id?.trim()) {
      newErrors.tax_id = 'El RFC/ID fiscal es requerido';
    }
    
    if (!formData.fiscal_address?.trim()) {
      newErrors.fiscal_address = 'La dirección fiscal es requerida';
    }
    
    setErrors(newErrors);
    return Object.keys(newErrors).length === 0;
  };

  const handleSave = async () => {
    if (!validateForm()) return;
    
    try {
      if (fiscalData) {
        // Actualizar datos fiscales existentes
        const { error } = await supabase
          .from('client_fiscal')
          .update({
            tax_id: formData.tax_id,
            tax_regime: formData.tax_regime,
            fiscal_address: formData.fiscal_address,
            legal_representative: formData.legal_representative,
            incorporation_date: formData.incorporation_date,
            tax_status: formData.tax_status,
            updated_at: new Date().toISOString()
          })
          .eq('id', fiscalData.id);

        if (error) throw error;
        toast.success('Datos fiscales actualizados exitosamente');
      } else {
        // Crear nuevos datos fiscales
        const { error } = await supabase
          .from('client_fiscal')
          .insert({
            client_id: clientId,
            tax_id: formData.tax_id,
            tax_regime: formData.tax_regime,
            fiscal_address: formData.fiscal_address,
            legal_representative: formData.legal_representative,
            incorporation_date: formData.incorporation_date,
            tax_status: formData.tax_status
          });

        if (error) throw error;
        toast.success('Datos fiscales guardados exitosamente');
      }
      
      fetchFiscalData();
    } catch (error) {
      console.error('Error saving fiscal data:', error);
      toast.error('Error al guardar los datos fiscales');
    }
  };

  const handleFileChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    if (e.target.files && e.target.files[0]) {
      setSelectedFile(e.target.files[0]);
    }
  };

  const handleUploadDocument = async (e: React.FormEvent) => {
    e.preventDefault();
    
    if (!selectedFile) {
      toast.error('Por favor seleccione un archivo');
      return;
    }
    
    try {
      setUploading(true);
      
      // 1. Subir el archivo a Storage
      const fileExt = selectedFile.name.split('.').pop();
      const fileName = `${clientId}/${Date.now()}.${fileExt}`;
      
      const { data: fileData, error: uploadError } = await supabase.storage
        .from('client_documents')
        .upload(fileName, selectedFile);
      
      if (uploadError) throw uploadError;
      
      // 2. Obtener la URL pública del archivo
      const { data: urlData } = await supabase.storage
        .from('client_documents')
        .getPublicUrl(fileName);
      
      if (!urlData.publicUrl) throw new Error('No se pudo obtener la URL del archivo');
      
      // 3. Guardar la referencia en la base de datos
      const { error: dbError } = await supabase
        .from('client_fiscal_documents')
        .insert({
          client_id: clientId,
          fiscal_id: fiscalData?.id,
          name: documentFormData.name || selectedFile.name,
          file_url: urlData.publicUrl,
          file_type: selectedFile.type,
          file_size: selectedFile.size,
          expiration_date: documentFormData.expiration_date || null,
          document_type: documentFormData.document_type,
          notes: documentFormData.notes
        });
      
      if (dbError) throw dbError;
      
      toast.success('Documento subido exitosamente');
      resetDocumentForm();
      fetchDocuments();
    } catch (error) {
      console.error('Error uploading document:', error);
      toast.error('Error al subir el documento');
    } finally {
      setUploading(false);
    }
  };

  const handleDeleteDocument = async (documentId: string) => {
    if (!window.confirm('¿Está seguro de eliminar este documento?')) return;
    
    try {
      const { error } = await supabase
        .from('client_fiscal_documents')
        .delete()
        .eq('id', documentId);

      if (error) throw error;
      
      toast.success('Documento eliminado exitosamente');
      fetchDocuments();
    } catch (error) {
      console.error('Error deleting document:', error);
      toast.error('Error al eliminar el documento');
    }
  };

  const resetDocumentForm = () => {
    setDocumentFormData({
      name: '',
      document_type: 'tax_id',
      expiration_date: '',
      notes: ''
    });
    setSelectedFile(null);
    setShowDocumentForm(false);
  };

  const getDocumentTypeLabel = (type: string) => {
    switch (type) {
      case 'tax_id':
        return 'RFC/ID Fiscal';
      case 'incorporation':
        return 'Acta Constitutiva';
      case 'power_of_attorney':
        return 'Poder Notarial';
      case 'other':
        return 'Otro';
      default:
        return type;
    }
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
      {/* Información Fiscal */}
      <div className="bg-white shadow rounded-lg overflow-hidden">
        <div className="p-4 sm:px-6 border-b border-gray-200">
          <h3 className="text-lg font-medium text-gray-900">Información Fiscal</h3>
        </div>
        
        <div className="p-6">
          <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
            <div>
              <label className="block text-sm font-medium text-gray-700">
                RFC/ID Fiscal <span className="text-red-500">*</span>
              </label>
              {isEditing ? (
                <div>
                  <input
                    type="text"
                    value={formData.tax_id || ''}
                    onChange={(e) => setFormData({ ...formData, tax_id: e.target.value })}
                    className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
                  />
                  {errors.tax_id && (
                    <p className="mt-1 text-sm text-red-600 flex items-center">
                      <AlertTriangle className="w-4 h-4 mr-1" />
                      {errors.tax_id}
                    </p>
                  )}
                </div>
              ) : (
                <p className="mt-1 text-sm text-gray-900">{fiscalData?.tax_id || 'No especificado'}</p>
              )}
            </div>
            
            <div>
              <label className="block text-sm font-medium text-gray-700">
                Régimen Fiscal
              </label>
              {isEditing ? (
                <input
                  type="text"
                  value={formData.tax_regime || ''}
                  onChange={(e) => setFormData({ ...formData, tax_regime: e.target.value })}
                  className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
                />
              ) : (
                <p className="mt-1 text-sm text-gray-900">{fiscalData?.tax_regime || 'No especificado'}</p>
              )}
            </div>
            
            <div className="md:col-span-2">
              <label className="block text-sm font-medium text-gray-700">
                Dirección Fiscal <span className="text-red-500">*</span>
              </label>
              {isEditing ? (
                <div>
                  <textarea
                    value={formData.fiscal_address || ''}
                    onChange={(e) => setFormData({ ...formData, fiscal_address: e.target.value })}
                    rows={3}
                    className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
                  />
                  {errors.fiscal_address && (
                    <p className="mt-1 text-sm text-red-600 flex items-center">
                      <AlertTriangle className="w-4 h-4 mr-1" />
                      {errors.fiscal_address}
                    </p>
                  )}
                </div>
              ) : (
                <p className="mt-1 text-sm text-gray-900">{fiscalData?.fiscal_address || 'No especificada'}</p>
              )}
            </div>
            
            <div>
              <label className="block text-sm font-medium text-gray-700">
                Representante Legal
              </label>
              {isEditing ? (
                <input
                  type="text"
                  value={formData.legal_representative || ''}
                  onChange={(e) => setFormData({ ...formData, legal_representative: e.target.value })}
                  className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
                />
              ) : (
                <p className="mt-1 text-sm text-gray-900">{fiscalData?.legal_representative || 'No especificado'}</p>
              )}
            </div>
            
            <div>
              <label className="block text-sm font-medium text-gray-700">
                Fecha de Constitución
              </label>
              {isEditing ? (
                <input
                  type="date"
                  value={formData.incorporation_date || ''}
                  onChange={(e) => setFormData({ ...formData, incorporation_date: e.target.value })}
                  className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
                />
              ) : (
                <p className="mt-1 text-sm text-gray-900">
                  {fiscalData?.incorporation_date 
                    ? new Date(fiscalData.incorporation_date).toLocaleDateString() 
                    : 'No especificada'}
                </p>
              )}
            </div>
            
            <div>
              <label className="block text-sm font-medium text-gray-700">
                Estado Fiscal
              </label>
              {isEditing ? (
                <select
                  value={formData.tax_status || 'active'}
                  onChange={(e) => setFormData({ ...formData, tax_status: e.target.value as 'active' | 'inactive' | 'pending' })}
                  className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
                >
                  <option value="active">Activo</option>
                  <option value="inactive">Inactivo</option>
                  <option value="pending">Pendiente</option>
                </select>
              ) : (
                <p className="mt-1 text-sm text-gray-900">
                  <span className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${
                    fiscalData?.tax_status === 'active' ? 'bg-green-100 text-green-800' :
                    fiscalData?.tax_status === 'inactive' ? 'bg-gray-100 text-gray-800' :
                    'bg-yellow-100 text-yellow-800'
                  }`}>
                    {fiscalData?.tax_status === 'active' ? 'Activo' :
                     fiscalData?.tax_status === 'inactive' ? 'Inactivo' :
                     'Pendiente'}
                  </span>
                </p>
              )}
            </div>
          </div>
          
          {isEditing && (
            <div className="mt-6 flex justify-end">
              <button
                onClick={handleSave}
                className="inline-flex items-center px-4 py-2 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-blue-600 hover:bg-blue-700"
              >
                <Save className="w-4 h-4 mr-2" />
                Guardar Información Fiscal
              </button>
            </div>
          )}
        </div>
      </div>

      {/* Documentos Fiscales */}
      <div className="bg-white shadow rounded-lg overflow-hidden">
        <div className="p-4 sm:px-6 border-b border-gray-200 flex justify-between items-center">
          <h3 className="text-lg font-medium text-gray-900">Documentos Fiscales y Legales</h3>
          {isEditing && (
            <button
              onClick={() => setShowDocumentForm(true)}
              className="inline-flex items-center px-3 py-1.5 border border-transparent text-sm font-medium rounded-md shadow-sm text-white bg-blue-600 hover:bg-blue-700"
            >
              <Upload className="w-4 h-4 mr-1" />
              Subir Documento
            </button>
          )}
        </div>
        
        {documents.length === 0 ? (
          <div className="p-6 text-center">
            <FileText className="mx-auto h-12 w-12 text-gray-400" />
            <h3 className="mt-2 text-sm font-medium text-gray-900">No hay documentos</h3>
            <p className="mt-1 text-sm text-gray-500">
              Comience subiendo documentos fiscales y legales para este cliente.
            </p>
            {isEditing && (
              <div className="mt-6">
                <button
                  onClick={() => setShowDocumentForm(true)}
                  className="inline-flex items-center px-4 py-2 border border-transparent shadow-sm text-sm font-medium rounded-md text-white bg-blue-600 hover:bg-blue-700"
                >
                  <Upload className="w-5 h-5 mr-2" />
                  Subir Documento
                </button>
              </div>
            )}
          </div>
        ) : (
          <ul className="divide-y divide-gray-200">
            {documents.map((document) => (
              <li key={document.id} className="p-4 sm:px-6">
                <div className="flex items-center justify-between">
                  <div className="flex items-center">
                    <div className="flex-shrink-0">
                      <FileText className="h-10 w-10 text-blue-500" />
                    </div>
                    <div className="ml-4">
                      <h4 className="text-sm font-medium text-gray-900">{document.name}</h4>
                      <div className="mt-1 flex items-center">
                        <span className="text-xs font-medium bg-blue-100 text-blue-800 px-2 py-0.5 rounded-full">
                          {getDocumentTypeLabel(document.document_type)}
                        </span>
                        {document.expiration_date && (
                          <span className="ml-2 text-xs text-gray-500">
                            Vence: {new Date(document.expiration_date).toLocaleDateString()}
                          </span>
                        )}
                      </div>
                      {document.notes && (
                        <p className="mt-1 text-sm text-gray-500">{document.notes}</p>
                      )}
                    </div>
                  </div>
                  <div className="flex space-x-2">
                    <a
                      href={document.file_url}
                      target="_blank"
                      rel="noopener noreferrer"
                      className="text-blue-600 hover:text-blue-900"
                      title="Descargar documento"
                    >
                      <Download className="h-5 w-5" />
                    </a>
                    {isEditing && (
                      <button
                        onClick={() => handleDeleteDocument(document.id)}
                        className="text-red-600 hover:text-red-900"
                        title="Eliminar documento"
                      >
                        <Trash2 className="h-5 w-5" />
                      </button>
                    )}
                  </div>
                </div>
              </li>
            ))}
          </ul>
        )}
      </div>

      {/* Formulario de subida de documento */}
      {showDocumentForm && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
          <div className="bg-white rounded-lg w-full max-w-md p-6">
            <div className="flex justify-between items-center mb-4">
              <h2 className="text-xl font-semibold text-gray-900">
                Subir Documento
              </h2>
              <button
                onClick={resetDocumentForm}
                className="text-gray-400 hover:text-gray-500"
              >
                <X className="w-6 h-6" />
              </button>
            </div>

            <form onSubmit={handleUploadDocument} className="space-y-4">
              <div>
                <label htmlFor="name" className="block text-sm font-medium text-gray-700">
                  Nombre del Documento
                </label>
                <input
                  type="text"
                  id="name"
                  value={documentFormData.name}
                  onChange={(e) => setDocumentFormData({ ...documentFormData, name: e.target.value })}
                  placeholder="Ej. RFC Empresa"
                  className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
                />
              </div>

              <div>
                <label htmlFor="document_type" className="block text-sm font-medium text-gray-700">
                  Tipo de Documento
                </label>
                <select
                  id="document_type"
                  value={documentFormData.document_type}
                  onChange={(e) => setDocumentFormData({ ...documentFormData, document_type: e.target.value })}
                  className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
                >
                  <option value="tax_id">RFC/ID Fiscal</option>
                  <option value="incorporation">Acta Constitutiva</option>
                  <option value="power_of_attorney">Poder Notarial</option>
                  <option value="other">Otro</option>
                </select>
              </div>

              <div>
                <label htmlFor="expiration_date" className="block text-sm font-medium text-gray-700">
                  Fecha de Vencimiento (opcional)
                </label>
                <input
                  type="date"
                  id="expiration_date"
                  value={documentFormData.expiration_date}
                  onChange={(e) => setDocumentFormData({ ...documentFormData, expiration_date: e.target.value })}
                  className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
                />
              </div>

              <div>
                <label htmlFor="notes" className="block text-sm font-medium text-gray-700">
                  Notas (opcional)
                </label>
                <textarea
                  id="notes"
                  rows={2}
                  value={documentFormData.notes}
                  onChange={(e) => setDocumentFormData({ ...documentFormData, notes: e.target.value })}
                  className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
                />
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700">
                  Archivo <span className="text-red-500">*</span>
                </label>
                <div className="mt-1 flex justify-center px-6 pt-5 pb-6 border-2 border-gray-300 border-dashed rounded-md">
                  <div className="space-y-1 text-center">
                    <Upload className="mx-auto h-12 w-12 text-gray-400" />
                    <div className="flex text-sm text-gray-600">
                      <label
                        htmlFor="file-upload"
                        className="relative cursor-pointer bg-white rounded-md font-medium text-blue-600 hover:text-blue-500"
                      >
                        <span>Seleccionar archivo</span>
                        <input
                          id="file-upload"
                          name="file-upload"
                          type="file"
                          className="sr-only"
                          onChange={handleFileChange}
                        />
                      </label>
                      <p className="pl-1">o arrastrar y soltar</p>
                    </div>
                    <p className="text-xs text-gray-500">
                      PDF, PNG, JPG hasta 10MB
                    </p>
                  </div>
                </div>
                {selectedFile && (
                  <p className="mt-2 text-sm text-gray-600">
                    Archivo seleccionado: {selectedFile.name}
                  </p>
                )}
              </div>

              <div className="flex justify-end space-x-3 pt-4">
                <button
                  type="button"
                  onClick={resetDocumentForm}
                  className="px-4 py-2 border border-gray-300 rounded-md text-sm font-medium text-gray-700 hover:bg-gray-50"
                >
                  Cancelar
                </button>
                <button
                  type="submit"
                  disabled={uploading || !selectedFile}
                  className="px-4 py-2 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-blue-600 hover:bg-blue-700 disabled:opacity-50"
                >
                  {uploading ? 'Subiendo...' : 'Subir Documento'}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
}
