package com.oceanview.model;

import java.io.Serializable;
import java.time.LocalDateTime;
import java.util.Objects;

/**
 * User Entity - Represents a system user
 * Supports three roles: ADMIN, STAFF, GUEST
 * 
 * @author Ocean View Resort Development Team
 * @version 1.0.0
 */
public class User implements Serializable {
    
    private static final long serialVersionUID = 1L;
    
    // User Role Enum
    public enum Role {
        ADMIN, STAFF, GUEST
    }
    
    // User Status Enum
    public enum Status {
        ACTIVE, INACTIVE, SUSPENDED
    }
    
    // Fields
    private Integer userId;
    private String username;
    private String password;
    private String email;
    private String fullName;
    private String firstName;
    private String lastName;
    private String phone;
    private Role role;
    private Status status;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
    private LocalDateTime lastLogin;
    
    // Constructors
    public User() {
        this.role = Role.GUEST;
        this.status = Status.ACTIVE;
        this.createdAt = LocalDateTime.now();
    }
    
    public User(String username, String password, String email, String fullName, Role role) {
        this();
        this.username = username;
        this.password = password;
        this.email = email;
        this.fullName = fullName;
        this.role = role;
    }
    
    // Getters and Setters
    public Integer getUserId() {
        return userId;
    }
    
    public void setUserId(Integer userId) {
        this.userId = userId;
    }
    
    public String getUsername() {
        return username;
    }
    
    public void setUsername(String username) {
        this.username = username;
    }
    
    public String getPassword() {
        return password;
    }
    
    public void setPassword(String password) {
        this.password = password;
    }
    
    public String getEmail() {
        return email;
    }
    
    public void setEmail(String email) {
        this.email = email;
    }
    
    public String getFullName() {
        return fullName;
    }
    
    public void setFullName(String fullName) {
        this.fullName = fullName;
        // Auto-populate firstName and lastName from fullName if needed
        if (fullName != null && fullName.contains(" ")) {
            String[] parts = fullName.split(" ", 2);
            this.firstName = parts[0];
            this.lastName = parts[1];
        }
    }
    
    public String getFirstName() {
        return firstName != null ? firstName : (fullName != null && fullName.contains(" ") ? fullName.split(" ")[0] : fullName);
    }
    
    public void setFirstName(String firstName) {
        this.firstName = firstName;
    }
    
    public String getLastName() {
        return lastName != null ? lastName : (fullName != null && fullName.contains(" ") ? fullName.substring(fullName.indexOf(" ") + 1) : "");
    }
    
    public void setLastName(String lastName) {
        this.lastName = lastName;
    }
    
    public String getPhone() {
        return phone;
    }
    
    public void setPhone(String phone) {
        this.phone = phone;
    }
    
    public Role getRole() {
        return role;
    }
    
    public void setRole(Role role) {
        this.role = role;
    }
    
    public Status getStatus() {
        return status;
    }
    
    public void setStatus(Status status) {
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
    
    public LocalDateTime getLastLogin() {
        return lastLogin;
    }
    
    public void setLastLogin(LocalDateTime lastLogin) {
        this.lastLogin = lastLogin;
    }
    
    // Business Methods
    public boolean isAdmin() {
        return Role.ADMIN.equals(this.role);
    }
    
    public boolean isStaff() {
        return Role.STAFF.equals(this.role);
    }
    
    public boolean isGuest() {
        return Role.GUEST.equals(this.role);
    }
    
    public boolean isActive() {
        return Status.ACTIVE.equals(this.status);
    }
    
    public boolean isSuspended() {
        return Status.SUSPENDED.equals(this.status);
    }
    
    // equals and hashCode
    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (o == null || getClass() != o.getClass()) return false;
        User user = (User) o;
        return Objects.equals(userId, user.userId) &&
               Objects.equals(username, user.username);
    }
    
    @Override
    public int hashCode() {
        return Objects.hash(userId, username);
    }
    
    // toString
    @Override
    public String toString() {
        return "User{" +
                "userId=" + userId +
                ", username='" + username + '\'' +
                ", email='" + email + '\'' +
                ", fullName='" + fullName + '\'' +
                ", role=" + role +
                ", status=" + status +
                '}';
    }
}
