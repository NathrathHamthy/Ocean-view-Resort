package com.oceanview.controller;

import com.oceanview.model.User;
import com.oceanview.model.Reservation;
import com.oceanview.model.Review;
import com.oceanview.service.ReservationService;
import com.oceanview.service.RoomService;
import com.oceanview.service.BillingService;
import com.oceanview.service.GuestService;
import com.oceanview.dao.ReviewDAO;
import com.oceanview.dao.OfferDAO;
import com.oceanview.dao.GuestDAO;
import com.oceanview.factory.DAOFactory;
import com.oceanview.model.Guest;
import com.oceanview.util.Constants;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.io.IOException;

/**
 * Dashboard Servlet
 * Provides dashboard data for different user roles
 * URL Mapping: /dashboard (configured in web.xml)
 * 
 * @author Ocean View Resort Development Team
 * @version 1.0.0
 */
public class DashboardServlet extends HttpServlet {
    
    private static final Logger logger = LoggerFactory.getLogger(DashboardServlet.class);
    private ReservationService reservationService;
    private RoomService roomService;
    private BillingService billingService;
    private GuestService guestService;
    
    @Override
    public void init() throws ServletException {
        reservationService = new ReservationService();
        roomService = new RoomService();
        billingService = new BillingService();
        guestService = new GuestService();
        logger.info("DashboardServlet initialized");
    }
    
    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        
        HttpSession session = request.getSession();
        User user = (User) session.getAttribute(Constants.SESSION_USER);
        
        if (user == null) {
            response.sendRedirect(request.getContextPath() + "/login");
            return;
        }
        
        // Load dashboard data based on user role
        if (user.isAdmin()) {
            // Redirect to dedicated AdminDashboardServlet which loads proper DB stats
            response.sendRedirect(request.getContextPath() + "/admin/dashboard");
            return;
        } else if (user.isStaff()) {
            loadStaffDashboard(request, response);
        } else {
            loadGuestDashboard(request, response);
        }
    }
    
    /**
     * Load admin dashboard data
     */
    private void loadAdminDashboard(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        
        try {
            // Room statistics
            int[] roomStats = roomService.getRoomStatistics();
            int totalRooms = roomStats[0] + roomStats[1] + roomStats[2] + roomStats[3];
            
            request.setAttribute("totalRooms", totalRooms);
            request.setAttribute("availableRooms", roomStats[0]);
            request.setAttribute("occupiedRooms", roomStats[1]);
            request.setAttribute("reservedRooms", roomStats[2]);
            request.setAttribute("maintenanceRooms", roomStats[3]);
            
            // Reservation counts
            int totalReservations = reservationService.getAllReservations().size();
            int activeReservations = reservationService.getActiveReservations().size();
            int todayCheckIns = reservationService.getTodayCheckIns().size();
            int todayCheckOuts = reservationService.getTodayCheckOuts().size();
            
            request.setAttribute("totalReservations", totalReservations);
            request.setAttribute("activeReservations", activeReservations);
            request.setAttribute("todayCheckIns", todayCheckIns);
            request.setAttribute("todayCheckOuts", todayCheckOuts);
            
            // Revenue
            double totalRevenue = billingService.getTotalRevenue();
            double monthlyRevenue = totalRevenue; // Simplified - use current total as monthly
            request.setAttribute("totalRevenue", totalRevenue);
            request.setAttribute("monthlyRevenue", monthlyRevenue);
            
            // Total guests (unique guests from all reservations)
            int totalGuests = reservationService.getAllReservations().size(); // Simplified
            request.setAttribute("totalGuests", totalGuests);
            
            // Occupancy rate
            double occupancyRate = totalRooms > 0 ? ((double) roomStats[1] / totalRooms) * 100 : 0.0;
            request.setAttribute("occupancyRate", occupancyRate);
            
            // Pending reviews (simplified - count recent reservations)
            int pendingReviews = 0;
            request.setAttribute("pendingReviews", pendingReviews);
            
            // Recent activities
            request.setAttribute("recentReservations", reservationService.getAllReservations());
            request.setAttribute("todayCheckInsList", reservationService.getTodayCheckIns());
            request.setAttribute("todayCheckOutsList", reservationService.getTodayCheckOuts());
            
            logger.info("Admin dashboard data loaded successfully");
            request.getRequestDispatcher("/views/admin/dashboard.jsp").forward(request, response);
            
        } catch (Exception e) {
            logger.error("Error loading admin dashboard", e);
            request.setAttribute(Constants.ATTR_ERROR, "Error loading dashboard");
            request.getRequestDispatcher("/views/admin/dashboard.jsp").forward(request, response);
        }
    }
    
    /**
     * Load staff dashboard data
     */
    private void loadStaffDashboard(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        try {
            // Today's check-ins and check-outs (Lists for table display)
            java.util.List<com.oceanview.model.Reservation> todayCheckIns  = reservationService.getTodayCheckIns();
            java.util.List<com.oceanview.model.Reservation> todayCheckOuts = reservationService.getTodayCheckOuts();
            java.util.List<com.oceanview.model.Reservation> activeReservations = reservationService.getActiveReservations();
            java.util.List<com.oceanview.model.Reservation> allReservations = reservationService.getAllReservations();

            request.setAttribute("todayCheckIns",      todayCheckIns);
            request.setAttribute("todayCheckOuts",     todayCheckOuts);
            request.setAttribute("activeReservations", activeReservations);

            // Stat counts
            request.setAttribute("todayCheckInCount",  todayCheckIns.size());
            request.setAttribute("todayCheckOutCount", todayCheckOuts.size());
            request.setAttribute("activeCount",        activeReservations.size());

            // Pending reservations count
            long pendingCount = allReservations.stream()
                .filter(r -> r.getStatus() == com.oceanview.model.Reservation.ReservationStatus.PENDING)
                .count();
            request.setAttribute("pendingCount", (int) pendingCount);

            // Room statistics [available, occupied, reserved, maintenance]
            int[] roomStats = roomService.getRoomStatistics();
            int totalRooms  = roomStats[0] + roomStats[1] + roomStats[2] + roomStats[3];
            request.setAttribute("availableRooms",    roomStats[0]);
            request.setAttribute("occupiedRooms",     roomStats[1]);
            request.setAttribute("reservedRooms",     roomStats[2]);
            request.setAttribute("maintenanceRooms",  roomStats[3]);
            request.setAttribute("totalRooms",        totalRooms);

            // Occupancy rate
            double occupancyRate = totalRooms > 0
                ? Math.round(((double)(roomStats[1] + roomStats[2]) / totalRooms) * 1000.0) / 10.0
                : 0.0;
            request.setAttribute("occupancyRate", occupancyRate);

            // Recent 8 reservations for the activity feed
            java.util.List<com.oceanview.model.Reservation> recent = allReservations.stream()
                .limit(8)
                .collect(java.util.stream.Collectors.toList());
            request.setAttribute("recentReservations", recent);

            logger.info("Staff dashboard data loaded successfully");
            request.getRequestDispatcher("/views/staff/dashboard.jsp").forward(request, response);

        } catch (Exception e) {
            logger.error("Error loading staff dashboard", e);
            request.setAttribute(Constants.ATTR_ERROR, "Error loading dashboard data. Please try again.");
            request.getRequestDispatcher("/views/staff/dashboard.jsp").forward(request, response);
        }
    }
    
    /**
     * Load guest dashboard data
     */
    private void loadGuestDashboard(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        HttpSession session = request.getSession();
        User user = (User) session.getAttribute(Constants.SESSION_USER);

        try {
            int userId = user.getUserId();

            // Fetch all reservations for this user (joins guests table internally)
            java.util.List<Reservation> allReservations = reservationService.getReservationsByUserId(userId);

            // Partition reservations into upcoming/current, completed and cancelled
            java.util.List<Reservation> currentReservations = new java.util.ArrayList<>();
            long upcomingCount  = 0L;
            long completedCount = 0L;
            long cancelledCount = 0L;

            for (Reservation r : allReservations) {
                if (r.getStatus() == null) continue;
                Reservation.ReservationStatus status = r.getStatus();
                if (status == Reservation.ReservationStatus.PENDING
                        || status == Reservation.ReservationStatus.CONFIRMED
                        || status == Reservation.ReservationStatus.CHECKED_IN) {
                    currentReservations.add(r);
                    upcomingCount++;
                } else if (status == Reservation.ReservationStatus.CHECKED_OUT) {
                    completedCount++;
                } else if (status == Reservation.ReservationStatus.CANCELLED) {
                    cancelledCount++;
                }
            }

            // Count active/available special offers
            long availableOffers = 0L;
            try {
                OfferDAO offerDAO = DAOFactory.getOfferDAO();
                availableOffers = offerDAO.findActiveOffers().size();
            } catch (Exception ex) {
                logger.warn("Could not load active offers count", ex);
            }

            // Fetch recent reviews written by this guest
            java.util.List<Review> recentReviews = new java.util.ArrayList<>();
            try {
                GuestDAO guestDAO = DAOFactory.getGuestDAO();
                java.util.Optional<Guest> guestOpt = guestDAO.findByUserId(userId);
                if (guestOpt.isPresent()) {
                    ReviewDAO reviewDAO = DAOFactory.getReviewDAO();
                    recentReviews = reviewDAO.findByGuestId(guestOpt.get().getGuestId());
                }
            } catch (Exception ex) {
                logger.warn("Could not load recent reviews for user {}", userId, ex);
            }

            // Set all attributes expected by dashboard.jsp
            request.setAttribute("currentReservations",  currentReservations);
            request.setAttribute("recentReviews",        recentReviews);
            request.setAttribute("upcomingReservations", upcomingCount);
            request.setAttribute("completedReservations", completedCount);
            request.setAttribute("cancelledReservations", cancelledCount);
            request.setAttribute("availableOffers",       availableOffers);

            logger.info("Guest dashboard loaded for userId={}: upcoming={}, completed={}, cancelled={}, offers={}",
                        userId, upcomingCount, completedCount, cancelledCount, availableOffers);

            request.getRequestDispatcher("/views/guest/dashboard.jsp").forward(request, response);

        } catch (Exception e) {
            logger.error("Error loading guest dashboard for user {}", user.getUserId(), e);
            request.setAttribute(Constants.ATTR_ERROR, "Error loading dashboard. Please try again.");
            request.getRequestDispatcher("/views/guest/dashboard.jsp").forward(request, response);
        }
    }
}
