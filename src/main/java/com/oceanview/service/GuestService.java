package com.oceanview.service;

import com.oceanview.dao.GuestDAO;
import com.oceanview.dao.ReservationDAO;
import com.oceanview.dao.ReviewDAO;
import com.oceanview.dao.OfferDAO;
import com.oceanview.factory.DAOFactory;
import com.oceanview.model.Guest;
import com.oceanview.model.Reservation;
import com.oceanview.model.Review;
import com.oceanview.model.Offer;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.math.BigDecimal;
import java.sql.SQLException;
import java.util.*;

/**
 * Guest Service - Business logic for guest operations
 * 
 * @author Ocean View Resort Development Team
 * @version 1.0.0
 */
public class GuestService {
    
    private static final Logger logger = LoggerFactory.getLogger(GuestService.class);
    
    private final GuestDAO guestDAO;
    private final ReservationDAO reservationDAO;
    private final ReviewDAO reviewDAO;
    private final OfferDAO offerDAO;
    
    public GuestService() {
        this.guestDAO = DAOFactory.getGuestDAO();
        this.reservationDAO = DAOFactory.getReservationDAO();
        this.reviewDAO = DAOFactory.getReviewDAO();
        this.offerDAO = DAOFactory.getOfferDAO();
    }
    
    /**
     * DTO for guest dashboard statistics
     */
    public static class GuestStatistics {
        private int activeBookingsCount;
        private int reviewsWrittenCount;
        private int totalStaysCount;
        private int loyaltyPoints;
        private Reservation currentBooking;
        private List<Offer> activeOffers;
        
        public GuestStatistics() {
            this.activeOffers = new ArrayList<>();
        }
        
        // Getters and Setters
        public int getActiveBookingsCount() {
            return activeBookingsCount;
        }
        
        public void setActiveBookingsCount(int activeBookingsCount) {
            this.activeBookingsCount = activeBookingsCount;
        }
        
        public int getReviewsWrittenCount() {
            return reviewsWrittenCount;
        }
        
        public void setReviewsWrittenCount(int reviewsWrittenCount) {
            this.reviewsWrittenCount = reviewsWrittenCount;
        }
        
        public int getTotalStaysCount() {
            return totalStaysCount;
        }
        
        public void setTotalStaysCount(int totalStaysCount) {
            this.totalStaysCount = totalStaysCount;
        }
        
        public int getLoyaltyPoints() {
            return loyaltyPoints;
        }
        
        public void setLoyaltyPoints(int loyaltyPoints) {
            this.loyaltyPoints = loyaltyPoints;
        }
        
        public Reservation getCurrentBooking() {
            return currentBooking;
        }
        
        public void setCurrentBooking(Reservation currentBooking) {
            this.currentBooking = currentBooking;
        }
        
        public List<Offer> getActiveOffers() {
            return activeOffers;
        }
        
        public void setActiveOffers(List<Offer> activeOffers) {
            this.activeOffers = activeOffers;
        }
    }
    
    /**
     * Get comprehensive guest statistics for dashboard
     */
    public GuestStatistics getGuestStatistics(int userId) throws SQLException {
        logger.info("Fetching guest statistics for user ID: {}", userId);

        GuestStatistics stats = new GuestStatistics();

        try {
            // Get guest profile — auto-create one if missing (handles legacy/seeded accounts)
            Optional<Guest> guestOpt = guestDAO.findByUserId(userId);
            if (!guestOpt.isPresent()) {
                logger.warn("Guest profile not found for user ID: {} — auto-creating one", userId);
                try {
                    Guest newGuest = new Guest();
                    newGuest.setUserId(userId);
                    int newGuestId = guestDAO.create(newGuest);
                    if (newGuestId > 0) {
                        guestOpt = guestDAO.findByUserId(userId);
                    }
                } catch (SQLException createEx) {
                    logger.error("Could not auto-create guest profile for userId={}", userId, createEx);
                }
                // If still not present, return empty stats — nothing more we can do
                if (!guestOpt.isPresent()) {
                    logger.error("Guest profile still missing for userId={} — returning empty stats", userId);
                    return stats;
                }
            }

            Guest guest = guestOpt.get();
            int guestId = guest.getGuestId();

            // Get active bookings count (PENDING + CONFIRMED + CHECKED_IN)
            stats.setActiveBookingsCount(reservationDAO.countActiveByGuestId(guestId));

            // Get reviews written count
            stats.setReviewsWrittenCount(reviewDAO.countByGuestId(guestId));

            // Get total completed stays (CHECKED_OUT)
            stats.setTotalStaysCount(reservationDAO.countCompletedByGuestId(guestId));

            // Calculate loyalty points (based on completed stays)
            stats.setLoyaltyPoints(calculateLoyaltyPoints(guestId));

            // Get current/upcoming booking
            Optional<Reservation> currentBooking = reservationDAO.findCurrentOrUpcomingByGuestId(guestId);
            currentBooking.ifPresent(stats::setCurrentBooking);

            // Get active offers — limit to top 3 for dashboard
            List<Offer> activeOffers = offerDAO.findActiveOffers();
            if (activeOffers.size() > 3) {
                activeOffers = activeOffers.subList(0, 3);
            }
            stats.setActiveOffers(activeOffers);

            logger.info("Guest statistics retrieved: userId={}, guestId={}, activeBookings={}, reviews={}, totalStays={}, loyaltyPoints={}",
                       userId, guestId, stats.getActiveBookingsCount(), stats.getReviewsWrittenCount(),
                       stats.getTotalStaysCount(), stats.getLoyaltyPoints());

            return stats;

        } catch (SQLException e) {
            logger.error("Error fetching guest statistics for user ID: {}", userId, e);
            throw e;
        }
    }
    
    /**
     * Calculate loyalty points based on guest history
     * Simple formula: 20 points per completed stay + bonus for total amount spent
     */
    private int calculateLoyaltyPoints(int guestId) throws SQLException {
        try {
            List<Reservation> completedReservations = reservationDAO.findCompletedByGuestId(guestId);
            
            int points = 0;
            for (Reservation reservation : completedReservations) {
                // Base points per stay
                points += 20;
                
                // Bonus points based on amount spent (1 point per $10)
                if (reservation.getFinalAmount() != null) {
                    points += reservation.getFinalAmount().divide(BigDecimal.TEN).intValue();
                }
            }
            
            return points;
            
        } catch (SQLException e) {
            logger.error("Error calculating loyalty points for guest ID: {}", guestId, e);
            return 0;
        }
    }
    
    /**
     * Get guest profile by user ID
     */
    public Optional<Guest> getGuestByUserId(int userId) throws SQLException {
        try {
            return guestDAO.findByUserId(userId);
        } catch (SQLException e) {
            logger.error("Error fetching guest by user ID: {}", userId, e);
            throw e;
        }
    }
    
    /**
     * Create guest profile
     */
    public int createGuest(Guest guest) throws SQLException {
        try {
            logger.info("Creating guest profile for user ID: {}", guest.getUserId());
            return guestDAO.create(guest);
        } catch (SQLException e) {
            logger.error("Error creating guest profile", e);
            throw e;
        }
    }
    
    /**
     * Update guest profile
     */
    public boolean updateGuest(Guest guest) throws SQLException {
        try {
            logger.info("Updating guest profile ID: {}", guest.getGuestId());
            return guestDAO.update(guest);
        } catch (SQLException e) {
            logger.error("Error updating guest profile", e);
            throw e;
        }
    }
    
    /**
     * Get all active reservations for a guest
     */
    public List<Reservation> getActiveReservations(int guestId) throws SQLException {
        try {
            return reservationDAO.findActiveByGuestId(guestId);
        } catch (SQLException e) {
            logger.error("Error fetching active reservations for guest ID: {}", guestId, e);
            throw e;
        }
    }
    
    /**
     * Get reservation history for a guest
     */
    public List<Reservation> getReservationHistory(int guestId) throws SQLException {
        try {
            return reservationDAO.findByGuestId(guestId);
        } catch (SQLException e) {
            logger.error("Error fetching reservation history for guest ID: {}", guestId, e);
            throw e;
        }
    }
    
    /**
     * Get reviews written by guest
     */
    public List<Review> getGuestReviews(int guestId) throws SQLException {
        try {
            return reviewDAO.findByGuestId(guestId);
        } catch (SQLException e) {
            logger.error("Error fetching reviews for guest ID: {}", guestId, e);
            throw e;
        }
    }
}
