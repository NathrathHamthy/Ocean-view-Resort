package com.oceanview.config;

import org.apache.commons.dbcp2.BasicDataSource;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.io.IOException;
import java.io.InputStream;
import java.sql.Connection;
import java.sql.SQLException;
import java.util.Properties;

/**
 * Database Configuration - Singleton Pattern
 * Manages database connection pool using Apache Commons DBCP2
 * 
 * @author Ocean View Resort Development Team
 * @version 1.0.0
 */
public class DatabaseConfig {
    
    private static final Logger logger = LoggerFactory.getLogger(DatabaseConfig.class);
    private static DatabaseConfig instance;
    private BasicDataSource dataSource;
    
    // Private constructor for Singleton pattern
    private DatabaseConfig() {
        initializeDataSource();
    }
    
    /**
     * Get singleton instance of DatabaseConfig
     * @return DatabaseConfig instance
     */
    public static synchronized DatabaseConfig getInstance() {
        if (instance == null) {
            instance = new DatabaseConfig();
        }
        return instance;
    }
    
    /**
     * Initialize the data source with connection pooling
     */
    private void initializeDataSource() {
        try {
            Properties props = loadProperties();
            
            dataSource = new BasicDataSource();
            
            // Basic connection settings
            dataSource.setDriverClassName(props.getProperty("db.driver"));
            dataSource.setUrl(props.getProperty("db.url"));
            dataSource.setUsername(props.getProperty("db.username"));
            dataSource.setPassword(props.getProperty("db.password"));
            
            // Connection pool settings
            dataSource.setInitialSize(Integer.parseInt(props.getProperty("db.pool.initialSize", "5")));
            dataSource.setMaxTotal(Integer.parseInt(props.getProperty("db.pool.maxActive", "20")));
            dataSource.setMaxIdle(Integer.parseInt(props.getProperty("db.pool.maxIdle", "10")));
            dataSource.setMinIdle(Integer.parseInt(props.getProperty("db.pool.minIdle", "5")));
            dataSource.setMaxWaitMillis(Long.parseLong(props.getProperty("db.pool.maxWait", "30000")));
            
            // Connection validation
            dataSource.setTestOnBorrow(true);
            dataSource.setTestOnReturn(true);
            dataSource.setTestWhileIdle(true);
            dataSource.setValidationQuery("SELECT 1");
            dataSource.setTimeBetweenEvictionRunsMillis(30000);
            dataSource.setMinEvictableIdleTimeMillis(60000);
            
            logger.info("Database connection pool initialized successfully");
            
        } catch (Exception e) {
            logger.error("Failed to initialize database connection pool", e);
            throw new RuntimeException("Database configuration failed", e);
        }
    }
    
    /**
     * Load properties from configuration file
     * @return Properties object
     * @throws IOException if file cannot be read
     */
    private Properties loadProperties() throws IOException {
        Properties props = new Properties();
        try (InputStream input = getClass().getClassLoader()
                .getResourceAsStream("config/application.properties")) {
            
            if (input == null) {
                throw new IOException("Unable to find application.properties");
            }
            
            props.load(input);
            logger.info("Application properties loaded successfully");
            
        } catch (IOException e) {
            logger.error("Failed to load application properties", e);
            throw e;
        }
        return props;
    }
    
    /**
     * Get a database connection from the pool
     * @return Connection object
     * @throws SQLException if connection cannot be obtained
     */
    public Connection getConnection() throws SQLException {
        try {
            Connection conn = dataSource.getConnection();
            logger.debug("Database connection obtained from pool");
            return conn;
        } catch (SQLException e) {
            logger.error("Failed to get database connection", e);
            throw e;
        }
    }
    
    /**
     * Close the data source and release all connections
     */
    public void closeDataSource() {
        try {
            if (dataSource != null && !dataSource.isClosed()) {
                dataSource.close();
                logger.info("Database connection pool closed");
            }
        } catch (SQLException e) {
            logger.error("Error closing data source", e);
        }
    }
    
    /**
     * Get the data source
     * @return BasicDataSource
     */
    public BasicDataSource getDataSource() {
        return dataSource;
    }
    
    /**
     * Get active connection count
     * @return number of active connections
     */
    public int getActiveConnections() {
        return dataSource.getNumActive();
    }
    
    /**
     * Get idle connection count
     * @return number of idle connections
     */
    public int getIdleConnections() {
        return dataSource.getNumIdle();
    }
    
    /**
     * Test database connectivity
     * @return true if connection is successful
     */
    public boolean testConnection() {
        try (Connection conn = getConnection()) {
            return conn != null && !conn.isClosed();
        } catch (SQLException e) {
            logger.error("Database connection test failed", e);
            return false;
        }
    }
}
