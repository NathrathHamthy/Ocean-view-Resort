package com.oceanview.dao;

import com.oceanview.model.Offer;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.sql.*;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;

/**
 * Offer DAO - Data Access Object for Offer entity
 * 
 * @author Ocean View Resort Development Team
 * @version 1.0.0
 */
public class OfferDAO extends BaseDAO {
    
    private static final Logger logger = LoggerFactory.getLogger(OfferDAO.class);
    
    // SQL Queries
    private static final String INSERT_OFFER = 
        "INSERT INTO offers (title, description, discount_type, discount_value, " +
        "start_date, end_date, applicable_rooms, min_nights, promo_code, used_count, max_uses, status) " +
        "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";
    
    private static final String UPDATE_OFFER = 
        "UPDATE offers SET title = ?, description = ?, discount_type = ?, " +
        "discount_value = ?, start_date = ?, end_date = ?, applicable_rooms = ?, " +
        "min_nights = ?, promo_code = ?, used_count = ?, max_uses = ?, status = ? WHERE offer_id = ?";
    
    private static final String UPDATE_STATUS = 
        "UPDATE offers SET status = ? WHERE offer_id = ?";
    
    private static final String DELETE_OFFER = 
        "DELETE FROM offers WHERE offer_id = ?";
    
    private static final String SELECT_BY_ID = 
        "SELECT * FROM offers WHERE offer_id = ?";
    
    private static final String SELECT_ALL = 
        "SELECT * FROM offers ORDER BY created_at DESC";
    
    private static final String SELECT_ACTIVE = 
        "SELECT * FROM offers WHERE status = 'ACTIVE' AND start_date <= CURDATE() " +
        "AND end_date >= CURDATE() ORDER BY created_at DESC";
    
    private static final String SELECT_BY_STATUS = 
        "SELECT * FROM offers WHERE status = ? ORDER BY created_at DESC";
    
    private static final String SELECT_UPCOMING = 
        "SELECT * FROM offers WHERE status = 'ACTIVE' AND start_date > CURDATE() " +
        "ORDER BY start_date";
    
    private static final String UPDATE_EXPIRED = 
        "UPDATE offers SET status = 'EXPIRED' WHERE status = 'ACTIVE' AND end_date < CURDATE()";
    
    /**
     * Create a new offer
     */
    public int create(Offer offer) throws SQLException {
        Connection conn = null;
        PreparedStatement stmt = null;
        ResultSet rs = null;
        
        try {
            conn = getConnection();
            stmt = conn.prepareStatement(INSERT_OFFER, Statement.RETURN_GENERATED_KEYS);
            
            stmt.setString(1, offer.getTitle());
            stmt.setString(2, offer.getDescription());
            stmt.setString(3, offer.getDiscountType().name());
            stmt.setBigDecimal(4, offer.getDiscountValue());
            stmt.setDate(5, Date.valueOf(offer.getStartDate()));
            stmt.setDate(6, Date.valueOf(offer.getEndDate()));
            stmt.setString(7, offer.getApplicableRooms());
            stmt.setInt(8, offer.getMinNights());
            stmt.setString(9, offer.getPromoCode());
            stmt.setInt(10, offer.getUsedCount());
            if (offer.getMaxUses() != null) {
                stmt.setInt(11, offer.getMaxUses());
            } else {
                stmt.setNull(11, Types.INTEGER);
            }
            stmt.setString(12, offer.getStatus().name());
            
            int affectedRows = stmt.executeUpdate();
            
            if (affectedRows == 0) {
                throw new SQLException("Creating offer failed, no rows affected.");
            }
            
            rs = stmt.getGeneratedKeys();
            if (rs.next()) {
                int offerId = rs.getInt(1);
                logger.info("Offer created successfully with ID: {}", offerId);
                return offerId;
            } else {
                throw new SQLException("Creating offer failed, no ID obtained.");
            }
            
        } catch (SQLException e) {
            logSQLException("create offer", e);
            throw e;
        } finally {
            closeResources(conn, stmt, rs);
        }
    }
    
    /**
     * Update existing offer
     */
    public boolean update(Offer offer) throws SQLException {
        Connection conn = null;
        PreparedStatement stmt = null;
        
        try {
            conn = getConnection();
            stmt = conn.prepareStatement(UPDATE_OFFER);
            
            stmt.setString(1, offer.getTitle());
            stmt.setString(2, offer.getDescription());
            stmt.setString(3, offer.getDiscountType().name());
            stmt.setBigDecimal(4, offer.getDiscountValue());
            stmt.setDate(5, Date.valueOf(offer.getStartDate()));
            stmt.setDate(6, Date.valueOf(offer.getEndDate()));
            stmt.setString(7, offer.getApplicableRooms());
            stmt.setInt(8, offer.getMinNights());
            stmt.setString(9, offer.getPromoCode());
            stmt.setInt(10, offer.getUsedCount());
            if (offer.getMaxUses() != null) {
                stmt.setInt(11, offer.getMaxUses());
            } else {
                stmt.setNull(11, Types.INTEGER);
            }
            stmt.setString(12, offer.getStatus().name());
            stmt.setInt(13, offer.getOfferId());
            
            int affectedRows = stmt.executeUpdate();
            logger.info("Offer updated: ID={}, affected rows={}", offer.getOfferId(), affectedRows);
            
            return affectedRows > 0;
            
        } catch (SQLException e) {
            logSQLException("update offer", e);
            throw e;
        } finally {
            closeResources(conn, stmt);
        }
    }
    
    /**
     * Update offer status
     */
    public boolean updateStatus(int offerId, Offer.OfferStatus status) throws SQLException {
        Connection conn = null;
        PreparedStatement stmt = null;
        
        try {
            conn = getConnection();
            stmt = conn.prepareStatement(UPDATE_STATUS);
            
            stmt.setString(1, status.name());
            stmt.setInt(2, offerId);
            
            int affectedRows = stmt.executeUpdate();
            logger.info("Offer status updated: ID={}, status={}", offerId, status);
            
            return affectedRows > 0;
            
        } catch (SQLException e) {
            logSQLException("update offer status", e);
            throw e;
        } finally {
            closeResources(conn, stmt);
        }
    }
    
    /**
     * Delete offer
     */
    public boolean delete(int offerId) throws SQLException {
        Connection conn = null;
        PreparedStatement stmt = null;
        
        try {
            conn = getConnection();
            stmt = conn.prepareStatement(DELETE_OFFER);
            stmt.setInt(1, offerId);
            
            int affectedRows = stmt.executeUpdate();
            logger.info("Offer deleted: ID={}, affected rows={}", offerId, affectedRows);
            
            return affectedRows > 0;
            
        } catch (SQLException e) {
            logSQLException("delete offer", e);
            throw e;
        } finally {
            closeResources(conn, stmt);
        }
    }
    
    /**
     * Find offer by ID
     */
    public Optional<Offer> findById(int offerId) throws SQLException {
        Connection conn = null;
        PreparedStatement stmt = null;
        ResultSet rs = null;
        
        try {
            conn = getConnection();
            stmt = conn.prepareStatement(SELECT_BY_ID);
            stmt.setInt(1, offerId);
            
            rs = stmt.executeQuery();
            
            if (rs.next()) {
                return Optional.of(mapResultSetToOffer(rs));
            }
            
            return Optional.empty();
            
        } catch (SQLException e) {
            logSQLException("find offer by ID", e);
            throw e;
        } finally {
            closeResources(conn, stmt, rs);
        }
    }
    
    /**
     * Find all offers
     */
    public List<Offer> findAll() throws SQLException {
        Connection conn = null;
        PreparedStatement stmt = null;
        ResultSet rs = null;
        List<Offer> offers = new ArrayList<>();
        
        try {
            conn = getConnection();
            stmt = conn.prepareStatement(SELECT_ALL);
            rs = stmt.executeQuery();
            
            while (rs.next()) {
                offers.add(mapResultSetToOffer(rs));
            }
            
            logger.debug("Found {} offers", offers.size());
            return offers;
            
        } catch (SQLException e) {
            logSQLException("find all offers", e);
            throw e;
        } finally {
            closeResources(conn, stmt, rs);
        }
    }
    
    /**
     * Find active offers
     */
    public List<Offer> findActiveOffers() throws SQLException {
        Connection conn = null;
        PreparedStatement stmt = null;
        ResultSet rs = null;
        List<Offer> offers = new ArrayList<>();
        
        try {
            conn = getConnection();
            stmt = conn.prepareStatement(SELECT_ACTIVE);
            rs = stmt.executeQuery();
            
            while (rs.next()) {
                offers.add(mapResultSetToOffer(rs));
            }
            
            logger.debug("Found {} active offers", offers.size());
            return offers;
            
        } catch (SQLException e) {
            logSQLException("find active offers", e);
            throw e;
        } finally {
            closeResources(conn, stmt, rs);
        }
    }
    
    /**
     * Find offer by promo code
     */
    public Offer findByPromoCode(String promoCode) throws SQLException {
        Connection conn = null;
        PreparedStatement stmt = null;
        ResultSet rs = null;
        try {
            conn = getConnection();
            stmt = conn.prepareStatement(
                "SELECT * FROM offers WHERE promo_code = ? AND status = 'ACTIVE' " +
                "AND start_date <= CURDATE() AND end_date >= CURDATE() LIMIT 1");
            stmt.setString(1, promoCode);
            rs = stmt.executeQuery();
            if (rs.next()) return mapResultSetToOffer(rs);
            return null;
        } catch (SQLException e) {
            logSQLException("find offer by promo code", e);
            throw e;
        } finally {
            closeResources(conn, stmt, rs);
        }
    }

    /**
     * Update expired offers
     */
    public int updateExpiredOffers() throws SQLException {
        Connection conn = null;
        PreparedStatement stmt = null;
        
        try {
            conn = getConnection();
            stmt = conn.prepareStatement(UPDATE_EXPIRED);
            
            int affectedRows = stmt.executeUpdate();
            logger.info("Updated {} expired offers", affectedRows);
            
            return affectedRows;
            
        } catch (SQLException e) {
            logSQLException("update expired offers", e);
            throw e;
        } finally {
            closeResources(conn, stmt);
        }
    }
    
    /**
     * Map ResultSet to Offer object
     */
    private Offer mapResultSetToOffer(ResultSet rs) throws SQLException {
        Offer offer = new Offer();
        offer.setOfferId(rs.getInt("offer_id"));
        offer.setTitle(rs.getString("title"));
        offer.setDescription(rs.getString("description"));
        offer.setDiscountType(Offer.DiscountType.valueOf(rs.getString("discount_type")));
        offer.setDiscountValue(rs.getBigDecimal("discount_value"));
        offer.setStartDate(rs.getDate("start_date").toLocalDate());
        offer.setEndDate(rs.getDate("end_date").toLocalDate());
        offer.setApplicableRooms(rs.getString("applicable_rooms"));
        offer.setMinNights(rs.getInt("min_nights"));
        offer.setPromoCode(rs.getString("promo_code"));
        offer.setUsedCount(rs.getInt("used_count"));
        
        // Handle nullable max_uses
        int maxUses = rs.getInt("max_uses");
        if (!rs.wasNull()) {
            offer.setMaxUses(maxUses);
        }
        
        offer.setStatus(Offer.OfferStatus.valueOf(rs.getString("status")));
        
        Timestamp createdAt = rs.getTimestamp("created_at");
        if (createdAt != null) {
            offer.setCreatedAt(createdAt.toLocalDateTime());
        }
        
        return offer;
    }
}
