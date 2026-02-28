package com.oceanview.model;

import java.io.Serializable;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.temporal.ChronoUnit;
import java.util.Objects;

/**
 * Reservation Entity - Represents a room booking
 * 
 * @author Ocean View Resort Development Team
 * @version 1.0.0
 */
public class Reservation implements Serializable {
    
    private static final long serialVersionUID = 1L;
    
    // Reservation Status Enum
    public enum ReservationStatus {
        PENDING, CONFIRMED, CHECKED_IN, CHECKED_OUT, CANCELLED
    }
    
    // Fields
    private Integer reservationId;
    private String reservationNumber;
    private Integer guestId;
    private Integer roomId;
    private LocalDate checkInDate;
    private LocalDate checkOutDate;
    private Integer numberOfGuests;
    private Integer numberOfNights;
    private BigDecimal totalAmount;
    private BigDecimal discountAmount;
    private BigDecimal taxAmount;
    private BigDecimal finalAmount;
    private ReservationStatus status;
    private String specialRequests;
    private Integer createdBy;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
    
    // Associated objects
    private Guest guest;
    private Room room;
    private User createdByUser;
    
    // Constructors
    public Reservation() {
        this.status = ReservationStatus.PENDING;
        this.createdAt = LocalDateTime.now();
        this.totalAmount = BigDecimal.ZERO;
        this.discountAmount = BigDecimal.ZERO;
        this.taxAmount = BigDecimal.ZERO;
        this.finalAmount = BigDecimal.ZERO;
        this.numberOfGuests = 1;
    }
    
    public Reservation(Integer guestId, Integer roomId, LocalDate checkInDate, LocalDate checkOutDate) {
        this();
        this.guestId = guestId;
        this.roomId = roomId;
        this.checkInDate = checkInDate;
        this.checkOutDate = checkOutDate;
        this.numberOfNights = calculateNights();
    }
    
    // Getters and Setters
    public Integer getReservationId() {
        return reservationId;
    }
    
    public void setReservationId(Integer reservationId) {
        this.reservationId = reservationId;
    }
    
    public String getReservationNumber() {
        return reservationNumber;
    }
    
    public void setReservationNumber(String reservationNumber) {
        this.reservationNumber = reservationNumber;
    }
    
    public Integer getGuestId() {
        return guestId;
    }
    
    public void setGuestId(Integer guestId) {
        this.guestId = guestId;
    }
    
    public Integer getRoomId() {
        return roomId;
    }
    
    public void setRoomId(Integer roomId) {
        this.roomId = roomId;
    }
    
    public LocalDate getCheckInDate() {
        return checkInDate;
    }
    
    public void setCheckInDate(LocalDate checkInDate) {
        this.checkInDate = checkInDate;
        this.numberOfNights = calculateNights();
    }
    
    public LocalDate getCheckOutDate() {
        return checkOutDate;
    }
    
    public void setCheckOutDate(LocalDate checkOutDate) {
        this.checkOutDate = checkOutDate;
        this.numberOfNights = calculateNights();
    }
    
    public Integer getNumberOfGuests() {
        return numberOfGuests;
    }
    
    public void setNumberOfGuests(Integer numberOfGuests) {
        this.numberOfGuests = numberOfGuests;
    }
    
    public Integer getNumberOfNights() {
        return numberOfNights;
    }
    
    public void setNumberOfNights(Integer numberOfNights) {
        this.numberOfNights = numberOfNights;
    }
    
    public BigDecimal getTotalAmount() {
        return totalAmount;
    }
    
    public void setTotalAmount(BigDecimal totalAmount) {
        this.totalAmount = totalAmount;
    }
    
    public BigDecimal getDiscountAmount() {
        return discountAmount;
    }
    
    public void setDiscountAmount(BigDecimal discountAmount) {
        this.discountAmount = discountAmount;
    }
    
    public BigDecimal getTaxAmount() {
        return taxAmount;
    }
    
    public void setTaxAmount(BigDecimal taxAmount) {
        this.taxAmount = taxAmount;
    }
    
    public BigDecimal getFinalAmount() {
        return finalAmount;
    }
    
    public void setFinalAmount(BigDecimal finalAmount) {
        this.finalAmount = finalAmount;
    }
    
    public ReservationStatus getStatus() {
        return status;
    }
    
    public void setStatus(ReservationStatus status) {
        this.status = status;
    }
    
    public String getSpecialRequests() {
        return specialRequests;
    }
    
    public void setSpecialRequests(String specialRequests) {
        this.specialRequests = specialRequests;
    }
    
    public Integer getCreatedBy() {
        return createdBy;
    }
    
    public void setCreatedBy(Integer createdBy) {
        this.createdBy = createdBy;
    }
    
    public LocalDateTime getCreatedAt() {
        return createdAt;
    }
    
    public void setCreatedAt(LocalDateTime createdAt) {
        this.createdAt = createdAt;
    }
    
    public LocalDateTime getUpdatedAt() {
        return updatedAt;
    }
    
    public void setUpdatedAt(LocalDateTime updatedAt) {
        this.updatedAt = updatedAt;
    }
    
    public Guest getGuest() {
        return guest;
    }
    
    public void setGuest(Guest guest) {
        this.guest = guest;
        if (guest != null) {
            this.guestId = guest.getGuestId();
        }
    }
    
    public Room getRoom() {
        return room;
    }
    
    public void setRoom(Room room) {
        this.room = room;
        if (room != null) {
            this.roomId = room.getRoomId();
        }
    }
    
    public User getCreatedByUser() {
        return createdByUser;
    }
    
    public void setCreatedByUser(User createdByUser) {
        this.createdByUser = createdByUser;
        if (createdByUser != null) {
            this.createdBy = createdByUser.getUserId();
        }
    }
    
    // Convenience methods for JSP display
    public Integer getId() {
        return reservationId;
    }
    
    public String getGuestName() {
        if (guest != null) {
            return guest.getFirstName() + " " + guest.getLastName();
        }
        return null;
    }
    
    public String getRoomNumber() {
        if (room != null) {
            return room.getRoomNumber();
        }
        return null;
    }
    
    // Business Methods
    private int calculateNights() {
        if (checkInDate != null && checkOutDate != null) {
            return (int) ChronoUnit.DAYS.between(checkInDate, checkOutDate);
        }
        return 0;
    }
    
    public void calculateAmounts(BigDecimal roomPrice, double taxPercentage, double serviceChargePercentage) {
        // Calculate total amount (room price * nights)
        this.totalAmount = roomPrice.multiply(BigDecimal.valueOf(numberOfNights));
        
        // Apply discount
        BigDecimal amountAfterDiscount = this.totalAmount.subtract(this.discountAmount);
        
        // Calculate tax
        BigDecimal taxRate = BigDecimal.valueOf(taxPercentage / 100);
        this.taxAmount = amountAfterDiscount.multiply(taxRate);
        
        // Calculate service charge
        BigDecimal serviceChargeRate = BigDecimal.valueOf(serviceChargePercentage / 100);
        BigDecimal serviceCharge = amountAfterDiscount.multiply(serviceChargeRate);
        
        // Calculate final amount
        this.finalAmount = amountAfterDiscount.add(this.taxAmount).add(serviceCharge);
    }
    
    public boolean isPending() {
        return ReservationStatus.PENDING.equals(this.status);
    }
    
    public boolean isConfirmed() {
        return ReservationStatus.CONFIRMED.equals(this.status);
    }
    
    public boolean isCheckedIn() {
        return ReservationStatus.CHECKED_IN.equals(this.status);
    }
    
    public boolean isCheckedOut() {
        return ReservationStatus.CHECKED_OUT.equals(this.status);
    }
    
    public boolean isCancelled() {
        return ReservationStatus.CANCELLED.equals(this.status);
    }
    
    public boolean isActive() {
        return isConfirmed() || isCheckedIn();
    }
    
    public boolean canCheckIn() {
        return isConfirmed() && !LocalDate.now().isBefore(checkInDate);
    }
    
    public boolean canCheckOut() {
        return isCheckedIn();
    }
    
    public boolean canCancel() {
        return isPending() || isConfirmed();
    }
    
    // equals and hashCode
    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (o == null || getClass() != o.getClass()) return false;
        Reservation that = (Reservation) o;
        return Objects.equals(reservationId, that.reservationId) &&
               Objects.equals(reservationNumber, that.reservationNumber);
    }
    
    @Override
    public int hashCode() {
        return Objects.hash(reservationId, reservationNumber);
    }
    
    // toString
    @Override
    public String toString() {
        return "Reservation{" +
                "reservationId=" + reservationId +
                ", reservationNumber='" + reservationNumber + '\'' +
                ", guestId=" + guestId +
                ", roomId=" + roomId +
                ", checkInDate=" + checkInDate +
                ", checkOutDate=" + checkOutDate +
                ", numberOfNights=" + numberOfNights +
                ", finalAmount=" + finalAmount +
                ", status=" + status +
                '}';
    }
}
