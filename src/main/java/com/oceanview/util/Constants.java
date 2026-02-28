package com.oceanview.util;

/**
 * Application Constants
 * Contains all constant values used throughout the application
 * 
 * @author Ocean View Resort Development Team
 * @version 1.0.0
 */
public class Constants {
    
    // Prevent instantiation
    private Constants() {
        throw new IllegalStateException("Constants class");
    }
    
    // ========================================
    // USER ROLES
    // ========================================
    public static final String ROLE_ADMIN = "ADMIN";
    public static final String ROLE_STAFF = "STAFF";
    public static final String ROLE_GUEST = "GUEST";
    
    // ========================================
    // USER STATUS
    // ========================================
    public static final String STATUS_ACTIVE = "ACTIVE";
    public static final String STATUS_INACTIVE = "INACTIVE";
    public static final String STATUS_SUSPENDED = "SUSPENDED";
    
    // ========================================
    // ROOM TYPES
    // ========================================
    public static final String ROOM_TYPE_SINGLE = "SINGLE";
    public static final String ROOM_TYPE_DOUBLE = "DOUBLE";
    public static final String ROOM_TYPE_DELUXE = "DELUXE";
    public static final String ROOM_TYPE_SUITE = "SUITE";
    public static final String ROOM_TYPE_FAMILY = "FAMILY";
    
    // ========================================
    // ROOM STATUS
    // ========================================
    public static final String ROOM_STATUS_AVAILABLE = "AVAILABLE";
    public static final String ROOM_STATUS_OCCUPIED = "OCCUPIED";
    public static final String ROOM_STATUS_MAINTENANCE = "MAINTENANCE";
    public static final String ROOM_STATUS_RESERVED = "RESERVED";
    
    // ========================================
    // RESERVATION STATUS
    // ========================================
    public static final String RESERVATION_STATUS_PENDING = "PENDING";
    public static final String RESERVATION_STATUS_CONFIRMED = "CONFIRMED";
    public static final String RESERVATION_STATUS_CHECKED_IN = "CHECKED_IN";
    public static final String RESERVATION_STATUS_CHECKED_OUT = "CHECKED_OUT";
    public static final String RESERVATION_STATUS_CANCELLED = "CANCELLED";
    
    // ========================================
    // PAYMENT STATUS
    // ========================================
    public static final String PAYMENT_STATUS_PENDING = "PENDING";
    public static final String PAYMENT_STATUS_COMPLETED = "COMPLETED";
    public static final String PAYMENT_STATUS_FAILED = "FAILED";
    public static final String PAYMENT_STATUS_REFUNDED = "REFUNDED";
    
    // ========================================
    // PAYMENT METHODS
    // ========================================
    public static final String PAYMENT_METHOD_CASH = "CASH";
    public static final String PAYMENT_METHOD_CARD = "CARD";
    public static final String PAYMENT_METHOD_BANK_TRANSFER = "BANK_TRANSFER";
    public static final String PAYMENT_METHOD_ONLINE = "ONLINE";
    
    // ========================================
    // REVIEW STATUS
    // ========================================
    public static final String REVIEW_STATUS_PENDING = "PENDING";
    public static final String REVIEW_STATUS_APPROVED = "APPROVED";
    public static final String REVIEW_STATUS_REJECTED = "REJECTED";
    
    // ========================================
    // OFFER STATUS
    // ========================================
    public static final String OFFER_STATUS_ACTIVE = "ACTIVE";
    public static final String OFFER_STATUS_INACTIVE = "INACTIVE";
    public static final String OFFER_STATUS_EXPIRED = "EXPIRED";
    
    // ========================================
    // DISCOUNT TYPES
    // ========================================
    public static final String DISCOUNT_TYPE_PERCENTAGE = "PERCENTAGE";
    public static final String DISCOUNT_TYPE_FIXED = "FIXED";
    
    // ========================================
    // SESSION ATTRIBUTES
    // ========================================
    public static final String SESSION_USER = "loggedInUser";
    public static final String SESSION_USER_ID = "userId";
    public static final String SESSION_USERNAME = "username";
    public static final String SESSION_USER_ROLE = "userRole";
    public static final String SESSION_USER_NAME = "fullName";
    
    // ========================================
    // REQUEST ATTRIBUTES
    // ========================================
    public static final String ATTR_ERROR = "error";
    public static final String ATTR_SUCCESS = "success";
    public static final String ATTR_MESSAGE = "message";
    public static final String ATTR_DATA = "data";
    
    // ========================================
    // VALIDATION MESSAGES
    // ========================================
    public static final String MSG_INVALID_EMAIL = "Invalid email format";
    public static final String MSG_INVALID_PHONE = "Invalid phone number format";
    public static final String MSG_PASSWORD_TOO_SHORT = "Password must be at least 8 characters";
    public static final String MSG_REQUIRED_FIELD = "This field is required";
    public static final String MSG_INVALID_DATE_RANGE = "Invalid date range";
    public static final String MSG_ROOM_NOT_AVAILABLE = "Room is not available for selected dates";
    
    // ========================================
    // SUCCESS MESSAGES
    // ========================================
    public static final String MSG_LOGIN_SUCCESS = "Login successful";
    public static final String MSG_LOGOUT_SUCCESS = "Logout successful";
    public static final String MSG_REGISTRATION_SUCCESS = "Registration successful";
    public static final String MSG_RESERVATION_SUCCESS = "Reservation created successfully";
    public static final String MSG_RESERVATION_CANCELLED = "Reservation cancelled successfully";
    public static final String MSG_CHECKIN_SUCCESS = "Check-in successful";
    public static final String MSG_CHECKOUT_SUCCESS = "Check-out successful";
    public static final String MSG_PAYMENT_SUCCESS = "Payment processed successfully";
    public static final String MSG_PROFILE_UPDATED = "Profile updated successfully";
    public static final String MSG_REVIEW_SUBMITTED = "Review submitted successfully";
    
    // ========================================
    // ERROR MESSAGES
    // ========================================
    public static final String MSG_LOGIN_FAILED = "Invalid username or password";
    public static final String MSG_ACCESS_DENIED = "Access denied";
    public static final String MSG_SESSION_EXPIRED = "Your session has expired. Please login again";
    public static final String MSG_DATABASE_ERROR = "Database error occurred";
    public static final String MSG_UNKNOWN_ERROR = "An unexpected error occurred";
    public static final String MSG_USER_NOT_FOUND = "User not found";
    public static final String MSG_RESERVATION_NOT_FOUND = "Reservation not found";
    public static final String MSG_ROOM_NOT_FOUND = "Room not found";
    public static final String MSG_DUPLICATE_EMAIL = "Email already exists";
    public static final String MSG_DUPLICATE_USERNAME = "Username already exists";
    
    // ========================================
    // DATE FORMATS
    // ========================================
    public static final String DATE_FORMAT = "yyyy-MM-dd";
    public static final String DATETIME_FORMAT = "yyyy-MM-dd HH:mm:ss";
    public static final String TIME_FORMAT = "HH:mm:ss";
    public static final String DISPLAY_DATE_FORMAT = "dd MMM yyyy";
    public static final String DISPLAY_DATETIME_FORMAT = "dd MMM yyyy HH:mm";
    
    // ========================================
    // PAGINATION
    // ========================================
    public static final int DEFAULT_PAGE_SIZE = 10;
    public static final int MAX_PAGE_SIZE = 100;
    
    // ========================================
    // FILE UPLOAD
    // ========================================
    public static final long MAX_FILE_SIZE = 5 * 1024 * 1024; // 5MB
    public static final String[] ALLOWED_IMAGE_EXTENSIONS = {"jpg", "jpeg", "png", "gif"};
    public static final String[] ALLOWED_DOCUMENT_EXTENSIONS = {"pdf", "doc", "docx"};
    
    // ========================================
    // EMAIL TEMPLATES
    // ========================================
    public static final String EMAIL_SUBJECT_BOOKING_CONFIRMATION = "Booking Confirmation - Ocean View Resort";
    public static final String EMAIL_SUBJECT_BOOKING_CANCELLATION = "Booking Cancellation - Ocean View Resort";
    public static final String EMAIL_SUBJECT_CHECKIN_REMINDER = "Check-in Reminder - Ocean View Resort";
    public static final String EMAIL_SUBJECT_PAYMENT_RECEIPT = "Payment Receipt - Ocean View Resort";
    
    // ========================================
    // BILLING
    // ========================================
    public static final double DEFAULT_TAX_PERCENTAGE = 10.0;
    public static final double DEFAULT_SERVICE_CHARGE = 5.0;
    public static final String CURRENCY = "USD";
    public static final String CURRENCY_SYMBOL = "$";
    
    // ========================================
    // RATINGS
    // ========================================
    public static final int MIN_RATING = 1;
    public static final int MAX_RATING = 5;
    
    // ========================================
    // REGEX PATTERNS
    // ========================================
    public static final String REGEX_EMAIL = "^[A-Za-z0-9+_.-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$";
    public static final String REGEX_PHONE = "^[+]?[0-9]{10,15}$";
    public static final String REGEX_USERNAME = "^[a-zA-Z0-9._-]{3,20}$";
    public static final String REGEX_PASSWORD = "^(?=.*[0-9])(?=.*[a-z])(?=.*[A-Z])(?=.*[@#$%^&+=])(?=\\S+$).{8,}$";
    
    // ========================================
    // APPLICATION INFO
    // ========================================
    public static final String APP_NAME = "Ocean View Resort";
    public static final String APP_VERSION = "1.0.0";
    public static final String APP_DESCRIPTION = "Advanced Hotel Booking System";
    
}
