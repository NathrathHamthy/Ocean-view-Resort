package com.oceanview.dao;

import com.oceanview.model.Guest;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.sql.*;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;

/**
 * Guest DAO - Data Access Object for Guest entity
 * 
 * @author Ocean View Resort Development Team
 * @version 1.0.0
 */
public class GuestDAO extends BaseDAO {
    
    private static final Logger logger = LoggerFactory.getLogger(GuestDAO.class);
    
    // SQL Queries
    private static final String INSERT_GUEST = 
        "INSERT INTO guests (user_id, address, city, country, postal_code, id_type, " +
        "id_number, date_of_birth, gender, preferences) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";
    
    private static final String UPDATE_GUEST = 
        "UPDATE guests SET address = ?, city = ?, country = ?, postal_code = ?, " +
        "id_type = ?, id_number = ?, date_of_birth = ?, gender = ?, preferences = ? " +
        "WHERE guest_id = ?";
    
    private static final String DELETE_GUEST = 
        "DELETE FROM guests WHERE guest_id = ?";
    
    private static final String SELECT_BY_ID = 
        "SELECT * FROM guests WHERE guest_id = ?";
    
    private static final String SELECT_BY_USER_ID = 
        "SELECT * FROM guests WHERE user_id = ?";
    
    private static final String SELECT_ALL = 
        "SELECT * FROM guests ORDER BY created_at DESC";
    
    private static final String SELECT_BY_COUNTRY = 
        "SELECT * FROM guests WHERE country = ? ORDER BY created_at DESC";
    
    /**
     * Create a new guest
     */
    public int create(Guest guest) throws SQLException {
        Connection conn = null;
        PreparedStatement stmt = null;
        ResultSet rs = null;
        
        try {
            conn = getConnection();
            stmt = conn.prepareStatement(INSERT_GUEST, Statement.RETURN_GENERATED_KEYS);
            
            stmt.setInt(1, guest.getUserId());
            stmt.setString(2, guest.getAddress());
            stmt.setString(3, guest.getCity());
            stmt.setString(4, guest.getCountry());
            stmt.setString(5, guest.getPostalCode());
            stmt.setString(6, guest.getIdType());
            stmt.setString(7, guest.getIdNumber());
            
            if (guest.getDateOfBirth() != null) {
                stmt.setDate(8, Date.valueOf(guest.getDateOfBirth()));
            } else {
                stmt.setNull(8, Types.DATE);
            }
            
            if (guest.getGender() != null) {
                stmt.setString(9, guest.getGender().name());
            } else {
                stmt.setNull(9, Types.VARCHAR);
            }
            
            stmt.setString(10, guest.getPreferences());
            
            int affectedRows = stmt.executeUpdate();
            
            if (affectedRows == 0) {
                throw new SQLException("Creating guest failed, no rows affected.");
            }
            
            rs = stmt.getGeneratedKeys();
            if (rs.next()) {
                int guestId = rs.getInt(1);
                logger.info("Guest created successfully with ID: {}", guestId);
                return guestId;
            } else {
                throw new SQLException("Creating guest failed, no ID obtained.");
            }
            
        } catch (SQLException e) {
            logSQLException("create guest", e);
            throw e;
        } finally {
            closeResources(conn, stmt, rs);
        }
    }
    
    /**
     * Update existing guest
     */
    public boolean update(Guest guest) throws SQLException {
        Connection conn = null;
        PreparedStatement stmt = null;
        
        try {
            conn = getConnection();
            stmt = conn.prepareStatement(UPDATE_GUEST);
            
            stmt.setString(1, guest.getAddress());
            stmt.setString(2, guest.getCity());
            stmt.setString(3, guest.getCountry());
            stmt.setString(4, guest.getPostalCode());
            stmt.setString(5, guest.getIdType());
            stmt.setString(6, guest.getIdNumber());
            
            if (guest.getDateOfBirth() != null) {
                stmt.setDate(7, Date.valueOf(guest.getDateOfBirth()));
            } else {
                stmt.setNull(7, Types.DATE);
            }
            
            if (guest.getGender() != null) {
                stmt.setString(8, guest.getGender().name());
            } else {
                stmt.setNull(8, Types.VARCHAR);
            }
            
            stmt.setString(9, guest.getPreferences());
            stmt.setInt(10, guest.getGuestId());
            
            int affectedRows = stmt.executeUpdate();
            logger.info("Guest updated: ID={}, affected rows={}", guest.getGuestId(), affectedRows);
            
            return affectedRows > 0;
            
        } catch (SQLException e) {
            logSQLException("update guest", e);
            throw e;
        } finally {
            closeResources(conn, stmt);
        }
    }
    
    /**
     * Delete guest
     */
    public boolean delete(int guestId) throws SQLException {
        Connection conn = null;
        PreparedStatement stmt = null;
        
        try {
            conn = getConnection();
            stmt = conn.prepareStatement(DELETE_GUEST);
            stmt.setInt(1, guestId);
            
            int affectedRows = stmt.executeUpdate();
            logger.info("Guest deleted: ID={}, affected rows={}", guestId, affectedRows);
            
            return affectedRows > 0;
            
        } catch (SQLException e) {
            logSQLException("delete guest", e);
            throw e;
        } finally {
            closeResources(conn, stmt);
        }
    }
    
    /**
     * Find guest by ID
     */
    public Optional<Guest> findById(int guestId) throws SQLException {
        Connection conn = null;
        PreparedStatement stmt = null;
        ResultSet rs = null;
        
        try {
            conn = getConnection();
            stmt = conn.prepareStatement(SELECT_BY_ID);
            stmt.setInt(1, guestId);
            
            rs = stmt.executeQuery();
            
            if (rs.next()) {
                return Optional.of(mapResultSetToGuest(rs));
            }
            
            return Optional.empty();
            
        } catch (SQLException e) {
            logSQLException("find guest by ID", e);
            throw e;
        } finally {
            closeResources(conn, stmt, rs);
        }
    }
    
    /**
     * Find guest by user ID
     */
    public Optional<Guest> findByUserId(int userId) throws SQLException {
        Connection conn = null;
        PreparedStatement stmt = null;
        ResultSet rs = null;
        
        try {
            conn = getConnection();
            stmt = conn.prepareStatement(SELECT_BY_USER_ID);
            stmt.setInt(1, userId);
            
            rs = stmt.executeQuery();
            
            if (rs.next()) {
                return Optional.of(mapResultSetToGuest(rs));
            }
            
            return Optional.empty();
            
        } catch (SQLException e) {
            logSQLException("find guest by user ID", e);
            throw e;
        } finally {
            closeResources(conn, stmt, rs);
        }
    }
    
    /**
     * Get guest_id for a given user_id — used during booking to resolve the FK
     */
    public int findGuestIdByUserId(int userId) throws SQLException {
        Connection conn = null; PreparedStatement stmt = null; ResultSet rs = null;
        try {
            conn = getConnection();
            stmt = conn.prepareStatement("SELECT guest_id FROM guests WHERE user_id = ? LIMIT 1");
            stmt.setInt(1, userId);
            rs = stmt.executeQuery();
            if (rs.next()) return rs.getInt("guest_id");
            return -1; // not found
        } catch (SQLException e) { logSQLException("find guestId by userId", e); throw e; }
        finally { closeResources(conn, stmt, rs); }
    }

    public List<Guest> findAll() throws SQLException {
        Connection conn = null;
        PreparedStatement stmt = null;
        ResultSet rs = null;
        List<Guest> guests = new ArrayList<>();
        
        try {
            conn = getConnection();
            stmt = conn.prepareStatement(SELECT_ALL);
            rs = stmt.executeQuery();
            
            while (rs.next()) {
                guests.add(mapResultSetToGuest(rs));
            }
            
            logger.debug("Found {} guests", guests.size());
            return guests;
            
        } catch (SQLException e) {
            logSQLException("find all guests", e);
            throw e;
        } finally {
            closeResources(conn, stmt, rs);
        }
    }
    
    /**
     * Map ResultSet to Guest object
     */
    private Guest mapResultSetToGuest(ResultSet rs) throws SQLException {
        Guest guest = new Guest();
        guest.setGuestId(rs.getInt("guest_id"));
        guest.setUserId(rs.getInt("user_id"));
        guest.setAddress(rs.getString("address"));
        guest.setCity(rs.getString("city"));
        guest.setCountry(rs.getString("country"));
        guest.setPostalCode(rs.getString("postal_code"));
        guest.setIdType(rs.getString("id_type"));
        guest.setIdNumber(rs.getString("id_number"));
        
        Date dob = rs.getDate("date_of_birth");
        if (dob != null) {
            guest.setDateOfBirth(dob.toLocalDate());
        }
        
        String gender = rs.getString("gender");
        if (gender != null) {
            guest.setGender(Guest.Gender.valueOf(gender));
        }
        
        guest.setPreferences(rs.getString("preferences"));
        
        Timestamp createdAt = rs.getTimestamp("created_at");
        if (createdAt != null) {
            guest.setCreatedAt(createdAt.toLocalDateTime());
        }
        
        return guest;
    }
}
