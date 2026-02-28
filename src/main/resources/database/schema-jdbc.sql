-- ============================================
-- Ocean View Resort - Database Schema (JDBC Compatible)
-- Version: 1.0.0
-- Author: Ocean View Resort Development Team
-- Description: JDBC-compatible schema without DELIMITER syntax
-- Note: Execute triggers and procedures separately via JDBC
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
    size INT DEFAULT NULL,
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


INSERT INTO users (username, password, email, full_name, phone, role, status)
VALUES ('admin', '$2a$10$REPLACE_WITH_BCRYPT_HASH_HERE', 'admin@gmail.com', 'System Administrator', '0770000000', 'ADMIN', 'ACTIVE');



UPDATE users SET password = '$2a$12$5WGRz8VlEi0G8Daizg7YU.lqbMHX56raGbFSTz1IkOd8Q1xrt0j6.' WHERE email = 'admin@gmail.com';

USE oceanview_resort;

-- ============================================================
-- CLEAN SLATE (only test seed rows — safe to re-run)
-- ============================================================
SET FOREIGN_KEY_CHECKS = 0;

DELETE FROM audit_logs   WHERE user_id IN (SELECT user_id FROM users WHERE username IN ('admin','staff'));
DELETE FROM payments     WHERE reservation_id IN (SELECT reservation_id FROM reservations WHERE guest_id IN (SELECT guest_id FROM guests WHERE user_id IN (SELECT user_id FROM users WHERE username IN ('admin','staff','testguest'))));
DELETE FROM reservations WHERE guest_id IN (SELECT guest_id FROM guests WHERE user_id IN (SELECT user_id FROM users WHERE username IN ('testguest')));
DELETE FROM guests       WHERE user_id IN (SELECT user_id FROM users WHERE username IN ('admin','staff','testguest'));
DELETE FROM users        WHERE username IN ('admin','staff','testguest');

SET FOREIGN_KEY_CHECKS = 1;

-- ============================================================
-- 1. USERS
--    admin     → Admin@1234
--    staff     → Staff@1234
--    testguest → password123
-- ============================================================
INSERT INTO users (username, password, email, full_name, phone, role, status) VALUES
                                                                                  (
                                                                                      'admin',
                                                                                      '$2a$10$30NIwlHNcRCHdvSzBbBlhexE0HmlmeiVUhs7COk4h/q5kUNeYqgyi',
                                                                                      'admin@oceanview.com',
                                                                                      'Alex Admin',
                                                                                      '+1-800-000-0001',
                                                                                      'ADMIN',
                                                                                      'ACTIVE'
                                                                                  ),
                                                                                  (
                                                                                      'staff',
                                                                                      '$2a$10$OTcvwLrmQokfILD44Kg4MusYVFA56S8a/TlkVZbGAKwy9KY/qaTku',
                                                                                      'staff@oceanview.com',
                                                                                      'Sam Staff',
                                                                                      '+1-800-000-0002',
                                                                                      'STAFF',
                                                                                      'ACTIVE'
                                                                                  ),
                                                                                  (
                                                                                      'testguest',
                                                                                      '$2a$10$IiPevqq2RdoiAN/uIS1h3u.QyAXy0WwJieEoA.6L5Gw4.bawXnni2',
                                                                                      'guest@oceanview.com',
                                                                                      'Gary Guest',
                                                                                      '+1-800-000-0003',
                                                                                      'GUEST',
                                                                                      'ACTIVE'
                                                                                  );

-- ============================================================
-- 2. GUEST PROFILE for testguest
-- ============================================================
INSERT INTO guests (user_id, address, city, country, postal_code, id_type, id_number, date_of_birth, gender)
SELECT user_id, '10 Ocean Blvd', 'Miami', 'USA', '33101',
       'Passport', 'P00TEST001', '1990-06-15', 'MALE'
FROM   users WHERE username = 'testguest';

-- ============================================================
-- 3. ROOMS — ensure at least a few rooms exist
--    (skip if already present — INSERT IGNORE on room_number unique key)
-- ============================================================
INSERT IGNORE INTO rooms (room_number, room_type, floor, capacity, price_per_night, description, amenities, status) VALUES
                                                                                                                        ('101', 'SINGLE',  1, 1,  80.00, 'Cozy single with garden view',        '["WiFi","AC","TV"]',                                           'AVAILABLE'),
                                                                                                                        ('102', 'SINGLE',  1, 1,  80.00, 'Single room, east facing',             '["WiFi","AC","TV"]',                                           'AVAILABLE'),
                                                                                                                        ('201', 'DOUBLE',  2, 2, 120.00, 'Double room with queen bed',           '["WiFi","AC","TV","Mini Bar"]',                                 'AVAILABLE'),
                                                                                                                        ('202', 'DOUBLE',  2, 2, 120.00, 'Double with balcony',                  '["WiFi","AC","TV","Mini Bar","Balcony"]',                       'OCCUPIED'),
                                                                                                                        ('301', 'DELUXE',  3, 2, 180.00, 'Deluxe ocean-view room',               '["WiFi","AC","Smart TV","Mini Bar","Safe","Ocean View"]',       'RESERVED'),
                                                                                                                        ('302', 'DELUXE',  3, 3, 200.00, 'Deluxe with extra bed',                '["WiFi","AC","Smart TV","Mini Bar","Safe","Ocean View"]',       'AVAILABLE'),
                                                                                                                        ('401', 'SUITE',   4, 4, 300.00, 'Junior suite with living area',        '["WiFi","AC","Smart TV","Mini Bar","Safe","Balcony","Kitchen"]','AVAILABLE'),
                                                                                                                        ('402', 'SUITE',   4, 4, 350.00, 'Presidential suite, panoramic view',  '["WiFi","AC","Smart TV","Mini Bar","Safe","Balcony","Jacuzzi"]','MAINTENANCE'),
                                                                                                                        ('501', 'FAMILY',  5, 5, 250.00, 'Family room, two bedrooms',            '["WiFi","AC","Smart TV","Kitchen","Two Bedrooms"]',             'AVAILABLE'),
                                                                                                                        ('502', 'FAMILY',  5, 6, 280.00, 'Large family suite with ocean view',   '["WiFi","AC","Smart TV","Kitchen","Two Bedrooms","Ocean View"]','AVAILABLE');

-- ============================================================
-- 4. RESERVATIONS  (wired to testguest + staff as creator)
--    Covers all status types so the dashboard shows real data
-- ============================================================

-- Helper: capture IDs
SET @guest_id  = (SELECT guest_id FROM guests WHERE user_id = (SELECT user_id FROM users WHERE username = 'testguest'));
SET @staff_id  = (SELECT user_id FROM users WHERE username = 'staff');
SET @admin_id  = (SELECT user_id FROM users WHERE username = 'admin');

SET @room_single  = (SELECT room_id FROM rooms WHERE room_number = '101' LIMIT 1);
SET @room_double  = (SELECT room_id FROM rooms WHERE room_number = '201' LIMIT 1);
SET @room_deluxe  = (SELECT room_id FROM rooms WHERE room_number = '301' LIMIT 1);
SET @room_suite   = (SELECT room_id FROM rooms WHERE room_number = '401' LIMIT 1);
SET @room_family  = (SELECT room_id FROM rooms WHERE room_number = '501' LIMIT 1);

-- TODAY check-in (CONFIRMED → staff can process check-in)
INSERT INTO reservations
(reservation_number, guest_id, room_id, check_in_date, check_out_date,
 number_of_guests, number_of_nights, total_amount, discount_amount, tax_amount, final_amount, status, created_by)
VALUES
    ('RES-TEST-0001', @guest_id, @room_single, CURDATE(), DATE_ADD(CURDATE(), INTERVAL 3 DAY),
     1, 3, 240.00, 0.00, 24.00, 264.00, 'CONFIRMED', @staff_id);

-- TODAY check-out (CHECKED_IN → staff can process check-out)
INSERT INTO reservations
(reservation_number, guest_id, room_id, check_in_date, check_out_date,
 number_of_guests, number_of_nights, total_amount, discount_amount, tax_amount, final_amount, status, created_by)
VALUES
    ('RES-TEST-0002', @guest_id, @room_double, DATE_SUB(CURDATE(), INTERVAL 3 DAY), CURDATE(),
     2, 3, 360.00, 0.00, 36.00, 396.00, 'CHECKED_IN', @staff_id);

-- UPCOMING (PENDING → needs confirmation)
INSERT INTO reservations
(reservation_number, guest_id, room_id, check_in_date, check_out_date,
 number_of_guests, number_of_nights, total_amount, discount_amount, tax_amount, final_amount, status, created_by)
VALUES
    ('RES-TEST-0003', @guest_id, @room_deluxe, DATE_ADD(CURDATE(), INTERVAL 5 DAY), DATE_ADD(CURDATE(), INTERVAL 10 DAY),
     2, 5, 900.00, 90.00, 81.00, 891.00, 'PENDING', @staff_id);

-- UPCOMING (CONFIRMED)
INSERT INTO reservations
(reservation_number, guest_id, room_id, check_in_date, check_out_date,
 number_of_guests, number_of_nights, total_amount, discount_amount, tax_amount, final_amount, status, created_by)
VALUES
    ('RES-TEST-0004', @guest_id, @room_suite, DATE_ADD(CURDATE(), INTERVAL 14 DAY), DATE_ADD(CURDATE(), INTERVAL 21 DAY),
     4, 7, 2100.00, 210.00, 189.00, 2079.00, 'CONFIRMED', @admin_id);

-- PAST (CHECKED_OUT)
INSERT INTO reservations
(reservation_number, guest_id, room_id, check_in_date, check_out_date,
 number_of_guests, number_of_nights, total_amount, discount_amount, tax_amount, final_amount, status, created_by)
VALUES
    ('RES-TEST-0005', @guest_id, @room_family, DATE_SUB(CURDATE(), INTERVAL 14 DAY), DATE_SUB(CURDATE(), INTERVAL 7 DAY),
     4, 7, 1750.00, 0.00, 175.00, 1925.00, 'CHECKED_OUT', @staff_id);

-- CANCELLED
INSERT INTO reservations
(reservation_number, guest_id, room_id, check_in_date, check_out_date,
 number_of_guests, number_of_nights, total_amount, discount_amount, tax_amount, final_amount, status, created_by)
VALUES
    ('RES-TEST-0006', @guest_id, @room_single, DATE_SUB(CURDATE(), INTERVAL 30 DAY), DATE_SUB(CURDATE(), INTERVAL 27 DAY),
     1, 3, 240.00, 0.00, 24.00, 264.00, 'CANCELLED', @staff_id);

-- ============================================================
-- 5. PAYMENTS for completed/checked-in reservations
-- ============================================================
INSERT INTO payments (reservation_id, payment_number, amount, payment_method, payment_status, transaction_id)
SELECT reservation_id, CONCAT('PAY-TEST-', LPAD(reservation_id,4,'0')), final_amount,
       'CARD', 'COMPLETED', CONCAT('TXN-TEST-', reservation_id)
FROM   reservations
WHERE  reservation_number IN ('RES-TEST-0002','RES-TEST-0005');

-- ============================================================
-- 6. AUDIT LOG entries
-- ============================================================
INSERT INTO audit_logs (user_id, action, entity_type, entity_id, details, ip_address)
VALUES
    (@admin_id, 'LOGIN',  'USER', @admin_id, '{"note":"admin seed login"}',  '127.0.0.1'),
    (@staff_id, 'LOGIN',  'USER', @staff_id, '{"note":"staff seed login"}',  '127.0.0.1'),
    (@staff_id, 'CREATE', 'RESERVATION', 1,  '{"reservation_number":"RES-TEST-0001"}', '127.0.0.1');

-- ============================================================
-- VERIFY
-- ============================================================
SELECT '=== TEST ACCOUNTS ===' AS info;
SELECT username, email, role, status FROM users WHERE username IN ('admin','staff','testguest');

SELECT '=== ROOM COUNTS ===' AS info;
SELECT status, COUNT(*) AS cnt FROM rooms GROUP BY status;

SELECT '=== RESERVATION COUNTS ===' AS info;
SELECT status, COUNT(*) AS cnt FROM reservations WHERE reservation_number LIKE 'RES-TEST-%' GROUP BY status;

SELECT '=== TODAY CHECK-INS ===' AS info;
SELECT reservation_number, status, check_in_date, check_out_date
FROM   reservations
WHERE  check_in_date = CURDATE() AND reservation_number LIKE 'RES-TEST-%';

SELECT '=== TODAY CHECK-OUTS ===' AS info;
SELECT reservation_number, status, check_in_date, check_out_date
FROM   reservations
WHERE  check_out_date = CURDATE() AND reservation_number LIKE 'RES-TEST-%';





USE oceanview_resort;

-- SINGLE rooms
UPDATE rooms SET image_url = 'https://images.unsplash.com/photo-1631049307264-da0ec9d70304?w=800&q=80'
WHERE room_type = 'SINGLE';

-- DOUBLE rooms
UPDATE rooms SET image_url = 'https://images.unsplash.com/photo-1566665797739-1674de7a421a?w=800&q=80'
WHERE room_type = 'DOUBLE';

-- DELUXE rooms
UPDATE rooms SET image_url = 'https://images.unsplash.com/photo-1578683010236-d716f9a3f461?w=800&q=80'
WHERE room_type = 'DELUXE';

-- SUITE rooms
UPDATE rooms SET image_url = 'https://images.unsplash.com/photo-1631049552057-403cdb8f0658?w=800&q=80'
WHERE room_type = 'SUITE';

-- FAMILY rooms
UPDATE rooms SET image_url = 'https://images.unsplash.com/photo-1591088398332-8a7791972843?w=800&q=80'
WHERE room_type = 'FAMILY';

-- Verify
SELECT room_number, room_type, image_url FROM rooms ORDER BY room_type, room_number;







USE oceanview_resort;

UPDATE rooms SET price_per_night = 80.00  * 300 WHERE room_number = '101';  -- Rs. 24,000
UPDATE rooms SET price_per_night = 80.00  * 300 WHERE room_number = '102';  -- Rs. 24,000
UPDATE rooms SET price_per_night = 80.00  * 300 WHERE room_number = '103';  -- Rs. 24,000
UPDATE rooms SET price_per_night = 120.00 * 300 WHERE room_number = '104';  -- Rs. 36,000
UPDATE rooms SET price_per_night = 120.00 * 300 WHERE room_number = '105';  -- Rs. 36,000
UPDATE rooms SET price_per_night = 180.00 * 300 WHERE room_number = '201';  -- Rs. 54,000
UPDATE rooms SET price_per_night = 180.00 * 300 WHERE room_number = '202';  -- Rs. 54,000
UPDATE rooms SET price_per_night = 200.00 * 300 WHERE room_number = '203';  -- Rs. 60,000
UPDATE rooms SET price_per_night = 300.00 * 300 WHERE room_number = '301';  -- Rs. 90,000
UPDATE rooms SET price_per_night = 320.00 * 300 WHERE room_number = '302';  -- Rs. 96,000
UPDATE rooms SET price_per_night = 250.00 * 300 WHERE room_number = '303';  -- Rs. 75,000
UPDATE rooms SET price_per_night = 280.00 * 300 WHERE room_number = '304';  -- Rs. 84,000
UPDATE rooms SET price_per_night = 150.00 * 300 WHERE room_number = '401';  -- Rs. 45,000
UPDATE rooms SET price_per_night = 150.00 * 300 WHERE room_number = '402';  -- Rs. 45,000
UPDATE rooms SET price_per_night = 220.00 * 300 WHERE room_number = '403';  -- Rs. 66,000




-- Verify
SELECT room_number, room_type, price_per_night FROM rooms WHERE room_number IN ('501', '502');
-- Verify
SELECT room_number, room_type, price_per_night FROM rooms ORDER BY room_type, room_number;



-- Family rooms
UPDATE rooms SET price_per_night = 75000.00 WHERE room_number = '303';
UPDATE rooms SET price_per_night = 84000.00 WHERE room_number = '304';
UPDATE rooms SET price_per_night = 75000.00 WHERE room_number = '501';
UPDATE rooms SET price_per_night = 75000.00 WHERE room_number = '502';

-- Verify all
SELECT room_number, room_type, price_per_night FROM rooms ORDER BY room_type, room_number;

-- ============================================
-- Database Schema Creation Complete
-- ============================================
