package com.oceanview.service;

import com.oceanview.dao.SettingsDAO;
import com.oceanview.model.HotelSetting;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.*;

/**
 * SettingsService
 * Business logic layer for hotel settings management.
 *
 * @author Ocean View Resort Development Team
 * @version 1.0.0
 */
public class SettingsService {

    private static final Logger logger = LoggerFactory.getLogger(SettingsService.class);
    private final SettingsDAO settingsDAO;

    public SettingsService() {
        this.settingsDAO = new SettingsDAO();
    }

    // ── READ ─────────────────────────────────────────────────────────────────

    /** Get all settings grouped by category. */
    public Map<String, List<HotelSetting>> getAllGrouped() {
        return settingsDAO.findGroupedByCategory();
    }

    /** Get all settings as a flat key→value map. */
    public Map<String, String> getAllAsMap() {
        return settingsDAO.findAllAsMap();
    }

    /** Get all settings for a specific category. */
    public List<HotelSetting> getByCategory(String category) {
        return settingsDAO.findByCategory(category);
    }

    /** Get a single setting value by key, with a default fallback. */
    public String getValue(String key, String defaultValue) {
        return settingsDAO.findByKey(key)
                .map(HotelSetting::getSettingValue)
                .orElse(defaultValue);
    }

    /** Get a boolean setting value. */
    public boolean getBooleanValue(String key, boolean defaultValue) {
        Optional<HotelSetting> opt = settingsDAO.findByKey(key);
        return opt.map(HotelSetting::getValueAsBoolean).orElse(defaultValue);
    }

    /** Get an integer setting value. */
    public int getIntValue(String key, int defaultValue) {
        Optional<HotelSetting> opt = settingsDAO.findByKey(key);
        return opt.map(HotelSetting::getValueAsInt).orElse(defaultValue);
    }

    /** Get a double setting value. */
    public double getDoubleValue(String key, double defaultValue) {
        Optional<HotelSetting> opt = settingsDAO.findByKey(key);
        return opt.map(HotelSetting::getValueAsDouble).orElse(defaultValue);
    }

    // ── UPDATE ────────────────────────────────────────────────────────────────

    /**
     * Update a single setting by key.
     * Returns true on success.
     */
    public boolean updateSetting(String key, String value, int updatedByUserId) {
        if (key == null || key.trim().isEmpty()) return false;
        String safeValue = value != null ? value.trim() : "";
        boolean result = settingsDAO.updateValue(key, safeValue, updatedByUserId);
        if (result) logger.info("Setting updated: key='{}' by userId={}", key, updatedByUserId);
        else        logger.warn("Setting update failed or key not found/editable: key='{}'", key);
        return result;
    }

    /**
     * Batch update multiple settings from a form parameter map.
     * Only keys prefixed with "setting." are processed.
     * e.g. setting.app.name=Ocean View Resort
     */
    public boolean updateCategory(Map<String, String[]> paramMap, String category, int updatedByUserId) {
        // Build key→value pairs from request params
        Map<String, String> updates = new LinkedHashMap<>();
        List<HotelSetting> catSettings = settingsDAO.findByCategory(category);

        for (HotelSetting s : catSettings) {
            String paramKey = "setting." + s.getSettingKey();
            if (paramMap.containsKey(paramKey)) {
                String[] vals = paramMap.get(paramKey);
                String val = (vals != null && vals.length > 0) ? vals[0] : "";
                updates.put(s.getSettingKey(), val);
            } else if (s.getSettingType() == HotelSetting.SettingType.BOOLEAN) {
                // Unchecked checkboxes don't appear in form — treat as false
                updates.put(s.getSettingKey(), "false");
            }
        }

        if (updates.isEmpty()) return true;
        boolean result = settingsDAO.updateValues(updates, updatedByUserId);
        if (result) logger.info("Category '{}' settings updated ({} keys) by userId={}", category, updates.size(), updatedByUserId);
        return result;
    }

    // ── CREATE ────────────────────────────────────────────────────────────────

    /**
     * Create a new custom setting.
     * Returns true on success. Fails if key already exists.
     */
    public boolean createSetting(String category, String key, String value,
                                  HotelSetting.SettingType type, String description) {
        if (category == null || key == null || key.trim().isEmpty()) return false;
        if (settingsDAO.exists(key.trim())) {
            logger.warn("Create setting failed — key already exists: '{}'", key);
            return false;
        }
        HotelSetting s = new HotelSetting(category.trim(), key.trim(), value, type, description);
        boolean result = settingsDAO.create(s);
        if (result) logger.info("New setting created: key='{}'", key);
        return result;
    }

    // ── DELETE ────────────────────────────────────────────────────────────────

    /**
     * Delete a custom setting by key.
     */
    public boolean deleteSetting(String key) {
        if (key == null || key.trim().isEmpty()) return false;
        boolean result = settingsDAO.delete(key.trim());
        if (result) logger.info("Setting deleted: key='{}'", key);
        return result;
    }

    // ── SYSTEM UTILITIES ──────────────────────────────────────────────────────

    /** Build system information map for display. */
    public Map<String, String> getSystemInfo() {
        Map<String, String> info = new LinkedHashMap<>();
        Runtime rt = Runtime.getRuntime();
        long maxMB  = rt.maxMemory()   / 1024 / 1024;
        long totMB  = rt.totalMemory() / 1024 / 1024;
        long freeMB = rt.freeMemory()  / 1024 / 1024;
        long usedMB = totMB - freeMB;

        info.put("javaVersion",        System.getProperty("java.version", "N/A"));
        info.put("javaVendor",         System.getProperty("java.vendor",  "N/A"));
        info.put("osName",             System.getProperty("os.name",      "N/A"));
        info.put("osVersion",          System.getProperty("os.version",   "N/A"));
        info.put("osArch",             System.getProperty("os.arch",      "N/A"));
        info.put("processors",         String.valueOf(rt.availableProcessors()));
        info.put("maxMemoryMB",        String.valueOf(maxMB));
        info.put("usedMemoryMB",       String.valueOf(usedMB));
        info.put("freeMemoryMB",       String.valueOf(freeMB));
        info.put("memoryPct",          maxMB > 0 ? String.valueOf((int)(usedMB * 100 / maxMB)) : "0");
        return info;
    }
}
