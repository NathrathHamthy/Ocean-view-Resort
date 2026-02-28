package com.oceanview.model;

import java.io.Serializable;
import java.time.LocalDateTime;

/**
 * Hotel setting entity.
 */
public class HotelSetting implements Serializable {

    private static final long serialVersionUID = 1L;

    public enum SettingType {
        STRING, INTEGER, DECIMAL, BOOLEAN, JSON
    }

    private int settingId;
    private String category;
    private String settingKey;
    private String settingValue;
    private SettingType settingType;
    private String description;
    private boolean editable;
    private LocalDateTime updatedAt;
    private Integer updatedBy;

    public HotelSetting() {
        this.settingType = SettingType.STRING;
        this.editable = true;
    }

    public HotelSetting(String category, String key, String value, SettingType type, String description) {
        this.category = category;
        this.settingKey = key;
        this.settingValue = value;
        this.settingType = type;
        this.description = description;
        this.editable = true;
    }

    public int getSettingId() {
        return settingId;
    }

    public void setSettingId(int settingId) {
        this.settingId = settingId;
    }

    public String getCategory() {
        return category;
    }

    public void setCategory(String category) {
        this.category = category;
    }

    public String getSettingKey() {
        return settingKey;
    }

    public void setSettingKey(String settingKey) {
        this.settingKey = settingKey;
    }

    public String getSettingValue() {
        return settingValue;
    }

    public void setSettingValue(String settingValue) {
        this.settingValue = settingValue;
    }

    public SettingType getSettingType() {
        return settingType;
    }

    public void setSettingType(SettingType settingType) {
        this.settingType = settingType;
    }

    public String getDescription() {
        return description;
    }

    public void setDescription(String description) {
        this.description = description;
    }

    public boolean isEditable() {
        return editable;
    }

    public void setEditable(boolean editable) {
        this.editable = editable;
    }

    public LocalDateTime getUpdatedAt() {
        return updatedAt;
    }

    public void setUpdatedAt(LocalDateTime updatedAt) {
        this.updatedAt = updatedAt;
    }

    public Integer getUpdatedBy() {
        return updatedBy;
    }

    public void setUpdatedBy(Integer updatedBy) {
        this.updatedBy = updatedBy;
    }

    public boolean getValueAsBoolean() {
        return "true".equalsIgnoreCase(settingValue);
    }

    public int getValueAsInt() {
        try {
            return Integer.parseInt(settingValue);
        } catch (NumberFormatException ex) {
            return 0;
        }
    }

    public double getValueAsDouble() {
        try {
            return Double.parseDouble(settingValue);
        } catch (NumberFormatException ex) {
            return 0.0;
        }
    }

    public String getDisplayKey() {
        if (settingKey == null) {
            return "";
        }
        String[] parts = settingKey.split("\\.");
        StringBuilder result = new StringBuilder();
        for (String part : parts) {
            if (result.length() > 0) {
                result.append(' ');
            }
            if (!part.isEmpty()) {
                result.append(Character.toUpperCase(part.charAt(0))).append(part.substring(1));
            }
        }
        return result.toString();
    }

    @Override
    public String toString() {
        return "HotelSetting{id=" + settingId + ", key='" + settingKey + "', value='" + settingValue + "'}";
    }
}
