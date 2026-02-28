package com.oceanview.service;

import com.oceanview.config.AppConfig;
import com.oceanview.dao.PaymentDAO;
import com.oceanview.dao.ReservationDAO;
import com.oceanview.model.Payment;
import com.oceanview.model.Reservation;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.math.BigDecimal;
import java.sql.SQLException;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.List;
import java.util.Optional;

/**
 * Billing Service
 * Handles payment and billing operations
 * 
 * @author Ocean View Resort Development Team
 * @version 1.0.0
 */
public class BillingService {
    
    private static final Logger logger = LoggerFactory.getLogger(BillingService.class);
    private final PaymentDAO paymentDAO;
    private final ReservationDAO reservationDAO;
    private final AppConfig config;
    
    /**
     * Constructor
     */
    public BillingService() {
        this.paymentDAO = new PaymentDAO();
        this.reservationDAO = new ReservationDAO();
        this.config = AppConfig.getInstance();
    }
    
    /**
     * Process payment for a reservation
     * @param reservationId Reservation ID
     * @param paymentMethod Payment method
     * @param transactionId Transaction ID (optional)
     * @return Payment ID if successful, -1 if failed
     */
    public int processPayment(int reservationId, Payment.PaymentMethod paymentMethod, String transactionId) {
        try {
            // Get reservation
            Optional<Reservation> resOpt = reservationDAO.findById(reservationId);
            
            if (resOpt.isEmpty()) {
                logger.warn("Payment processing failed: Reservation not found - ID: {}", reservationId);
                return -1;
            }
            
            Reservation reservation = resOpt.get();
            
            // Check if reservation can be paid
            if (reservation.isCancelled()) {
                logger.warn("Payment processing failed: Reservation is cancelled - ID: {}", reservationId);
                return -2;
            }
            
            // Create payment
            Payment payment = new Payment();
            payment.setReservationId(reservationId);
            payment.setPaymentNumber(generatePaymentNumber());
            payment.setAmount(reservation.getFinalAmount());
            payment.setPaymentMethod(paymentMethod);
            payment.setPaymentStatus(Payment.PaymentStatus.COMPLETED);
            payment.setTransactionId(transactionId);
            payment.setPaymentDate(LocalDateTime.now());
            
            int paymentId = paymentDAO.create(payment);
            
            if (paymentId > 0) {
                logger.info("Payment processed successfully: Payment ID={}, Reservation ID={}", 
                           paymentId, reservationId);
            }
            
            return paymentId;
            
        } catch (SQLException e) {
            logger.error("Error processing payment for reservation ID: {}", reservationId, e);
            return -3;
        }
    }
    
    /**
     * Create payment record
     * @param payment Payment object
     * @return Payment ID if successful
     */
    public int createPayment(Payment payment) {
        try {
            // Generate payment number if not set
            if (payment.getPaymentNumber() == null || payment.getPaymentNumber().isEmpty()) {
                payment.setPaymentNumber(generatePaymentNumber());
            }
            
            int paymentId = paymentDAO.create(payment);
            
            if (paymentId > 0) {
                logger.info("Payment created successfully: {}", payment.getPaymentNumber());
            }
            
            return paymentId;
            
        } catch (SQLException e) {
            logger.error("Error creating payment", e);
            return -1;
        }
    }
    
    /**
     * Update payment status
     * @param paymentId Payment ID
     * @param status New status
     * @return true if successful
     */
    public boolean updatePaymentStatus(int paymentId, Payment.PaymentStatus status) {
        try {
            boolean success = paymentDAO.updateStatus(paymentId, status);
            
            if (success) {
                logger.info("Payment status updated: ID={}, status={}", paymentId, status);
            }
            
            return success;
            
        } catch (SQLException e) {
            logger.error("Error updating payment status: ID={}", paymentId, e);
            return false;
        }
    }
    
    /**
     * Get payment by ID
     * @param paymentId Payment ID
     * @return Optional Payment
     */
    public Optional<Payment> getPaymentById(int paymentId) {
        try {
            return paymentDAO.findById(paymentId);
        } catch (SQLException e) {
            logger.error("Error getting payment by ID: {}", paymentId, e);
            return Optional.empty();
        }
    }
    
    /**
     * Get payments for a reservation
     * @param reservationId Reservation ID
     * @return List of payments
     */
    public List<Payment> getPaymentsByReservation(int reservationId) {
        try {
            return paymentDAO.findByReservationId(reservationId);
        } catch (SQLException e) {
            logger.error("Error getting payments by reservation: {}", reservationId, e);
            return List.of();
        }
    }
    
    /**
     * Get all payments
     * @return List of payments
     */
    public List<Payment> getAllPayments() {
        try {
            return paymentDAO.findAll();
        } catch (SQLException e) {
            logger.error("Error getting all payments", e);
            return List.of();
        }
    }
    
    /**
     * Get total revenue
     * @return Total revenue amount
     */
    public double getTotalRevenue() {
        try {
            return paymentDAO.getTotalRevenue();
        } catch (SQLException e) {
            logger.error("Error getting total revenue", e);
            return 0.0;
        }
    }
    
    /**
     * Calculate bill for a reservation
     * @param reservationId Reservation ID
     * @return Reservation with calculated amounts
     */
    public Optional<Reservation> calculateBill(int reservationId) {
        try {
            Optional<Reservation> resOpt = reservationDAO.findById(reservationId);
            
            if (resOpt.isPresent()) {
                Reservation reservation = resOpt.get();
                logger.info("Bill calculated for reservation: {}", reservation.getReservationNumber());
                return Optional.of(reservation);
            }
            
            return Optional.empty();
            
        } catch (SQLException e) {
            logger.error("Error calculating bill for reservation ID: {}", reservationId, e);
            return Optional.empty();
        }
    }
    
    /**
     * Generate unique payment number
     * Format: PAY-YYYY-XXXX
     * @return Payment number
     */
    private String generatePaymentNumber() {
        String year = LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyy"));
        long timestamp = System.currentTimeMillis() % 10000;
        return String.format("PAY-%s-%04d", year, timestamp);
    }
    
    /**
     * Refund payment
     * @param paymentId Payment ID
     * @return true if successful
     */
    public boolean refundPayment(int paymentId) {
        try {
            Optional<Payment> paymentOpt = paymentDAO.findById(paymentId);
            
            if (paymentOpt.isEmpty()) {
                logger.warn("Refund failed: Payment not found - ID: {}", paymentId);
                return false;
            }
            
            Payment payment = paymentOpt.get();
            
            if (!payment.isCompleted()) {
                logger.warn("Refund failed: Payment not completed - ID: {}", paymentId);
                return false;
            }
            
            boolean success = paymentDAO.updateStatus(paymentId, Payment.PaymentStatus.REFUNDED);
            
            if (success) {
                logger.info("Payment refunded: ID={}", paymentId);
            }
            
            return success;
            
        } catch (SQLException e) {
            logger.error("Error refunding payment: ID={}", paymentId, e);
            return false;
        }
    }
}
