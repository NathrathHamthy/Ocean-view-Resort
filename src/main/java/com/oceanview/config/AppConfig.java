package com.oceanview.config;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.io.IOException;
import java.io.InputStream;
import java.util.Properties;

/**
 * Application Configuration - Singleton Pattern
 * Manages application-wide configuration settings
 * 
 * @author Ocean View Resort Development Team
 * @version 1.0.0
 */
public class AppConfig {
    
    private static final Logger logger = LoggerFactory.getLogger(AppConfig.class);
    private static AppConfig instance;
    private Properties properties;
    
    // Private constructor for Singleton pattern
    private AppConfig() {
        loadConfiguration();
    }
    
    /**
     * Get singleton instance of AppConfig
     * @return AppConfig instance
     */
    public static synchronized AppConfig getInstance() {
        if (instance == null) {
            instance = new AppConfig();
        }
        return instance;
    }
    
    /**
     * Load configuration from properties file
     */
    private void loadConfiguration() {
        properties = new Properties();
        try (InputStream input = getClass().getClassLoader()
                .getResourceAsStream("config/application.properties")) {
            
            if (input == null) {
                logger.error("Unable to find application.properties");
                throw new RuntimeException("Configuration file not found");
            }
            
            properties.load(input);
            logger.info("Application configuration loaded successfully");
            
        } catch (IOException e) {
            logger.error("Failed to load application configuration", e);
            throw new RuntimeException("Failed to load configuration", e);
        }
    }
    
    /**
     * Get property value by key
     * @param key property key
     * @return property value
     */
    public String getProperty(String key) {
        return properties.getProperty(key);
    }
    
    /**
     * Get property value with default
     * @param key property key
     * @param defaultValue default value if key not found
     * @return property value or default
     */
    public String getProperty(String key, String defaultValue) {
        return properties.getProperty(key, defaultValue);
    }
    
    /**
     * Get integer property value
     * @param key property key
     * @param defaultValue default value
     * @return integer value
     */
    public int getIntProperty(String key, int defaultValue) {
        String value = properties.getProperty(key);
        if (value != null) {
            try {
                return Integer.parseInt(value);
            } catch (NumberFormatException e) {
                logger.warn("Invalid integer value for key: {}, using default", key);
            }
        }
        return defaultValue;
    }
    
    /**
     * Get boolean property value
     * @param key property key
     * @param defaultValue default value
     * @return boolean value
     */
    public boolean getBooleanProperty(String key, boolean defaultValue) {
        String value = properties.getProperty(key);
        if (value != null) {
            return Boolean.parseBoolean(value);
        }
        return defaultValue;
    }
    
    /**
     * Get double property value
     * @param key property key
     * @param defaultValue default value
     * @return double value
     */
    public double getDoubleProperty(String key, double defaultValue) {
        String value = properties.getProperty(key);
        if (value != null) {
            try {
                return Double.parseDouble(value);
            } catch (NumberFormatException e) {
                logger.warn("Invalid double value for key: {}, using default", key);
            }
        }
        return defaultValue;
    }
    
    // ========================================
    // Application Settings Getters
    // ========================================
    
    public String getAppName() {
        return getProperty("app.name", "Ocean View Resort");
    }
    
    public String getAppVersion() {
        return getProperty("app.version", "1.0.0");
    }
    
    public int getSessionTimeout() {
        return getIntProperty("session.timeout", 30);
    }
    
    // ========================================
    // File Upload Settings
    // ========================================
    
    public String getUploadDirectory() {
        return getProperty("upload.directory", "/uploads");
    }
    
    public long getMaxFileSize() {
        return Long.parseLong(getProperty("upload.maxFileSize", "5242880"));
    }
    
    // ========================================
    // Security Settings
    // ========================================
    
    public int getPasswordMinLength() {
        return getIntProperty("security.password.minLength", 8);
    }
    
    public boolean isPasswordSpecialCharRequired() {
        return getBooleanProperty("security.password.requireSpecialChar", true);
    }
    
    public boolean isPasswordNumberRequired() {
        return getBooleanProperty("security.password.requireNumber", true);
    }
    
    public boolean isPasswordUppercaseRequired() {
        return getBooleanProperty("security.password.requireUppercase", true);
    }
    
    // ========================================
    // Billing Settings
    // ========================================
    
    public double getTaxPercentage() {
        return getDoubleProperty("billing.tax.percentage", 10.0);
    }
    
    public double getServiceChargePercentage() {
        return getDoubleProperty("billing.service.charge.percentage", 5.0);
    }
    
    public String getCurrency() {
        return getProperty("billing.currency", "USD");
    }
    
    public String getCurrencySymbol() {
        return getProperty("billing.currency.symbol", "$");
    }
    
    // ========================================
    // Pagination Settings
    // ========================================
    
    public int getDefaultPageSize() {
        return getIntProperty("pagination.defaultPageSize", 10);
    }
    
    public int getMaxPageSize() {
        return getIntProperty("pagination.maxPageSize", 100);
    }
    
    // ========================================
    // Feature Flags
    // ========================================
    
    public boolean isSmsNotificationsEnabled() {
        return getBooleanProperty("features.sms.notifications", false);
    }
    
    public boolean isPdfGenerationEnabled() {
        return getBooleanProperty("features.pdf.generation", true);
    }
    
    public boolean isAuditLoggingEnabled() {
        return getBooleanProperty("features.audit.logging", true);
    }
    
    public boolean isReviewsEnabled() {
        return getBooleanProperty("features.reviews.enabled", true);
    }
    
    public boolean isOffersEnabled() {
        return getBooleanProperty("features.offers.enabled", true);
    }
}
