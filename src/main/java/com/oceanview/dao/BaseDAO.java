package com.oceanview.dao;

import com.oceanview.config.DatabaseConfig;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;

/**
 * Base DAO - Parent class for all DAOs
 * Provides common database operations and resource management
 * 
 * @author Ocean View Resort Development Team
 * @version 1.0.0
 */
public abstract class BaseDAO {
    
    protected static final Logger logger = LoggerFactory.getLogger(BaseDAO.class);
    protected DatabaseConfig dbConfig;
    
    /**
     * Constructor
     */
    public BaseDAO() {
        this.dbConfig = DatabaseConfig.getInstance();
    }
    
    /**
     * Get database connection
     * @return Connection object
     * @throws SQLException if connection fails
     */
    protected Connection getConnection() throws SQLException {
        return dbConfig.getConnection();
    }
    
    /**
     * Close connection safely
     * @param conn Connection to close
     */
    protected void closeConnection(Connection conn) {
        if (conn != null) {
            try {
                conn.close();
                logger.debug("Connection closed successfully");
            } catch (SQLException e) {
                logger.error("Error closing connection", e);
            }
        }
    }
    
    /**
     * Close PreparedStatement safely
     * @param stmt PreparedStatement to close
     */
    protected void closeStatement(PreparedStatement stmt) {
        if (stmt != null) {
            try {
                stmt.close();
                logger.debug("Statement closed successfully");
            } catch (SQLException e) {
                logger.error("Error closing statement", e);
            }
        }
    }
    
    /**
     * Close ResultSet safely
     * @param rs ResultSet to close
     */
    protected void closeResultSet(ResultSet rs) {
        if (rs != null) {
            try {
                rs.close();
                logger.debug("ResultSet closed successfully");
            } catch (SQLException e) {
                logger.error("Error closing result set", e);
            }
        }
    }
    
    /**
     * Close all resources safely
     * @param conn Connection
     * @param stmt PreparedStatement
     * @param rs ResultSet
     */
    protected void closeResources(Connection conn, PreparedStatement stmt, ResultSet rs) {
        closeResultSet(rs);
        closeStatement(stmt);
        closeConnection(conn);
    }
    
    /**
     * Close connection and statement
     * @param conn Connection
     * @param stmt PreparedStatement
     */
    protected void closeResources(Connection conn, PreparedStatement stmt) {
        closeStatement(stmt);
        closeConnection(conn);
    }
    
    /**
     * Rollback transaction safely
     * @param conn Connection
     */
    protected void rollback(Connection conn) {
        if (conn != null) {
            try {
                conn.rollback();
                logger.debug("Transaction rolled back");
            } catch (SQLException e) {
                logger.error("Error rolling back transaction", e);
            }
        }
    }
    
    /**
     * Begin transaction
     * @param conn Connection
     * @throws SQLException if operation fails
     */
    protected void beginTransaction(Connection conn) throws SQLException {
        if (conn != null) {
            conn.setAutoCommit(false);
            logger.debug("Transaction started");
        }
    }
    
    /**
     * Commit transaction
     * @param conn Connection
     * @throws SQLException if operation fails
     */
    protected void commit(Connection conn) throws SQLException {
        if (conn != null) {
            conn.commit();
            logger.debug("Transaction committed");
        }
    }
    
    /**
     * Log SQL exception
     * @param operation Operation name
     * @param e SQLException
     */
    protected void logSQLException(String operation, SQLException e) {
        logger.error("SQL Error in {}: {} - SQLState: {}, ErrorCode: {}", 
                    operation, e.getMessage(), e.getSQLState(), e.getErrorCode());
    }
}
