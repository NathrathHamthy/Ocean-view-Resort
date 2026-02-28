-- ============================================
-- Ocean View Resort - Database Triggers
-- Version: 1.0.0
-- Note: Execute these separately via JDBC after schema creation
-- ============================================

USE oceanview_resort;

-- Drop trigger if exists
DROP TRIGGER IF EXISTS trg_reservation_confirmed;

-- Trigger: Update room status when reservation status changes
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
END;
