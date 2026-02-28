package com.oceanview.util;

import org.mindrot.jbcrypt.BCrypt;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * Password Utility
 * Handles password hashing and verification using BCrypt
 * 
 * @author Ocean View Resort Development Team
 * @version 1.0.0
 */
public class PasswordUtil {
    
    private static final Logger logger = LoggerFactory.getLogger(PasswordUtil.class);
    private static final int BCRYPT_ROUNDS = 12;
    
    // Private constructor to prevent instantiation
    private PasswordUtil() {
        throw new IllegalStateException("Utility class");
    }
    
    /**
     * Hash a plain text password using BCrypt
     * @param plainPassword Plain text password
     * @return Hashed password
     */
    public static String hashPassword(String plainPassword) {
        try {
            String hashed = BCrypt.hashpw(plainPassword, BCrypt.gensalt(BCRYPT_ROUNDS));
            logger.debug("Password hashed successfully");
            return hashed;
        } catch (Exception e) {
            logger.error("Error hashing password", e);
            throw new RuntimeException("Failed to hash password", e);
        }
    }
    
    /**
     * Verify a plain text password against a hashed password
     * @param plainPassword Plain text password
     * @param hashedPassword Hashed password from database
     * @return true if passwords match
     */
    public static boolean verifyPassword(String plainPassword, String hashedPassword) {
        try {
            boolean matches = BCrypt.checkpw(plainPassword, hashedPassword);
            logger.debug("Password verification: {}", matches ? "success" : "failed");
            return matches;
        } catch (Exception e) {
            logger.error("Error verifying password", e);
            return false;
        }
    }
    
    /**
     * Check if a password needs rehashing (if algorithm updated)
     * @param hashedPassword Hashed password
     * @return true if needs rehashing
     */
    public static boolean needsRehash(String hashedPassword) {
        // BCrypt format: $2a$rounds$salt+hash
        // Check if using current round configuration
        String currentPrefix = "$2a$" + BCRYPT_ROUNDS + "$";
        return !hashedPassword.startsWith(currentPrefix);
    }
}
