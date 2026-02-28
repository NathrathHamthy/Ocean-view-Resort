-- ============================================================
-- Migration: Update room prices to LKR
-- Database: oceanview_resort
-- Run once to update all room prices to Sri Lankan Rupees
-- ============================================================

USE oceanview_resort;

-- ── SINGLE ROOMS (Rs. 24,000/night) ──────────────────────────
UPDATE rooms SET price_per_night = 24000.00 WHERE room_number = '101';
UPDATE rooms SET price_per_night = 24000.00 WHERE room_number = '102';
UPDATE rooms SET price_per_night = 24000.00 WHERE room_number = '103';

-- ── DOUBLE ROOMS (Rs. 36,000/night) ──────────────────────────
UPDATE rooms SET price_per_night = 36000.00 WHERE room_number = '104';
UPDATE rooms SET price_per_night = 36000.00 WHERE room_number = '105';

-- ── DELUXE ROOMS (Rs. 54,000 – 60,000/night) ─────────────────
UPDATE rooms SET price_per_night = 54000.00 WHERE room_number = '201';
UPDATE rooms SET price_per_night = 54000.00 WHERE room_number = '202';
UPDATE rooms SET price_per_night = 60000.00 WHERE room_number = '203';

-- ── SUITE ROOMS (Rs. 75,000 – 96,000/night) ──────────────────
UPDATE rooms SET price_per_night = 90000.00 WHERE room_number = '301';
UPDATE rooms SET price_per_night = 96000.00 WHERE room_number = '302';

-- ── FAMILY ROOMS (Rs. 75,000 – 84,000/night) ─────────────────
UPDATE rooms SET price_per_night = 75000.00 WHERE room_number = '303';
UPDATE rooms SET price_per_night = 84000.00 WHERE room_number = '304';
UPDATE rooms SET price_per_night = 45000.00 WHERE room_number = '401';
UPDATE rooms SET price_per_night = 45000.00 WHERE room_number = '402';
UPDATE rooms SET price_per_night = 66000.00 WHERE room_number = '403';
UPDATE rooms SET price_per_night = 75000.00 WHERE room_number = '501';
UPDATE rooms SET price_per_night = 75000.00 WHERE room_number = '502';

-- ── VERIFY ────────────────────────────────────────────────────
SELECT
    room_number,
    room_type,
    CONCAT('Rs. ', FORMAT(price_per_night, 2)) AS price_per_night,
    status
FROM rooms
ORDER BY room_type, room_number;
