package com.oceanview.model;

import java.io.Serializable;
import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.Objects;

/**
 * Payment Entity - Represents a payment transaction
 * 
 * @author Ocean View Resort Development Team
 * @version 1.0.0
 */
public class Payment implements Serializable {
    
    private static final long serialVersionUID = 1L;
    
    // Payment Method Enum
    public enum PaymentMethod {
        CASH, CARD, BANK_TRANSFER, ONLINE
    }
    
    // Payment Status Enum
    public enum PaymentStatus {
        PENDING, COMPLETED, FAILED, REFUNDED
    }
    
    // Fields
    private Integer paymentId;
    private Integer reservationId;
    private String paymentNumber;
    private BigDecimal amount;
    private PaymentMethod paymentMethod;
    private PaymentStatus paymentStatus;
    private String transactionId;
    private LocalDateTime paymentDate;
    private String notes;
    
    // Associated object
    private Reservation reservation;
    
    // Constructors
    public Payment() {
        this.paymentStatus = PaymentStatus.PENDING;
        this.paymentDate = LocalDateTime.now();
        this.amount = BigDecimal.ZERO;
    }
    
    public Payment(Integer reservationId, BigDecimal amount, PaymentMethod paymentMethod) {
        this();
        this.reservationId = reservationId;
        this.amount = amount;
        this.paymentMethod = paymentMethod;
    }
    
    // Getters and Setters
    public Integer getPaymentId() {
        return paymentId;
    }
    
    public void setPaymentId(Integer paymentId) {
        this.paymentId = paymentId;
    }
    
    public Integer getReservationId() {
        return reservationId;
    }
    
    public void setReservationId(Integer reservationId) {
        this.reservationId = reservationId;
    }
    
    public String getPaymentNumber() {
        return paymentNumber;
    }
    
    public void setPaymentNumber(String paymentNumber) {
        this.paymentNumber = paymentNumber;
    }
    
    public BigDecimal getAmount() {
        return amount;
    }
    
    public void setAmount(BigDecimal amount) {
        this.amount = amount;
    }
    
    public PaymentMethod getPaymentMethod() {
        return paymentMethod;
    }
    
    public void setPaymentMethod(PaymentMethod paymentMethod) {
        this.paymentMethod = paymentMethod;
    }
    
    public PaymentStatus getPaymentStatus() {
        return paymentStatus;
    }
    
    public void setPaymentStatus(PaymentStatus paymentStatus) {
        this.paymentStatus = paymentStatus;
    }
    
    public String getTransactionId() {
        return transactionId;
    }
    
    public void setTransactionId(String transactionId) {
        this.transactionId = transactionId;
    }
    
    public LocalDateTime getPaymentDate() {
        return paymentDate;
    }
    
    public void setPaymentDate(LocalDateTime paymentDate) {
        this.paymentDate = paymentDate;
    }
    
    public String getNotes() {
        return notes;
    }
    
    public void setNotes(String notes) {
        this.notes = notes;
    }
    
    public Reservation getReservation() {
        return reservation;
    }
    
    public void setReservation(Reservation reservation) {
        this.reservation = reservation;
        if (reservation != null) {
            this.reservationId = reservation.getReservationId();
        }
    }
    
    // Business Methods
    public boolean isPending() {
        return PaymentStatus.PENDING.equals(this.paymentStatus);
    }
    
    public boolean isCompleted() {
        return PaymentStatus.COMPLETED.equals(this.paymentStatus);
    }
    
    public boolean isFailed() {
        return PaymentStatus.FAILED.equals(this.paymentStatus);
    }
    
    public boolean isRefunded() {
        return PaymentStatus.REFUNDED.equals(this.paymentStatus);
    }
    
    public boolean isCash() {
        return PaymentMethod.CASH.equals(this.paymentMethod);
    }
    
    public boolean isCard() {
        return PaymentMethod.CARD.equals(this.paymentMethod);
    }
    
    public boolean isOnline() {
        return PaymentMethod.ONLINE.equals(this.paymentMethod);
    }
    
    // equals and hashCode
    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (o == null || getClass() != o.getClass()) return false;
        Payment payment = (Payment) o;
        return Objects.equals(paymentId, payment.paymentId) &&
               Objects.equals(paymentNumber, payment.paymentNumber);
    }
    
    @Override
    public int hashCode() {
        return Objects.hash(paymentId, paymentNumber);
    }
    
    // toString
    @Override
    public String toString() {
        return "Payment{" +
                "paymentId=" + paymentId +
                ", paymentNumber='" + paymentNumber + '\'' +
                ", reservationId=" + reservationId +
                ", amount=" + amount +
                ", paymentMethod=" + paymentMethod +
                ", paymentStatus=" + paymentStatus +
                ", paymentDate=" + paymentDate +
                '}';
    }
}
