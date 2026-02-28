package com.oceanview.service;

import com.oceanview.config.AppConfig;
import com.oceanview.dao.ReservationDAO;
import com.oceanview.dao.RoomDAO;
import com.oceanview.model.Reservation;
import com.oceanview.model.Room;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.math.BigDecimal;
import java.sql.SQLException;
import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.util.List;
import java.util.Optional;

/**
 * Reservation Service
 * Handles reservation business logic
 * 
 * @author Ocean View Resort Development Team
 * @version 1.0.0
 */
public class ReservationService {
    
    private static final Logger logger = LoggerFactory.getLogger(ReservationService.class);
    private final ReservationDAO reservationDAO;
    private final RoomDAO roomDAO;
    private final AppConfig config;
    
    /**
     * Constructor
     */
    public ReservationService() {
        this.reservationDAO = new ReservationDAO();
        this.roomDAO = new RoomDAO();
        this.config = AppConfig.getInstance();
    }
    
    /**
     * Create a new reservation
     * @param reservation Reservation object
     * @return Reservation ID if successful, -1 if failed
     */
    public int createReservation(Reservation reservation) {
        try {
            // Validate dates
            if (reservation.getCheckInDate().isBefore(LocalDate.now())) {
                logger.warn("Reservation creation failed: Check-in date is in the past");
                return -1;
            }
            
            if (reservation.getCheckOutDate().isBefore(reservation.getCheckInDate())) {
                logger.warn("Reservation creation failed: Check-out date before check-in date");
                return -2;
            }
            
            // Check room availability
            Optional<Room> roomOpt = roomDAO.findById(reservation.getRoomId());
            if (roomOpt.isEmpty()) {
                logger.warn("Reservation creation failed: Room not found - ID: {}", 
                           reservation.getRoomId());
                return -3;
            }
            
            Room room = roomOpt.get();
            
            // Calculate amounts
            double taxPercentage = config.getTaxPercentage();
            double serviceCharge = config.getServiceChargePercentage();
            reservation.calculateAmounts(room.getPricePerNight(), taxPercentage, serviceCharge);
            
            // Generate reservation number
            String reservationNumber = generateReservationNumber();
            reservation.setReservationNumber(reservationNumber);
            
            // Set initial status
            reservation.setStatus(Reservation.ReservationStatus.PENDING);
            
            // Create reservation
            int reservationId = reservationDAO.create(reservation);
            
            if (reservationId > 0) {
                logger.info("Reservation created successfully: {}", reservationNumber);
            }
            
            return reservationId;
            
        } catch (SQLException e) {
            logger.error("Error creating reservation", e);
            return -4;
        }
    }
    
    /**
     * Update existing reservation
     * @param reservation Reservation object
     * @return true if successful
     */
    public boolean updateReservation(Reservation reservation) {
        try {
            // Recalculate amounts
            Optional<Room> roomOpt = roomDAO.findById(reservation.getRoomId());
            if (roomOpt.isPresent()) {
                Room room = roomOpt.get();
                double taxPercentage = config.getTaxPercentage();
                double serviceCharge = config.getServiceChargePercentage();
                reservation.calculateAmounts(room.getPricePerNight(), taxPercentage, serviceCharge);
            }
            
            boolean success = reservationDAO.update(reservation);
            
            if (success) {
                logger.info("Reservation updated successfully: ID={}", reservation.getReservationId());
            }
            
            return success;
            
        } catch (SQLException e) {
            logger.error("Error updating reservation: ID={}", reservation.getReservationId(), e);
            return false;
        }
    }
    
    /**
     * Confirm a reservation
     * @param reservationId Reservation ID
     * @return true if successful
     */
    public boolean confirmReservation(int reservationId) {
        try {
            Optional<Reservation> resOpt = reservationDAO.findById(reservationId);
            
            if (resOpt.isEmpty()) {
                logger.warn("Confirm failed: Reservation not found - ID: {}", reservationId);
                return false;
            }
            
            Reservation reservation = resOpt.get();
            
            if (!reservation.isPending()) {
                logger.warn("Confirm failed: Reservation not in PENDING status - ID: {}", reservationId);
                return false;
            }
            
            // Update reservation status
            boolean success = reservationDAO.updateStatus(reservationId, 
                                                          Reservation.ReservationStatus.CONFIRMED);
            
            if (success) {
                // Update room status
                roomDAO.updateStatus(reservation.getRoomId(), Room.RoomStatus.RESERVED);
                logger.info("Reservation confirmed: ID={}", reservationId);
            }
            
            return success;
            
        } catch (SQLException e) {
            logger.error("Error confirming reservation: ID={}", reservationId, e);
            return false;
        }
    }
    
    /**
     * Check-in a reservation
     * @param reservationId Reservation ID
     * @return true if successful
     */
    public boolean checkInReservation(int reservationId) {
        try {
            Optional<Reservation> resOpt = reservationDAO.findById(reservationId);
            
            if (resOpt.isEmpty()) {
                logger.warn("Check-in failed: Reservation not found - ID: {}", reservationId);
                return false;
            }
            
            Reservation reservation = resOpt.get();
            
            if (!reservation.canCheckIn()) {
                logger.warn("Check-in failed: Reservation cannot be checked in - ID: {}", reservationId);
                return false;
            }
            
            // Update reservation status
            boolean success = reservationDAO.updateStatus(reservationId, 
                                                          Reservation.ReservationStatus.CHECKED_IN);
            
            if (success) {
                // Update room status
                roomDAO.updateStatus(reservation.getRoomId(), Room.RoomStatus.OCCUPIED);
                logger.info("Reservation checked in: ID={}", reservationId);
            }
            
            return success;
            
        } catch (SQLException e) {
            logger.error("Error checking in reservation: ID={}", reservationId, e);
            return false;
        }
    }
    
    /**
     * Check-out a reservation
     * @param reservationId Reservation ID
     * @return true if successful
     */
    public boolean checkOutReservation(int reservationId) {
        try {
            Optional<Reservation> resOpt = reservationDAO.findById(reservationId);
            
            if (resOpt.isEmpty()) {
                logger.warn("Check-out failed: Reservation not found - ID: {}", reservationId);
                return false;
            }
            
            Reservation reservation = resOpt.get();
            
            if (!reservation.canCheckOut()) {
                logger.warn("Check-out failed: Reservation cannot be checked out - ID: {}", reservationId);
                return false;
            }
            
            // Update reservation status
            boolean success = reservationDAO.updateStatus(reservationId, 
                                                          Reservation.ReservationStatus.CHECKED_OUT);
            
            if (success) {
                // Update room status
                roomDAO.updateStatus(reservation.getRoomId(), Room.RoomStatus.AVAILABLE);
                logger.info("Reservation checked out: ID={}", reservationId);
            }
            
            return success;
            
        } catch (SQLException e) {
            logger.error("Error checking out reservation: ID={}", reservationId, e);
            return false;
        }
    }
    
    /**
     * Cancel a reservation
     * @param reservationId Reservation ID
     * @return true if successful
     */
    public boolean cancelReservation(int reservationId) {
        try {
            Optional<Reservation> resOpt = reservationDAO.findById(reservationId);
            
            if (resOpt.isEmpty()) {
                logger.warn("Cancel failed: Reservation not found - ID: {}", reservationId);
                return false;
            }
            
            Reservation reservation = resOpt.get();
            
            if (!reservation.canCancel()) {
                logger.warn("Cancel failed: Reservation cannot be cancelled - ID: {}", reservationId);
                return false;
            }

            // Capture status BEFORE updating so room release logic is correct
            boolean wasConfirmed = reservation.isConfirmed();
            boolean wasPending   = reservation.isPending();
            Integer roomId       = reservation.getRoomId();
            
            // Update reservation status
            boolean success = reservationDAO.updateStatus(reservationId, 
                                                          Reservation.ReservationStatus.CANCELLED);
            
            if (success) {
                // Release room back to AVAILABLE if it was held (CONFIRMED sets room to RESERVED,
                // PENDING may also have room marked RESERVED in some flows)
                if (roomId != null && roomId > 0 && (wasConfirmed || wasPending)) {
                    try {
                        Optional<Room> roomOpt = roomDAO.findById(roomId);
                        if (roomOpt.isPresent()) {
                            Room room = roomOpt.get();
                            // Only reset if room is currently RESERVED or OCCUPIED (not MAINTENANCE)
                            if (room.getStatus() == Room.RoomStatus.RESERVED ||
                                room.getStatus() == Room.RoomStatus.OCCUPIED) {
                                roomDAO.updateStatus(roomId, Room.RoomStatus.AVAILABLE);
                                logger.info("Room {} released to AVAILABLE after cancellation of reservation ID={}", roomId, reservationId);
                            }
                        }
                    } catch (SQLException roomEx) {
                        // Log but don't fail the cancellation — reservation is already cancelled
                        logger.warn("Could not update room status for room ID={} after cancellation: {}", roomId, roomEx.getMessage());
                    }
                }
                logger.info("Reservation cancelled: ID={}", reservationId);
            }
            
            return success;
            
        } catch (SQLException e) {
            logger.error("Error cancelling reservation: ID={}", reservationId, e);
            return false;
        }
    }
    
    /**
     * Get reservation by ID
     * @param reservationId Reservation ID
     * @return Optional Reservation
     */
    public Optional<Reservation> getReservationById(int reservationId) {
        try {
            return reservationDAO.findById(reservationId);
        } catch (SQLException e) {
            logger.error("Error getting reservation by ID: {}", reservationId, e);
            return Optional.empty();
        }
    }
    
    /**
     * Get reservation by reservation number
     * @param reservationNumber Reservation number
     * @return Optional Reservation
     */
    public Optional<Reservation> getReservationByNumber(String reservationNumber) {
        try {
            return reservationDAO.findByReservationNumber(reservationNumber);
        } catch (SQLException e) {
            logger.error("Error getting reservation by number: {}", reservationNumber, e);
            return Optional.empty();
        }
    }
    
    /**
     * Get reservations by guest
     * @param guestId Guest ID
     * @return List of reservations
     */
    public List<Reservation> getReservationsByGuest(int guestId) {
        try {
            return reservationDAO.findByGuestId(guestId);
        } catch (SQLException e) {
            logger.error("Error getting reservations by guest: {}", guestId, e);
            return List.of();
        }
    }

    /**
     * Resolve guest_id from a logged-in user's userId.
     * Returns -1 if the user has no guest profile yet.
     */
    public int getGuestIdByUserId(int userId) {
        try {
            return new com.oceanview.dao.GuestDAO().findGuestIdByUserId(userId);
        } catch (java.sql.SQLException e) {
            logger.error("Error resolving guestId for userId={}", userId, e);
            return -1;
        }
    }

    /**
     * Get reservations by user ID (for logged-in guests)
     * Joins guests table internally - call this with session user's userId
     * @param userId User ID from session
     * @return List of reservations with room details hydrated
     */
    public List<Reservation> getReservationsByUserId(int userId) {
        try {
            return reservationDAO.findByUserId(userId);
        } catch (SQLException e) {
            logger.error("Error getting reservations by user ID: {}", userId, e);
            return List.of();
        }
    }
    
    /**
     * Get all reservations
     * @return List of reservations
     */
    public List<Reservation> getAllReservations() {
        try {
            return reservationDAO.findAll();
        } catch (SQLException e) {
            logger.error("Error getting all reservations", e);
            return List.of();
        }
    }
    
    /**
     * Get active reservations
     * @return List of active reservations
     */
    public List<Reservation> getActiveReservations() {
        try {
            return reservationDAO.findActiveReservations();
        } catch (SQLException e) {
            logger.error("Error getting active reservations", e);
            return List.of();
        }
    }
    
    /**
     * Get today's check-ins
     * @return List of reservations
     */
    public List<Reservation> getTodayCheckIns() {
        try {
            return reservationDAO.findTodayCheckIns();
        } catch (SQLException e) {
            logger.error("Error getting today's check-ins", e);
            return List.of();
        }
    }
    
    /**
     * Get today's check-outs
     * @return List of reservations
     */
    public List<Reservation> getTodayCheckOuts() {
        try {
            return reservationDAO.findTodayCheckOuts();
        } catch (SQLException e) {
            logger.error("Error getting today's check-outs", e);
            return List.of();
        }
    }
    
    /**
     * Generate unique reservation number
     * Format: RES-YYYY-XXXX
     * @return Reservation number
     */
    private String generateReservationNumber() {
        String year = LocalDate.now().format(DateTimeFormatter.ofPattern("yyyy"));
        long timestamp = System.currentTimeMillis() % 10000;
        return String.format("RES-%s-%04d", year, timestamp);
    }
}
