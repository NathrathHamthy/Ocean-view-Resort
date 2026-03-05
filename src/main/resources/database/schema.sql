-- ============================================
-- Ocean View Resort - Database Schema
-- Version: 1.0.0
-- Author: Ocean View Resort Development Team
-- Description: Complete database schema for hotel booking system
-- ============================================

-- Create database if not exists
CREATE DATABASE IF NOT EXISTS oceanview_resort
CHARACTER SET utf8mb4
COLLATE utf8mb4_unicode_ci;

USE oceanview_resort;

-- Drop tables if they exist (for clean installation)
DROP TABLE IF EXISTS audit_logs;
DROP TABLE IF EXISTS reviews;
DROP TABLE IF EXISTS payments;
DROP TABLE IF EXISTS reservations;
DROP TABLE IF EXISTS offers;
DROP TABLE IF EXISTS rooms;
DROP TABLE IF EXISTS guests;
DROP TABLE IF EXISTS users;

-- ============================================
-- Table: users
-- Description: Stores user authentication and basic information
-- ============================================
CREATE TABLE users (
    user_id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    password VARCHAR(255) NOT NULL COMMENT 'BCrypt hashed password',
    email VARCHAR(100) UNIQUE NOT NULL,
    full_name VARCHAR(100) NOT NULL,
    phone VARCHAR(20),
    role ENUM('ADMIN', 'STAFF', 'GUEST') NOT NULL DEFAULT 'GUEST',
    status ENUM('ACTIVE', 'INACTIVE', 'SUSPENDED') NOT NULL DEFAULT 'ACTIVE',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    last_login TIMESTAMP NULL,
    INDEX idx_username (username),
    INDEX idx_email (email),
    INDEX idx_role (role),
    INDEX idx_status (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================
-- Table: guests
-- Description: Extended information for guest users
-- ============================================
CREATE TABLE guests (
    guest_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    address TEXT,
    city VARCHAR(50),
    country VARCHAR(50),
    postal_code VARCHAR(10),
    id_type VARCHAR(20) COMMENT 'Passport, National ID, Driver License',
    id_number VARCHAR(50),
    date_of_birth DATE,
    gender ENUM('MALE', 'FEMALE', 'OTHER'),
    preferences TEXT COMMENT 'Guest preferences in JSON format',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    INDEX idx_user_id (user_id),
    INDEX idx_country (country)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================
-- Table: rooms
-- Description: Hotel room inventory
-- ============================================
CREATE TABLE rooms (
    room_id INT AUTO_INCREMENT PRIMARY KEY,
    room_number VARCHAR(10) UNIQUE NOT NULL,
    room_type ENUM('SINGLE', 'DOUBLE', 'DELUXE', 'SUITE', 'FAMILY') NOT NULL,
    floor INT NOT NULL,
    capacity INT NOT NULL DEFAULT 1,
    price_per_night DECIMAL(10,2) NOT NULL,
    size INT DEFAULT NULL COMMENT 'Room size in square meters',
    description TEXT,
    amenities TEXT COMMENT 'Room amenities in JSON format',
    image_url VARCHAR(255),
    status ENUM('AVAILABLE', 'OCCUPIED', 'MAINTENANCE', 'RESERVED') NOT NULL DEFAULT 'AVAILABLE',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_room_number (room_number),
    INDEX idx_room_type (room_type),
    INDEX idx_status (status),
    INDEX idx_price (price_per_night)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================
-- Table: offers
-- Description: Promotional offers and discounts
-- ============================================
CREATE TABLE offers (
    offer_id INT AUTO_INCREMENT PRIMARY KEY,
    title VARCHAR(100) NOT NULL,
    description TEXT,
    discount_type ENUM('PERCENTAGE', 'FIXED') NOT NULL,
    discount_value DECIMAL(10,2) NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    applicable_rooms TEXT COMMENT 'Room types in JSON array format',
    min_nights INT DEFAULT 1,
    promo_code VARCHAR(50) UNIQUE,
    used_count INT DEFAULT 0,
    max_uses INT DEFAULT NULL,
    status ENUM('ACTIVE', 'INACTIVE', 'EXPIRED', 'SCHEDULED') NOT NULL DEFAULT 'ACTIVE',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_status (status),
    INDEX idx_dates (start_date, end_date),
    INDEX idx_promo_code (promo_code)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================
-- Table: reservations
-- Description: Booking records
-- ============================================
CREATE TABLE reservations (
    reservation_id INT AUTO_INCREMENT PRIMARY KEY,
    reservation_number VARCHAR(20) UNIQUE NOT NULL,
    guest_id INT NOT NULL,
    room_id INT NOT NULL,
    check_in_date DATE NOT NULL,
    check_out_date DATE NOT NULL,
    number_of_guests INT NOT NULL DEFAULT 1,
    number_of_nights INT NOT NULL,
    total_amount DECIMAL(10,2) NOT NULL,
    discount_amount DECIMAL(10,2) DEFAULT 0.00,
    tax_amount DECIMAL(10,2) DEFAULT 0.00,
    final_amount DECIMAL(10,2) NOT NULL,
    status ENUM('PENDING', 'CONFIRMED', 'CHECKED_IN', 'CHECKED_OUT', 'CANCELLED') NOT NULL DEFAULT 'PENDING',
    special_requests TEXT,
    created_by INT NOT NULL COMMENT 'User ID who created the reservation',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (guest_id) REFERENCES guests(guest_id) ON DELETE RESTRICT,
    FOREIGN KEY (room_id) REFERENCES rooms(room_id) ON DELETE RESTRICT,
    FOREIGN KEY (created_by) REFERENCES users(user_id) ON DELETE RESTRICT,
    INDEX idx_reservation_number (reservation_number),
    INDEX idx_guest_id (guest_id),
    INDEX idx_room_id (room_id),
    INDEX idx_dates (check_in_date, check_out_date),
    INDEX idx_status (status),
    INDEX idx_created_at (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================
-- Table: payments
-- Description: Payment transactions
-- ============================================
CREATE TABLE payments (
    payment_id INT AUTO_INCREMENT PRIMARY KEY,
    reservation_id INT NOT NULL,
    payment_number VARCHAR(20) UNIQUE NOT NULL,
    amount DECIMAL(10,2) NOT NULL,
    payment_method ENUM('CASH', 'CARD', 'BANK_TRANSFER', 'ONLINE') NOT NULL,
    payment_status ENUM('PENDING', 'COMPLETED', 'FAILED', 'REFUNDED') NOT NULL DEFAULT 'PENDING',
    transaction_id VARCHAR(100),
    payment_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    notes TEXT,
    FOREIGN KEY (reservation_id) REFERENCES reservations(reservation_id) ON DELETE RESTRICT,
    INDEX idx_reservation_id (reservation_id),
    INDEX idx_payment_number (payment_number),
    INDEX idx_payment_status (payment_status),
    INDEX idx_payment_date (payment_date)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================
-- Table: reviews
-- Description: Guest reviews and ratings
-- ============================================
CREATE TABLE reviews (
    review_id INT AUTO_INCREMENT PRIMARY KEY,
    reservation_id INT NOT NULL,
    guest_id INT NOT NULL,
    rating INT NOT NULL CHECK (rating BETWEEN 1 AND 5),
    cleanliness_rating INT CHECK (cleanliness_rating BETWEEN 1 AND 5),
    service_rating INT CHECK (service_rating BETWEEN 1 AND 5),
    value_rating INT CHECK (value_rating BETWEEN 1 AND 5),
    comment TEXT,
    response TEXT COMMENT 'Admin or management response',
    status ENUM('PENDING', 'APPROVED', 'REJECTED') NOT NULL DEFAULT 'PENDING',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (reservation_id) REFERENCES reservations(reservation_id) ON DELETE CASCADE,
    FOREIGN KEY (guest_id) REFERENCES guests(guest_id) ON DELETE CASCADE,
    INDEX idx_reservation_id (reservation_id),
    INDEX idx_guest_id (guest_id),
    INDEX idx_rating (rating),
    INDEX idx_status (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================
-- Table: audit_logs
-- Description: System activity tracking
-- ============================================
CREATE TABLE audit_logs (
    log_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT,
    action VARCHAR(50) NOT NULL COMMENT 'CREATE, UPDATE, DELETE, LOGIN, LOGOUT',
    entity_type VARCHAR(50) COMMENT 'USER, ROOM, RESERVATION, etc.',
    entity_id INT,
    details TEXT COMMENT 'Additional details in JSON format',
    ip_address VARCHAR(45),
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE SET NULL,
    INDEX idx_user_id (user_id),
    INDEX idx_action (action),
    INDEX idx_entity (entity_type, entity_id),
    INDEX idx_timestamp (timestamp)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================
-- Triggers
-- ============================================

-- Trigger: Update room status when reservation is confirmed
DELIMITER //
CREATE TRIGGER trg_reservation_confirmed
AFTER UPDATE ON reservations
FOR EACH ROW
BEGIN
    IF NEW.status = 'CONFIRMED' AND OLD.status != 'CONFIRMED' THEN
        UPDATE rooms SET status = 'RESERVED' WHERE room_id = NEW.room_id;
    END IF;
    
    IF NEW.status = 'CHECKED_IN' AND OLD.status != 'CHECKED_IN' THEN
        UPDATE rooms SET status = 'OCCUPIED' WHERE room_id = NEW.room_id;
    END IF;
    
    IF NEW.status = 'CHECKED_OUT' AND OLD.status != 'CHECKED_OUT' THEN
        UPDATE rooms SET status = 'AVAILABLE' WHERE room_id = NEW.room_id;
    END IF;
    
    IF NEW.status = 'CANCELLED' AND OLD.status != 'CANCELLED' THEN
        UPDATE rooms SET status = 'AVAILABLE' WHERE room_id = NEW.room_id;
    END IF;
END//
DELIMITER ;

-- ============================================
-- Views for Reporting
-- ============================================

-- View: Active Reservations
CREATE OR REPLACE VIEW v_active_reservations AS
SELECT 
    r.reservation_id,
    r.reservation_number,
    r.check_in_date,
    r.check_out_date,
    r.status,
    u.full_name AS guest_name,
    u.email AS guest_email,
    u.phone AS guest_phone,
    rm.room_number,
    rm.room_type,
    r.final_amount
FROM reservations r
JOIN guests g ON r.guest_id = g.guest_id
JOIN users u ON g.user_id = u.user_id
JOIN rooms rm ON r.room_id = rm.room_id
WHERE r.status IN ('CONFIRMED', 'CHECKED_IN');

-- View: Room Availability
CREATE OR REPLACE VIEW v_available_rooms AS
SELECT 
    room_id,
    room_number,
    room_type,
    floor,
    capacity,
    price_per_night,
    description,
    status
FROM rooms
WHERE status = 'AVAILABLE';

-- View: Revenue Summary
CREATE OR REPLACE VIEW v_revenue_summary AS
SELECT 
    DATE(r.created_at) AS booking_date,
    COUNT(r.reservation_id) AS total_bookings,
    SUM(r.final_amount) AS total_revenue,
    AVG(r.final_amount) AS average_booking_value
FROM reservations r
WHERE r.status != 'CANCELLED'
GROUP BY DATE(r.created_at);

-- ============================================
-- Stored Procedures
-- ============================================

-- Procedure: Get Available Rooms
DELIMITER //
CREATE PROCEDURE sp_get_available_rooms(
    IN p_check_in DATE,
    IN p_check_out DATE,
    IN p_room_type VARCHAR(20)
)
BEGIN
    SELECT r.*
    FROM rooms r
    WHERE r.status = 'AVAILABLE'
    AND (p_room_type IS NULL OR r.room_type = p_room_type)
    AND r.room_id NOT IN (
        SELECT res.room_id
        FROM reservations res
        WHERE res.status IN ('CONFIRMED', 'CHECKED_IN', 'RESERVED')
        AND (
            (p_check_in BETWEEN res.check_in_date AND res.check_out_date)
            OR (p_check_out BETWEEN res.check_in_date AND res.check_out_date)
            OR (res.check_in_date BETWEEN p_check_in AND p_check_out)
        )
    );
END//
DELIMITER ;

-- ============================================
-- Database Schema Creation Complete
-- ============================================
