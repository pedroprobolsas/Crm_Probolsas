import { jsPDF } from 'jspdf';
import { format } from 'date-fns';
import { es } from 'date-fns/locale';
import type { Quote } from '../types';

export async function generateQuotePDF(quote: Quote) {
  // Create new PDF document
  const doc = new jsPDF();
  
  // Font and style configuration
  const titleSize = 18;
  const subtitleSize = 14;
  const normalSize = 10;
  const smallSize = 8;
  
  // Colors
  const primaryColor = '#1E40AF'; // blue-800
  const textColor = '#111827'; // gray-900
  const secondaryColor = '#6B7280'; // gray-500

  // Initial positions
  let y = 20;
  const marginLeft = 20;
  const marginRight = 190;
  const pageWidth = 210;
  const contentWidth = pageWidth - marginLeft - 20;

  // Header
  doc.setFontSize(titleSize);
  doc.setTextColor(primaryColor);
  doc.text('PROBOLSAS', marginLeft, y);
  
  y += 10;
  doc.setFontSize(subtitleSize);
  doc.text(`Cotización #${quote.quote_number}`, marginLeft, y);

  // General information
  y += 15;
  doc.setFontSize(normalSize);
  doc.setTextColor(textColor);
  doc.text(`Fecha: ${format(new Date(quote.created_at), 'PPP', { locale: es })}`, marginLeft, y);
  y += 7;
  doc.text(`Válida hasta: ${format(new Date(quote.valid_until), 'PPP', { locale: es })}`, marginLeft, y);
  y += 7;
  doc.text(`Cliente: ${quote.client_name}`, marginLeft, y);
  y += 7;
  doc.text(`Empresa: ${quote.client_company}`, marginLeft, y);
  y += 7;
  doc.text(`Asesor: ${quote.agent_name}`, marginLeft, y);

  // Quote status
  y += 15;
  doc.setFontSize(subtitleSize);
  doc.setTextColor(primaryColor);
  doc.text('Estado', marginLeft, y);
  y += 7;
  doc.setFontSize(normalSize);
  doc.setTextColor(textColor);
  doc.text(quote.status === 'draft' ? 'Borrador' :
           quote.status === 'sent' ? 'Enviada' :
           quote.status === 'approved' ? 'Aprobada' : 'Rechazada', marginLeft, y);

  // Products table
  y += 15;
  doc.setFontSize(subtitleSize);
  doc.setTextColor(primaryColor);
  doc.text('Productos', marginLeft, y);
  y += 10;

  // Table headers
  const headers = ['Producto', 'Cantidad', 'Precio Unit.', 'Total'];
  const colWidths = [80, 30, 30, 30];
  let x = marginLeft;

  doc.setFontSize(normalSize);
  doc.setTextColor(secondaryColor);
  headers.forEach((header, i) => {
    doc.text(header, x, y);
    x += colWidths[i];
  });

  // Table content
  y += 5;
  doc.setTextColor(textColor);
  quote.items.forEach((item) => {
    // Check if we need a new page
    if (y > 250) {
      doc.addPage();
      y = 20;
    }

    x = marginLeft;
    doc.text(item.product_name, x, y);
    x += colWidths[0];
    doc.text(item.quantity.toString(), x, y);
    x += colWidths[1];
    doc.text(`$${item.unit_price.toLocaleString('es-CO')}`, x, y);
    x += colWidths[2];
    doc.text(`$${item.total_price.toLocaleString('es-CO')}`, x, y);
    y += 7;
  });

  // Total
  y += 5;
  doc.setFontSize(subtitleSize);
  doc.setTextColor(primaryColor);
  doc.text(`Total: $${quote.total_amount.toLocaleString('es-CO')}`, marginRight - 40, y);

  // Terms and conditions
  if (quote.terms) {
    y += 15;
    doc.setFontSize(subtitleSize);
    doc.text('Términos y Condiciones', marginLeft, y);
    y += 7;
    doc.setFontSize(normalSize);
    doc.setTextColor(textColor);
    
    const terms = doc.splitTextToSize(quote.terms, contentWidth);
    terms.forEach((line: string) => {
      if (y > 250) {
        doc.addPage();
        y = 20;
      }
      doc.text(line, marginLeft, y);
      y += 5;
    });
  }

  // Notes
  if (quote.notes) {
    y += 10;
    doc.setFontSize(subtitleSize);
    doc.setTextColor(primaryColor);
    doc.text('Notas Adicionales', marginLeft, y);
    y += 7;
    doc.setFontSize(normalSize);
    doc.setTextColor(textColor);
    
    const notes = doc.splitTextToSize(quote.notes, contentWidth);
    notes.forEach((line: string) => {
      if (y > 250) {
        doc.addPage();
        y = 20;
      }
      doc.text(line, marginLeft, y);
      y += 5;
    });
  }

  // Footer
  const pageCount = doc.getNumberOfPages();
  doc.setFontSize(smallSize);
  doc.setTextColor(secondaryColor);
  
  for (let i = 1; i <= pageCount; i++) {
    doc.setPage(i);
    doc.text(
      `Página ${i} de ${pageCount}`,
      pageWidth / 2,
      290,
      { align: 'center' }
    );
  }

  // Save the PDF
  doc.save(`cotizacion-${quote.quote_number}.pdf`);
}