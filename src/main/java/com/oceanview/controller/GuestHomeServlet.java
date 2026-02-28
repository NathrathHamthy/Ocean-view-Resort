package com.oceanview.controller;

import com.oceanview.model.User;
import com.oceanview.service.GuestService;
import com.oceanview.service.GuestService.GuestStatistics;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.io.IOException;
import java.sql.SQLException;

/**
 * Guest Home Servlet
 * Displays the guest dashboard/home page with statistics and current bookings
 * URL Mapping: /guest/home (configured in web.xml)
 * 
 * @author Ocean View Resort Development Team
 * @version 1.0.0
 */
public class GuestHomeServlet extends HttpServlet {
    
    private static final Logger logger = LoggerFactory.getLogger(GuestHomeServlet.class);
    private final GuestService guestService;
    
    public GuestHomeServlet() {
        this.guestService = new GuestService();
    }
    
    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        
        HttpSession session = request.getSession(false);
        
        // Check if user is logged in - use "loggedInUser" as set by LoginServlet
        if (session == null || session.getAttribute("loggedInUser") == null) {
            response.sendRedirect(request.getContextPath() + "/login");
            return;
        }
        
        User user = (User) session.getAttribute("loggedInUser");
        
        // Check if user has GUEST role
        if (!"GUEST".equals(user.getRole().toString())) {
            logger.warn("Unauthorized access attempt to guest home by user: {} with role: {}", 
                       user.getUsername(), user.getRole());
            response.sendRedirect(request.getContextPath() + "/dashboard");
            return;
        }
        
        try {
            // Load guest statistics from database
            GuestStatistics stats = guestService.getGuestStatistics(user.getUserId());
            
            // Set attributes for JSP
            request.setAttribute("activeBookingsCount", stats.getActiveBookingsCount());
            request.setAttribute("reviewsWrittenCount", stats.getReviewsWrittenCount());
            request.setAttribute("totalStaysCount", stats.getTotalStaysCount());
            request.setAttribute("loyaltyPoints", stats.getLoyaltyPoints());
            request.setAttribute("currentBooking", stats.getCurrentBooking());
            request.setAttribute("activeOffers", stats.getActiveOffers());
            
            logger.info("Guest home accessed by: {} - Stats loaded successfully", user.getUsername());
            
        } catch (SQLException e) {
            logger.error("Error loading guest statistics for user: {}", user.getUsername(), e);
            // Set default values on error
            request.setAttribute("activeBookingsCount", 0);
            request.setAttribute("reviewsWrittenCount", 0);
            request.setAttribute("totalStaysCount", 0);
            request.setAttribute("loyaltyPoints", 0);
            request.setAttribute("error", "Unable to load dashboard data. Please try again later.");
        }
        
        request.getRequestDispatcher("/views/guest/home.jsp").forward(request, response);
    }
    
    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        doGet(request, response);
    }
}
