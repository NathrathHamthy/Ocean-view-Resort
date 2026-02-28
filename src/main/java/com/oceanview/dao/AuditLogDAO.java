package com.oceanview.dao;

import com.oceanview.model.AuditLog;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.sql.*;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;

/**
 * AuditLog DAO - Data Access Object for AuditLog entity
 * 
 * @author Ocean View Resort Development Team
 * @version 1.0.0
 */
public class AuditLogDAO extends BaseDAO {
    
    private static final Logger logger = LoggerFactory.getLogger(AuditLogDAO.class);
    
    // SQL Queries
    private static final String INSERT_LOG = 
        "INSERT INTO audit_logs (user_id, action, entity_type, entity_id, details, ip_address) " +
        "VALUES (?, ?, ?, ?, ?, ?)";
    
    private static final String SELECT_BY_ID = 
        "SELECT * FROM audit_logs WHERE log_id = ?";
    
    private static final String SELECT_ALL = 
        "SELECT * FROM audit_logs ORDER BY timestamp DESC LIMIT ?";
    
    private static final String SELECT_BY_USER = 
        "SELECT * FROM audit_logs WHERE user_id = ? ORDER BY timestamp DESC LIMIT ?";
    
    private static final String SELECT_BY_ACTION = 
        "SELECT * FROM audit_logs WHERE action = ? ORDER BY timestamp DESC LIMIT ?";
    
    private static final String SELECT_BY_ENTITY = 
        "SELECT * FROM audit_logs WHERE entity_type = ? AND entity_id = ? " +
        "ORDER BY timestamp DESC";
    
    private static final String SELECT_BY_DATE_RANGE = 
        "SELECT * FROM audit_logs WHERE DATE(timestamp) BETWEEN ? AND ? " +
        "ORDER BY timestamp DESC";
    
    private static final String DELETE_OLD_LOGS = 
        "DELETE FROM audit_logs WHERE timestamp < DATE_SUB(NOW(), INTERVAL ? DAY)";
    
    /**
     * Create a new audit log entry
     */
    public int create(AuditLog auditLog) throws SQLException {
        Connection conn = null;
        PreparedStatement stmt = null;
        ResultSet rs = null;
        
        try {
            conn = getConnection();
            stmt = conn.prepareStatement(INSERT_LOG, Statement.RETURN_GENERATED_KEYS);
            
            if (auditLog.getUserId() != null) {
                stmt.setInt(1, auditLog.getUserId());
            } else {
                stmt.setNull(1, Types.INTEGER);
            }
            
            stmt.setString(2, auditLog.getAction());
            stmt.setString(3, auditLog.getEntityType());
            
            if (auditLog.getEntityId() != null) {
                stmt.setInt(4, auditLog.getEntityId());
            } else {
                stmt.setNull(4, Types.INTEGER);
            }
            
            stmt.setString(5, auditLog.getDetails());
            stmt.setString(6, auditLog.getIpAddress());
            
            int affectedRows = stmt.executeUpdate();
            
            if (affectedRows == 0) {
                throw new SQLException("Creating audit log failed, no rows affected.");
            }
            
            rs = stmt.getGeneratedKeys();
            if (rs.next()) {
                int logId = rs.getInt(1);
                logger.debug("Audit log created successfully with ID: {}", logId);
                return logId;
            } else {
                throw new SQLException("Creating audit log failed, no ID obtained.");
            }
            
        } catch (SQLException e) {
            logSQLException("create audit log", e);
            throw e;
        } finally {
            closeResources(conn, stmt, rs);
        }
    }
    
    /**
     * Find audit log by ID
     */
    public Optional<AuditLog> findById(int logId) throws SQLException {
        Connection conn = null;
        PreparedStatement stmt = null;
        ResultSet rs = null;
        
        try {
            conn = getConnection();
            stmt = conn.prepareStatement(SELECT_BY_ID);
            stmt.setInt(1, logId);
            
            rs = stmt.executeQuery();
            
            if (rs.next()) {
                return Optional.of(mapResultSetToAuditLog(rs));
            }
            
            return Optional.empty();
            
        } catch (SQLException e) {
            logSQLException("find audit log by ID", e);
            throw e;
        } finally {
            closeResources(conn, stmt, rs);
        }
    }
    
    /**
     * Find recent audit logs
     */
    public List<AuditLog> findRecent(int limit) throws SQLException {
        Connection conn = null;
        PreparedStatement stmt = null;
        ResultSet rs = null;
        List<AuditLog> logs = new ArrayList<>();
        
        try {
            conn = getConnection();
            stmt = conn.prepareStatement(SELECT_ALL);
            stmt.setInt(1, limit);
            rs = stmt.executeQuery();
            
            while (rs.next()) {
                logs.add(mapResultSetToAuditLog(rs));
            }
            
            logger.debug("Found {} audit logs", logs.size());
            return logs;
            
        } catch (SQLException e) {
            logSQLException("find recent audit logs", e);
            throw e;
        } finally {
            closeResources(conn, stmt, rs);
        }
    }
    
    /**
     * Find audit logs by user
     */
    public List<AuditLog> findByUserId(int userId, int limit) throws SQLException {
        Connection conn = null;
        PreparedStatement stmt = null;
        ResultSet rs = null;
        List<AuditLog> logs = new ArrayList<>();
        
        try {
            conn = getConnection();
            stmt = conn.prepareStatement(SELECT_BY_USER);
            stmt.setInt(1, userId);
            stmt.setInt(2, limit);
            rs = stmt.executeQuery();
            
            while (rs.next()) {
                logs.add(mapResultSetToAuditLog(rs));
            }
            
            logger.debug("Found {} audit logs for user ID: {}", logs.size(), userId);
            return logs;
            
        } catch (SQLException e) {
            logSQLException("find audit logs by user", e);
            throw e;
        } finally {
            closeResources(conn, stmt, rs);
        }
    }
    
    /**
     * Find audit logs by action
     */
    public List<AuditLog> findByAction(String action, int limit) throws SQLException {
        Connection conn = null;
        PreparedStatement stmt = null;
        ResultSet rs = null;
        List<AuditLog> logs = new ArrayList<>();
        
        try {
            conn = getConnection();
            stmt = conn.prepareStatement(SELECT_BY_ACTION);
            stmt.setString(1, action);
            stmt.setInt(2, limit);
            rs = stmt.executeQuery();
            
            while (rs.next()) {
                logs.add(mapResultSetToAuditLog(rs));
            }
            
            logger.debug("Found {} audit logs for action: {}", logs.size(), action);
            return logs;
            
        } catch (SQLException e) {
            logSQLException("find audit logs by action", e);
            throw e;
        } finally {
            closeResources(conn, stmt, rs);
        }
    }
    
    /**
     * Find audit logs by entity
     */
    public List<AuditLog> findByEntity(String entityType, int entityId) throws SQLException {
        Connection conn = null;
        PreparedStatement stmt = null;
        ResultSet rs = null;
        List<AuditLog> logs = new ArrayList<>();
        
        try {
            conn = getConnection();
            stmt = conn.prepareStatement(SELECT_BY_ENTITY);
            stmt.setString(1, entityType);
            stmt.setInt(2, entityId);
            rs = stmt.executeQuery();
            
            while (rs.next()) {
                logs.add(mapResultSetToAuditLog(rs));
            }
            
            logger.debug("Found {} audit logs for {} ID: {}", logs.size(), entityType, entityId);
            return logs;
            
        } catch (SQLException e) {
            logSQLException("find audit logs by entity", e);
            throw e;
        } finally {
            closeResources(conn, stmt, rs);
        }
    }
    
    /**
     * Delete old logs
     */
    public int deleteOldLogs(int daysToKeep) throws SQLException {
        Connection conn = null;
        PreparedStatement stmt = null;
        
        try {
            conn = getConnection();
            stmt = conn.prepareStatement(DELETE_OLD_LOGS);
            stmt.setInt(1, daysToKeep);
            
            int affectedRows = stmt.executeUpdate();
            logger.info("Deleted {} old audit logs (older than {} days)", affectedRows, daysToKeep);
            
            return affectedRows;
            
        } catch (SQLException e) {
            logSQLException("delete old audit logs", e);
            throw e;
        } finally {
            closeResources(conn, stmt);
        }
    }
    
    /**
     * Map ResultSet to AuditLog object
     */
    private AuditLog mapResultSetToAuditLog(ResultSet rs) throws SQLException {
        AuditLog auditLog = new AuditLog();
        auditLog.setLogId(rs.getInt("log_id"));
        
        int userId = rs.getInt("user_id");
        if (!rs.wasNull()) {
            auditLog.setUserId(userId);
        }
        
        auditLog.setAction(rs.getString("action"));
        auditLog.setEntityType(rs.getString("entity_type"));
        
        int entityId = rs.getInt("entity_id");
        if (!rs.wasNull()) {
            auditLog.setEntityId(entityId);
        }
        
        auditLog.setDetails(rs.getString("details"));
        auditLog.setIpAddress(rs.getString("ip_address"));
        
        Timestamp timestamp = rs.getTimestamp("timestamp");
        if (timestamp != null) {
            auditLog.setTimestamp(timestamp.toLocalDateTime());
        }
        
        return auditLog;
    }
}
