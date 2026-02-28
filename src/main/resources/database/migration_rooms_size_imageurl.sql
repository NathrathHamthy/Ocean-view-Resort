-- Migration: Add size and image_url columns to rooms table
-- Run this once against the oceanview_resort database if these columns are missing
-- Safe to run multiple times (uses IF NOT EXISTS pattern via stored procedure)

USE oceanview_resort;
SET @col_exists = (
    SELECT COUNT(*) FROM information_schema.columns
    WHERE table_schema = DATABASE()
      AND table_name   = 'rooms'
      AND column_name  = 'size'
);
SET @sql = IF(@col_exists = 0,
    'ALTER TABLE rooms ADD COLUMN size INT DEFAULT NULL COMMENT ''Room size in square meters'' AFTER price_per_night',
    'SELECT ''Column size already exists, skipping.'' AS info'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Add 'image_url' column (room image path or URL)
SET @col_exists2 = (
    SELECT COUNT(*) FROM information_schema.columns
    WHERE table_schema = DATABASE()
      AND table_name   = 'rooms'
      AND column_name  = 'image_url'
);
SET @sql2 = IF(@col_exists2 = 0,
    'ALTER TABLE rooms ADD COLUMN image_url VARCHAR(500) DEFAULT NULL COMMENT ''Room image URL or path'' AFTER size',
    'SELECT ''Column image_url already exists, skipping.'' AS info'
);
PREPARE stmt2 FROM @sql2;
EXECUTE stmt2;
DEALLOCATE PREPARE stmt2;

-- Verify
SELECT column_name, column_type, is_nullable, column_comment
FROM information_schema.columns
WHERE table_schema = DATABASE()
  AND table_name   = 'rooms'
  AND column_name  IN ('size', 'image_url')
ORDER BY ordinal_position;
