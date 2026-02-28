package com.oceanview.factory;

import com.oceanview.dao.*;

/**
 * DAO Factory - Factory Pattern
 * Creates DAO instances
 * 
 * @author Ocean View Resort Development Team
 * @version 1.0.0
 */
public class DAOFactory {
    
    /**
     * Get UserDAO instance
     * @return UserDAO
     */
    public static UserDAO getUserDAO() {
        return new UserDAO();
    }
    
    /**
     * Get GuestDAO instance
     * @return GuestDAO
     */
    public static GuestDAO getGuestDAO() {
        return new GuestDAO();
    }
    
    /**
     * Get RoomDAO instance
     * @return RoomDAO
     */
    public static RoomDAO getRoomDAO() {
        return new RoomDAO();
    }
    
    /**
     * Get ReservationDAO instance
     * @return ReservationDAO
     */
    public static ReservationDAO getReservationDAO() {
        return new ReservationDAO();
    }
    
    /**
     * Get PaymentDAO instance
     * @return PaymentDAO
     */
    public static PaymentDAO getPaymentDAO() {
        return new PaymentDAO();
    }
    
    /**
     * Get ReviewDAO instance
     * @return ReviewDAO
     */
    public static ReviewDAO getReviewDAO() {
        return new ReviewDAO();
    }
    
    /**
     * Get OfferDAO instance
     * @return OfferDAO
     */
    public static OfferDAO getOfferDAO() {
        return new OfferDAO();
    }
    
    /**
     * Get AuditLogDAO instance
     * @return AuditLogDAO
     */
    public static AuditLogDAO getAuditLogDAO() {
        return new AuditLogDAO();
    }

    /**
     * Get SettingsDAO instance
     * @return SettingsDAO
     */
    public static com.oceanview.dao.SettingsDAO getSettingsDAO() {
        return new com.oceanview.dao.SettingsDAO();
    }
}
