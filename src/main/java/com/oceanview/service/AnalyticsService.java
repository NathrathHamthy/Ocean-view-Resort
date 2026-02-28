package com.oceanview.service;

import com.oceanview.dao.PaymentDAO;
import com.oceanview.dao.ReservationDAO;
import com.oceanview.dao.RoomDAO;
import com.oceanview.dao.UserDAO;
import com.oceanview.model.Payment;
import com.oceanview.model.Reservation;
import com.oceanview.model.Room;
import com.oceanview.model.User;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.math.BigDecimal;
import java.sql.SQLException;
import java.time.LocalDate;
import java.time.temporal.ChronoUnit;
import java.util.*;
import java.util.stream.Collectors;

/**
 * Analytics Service
 * Provides business intelligence and analytics for the hotel management system
 * 
 * @author Ocean View Resort Development Team
 * @version 1.0.0
 */
public class AnalyticsService {
    
    private static final Logger logger = LoggerFactory.getLogger(AnalyticsService.class);
    
    private final ReservationDAO reservationDAO;
    private final RoomDAO roomDAO;
    private final PaymentDAO paymentDAO;
    private final UserDAO userDAO;
    
    /**
     * Constructor
     */
    public AnalyticsService() {
        this.reservationDAO = new ReservationDAO();
        this.roomDAO = new RoomDAO();
        this.paymentDAO = new PaymentDAO();
        this.userDAO = new UserDAO();
    }
    
    /**
     * Get dashboard statistics
     * @return Map with key statistics
     */
    public Map<String, Object> getDashboardStatistics() {
        Map<String, Object> stats = new HashMap<>();
        
        try {
            // Reservation Statistics
            List<Reservation> allReservations = reservationDAO.findAll();
            stats.put("totalReservations", allReservations.size());
            stats.put("activeReservations", getActiveReservationsCount(allReservations));
            stats.put("pendingReservations", getPendingReservationsCount(allReservations));
            stats.put("todayCheckIns", getTodayCheckIns(allReservations).size());
            stats.put("todayCheckOuts", getTodayCheckOuts(allReservations).size());
            
            // Room Statistics
            List<Room> allRooms = roomDAO.findAll();
            stats.put("totalRooms", allRooms.size());
            stats.put("availableRooms", getAvailableRoomsCount(allRooms));
            stats.put("occupiedRooms", getOccupiedRoomsCount(allRooms));
            stats.put("occupancyRate", calculateOccupancyRate(allRooms));
            
            // Revenue Statistics
            double totalRevenue = paymentDAO.getTotalRevenue();
            stats.put("totalRevenue", totalRevenue);
            stats.put("monthlyRevenue", getMonthlyRevenue());
            stats.put("todayRevenue", getTodayRevenue());
            
            // User Statistics
            int totalUsers = userDAO.findAll().size();
            stats.put("totalUsers", totalUsers);
            stats.put("totalGuests", getUsersByRole(User.Role.GUEST).size());
            
            logger.info("Dashboard statistics generated successfully");
            
        } catch (SQLException e) {
            logger.error("Error generating dashboard statistics", e);
        }
        
        return stats;
    }
    
    /**
     * Get revenue analytics for a date range
     * @param startDate Start date
     * @param endDate End date
     * @return Revenue analytics map
     */
    public Map<String, Object> getRevenueAnalytics(LocalDate startDate, LocalDate endDate) {
        Map<String, Object> analytics = new HashMap<>();
        
        try {
            List<Payment> payments = paymentDAO.findAll();
            
            // Filter by date range
            List<Payment> filteredPayments = payments.stream()
                .filter(p -> p.getPaymentDate() != null)
                .filter(p -> {
                    LocalDate paymentDate = p.getPaymentDate().toLocalDate();
                    return !paymentDate.isBefore(startDate) && !paymentDate.isAfter(endDate);
                })
                .collect(Collectors.toList());
            
            // Total revenue
            double totalRevenue = filteredPayments.stream()
                .filter(Payment::isCompleted)
                .mapToDouble(p -> p.getAmount().doubleValue())
                .sum();
            
            analytics.put("totalRevenue", totalRevenue);
            analytics.put("totalTransactions", filteredPayments.size());
            analytics.put("averageTransactionValue", 
                         filteredPayments.isEmpty() ? 0 : totalRevenue / filteredPayments.size());
            
            // Revenue by payment method
            Map<String, Double> revenueByMethod = filteredPayments.stream()
                .filter(Payment::isCompleted)
                .collect(Collectors.groupingBy(
                    p -> p.getPaymentMethod().name(),
                    Collectors.summingDouble(p -> p.getAmount().doubleValue())
                ));
            analytics.put("revenueByPaymentMethod", revenueByMethod);
            
            // Revenue by day
            Map<LocalDate, Double> revenueByDay = filteredPayments.stream()
                .filter(Payment::isCompleted)
                .collect(Collectors.groupingBy(
                    p -> p.getPaymentDate().toLocalDate(),
                    Collectors.summingDouble(p -> p.getAmount().doubleValue())
                ));
            analytics.put("revenueByDay", revenueByDay);
            
            // Refunds
            double totalRefunds = filteredPayments.stream()
                .filter(Payment::isRefunded)
                .mapToDouble(p -> p.getAmount().doubleValue())
                .sum();
            analytics.put("totalRefunds", totalRefunds);
            analytics.put("netRevenue", totalRevenue - totalRefunds);
            
            logger.info("Revenue analytics generated for {} to {}", startDate, endDate);
            
        } catch (SQLException e) {
            logger.error("Error generating revenue analytics", e);
        }
        
        return analytics;
    }
    
    /**
     * Get occupancy analytics
     * @param startDate Start date
     * @param endDate End date
     * @return Occupancy analytics map
     */
    public Map<String, Object> getOccupancyAnalytics(LocalDate startDate, LocalDate endDate) {
        Map<String, Object> analytics = new HashMap<>();
        
        try {
            List<Room> allRooms = roomDAO.findAll();
            List<Reservation> allReservations = reservationDAO.findAll();
            
            // Calculate total room nights available
            long daysBetween = ChronoUnit.DAYS.between(startDate, endDate) + 1;
            long totalRoomNights = allRooms.size() * daysBetween;
            
            // Calculate occupied room nights
            long occupiedRoomNights = allReservations.stream()
                .filter(r -> r.getStatus() == Reservation.ReservationStatus.CHECKED_IN ||
                           r.getStatus() == Reservation.ReservationStatus.CHECKED_OUT)
                .filter(r -> isReservationInDateRange(r, startDate, endDate))
                .mapToLong(r -> calculateOverlapNights(r, startDate, endDate))
                .sum();
            
            double occupancyRate = totalRoomNights > 0 ? 
                (double) occupiedRoomNights / totalRoomNights * 100 : 0;
            
            analytics.put("totalRooms", allRooms.size());
            analytics.put("totalRoomNights", totalRoomNights);
            analytics.put("occupiedRoomNights", occupiedRoomNights);
            analytics.put("occupancyRate", occupancyRate);
            
            // Occupancy by room type
            Map<String, Double> occupancyByType = calculateOccupancyByRoomType(
                allRooms, allReservations, startDate, endDate);
            analytics.put("occupancyByRoomType", occupancyByType);
            
            // Average length of stay
            double avgLengthOfStay = allReservations.stream()
                .filter(r -> isReservationInDateRange(r, startDate, endDate))
                .mapToInt(Reservation::getNumberOfNights)
                .average()
                .orElse(0.0);
            analytics.put("averageLengthOfStay", avgLengthOfStay);
            
            logger.info("Occupancy analytics generated for {} to {}", startDate, endDate);
            
        } catch (SQLException e) {
            logger.error("Error generating occupancy analytics", e);
        }
        
        return analytics;
    }
    
    /**
     * Get reservation analytics
     * @param startDate Start date
     * @param endDate End date
     * @return Reservation analytics map
     */
    public Map<String, Object> getReservationAnalytics(LocalDate startDate, LocalDate endDate) {
        Map<String, Object> analytics = new HashMap<>();
        
        try {
            List<Reservation> reservations = reservationDAO.findAll();
            
            // Filter by date range
            List<Reservation> filteredReservations = reservations.stream()
                .filter(r -> isReservationInDateRange(r, startDate, endDate))
                .collect(Collectors.toList());
            
            analytics.put("totalReservations", filteredReservations.size());
            
            // Reservations by status
            Map<String, Long> reservationsByStatus = filteredReservations.stream()
                .collect(Collectors.groupingBy(
                    r -> r.getStatus().name(),
                    Collectors.counting()
                ));
            analytics.put("reservationsByStatus", reservationsByStatus);
            
            // Cancellation rate
            long cancelledCount = filteredReservations.stream()
                .filter(Reservation::isCancelled)
                .count();
            double cancellationRate = filteredReservations.isEmpty() ? 0 : 
                (double) cancelledCount / filteredReservations.size() * 100;
            analytics.put("cancellationRate", cancellationRate);
            
            // Average booking value
            double avgBookingValue = filteredReservations.stream()
                .filter(r -> !r.isCancelled())
                .mapToDouble(r -> r.getFinalAmount().doubleValue())
                .average()
                .orElse(0.0);
            analytics.put("averageBookingValue", avgBookingValue);
            
            // Total booking value
            double totalBookingValue = filteredReservations.stream()
                .filter(r -> !r.isCancelled())
                .mapToDouble(r -> r.getFinalAmount().doubleValue())
                .sum();
            analytics.put("totalBookingValue", totalBookingValue);
            
            // Average guests per reservation
            double avgGuests = filteredReservations.stream()
                .mapToInt(Reservation::getNumberOfGuests)
                .average()
                .orElse(0.0);
            analytics.put("averageGuestsPerReservation", avgGuests);
            
            // Booking lead time (days between booking and check-in)
            double avgLeadTime = filteredReservations.stream()
                .filter(r -> r.getCreatedAt() != null && r.getCheckInDate() != null)
                .mapToLong(r -> ChronoUnit.DAYS.between(
                    r.getCreatedAt().toLocalDate(), 
                    r.getCheckInDate()))
                .average()
                .orElse(0.0);
            analytics.put("averageBookingLeadTime", avgLeadTime);
            
            logger.info("Reservation analytics generated for {} to {}", startDate, endDate);
            
        } catch (SQLException e) {
            logger.error("Error generating reservation analytics", e);
        }
        
        return analytics;
    }
    
    /**
     * Get room performance analytics
     * @return Room performance map
     */
    public Map<String, Object> getRoomPerformanceAnalytics() {
        Map<String, Object> analytics = new HashMap<>();
        
        try {
            List<Room> rooms = roomDAO.findAll();
            List<Reservation> reservations = reservationDAO.findAll();
            
            // Most booked room types
            Map<String, Long> bookingsByRoomType = reservations.stream()
                .filter(r -> r.getRoom() != null)
                .collect(Collectors.groupingBy(
                    r -> r.getRoom().getRoomType().name(),
                    Collectors.counting()
                ));
            analytics.put("bookingsByRoomType", bookingsByRoomType);
            
            // Revenue by room type
            Map<String, Double> revenueByRoomType = reservations.stream()
                .filter(r -> r.getRoom() != null && !r.isCancelled())
                .collect(Collectors.groupingBy(
                    r -> r.getRoom().getRoomType().name(),
                    Collectors.summingDouble(r -> r.getFinalAmount().doubleValue())
                ));
            analytics.put("revenueByRoomType", revenueByRoomType);
            
            // Average price by room type
            Map<String, Double> avgPriceByType = rooms.stream()
                .collect(Collectors.groupingBy(
                    r -> r.getRoomType().name(),
                    Collectors.averagingDouble(r -> r.getPricePerNight().doubleValue())
                ));
            analytics.put("averagePriceByRoomType", avgPriceByType);
            
            // Room type distribution
            Map<String, Long> roomTypeDistribution = rooms.stream()
                .collect(Collectors.groupingBy(
                    r -> r.getRoomType().name(),
                    Collectors.counting()
                ));
            analytics.put("roomTypeDistribution", roomTypeDistribution);
            
            logger.info("Room performance analytics generated");
            
        } catch (SQLException e) {
            logger.error("Error generating room performance analytics", e);
        }
        
        return analytics;
    }
    
    /**
     * Get customer analytics
     * @return Customer analytics map
     */
    public Map<String, Object> getCustomerAnalytics() {
        Map<String, Object> analytics = new HashMap<>();
        
        try {
            List<User> allUsers = userDAO.findAll();
            List<Reservation> allReservations = reservationDAO.findAll();
            
            // Total customers
            long totalGuests = allUsers.stream()
                .filter(User::isGuest)
                .count();
            analytics.put("totalCustomers", totalGuests);
            
            // New customers this month
            LocalDate monthStart = LocalDate.now().withDayOfMonth(1);
            long newCustomersThisMonth = allUsers.stream()
                .filter(User::isGuest)
                .filter(u -> u.getCreatedAt() != null)
                .filter(u -> !u.getCreatedAt().toLocalDate().isBefore(monthStart))
                .count();
            analytics.put("newCustomersThisMonth", newCustomersThisMonth);
            
            // Repeat customers (customers with more than one reservation)
            Map<Integer, Long> reservationsByGuest = allReservations.stream()
                .collect(Collectors.groupingBy(
                    Reservation::getGuestId,
                    Collectors.counting()
                ));
            
            long repeatCustomers = reservationsByGuest.values().stream()
                .filter(count -> count > 1)
                .count();
            analytics.put("repeatCustomers", repeatCustomers);
            
            double repeatCustomerRate = totalGuests > 0 ? 
                (double) repeatCustomers / totalGuests * 100 : 0;
            analytics.put("repeatCustomerRate", repeatCustomerRate);
            
            // Average reservations per customer
            double avgReservationsPerCustomer = totalGuests > 0 ? 
                (double) allReservations.size() / totalGuests : 0;
            analytics.put("averageReservationsPerCustomer", avgReservationsPerCustomer);
            
            logger.info("Customer analytics generated");
            
        } catch (SQLException e) {
            logger.error("Error generating customer analytics", e);
        }
        
        return analytics;
    }
    
    /**
     * Get top performing metrics
     * @return Top metrics map
     */
    public Map<String, Object> getTopPerformingMetrics() {
        Map<String, Object> metrics = new HashMap<>();
        
        try {
            List<Reservation> reservations = reservationDAO.findAll();
            
            // Best revenue day
            Map<LocalDate, Double> revenueByDay = reservations.stream()
                .filter(r -> !r.isCancelled())
                .filter(r -> r.getCreatedAt() != null)
                .collect(Collectors.groupingBy(
                    r -> r.getCreatedAt().toLocalDate(),
                    Collectors.summingDouble(r -> r.getFinalAmount().doubleValue())
                ));
            
            if (!revenueByDay.isEmpty()) {
                LocalDate bestDay = revenueByDay.entrySet().stream()
                    .max(Map.Entry.comparingByValue())
                    .map(Map.Entry::getKey)
                    .orElse(null);
                metrics.put("bestRevenueDay", bestDay);
                metrics.put("bestRevenueDayAmount", revenueByDay.get(bestDay));
            }
            
            // Most popular room type
            Map<String, Long> bookingsByType = reservations.stream()
                .filter(r -> r.getRoom() != null)
                .collect(Collectors.groupingBy(
                    r -> r.getRoom().getRoomType().name(),
                    Collectors.counting()
                ));
            
            if (!bookingsByType.isEmpty()) {
                String mostPopularType = bookingsByType.entrySet().stream()
                    .max(Map.Entry.comparingByValue())
                    .map(Map.Entry::getKey)
                    .orElse(null);
                metrics.put("mostPopularRoomType", mostPopularType);
                metrics.put("mostPopularRoomTypeBookings", bookingsByType.get(mostPopularType));
            }
            
            logger.info("Top performing metrics generated");
            
        } catch (SQLException e) {
            logger.error("Error generating top performing metrics", e);
        }
        
        return metrics;
    }
    
    // Helper Methods
    
    private int getActiveReservationsCount(List<Reservation> reservations) {
        return (int) reservations.stream()
            .filter(Reservation::isActive)
            .count();
    }
    
    private int getPendingReservationsCount(List<Reservation> reservations) {
        return (int) reservations.stream()
            .filter(Reservation::isPending)
            .count();
    }
    
    private List<Reservation> getTodayCheckIns(List<Reservation> reservations) {
        LocalDate today = LocalDate.now();
        return reservations.stream()
            .filter(r -> r.getCheckInDate() != null)
            .filter(r -> r.getCheckInDate().equals(today))
            .collect(Collectors.toList());
    }
    
    private List<Reservation> getTodayCheckOuts(List<Reservation> reservations) {
        LocalDate today = LocalDate.now();
        return reservations.stream()
            .filter(r -> r.getCheckOutDate() != null)
            .filter(r -> r.getCheckOutDate().equals(today))
            .collect(Collectors.toList());
    }
    
    private int getAvailableRoomsCount(List<Room> rooms) {
        return (int) rooms.stream()
            .filter(Room::isAvailable)
            .count();
    }
    
    private int getOccupiedRoomsCount(List<Room> rooms) {
        return (int) rooms.stream()
            .filter(Room::isOccupied)
            .count();
    }
    
    private double calculateOccupancyRate(List<Room> rooms) {
        if (rooms.isEmpty()) return 0.0;
        long occupied = rooms.stream().filter(Room::isOccupied).count();
        return (double) occupied / rooms.size() * 100;
    }
    
    private double getMonthlyRevenue() throws SQLException {
        List<Payment> payments = paymentDAO.findAll();
        LocalDate monthStart = LocalDate.now().withDayOfMonth(1);
        
        return payments.stream()
            .filter(p -> p.getPaymentDate() != null)
            .filter(p -> !p.getPaymentDate().toLocalDate().isBefore(monthStart))
            .filter(Payment::isCompleted)
            .mapToDouble(p -> p.getAmount().doubleValue())
            .sum();
    }
    
    private double getTodayRevenue() throws SQLException {
        List<Payment> payments = paymentDAO.findAll();
        LocalDate today = LocalDate.now();
        
        return payments.stream()
            .filter(p -> p.getPaymentDate() != null)
            .filter(p -> p.getPaymentDate().toLocalDate().equals(today))
            .filter(Payment::isCompleted)
            .mapToDouble(p -> p.getAmount().doubleValue())
            .sum();
    }
    
    private List<User> getUsersByRole(User.Role role) throws SQLException {
        return userDAO.findAll().stream()
            .filter(u -> u.getRole() == role)
            .collect(Collectors.toList());
    }
    
    private boolean isReservationInDateRange(Reservation r, LocalDate start, LocalDate end) {
        if (r.getCheckInDate() == null || r.getCheckOutDate() == null) {
            return false;
        }
        return !r.getCheckOutDate().isBefore(start) && !r.getCheckInDate().isAfter(end);
    }
    
    private long calculateOverlapNights(Reservation r, LocalDate start, LocalDate end) {
        LocalDate overlapStart = r.getCheckInDate().isBefore(start) ? start : r.getCheckInDate();
        LocalDate overlapEnd = r.getCheckOutDate().isAfter(end) ? end : r.getCheckOutDate();
        
        long nights = ChronoUnit.DAYS.between(overlapStart, overlapEnd);
        return Math.max(0, nights);
    }
    
    private Map<String, Double> calculateOccupancyByRoomType(
            List<Room> rooms, List<Reservation> reservations, 
            LocalDate startDate, LocalDate endDate) {
        
        Map<String, Double> occupancyByType = new HashMap<>();
        
        for (Room.RoomType type : Room.RoomType.values()) {
            long roomsOfType = rooms.stream()
                .filter(r -> r.getRoomType() == type)
                .count();
            
            if (roomsOfType == 0) continue;
            
            long daysBetween = ChronoUnit.DAYS.between(startDate, endDate) + 1;
            long totalRoomNights = roomsOfType * daysBetween;
            
            long occupiedNights = reservations.stream()
                .filter(r -> r.getRoom() != null)
                .filter(r -> r.getRoom().getRoomType() == type)
                .filter(r -> r.getStatus() == Reservation.ReservationStatus.CHECKED_IN ||
                           r.getStatus() == Reservation.ReservationStatus.CHECKED_OUT)
                .filter(r -> isReservationInDateRange(r, startDate, endDate))
                .mapToLong(r -> calculateOverlapNights(r, startDate, endDate))
                .sum();
            
            double occupancyRate = totalRoomNights > 0 ? 
                (double) occupiedNights / totalRoomNights * 100 : 0;
            
            occupancyByType.put(type.name(), occupancyRate);
        }
        
        return occupancyByType;
    }
}
