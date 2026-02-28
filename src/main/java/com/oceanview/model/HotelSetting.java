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
}
