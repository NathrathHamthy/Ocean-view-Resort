package com.oceanview.service;

import com.oceanview.dao.UserDAO;
import com.oceanview.model.User;
import com.oceanview.util.PasswordUtil;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.sql.SQLException;
import java.util.Optional;

/**
 * Authentication Service
 * Handles user authentication and registration
 * 
 * @author Ocean View Resort Development Team
 * @version 1.0.0
 */
public class AuthenticationService {
    
    private static final Logger logger = LoggerFactory.getLogger(AuthenticationService.class);
    private final UserDAO userDAO;
    
    /**
     * Constructor
     */
    public AuthenticationService() {
        this.userDAO = new UserDAO();
    }
    
    /**
     * Authenticate user with username or email and password
     * @param usernameOrEmail Username or email address
     * @param password Plain text password
     * @return Optional User if authentication successful
     */
    public Optional<User> authenticate(String usernameOrEmail, String password) {
        try {
            // Find user by username first
            Optional<User> userOpt = userDAO.findByUsername(usernameOrEmail);
            
            // If not found by username, try email
            if (userOpt.isEmpty()) {
                userOpt = userDAO.findByEmail(usernameOrEmail);
            }
            
            if (userOpt.isEmpty()) {
                logger.warn("Authentication failed: User not found - {}", usernameOrEmail);
                return Optional.empty();
            }
            
            User user = userOpt.get();
            
            // Check if user is active
            if (!user.isActive()) {
                logger.warn("Authentication failed: User not active - {}", usernameOrEmail);
                return Optional.empty();
            }
            
            // Verify password
            if (PasswordUtil.verifyPassword(password, user.getPassword())) {
                // Update last login timestamp
                userDAO.updateLastLogin(user.getUserId());
                logger.info("Authentication successful for user: {}", usernameOrEmail);
                return Optional.of(user);
            } else {
                logger.warn("Authentication failed: Invalid password for user - {}", usernameOrEmail);
                return Optional.empty();
            }
            
        } catch (SQLException e) {
            logger.error("Error during authentication for user: {}", usernameOrEmail, e);
            return Optional.empty();
        }
    }
    
    /**
     * Register a new user
     * @param user User object with plain text password
     * @return User ID if successful, -1 if failed
     */
    public int register(User user) {
        try {
            // Check if username already exists
            if (userDAO.existsByUsername(user.getUsername())) {
                logger.warn("Registration failed: Username already exists - {}", user.getUsername());
                return -1;
            }
            
            // Check if email already exists
            if (userDAO.existsByEmail(user.getEmail())) {
                logger.warn("Registration failed: Email already exists - {}", user.getEmail());
                return -2;
            }
            
            // Hash the password
            String hashedPassword = PasswordUtil.hashPassword(user.getPassword());
            user.setPassword(hashedPassword);
            
            // Create user
            int userId = userDAO.create(user);
            logger.info("User registered successfully: {} with ID: {}", user.getUsername(), userId);
            
            return userId;
            
        } catch (SQLException e) {
            logger.error("Error during registration for user: {}", user.getUsername(), e);
            return -3;
        }
    }
    
    /**
     * Change user password
     * @param userId User ID
     * @param oldPassword Current password
     * @param newPassword New password
     * @return true if successful
     */
    public boolean changePassword(int userId, String oldPassword, String newPassword) {
        try {
            // Get user
            Optional<User> userOpt = userDAO.findById(userId);
            
            if (userOpt.isEmpty()) {
                logger.warn("Password change failed: User not found - ID: {}", userId);
                return false;
            }
            
            User user = userOpt.get();
            
            // Verify old password
            if (!PasswordUtil.verifyPassword(oldPassword, user.getPassword())) {
                logger.warn("Password change failed: Invalid old password for user ID: {}", userId);
                return false;
            }
            
            // Hash new password
            String hashedPassword = PasswordUtil.hashPassword(newPassword);
            
            // Update password
            boolean success = userDAO.updatePassword(userId, hashedPassword);
            
            if (success) {
                logger.info("Password changed successfully for user ID: {}", userId);
            }
            
            return success;
            
        } catch (SQLException e) {
            logger.error("Error during password change for user ID: {}", userId, e);
            return false;
        }
    }
    
    /**
     * Reset user password (admin function)
     * @param userId User ID
     * @param newPassword New password
     * @return true if successful
     */
    public boolean resetPassword(int userId, String newPassword) {
        try {
            // Hash new password
            String hashedPassword = PasswordUtil.hashPassword(newPassword);
            
            // Update password
            boolean success = userDAO.updatePassword(userId, hashedPassword);
            
            if (success) {
                logger.info("Password reset successfully for user ID: {}", userId);
            }
            
            return success;
            
        } catch (SQLException e) {
            logger.error("Error during password reset for user ID: {}", userId, e);
            return false;
        }
    }
    
    /**
     * Check if username is available
     * @param username Username to check
     * @return true if available
     */
    public boolean isUsernameAvailable(String username) {
        try {
            return !userDAO.existsByUsername(username);
        } catch (SQLException e) {
            logger.error("Error checking username availability: {}", username, e);
            return false;
        }
    }
    
    /**
     * Check if email is available
     * @param email Email to check
     * @return true if available
     */
    public boolean isEmailAvailable(String email) {
        try {
            return !userDAO.existsByEmail(email);
        } catch (SQLException e) {
            logger.error("Error checking email availability: {}", email, e);
            return false;
        }
    }
}
