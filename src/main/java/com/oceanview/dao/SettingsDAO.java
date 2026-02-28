package com.oceanview.dao;

import com.oceanview.model.HotelSetting;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.sql.*;
import java.time.LocalDateTime;
import java.util.*;

/**
 * SettingsDAO - Data Access Object for hotel_settings table.
 * Provides full CRUD operations on the key-value settings store.
 *
 * @author Ocean View Resort Development Team
 * @version 1.0.0
 */
public class SettingsDAO extends BaseDAO {

    private static final Logger logger = LoggerFactory.getLogger(SettingsDAO.class);

    // ── SQL Queries ─────────────────────────────────────────────────────────
    private static final String SELECT_ALL =
        "SELECT * FROM hotel_settings ORDER BY category, setting_key";

    private static final String SELECT_BY_CATEGORY =
        "SELECT * FROM hotel_settings WHERE category = ? ORDER BY setting_key";

    private static final String SELECT_BY_KEY =
        "SELECT * FROM hotel_settings WHERE setting_key = ?";

    private static final String UPDATE_VALUE =
        "UPDATE hotel_settings SET setting_value = ?, updated_by = ?, updated_at = NOW() " +
        "WHERE setting_key = ? AND is_editable = 1";

    private static final String INSERT_SETTING =
        "INSERT INTO hotel_settings (category, setting_key, setting_value, setting_type, description, is_editable) " +
        "VALUES (?, ?, ?, ?, ?, ?)";

    private static final String DELETE_BY_KEY =
        "DELETE FROM hotel_settings WHERE setting_key = ?";

    private static final String EXISTS_BY_KEY =
        "SELECT COUNT(*) FROM hotel_settings WHERE setting_key = ?";

    // ── findAll ──────────────────────────────────────────────────────────────
    /**
     * Find all settings ordered by category and key.
     */
    public List<HotelSetting> findAll() {
        List<HotelSetting> list = new ArrayList<>();
        Connection conn = null;
        PreparedStatement stmt = null;
        ResultSet rs = null;
        try {
            conn = getConnection();
            stmt = conn.prepareStatement(SELECT_ALL);
            rs   = stmt.executeQuery();
            while (rs.next()) list.add(mapRow(rs));
            logger.debug("Loaded {} settings from DB", list.size());
        } catch (SQLException e) {
            logSQLException("findAll settings", e);
        } finally {
            closeResources(conn, stmt, rs);
        }
        return list;
    }

    // ── findByCategory ───────────────────────────────────────────────────────
    /**
     * Find all settings for a given category.
     */
    public List<HotelSetting> findByCategory(String category) {
        List<HotelSetting> list = new ArrayList<>();
        Connection conn = null;
        PreparedStatement stmt = null;
        ResultSet rs = null;
        try {
            conn = getConnection();
            stmt = conn.prepareStatement(SELECT_BY_CATEGORY);
            stmt.setString(1, category);
            rs = stmt.executeQuery();
            while (rs.next()) list.add(mapRow(rs));
        } catch (SQLException e) {
            logSQLException("findByCategory settings", e);
        } finally {
            closeResources(conn, stmt, rs);
        }
        return list;
    }

    // ── findByKey ────────────────────────────────────────────────────────────
    /**
     * Find a single setting by its unique key.
     */
    public Optional<HotelSetting> findByKey(String key) {
        Connection conn = null;
        PreparedStatement stmt = null;
        ResultSet rs = null;
        try {
            conn = getConnection();
            stmt = conn.prepareStatement(SELECT_BY_KEY);
            stmt.setString(1, key);
            rs = stmt.executeQuery();
            if (rs.next()) return Optional.of(mapRow(rs));
        } catch (SQLException e) {
            logSQLException("findByKey settings", e);
        } finally {
            closeResources(conn, stmt, rs);
        }
        return Optional.empty();
    }

    // ── findAllAsMap ─────────────────────────────────────────────────────────
    /**
     * Return all settings as a simple key → value map.
     */
    public Map<String, String> findAllAsMap() {
        Map<String, String> map = new LinkedHashMap<>();
        for (HotelSetting s : findAll()) {
            map.put(s.getSettingKey(), s.getSettingValue());
        }
        return map;
    }

    // ── findGroupedByCategory ────────────────────────────────────────────────
    /**
     * Return settings grouped by category (preserves insertion order).
     */
    public Map<String, List<HotelSetting>> findGroupedByCategory() {
        Map<String, List<HotelSetting>> grouped = new LinkedHashMap<>();
        for (HotelSetting s : findAll()) {
            grouped.computeIfAbsent(s.getCategory(), k -> new ArrayList<>()).add(s);
        }
        return grouped;
    }

    // ── updateValue ──────────────────────────────────────────────────────────
    /**
     * Update a single setting value by key.
     * Only updates rows where is_editable = 1.
     */
    public boolean updateValue(String key, String value, int updatedByUserId) {
        Connection conn = null;
        PreparedStatement stmt = null;
        try {
            conn = getConnection();
            stmt = conn.prepareStatement(UPDATE_VALUE);
            stmt.setString(1, value);
            stmt.setInt(2, updatedByUserId);
            stmt.setString(3, key);
            int affected = stmt.executeUpdate();
            logger.debug("Updated setting key='{}' affected={}", key, affected);
            return affected > 0;
        } catch (SQLException e) {
            logSQLException("updateValue setting key=" + key, e);
            return false;
        } finally {
            closeResources(conn, stmt);
        }
    }

    // ── updateValues (batch) ─────────────────────────────────────────────────
    /**
     * Batch-update multiple settings in a single transaction.
     * Returns true only if ALL updates succeed.
     */
    public boolean updateValues(Map<String, String> keyValuePairs, int updatedByUserId) {
        if (keyValuePairs == null || keyValuePairs.isEmpty()) return true;

        Connection conn = null;
        PreparedStatement stmt = null;
        try {
            conn = getConnection();
            beginTransaction(conn);
            stmt = conn.prepareStatement(UPDATE_VALUE);

            for (Map.Entry<String, String> entry : keyValuePairs.entrySet()) {
                stmt.setString(1, entry.getValue());
                stmt.setInt(2, updatedByUserId);
                stmt.setString(3, entry.getKey());
                stmt.addBatch();
            }

            int[] results = stmt.executeBatch();
            commit(conn);

            int updated = 0;
            for (int r : results) if (r > 0) updated++;
            logger.info("Batch settings update: {} keys submitted, {} rows updated", keyValuePairs.size(), updated);
            return true;

        } catch (SQLException e) {
            rollback(conn);
            logSQLException("updateValues batch", e);
            return false;
        } finally {
            closeResources(conn, stmt);
        }
    }

    // ── create ───────────────────────────────────────────────────────────────
    /**
     * Insert a new setting record.
     */
    public boolean create(HotelSetting setting) {
        Connection conn = null;
        PreparedStatement stmt = null;
        ResultSet rs = null;
        try {
            conn = getConnection();
            stmt = conn.prepareStatement(INSERT_SETTING, Statement.RETURN_GENERATED_KEYS);
            stmt.setString(1, setting.getCategory());
            stmt.setString(2, setting.getSettingKey());
            stmt.setString(3, setting.getSettingValue());
            stmt.setString(4, setting.getSettingType() != null ? setting.getSettingType().name() : "STRING");
            stmt.setString(5, setting.getDescription());
            stmt.setBoolean(6, setting.isEditable());
            int affected = stmt.executeUpdate();
            if (affected > 0) {
                rs = stmt.getGeneratedKeys();
                if (rs.next()) setting.setSettingId(rs.getInt(1));
                logger.info("Created new setting key='{}'", setting.getSettingKey());
                return true;
            }
        } catch (SQLException e) {
            logSQLException("create setting", e);
        } finally {
            closeResources(conn, stmt, rs);
        }
        return false;
    }

    // ── delete ───────────────────────────────────────────────────────────────
    /**
     * Delete a setting by key.
     */
    public boolean delete(String key) {
        Connection conn = null;
        PreparedStatement stmt = null;
        try {
            conn = getConnection();
            stmt = conn.prepareStatement(DELETE_BY_KEY);
            stmt.setString(1, key);
            int affected = stmt.executeUpdate();
            logger.info("Deleted setting key='{}', affected={}", key, affected);
            return affected > 0;
        } catch (SQLException e) {
            logSQLException("delete setting key=" + key, e);
            return false;
        } finally {
            closeResources(conn, stmt);
        }
    }

    // ── exists ───────────────────────────────────────────────────────────────
    /**
     * Check if a setting with the given key exists.
     */
    public boolean exists(String key) {
        Connection conn = null;
        PreparedStatement stmt = null;
        ResultSet rs = null;
        try {
            conn = getConnection();
            stmt = conn.prepareStatement(EXISTS_BY_KEY);
            stmt.setString(1, key);
            rs = stmt.executeQuery();
            if (rs.next()) return rs.getInt(1) > 0;
        } catch (SQLException e) {
            logSQLException("exists setting", e);
        } finally {
            closeResources(conn, stmt, rs);
        }
        return false;
    }

    // ── mapRow ───────────────────────────────────────────────────────────────
    private HotelSetting mapRow(ResultSet rs) throws SQLException {
        HotelSetting s = new HotelSetting();
        s.setSettingId(rs.getInt("setting_id"));
        s.setCategory(rs.getString("category"));
        s.setSettingKey(rs.getString("setting_key"));
        s.setSettingValue(rs.getString("setting_value"));
        s.setEditable(rs.getBoolean("is_editable"));
        s.setDescription(rs.getString("description"));

        String typeStr = rs.getString("setting_type");
        try {
            s.setSettingType(HotelSetting.SettingType.valueOf(typeStr));
        } catch (Exception ex) {
            s.setSettingType(HotelSetting.SettingType.STRING);
        }

        Timestamp updatedAt = rs.getTimestamp("updated_at");
        if (updatedAt != null) s.setUpdatedAt(updatedAt.toLocalDateTime());

        int updatedBy = rs.getInt("updated_by");
        if (!rs.wasNull()) s.setUpdatedBy(updatedBy);

        return s;
    }
}
