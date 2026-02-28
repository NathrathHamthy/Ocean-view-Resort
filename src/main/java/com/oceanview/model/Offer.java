package com.oceanview.model;

import java.io.Serializable;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.Objects;

/**
 * Offer Entity - Represents a promotional offer
 * 
 * @author Ocean View Resort Development Team
 * @version 1.0.0
 */
public class Offer implements Serializable {
    
    private static final long serialVersionUID = 1L;
    
    // Discount Type Enum
    public enum DiscountType {
        PERCENTAGE, FIXED
    }
    
    // Offer Status Enum
    public enum OfferStatus {
        ACTIVE, INACTIVE, EXPIRED, SCHEDULED
    }
    
    // Fields
    private Integer offerId;
    private String title;
    private String offerName; // Alias for title
    private String description;
    private DiscountType discountType;
    private BigDecimal discountValue;
    private LocalDate startDate;
    private LocalDate endDate;
    private String applicableRooms;
    private Integer minNights;
    private Integer minStayNights; // Alias for minNights
    private String promoCode;
    private Integer usedCount;
    private Integer maxUses;
    private OfferStatus status;
    private OfferStatus offerStatus; // Alias for status
    private LocalDateTime createdAt;
    
    // Constructors
    public Offer() {
        this.status = OfferStatus.ACTIVE;
        this.offerStatus = OfferStatus.ACTIVE;
        this.createdAt = LocalDateTime.now();
        this.discountValue = BigDecimal.ZERO;
        this.minNights = 1;
        this.minStayNights = 1;
        this.usedCount = 0;
    }
    
    public Offer(String title, DiscountType discountType, BigDecimal discountValue, 
                 LocalDate startDate, LocalDate endDate) {
        this();
        this.title = title;
        this.discountType = discountType;
        this.discountValue = discountValue;
        this.startDate = startDate;
        this.endDate = endDate;
    }
    
    // Getters and Setters
    public Integer getOfferId() {
        return offerId;
    }
    
    public void setOfferId(Integer offerId) {
        this.offerId = offerId;
    }
    
    public String getTitle() {
        return title;
    }
    
    public void setTitle(String title) {
        this.title = title;
        this.offerName = title; // Keep in sync
    }
    
    public String getOfferName() {
        return offerName != null ? offerName : title;
    }
    
    public void setOfferName(String offerName) {
        this.offerName = offerName;
        this.title = offerName; // Keep in sync
    }
    
    public String getDescription() {
        return description;
    }
    
    public void setDescription(String description) {
        this.description = description;
    }
    
    public DiscountType getDiscountType() {
        return discountType;
    }
    
    public void setDiscountType(DiscountType discountType) {
        this.discountType = discountType;
    }
    
    public BigDecimal getDiscountValue() {
        return discountValue;
    }
    
    public void setDiscountValue(BigDecimal discountValue) {
        this.discountValue = discountValue;
    }
    
    public LocalDate getStartDate() {
        return startDate;
    }
    
    public void setStartDate(LocalDate startDate) {
        this.startDate = startDate;
    }
    
    public LocalDate getEndDate() {
        return endDate;
    }
    
    public void setEndDate(LocalDate endDate) {
        this.endDate = endDate;
    }
    
    public String getApplicableRooms() {
        return applicableRooms;
    }
    
    public void setApplicableRooms(String applicableRooms) {
        this.applicableRooms = applicableRooms;
    }
    
    public Integer getMinNights() {
        return minNights;
    }
    
    public void setMinNights(Integer minNights) {
        this.minNights = minNights;
        this.minStayNights = minNights; // Keep in sync
    }
    
    public Integer getMinStayNights() {
        return minStayNights != null ? minStayNights : minNights;
    }
    
    public void setMinStayNights(Integer minStayNights) {
        this.minStayNights = minStayNights;
        this.minNights = minStayNights; // Keep in sync
    }
    
    public String getPromoCode() {
        return promoCode;
    }
    
    public void setPromoCode(String promoCode) {
        this.promoCode = promoCode;
    }
    
    public Integer getUsedCount() {
        return usedCount != null ? usedCount : 0;
    }
    
    public void setUsedCount(Integer usedCount) {
        this.usedCount = usedCount;
    }
    
    public Integer getMaxUses() {
        return maxUses;
    }
    
    public void setMaxUses(Integer maxUses) {
        this.maxUses = maxUses;
    }
    
    public OfferStatus getStatus() {
        return status;
    }
    
    public void setStatus(OfferStatus status) {
        this.status = status;
        this.offerStatus = status; // Keep in sync
    }
    
    public OfferStatus getOfferStatus() {
        return offerStatus != null ? offerStatus : status;
    }
    
    public void setOfferStatus(OfferStatus offerStatus) {
        this.offerStatus = offerStatus;
        this.status = offerStatus; // Keep in sync
    }
    
    public LocalDateTime getCreatedAt() {
        return createdAt;
    }
    
    public void setCreatedAt(LocalDateTime createdAt) {
        this.createdAt = createdAt;
    }
    
    // Business Methods
    public boolean isActive() {
        return OfferStatus.ACTIVE.equals(this.status) && isValidDate();
    }
    
    public boolean isExpired() {
        return OfferStatus.EXPIRED.equals(this.status) || 
               (endDate != null && endDate.isBefore(LocalDate.now()));
    }
    
    public boolean isValidDate() {
        LocalDate now = LocalDate.now();
        return (startDate == null || !now.isBefore(startDate)) &&
               (endDate == null || !now.isAfter(endDate));
    }
    
    public boolean isPercentageDiscount() {
        return DiscountType.PERCENTAGE.equals(this.discountType);
    }
    
    public boolean isFixedDiscount() {
        return DiscountType.FIXED.equals(this.discountType);
    }
    
    public BigDecimal calculateDiscount(BigDecimal amount) {
        if (isPercentageDiscount()) {
            return amount.multiply(discountValue).divide(BigDecimal.valueOf(100));
        } else {
            return discountValue;
        }
    }
    
    public boolean isApplicableToRoom(String roomType) {
        if (applicableRooms == null || applicableRooms.isEmpty()) {
            return true; // Applicable to all rooms
        }
        return applicableRooms.contains(roomType);
    }
    
    public boolean meetsMinimumNights(int nights) {
        return nights >= minNights;
    }
    
    public String getDiscountDescription() {
        if (isPercentageDiscount()) {
            return discountValue.stripTrailingZeros().toPlainString() + "% off";
        } else {
            return "Rs. " + discountValue.stripTrailingZeros().toPlainString() + " off";
        }
    }
    
    // equals and hashCode
    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (o == null || getClass() != o.getClass()) return false;
        Offer offer = (Offer) o;
        return Objects.equals(offerId, offer.offerId);
    }
    
    @Override
    public int hashCode() {
        return Objects.hash(offerId);
    }
    
    // toString
    @Override
    public String toString() {
        return "Offer{" +
                "offerId=" + offerId +
                ", title='" + title + '\'' +
                ", discountType=" + discountType +
                ", discountValue=" + discountValue +
                ", startDate=" + startDate +
                ", endDate=" + endDate +
                ", status=" + status +
                '}';
    }
}
