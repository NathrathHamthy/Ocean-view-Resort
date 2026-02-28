package com.oceanview.model;

import java.io.Serializable;
import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.Objects;

/**
 * Room Entity - Represents a hotel room
 * 
 * @author Ocean View Resort Development Team
 * @version 1.0.0
 */
public class Room implements Serializable {
    
    private static final long serialVersionUID = 1L;
    
    // Room Type Enum
    public enum RoomType {
        SINGLE, DOUBLE, DELUXE, SUITE, FAMILY
    }
    
    // Room Status Enum
    public enum RoomStatus {
        AVAILABLE, OCCUPIED, MAINTENANCE, RESERVED
    }
    
    // Fields
    private Integer roomId;
    private String roomNumber;
    private RoomType roomType;
    private Integer floor;
    private Integer capacity;
    private BigDecimal pricePerNight;
    private Integer size; // Room size in square meters
    private String description;
    private String amenities;
    private String imageUrl;
    private RoomStatus status;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
    
    // Constructors
    public Room() {
        this.status = RoomStatus.AVAILABLE;
        this.createdAt = LocalDateTime.now();
        this.pricePerNight = BigDecimal.ZERO;
    }
    
    public Room(String roomNumber, RoomType roomType, Integer floor, 
                Integer capacity, BigDecimal pricePerNight) {
        this();
        this.roomNumber = roomNumber;
        this.roomType = roomType;
        this.floor = floor;
        this.capacity = capacity;
        this.pricePerNight = pricePerNight;
    }
    
    // Getters and Setters
    public Integer getRoomId() {
        return roomId;
    }
    
    public void setRoomId(Integer roomId) {
        this.roomId = roomId;
    }
    
    public String getRoomNumber() {
        return roomNumber;
    }
    
    public void setRoomNumber(String roomNumber) {
        this.roomNumber = roomNumber;
    }
    
    public RoomType getRoomType() {
        return roomType;
    }
    
    public void setRoomType(RoomType roomType) {
        this.roomType = roomType;
    }
    
    public Integer getFloor() {
        return floor;
    }
    
    public void setFloor(Integer floor) {
        this.floor = floor;
    }
    
    public Integer getCapacity() {
        return capacity;
    }
    
    public void setCapacity(Integer capacity) {
        this.capacity = capacity;
    }
    
    public BigDecimal getPricePerNight() {
        return pricePerNight;
    }
    
    public void setPricePerNight(BigDecimal pricePerNight) {
        this.pricePerNight = pricePerNight;
    }
    
    public Integer getSize() {
        return size;
    }
    
    public void setSize(Integer size) {
        this.size = size;
    }
    
    // Alias method for JSP compatibility
    public Integer getFloorNumber() {
        return floor;
    }
    
    public void setFloorNumber(Integer floorNumber) {
        this.floor = floorNumber;
    }
    
    public String getDescription() {
        return description;
    }
    
    public void setDescription(String description) {
        this.description = description;
    }
    
    public String getAmenities() {
        return amenities;
    }
    
    public void setAmenities(String amenities) {
        this.amenities = amenities;
    }
    
    public String getImageUrl() {
        return imageUrl;
    }
    
    public void setImageUrl(String imageUrl) {
        this.imageUrl = imageUrl;
    }
    
    public RoomStatus getStatus() {
        return status;
    }
    
    public void setStatus(RoomStatus status) {
        this.status = status;
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
    
    // Business Methods
    public boolean isAvailable() {
        return RoomStatus.AVAILABLE.equals(this.status);
    }
    
    public boolean isOccupied() {
        return RoomStatus.OCCUPIED.equals(this.status);
    }
    
    public boolean isReserved() {
        return RoomStatus.RESERVED.equals(this.status);
    }
    
    public boolean isUnderMaintenance() {
        return RoomStatus.MAINTENANCE.equals(this.status);
    }
    
    public String getRoomTypeName() {
        return roomType != null ? roomType.name() : "";
    }
    
    public String getStatusName() {
        return status != null ? status.name() : "";
    }
    
    public BigDecimal calculatePrice(int nights) {
        return pricePerNight.multiply(BigDecimal.valueOf(nights));
    }
    
    // equals and hashCode
    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (o == null || getClass() != o.getClass()) return false;
        Room room = (Room) o;
        return Objects.equals(roomId, room.roomId) &&
               Objects.equals(roomNumber, room.roomNumber);
    }
    
    @Override
    public int hashCode() {
        return Objects.hash(roomId, roomNumber);
    }
    
    // toString
    @Override
    public String toString() {
        return "Room{" +
                "roomId=" + roomId +
                ", roomNumber='" + roomNumber + '\'' +
                ", roomType=" + roomType +
                ", floor=" + floor +
                ", capacity=" + capacity +
                ", pricePerNight=" + pricePerNight +
                ", status=" + status +
                '}';
    }
}
