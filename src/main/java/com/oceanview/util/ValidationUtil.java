package com.oceanview.util;

import java.time.LocalDate;
import java.util.regex.Pattern;

/**
 * Validation Utility
 * Provides validation methods for various inputs
 * 
 * @author Ocean View Resort Development Team
 * @version 1.0.0
 */
public class ValidationUtil {
    
    // Regex patterns
    private static final Pattern EMAIL_PATTERN = Pattern.compile(Constants.REGEX_EMAIL);
    private static final Pattern PHONE_PATTERN = Pattern.compile(Constants.REGEX_PHONE);
    private static final Pattern USERNAME_PATTERN = Pattern.compile(Constants.REGEX_USERNAME);
    
    // Private constructor to prevent instantiation
    private ValidationUtil() {
        throw new IllegalStateException("Utility class");
    }
    
    /**
     * Validate email format
     * @param email Email address
     * @return true if valid
     */
    public static boolean isValidEmail(String email) {
        if (email == null || email.trim().isEmpty()) {
            return false;
        }
        return EMAIL_PATTERN.matcher(email.trim()).matches();
    }
    
    /**
     * Validate phone number format
     * @param phone Phone number
     * @return true if valid
     */
    public static boolean isValidPhone(String phone) {
        if (phone == null || phone.trim().isEmpty()) {
            return true; // Phone is optional
        }
        return PHONE_PATTERN.matcher(phone.trim()).matches();
    }
    
    /**
     * Validate username format
     * @param username Username
     * @return true if valid
     */
    public static boolean isValidUsername(String username) {
        if (username == null || username.trim().isEmpty()) {
            return false;
        }
        return USERNAME_PATTERN.matcher(username.trim()).matches();
    }
    
    /**
     * Validate password strength
     * @param password Password
     * @return true if valid
     */
    public static boolean isValidPassword(String password) {
        if (password == null || password.length() < 8) {
            return false;
        }
        return true;
    }
    
    /**
     * Validate date range
     * @param startDate Start date
     * @param endDate End date
     * @return true if valid
     */
    public static boolean isValidDateRange(LocalDate startDate, LocalDate endDate) {
        if (startDate == null || endDate == null) {
            return false;
        }
        return !endDate.isBefore(startDate);
    }
    
    /**
     * Check if string is null or empty
     * @param str String to check
     * @return true if null or empty
     */
    public static boolean isEmpty(String str) {
        return str == null || str.trim().isEmpty();
    }
    
    /**
     * Sanitize input string
     * @param input Input string
     * @return Sanitized string
     */
    public static String sanitize(String input) {
        if (input == null) {
            return null;
        }
        
        // Remove potentially dangerous characters
        return input.trim()
                   .replaceAll("<", "&lt;")
                   .replaceAll(">", "&gt;")
                   .replaceAll("\"", "&quot;")
                   .replaceAll("'", "&#x27;")
                   .replaceAll("/", "&#x2F;");
    }
    
    /**
     * Validate integer input
     * @param str String to validate
     * @return true if valid integer
     */
    public static boolean isValidInteger(String str) {
        if (isEmpty(str)) {
            return false;
        }
        try {
            Integer.parseInt(str.trim());
            return true;
        } catch (NumberFormatException e) {
            return false;
        }
    }
    
    /**
     * Validate double input
     * @param str String to validate
     * @return true if valid double
     */
    public static boolean isValidDouble(String str) {
        if (isEmpty(str)) {
            return false;
        }
        try {
            Double.parseDouble(str.trim());
            return true;
        } catch (NumberFormatException e) {
            return false;
        }
    }
}
