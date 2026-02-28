package com.oceanview.model;

import java.io.Serializable;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.Objects;

/**
 * Guest Entity - Extended information for guest users
 * 
 * @author Ocean View Resort Development Team
 * @version 1.0.0
 */
public class Guest implements Serializable {
    
    private static final long serialVersionUID = 1L;
    
    // Gender Enum
    public enum Gender {
        MALE, FEMALE, OTHER
    }
    
    // Fields
    private Integer guestId;
    private Integer userId;
    private String address;
    private String city;
    private String country;
    private String postalCode;
    private String idType;
    private String idNumber;
    private LocalDate dateOfBirth;
    private Gender gender;
    private String preferences;
    private LocalDateTime createdAt;
    
    // Associated User object
    private User user;
    
    // Constructors
    public Guest() {
        this.createdAt = LocalDateTime.now();
    }
    
    public Guest(Integer userId) {
        this();
        this.userId = userId;
    }
    
    // Getters and Setters
    public Integer getGuestId() {
        return guestId;
    }
    
    public void setGuestId(Integer guestId) {
        this.guestId = guestId;
    }
    
    public Integer getUserId() {
        return userId;
    }
    
    public void setUserId(Integer userId) {
        this.userId = userId;
    }
    
    public String getAddress() {
        return address;
    }
    
    public void setAddress(String address) {
        this.address = address;
    }
    
    public String getCity() {
        return city;
    }
    
    public void setCity(String city) {
        this.city = city;
    }
    
    public String getCountry() {
        return country;
    }
    
    public void setCountry(String country) {
        this.country = country;
    }
    
    public String getPostalCode() {
        return postalCode;
    }
    
    public void setPostalCode(String postalCode) {
        this.postalCode = postalCode;
    }
    
    public String getIdType() {
        return idType;
    }
    
    public void setIdType(String idType) {
        this.idType = idType;
    }
    
    public String getIdNumber() {
        return idNumber;
    }
    
    public void setIdNumber(String idNumber) {
        this.idNumber = idNumber;
    }
    
    public LocalDate getDateOfBirth() {
        return dateOfBirth;
    }
    
    public void setDateOfBirth(LocalDate dateOfBirth) {
        this.dateOfBirth = dateOfBirth;
    }
    
    public Gender getGender() {
        return gender;
    }
    
    public void setGender(Gender gender) {
        this.gender = gender;
    }
    
    public String getPreferences() {
        return preferences;
    }
    
    public void setPreferences(String preferences) {
        this.preferences = preferences;
    }
    
    public LocalDateTime getCreatedAt() {
        return createdAt;
    }
    
    public void setCreatedAt(LocalDateTime createdAt) {
        this.createdAt = createdAt;
    }
    
    public User getUser() {
        return user;
    }
    
    public void setUser(User user) {
        this.user = user;
        if (user != null) {
            this.userId = user.getUserId();
        }
    }
    
    // Transient fields for display purposes (not persisted)
    private transient String firstName;
    private transient String lastName;
    
    // Getters and setters for transient fields
    public String getFirstName() {
        return firstName;
    }
    
    public void setFirstName(String firstName) {
        this.firstName = firstName;
    }
    
    public String getLastName() {
        return lastName;
    }
    
    public void setLastName(String lastName) {
        this.lastName = lastName;
    }
    
    // Business Methods
    public int getAge() {
        if (dateOfBirth == null) {
            return 0;
        }
        return LocalDate.now().getYear() - dateOfBirth.getYear();
    }
    
    public String getFullAddress() {
        StringBuilder sb = new StringBuilder();
        if (address != null) sb.append(address);
        if (city != null) sb.append(", ").append(city);
        if (country != null) sb.append(", ").append(country);
        if (postalCode != null) sb.append(" ").append(postalCode);
        return sb.toString();
    }
    
    // equals and hashCode
    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (o == null || getClass() != o.getClass()) return false;
        Guest guest = (Guest) o;
        return Objects.equals(guestId, guest.guestId);
    }
    
    @Override
    public int hashCode() {
        return Objects.hash(guestId);
    }
    
    // toString
    @Override
    public String toString() {
        return "Guest{" +
                "guestId=" + guestId +
                ", userId=" + userId +
                ", city='" + city + '\'' +
                ", country='" + country + '\'' +
                ", idType='" + idType + '\'' +
                ", gender=" + gender +
                '}';
    }
}
