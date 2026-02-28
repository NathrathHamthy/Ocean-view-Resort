package com.oceanview.controller;

import com.oceanview.dao.PaymentDAO;
import com.oceanview.dao.ReviewDAO;
import com.oceanview.model.Payment;
import com.oceanview.model.Reservation;
import com.oceanview.model.Review;
import com.oceanview.model.Room;
import com.oceanview.model.User;
import com.oceanview.service.AnalyticsService;
import com.oceanview.service.BillingService;
import com.oceanview.service.ReservationService;
import com.oceanview.service.RoomService;
import com.oceanview.factory.DAOFactory;
import com.oceanview.factory.ServiceFactory;
import com.oceanview.util.Constants;
import com.oceanview.util.DateUtil;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.io.IOException;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

/**
 * Report Servlet
 * Generates various reports for the hotel management system
 * URL Mapping: /report (configured in web.xml)
 * 
 * @author Ocean View Resort Development Team
 * @version 1.0.0
 */
public class ReportServlet extends HttpServlet {
    
    private static final Logger logger = LoggerFactory.getLogger(ReportServlet.class);
    private ReservationService reservationService;
    private RoomService roomService;
    private BillingService billingService;
    private AnalyticsService analyticsService;
    private PaymentDAO paymentDAO;
    private ReviewDAO reviewDAO;

    @Override
    public void init() throws ServletException {
        reservationService  = ServiceFactory.getReservationService();
        roomService         = ServiceFactory.getRoomService();
        billingService      = ServiceFactory.getBillingService();
        analyticsService    = ServiceFactory.getAnalyticsService();
        paymentDAO          = DAOFactory.getPaymentDAO();
        reviewDAO           = DAOFactory.getReviewDAO();
        logger.info("ReportServlet initialized");
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
        
        // Only admin and staff can access reports
        if (!user.isAdmin() && !user.isStaff()) {
            request.setAttribute(Constants.ATTR_ERROR, Constants.MSG_ACCESS_DENIED);
            response.sendRedirect(request.getContextPath() + "/dashboard");
            return;
        }
        
        String action = request.getParameter("action");
        
        if (action == null || action.isEmpty()) {
            action = "dashboard";
        }
        
        try {
            switch (action) {
                case "dashboard":
                    showReportDashboard(request, response);
                    break;
                case "revenue":
                    generateRevenueReport(request, response);
                    break;
                case "occupancy":
                    generateOccupancyReport(request, response);
                    break;
                case "reservations":
                    generateReservationReport(request, response);
                    break;
                case "rooms":
                    generateRoomReport(request, response);
                    break;
                default:
                    showReportDashboard(request, response);
                    break;
            }
        } catch (Exception e) {
            logger.error("Error in ReportServlet GET", e);
            request.setAttribute(Constants.ATTR_ERROR, "Error generating report");
            request.getRequestDispatcher("/views/error/error.jsp").forward(request, response);
        }
    }
    
    /**
     * Show report dashboard - loads all real analytics data
     */
    private void showReportDashboard(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        logger.info("Loading report dashboard");

        try {
            // ── Reservation stats ──
            List<Reservation> allReservations = reservationService.getAllReservations();
            long pendingRes    = allReservations.stream().filter(Reservation::isPending).count();
            long confirmedRes  = allReservations.stream().filter(Reservation::isConfirmed).count();
            long checkedInRes  = allReservations.stream().filter(Reservation::isCheckedIn).count();
            long checkedOutRes = allReservations.stream().filter(Reservation::isCheckedOut).count();
            long cancelledRes  = allReservations.stream().filter(Reservation::isCancelled).count();

            // ── Room stats ──
            int[] roomStats = roomService.getRoomStatistics();
            int totalRooms     = roomStats[0] + roomStats[1] + roomStats[2] + roomStats[3];
            double occRate     = totalRooms > 0 ? (double) roomStats[1] / totalRooms * 100 : 0;
            List<Room> allRooms = roomService.getAllRooms();

            // ── Revenue stats ──
            double totalRevenue  = billingService.getTotalRevenue();
            double todayRevenue  = paymentDAO.getTodayRevenue();
            double monthRevenue  = paymentDAO.getMonthlyRevenue();
            double yearRevenue   = paymentDAO.getYearlyRevenue();

            // ── Monthly revenue for chart (last 6 months) ──
            Map<String, Double> monthlyRevMap = new LinkedHashMap<>();
            String[] months = {"Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"};
            int curMonth = LocalDate.now().getMonthValue();
            int curYear  = LocalDate.now().getYear();
            for (int i = 5; i >= 0; i--) {
                int m = curMonth - i;
                if (m <= 0) { m += 12; }
                monthlyRevMap.put(months[m-1], 0.0);
            }
            // Use current month actual revenue for last entry
            monthlyRevMap.put(months[curMonth-1], paymentDAO.getMonthlyRevenue());

            // ── Room type distribution ──
            Map<String, Long> roomsByType = allRooms.stream()
                .collect(Collectors.groupingBy(r -> r.getRoomType().name(), Collectors.counting()));

            // ── Recent reservations (last 10) ──
            List<Reservation> recentReservations = allReservations.stream()
                .sorted((a, b) -> {
                    if (b.getCreatedAt() == null) return -1;
                    if (a.getCreatedAt() == null) return 1;
                    return b.getCreatedAt().compareTo(a.getCreatedAt());
                })
                .limit(10)
                .collect(Collectors.toList());

            // ── Recent payments ──
            List<Payment> allPayments = billingService.getAllPayments();
            List<Payment> recentPayments = allPayments.stream()
                .filter(p -> p.getPaymentDate() != null)
                .sorted((a, b) -> b.getPaymentDate().compareTo(a.getPaymentDate()))
                .limit(10)
                .collect(Collectors.toList());

            // ── Revenue by payment method ──
            Map<String, Double> revenueByMethod = allPayments.stream()
                .filter(Payment::isCompleted)
                .collect(Collectors.groupingBy(
                    p -> p.getPaymentMethod().name(),
                    Collectors.summingDouble(p -> p.getAmount().doubleValue())
                ));

            // ── Review stats ──
            List<Review> allReviews = reviewDAO.findAll();
            long approvedReviews  = allReviews.stream().filter(Review::isApproved).count();
            long pendingReviews   = allReviews.stream().filter(Review::isPending).count();
            double avgRating      = allReviews.stream().filter(Review::isApproved)
                .mapToInt(Review::getRating).average().orElse(0.0);

            // ── Today's activities ──
            int todayCheckIns  = reservationService.getTodayCheckIns().size();
            int todayCheckOuts = reservationService.getTodayCheckOuts().size();

            // ── Set all attributes ──
            request.setAttribute("totalReservations",  allReservations.size());
            request.setAttribute("pendingRes",         pendingRes);
            request.setAttribute("confirmedRes",       confirmedRes);
            request.setAttribute("checkedInRes",       checkedInRes);
            request.setAttribute("checkedOutRes",      checkedOutRes);
            request.setAttribute("cancelledRes",       cancelledRes);
            request.setAttribute("totalRooms",         totalRooms);
            request.setAttribute("availableRooms",     roomStats[0]);
            request.setAttribute("occupiedRooms",      roomStats[1]);
            request.setAttribute("reservedRooms",      roomStats[2]);
            request.setAttribute("maintenanceRooms",   roomStats[3]);
            request.setAttribute("occupancyRate",      String.format("%.1f", occRate));
            request.setAttribute("totalRevenue",       String.format("%.2f", totalRevenue));
            request.setAttribute("todayRevenue",       String.format("%.2f", todayRevenue));
            request.setAttribute("monthRevenue",       String.format("%.2f", monthRevenue));
            request.setAttribute("yearRevenue",        String.format("%.2f", yearRevenue));
            request.setAttribute("monthlyRevMap",      monthlyRevMap);
            request.setAttribute("roomsByType",        roomsByType);
            request.setAttribute("recentReservations", recentReservations);
            request.setAttribute("recentPayments",     recentPayments);
            request.setAttribute("revenueByMethod",    revenueByMethod);
            request.setAttribute("totalReviews",       allReviews.size());
            request.setAttribute("approvedReviews",    approvedReviews);
            request.setAttribute("pendingReviews",     pendingReviews);
            request.setAttribute("avgRating",          String.format("%.1f", avgRating));
            request.setAttribute("todayCheckIns",      todayCheckIns);
            request.setAttribute("todayCheckOuts",     todayCheckOuts);

        } catch (Exception e) {
            logger.error("Error loading dashboard data", e);
            request.setAttribute(Constants.ATTR_ERROR, "Error loading report data: " + e.getMessage());
        }

        request.getRequestDispatcher("/views/admin/reports.jsp").forward(request, response);
    }
    
    /**
     * Generate revenue report
     */
    private void generateRevenueReport(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        
        String startDateStr = request.getParameter("startDate");
        String endDateStr = request.getParameter("endDate");
        
        LocalDate startDate = startDateStr != null ? DateUtil.parseDate(startDateStr) : LocalDate.now().minusMonths(1);
        LocalDate endDate = endDateStr != null ? DateUtil.parseDate(endDateStr) : LocalDate.now();
        
        logger.info("Generating revenue report from {} to {}", startDate, endDate);
        
        // Get all payments
        List<Payment> allPayments = billingService.getAllPayments();
        
        // Filter payments by date range
        List<Payment> filteredPayments = allPayments.stream()
            .filter(p -> p.getPaymentDate() != null)
            .filter(p -> {
                LocalDate paymentDate = p.getPaymentDate().toLocalDate();
                return !paymentDate.isBefore(startDate) && !paymentDate.isAfter(endDate);
            })
            .collect(Collectors.toList());
        
        // Calculate totals
        double totalRevenue = filteredPayments.stream()
            .filter(Payment::isCompleted)
            .mapToDouble(p -> p.getAmount().doubleValue())
            .sum();
        
        double totalRefunds = filteredPayments.stream()
            .filter(Payment::isRefunded)
            .mapToDouble(p -> p.getAmount().doubleValue())
            .sum();
        
        double netRevenue = totalRevenue - totalRefunds;
        
        // Group by payment method
        Map<String, Double> revenueByMethod = filteredPayments.stream()
            .filter(Payment::isCompleted)
            .collect(Collectors.groupingBy(
                p -> p.getPaymentMethod().name(),
                Collectors.summingDouble(p -> p.getAmount().doubleValue())
            ));
        
        request.setAttribute("startDate", startDate);
        request.setAttribute("endDate", endDate);
        request.setAttribute("payments", filteredPayments);
        request.setAttribute("totalRevenue", totalRevenue);
        request.setAttribute("totalRefunds", totalRefunds);
        request.setAttribute("netRevenue", netRevenue);
        request.setAttribute("revenueByMethod", revenueByMethod);
        
        request.getRequestDispatcher("/views/reports/revenue.jsp").forward(request, response);
    }
    
    /**
     * Generate occupancy report
     */
    private void generateOccupancyReport(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        
        logger.info("Generating occupancy report");
        
        // Get room statistics
        int[] roomStats = roomService.getRoomStatistics();
        int totalRooms = roomStats[0] + roomStats[1] + roomStats[2] + roomStats[3];
        
        double occupancyRate = totalRooms > 0 ? 
            (double) roomStats[1] / totalRooms * 100 : 0;
        
        // Get all rooms
        List<Room> allRooms = roomService.getAllRooms();
        
        // Group rooms by type
        Map<String, Long> roomsByType = allRooms.stream()
            .collect(Collectors.groupingBy(
                r -> r.getRoomType().name(),
                Collectors.counting()
            ));
        
        // Group rooms by status
        Map<String, Long> roomsByStatus = allRooms.stream()
            .collect(Collectors.groupingBy(
                r -> r.getStatus().name(),
                Collectors.counting()
            ));
        
        request.setAttribute("totalRooms", totalRooms);
        request.setAttribute("availableRooms", roomStats[0]);
        request.setAttribute("occupiedRooms", roomStats[1]);
        request.setAttribute("reservedRooms", roomStats[2]);
        request.setAttribute("maintenanceRooms", roomStats[3]);
        request.setAttribute("occupancyRate", occupancyRate);
        request.setAttribute("roomsByType", roomsByType);
        request.setAttribute("roomsByStatus", roomsByStatus);
        request.setAttribute("allRooms", allRooms);
        
        request.getRequestDispatcher("/views/reports/occupancy.jsp").forward(request, response);
    }
    
    /**
     * Generate reservation report
     */
    private void generateReservationReport(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        
        String startDateStr = request.getParameter("startDate");
        String endDateStr = request.getParameter("endDate");
        String status = request.getParameter("status");
        
        LocalDate startDate = startDateStr != null ? DateUtil.parseDate(startDateStr) : LocalDate.now().minusMonths(1);
        LocalDate endDate = endDateStr != null ? DateUtil.parseDate(endDateStr) : LocalDate.now();
        
        logger.info("Generating reservation report from {} to {}", startDate, endDate);
        
        // Get all reservations
        List<Reservation> allReservations = reservationService.getAllReservations();
        
        // Filter reservations
        List<Reservation> filteredReservations = allReservations.stream()
            .filter(r -> r.getCheckInDate() != null)
            .filter(r -> !r.getCheckInDate().isBefore(startDate) && !r.getCheckInDate().isAfter(endDate))
            .filter(r -> status == null || status.isEmpty() || r.getStatus().name().equals(status))
            .collect(Collectors.toList());
        
        // Group by status
        Map<String, Long> reservationsByStatus = filteredReservations.stream()
            .collect(Collectors.groupingBy(
                r -> r.getStatus().name(),
                Collectors.counting()
            ));
        
        // Calculate total revenue from reservations
        double totalReservationRevenue = filteredReservations.stream()
            .filter(r -> !r.isCancelled())
            .mapToDouble(r -> r.getFinalAmount().doubleValue())
            .sum();
        
        request.setAttribute("startDate", startDate);
        request.setAttribute("endDate", endDate);
        request.setAttribute("selectedStatus", status);
        request.setAttribute("reservations", filteredReservations);
        request.setAttribute("reservationsByStatus", reservationsByStatus);
        request.setAttribute("totalReservationRevenue", totalReservationRevenue);
        
        request.getRequestDispatcher("/views/reports/reservations.jsp").forward(request, response);
    }
    
    /**
     * Generate room report
     */
    private void generateRoomReport(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        
        logger.info("Generating room report");
        
        List<Room> allRooms = roomService.getAllRooms();
        
        // Group by room type
        Map<String, List<Room>> roomsByType = allRooms.stream()
            .collect(Collectors.groupingBy(r -> r.getRoomType().name()));
        
        // Calculate statistics per room type
        Map<String, Map<String, Object>> typeStats = new HashMap<>();
        
        for (String type : roomsByType.keySet()) {
            List<Room> rooms = roomsByType.get(type);
            Map<String, Object> stats = new HashMap<>();
            
            stats.put("total", rooms.size());
            stats.put("available", rooms.stream().filter(Room::isAvailable).count());
            stats.put("occupied", rooms.stream().filter(Room::isOccupied).count());
            stats.put("reserved", rooms.stream().filter(Room::isReserved).count());
            stats.put("maintenance", rooms.stream().filter(Room::isUnderMaintenance).count());
            
            // Average price
            double avgPrice = rooms.stream()
                .mapToDouble(r -> r.getPricePerNight().doubleValue())
                .average()
                .orElse(0.0);
            stats.put("avgPrice", avgPrice);
            
            typeStats.put(type, stats);
        }
        
        request.setAttribute("allRooms", allRooms);
        request.setAttribute("roomsByType", roomsByType);
        request.setAttribute("typeStats", typeStats);
        
        request.getRequestDispatcher("/views/reports/rooms.jsp").forward(request, response);
    }
}
