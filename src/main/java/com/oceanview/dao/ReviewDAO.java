package com.oceanview.dao;

import com.oceanview.model.Review;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.sql.*;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;

/**
 * Review DAO - Data Access Object for Review entity
 * 
 * @author Ocean View Resort Development Team
 * @version 1.0.0
 */
public class ReviewDAO extends BaseDAO {
    
    private static final Logger logger = LoggerFactory.getLogger(ReviewDAO.class);
    
    // SQL Queries
    private static final String INSERT_REVIEW = 
        "INSERT INTO reviews (reservation_id, guest_id, rating, cleanliness_rating, " +
        "service_rating, value_rating, comment, status) VALUES (?, ?, ?, ?, ?, ?, ?, ?)";
    
    private static final String UPDATE_REVIEW = 
        "UPDATE reviews SET rating = ?, cleanliness_rating = ?, service_rating = ?, " +
        "value_rating = ?, comment = ?, status = ? WHERE review_id = ?";
    
    private static final String UPDATE_STATUS = 
        "UPDATE reviews SET status = ? WHERE review_id = ?";
    
    private static final String UPDATE_RESPONSE = 
        "UPDATE reviews SET response = ? WHERE review_id = ?";
    
    private static final String DELETE_REVIEW = 
        "DELETE FROM reviews WHERE review_id = ?";
    
    private static final String SELECT_BY_ID = 
        "SELECT * FROM reviews WHERE review_id = ?";
    
    private static final String SELECT_BY_RESERVATION = 
        "SELECT * FROM reviews WHERE reservation_id = ?";
    
    private static final String SELECT_BY_GUEST = 
        "SELECT * FROM reviews WHERE guest_id = ? ORDER BY created_at DESC";
    
    private static final String SELECT_ALL = 
        "SELECT * FROM reviews ORDER BY created_at DESC";
    
    private static final String SELECT_BY_STATUS = 
        "SELECT * FROM reviews WHERE status = ? ORDER BY created_at DESC";
    
    private static final String SELECT_APPROVED = 
        "SELECT * FROM reviews WHERE status = 'APPROVED' ORDER BY created_at DESC LIMIT ?";
    
    private static final String AVG_RATING = 
        "SELECT AVG(rating) FROM reviews WHERE status = 'APPROVED'";
    
    private static final String COUNT_BY_RATING = 
        "SELECT COUNT(*) FROM reviews WHERE rating = ? AND status = 'APPROVED'";
    
    /**
     * Create a new review
     */
    public int create(Review review) throws SQLException {
        Connection conn = null;
        PreparedStatement stmt = null;
        ResultSet rs = null;
        
        try {
            conn = getConnection();
            stmt = conn.prepareStatement(INSERT_REVIEW, Statement.RETURN_GENERATED_KEYS);
            
            stmt.setInt(1, review.getReservationId());
            stmt.setInt(2, review.getGuestId());
            stmt.setInt(3, review.getRating());
            
            if (review.getCleanlinessRating() != null) {
                stmt.setInt(4, review.getCleanlinessRating());
            } else {
                stmt.setNull(4, Types.INTEGER);
            }
            
            if (review.getServiceRating() != null) {
                stmt.setInt(5, review.getServiceRating());
            } else {
                stmt.setNull(5, Types.INTEGER);
            }
            
            if (review.getValueRating() != null) {
                stmt.setInt(6, review.getValueRating());
            } else {
                stmt.setNull(6, Types.INTEGER);
            }
            
            stmt.setString(7, review.getComment());
            stmt.setString(8, review.getStatus().name());
            
            int affectedRows = stmt.executeUpdate();
            
            if (affectedRows == 0) {
                throw new SQLException("Creating review failed, no rows affected.");
            }
            
            rs = stmt.getGeneratedKeys();
            if (rs.next()) {
                int reviewId = rs.getInt(1);
                logger.info("Review created successfully with ID: {}", reviewId);
                return reviewId;
            } else {
                throw new SQLException("Creating review failed, no ID obtained.");
            }
            
        } catch (SQLException e) {
            logSQLException("create review", e);
            throw e;
        } finally {
            closeResources(conn, stmt, rs);
        }
    }
    
    /**
     * Update existing review
     */
    public boolean update(Review review) throws SQLException {
        Connection conn = null;
        PreparedStatement stmt = null;
        
        try {
            conn = getConnection();
            stmt = conn.prepareStatement(UPDATE_REVIEW);
            
            stmt.setInt(1, review.getRating());
            
            if (review.getCleanlinessRating() != null) {
                stmt.setInt(2, review.getCleanlinessRating());
            } else {
                stmt.setNull(2, Types.INTEGER);
            }
            
            if (review.getServiceRating() != null) {
                stmt.setInt(3, review.getServiceRating());
            } else {
                stmt.setNull(3, Types.INTEGER);
            }
            
            if (review.getValueRating() != null) {
                stmt.setInt(4, review.getValueRating());
            } else {
                stmt.setNull(4, Types.INTEGER);
            }
            
            stmt.setString(5, review.getComment());
            stmt.setString(6, review.getStatus().name());
            stmt.setInt(7, review.getReviewId());
            
            int affectedRows = stmt.executeUpdate();
            logger.info("Review updated: ID={}, affected rows={}", review.getReviewId(), affectedRows);
            
            return affectedRows > 0;
            
        } catch (SQLException e) {
            logSQLException("update review", e);
            throw e;
        } finally {
            closeResources(conn, stmt);
        }
    }
    
    /**
     * Update review status
     */
    public boolean updateStatus(int reviewId, Review.ReviewStatus status) throws SQLException {
        Connection conn = null;
        PreparedStatement stmt = null;
        
        try {
            conn = getConnection();
            stmt = conn.prepareStatement(UPDATE_STATUS);
            
            stmt.setString(1, status.name());
            stmt.setInt(2, reviewId);
            
            int affectedRows = stmt.executeUpdate();
            logger.info("Review status updated: ID={}, status={}", reviewId, status);
            
            return affectedRows > 0;
            
        } catch (SQLException e) {
            logSQLException("update review status", e);
            throw e;
        } finally {
            closeResources(conn, stmt);
        }
    }
    
    /**
     * Add response to review
     */
    public boolean addResponse(int reviewId, String response) throws SQLException {
        Connection conn = null;
        PreparedStatement stmt = null;
        
        try {
            conn = getConnection();
            stmt = conn.prepareStatement(UPDATE_RESPONSE);
            
            stmt.setString(1, response);
            stmt.setInt(2, reviewId);
            
            int affectedRows = stmt.executeUpdate();
            logger.info("Review response added: ID={}", reviewId);
            
            return affectedRows > 0;
            
        } catch (SQLException e) {
            logSQLException("add review response", e);
            throw e;
        } finally {
            closeResources(conn, stmt);
        }
    }
    
    /**
     * Delete review
     */
    public boolean delete(int reviewId) throws SQLException {
        Connection conn = null;
        PreparedStatement stmt = null;
        
        try {
            conn = getConnection();
            stmt = conn.prepareStatement(DELETE_REVIEW);
            stmt.setInt(1, reviewId);
            
            int affectedRows = stmt.executeUpdate();
            logger.info("Review deleted: ID={}, affected rows={}", reviewId, affectedRows);
            
            return affectedRows > 0;
            
        } catch (SQLException e) {
            logSQLException("delete review", e);
            throw e;
        } finally {
            closeResources(conn, stmt);
        }
    }
    
    /**
     * Find review by ID
     */
    public Optional<Review> findById(int reviewId) throws SQLException {
        Connection conn = null;
        PreparedStatement stmt = null;
        ResultSet rs = null;
        
        try {
            conn = getConnection();
            stmt = conn.prepareStatement(SELECT_BY_ID);
            stmt.setInt(1, reviewId);
            
            rs = stmt.executeQuery();
            
            if (rs.next()) {
                return Optional.of(mapResultSetToReview(rs));
            }
            
            return Optional.empty();
            
        } catch (SQLException e) {
            logSQLException("find review by ID", e);
            throw e;
        } finally {
            closeResources(conn, stmt, rs);
        }
    }
    
    /**
     * Find reviews by guest
     */
    public List<Review> findByGuestId(int guestId) throws SQLException {
        Connection conn = null;
        PreparedStatement stmt = null;
        ResultSet rs = null;
        List<Review> reviews = new ArrayList<>();
        
        try {
            conn = getConnection();
            stmt = conn.prepareStatement(SELECT_BY_GUEST);
            stmt.setInt(1, guestId);
            rs = stmt.executeQuery();
            
            while (rs.next()) {
                reviews.add(mapResultSetToReview(rs));
            }
            
            logger.debug("Found {} reviews for guest ID: {}", reviews.size(), guestId);
            return reviews;
            
        } catch (SQLException e) {
            logSQLException("find reviews by guest", e);
            throw e;
        } finally {
            closeResources(conn, stmt, rs);
        }
    }
    
    /**
     * Find all reviews
     */
    public List<Review> findAll() throws SQLException {
        Connection conn = null;
        PreparedStatement stmt = null;
        ResultSet rs = null;
        List<Review> reviews = new ArrayList<>();
        
        try {
            conn = getConnection();
            stmt = conn.prepareStatement(SELECT_ALL);
            rs = stmt.executeQuery();
            
            while (rs.next()) {
                reviews.add(mapResultSetToReview(rs));
            }
            
            logger.debug("Found {} reviews", reviews.size());
            return reviews;
            
        } catch (SQLException e) {
            logSQLException("find all reviews", e);
            throw e;
        } finally {
            closeResources(conn, stmt, rs);
        }
    }
    
    /**
     * Find approved reviews
     */
    public List<Review> findApprovedReviews(int limit) throws SQLException {
        Connection conn = null;
        PreparedStatement stmt = null;
        ResultSet rs = null;
        List<Review> reviews = new ArrayList<>();
        
        try {
            conn = getConnection();
            stmt = conn.prepareStatement(SELECT_APPROVED);
            stmt.setInt(1, limit);
            rs = stmt.executeQuery();
            
            while (rs.next()) {
                reviews.add(mapResultSetToReview(rs));
            }
            
            logger.debug("Found {} approved reviews", reviews.size());
            return reviews;
            
        } catch (SQLException e) {
            logSQLException("find approved reviews", e);
            throw e;
        } finally {
            closeResources(conn, stmt, rs);
        }
    }
    
    /**
     * Find pending reviews
     */
    public List<Review> findPendingReviews() throws SQLException {
        Connection conn = null;
        PreparedStatement stmt = null;
        ResultSet rs = null;
        List<Review> reviews = new ArrayList<>();
        
        try {
            conn = getConnection();
            stmt = conn.prepareStatement(SELECT_BY_STATUS);
            stmt.setString(1, Review.ReviewStatus.PENDING.name());
            rs = stmt.executeQuery();
            
            while (rs.next()) {
                reviews.add(mapResultSetToReview(rs));
            }
            
            logger.debug("Found {} pending reviews", reviews.size());
            return reviews;
            
        } catch (SQLException e) {
            logSQLException("find pending reviews", e);
            throw e;
        } finally {
            closeResources(conn, stmt, rs);
        }
    }
    
    /**
     * Get average rating
     */
    public double getAverageRating() throws SQLException {
        Connection conn = null;
        PreparedStatement stmt = null;
        ResultSet rs = null;
        
        try {
            conn = getConnection();
            stmt = conn.prepareStatement(AVG_RATING);
            rs = stmt.executeQuery();
            
            if (rs.next()) {
                return rs.getDouble(1);
            }
            
            return 0.0;
            
        } catch (SQLException e) {
            logSQLException("get average rating", e);
            throw e;
        } finally {
            closeResources(conn, stmt, rs);
        }
    }
    
    /**
     * Count all reviews
     */
    public int count() throws SQLException {
        Connection conn = null;
        PreparedStatement stmt = null;
        ResultSet rs = null;
        
        String sql = "SELECT COUNT(*) FROM reviews";
        
        try {
            conn = getConnection();
            stmt = conn.prepareStatement(sql);
            rs = stmt.executeQuery();
            
            if (rs.next()) {
                return rs.getInt(1);
            }
            return 0;
            
        } catch (SQLException e) {
            logSQLException("count reviews", e);
            throw e;
        } finally {
            closeResources(conn, stmt, rs);
        }
    }
    
    /**
     * Count reviews by status
     */
    public int countByStatus(String status) throws SQLException {
        Connection conn = null;
        PreparedStatement stmt = null;
        ResultSet rs = null;
        
        String sql = "SELECT COUNT(*) FROM reviews WHERE status = ?";
        
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
            logSQLException("count reviews by status", e);
            throw e;
        } finally {
            closeResources(conn, stmt, rs);
        }
    }
    
    /**
     * Count reviews by guest ID
     */
    public int countByGuestId(int guestId) throws SQLException {
        Connection conn = null;
        PreparedStatement stmt = null;
        ResultSet rs = null;
        
        String sql = "SELECT COUNT(*) FROM reviews WHERE guest_id = ?";
        
        try {
            conn = getConnection();
            stmt = conn.prepareStatement(sql);
            stmt.setInt(1, guestId);
            rs = stmt.executeQuery();
            
            if (rs.next()) {
                return rs.getInt(1);
            }
            return 0;
            
        } catch (SQLException e) {
            logSQLException("count reviews by guest", e);
            throw e;
        } finally {
            closeResources(conn, stmt, rs);
        }
    }
    
    /**
     * Map ResultSet to Review object
     */
    private Review mapResultSetToReview(ResultSet rs) throws SQLException {
        Review review = new Review();
        review.setReviewId(rs.getInt("review_id"));
        review.setReservationId(rs.getInt("reservation_id"));
        review.setGuestId(rs.getInt("guest_id"));
        review.setRating(rs.getInt("rating"));
        
        int cleanlinessRating = rs.getInt("cleanliness_rating");
        if (!rs.wasNull()) {
            review.setCleanlinessRating(cleanlinessRating);
        }
        
        int serviceRating = rs.getInt("service_rating");
        if (!rs.wasNull()) {
            review.setServiceRating(serviceRating);
        }
        
        int valueRating = rs.getInt("value_rating");
        if (!rs.wasNull()) {
            review.setValueRating(valueRating);
        }
        
        review.setComment(rs.getString("comment"));
        review.setResponse(rs.getString("response"));
        review.setStatus(Review.ReviewStatus.valueOf(rs.getString("status")));
        
        Timestamp createdAt = rs.getTimestamp("created_at");
        if (createdAt != null) {
            review.setCreatedAt(createdAt.toLocalDateTime());
        }
        
        return review;
    }
}
