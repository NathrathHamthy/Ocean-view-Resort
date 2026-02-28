package com.oceanview.model;

import java.io.Serializable;
import java.time.LocalDateTime;

/**
 * HotelSetting Model
 * Represents a single configuration entry stored in hotel_settings table.
 *
 * @author Ocean View Resort Development Team
 * @version 1.0.0
 */
public class HotelSetting implements Serializable {

    private static final long serialVersionUID = 1L;

    public enum SettingType { STRING, INTEGER, DECIMAL, BOOLEAN, JSON }

    private int         settingId;
    private String      category;
    private String      settingKey;
    private String      settingValue;
    private SettingType settingType;
    private String      description;
    private boolean     isEditable;
    private LocalDateTime updatedAt;
    private Integer     updatedBy;

    // ── Constructors ────────────────────────────────────────
    public HotelSetting() {
        this.settingType = SettingType.STRING;
        this.isEditable  = true;
    }

    public HotelSetting(String category, String key, String value, SettingType type, String description) {
        this.category     = category;
        this.settingKey   = key;
        this.settingValue = value;
        this.settingType  = type;
        this.description  = description;
        this.isEditable   = true;
    }

    // ── Getters & Setters ────────────────────────────────────
    public int getSettingId()                   { return settingId; }
    public void setSettingId(int settingId)     { this.settingId = settingId; }

    public String getCategory()                 { return category; }
    public void setCategory(String category)    { this.category = category; }

    public String getSettingKey()               { return settingKey; }
    public void setSettingKey(String key)       { this.settingKey = key; }

    public String getSettingValue()             { return settingValue; }
    public void setSettingValue(String value)   { this.settingValue = value; }

    public SettingType getSettingType()                     { return settingType; }
    public void setSettingType(SettingType settingType)     { this.settingType = settingType; }

    public String getDescription()                          { return description; }
    public void setDescription(String description)          { this.description = description; }

    public boolean isEditable()                             { return isEditable; }
    public void setEditable(boolean editable)               { this.isEditable = editable; }

    public LocalDateTime getUpdatedAt()                     { return updatedAt; }
    public void setUpdatedAt(LocalDateTime updatedAt)       { this.updatedAt = updatedAt; }

    public Integer getUpdatedBy()                           { return updatedBy; }
    public void setUpdatedBy(Integer updatedBy)             { this.updatedBy = updatedBy; }

    // ── Convenience value accessors ──────────────────────────

    /** Returns the value as boolean. Treats "true" (case-insensitive) as true. */
    public boolean getValueAsBoolean() {
        return "true".equalsIgnoreCase(settingValue);
    }

    /** Returns the value as int. Returns 0 on parse failure. */
    public int getValueAsInt() {
        try { return Integer.parseInt(settingValue); }
        catch (NumberFormatException e) { return 0; }
    }

    /** Returns the value as double. Returns 0.0 on parse failure. */
    public double getValueAsDouble() {
        try { return Double.parseDouble(settingValue); }
        catch (NumberFormatException e) { return 0.0; }
    }

    /** Returns display-friendly key (dots replaced by spaces, title-cased). */
    public String getDisplayKey() {
        if (settingKey == null) return "";
        String[] parts = settingKey.split("\\.");
        StringBuilder sb = new StringBuilder();
        for (String p : parts) {
            if (sb.length() > 0) sb.append(" ");
            if (!p.isEmpty()) sb.append(Character.toUpperCase(p.charAt(0))).append(p.substring(1));
        }
        return sb.toString();
    }

    @Override
    public String toString() {
        return "HotelSetting{id=" + settingId + ", key='" + settingKey + "', value='" + settingValue + "'}";
    }
}
