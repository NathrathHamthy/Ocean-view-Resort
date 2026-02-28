package com.oceanview.util;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.text.DecimalFormat;
import java.text.NumberFormat;
import java.util.Locale;

/**
 * Number Utility
 * Provides number formatting and calculation methods
 * 
 * @author Ocean View Resort Development Team
 * @version 1.0.0
 */
public class NumberUtil {
    
    private static final DecimalFormat CURRENCY_FORMAT = new DecimalFormat("#,##0.00");
    private static final DecimalFormat DECIMAL_FORMAT = new DecimalFormat("#,##0.##");
    private static final DecimalFormat PERCENTAGE_FORMAT = new DecimalFormat("#0.0");
    
    // Private constructor to prevent instantiation
    private NumberUtil() {
        throw new IllegalStateException("Utility class");
    }
    
    /**
     * Format amount as currency
     * @param amount Amount
     * @return Formatted currency string
     */
    public static String formatCurrency(BigDecimal amount) {
        if (amount == null) {
            return "$0.00";
        }
        return "$" + CURRENCY_FORMAT.format(amount);
    }
    
    /**
     * Format amount as currency with symbol
     * @param amount Amount
     * @param symbol Currency symbol
     * @return Formatted currency string
     */
    public static String formatCurrency(BigDecimal amount, String symbol) {
        if (amount == null) {
            return symbol + "0.00";
        }
        return symbol + CURRENCY_FORMAT.format(amount);
    }
    
    /**
     * Format double as currency
     * @param amount Amount
     * @return Formatted currency string
     */
    public static String formatCurrency(double amount) {
        return formatCurrency(BigDecimal.valueOf(amount));
    }
    
    /**
     * Format number with commas
     * @param number Number
     * @return Formatted number string
     */
    public static String formatNumber(long number) {
        return DECIMAL_FORMAT.format(number);
    }
    
    /**
     * Format decimal number
     * @param number Number
     * @return Formatted decimal string
     */
    public static String formatDecimal(double number) {
        return DECIMAL_FORMAT.format(number);
    }
    
    /**
     * Format as percentage
     * @param value Value (e.g., 0.15 for 15%)
     * @return Formatted percentage string
     */
    public static String formatPercentage(double value) {
        return PERCENTAGE_FORMAT.format(value * 100) + "%";
    }
    
    /**
     * Round BigDecimal to 2 decimal places
     * @param amount Amount
     * @return Rounded amount
     */
    public static BigDecimal round(BigDecimal amount) {
        if (amount == null) {
            return BigDecimal.ZERO;
        }
        return amount.setScale(2, RoundingMode.HALF_UP);
    }
    
    /**
     * Round double to 2 decimal places
     * @param value Value
     * @return Rounded value
     */
    public static double round(double value) {
        return Math.round(value * 100.0) / 100.0;
    }
    
    /**
     * Calculate percentage
     * @param value Value
     * @param total Total
     * @return Percentage (0-100)
     */
    public static double calculatePercentage(double value, double total) {
        if (total == 0) {
            return 0;
        }
        return (value / total) * 100;
    }
    
    /**
     * Calculate discount amount
     * @param amount Original amount
     * @param discountPercentage Discount percentage (e.g., 10 for 10%)
     * @return Discount amount
     */
    public static BigDecimal calculateDiscount(BigDecimal amount, double discountPercentage) {
        if (amount == null) {
            return BigDecimal.ZERO;
        }
        
        BigDecimal percentage = BigDecimal.valueOf(discountPercentage / 100);
        return round(amount.multiply(percentage));
    }
    
    /**
     * Apply discount to amount
     * @param amount Original amount
     * @param discountPercentage Discount percentage (e.g., 10 for 10%)
     * @return Amount after discount
     */
    public static BigDecimal applyDiscount(BigDecimal amount, double discountPercentage) {
        BigDecimal discount = calculateDiscount(amount, discountPercentage);
        return round(amount.subtract(discount));
    }
    
    /**
     * Calculate tax
     * @param amount Amount
     * @param taxPercentage Tax percentage (e.g., 10 for 10%)
     * @return Tax amount
     */
    public static BigDecimal calculateTax(BigDecimal amount, double taxPercentage) {
        if (amount == null) {
            return BigDecimal.ZERO;
        }
        
        BigDecimal percentage = BigDecimal.valueOf(taxPercentage / 100);
        return round(amount.multiply(percentage));
    }
    
    /**
     * Calculate total with tax
     * @param amount Original amount
     * @param taxPercentage Tax percentage (e.g., 10 for 10%)
     * @return Amount including tax
     */
    public static BigDecimal calculateTotalWithTax(BigDecimal amount, double taxPercentage) {
        BigDecimal tax = calculateTax(amount, taxPercentage);
        return round(amount.add(tax));
    }
    
    /**
     * Check if number is positive
     * @param amount Amount
     * @return true if positive
     */
    public static boolean isPositive(BigDecimal amount) {
        return amount != null && amount.compareTo(BigDecimal.ZERO) > 0;
    }
    
    /**
     * Check if number is zero
     * @param amount Amount
     * @return true if zero
     */
    public static boolean isZero(BigDecimal amount) {
        return amount == null || amount.compareTo(BigDecimal.ZERO) == 0;
    }
    
    /**
     * Get max value
     * @param a First value
     * @param b Second value
     * @return Maximum value
     */
    public static BigDecimal max(BigDecimal a, BigDecimal b) {
        if (a == null) return b;
        if (b == null) return a;
        return a.compareTo(b) > 0 ? a : b;
    }
    
    /**
     * Get min value
     * @param a First value
     * @param b Second value
     * @return Minimum value
     */
    public static BigDecimal min(BigDecimal a, BigDecimal b) {
        if (a == null) return b;
        if (b == null) return a;
        return a.compareTo(b) < 0 ? a : b;
    }
    
    /**
     * Safe BigDecimal from string
     * @param str String value
     * @return BigDecimal or ZERO if invalid
     */
    public static BigDecimal safeBigDecimal(String str) {
        if (str == null || str.trim().isEmpty()) {
            return BigDecimal.ZERO;
        }
        
        try {
            return new BigDecimal(str.trim());
        } catch (NumberFormatException e) {
            return BigDecimal.ZERO;
        }
    }
    
    /**
     * Format number in locale-specific format
     * @param number Number
     * @param locale Locale
     * @return Formatted string
     */
    public static String formatNumberLocale(double number, Locale locale) {
        NumberFormat formatter = NumberFormat.getInstance(locale);
        return formatter.format(number);
    }
}
