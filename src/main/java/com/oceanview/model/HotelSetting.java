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
}
