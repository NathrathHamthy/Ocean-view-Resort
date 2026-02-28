-- Migration script to add missing fields to offers table
-- Run this if your offers table already exists

-- Add promo_code column
ALTER TABLE offers ADD COLUMN IF NOT EXISTS promo_code VARCHAR(50) UNIQUE AFTER min_nights;

-- Add used_count column
ALTER TABLE offers ADD COLUMN IF NOT EXISTS used_count INT DEFAULT 0 AFTER promo_code;

-- Add max_uses column
ALTER TABLE offers ADD COLUMN IF NOT EXISTS max_uses INT DEFAULT NULL AFTER used_count;

-- Update status enum to include SCHEDULED
ALTER TABLE offers MODIFY COLUMN status ENUM('ACTIVE', 'INACTIVE', 'EXPIRED', 'SCHEDULED') NOT NULL DEFAULT 'ACTIVE';

-- Add index for promo_code
CREATE INDEX IF NOT EXISTS idx_promo_code ON offers(promo_code);
