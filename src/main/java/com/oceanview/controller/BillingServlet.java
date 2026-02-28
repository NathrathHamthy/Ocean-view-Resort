package com.oceanview.controller;

import com.oceanview.model.Payment;
import com.oceanview.model.Reservation;
import com.oceanview.model.User;
import com.oceanview.service.BillingService;
import com.oceanview.service.ReservationService;
import com.oceanview.util.Constants;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.io.IOException;
import java.util.List;
import java.util.Optional;

/**
 * Billing Servlet
 * Handles payment and billing operations
 * URL Mapping: /billing (configured in web.xml)
 * 
 * @author Ocean View Resort Development Team
 * @version 1.0.0
 */
public class BillingServlet extends HttpServlet {
    
    private static final Logger logger = LoggerFactory.getLogger(BillingServlet.class);
    private BillingService billingService;
    private ReservationService reservationService;
    
    @Override
    public void init() throws ServletException {
        billingService = new BillingService();
        reservationService = new ReservationService();
        logger.info("BillingServlet initialized");
    }
    
    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        
        String action = request.getParameter("action");
        
        if (action == null || action.isEmpty()) {
            action = "list";
        }
        
        try {
            switch (action) {
                case "list":
                    listPayments(request, response);
                    break;
                case "view":
                    viewPayment(request, response);
                    break;
                case "viewBill":
                    viewBill(request, response);
                    break;
                case "processPayment":
                    showPaymentForm(request, response);
                    break;
                default:
                    listPayments(request, response);
                    break;
            }
        } catch (Exception e) {
            logger.error("Error in BillingServlet GET", e);
            request.setAttribute(Constants.ATTR_ERROR, "Error processing request");
            request.getRequestDispatcher("/views/error/error.jsp").forward(request, response);
        }
    }
    
    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        
        String action = request.getParameter("action");
        
        if (action == null || action.isEmpty()) {
            response.sendError(HttpServletResponse.SC_BAD_REQUEST, "Action parameter is required");
            return;
        }
        
        try {
            switch (action) {
                case "processPayment":
                    processPayment(request, response);
                    break;
                case "refund":
                    refundPayment(request, response);
                    break;
                default:
                    response.sendError(HttpServletResponse.SC_BAD_REQUEST, "Invalid action");
                    break;
            }
        } catch (Exception e) {
            logger.error("Error in BillingServlet POST", e);
            request.setAttribute(Constants.ATTR_ERROR, "Error processing request");
            request.getRequestDispatcher("/views/error/error.jsp").forward(request, response);
        }
    }
    
    /**
     * List all payments
     */
    private void listPayments(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        
        HttpSession session = request.getSession();
        User user = (User) session.getAttribute(Constants.SESSION_USER);
        
        if (user == null) {
            response.sendRedirect(request.getContextPath() + "/login");
            return;
        }
        
        List<Payment> payments = billingService.getAllPayments();
        request.setAttribute("payments", payments);
        
        // Calculate total revenue
        double totalRevenue = billingService.getTotalRevenue();
        request.setAttribute("totalRevenue", totalRevenue);
        
        logger.info("Loaded {} payments", payments.size());
        
        // Forward based on user role
        if (user.isAdmin()) {
            request.getRequestDispatcher("/views/admin/billing/list.jsp").forward(request, response);
        } else if (user.isStaff()) {
            request.getRequestDispatcher("/views/staff/billing/list.jsp").forward(request, response);
        } else {
            request.getRequestDispatcher("/views/guest/billing/list.jsp").forward(request, response);
        }
    }
    
    /**
     * View payment details
     */
    private void viewPayment(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        
        String paymentIdStr = request.getParameter("id");
        
        if (paymentIdStr == null || paymentIdStr.isEmpty()) {
            request.setAttribute(Constants.ATTR_ERROR, "Payment ID is required");
            listPayments(request, response);
            return;
        }
        
        try {
            int paymentId = Integer.parseInt(paymentIdStr);
            Optional<Payment> paymentOpt = billingService.getPaymentById(paymentId);
            
            if (paymentOpt.isPresent()) {
                request.setAttribute("payment", paymentOpt.get());
                request.getRequestDispatcher("/views/billing/view.jsp").forward(request, response);
            } else {
                request.setAttribute(Constants.ATTR_ERROR, "Payment not found");
                listPayments(request, response);
            }
        } catch (NumberFormatException e) {
            logger.error("Invalid payment ID: {}", paymentIdStr);
            request.setAttribute(Constants.ATTR_ERROR, "Invalid payment ID");
            listPayments(request, response);
        }
    }
    
    /**
     * View bill for a reservation
     */
    private void viewBill(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        
        String reservationIdStr = request.getParameter("reservationId");
        
        if (reservationIdStr == null || reservationIdStr.isEmpty()) {
            request.setAttribute(Constants.ATTR_ERROR, "Reservation ID is required");
            response.sendRedirect(request.getContextPath() + "/reservation?action=list");
            return;
        }
        
        try {
            int reservationId = Integer.parseInt(reservationIdStr);
            Optional<Reservation> billOpt = billingService.calculateBill(reservationId);
            
            if (billOpt.isPresent()) {
                Reservation reservation = billOpt.get();
                request.setAttribute("reservation", reservation);
                
                // Get payment history for this reservation
                List<Payment> payments = billingService.getPaymentsByReservation(reservationId);
                request.setAttribute("payments", payments);
                
                request.getRequestDispatcher("/views/billing/bill.jsp").forward(request, response);
            } else {
                request.setAttribute(Constants.ATTR_ERROR, "Reservation not found");
                response.sendRedirect(request.getContextPath() + "/reservation?action=list");
            }
        } catch (NumberFormatException e) {
            logger.error("Invalid reservation ID: {}", reservationIdStr);
            request.setAttribute(Constants.ATTR_ERROR, "Invalid reservation ID");
            response.sendRedirect(request.getContextPath() + "/reservation?action=list");
        }
    }
    
    /**
     * Show payment form
     */
    private void showPaymentForm(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        
        String reservationIdStr = request.getParameter("reservationId");
        
        if (reservationIdStr == null || reservationIdStr.isEmpty()) {
            request.setAttribute(Constants.ATTR_ERROR, "Reservation ID is required");
            response.sendRedirect(request.getContextPath() + "/reservation?action=list");
            return;
        }
        
        try {
            int reservationId = Integer.parseInt(reservationIdStr);
            Optional<Reservation> reservationOpt = reservationService.getReservationById(reservationId);
            
            if (reservationOpt.isPresent()) {
                request.setAttribute("reservation", reservationOpt.get());
                request.getRequestDispatcher("/views/billing/payment-form.jsp").forward(request, response);
            } else {
                request.setAttribute(Constants.ATTR_ERROR, "Reservation not found");
                response.sendRedirect(request.getContextPath() + "/reservation?action=list");
            }
        } catch (NumberFormatException e) {
            logger.error("Invalid reservation ID: {}", reservationIdStr);
            request.setAttribute(Constants.ATTR_ERROR, "Invalid reservation ID");
            response.sendRedirect(request.getContextPath() + "/reservation?action=list");
        }
    }
    
    /**
     * Process payment
     */
    private void processPayment(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        
        String reservationIdStr = request.getParameter("reservationId");
        String paymentMethod = request.getParameter("paymentMethod");
        String transactionId = request.getParameter("transactionId");
        
        // Validate input
        if (reservationIdStr == null || reservationIdStr.isEmpty()) {
            request.setAttribute(Constants.ATTR_ERROR, "Reservation ID is required");
            response.sendRedirect(request.getContextPath() + "/billing");
            return;
        }
        
        if (paymentMethod == null || paymentMethod.isEmpty()) {
            request.setAttribute(Constants.ATTR_ERROR, "Payment method is required");
            showPaymentForm(request, response);
            return;
        }
        
        try {
            int reservationId = Integer.parseInt(reservationIdStr);
            Payment.PaymentMethod method = Payment.PaymentMethod.valueOf(paymentMethod.toUpperCase());
            
            int paymentId = billingService.processPayment(reservationId, method, transactionId);
            
            if (paymentId > 0) {
                logger.info("Payment processed successfully: ID={}", paymentId);
                request.setAttribute(Constants.ATTR_SUCCESS, Constants.MSG_PAYMENT_SUCCESS);
                
                // Redirect to payment confirmation page
                response.sendRedirect(request.getContextPath() + "/billing?action=view&id=" + paymentId);
            } else {
                String errorMsg = getPaymentErrorMessage(paymentId);
                request.setAttribute(Constants.ATTR_ERROR, errorMsg);
                showPaymentForm(request, response);
            }
            
        } catch (NumberFormatException e) {
            logger.error("Invalid reservation ID: {}", reservationIdStr);
            request.setAttribute(Constants.ATTR_ERROR, "Invalid reservation ID");
            response.sendRedirect(request.getContextPath() + "/billing");
        } catch (IllegalArgumentException e) {
            logger.error("Invalid payment method: {}", paymentMethod);
            request.setAttribute(Constants.ATTR_ERROR, "Invalid payment method");
            showPaymentForm(request, response);
        }
    }
    
    /**
     * Refund payment
     */
    private void refundPayment(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        
        String paymentIdStr = request.getParameter("id");
        
        if (paymentIdStr == null || paymentIdStr.isEmpty()) {
            request.setAttribute(Constants.ATTR_ERROR, "Payment ID is required");
            listPayments(request, response);
            return;
        }
        
        try {
            int paymentId = Integer.parseInt(paymentIdStr);
            boolean success = billingService.refundPayment(paymentId);
            
            if (success) {
                logger.info("Payment refunded successfully: ID={}", paymentId);
                request.setAttribute(Constants.ATTR_SUCCESS, "Payment refunded successfully");
            } else {
                request.setAttribute(Constants.ATTR_ERROR, "Failed to refund payment");
            }
            
            viewPayment(request, response);
            
        } catch (NumberFormatException e) {
            logger.error("Invalid payment ID: {}", paymentIdStr);
            request.setAttribute(Constants.ATTR_ERROR, "Invalid payment ID");
            listPayments(request, response);
        }
    }
    
    /**
     * Get error message based on payment error code
     */
    private String getPaymentErrorMessage(int errorCode) {
        switch (errorCode) {
            case -1:
                return "Reservation not found";
            case -2:
                return "Cannot process payment for cancelled reservation";
            case -3:
                return "Database error occurred while processing payment";
            default:
                return "Payment processing failed";
        }
    }
}
