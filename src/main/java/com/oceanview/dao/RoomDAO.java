package com.oceanview.dao;

import com.oceanview.model.Room;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.math.BigDecimal;
import java.sql.*;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;

/**
 * Room DAO - Data Access Object for Room entity
 * 
 * @author Ocean View Resort Development Team
 * @version 1.0.0
 */
public class RoomDAO extends BaseDAO {
    
    private static final Logger logger = LoggerFactory.getLogger(RoomDAO.class);
    
    // SQL Queries
    private static final String INSERT_ROOM = 
        "INSERT INTO rooms (room_number, room_type, floor, capacity, price_per_night, " +
        "size, description, amenities, image_url, status) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";
    
    private static final String UPDATE_ROOM = 
        "UPDATE rooms SET room_number = ?, room_type = ?, floor = ?, capacity = ?, " +
        "price_per_night = ?, size = ?, description = ?, amenities = ?, image_url = ?, " +
        "status = ?, updated_at = CURRENT_TIMESTAMP WHERE room_id = ?";
    
    private static final String UPDATE_STATUS = 
        "UPDATE rooms SET status = ?, updated_at = CURRENT_TIMESTAMP WHERE room_id = ?";
    
    private static final String DELETE_ROOM = 
        "DELETE FROM rooms WHERE room_id = ?";
    
    private static final String SELECT_BY_ID = 
        "SELECT * FROM rooms WHERE room_id = ?";
    
    private static final String SELECT_BY_NUMBER = 
        "SELECT * FROM rooms WHERE room_number = ?";
    
    private static final String SELECT_ALL = 
        "SELECT * FROM rooms ORDER BY room_number";
    
    private static final String SELECT_BY_TYPE = 
        "SELECT * FROM rooms WHERE room_type = ? ORDER BY room_number";
    
    private static final String SELECT_BY_STATUS = 
        "SELECT * FROM rooms WHERE status = ? ORDER BY room_number";
    
    private static final String SELECT_AVAILABLE = 
        "SELECT * FROM rooms WHERE status = 'AVAILABLE' ORDER BY room_number";
    
    private static final String SELECT_AVAILABLE_BY_DATE = 
        "SELECT r.* FROM rooms r WHERE r.status = 'AVAILABLE' " +
        "AND r.room_id NOT IN ( " +
        "  SELECT res.room_id FROM reservations res " +
        "  WHERE res.status IN ('CONFIRMED', 'CHECKED_IN') " +
        "  AND (? < res.check_out_date AND ? > res.check_in_date) " +
        ") ORDER BY r.room_number";
    
    private static final String SELECT_AVAILABLE_BY_TYPE_AND_DATE = 
        "SELECT r.* FROM rooms r WHERE r.status = 'AVAILABLE' AND r.room_type = ? " +
        "AND r.room_id NOT IN ( " +
        "  SELECT res.room_id FROM reservations res " +
        "  WHERE res.status IN ('CONFIRMED', 'CHECKED_IN') " +
        "  AND (? < res.check_out_date AND ? > res.check_in_date) " +
        ") ORDER BY r.room_number";
    
    private static final String COUNT_BY_STATUS = 
        "SELECT COUNT(*) FROM rooms WHERE status = ?";
    
    /**
     * Create a new room
     */
    public int create(Room room) throws SQLException {
        Connection conn = null;
        PreparedStatement stmt = null;
        ResultSet rs = null;
        
        try {
            conn = getConnection();
            stmt = conn.prepareStatement(INSERT_ROOM, Statement.RETURN_GENERATED_KEYS);
            
            stmt.setString(1, room.getRoomNumber());
            stmt.setString(2, room.getRoomType().name());
            stmt.setInt(3, room.getFloor());
            stmt.setInt(4, room.getCapacity());
            stmt.setBigDecimal(5, room.getPricePerNight());
            if (room.getSize() != null) {
                stmt.setInt(6, room.getSize());
            } else {
                stmt.setNull(6, java.sql.Types.INTEGER);
            }
            stmt.setString(7, room.getDescription());
            stmt.setString(8, room.getAmenities());
            stmt.setString(9, room.getImageUrl());
            stmt.setString(10, room.getStatus().name());
            
            int affectedRows = stmt.executeUpdate();
            
            if (affectedRows == 0) {
                throw new SQLException("Creating room failed, no rows affected.");
            }
            
            rs = stmt.getGeneratedKeys();
            if (rs.next()) {
                int roomId = rs.getInt(1);
                logger.info("Room created successfully with ID: {}", roomId);
                return roomId;
            } else {
                throw new SQLException("Creating room failed, no ID obtained.");
            }
            
        } catch (SQLException e) {
            logSQLException("create room", e);
            throw e;
        } finally {
            closeResources(conn, stmt, rs);
        }
    }
    
    /**
     * Update existing room
     */
    public boolean update(Room room) throws SQLException {
        Connection conn = null;
        PreparedStatement stmt = null;
        
        try {
            conn = getConnection();
            stmt = conn.prepareStatement(UPDATE_ROOM);
            
            stmt.setString(1, room.getRoomNumber());
            stmt.setString(2, room.getRoomType().name());
            stmt.setInt(3, room.getFloor());
            stmt.setInt(4, room.getCapacity());
            stmt.setBigDecimal(5, room.getPricePerNight());
            if (room.getSize() != null) {
                stmt.setInt(6, room.getSize());
            } else {
                stmt.setNull(6, java.sql.Types.INTEGER);
            }
            stmt.setString(7, room.getDescription());
            stmt.setString(8, room.getAmenities());
            stmt.setString(9, room.getImageUrl());
            stmt.setString(10, room.getStatus().name());
            stmt.setInt(11, room.getRoomId());
            
            int affectedRows = stmt.executeUpdate();
            logger.info("Room updated: ID={}, affected rows={}", room.getRoomId(), affectedRows);
            
            return affectedRows > 0;
            
        } catch (SQLException e) {
            logSQLException("update room", e);
            throw e;
        } finally {
            closeResources(conn, stmt);
        }
    }
    
    /**
     * Update room status
     */
    public boolean updateStatus(int roomId, Room.RoomStatus status) throws SQLException {
        Connection conn = null;
        PreparedStatement stmt = null;
        
        try {
            conn = getConnection();
            stmt = conn.prepareStatement(UPDATE_STATUS);
            
            stmt.setString(1, status.name());
            stmt.setInt(2, roomId);
            
            int affectedRows = stmt.executeUpdate();
            logger.info("Room status updated: ID={}, status={}", roomId, status);
            
            return affectedRows > 0;
            
        } catch (SQLException e) {
            logSQLException("update room status", e);
            throw e;
        } finally {
            closeResources(conn, stmt);
        }
    }
    
    /**
     * Delete room
     */
    public boolean delete(int roomId) throws SQLException {
        Connection conn = null;
        PreparedStatement stmt = null;
        
        try {
            conn = getConnection();
            stmt = conn.prepareStatement(DELETE_ROOM);
            stmt.setInt(1, roomId);
            
            int affectedRows = stmt.executeUpdate();
            logger.info("Room deleted: ID={}, affected rows={}", roomId, affectedRows);
            
            return affectedRows > 0;
            
        } catch (SQLException e) {
            logSQLException("delete room", e);
            throw e;
        } finally {
            closeResources(conn, stmt);
        }
    }
    
    /**
     * Find room by ID
     */
    public Optional<Room> findById(int roomId) throws SQLException {
        Connection conn = null;
        PreparedStatement stmt = null;
        ResultSet rs = null;
        
        try {
            conn = getConnection();
            stmt = conn.prepareStatement(SELECT_BY_ID);
            stmt.setInt(1, roomId);
            
            rs = stmt.executeQuery();
            
            if (rs.next()) {
                return Optional.of(mapResultSetToRoom(rs));
            }
            
            return Optional.empty();
            
        } catch (SQLException e) {
            logSQLException("find room by ID", e);
            throw e;
        } finally {
            closeResources(conn, stmt, rs);
        }
    }
    
    /**
     * Find room by room number
     */
    public Optional<Room> findByRoomNumber(String roomNumber) throws SQLException {
        Connection conn = null;
        PreparedStatement stmt = null;
        ResultSet rs = null;
        
        try {
            conn = getConnection();
            stmt = conn.prepareStatement(SELECT_BY_NUMBER);
            stmt.setString(1, roomNumber);
            
            rs = stmt.executeQuery();
            
            if (rs.next()) {
                return Optional.of(mapResultSetToRoom(rs));
            }
            
            return Optional.empty();
            
        } catch (SQLException e) {
            logSQLException("find room by number", e);
            throw e;
        } finally {
            closeResources(conn, stmt, rs);
        }
    }
    
    /**
     * Find all rooms
     */
    public List<Room> findAll() throws SQLException {
        Connection conn = null;
        PreparedStatement stmt = null;
        ResultSet rs = null;
        List<Room> rooms = new ArrayList<>();
        
        try {
            conn = getConnection();
            stmt = conn.prepareStatement(SELECT_ALL);
            rs = stmt.executeQuery();
            
            while (rs.next()) {
                rooms.add(mapResultSetToRoom(rs));
            }
            
            logger.debug("Found {} rooms", rooms.size());
            return rooms;
            
        } catch (SQLException e) {
            logSQLException("find all rooms", e);
            throw e;
        } finally {
            closeResources(conn, stmt, rs);
        }
    }
    
    /**
     * Find rooms by type
     */
    public List<Room> findByType(Room.RoomType roomType) throws SQLException {
        Connection conn = null;
        PreparedStatement stmt = null;
        ResultSet rs = null;
        List<Room> rooms = new ArrayList<>();
        
        try {
            conn = getConnection();
            stmt = conn.prepareStatement(SELECT_BY_TYPE);
            stmt.setString(1, roomType.name());
            rs = stmt.executeQuery();
            
            while (rs.next()) {
                rooms.add(mapResultSetToRoom(rs));
            }
            
            logger.debug("Found {} rooms of type {}", rooms.size(), roomType);
            return rooms;
            
        } catch (SQLException e) {
            logSQLException("find rooms by type", e);
            throw e;
        } finally {
            closeResources(conn, stmt, rs);
        }
    }
    
    /**
     * Find available rooms
     */
    public List<Room> findAvailableRooms() throws SQLException {
        Connection conn = null;
        PreparedStatement stmt = null;
        ResultSet rs = null;
        List<Room> rooms = new ArrayList<>();
        
        try {
            conn = getConnection();
            stmt = conn.prepareStatement(SELECT_AVAILABLE);
            rs = stmt.executeQuery();
            
            while (rs.next()) {
                rooms.add(mapResultSetToRoom(rs));
            }
            
            logger.debug("Found {} available rooms", rooms.size());
            return rooms;
            
        } catch (SQLException e) {
            logSQLException("find available rooms", e);
            throw e;
        } finally {
            closeResources(conn, stmt, rs);
        }
    }
    
    /**
     * Find available rooms for specific dates
     */
    public List<Room> findAvailableRoomsByDate(LocalDate checkIn, LocalDate checkOut) throws SQLException {
        Connection conn = null;
        PreparedStatement stmt = null;
        ResultSet rs = null;
        List<Room> rooms = new ArrayList<>();
        
        try {
            conn = getConnection();
            stmt = conn.prepareStatement(SELECT_AVAILABLE_BY_DATE);
            stmt.setDate(1, Date.valueOf(checkIn));
            stmt.setDate(2, Date.valueOf(checkOut));
            rs = stmt.executeQuery();
            
            while (rs.next()) {
                rooms.add(mapResultSetToRoom(rs));
            }
            
            logger.debug("Found {} available rooms for dates {} to {}", 
                        rooms.size(), checkIn, checkOut);
            return rooms;
            
        } catch (SQLException e) {
            logSQLException("find available rooms by date", e);
            throw e;
        } finally {
            closeResources(conn, stmt, rs);
        }
    }
    
    /**
     * Find available rooms by type and date
     */
    public List<Room> findAvailableRoomsByTypeAndDate(Room.RoomType roomType, 
                                                       LocalDate checkIn, 
                                                       LocalDate checkOut) throws SQLException {
        Connection conn = null;
        PreparedStatement stmt = null;
        ResultSet rs = null;
        List<Room> rooms = new ArrayList<>();
        
        try {
            conn = getConnection();
            stmt = conn.prepareStatement(SELECT_AVAILABLE_BY_TYPE_AND_DATE);
            stmt.setString(1, roomType.name());
            stmt.setDate(2, Date.valueOf(checkIn));
            stmt.setDate(3, Date.valueOf(checkOut));
            rs = stmt.executeQuery();
            
            while (rs.next()) {
                rooms.add(mapResultSetToRoom(rs));
            }
            
            logger.debug("Found {} available {} rooms for dates {} to {}", 
                        rooms.size(), roomType, checkIn, checkOut);
            return rooms;
            
        } catch (SQLException e) {
            logSQLException("find available rooms by type and date", e);
            throw e;
        } finally {
            closeResources(conn, stmt, rs);
        }
    }
    
    /**
     * Count rooms by status
     */
    public int countByStatus(String status) throws SQLException {
        Connection conn = null;
        PreparedStatement stmt = null;
        ResultSet rs = null;
        
        try {
            conn = getConnection();
            stmt = conn.prepareStatement(COUNT_BY_STATUS);
            stmt.setString(1, status);
            rs = stmt.executeQuery();
            
            if (rs.next()) {
                return rs.getInt(1);
            }
            
            return 0;
            
        } catch (SQLException e) {
            logSQLException("count rooms by status", e);
            throw e;
        } finally {
            closeResources(conn, stmt, rs);
        }
    }
    
    /**
     * Count all rooms
     */
    public int count() throws SQLException {
        Connection conn = null;
        PreparedStatement stmt = null;
        ResultSet rs = null;
        
        String sql = "SELECT COUNT(*) FROM rooms";
        
        try {
            conn = getConnection();
            stmt = conn.prepareStatement(sql);
            rs = stmt.executeQuery();
            
            if (rs.next()) {
                return rs.getInt(1);
            }
            
            return 0;
            
        } catch (SQLException e) {
            logSQLException("count rooms", e);
            throw e;
        } finally {
            closeResources(conn, stmt, rs);
        }
    }
    
    /**
     * Map ResultSet to Room object
     */
    private Room mapResultSetToRoom(ResultSet rs) throws SQLException {
        Room room = new Room();
        room.setRoomId(rs.getInt("room_id"));
        room.setRoomNumber(rs.getString("room_number"));
        room.setRoomType(Room.RoomType.valueOf(rs.getString("room_type")));
        room.setFloor(rs.getInt("floor"));
        room.setCapacity(rs.getInt("capacity"));
        room.setPricePerNight(rs.getBigDecimal("price_per_night"));
        room.setDescription(rs.getString("description"));
        room.setAmenities(rs.getString("amenities"));
        room.setImageUrl(rs.getString("image_url"));
        room.setStatus(Room.RoomStatus.valueOf(rs.getString("status")));
        
        Timestamp createdAt = rs.getTimestamp("created_at");
        if (createdAt != null) {
            room.setCreatedAt(createdAt.toLocalDateTime());
        }
        
        Timestamp updatedAt = rs.getTimestamp("updated_at");
        if (updatedAt != null) {
            room.setUpdatedAt(updatedAt.toLocalDateTime());
        }
        
        return room;
    }
}
