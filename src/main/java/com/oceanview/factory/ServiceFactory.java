package com.oceanview.factory;

import com.oceanview.service.*;

/**
 * Service Factory - Factory Pattern
 * Creates Service instances
 * 
 * @author Ocean View Resort Development Team
 * @version 1.0.0
 */
public class ServiceFactory {
    
    /**
     * Get AuthenticationService instance
     * @return AuthenticationService
     */
    public static AuthenticationService getAuthenticationService() {
        return new AuthenticationService();
    }
    
    /**
     * Get ReservationService instance
     * @return ReservationService
     */
    public static ReservationService getReservationService() {
        return new ReservationService();
    }
    
    /**
     * Get RoomService instance
     * @return RoomService
     */
    public static RoomService getRoomService() {
        return new RoomService();
    }
    
    /**
     * Get BillingService instance
     * @return BillingService
     */
    public static BillingService getBillingService() {
        return new BillingService();
    }
    
    /**
     * Get PDFService instance (Singleton)
     * @return PDFService
     */
    public static PDFService getPDFService() {
        return PDFService.getInstance();
    }
    
    /**
     * Get AnalyticsService instance
     * @return AnalyticsService
     */
    public static AnalyticsService getAnalyticsService() {
        return new AnalyticsService();
    }

    /**
     * Get GuestService instance
     * @return GuestService
     */
    public static com.oceanview.service.GuestService getGuestService() {
        return new com.oceanview.service.GuestService();
    }

    /**
     * Get SettingsService instance
     * @return SettingsService
     */
    public static com.oceanview.service.SettingsService getSettingsService() {
        return new com.oceanview.service.SettingsService();
    }
}
