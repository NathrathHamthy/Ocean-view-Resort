package com.oceanview.util;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.time.format.DateTimeParseException;
import java.time.temporal.ChronoUnit;

/**
 * Date Utility
 * Provides date manipulation and formatting methods
 * 
 * @author Ocean View Resort Development Team
 * @version 1.0.0
 */
public class DateUtil {
    
    // Date formatters
    public static final DateTimeFormatter DATE_FORMATTER = 
        DateTimeFormatter.ofPattern(Constants.DATE_FORMAT);
    
    public static final DateTimeFormatter DATETIME_FORMATTER = 
        DateTimeFormatter.ofPattern(Constants.DATETIME_FORMAT);
    
    public static final DateTimeFormatter DISPLAY_DATE_FORMATTER = 
        DateTimeFormatter.ofPattern(Constants.DISPLAY_DATE_FORMAT);
    
    public static final DateTimeFormatter DISPLAY_DATETIME_FORMATTER = 
        DateTimeFormatter.ofPattern(Constants.DISPLAY_DATETIME_FORMAT);
    
    // Private constructor to prevent instantiation
    private DateUtil() {
        throw new IllegalStateException("Utility class");
    }
    
    /**
     * Format date to standard format (yyyy-MM-dd)
     * @param date LocalDate
     * @return Formatted date string
     */
    public static String formatDate(LocalDate date) {
        if (date == null) {
            return null;
        }
        return date.format(DATE_FORMATTER);
    }
    
    /**
     * Format date to display format (dd MMM yyyy)
     * @param date LocalDate
     * @return Formatted date string
     */
    public static String formatDateForDisplay(LocalDate date) {
        if (date == null) {
            return null;
        }
        return date.format(DISPLAY_DATE_FORMATTER);
    }
    
    /**
     * Format datetime to standard format (yyyy-MM-dd HH:mm:ss)
     * @param dateTime LocalDateTime
     * @return Formatted datetime string
     */
    public static String formatDateTime(LocalDateTime dateTime) {
        if (dateTime == null) {
            return null;
        }
        return dateTime.format(DATETIME_FORMATTER);
    }
    
    /**
     * Format datetime to display format (dd MMM yyyy HH:mm)
     * @param dateTime LocalDateTime
     * @return Formatted datetime string
     */
    public static String formatDateTimeForDisplay(LocalDateTime dateTime) {
        if (dateTime == null) {
            return null;
        }
        return dateTime.format(DISPLAY_DATETIME_FORMATTER);
    }
    
    /**
     * Parse date string to LocalDate
     * @param dateStr Date string (yyyy-MM-dd)
     * @return LocalDate or null if invalid
     */
    public static LocalDate parseDate(String dateStr) {
        if (dateStr == null || dateStr.trim().isEmpty()) {
            return null;
        }
        try {
            return LocalDate.parse(dateStr.trim(), DATE_FORMATTER);
        } catch (DateTimeParseException e) {
            return null;
        }
    }
    
    /**
     * Parse datetime string to LocalDateTime
     * @param dateTimeStr DateTime string (yyyy-MM-dd HH:mm:ss)
     * @return LocalDateTime or null if invalid
     */
    public static LocalDateTime parseDateTime(String dateTimeStr) {
        if (dateTimeStr == null || dateTimeStr.trim().isEmpty()) {
            return null;
        }
        try {
            return LocalDateTime.parse(dateTimeStr.trim(), DATETIME_FORMATTER);
        } catch (DateTimeParseException e) {
            return null;
        }
    }
    
    /**
     * Calculate number of days between two dates
     * @param startDate Start date
     * @param endDate End date
     * @return Number of days
     */
    public static long daysBetween(LocalDate startDate, LocalDate endDate) {
        if (startDate == null || endDate == null) {
            return 0;
        }
        return ChronoUnit.DAYS.between(startDate, endDate);
    }
    
    /**
     * Calculate number of nights for a reservation
     * @param checkIn Check-in date
     * @param checkOut Check-out date
     * @return Number of nights
     */
    public static int calculateNights(LocalDate checkIn, LocalDate checkOut) {
        return (int) daysBetween(checkIn, checkOut);
    }
    
    /**
     * Check if date is in the past
     * @param date Date to check
     * @return true if in the past
     */
    public static boolean isPast(LocalDate date) {
        if (date == null) {
            return false;
        }
        return date.isBefore(LocalDate.now());
    }
    
    /**
     * Check if date is in the future
     * @param date Date to check
     * @return true if in the future
     */
    public static boolean isFuture(LocalDate date) {
        if (date == null) {
            return false;
        }
        return date.isAfter(LocalDate.now());
    }
    
    /**
     * Check if date is today
     * @param date Date to check
     * @return true if today
     */
    public static boolean isToday(LocalDate date) {
        if (date == null) {
            return false;
        }
        return date.equals(LocalDate.now());
    }
    
    /**
     * Get current date
     * @return Current LocalDate
     */
    public static LocalDate getCurrentDate() {
        return LocalDate.now();
    }
    
    /**
     * Get current datetime
     * @return Current LocalDateTime
     */
    public static LocalDateTime getCurrentDateTime() {
        return LocalDateTime.now();
    }
    
    /**
     * Add days to a date
     * @param date Original date
     * @param days Number of days to add
     * @return New date
     */
    public static LocalDate addDays(LocalDate date, int days) {
        if (date == null) {
            return null;
        }
        return date.plusDays(days);
    }
    
    /**
     * Subtract days from a date
     * @param date Original date
     * @param days Number of days to subtract
     * @return New date
     */
    public static LocalDate subtractDays(LocalDate date, int days) {
        if (date == null) {
            return null;
        }
        return date.minusDays(days);
    }
    
    /**
     * Check if date range is valid
     * @param startDate Start date
     * @param endDate End date
     * @return true if valid (end >= start)
     */
    public static boolean isValidDateRange(LocalDate startDate, LocalDate endDate) {
        if (startDate == null || endDate == null) {
            return false;
        }
        return !endDate.isBefore(startDate);
    }
    
    /**
     * Check if dates overlap
     * @param start1 First period start
     * @param end1 First period end
     * @param start2 Second period start
     * @param end2 Second period end
     * @return true if periods overlap
     */
    public static boolean datesOverlap(LocalDate start1, LocalDate end1, 
                                       LocalDate start2, LocalDate end2) {
        if (start1 == null || end1 == null || start2 == null || end2 == null) {
            return false;
        }
        return !end1.isBefore(start2) && !start1.isAfter(end2);
    }
    
    /**
     * Get date range as string
     * @param startDate Start date
     * @param endDate End date
     * @return Formatted date range
     */
    public static String getDateRangeString(LocalDate startDate, LocalDate endDate) {
        if (startDate == null || endDate == null) {
            return "";
        }
        return formatDateForDisplay(startDate) + " - " + formatDateForDisplay(endDate);
    }
}
