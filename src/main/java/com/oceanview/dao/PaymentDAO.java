package com.oceanview.dao;

import com.oceanview.model.Payment;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.sql.*;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;

/**
 * Payment DAO - Data Access Object for Payment entity
 * 
 * @author Ocean View Resort Development Team
 * @version 1.0.0
 */
public class PaymentDAO extends BaseDAO {
    
    private static final Logger logger = LoggerFactory.getLogger(PaymentDAO.class);
    
    // SQL Queries
    private static final String INSERT_PAYMENT = 
        "INSERT INTO payments (reservation_id, payment_number, amount, payment_method, " +
        "payment_status, transaction_id, notes) VALUES (?, ?, ?, ?, ?, ?, ?)";
    
    private static final String UPDATE_PAYMENT = 
        "UPDATE payments SET amount = ?, payment_method = ?, payment_status = ?, " +
        "transaction_id = ?, notes = ? WHERE payment_id = ?";
    
    private static final String UPDATE_STATUS = 
        "UPDATE payments SET payment_status = ? WHERE payment_id = ?";
    
    private static final String DELETE_PAYMENT = 
        "DELETE FROM payments WHERE payment_id = ?";
    
    private static final String SELECT_BY_ID = 
        "SELECT * FROM payments WHERE payment_id = ?";
    
    private static final String SELECT_BY_NUMBER = 
        "SELECT * FROM payments WHERE payment_number = ?";
    
    private static final String SELECT_BY_RESERVATION = 
        "SELECT * FROM payments WHERE reservation_id = ? ORDER BY payment_date DESC";
    
    private static final String SELECT_ALL = 
        "SELECT * FROM payments ORDER BY payment_date DESC";
    
    private static final String SELECT_BY_STATUS = 
        "SELECT * FROM payments WHERE payment_status = ? ORDER BY payment_date DESC";
    
    private static final String SELECT_BY_METHOD = 
        "SELECT * FROM payments WHERE payment_method = ? ORDER BY payment_date DESC";
    
    private static final String SELECT_BY_DATE_RANGE = 
        "SELECT * FROM payments WHERE DATE(payment_date) BETWEEN ? AND ? " +
        "ORDER BY payment_date DESC";
    
    private static final String SUM_BY_STATUS = 
        "SELECT SUM(amount) FROM payments WHERE payment_status = ?";
    
    private static final String SUM_BY_DATE_RANGE = 
        "SELECT SUM(amount) FROM payments WHERE DATE(payment_date) BETWEEN ? AND ? " +
        "AND payment_status = 'COMPLETED'";
    
    /**
     * Create a new payment
     */
    public int create(Payment payment) throws SQLException {
        Connection conn = null;
        PreparedStatement stmt = null;
        ResultSet rs = null;
        
        try {
            conn = getConnection();
            stmt = conn.prepareStatement(INSERT_PAYMENT, Statement.RETURN_GENERATED_KEYS);
            
            stmt.setInt(1, payment.getReservationId());
            stmt.setString(2, payment.getPaymentNumber());
            stmt.setBigDecimal(3, payment.getAmount());
            stmt.setString(4, payment.getPaymentMethod().name());
            stmt.setString(5, payment.getPaymentStatus().name());
            stmt.setString(6, payment.getTransactionId());
            stmt.setString(7, payment.getNotes());
            
            int affectedRows = stmt.executeUpdate();
            
            if (affectedRows == 0) {
                throw new SQLException("Creating payment failed, no rows affected.");
            }
            
            rs = stmt.getGeneratedKeys();
            if (rs.next()) {
                int paymentId = rs.getInt(1);
                logger.info("Payment created successfully with ID: {}", paymentId);
                return paymentId;
            } else {
                throw new SQLException("Creating payment failed, no ID obtained.");
            }
            
        } catch (SQLException e) {
            logSQLException("create payment", e);
            throw e;
        } finally {
            closeResources(conn, stmt, rs);
        }
    }
    
    /**
     * Update existing payment
     */
    public boolean update(Payment payment) throws SQLException {
        Connection conn = null;
        PreparedStatement stmt = null;
        
        try {
            conn = getConnection();
            stmt = conn.prepareStatement(UPDATE_PAYMENT);
            
            stmt.setBigDecimal(1, payment.getAmount());
            stmt.setString(2, payment.getPaymentMethod().name());
            stmt.setString(3, payment.getPaymentStatus().name());
            stmt.setString(4, payment.getTransactionId());
            stmt.setString(5, payment.getNotes());
            stmt.setInt(6, payment.getPaymentId());
            
            int affectedRows = stmt.executeUpdate();
            logger.info("Payment updated: ID={}, affected rows={}", payment.getPaymentId(), affectedRows);
            
            return affectedRows > 0;
            
        } catch (SQLException e) {
            logSQLException("update payment", e);
            throw e;
        } finally {
            closeResources(conn, stmt);
        }
    }
    
    /**
     * Update payment status
     */
    public boolean updateStatus(int paymentId, Payment.PaymentStatus status) throws SQLException {
        Connection conn = null;
        PreparedStatement stmt = null;
        
        try {
            conn = getConnection();
            stmt = conn.prepareStatement(UPDATE_STATUS);
            
            stmt.setString(1, status.name());
            stmt.setInt(2, paymentId);
            
            int affectedRows = stmt.executeUpdate();
            logger.info("Payment status updated: ID={}, status={}", paymentId, status);
            
            return affectedRows > 0;
            
        } catch (SQLException e) {
            logSQLException("update payment status", e);
            throw e;
        } finally {
            closeResources(conn, stmt);
        }
    }
    
    /**
     * Delete payment
     */
    public boolean delete(int paymentId) throws SQLException {
        Connection conn = null;
        PreparedStatement stmt = null;
        
        try {
            conn = getConnection();
            stmt = conn.prepareStatement(DELETE_PAYMENT);
            stmt.setInt(1, paymentId);
            
            int affectedRows = stmt.executeUpdate();
            logger.info("Payment deleted: ID={}, affected rows={}", paymentId, affectedRows);
            
            return affectedRows > 0;
            
        } catch (SQLException e) {
            logSQLException("delete payment", e);
            throw e;
        } finally {
            closeResources(conn, stmt);
        }
    }
    
    /**
     * Find payment by ID
     */
    public Optional<Payment> findById(int paymentId) throws SQLException {
        Connection conn = null;
        PreparedStatement stmt = null;
        ResultSet rs = null;
        
        try {
            conn = getConnection();
            stmt = conn.prepareStatement(SELECT_BY_ID);
            stmt.setInt(1, paymentId);
            
            rs = stmt.executeQuery();
            
            if (rs.next()) {
                return Optional.of(mapResultSetToPayment(rs));
            }
            
            return Optional.empty();
            
        } catch (SQLException e) {
            logSQLException("find payment by ID", e);
            throw e;
        } finally {
            closeResources(conn, stmt, rs);
        }
    }
    
    /**
     * Find payment by payment number
     */
    public Optional<Payment> findByPaymentNumber(String paymentNumber) throws SQLException {
        Connection conn = null;
        PreparedStatement stmt = null;
        ResultSet rs = null;
        
        try {
            conn = getConnection();
            stmt = conn.prepareStatement(SELECT_BY_NUMBER);
            stmt.setString(1, paymentNumber);
            
            rs = stmt.executeQuery();
            
            if (rs.next()) {
                return Optional.of(mapResultSetToPayment(rs));
            }
            
            return Optional.empty();
            
        } catch (SQLException e) {
            logSQLException("find payment by number", e);
            throw e;
        } finally {
            closeResources(conn, stmt, rs);
        }
    }
    
    /**
     * Find payments by reservation
     */
    public List<Payment> findByReservationId(int reservationId) throws SQLException {
        Connection conn = null;
        PreparedStatement stmt = null;
        ResultSet rs = null;
        List<Payment> payments = new ArrayList<>();
        
        try {
            conn = getConnection();
            stmt = conn.prepareStatement(SELECT_BY_RESERVATION);
            stmt.setInt(1, reservationId);
            rs = stmt.executeQuery();
            
            while (rs.next()) {
                payments.add(mapResultSetToPayment(rs));
            }
            
            logger.debug("Found {} payments for reservation ID: {}", payments.size(), reservationId);
            return payments;
            
        } catch (SQLException e) {
            logSQLException("find payments by reservation", e);
            throw e;
        } finally {
            closeResources(conn, stmt, rs);
        }
    }
    
    /**
     * Find all payments
     */
    public List<Payment> findAll() throws SQLException {
        Connection conn = null;
        PreparedStatement stmt = null;
        ResultSet rs = null;
        List<Payment> payments = new ArrayList<>();
        
        try {
            conn = getConnection();
            stmt = conn.prepareStatement(SELECT_ALL);
            rs = stmt.executeQuery();
            
            while (rs.next()) {
                payments.add(mapResultSetToPayment(rs));
            }
            
            logger.debug("Found {} payments", payments.size());
            return payments;
            
        } catch (SQLException e) {
            logSQLException("find all payments", e);
            throw e;
        } finally {
            closeResources(conn, stmt, rs);
        }
    }
    
    /**
     * Find payments by status
     */
    public List<Payment> findByStatus(Payment.PaymentStatus status) throws SQLException {
        Connection conn = null;
        PreparedStatement stmt = null;
        ResultSet rs = null;
        List<Payment> payments = new ArrayList<>();
        
        try {
            conn = getConnection();
            stmt = conn.prepareStatement(SELECT_BY_STATUS);
            stmt.setString(1, status.name());
            rs = stmt.executeQuery();
            
            while (rs.next()) {
                payments.add(mapResultSetToPayment(rs));
            }
            
            logger.debug("Found {} payments with status: {}", payments.size(), status);
            return payments;
            
        } catch (SQLException e) {
            logSQLException("find payments by status", e);
            throw e;
        } finally {
            closeResources(conn, stmt, rs);
        }
    }
    
    /**
     * Get total revenue (sum of completed payments)
     */
    public double getTotalRevenue() throws SQLException {
        Connection conn = null;
        PreparedStatement stmt = null;
        ResultSet rs = null;
        
        try {
            conn = getConnection();
            stmt = conn.prepareStatement(SUM_BY_STATUS);
            stmt.setString(1, Payment.PaymentStatus.COMPLETED.name());
            rs = stmt.executeQuery();
            
            if (rs.next()) {
                return rs.getDouble(1);
            }
            
            return 0.0;
            
        } catch (SQLException e) {
            logSQLException("get total revenue", e);
            throw e;
        } finally {
            closeResources(conn, stmt, rs);
        }
    }
    
    /**
     * Get monthly revenue
     */
    public double getMonthlyRevenue() throws SQLException {
        Connection conn = null;
        PreparedStatement stmt = null;
        ResultSet rs = null;
        
        String sql = "SELECT COALESCE(SUM(amount), 0) FROM payments " +
                     "WHERE payment_status = 'COMPLETED' " +
                     "AND MONTH(payment_date) = MONTH(CURDATE()) " +
                     "AND YEAR(payment_date) = YEAR(CURDATE())";
        
        try {
            conn = getConnection();
            stmt = conn.prepareStatement(sql);
            rs = stmt.executeQuery();
            
            if (rs.next()) {
                return rs.getDouble(1);
            }
            return 0.0;
            
        } catch (SQLException e) {
            logSQLException("get monthly revenue", e);
            throw e;
        } finally {
            closeResources(conn, stmt, rs);
        }
    }
    
    /**
     * Get today's revenue
     */
    public double getTodayRevenue() throws SQLException {
        Connection conn = null;
        PreparedStatement stmt = null;
        ResultSet rs = null;
        
        String sql = "SELECT COALESCE(SUM(amount), 0) FROM payments " +
                     "WHERE payment_status = 'COMPLETED' " +
                     "AND DATE(payment_date) = CURDATE()";
        
        try {
            conn = getConnection();
            stmt = conn.prepareStatement(sql);
            rs = stmt.executeQuery();
            
            if (rs.next()) {
                return rs.getDouble(1);
            }
            return 0.0;
            
        } catch (SQLException e) {
            logSQLException("get today revenue", e);
            throw e;
        } finally {
            closeResources(conn, stmt, rs);
        }
    }
    
    /**
     * Get yearly revenue
     */
    public double getYearlyRevenue() throws SQLException {
        Connection conn = null;
        PreparedStatement stmt = null;
        ResultSet rs = null;
        
        String sql = "SELECT COALESCE(SUM(amount), 0) FROM payments " +
                     "WHERE payment_status = 'COMPLETED' " +
                     "AND YEAR(payment_date) = YEAR(CURDATE())";
        
        try {
            conn = getConnection();
            stmt = conn.prepareStatement(sql);
            rs = stmt.executeQuery();
            
            if (rs.next()) {
                return rs.getDouble(1);
            }
            return 0.0;
            
        } catch (SQLException e) {
            logSQLException("get yearly revenue", e);
            throw e;
        } finally {
            closeResources(conn, stmt, rs);
        }
    }
    
    /**
     * Map ResultSet to Payment object
     */
    private Payment mapResultSetToPayment(ResultSet rs) throws SQLException {
        Payment payment = new Payment();
        payment.setPaymentId(rs.getInt("payment_id"));
        payment.setReservationId(rs.getInt("reservation_id"));
        payment.setPaymentNumber(rs.getString("payment_number"));
        payment.setAmount(rs.getBigDecimal("amount"));
        payment.setPaymentMethod(Payment.PaymentMethod.valueOf(rs.getString("payment_method")));
        payment.setPaymentStatus(Payment.PaymentStatus.valueOf(rs.getString("payment_status")));
        payment.setTransactionId(rs.getString("transaction_id"));
        payment.setNotes(rs.getString("notes"));
        
        Timestamp paymentDate = rs.getTimestamp("payment_date");
        if (paymentDate != null) {
            payment.setPaymentDate(paymentDate.toLocalDateTime());
        }
        
        return payment;
    }
}
