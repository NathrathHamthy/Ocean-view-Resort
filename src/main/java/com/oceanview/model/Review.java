package com.oceanview.model;

import java.io.Serializable;
import java.time.LocalDateTime;
import java.util.Objects;

/**
 * Review Entity - Represents a guest review
 * 
 * @author Ocean View Resort Development Team
 * @version 1.0.0
 */
public class Review implements Serializable {
    
    private static final long serialVersionUID = 1L;
    
    // Review Status Enum
    public enum ReviewStatus {
        PENDING, APPROVED, REJECTED
    }
    
    // Fields
    private Integer reviewId;
    private Integer reservationId;
    private Integer guestId;
    private Integer rating;
    private Integer cleanlinessRating;
    private Integer serviceRating;
    private Integer valueRating;
    private String comment;
    private String response;
    private ReviewStatus status;
    private LocalDateTime createdAt;
    
    // Associated objects
    private Reservation reservation;
    private Guest guest;
    
    // Constructors
    public Review() {
        this.status = ReviewStatus.PENDING;
        this.createdAt = LocalDateTime.now();
    }
    
    public Review(Integer reservationId, Integer guestId, Integer rating) {
        this();
        this.reservationId = reservationId;
        this.guestId = guestId;
        this.rating = rating;
    }
    
    // Getters and Setters
    public Integer getReviewId() {
        return reviewId;
    }
    
    public void setReviewId(Integer reviewId) {
        this.reviewId = reviewId;
    }
    
    public Integer getReservationId() {
        return reservationId;
    }
    
    public void setReservationId(Integer reservationId) {
        this.reservationId = reservationId;
    }
    
    public Integer getGuestId() {
        return guestId;
    }
    
    public void setGuestId(Integer guestId) {
        this.guestId = guestId;
    }
    
    public Integer getRating() {
        return rating;
    }
    
    public void setRating(Integer rating) {
        if (rating < 1 || rating > 5) {
            throw new IllegalArgumentException("Rating must be between 1 and 5");
        }
        this.rating = rating;
    }
    
    public Integer getCleanlinessRating() {
        return cleanlinessRating;
    }
    
    public void setCleanlinessRating(Integer cleanlinessRating) {
        this.cleanlinessRating = cleanlinessRating;
    }
    
    public Integer getServiceRating() {
        return serviceRating;
    }
    
    public void setServiceRating(Integer serviceRating) {
        this.serviceRating = serviceRating;
    }
    
    public Integer getValueRating() {
        return valueRating;
    }
    
    public void setValueRating(Integer valueRating) {
        this.valueRating = valueRating;
    }
    
    public String getComment() {
        return comment;
    }
    
    public void setComment(String comment) {
        this.comment = comment;
    }
    
    public String getResponse() {
        return response;
    }
    
    public void setResponse(String response) {
        this.response = response;
    }
    
    public ReviewStatus getStatus() {
        return status;
    }
    
    public void setStatus(ReviewStatus status) {
        this.status = status;
    }
    
    public LocalDateTime getCreatedAt() {
        return createdAt;
    }
    
    public void setCreatedAt(LocalDateTime createdAt) {
        this.createdAt = createdAt;
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
    
    public Guest getGuest() {
        return guest;
    }
    
    public void setGuest(Guest guest) {
        this.guest = guest;
        if (guest != null) {
            this.guestId = guest.getGuestId();
        }
    }
    
    // Business Methods
    public boolean isPending() {
        return ReviewStatus.PENDING.equals(this.status);
    }
    
    public boolean isApproved() {
        return ReviewStatus.APPROVED.equals(this.status);
    }
    
    public boolean isRejected() {
        return ReviewStatus.REJECTED.equals(this.status);
    }
    
    public double getAverageRating() {
        int count = 1; // Overall rating always counted
        int sum = rating != null ? rating : 0;
        
        if (cleanlinessRating != null) {
            sum += cleanlinessRating;
            count++;
        }
        if (serviceRating != null) {
            sum += serviceRating;
            count++;
        }
        if (valueRating != null) {
            sum += valueRating;
            count++;
        }
        
        return count > 0 ? (double) sum / count : 0.0;
    }
    
    public String getStarRating() {
        StringBuilder stars = new StringBuilder();
        int fullStars = rating != null ? rating : 0;
        for (int i = 0; i < 5; i++) {
            stars.append(i < fullStars ? "★" : "☆");
        }
        return stars.toString();
    }
    
    public boolean hasResponse() {
        return response != null && !response.trim().isEmpty();
    }
    
    // equals and hashCode
    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (o == null || getClass() != o.getClass()) return false;
        Review review = (Review) o;
        return Objects.equals(reviewId, review.reviewId);
    }
    
    @Override
    public int hashCode() {
        return Objects.hash(reviewId);
    }
    
    // toString
    @Override
    public String toString() {
        return "Review{" +
                "reviewId=" + reviewId +
                ", reservationId=" + reservationId +
                ", guestId=" + guestId +
                ", rating=" + rating +
                ", status=" + status +
                ", createdAt=" + createdAt +
                '}';
    }
}
