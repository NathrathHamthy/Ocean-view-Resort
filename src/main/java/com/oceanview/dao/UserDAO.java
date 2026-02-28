package com.oceanview.dao;

import com.oceanview.model.User;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.sql.*;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;

/**
 * User DAO - Data Access Object for User entity
 * Handles all database operations for users
 * 
 * @author Ocean View Resort Development Team
 * @version 1.0.0
 */
public class UserDAO extends BaseDAO {
    
    private static final Logger logger = LoggerFactory.getLogger(UserDAO.class);
    
    // SQL Queries
    private static final String INSERT_USER = 
        "INSERT INTO users (username, password, email, full_name, phone, role, status) " +
        "VALUES (?, ?, ?, ?, ?, ?, ?)";
    
    private static final String UPDATE_USER = 
        "UPDATE users SET username = ?, email = ?, full_name = ?, phone = ?, " +
        "role = ?, status = ?, updated_at = CURRENT_TIMESTAMP WHERE user_id = ?";
    
    private static final String UPDATE_PASSWORD = 
        "UPDATE users SET password = ?, updated_at = CURRENT_TIMESTAMP WHERE user_id = ?";
    
    private static final String UPDATE_LAST_LOGIN = 
        "UPDATE users SET last_login = CURRENT_TIMESTAMP WHERE user_id = ?";
    
    private static final String DELETE_USER = 
        "DELETE FROM users WHERE user_id = ?";
    
    private static final String SELECT_BY_ID = 
        "SELECT * FROM users WHERE user_id = ?";
    
    private static final String SELECT_BY_USERNAME = 
        "SELECT * FROM users WHERE username = ?";
    
    private static final String SELECT_BY_EMAIL = 
        "SELECT * FROM users WHERE email = ?";
    
    private static final String SELECT_ALL = 
        "SELECT * FROM users ORDER BY created_at DESC";
    
    private static final String SELECT_BY_ROLE = 
        "SELECT * FROM users WHERE role = ? ORDER BY created_at DESC";
    
    private static final String SELECT_BY_STATUS = 
        "SELECT * FROM users WHERE status = ? ORDER BY created_at DESC";
    
    private static final String COUNT_BY_USERNAME = 
        "SELECT COUNT(*) FROM users WHERE username = ?";
    
    private static final String COUNT_BY_EMAIL = 
        "SELECT COUNT(*) FROM users WHERE email = ?";
    
    /**
     * Create a new user
     * @param user User object
     * @return Generated user ID
     * @throws SQLException if operation fails
     */
    public int create(User user) throws SQLException {
        Connection conn = null;
        PreparedStatement stmt = null;
        ResultSet rs = null;
        
        try {
            conn = getConnection();
            stmt = conn.prepareStatement(INSERT_USER, Statement.RETURN_GENERATED_KEYS);
            
            stmt.setString(1, user.getUsername());
            stmt.setString(2, user.getPassword());
            stmt.setString(3, user.getEmail());
            stmt.setString(4, user.getFullName());
            stmt.setString(5, user.getPhone());
            stmt.setString(6, user.getRole().name());
            stmt.setString(7, user.getStatus().name());
            
            int affectedRows = stmt.executeUpdate();
            
            if (affectedRows == 0) {
                throw new SQLException("Creating user failed, no rows affected.");
            }
            
            rs = stmt.getGeneratedKeys();
            if (rs.next()) {
                int userId = rs.getInt(1);
                logger.info("User created successfully with ID: {}", userId);
                return userId;
            } else {
                throw new SQLException("Creating user failed, no ID obtained.");
            }
            
        } catch (SQLException e) {
            logSQLException("create user", e);
            throw e;
        } finally {
            closeResources(conn, stmt, rs);
        }
    }
    
    /**
     * Update existing user
     * @param user User object
     * @return true if successful
     * @throws SQLException if operation fails
     */
    public boolean update(User user) throws SQLException {
        Connection conn = null;
        PreparedStatement stmt = null;
        
        try {
            conn = getConnection();
            stmt = conn.prepareStatement(UPDATE_USER);
            
            stmt.setString(1, user.getUsername());
            stmt.setString(2, user.getEmail());
            stmt.setString(3, user.getFullName());
            stmt.setString(4, user.getPhone());
            stmt.setString(5, user.getRole().name());
            stmt.setString(6, user.getStatus().name());
            stmt.setInt(7, user.getUserId());
            
            int affectedRows = stmt.executeUpdate();
            logger.info("User updated: ID={}, affected rows={}", user.getUserId(), affectedRows);
            
            return affectedRows > 0;
            
        } catch (SQLException e) {
            logSQLException("update user", e);
            throw e;
        } finally {
            closeResources(conn, stmt);
        }
    }
    
    /**
     * Update user password
     * @param userId User ID
     * @param hashedPassword Hashed password
     * @return true if successful
     * @throws SQLException if operation fails
     */
    public boolean updatePassword(int userId, String hashedPassword) throws SQLException {
        Connection conn = null;
        PreparedStatement stmt = null;
        
        try {
            conn = getConnection();
            stmt = conn.prepareStatement(UPDATE_PASSWORD);
            
            stmt.setString(1, hashedPassword);
            stmt.setInt(2, userId);
            
            int affectedRows = stmt.executeUpdate();
            logger.info("Password updated for user ID: {}", userId);
            
            return affectedRows > 0;
            
        } catch (SQLException e) {
            logSQLException("update password", e);
            throw e;
        } finally {
            closeResources(conn, stmt);
        }
    }
    
    /**
     * Update last login timestamp
     * @param userId User ID
     * @throws SQLException if operation fails
     */
    public void updateLastLogin(int userId) throws SQLException {
        Connection conn = null;
        PreparedStatement stmt = null;
        
        try {
            conn = getConnection();
            stmt = conn.prepareStatement(UPDATE_LAST_LOGIN);
            stmt.setInt(1, userId);
            stmt.executeUpdate();
            
            logger.debug("Last login updated for user ID: {}", userId);
            
        } catch (SQLException e) {
            logSQLException("update last login", e);
            throw e;
        } finally {
            closeResources(conn, stmt);
        }
    }
    
    /**
     * Delete user
     * @param userId User ID
     * @return true if successful
     * @throws SQLException if operation fails
     */
    public boolean delete(int userId) throws SQLException {
        Connection conn = null;
        PreparedStatement stmt = null;
        
        try {
            conn = getConnection();
            stmt = conn.prepareStatement(DELETE_USER);
            stmt.setInt(1, userId);
            
            int affectedRows = stmt.executeUpdate();
            logger.info("User deleted: ID={}, affected rows={}", userId, affectedRows);
            
            return affectedRows > 0;
            
        } catch (SQLException e) {
            logSQLException("delete user", e);
            throw e;
        } finally {
            closeResources(conn, stmt);
        }
    }
    
    /**
     * Find user by ID
     * @param userId User ID
     * @return Optional User object
     * @throws SQLException if operation fails
     */
    public Optional<User> findById(int userId) throws SQLException {
        Connection conn = null;
        PreparedStatement stmt = null;
        ResultSet rs = null;
        
        try {
            conn = getConnection();
            stmt = conn.prepareStatement(SELECT_BY_ID);
            stmt.setInt(1, userId);
            
            rs = stmt.executeQuery();
            
            if (rs.next()) {
                return Optional.of(mapResultSetToUser(rs));
            }
            
            return Optional.empty();
            
        } catch (SQLException e) {
            logSQLException("find user by ID", e);
            throw e;
        } finally {
            closeResources(conn, stmt, rs);
        }
    }
    
    /**
     * Find user by username
     * @param username Username
     * @return Optional User object
     * @throws SQLException if operation fails
     */
    public Optional<User> findByUsername(String username) throws SQLException {
        Connection conn = null;
        PreparedStatement stmt = null;
        ResultSet rs = null;
        
        try {
            conn = getConnection();
            stmt = conn.prepareStatement(SELECT_BY_USERNAME);
            stmt.setString(1, username);
            
            rs = stmt.executeQuery();
            
            if (rs.next()) {
                return Optional.of(mapResultSetToUser(rs));
            }
            
            return Optional.empty();
            
        } catch (SQLException e) {
            logSQLException("find user by username", e);
            throw e;
        } finally {
            closeResources(conn, stmt, rs);
        }
    }
    
    /**
     * Find user by email
     * @param email Email address
     * @return Optional User object
     * @throws SQLException if operation fails
     */
    public Optional<User> findByEmail(String email) throws SQLException {
        Connection conn = null;
        PreparedStatement stmt = null;
        ResultSet rs = null;
        
        try {
            conn = getConnection();
            stmt = conn.prepareStatement(SELECT_BY_EMAIL);
            stmt.setString(1, email);
            
            rs = stmt.executeQuery();
            
            if (rs.next()) {
                return Optional.of(mapResultSetToUser(rs));
            }
            
            return Optional.empty();
            
        } catch (SQLException e) {
            logSQLException("find user by email", e);
            throw e;
        } finally {
            closeResources(conn, stmt, rs);
        }
    }
    
    /**
     * Find all users
     * @return List of users
     * @throws SQLException if operation fails
     */
    public List<User> findAll() throws SQLException {
        Connection conn = null;
        PreparedStatement stmt = null;
        ResultSet rs = null;
        List<User> users = new ArrayList<>();
        
        try {
            conn = getConnection();
            stmt = conn.prepareStatement(SELECT_ALL);
            rs = stmt.executeQuery();
            
            while (rs.next()) {
                users.add(mapResultSetToUser(rs));
            }
            
            logger.debug("Found {} users", users.size());
            return users;
            
        } catch (SQLException e) {
            logSQLException("find all users", e);
            throw e;
        } finally {
            closeResources(conn, stmt, rs);
        }
    }
    
    /**
     * Find users by role
     * @param role User role
     * @return List of users
     * @throws SQLException if operation fails
     */
    public List<User> findByRole(User.Role role) throws SQLException {
        Connection conn = null;
        PreparedStatement stmt = null;
        ResultSet rs = null;
        List<User> users = new ArrayList<>();
        
        try {
            conn = getConnection();
            stmt = conn.prepareStatement(SELECT_BY_ROLE);
            stmt.setString(1, role.name());
            rs = stmt.executeQuery();
            
            while (rs.next()) {
                users.add(mapResultSetToUser(rs));
            }
            
            logger.debug("Found {} users with role {}", users.size(), role);
            return users;
            
        } catch (SQLException e) {
            logSQLException("find users by role", e);
            throw e;
        } finally {
            closeResources(conn, stmt, rs);
        }
    }
    
    /**
     * Check if username exists
     * @param username Username
     * @return true if exists
     * @throws SQLException if operation fails
     */
    public boolean existsByUsername(String username) throws SQLException {
        Connection conn = null;
        PreparedStatement stmt = null;
        ResultSet rs = null;
        
        try {
            conn = getConnection();
            stmt = conn.prepareStatement(COUNT_BY_USERNAME);
            stmt.setString(1, username);
            rs = stmt.executeQuery();
            
            if (rs.next()) {
                return rs.getInt(1) > 0;
            }
            
            return false;
            
        } catch (SQLException e) {
            logSQLException("check username exists", e);
            throw e;
        } finally {
            closeResources(conn, stmt, rs);
        }
    }
    
    /**
     * Check if email exists
     * @param email Email address
     * @return true if exists
     * @throws SQLException if operation fails
     */
    public boolean existsByEmail(String email) throws SQLException {
        Connection conn = null;
        PreparedStatement stmt = null;
        ResultSet rs = null;
        
        try {
            conn = getConnection();
            stmt = conn.prepareStatement(COUNT_BY_EMAIL);
            stmt.setString(1, email);
            rs = stmt.executeQuery();
            
            if (rs.next()) {
                return rs.getInt(1) > 0;
            }
            
            return false;
            
        } catch (SQLException e) {
            logSQLException("check email exists", e);
            throw e;
        } finally {
            closeResources(conn, stmt, rs);
        }
    }
    
    /**
     * Count all users
     */
    public int count() throws SQLException {
        Connection conn = null;
        PreparedStatement stmt = null;
        ResultSet rs = null;
        
        String sql = "SELECT COUNT(*) FROM users";
        
        try {
            conn = getConnection();
            stmt = conn.prepareStatement(sql);
            rs = stmt.executeQuery();
            
            if (rs.next()) {
                return rs.getInt(1);
            }
            return 0;
            
        } catch (SQLException e) {
            logSQLException("count users", e);
            throw e;
        } finally {
            closeResources(conn, stmt, rs);
        }
    }
    
    /**
     * Count users by status
     */
    public int countByStatus(String status) throws SQLException {
        Connection conn = null;
        PreparedStatement stmt = null;
        ResultSet rs = null;
        
        String sql = "SELECT COUNT(*) FROM users WHERE status = ?";
        
        try {
            conn = getConnection();
            stmt = conn.prepareStatement(sql);
            stmt.setString(1, status);
            rs = stmt.executeQuery();
            
            if (rs.next()) {
                return rs.getInt(1);
            }
            return 0;
            
        } catch (SQLException e) {
            logSQLException("count users by status", e);
            throw e;
        } finally {
            closeResources(conn, stmt, rs);
        }
    }
    
    /**
     * Count users by role
     */
    public int countByRole(String role) throws SQLException {
        Connection conn = null;
        PreparedStatement stmt = null;
        ResultSet rs = null;
        
        String sql = "SELECT COUNT(*) FROM users WHERE role = ?";
        
        try {
            conn = getConnection();
            stmt = conn.prepareStatement(sql);
            stmt.setString(1, role);
            rs = stmt.executeQuery();
            
            if (rs.next()) {
                return rs.getInt(1);
            }
            return 0;
            
        } catch (SQLException e) {
            logSQLException("count users by role", e);
            throw e;
        } finally {
            closeResources(conn, stmt, rs);
        }
    }
    
    /**
     * Map ResultSet to User object
     * @param rs ResultSet
     * @return User object
     * @throws SQLException if mapping fails
     */
    private User mapResultSetToUser(ResultSet rs) throws SQLException {
        User user = new User();
        user.setUserId(rs.getInt("user_id"));
        user.setUsername(rs.getString("username"));
        user.setPassword(rs.getString("password"));
        user.setEmail(rs.getString("email"));
        user.setFullName(rs.getString("full_name"));
        user.setPhone(rs.getString("phone"));
        user.setRole(User.Role.valueOf(rs.getString("role")));
        user.setStatus(User.Status.valueOf(rs.getString("status")));
        
        Timestamp createdAt = rs.getTimestamp("created_at");
        if (createdAt != null) {
            user.setCreatedAt(createdAt.toLocalDateTime());
        }
        
        Timestamp updatedAt = rs.getTimestamp("updated_at");
        if (updatedAt != null) {
            user.setUpdatedAt(updatedAt.toLocalDateTime());
        }
        
        Timestamp lastLogin = rs.getTimestamp("last_login");
        if (lastLogin != null) {
            user.setLastLogin(lastLogin.toLocalDateTime());
        }
        
        return user;
    }
}
