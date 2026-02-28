-- ============================================================
-- Ocean View Resort — Staff & Admin Test Seed
-- Run this AFTER schema.sql to create test accounts + data
--
-- ╔══════════════════════════════════════════════╗
-- ║           TEST LOGIN CREDENTIALS            ║
-- ╠══════════════════════════════════════════════╣
-- ║  Role   │ Username  │ Password              ║
-- ╠══════════════════════════════════════════════╣
-- ║  ADMIN  │ admin     │ Admin@1234            ║
-- ║  STAFF  │ staff     │ Staff@1234            ║
-- ║  GUEST  │ testguest │ password123           ║
-- ╚══════════════════════════════════════════════╝
--
-- Hashes generated with BCrypt rounds=10, verified correct:
-- Admin@1234  → $2a$10$30NIwlHNcRCHdvSzBbBlhexE0HmlmeiVUhs7COk4h/q5kUNeYqgyi
-- Staff@1234  → $2a$10$OTcvwLrmQokfILD44Kg4MusYVFA56S8a/TlkVZbGAKwy9KY/qaTku
-- password123 → $2a$10$IiPevqq2RdoiAN/uIS1h3u.QyAXy0WwJieEoA.6L5Gw4.bawXnni2
-- ============================================================

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
