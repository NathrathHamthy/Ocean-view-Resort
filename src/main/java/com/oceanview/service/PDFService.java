package com.oceanview.service;

import com.itextpdf.text.*;
import com.itextpdf.text.pdf.PdfPCell;
import com.itextpdf.text.pdf.PdfPTable;
import com.itextpdf.text.pdf.PdfWriter;
import com.itextpdf.text.pdf.draw.LineSeparator;
import com.oceanview.model.Payment;
import com.oceanview.model.Reservation;
import com.oceanview.model.User;
import com.oceanview.util.DateUtil;
import com.oceanview.util.NumberUtil;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.io.ByteArrayOutputStream;
import java.io.FileOutputStream;
import java.io.IOException;
import java.time.LocalDateTime;
import java.util.List;

/**
 * PDF Service - Singleton Pattern
 * Generates PDF documents for invoices, reports, and confirmations
 * 
 * @author Ocean View Resort Development Team
 * @version 1.0.0
 */
public class PDFService {
    
    private static final Logger logger = LoggerFactory.getLogger(PDFService.class);
    private static PDFService instance;
    
    // PDF Configuration
    private static final Font TITLE_FONT = new Font(Font.FontFamily.TIMES_ROMAN, 20, Font.BOLD, BaseColor.BLUE);
    private static final Font HEADER_FONT = new Font(Font.FontFamily.TIMES_ROMAN, 14, Font.BOLD);
    private static final Font NORMAL_FONT = new Font(Font.FontFamily.TIMES_ROMAN, 12, Font.NORMAL);
    private static final Font SMALL_FONT = new Font(Font.FontFamily.TIMES_ROMAN, 10, Font.NORMAL);
    
    /**
     * Private constructor for Singleton
     */
    private PDFService() {
        logger.info("PDFService initialized");
    }
    
    /**
     * Get singleton instance
     * @return PDFService instance
     */
    public static synchronized PDFService getInstance() {
        if (instance == null) {
            instance = new PDFService();
        }
        return instance;
    }
    
    /**
     * Generate booking confirmation PDF
     * @param reservation Reservation details
     * @param user User details
     * @return PDF as byte array
     */
    public byte[] generateBookingConfirmationPDF(Reservation reservation, User user) {
        try {
            Document document = new Document(PageSize.A4);
            ByteArrayOutputStream baos = new ByteArrayOutputStream();
            PdfWriter.getInstance(document, baos);
            
            document.open();
            
            // Header
            addHeader(document, "BOOKING CONFIRMATION");
            
            // Hotel Information
            addHotelInfo(document);
            
            document.add(new Paragraph(" "));
            
            // Guest Information
            addSectionTitle(document, "Guest Information");
            addKeyValue(document, "Name:", user.getFullName());
            addKeyValue(document, "Email:", user.getEmail());
            if (user.getPhone() != null) {
                addKeyValue(document, "Phone:", user.getPhone());
            }
            
            document.add(new Paragraph(" "));
            
            // Reservation Details
            addSectionTitle(document, "Reservation Details");
            addKeyValue(document, "Reservation Number:", reservation.getReservationNumber());
            addKeyValue(document, "Check-in Date:", DateUtil.formatDateForDisplay(reservation.getCheckInDate()));
            addKeyValue(document, "Check-out Date:", DateUtil.formatDateForDisplay(reservation.getCheckOutDate()));
            addKeyValue(document, "Number of Nights:", String.valueOf(reservation.getNumberOfNights()));
            addKeyValue(document, "Number of Guests:", String.valueOf(reservation.getNumberOfGuests()));
            addKeyValue(document, "Status:", reservation.getStatus().name());
            
            document.add(new Paragraph(" "));
            
            // Billing Information
            addBillingTable(document, reservation);
            
            document.add(new Paragraph(" "));
            
            // Terms and Conditions
            addTermsAndConditions(document);
            
            // Footer
            addFooter(document);
            
            document.close();
            
            logger.info("Booking confirmation PDF generated for reservation: {}", 
                       reservation.getReservationNumber());
            
            return baos.toByteArray();
            
        } catch (DocumentException e) {
            logger.error("Error generating booking confirmation PDF", e);
            return null;
        }
    }
    
    /**
     * Generate invoice PDF
     * @param reservation Reservation details
     * @param payment Payment details
     * @param user User details
     * @return PDF as byte array
     */
    public byte[] generateInvoicePDF(Reservation reservation, Payment payment, User user) {
        try {
            Document document = new Document(PageSize.A4);
            ByteArrayOutputStream baos = new ByteArrayOutputStream();
            PdfWriter.getInstance(document, baos);
            
            document.open();
            
            // Header
            addHeader(document, "INVOICE");
            
            // Hotel Information
            addHotelInfo(document);
            
            document.add(new Paragraph(" "));
            
            // Invoice Information
            addSectionTitle(document, "Invoice Information");
            addKeyValue(document, "Invoice Number:", payment.getPaymentNumber());
            addKeyValue(document, "Invoice Date:", DateUtil.formatDateTimeForDisplay(payment.getPaymentDate()));
            addKeyValue(document, "Payment Method:", payment.getPaymentMethod().name());
            addKeyValue(document, "Payment Status:", payment.getPaymentStatus().name());
            if (payment.getTransactionId() != null) {
                addKeyValue(document, "Transaction ID:", payment.getTransactionId());
            }
            
            document.add(new Paragraph(" "));
            
            // Bill To
            addSectionTitle(document, "Bill To");
            addKeyValue(document, "Name:", user.getFullName());
            addKeyValue(document, "Email:", user.getEmail());
            if (user.getPhone() != null) {
                addKeyValue(document, "Phone:", user.getPhone());
            }
            
            document.add(new Paragraph(" "));
            
            // Reservation Details
            addSectionTitle(document, "Reservation Details");
            addKeyValue(document, "Reservation Number:", reservation.getReservationNumber());
            addKeyValue(document, "Check-in Date:", DateUtil.formatDateForDisplay(reservation.getCheckInDate()));
            addKeyValue(document, "Check-out Date:", DateUtil.formatDateForDisplay(reservation.getCheckOutDate()));
            addKeyValue(document, "Number of Nights:", String.valueOf(reservation.getNumberOfNights()));
            
            document.add(new Paragraph(" "));
            
            // Billing Table
            addInvoiceTable(document, reservation, payment);
            
            document.add(new Paragraph(" "));
            
            // Payment Information
            Paragraph paymentInfo = new Paragraph("Payment Received: " + 
                                                 NumberUtil.formatCurrency(payment.getAmount()), 
                                                 HEADER_FONT);
            paymentInfo.setAlignment(Element.ALIGN_RIGHT);
            document.add(paymentInfo);
            
            document.add(new Paragraph(" "));
            
            // Thank You Note
            Paragraph thankYou = new Paragraph("Thank you for choosing Ocean View Resort!", NORMAL_FONT);
            thankYou.setAlignment(Element.ALIGN_CENTER);
            document.add(thankYou);
            
            // Footer
            addFooter(document);
            
            document.close();
            
            logger.info("Invoice PDF generated for payment: {}", payment.getPaymentNumber());
            
            return baos.toByteArray();
            
        } catch (DocumentException e) {
            logger.error("Error generating invoice PDF", e);
            return null;
        }
    }
    
    /**
     * Generate revenue report PDF
     * @param startDate Start date
     * @param endDate End date
     * @param payments List of payments
     * @param totalRevenue Total revenue
     * @return PDF as byte array
     */
    public byte[] generateRevenueReportPDF(String startDate, String endDate, 
                                          List<Payment> payments, double totalRevenue) {
        try {
            Document document = new Document(PageSize.A4.rotate()); // Landscape
            ByteArrayOutputStream baos = new ByteArrayOutputStream();
            PdfWriter.getInstance(document, baos);
            
            document.open();
            
            // Header
            addHeader(document, "REVENUE REPORT");
            
            // Report Period
            Paragraph period = new Paragraph("Period: " + startDate + " to " + endDate, NORMAL_FONT);
            period.setAlignment(Element.ALIGN_CENTER);
            document.add(period);
            
            Paragraph generated = new Paragraph("Generated: " + 
                                              DateUtil.formatDateTimeForDisplay(LocalDateTime.now()), 
                                              SMALL_FONT);
            generated.setAlignment(Element.ALIGN_CENTER);
            document.add(generated);
            
            document.add(new Paragraph(" "));
            
            // Revenue Summary
            addSectionTitle(document, "Revenue Summary");
            addKeyValue(document, "Total Transactions:", String.valueOf(payments.size()));
            addKeyValue(document, "Total Revenue:", NumberUtil.formatCurrency(totalRevenue));
            
            document.add(new Paragraph(" "));
            
            // Payment Table
            PdfPTable table = new PdfPTable(6);
            table.setWidthPercentage(100);
            table.setWidths(new float[]{2, 2, 2, 2, 2, 2});
            
            // Table Headers
            addTableHeader(table, "Payment #");
            addTableHeader(table, "Date");
            addTableHeader(table, "Reservation #");
            addTableHeader(table, "Method");
            addTableHeader(table, "Status");
            addTableHeader(table, "Amount");
            
            // Table Data
            for (Payment payment : payments) {
                table.addCell(new PdfPCell(new Phrase(payment.getPaymentNumber(), SMALL_FONT)));
                table.addCell(new PdfPCell(new Phrase(
                    DateUtil.formatDateForDisplay(payment.getPaymentDate().toLocalDate()), SMALL_FONT)));
                table.addCell(new PdfPCell(new Phrase(
                    String.valueOf(payment.getReservationId()), SMALL_FONT)));
                table.addCell(new PdfPCell(new Phrase(payment.getPaymentMethod().name(), SMALL_FONT)));
                table.addCell(new PdfPCell(new Phrase(payment.getPaymentStatus().name(), SMALL_FONT)));
                
                PdfPCell amountCell = new PdfPCell(new Phrase(
                    NumberUtil.formatCurrency(payment.getAmount()), SMALL_FONT));
                amountCell.setHorizontalAlignment(Element.ALIGN_RIGHT);
                table.addCell(amountCell);
            }
            
            document.add(table);
            
            // Footer
            addFooter(document);
            
            document.close();
            
            logger.info("Revenue report PDF generated with {} transactions", payments.size());
            
            return baos.toByteArray();
            
        } catch (DocumentException e) {
            logger.error("Error generating revenue report PDF", e);
            return null;
        }
    }
    
    /**
     * Save PDF to file
     * @param pdfData PDF byte array
     * @param filePath Output file path
     * @return true if successful
     */
    public boolean savePDFToFile(byte[] pdfData, String filePath) {
        if (pdfData == null || pdfData.length == 0) {
            logger.error("PDF data is null or empty");
            return false;
        }
        
        try (FileOutputStream fos = new FileOutputStream(filePath)) {
            fos.write(pdfData);
            logger.info("PDF saved to file: {}", filePath);
            return true;
        } catch (IOException e) {
            logger.error("Error saving PDF to file: {}", filePath, e);
            return false;
        }
    }
    
    // Helper Methods
    
    private void addHeader(Document document, String title) throws DocumentException {
        Paragraph header = new Paragraph(title, TITLE_FONT);
        header.setAlignment(Element.ALIGN_CENTER);
        header.setSpacingAfter(10);
        document.add(header);
    }
    
    private void addHotelInfo(Document document) throws DocumentException {
        Paragraph hotelName = new Paragraph("Ocean View Resort", HEADER_FONT);
        hotelName.setAlignment(Element.ALIGN_CENTER);
        document.add(hotelName);
        
        Paragraph address = new Paragraph("123 Beach Road, Paradise Island", SMALL_FONT);
        address.setAlignment(Element.ALIGN_CENTER);
        document.add(address);
        
        Paragraph contact = new Paragraph("Phone: +1-555-OCEAN | Email: info@oceanviewresort.com", SMALL_FONT);
        contact.setAlignment(Element.ALIGN_CENTER);
        document.add(contact);
        
        document.add(new Paragraph(" "));
        document.add(new LineSeparator());
    }
    
    private void addSectionTitle(Document document, String title) throws DocumentException {
        Paragraph section = new Paragraph(title, HEADER_FONT);
        section.setSpacingBefore(5);
        section.setSpacingAfter(5);
        document.add(section);
    }
    
    private void addKeyValue(Document document, String key, String value) throws DocumentException {
        Chunk keyChunk = new Chunk(key + " ", NORMAL_FONT);
        keyChunk.setTextRise(0);
        
        Chunk valueChunk = new Chunk(value, NORMAL_FONT);
        
        Paragraph paragraph = new Paragraph();
        paragraph.add(keyChunk);
        paragraph.add(valueChunk);
        document.add(paragraph);
    }
    
    private void addBillingTable(Document document, Reservation reservation) throws DocumentException {
        PdfPTable table = new PdfPTable(2);
        table.setWidthPercentage(100);
        table.setWidths(new float[]{3, 1});
        
        // Subtotal
        table.addCell(new PdfPCell(new Phrase("Subtotal", NORMAL_FONT)));
        PdfPCell subtotalCell = new PdfPCell(new Phrase(
            NumberUtil.formatCurrency(reservation.getTotalAmount()), NORMAL_FONT));
        subtotalCell.setHorizontalAlignment(Element.ALIGN_RIGHT);
        table.addCell(subtotalCell);
        
        // Discount
        if (reservation.getDiscountAmount() != null && 
            NumberUtil.isPositive(reservation.getDiscountAmount())) {
            table.addCell(new PdfPCell(new Phrase("Discount", NORMAL_FONT)));
            PdfPCell discountCell = new PdfPCell(new Phrase(
                "-" + NumberUtil.formatCurrency(reservation.getDiscountAmount()), NORMAL_FONT));
            discountCell.setHorizontalAlignment(Element.ALIGN_RIGHT);
            table.addCell(discountCell);
        }
        
        // Tax
        table.addCell(new PdfPCell(new Phrase("Tax", NORMAL_FONT)));
        PdfPCell taxCell = new PdfPCell(new Phrase(
            NumberUtil.formatCurrency(reservation.getTaxAmount()), NORMAL_FONT));
        taxCell.setHorizontalAlignment(Element.ALIGN_RIGHT);
        table.addCell(taxCell);
        
        // Total
        PdfPCell totalLabelCell = new PdfPCell(new Phrase("Total Amount", HEADER_FONT));
        totalLabelCell.setBorderWidth(2);
        table.addCell(totalLabelCell);
        
        PdfPCell totalAmountCell = new PdfPCell(new Phrase(
            NumberUtil.formatCurrency(reservation.getFinalAmount()), HEADER_FONT));
        totalAmountCell.setHorizontalAlignment(Element.ALIGN_RIGHT);
        totalAmountCell.setBorderWidth(2);
        table.addCell(totalAmountCell);
        
        document.add(table);
    }
    
    private void addInvoiceTable(Document document, Reservation reservation, Payment payment) 
            throws DocumentException {
        PdfPTable table = new PdfPTable(2);
        table.setWidthPercentage(100);
        table.setWidths(new float[]{3, 1});
        
        // Room Charges
        table.addCell(new PdfPCell(new Phrase(
            "Room Charges (" + reservation.getNumberOfNights() + " nights)", NORMAL_FONT)));
        PdfPCell chargesCell = new PdfPCell(new Phrase(
            NumberUtil.formatCurrency(reservation.getTotalAmount()), NORMAL_FONT));
        chargesCell.setHorizontalAlignment(Element.ALIGN_RIGHT);
        table.addCell(chargesCell);
        
        // Tax
        table.addCell(new PdfPCell(new Phrase("Tax", NORMAL_FONT)));
        PdfPCell taxCell = new PdfPCell(new Phrase(
            NumberUtil.formatCurrency(reservation.getTaxAmount()), NORMAL_FONT));
        taxCell.setHorizontalAlignment(Element.ALIGN_RIGHT);
        table.addCell(taxCell);
        
        // Total
        PdfPCell totalLabelCell = new PdfPCell(new Phrase("Total", HEADER_FONT));
        totalLabelCell.setBorderWidth(2);
        table.addCell(totalLabelCell);
        
        PdfPCell totalAmountCell = new PdfPCell(new Phrase(
            NumberUtil.formatCurrency(reservation.getFinalAmount()), HEADER_FONT));
        totalAmountCell.setHorizontalAlignment(Element.ALIGN_RIGHT);
        totalAmountCell.setBorderWidth(2);
        table.addCell(totalAmountCell);
        
        document.add(table);
    }
    
    private void addTableHeader(PdfPTable table, String header) {
        PdfPCell cell = new PdfPCell(new Phrase(header, HEADER_FONT));
        cell.setBackgroundColor(BaseColor.LIGHT_GRAY);
        cell.setHorizontalAlignment(Element.ALIGN_CENTER);
        cell.setPadding(5);
        table.addCell(cell);
    }
    
    private void addTermsAndConditions(Document document) throws DocumentException {
        Paragraph terms = new Paragraph("Terms & Conditions:", HEADER_FONT);
        document.add(terms);
        
        Paragraph t1 = new Paragraph("• Check-in time: 2:00 PM | Check-out time: 12:00 PM", SMALL_FONT);
        document.add(t1);
        
        Paragraph t2 = new Paragraph("• Cancellation must be made 24 hours before check-in", SMALL_FONT);
        document.add(t2);
        
        Paragraph t3 = new Paragraph("• Valid ID required at check-in", SMALL_FONT);
        document.add(t3);
    }
    
    private void addFooter(Document document) throws DocumentException {
        document.add(new Paragraph(" "));
        document.add(new LineSeparator());
        
        Paragraph footer = new Paragraph(
            "This is a computer-generated document. No signature required.", 
            SMALL_FONT);
        footer.setAlignment(Element.ALIGN_CENTER);
        document.add(footer);
    }
}
