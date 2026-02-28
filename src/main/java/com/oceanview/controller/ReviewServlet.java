package com.oceanview.controller;

import com.oceanview.dao.ReviewDAO;
import com.oceanview.dao.ReservationDAO;
import com.oceanview.dao.GuestDAO;
import com.oceanview.model.Review;
import com.oceanview.model.Reservation;
import com.oceanview.model.User;
import com.oceanview.util.Constants;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.io.IOException;
import java.sql.SQLException;
import java.util.List;
import java.util.Optional;
import java.util.stream.Collectors;

/**
 * Review Servlet
 * Handles guest reviews and ratings
 * URL Mapping: /review (configured in web.xml)
 * 
 * @author Ocean View Resort Development Team
 * @version 1.0.0
 */
public class ReviewServlet extends HttpServlet {
    
    private static final Logger logger = LoggerFactory.getLogger(ReviewServlet.class);
    private ReviewDAO reviewDAO;
    private ReservationDAO reservationDAO;
    private GuestDAO guestDAO;
    
    @Override
    public void init() throws ServletException {
        reviewDAO = new ReviewDAO();
        reservationDAO = new ReservationDAO();
        guestDAO = new GuestDAO();
        logger.info("ReviewServlet initialized");
    }
    
    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        
        String action = request.getParameter("action");
        
        if (action == null || action.isEmpty()) {
            action = "myReviews";
        }

        String requestURI = request.getRequestURI();
        boolean isAdminReq = requestURI.contains("/admin/reviews");

        try {
            if (isAdminReq) {
                listAdminReviews(request, response);
                return;
            }
            switch (action) {
                case "list":
                case "myReviews":
                    showMyReviews(request, response);
                    break;
                case "view":
                    viewReview(request, response);
                    break;
                case "create":
                case "new":
                    showCreateForm(request, response);
                    break;
                case "pending":
                    showPendingReviews(request, response);
                    break;
                default:
                    showMyReviews(request, response);
                    break;
            }
        } catch (Exception e) {
            logger.error("Error in ReviewServlet GET", e);
            response.sendRedirect(request.getContextPath() + "/review");
        }
    }
    
    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        
        String action = request.getParameter("action");
        
        if (action == null || action.isEmpty()) {
            response.sendError(HttpServletResponse.SC_BAD_REQUEST, "Action parameter is required");
            return;
        }
        
        String postURI = request.getRequestURI();
        boolean isAdminPost = postURI.contains("/admin/reviews");

        try {
            switch (action) {
                case "create":
                    createReview(request, response);
                    break;
                case "update":
                    updateReview(request, response);
                    break;
                case "approve":
                    approveReviewAdmin(request, response, isAdminPost);
                    break;
                case "reject":
                    rejectReviewAdmin(request, response, isAdminPost);
                    break;
                case "respond":
                    respondToReviewAdmin(request, response, isAdminPost);
                    break;
                case "delete":
                    deleteReviewAdmin(request, response, isAdminPost);
                    break;
                default:
                    response.sendError(HttpServletResponse.SC_BAD_REQUEST, "Invalid action");
                    break;
            }
        } catch (Exception e) {
            logger.error("Error in ReviewServlet POST", e);
            response.sendRedirect(request.getContextPath() + (isAdminPost ? "/admin/reviews" : "/review"));
        }
    }
    
    /**
     * List ALL reviews for admin management page
     */
    private void listAdminReviews(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException, SQLException {

        List<Review> all = reviewDAO.findAll();
        String statusFilter = request.getParameter("status");
        List<Review> reviews;
        if (statusFilter != null && !statusFilter.isEmpty()) {
            final String sf = statusFilter.toUpperCase();
            reviews = all.stream()
                .filter(r -> r.getStatus().name().equals(sf))
                .collect(java.util.stream.Collectors.toList());
        } else {
            reviews = all;
        }

        long pendingCount  = all.stream().filter(Review::isPending).count();
        long approvedCount = all.stream().filter(Review::isApproved).count();
        long rejectedCount = all.stream().filter(Review::isRejected).count();
        double avgRating   = all.stream().filter(Review::isApproved)
            .mapToInt(Review::getRating).average().orElse(0.0);

        request.setAttribute("reviews",       reviews);
        request.setAttribute("allReviews",    all);
        request.setAttribute("statusFilter",  statusFilter);
        request.setAttribute("pendingCount",  pendingCount);
        request.setAttribute("approvedCount", approvedCount);
        request.setAttribute("rejectedCount", rejectedCount);
        request.setAttribute("avgRating",     String.format("%.1f", avgRating));
        request.setAttribute("totalCount",    all.size());

        HttpSession session = request.getSession(false);
        if (session != null) {
            String s = (String) session.getAttribute(Constants.ATTR_SUCCESS);
            String e = (String) session.getAttribute(Constants.ATTR_ERROR);
            if (s != null) { request.setAttribute(Constants.ATTR_SUCCESS, s); session.removeAttribute(Constants.ATTR_SUCCESS); }
            if (e != null) { request.setAttribute(Constants.ATTR_ERROR,   e); session.removeAttribute(Constants.ATTR_ERROR);   }
        }

        request.getRequestDispatcher("/views/admin/reviews.jsp").forward(request, response);
    }

    /**
     * Approve review - admin aware redirect
     */
    private void approveReviewAdmin(HttpServletRequest request, HttpServletResponse response, boolean isAdmin)
            throws ServletException, IOException, SQLException {
        String idStr = request.getParameter("id");
        HttpSession session = request.getSession();
        try {
            int reviewId = Integer.parseInt(idStr);
            boolean ok = reviewDAO.updateStatus(reviewId, Review.ReviewStatus.APPROVED);
            if (ok) session.setAttribute(Constants.ATTR_SUCCESS, "Review approved successfully.");
            else    session.setAttribute(Constants.ATTR_ERROR,   "Failed to approve review.");
        } catch (Exception e) {
            session.setAttribute(Constants.ATTR_ERROR, "Invalid review ID.");
        }
        response.sendRedirect(request.getContextPath() + (isAdmin ? "/admin/reviews" : "/review?action=pending"));
    }

    /**
     * Reject review - admin aware redirect
     */
    private void rejectReviewAdmin(HttpServletRequest request, HttpServletResponse response, boolean isAdmin)
            throws ServletException, IOException, SQLException {
        String idStr = request.getParameter("id");
        HttpSession session = request.getSession();
        try {
            int reviewId = Integer.parseInt(idStr);
            boolean ok = reviewDAO.updateStatus(reviewId, Review.ReviewStatus.REJECTED);
            if (ok) session.setAttribute(Constants.ATTR_SUCCESS, "Review rejected successfully.");
            else    session.setAttribute(Constants.ATTR_ERROR,   "Failed to reject review.");
        } catch (Exception e) {
            session.setAttribute(Constants.ATTR_ERROR, "Invalid review ID.");
        }
        response.sendRedirect(request.getContextPath() + (isAdmin ? "/admin/reviews" : "/review?action=pending"));
    }

    /**
     * Respond to review - admin aware redirect
     */
    private void respondToReviewAdmin(HttpServletRequest request, HttpServletResponse response, boolean isAdmin)
            throws ServletException, IOException, SQLException {
        String idStr = request.getParameter("id");
        String responseText = request.getParameter("response");
        HttpSession session = request.getSession();
        try {
            int reviewId = Integer.parseInt(idStr);
            if (responseText == null || responseText.trim().isEmpty()) {
                session.setAttribute(Constants.ATTR_ERROR, "Response text is required.");
            } else {
                boolean ok = reviewDAO.addResponse(reviewId, responseText.trim());
                if (ok) session.setAttribute(Constants.ATTR_SUCCESS, "Response added successfully.");
                else    session.setAttribute(Constants.ATTR_ERROR,   "Failed to add response.");
            }
        } catch (Exception e) {
            session.setAttribute(Constants.ATTR_ERROR, "Invalid review ID.");
        }
        response.sendRedirect(request.getContextPath() + (isAdmin ? "/admin/reviews" : "/review?action=pending"));
    }

    /**
     * Delete review - admin aware redirect
     */
    private void deleteReviewAdmin(HttpServletRequest request, HttpServletResponse response, boolean isAdmin)
            throws ServletException, IOException, SQLException {
        String idStr = request.getParameter("id");
        HttpSession session = request.getSession();
        try {
            int reviewId = Integer.parseInt(idStr);
            boolean ok = reviewDAO.delete(reviewId);
            if (ok) session.setAttribute(Constants.ATTR_SUCCESS, "Review deleted successfully.");
            else    session.setAttribute(Constants.ATTR_ERROR,   "Failed to delete review.");
        } catch (Exception e) {
            session.setAttribute(Constants.ATTR_ERROR, "Invalid review ID.");
        }
        response.sendRedirect(request.getContextPath() + (isAdmin ? "/admin/reviews" : "/review?action=myReviews"));
    }

    /**
     * List all approved reviews — delegates to showMyReviews for the guest page
     */
    private void listReviews(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException, SQLException {
        showMyReviews(request, response);
    }
    
    /**
     * View review details — shows the guest reviews page with the specific review highlighted.
     * Falls back to the full reviews list if ID is missing or not found.
     */
    private void viewReview(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException, SQLException {

        String reviewIdStr = request.getParameter("id");

        if (reviewIdStr == null || reviewIdStr.isEmpty()) {
            request.setAttribute(Constants.ATTR_ERROR, "Review ID is required");
            showMyReviews(request, response);
            return;
        }

        try {
            int reviewId = Integer.parseInt(reviewIdStr);
            Optional<Review> reviewOpt = reviewDAO.findById(reviewId);

            if (reviewOpt.isPresent()) {
                // Surface the single review as a request attribute; the guest reviews page
                // already lists all reviews, so just forward there.
                request.setAttribute("highlightReviewId", reviewId);
                showMyReviews(request, response);
            } else {
                request.setAttribute(Constants.ATTR_ERROR, "Review not found");
                showMyReviews(request, response);
            }
        } catch (NumberFormatException e) {
            logger.error("Invalid review ID: {}", reviewIdStr);
            request.setAttribute(Constants.ATTR_ERROR, "Invalid review ID");
            showMyReviews(request, response);
        }
    }
    
    /**
     * Show create review form — redirects to the guest reviews page with the
     * reservationId pre-selected so the inline write-review panel auto-scrolls.
     */
    private void showCreateForm(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException, SQLException {

        String reservationIdStr = request.getParameter("reservationId");

        if (reservationIdStr == null || reservationIdStr.isEmpty()) {
            request.setAttribute(Constants.ATTR_ERROR, "Reservation ID is required");
            response.sendRedirect(request.getContextPath() + "/reservation");
            return;
        }

        // Delegate to showMyReviews so the full reviews page loads with the
        // reservationId already selected in the write-review form.
        request.setAttribute("reservationId", reservationIdStr);
        showMyReviews(request, response);
    }
    
    /**
     * Show user's reviews — forwards to /views/guest/reviews.jsp
     * Attributes set:
     *   reviews              – List<Review>  all reviews by this guest
     *   eligibleReservations – List<Reservation> CHECKED_OUT stays not yet reviewed
     */
    private void showMyReviews(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException, SQLException {

        HttpSession session = request.getSession();
        User user = (User) session.getAttribute(Constants.SESSION_USER);

        if (user == null) {
            response.sendRedirect(request.getContextPath() + "/login");
            return;
        }

        int userId = user.getUserId();

        // Resolve the guest_id (guests.guest_id) from the logged-in user_id.
        // These are different keys: users.user_id != guests.guest_id.
        int guestId = guestDAO.findGuestIdByUserId(userId);

        if (guestId == -1) {
            // User has no guest profile yet — show empty page
            request.setAttribute("myReviews", new java.util.ArrayList<>());
            request.setAttribute("eligibleReservations", new java.util.ArrayList<>());
            logger.info("showMyReviews: no guest profile found for userId={}", userId);
            request.getRequestDispatcher("/views/guest/reviews.jsp").forward(request, response);
            return;
        }

        // 1. All reviews written by this guest
        List<Review> reviews = reviewDAO.findByGuestId(guestId);
        request.setAttribute("myReviews", reviews);

        // 2. Collect reservation IDs already reviewed so we can exclude them
        final java.util.Set<Integer> reviewedResIds = reviews.stream()
                .map(Review::getReservationId)
                .collect(java.util.stream.Collectors.toSet());

        // 3. Fetch completed reservations for this guest that haven't been reviewed yet
        List<Reservation> allRes = reservationDAO.findByGuestId(guestId);
        List<Reservation> eligible = allRes.stream()
                .filter(r -> r.getStatus() == Reservation.ReservationStatus.CHECKED_OUT)
                .filter(r -> !reviewedResIds.contains(r.getReservationId()))
                .collect(Collectors.toList());
        request.setAttribute("eligibleReservations", eligible);

        // Pre-select a reservation if coming from create/new action
        String reservationId = (String) request.getAttribute("reservationId");
        if (reservationId == null) reservationId = request.getParameter("reservationId");
        if (reservationId != null) request.setAttribute("reservationId", reservationId);

        logger.info("showMyReviews: userId={}, guestId={}, reviews={}, eligible={}", userId, guestId, reviews.size(), eligible.size());

        request.getRequestDispatcher("/views/guest/reviews.jsp").forward(request, response);
    }
    
    /**
     * Show pending reviews (Admin/Staff only)
     */
    private void showPendingReviews(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException, SQLException {
        
        HttpSession session = request.getSession();
        User user = (User) session.getAttribute(Constants.SESSION_USER);
        
        if (user == null) {
            response.sendRedirect(request.getContextPath() + "/login");
            return;
        }
        
        // Only admin and staff can view pending reviews
        if (!user.isAdmin() && !user.isStaff()) {
            request.setAttribute(Constants.ATTR_ERROR, Constants.MSG_ACCESS_DENIED);
            response.sendRedirect(request.getContextPath() + "/dashboard");
            return;
        }
        
        List<Review> pendingReviews = reviewDAO.findPendingReviews();
        request.setAttribute("reviews", pendingReviews);
        
        logger.info("Loaded {} pending reviews", pendingReviews.size());
        
        // Both admin and staff use the admin reviews page (the only reviews JSP that exists)
        request.getRequestDispatcher("/views/admin/reviews.jsp").forward(request, response);
    }
    
    /**
     * Create a new review
     */
    private void createReview(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException, SQLException {
        
        HttpSession session = request.getSession();
        User user = (User) session.getAttribute(Constants.SESSION_USER);
        
        if (user == null) {
            response.sendRedirect(request.getContextPath() + "/login");
            return;
        }
        
        // Get form parameters
        String reservationIdStr = request.getParameter("reservationId");
        String ratingStr = request.getParameter("rating");
        String cleanlinessRatingStr = request.getParameter("cleanlinessRating");
        String serviceRatingStr = request.getParameter("serviceRating");
        String valueRatingStr = request.getParameter("valueRating");
        String comment = request.getParameter("comment");
        
        // Validate input
        if (reservationIdStr == null || reservationIdStr.isEmpty()) {
            request.setAttribute(Constants.ATTR_ERROR, "Reservation ID is required");
            showCreateForm(request, response);
            return;
        }
        
        if (ratingStr == null || ratingStr.isEmpty()) {
            request.setAttribute(Constants.ATTR_ERROR, "Overall rating is required");
            showCreateForm(request, response);
            return;
        }
        
        try {
            int reservationId = Integer.parseInt(reservationIdStr);
            User sessionUser = (User) request.getSession().getAttribute(Constants.SESSION_USER);
            int guestId = guestDAO.findGuestIdByUserId(sessionUser.getUserId());
            if (guestId == -1) {
                request.setAttribute(Constants.ATTR_ERROR, "Guest profile not found. Please complete your profile first.");
                showMyReviews(request, response);
                return;
            }
            int rating = Integer.parseInt(ratingStr);
            
            // Validate rating range
            if (rating < 1 || rating > 5) {
                request.setAttribute(Constants.ATTR_ERROR, "Rating must be between 1 and 5");
                showCreateForm(request, response);
                return;
            }
            
            // Create review object
            Review review = new Review();
            review.setReservationId(reservationId);
            review.setGuestId(guestId);
            review.setRating(rating);
            
            if (cleanlinessRatingStr != null && !cleanlinessRatingStr.isEmpty()) {
                review.setCleanlinessRating(Integer.parseInt(cleanlinessRatingStr));
            }
            
            if (serviceRatingStr != null && !serviceRatingStr.isEmpty()) {
                review.setServiceRating(Integer.parseInt(serviceRatingStr));
            }
            
            if (valueRatingStr != null && !valueRatingStr.isEmpty()) {
                review.setValueRating(Integer.parseInt(valueRatingStr));
            }
            
            review.setComment(comment);
            review.setStatus(Review.ReviewStatus.PENDING);
            
            // Save review
            int reviewId = reviewDAO.create(review);
            
            if (reviewId > 0) {
                logger.info("Review created successfully: ID={}", reviewId);
                request.setAttribute(Constants.ATTR_SUCCESS, Constants.MSG_REVIEW_SUBMITTED);
                response.sendRedirect(request.getContextPath() + "/review?action=myReviews");
            } else {
                request.setAttribute(Constants.ATTR_ERROR, "Failed to create review");
                showCreateForm(request, response);
            }
            
        } catch (NumberFormatException e) {
            logger.error("Invalid input parameters", e);
            request.setAttribute(Constants.ATTR_ERROR, "Invalid input values");
            showCreateForm(request, response);
        }
    }
    
    /**
     * Update an existing review
     */
    private void updateReview(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException, SQLException {
        
        String reviewIdStr = request.getParameter("id");
        String ratingStr = request.getParameter("rating");
        String comment = request.getParameter("comment");
        
        if (reviewIdStr == null || reviewIdStr.isEmpty()) {
            request.setAttribute(Constants.ATTR_ERROR, "Review ID is required");
            response.sendRedirect(request.getContextPath() + "/review?action=myReviews");
            return;
        }
        
        try {
            int reviewId = Integer.parseInt(reviewIdStr);
            Optional<Review> reviewOpt = reviewDAO.findById(reviewId);
            
            if (reviewOpt.isPresent()) {
                Review review = reviewOpt.get();
                
                if (ratingStr != null && !ratingStr.isEmpty()) {
                    review.setRating(Integer.parseInt(ratingStr));
                }
                
                review.setComment(comment);
                
                boolean success = reviewDAO.update(review);
                
                if (success) {
                    logger.info("Review updated successfully: ID={}", reviewId);
                    request.setAttribute(Constants.ATTR_SUCCESS, "Review updated successfully");
                } else {
                    request.setAttribute(Constants.ATTR_ERROR, "Failed to update review");
                }
                
                viewReview(request, response);
            } else {
                request.setAttribute(Constants.ATTR_ERROR, "Review not found");
                response.sendRedirect(request.getContextPath() + "/review?action=myReviews");
            }
        } catch (NumberFormatException e) {
            logger.error("Invalid review ID: {}", reviewIdStr);
            request.setAttribute(Constants.ATTR_ERROR, "Invalid review ID");
            response.sendRedirect(request.getContextPath() + "/review?action=myReviews");
        }
    }
    
    /**
     * Approve a review (Admin/Staff only)
     */
    private void approveReview(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException, SQLException {
        
        String reviewIdStr = request.getParameter("id");
        
        if (reviewIdStr == null || reviewIdStr.isEmpty()) {
            request.setAttribute(Constants.ATTR_ERROR, "Review ID is required");
            showPendingReviews(request, response);
            return;
        }
        
        try {
            int reviewId = Integer.parseInt(reviewIdStr);
            boolean success = reviewDAO.updateStatus(reviewId, Review.ReviewStatus.APPROVED);
            
            if (success) {
                logger.info("Review approved: ID={}", reviewId);
                request.setAttribute(Constants.ATTR_SUCCESS, "Review approved successfully");
            } else {
                request.setAttribute(Constants.ATTR_ERROR, "Failed to approve review");
            }
            
            showPendingReviews(request, response);
            
        } catch (NumberFormatException e) {
            logger.error("Invalid review ID: {}", reviewIdStr);
            request.setAttribute(Constants.ATTR_ERROR, "Invalid review ID");
            showPendingReviews(request, response);
        }
    }
    
    /**
     * Reject a review (Admin/Staff only)
     */
    private void rejectReview(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException, SQLException {
        
        String reviewIdStr = request.getParameter("id");
        
        if (reviewIdStr == null || reviewIdStr.isEmpty()) {
            request.setAttribute(Constants.ATTR_ERROR, "Review ID is required");
            showPendingReviews(request, response);
            return;
        }
        
        try {
            int reviewId = Integer.parseInt(reviewIdStr);
            boolean success = reviewDAO.updateStatus(reviewId, Review.ReviewStatus.REJECTED);
            
            if (success) {
                logger.info("Review rejected: ID={}", reviewId);
                request.setAttribute(Constants.ATTR_SUCCESS, "Review rejected successfully");
            } else {
                request.setAttribute(Constants.ATTR_ERROR, "Failed to reject review");
            }
            
            showPendingReviews(request, response);
            
        } catch (NumberFormatException e) {
            logger.error("Invalid review ID: {}", reviewIdStr);
            request.setAttribute(Constants.ATTR_ERROR, "Invalid review ID");
            showPendingReviews(request, response);
        }
    }
    
    /**
     * Respond to a review (Admin/Staff only)
     */
    private void respondToReview(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException, SQLException {
        
        String reviewIdStr = request.getParameter("id");
        String responseText = request.getParameter("response");
        
        if (reviewIdStr == null || reviewIdStr.isEmpty()) {
            request.setAttribute(Constants.ATTR_ERROR, "Review ID is required");
            showPendingReviews(request, response);
            return;
        }
        
        if (responseText == null || responseText.trim().isEmpty()) {
            request.setAttribute(Constants.ATTR_ERROR, "Response text is required");
            viewReview(request, response);
            return;
        }
        
        try {
            int reviewId = Integer.parseInt(reviewIdStr);
            Optional<Review> reviewOpt = reviewDAO.findById(reviewId);
            
            if (reviewOpt.isPresent()) {
                Review review = reviewOpt.get();
                review.setResponse(responseText.trim());
                
                boolean success = reviewDAO.update(review);
                
                if (success) {
                    logger.info("Response added to review: ID={}", reviewId);
                    request.setAttribute(Constants.ATTR_SUCCESS, "Response added successfully");
                } else {
                    request.setAttribute(Constants.ATTR_ERROR, "Failed to add response");
                }
                
                viewReview(request, response);
            } else {
                request.setAttribute(Constants.ATTR_ERROR, "Review not found");
                showPendingReviews(request, response);
            }
        } catch (NumberFormatException e) {
            logger.error("Invalid review ID: {}", reviewIdStr);
            request.setAttribute(Constants.ATTR_ERROR, "Invalid review ID");
            showPendingReviews(request, response);
        }
    }
    
    /**
     * Delete a review
     */
    private void deleteReview(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException, SQLException {
        
        String reviewIdStr = request.getParameter("id");
        
        if (reviewIdStr == null || reviewIdStr.isEmpty()) {
            request.setAttribute(Constants.ATTR_ERROR, "Review ID is required");
            response.sendRedirect(request.getContextPath() + "/review?action=myReviews");
            return;
        }
        
        try {
            int reviewId = Integer.parseInt(reviewIdStr);
            boolean success = reviewDAO.delete(reviewId);
            
            if (success) {
                logger.info("Review deleted: ID={}", reviewId);
                request.setAttribute(Constants.ATTR_SUCCESS, "Review deleted successfully");
            } else {
                request.setAttribute(Constants.ATTR_ERROR, "Failed to delete review");
            }
            
            response.sendRedirect(request.getContextPath() + "/review?action=myReviews");
            
        } catch (NumberFormatException e) {
            logger.error("Invalid review ID: {}", reviewIdStr);
            request.setAttribute(Constants.ATTR_ERROR, "Invalid review ID");
            response.sendRedirect(request.getContextPath() + "/review?action=myReviews");
        }
    }
}
