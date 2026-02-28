package com.oceanview.controller;

import com.oceanview.dao.GuestDAO;
import com.oceanview.dao.ReservationDAO;
import com.oceanview.factory.DAOFactory;
import com.oceanview.model.Guest;
import com.oceanview.model.Reservation;
import com.oceanview.model.User;
import com.oceanview.service.ReservationService;
import com.oceanview.util.Constants;
import com.oceanview.util.ValidationUtil;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.io.IOException;
import java.io.PrintWriter;
import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

/**
 * Reservation Servlet
 * Handles reservation operations
 * URL Mapping: /reservation (configured in web.xml)
 * 
 * @author Ocean View Resort Development Team
 * @version 1.0.0
 */
public class ReservationServlet extends HttpServlet {
    
    private static final Logger logger = LoggerFactory.getLogger(ReservationServlet.class);
    private ReservationService reservationService;
    
    @Override
    public void init() throws ServletException {
        reservationService = new ReservationService();
        logger.info("ReservationServlet initialized");
    }
    
    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        // Guard: must be logged in
        HttpSession session = request.getSession(false);
        if (session == null || session.getAttribute(Constants.SESSION_USER) == null) {
            response.sendRedirect(request.getContextPath() + "/login");
            return;
        }

        String action = request.getParameter("action");
        if (action == null) action = "list";

        // Determine if request is coming from /staff/reservations URI
        String requestURI = request.getRequestURI();
        boolean isStaffRequest = requestURI.contains("/staff/reservations");

        boolean isAdminRequest = requestURI.contains("/admin/reservations");

        switch (action) {
            case "new":
                showBookingForm(request, response);
                break;
            case "view":
                viewReservation(request, response);
                break;
            case "cancel":
                cancelReservation(request, response, isAdminRequest);
                break;
            case "confirm":
                confirmReservation(request, response, isAdminRequest);
                break;
            case "checkin":
                checkInReservation(request, response, isAdminRequest);
                break;
            case "checkout":
                checkOutReservation(request, response, isAdminRequest);
                break;
            case "list":
            default:
                if (isAdminRequest) {
                    listAdminReservations(request, response);
                } else if (isStaffRequest) {
                    listStaffReservations(request, response);
                } else {
                    listReservations(request, response);
                }
        }
    }
    
    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        // Guard: must be logged in
        HttpSession session = request.getSession(false);
        String action = request.getParameter("action");
        if (action == null) action = "";
        if (session == null || session.getAttribute(Constants.SESSION_USER) == null) {
            // Return JSON for AJAX cancel requests, redirect otherwise
            if ("cancel".equals(action)) {
                response.setContentType("application/json;charset=UTF-8");
                response.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
                response.getWriter().print("{\"success\":false,\"message\":\"Session expired. Please log in again.\"}");
            } else {
                response.sendRedirect(request.getContextPath() + "/login");
            }
            return;
        }

        String requestURI = request.getRequestURI();
        boolean isStaffPost = requestURI.contains("/staff/reservations");
        boolean isAdminPost = requestURI.contains("/admin/reservations");

        switch (action) {
            case "create":
                createReservation(request, response);
                break;
            case "cancel":
                cancelReservationPost(request, response);
                break;
            case "confirm":
                confirmReservationPost(request, response, isAdminPost || isStaffPost);
                break;
            case "checkin":
                checkInReservationPost(request, response, isAdminPost || isStaffPost);
                break;
            case "checkout":
                checkOutReservationPost(request, response, isAdminPost || isStaffPost);
                break;
            case "update":
                updateReservation(request, response, isAdminPost);
                break;
            default:
                response.sendError(HttpServletResponse.SC_BAD_REQUEST, "Invalid action");
        }
    }
    
    /**
     * Show the booking form — pre-populated with roomId, checkIn, checkOut, guests from query params.
     */
    private void showBookingForm(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        String roomIdStr = request.getParameter("roomId");
        if (!ValidationUtil.isValidInteger(roomIdStr)) {
            response.sendRedirect(request.getContextPath() + "/rooms");
            return;
        }

        int roomId = Integer.parseInt(roomIdStr);

        // Load room details for the summary panel
        com.oceanview.service.RoomService roomService = new com.oceanview.service.RoomService();
        com.oceanview.model.Room room = roomService.getRoomById(roomId).orElse(null);

        if (room == null) {
            request.setAttribute(Constants.ATTR_ERROR, "Room not found.");
            response.sendRedirect(request.getContextPath() + "/rooms");
            return;
        }

        if (!room.isAvailable()) {
            request.setAttribute(Constants.ATTR_ERROR, "Sorry, this room is not available.");
            response.sendRedirect(request.getContextPath() + "/rooms");
            return;
        }

        // Load active offers for promo code use
        com.oceanview.dao.OfferDAO offerDAO = new com.oceanview.dao.OfferDAO();
        java.util.List<com.oceanview.model.Offer> activeOffers;
        try {
            activeOffers = offerDAO.findActiveOffers();
        } catch (Exception e) {
            activeOffers = java.util.List.of();
        }

        request.setAttribute("room", room);
        request.setAttribute("checkIn",  request.getParameter("checkIn"));
        request.setAttribute("checkOut", request.getParameter("checkOut"));
        request.setAttribute("guests",   request.getParameter("guests"));
        request.setAttribute("activeOffers", activeOffers);

        // Pass flash error if coming back from failed submit
        HttpSession session = request.getSession(false);
        String errMsg = (String) session.getAttribute(Constants.ATTR_ERROR);
        if (errMsg != null) {
            request.setAttribute(Constants.ATTR_ERROR, errMsg);
            session.removeAttribute(Constants.ATTR_ERROR);
        }

        request.getRequestDispatcher("/views/guest/booking.jsp").forward(request, response);
    }

    /**
     * Create a new reservation — auto-resolves guestId from session user.
     */
    private void createReservation(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        HttpSession session = request.getSession(false);
        User currentUser = (User) session.getAttribute(Constants.SESSION_USER);

        try {
            String roomIdStr        = request.getParameter("roomId");
            // Support both "checkIn"/"checkOut" (booking.jsp) and "checkInDate"/"checkOutDate" (legacy)
            String checkInStr       = request.getParameter("checkIn");
            if (checkInStr == null || checkInStr.isBlank())
                checkInStr          = request.getParameter("checkInDate");
            String checkOutStr      = request.getParameter("checkOut");
            if (checkOutStr == null || checkOutStr.isBlank())
                checkOutStr         = request.getParameter("checkOutDate");
            String numberOfGuestsStr= request.getParameter("numberOfGuests");
            String specialRequests  = request.getParameter("specialRequests");
            String promoCode        = request.getParameter("promoCode");
            String paymentMethod    = request.getParameter("paymentMethod");

            // Safe defaults for redirect params
            String safeRoomId  = roomIdStr         != null ? roomIdStr         : "";
            String safeCI      = checkInStr         != null ? checkInStr         : "";
            String safeCO      = checkOutStr        != null ? checkOutStr        : "";
            String safeGuests  = numberOfGuestsStr  != null ? numberOfGuestsStr  : "2";

            // Validate required params
            if (!ValidationUtil.isValidInteger(roomIdStr) ||
                checkInStr == null || checkOutStr == null ||
                checkInStr.isBlank() || checkOutStr.isBlank()) {

                session.setAttribute(Constants.ATTR_ERROR, "Please fill in all required fields: room, check-in and check-out dates.");
                response.sendRedirect(request.getContextPath() +
                    "/reservation?action=new&roomId=" + safeRoomId +
                    "&checkIn=" + safeCI + "&checkOut=" + safeCO +
                    "&guests=" + safeGuests);
                return;
            }

            // Validate guests (default to 2 if missing or invalid)
            if (!ValidationUtil.isValidInteger(numberOfGuestsStr)) {
                numberOfGuestsStr = "2";
            }

            int roomId        = Integer.parseInt(roomIdStr);
            int numberOfGuests= Integer.parseInt(numberOfGuestsStr);
            LocalDate checkIn = LocalDate.parse(checkInStr);
            LocalDate checkOut= LocalDate.parse(checkOutStr);

            // Resolve guestId from session userId
            int guestId = reservationService.getGuestIdByUserId(currentUser.getUserId());
            if (guestId < 0) {
                session.setAttribute(Constants.ATTR_ERROR,
                    "Your guest profile is not set up yet. Please complete your profile first.");
                response.sendRedirect(request.getContextPath() + "/guest/profile");
                return;
            }

            // Apply promo code discount if provided
            java.math.BigDecimal discountAmount = java.math.BigDecimal.ZERO;
            if (promoCode != null && !promoCode.isBlank()) {
                try {
                    com.oceanview.dao.OfferDAO offerDAO = new com.oceanview.dao.OfferDAO();
                    com.oceanview.model.Offer offer = offerDAO.findByPromoCode(promoCode.trim().toUpperCase());
                    if (offer != null && offer.isActive()) {
                        // Load room to compute discount
                        com.oceanview.service.RoomService roomService = new com.oceanview.service.RoomService();
                        com.oceanview.model.Room room = roomService.getRoomById(roomId).orElse(null);
                        if (room != null) {
                            long nights = java.time.temporal.ChronoUnit.DAYS.between(checkIn, checkOut);
                            java.math.BigDecimal base = room.getPricePerNight()
                                .multiply(java.math.BigDecimal.valueOf(nights));
                            if (offer.getDiscountType() == com.oceanview.model.Offer.DiscountType.PERCENTAGE) {
                                discountAmount = base.multiply(offer.getDiscountValue())
                                    .divide(java.math.BigDecimal.valueOf(100), 2, java.math.RoundingMode.HALF_UP);
                            } else {
                                // FIXED — cap at base price
                                discountAmount = offer.getDiscountValue().min(base);
                            }
                        }
                    }
                } catch (Exception ex) {
                    logger.warn("Could not apply promo code '{}': {}", promoCode, ex.getMessage());
                }
            }
            // Fallback: if server-side promo lookup failed but client sent a discountFixed, use it
            if (discountAmount.compareTo(java.math.BigDecimal.ZERO) == 0) {
                String discountFixedStr = request.getParameter("discountFixed");
                if (discountFixedStr != null && !discountFixedStr.isBlank()) {
                    try {
                        discountAmount = new java.math.BigDecimal(discountFixedStr)
                            .setScale(2, java.math.RoundingMode.HALF_UP);
                    } catch (NumberFormatException ignored) {}
                }
            }

            // Build reservation
            Reservation reservation = new Reservation();
            reservation.setGuestId(guestId);
            reservation.setRoomId(roomId);
            reservation.setCheckInDate(checkIn);
            reservation.setCheckOutDate(checkOut);
            reservation.setNumberOfGuests(numberOfGuests);
            reservation.setSpecialRequests(specialRequests);
            reservation.setDiscountAmount(discountAmount);
            reservation.setCreatedBy(currentUser.getUserId());

            int reservationId = reservationService.createReservation(reservation);

            if (reservationId > 0) {
                session.setAttribute(Constants.ATTR_SUCCESS,
                    "Reservation confirmed! Your booking has been successfully created.");
                response.sendRedirect(request.getContextPath() + "/reservation?action=list");
            } else {
                session.setAttribute(Constants.ATTR_ERROR, getErrorMessage(reservationId));
                response.sendRedirect(request.getContextPath() +
                    "/reservation?action=new&roomId=" + roomId +
                    "&checkIn=" + checkInStr + "&checkOut=" + checkOutStr +
                    "&guests=" + numberOfGuests);
            }

        } catch (Exception e) {
            logger.error("Error creating reservation", e);
            session.setAttribute(Constants.ATTR_ERROR, "An unexpected error occurred. Please try again.");
            response.sendRedirect(request.getContextPath() + "/rooms");
        }
    }
    
    /**
     * View reservation details
     * Guests can only view their own reservations.
     */
    private void viewReservation(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        String idStr = request.getParameter("id");
        if (!ValidationUtil.isValidInteger(idStr)) {
            response.sendError(HttpServletResponse.SC_BAD_REQUEST, "Invalid reservation ID");
            return;
        }

        HttpSession session = request.getSession(false);
        User user = (User) session.getAttribute(Constants.SESSION_USER);
        int reservationId = Integer.parseInt(idStr);

        Optional<Reservation> reservationOpt = reservationService.getReservationById(reservationId);

        if (reservationOpt.isEmpty()) {
            request.setAttribute(Constants.ATTR_ERROR, "Reservation not found");
            listReservations(request, response);
            return;
        }

        Reservation reservation = reservationOpt.get();

        // Ownership check for guests: verify this reservation belongs to this user
        if (user.isGuest()) {
            List<Reservation> myReservations = reservationService.getReservationsByUserId(user.getUserId());
            boolean owns = myReservations.stream()
                .anyMatch(r -> r.getReservationId().equals(reservationId));
            if (!owns) {
                response.sendError(HttpServletResponse.SC_FORBIDDEN, "Access denied");
                return;
            }
        }

        request.setAttribute("reservation", reservation);
        // Forward to the booking detail view; fall back to list view with this single item
        // so reservations.jsp can render it correctly as a list of one
        java.util.List<Reservation> single = new java.util.ArrayList<>();
        single.add(reservation);
        request.setAttribute("reservations", single);

        // Compute counts for single-item view
        long pc = reservation.isPending()    ? 1L : 0L;
        long cc = reservation.isConfirmed()  ? 1L : 0L;
        long ic = reservation.isCheckedIn()  ? 1L : 0L;
        long oc = reservation.isCheckedOut() ? 1L : 0L;
        long xc = reservation.isCancelled()  ? 1L : 0L;
        request.setAttribute("pendingCount",   pc);
        request.setAttribute("confirmedCount", cc);
        request.setAttribute("checkedInCount", ic);
        request.setAttribute("completedCount", oc);
        request.setAttribute("cancelledCount", xc);

        request.getRequestDispatcher("/views/guest/reservations.jsp").forward(request, response);
    }

    /**
     * List reservations for staff — all reservations with filter support,
     * forwards to the dedicated staff reservations view.
     */
    private void listStaffReservations(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        List<Reservation> all = reservationService.getAllReservations();

        // Server-side status filter (optional ?status= param)
        String statusFilter = request.getParameter("status");
        List<Reservation> reservations;
        if (statusFilter != null && !statusFilter.isEmpty()) {
            final String sf = statusFilter.toUpperCase();
            reservations = all.stream()
                .filter(r -> r.getStatus().name().equals(sf))
                .collect(java.util.stream.Collectors.toList());
        } else {
            reservations = all;
        }

        // Summary counts
        long pendingCount    = all.stream().filter(Reservation::isPending).count();
        long confirmedCount  = all.stream().filter(Reservation::isConfirmed).count();
        long checkedInCount  = all.stream().filter(Reservation::isCheckedIn).count();
        long checkedOutCount = all.stream().filter(Reservation::isCheckedOut).count();
        long cancelledCount  = all.stream().filter(Reservation::isCancelled).count();

        request.setAttribute("reservations",   reservations);
        request.setAttribute("statusFilter",   statusFilter);
        request.setAttribute("totalCount",     all.size());
        request.setAttribute("pendingCount",   pendingCount);
        request.setAttribute("confirmedCount", confirmedCount);
        request.setAttribute("checkedInCount", checkedInCount);
        request.setAttribute("checkedOutCount",checkedOutCount);
        request.setAttribute("cancelledCount", cancelledCount);

        // Flash messages
        HttpSession session = request.getSession(false);
        String successMsg = (String) session.getAttribute(Constants.ATTR_SUCCESS);
        String errorMsg   = (String) session.getAttribute(Constants.ATTR_ERROR);
        if (successMsg != null) { request.setAttribute(Constants.ATTR_SUCCESS, successMsg); session.removeAttribute(Constants.ATTR_SUCCESS); }
        if (errorMsg   != null) { request.setAttribute(Constants.ATTR_ERROR,   errorMsg);   session.removeAttribute(Constants.ATTR_ERROR);   }

        request.getRequestDispatcher("/views/staff/reservations.jsp").forward(request, response);
    }

    /**
     * List reservations — guests see only their own, staff/admin see all.
     */
    private void listReservations(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        HttpSession session = request.getSession(false);
        User user = (User) session.getAttribute(Constants.SESSION_USER);

        List<Reservation> reservations;

        if (user.isGuest()) {
            // Use userId → guest_id join so guests only see their own bookings
            reservations = reservationService.getReservationsByUserId(user.getUserId());
        } else {
            // Admin / Staff see everything
            reservations = reservationService.getAllReservations();
        }

        // Counts for the summary bar
        long pendingCount   = reservations.stream().filter(Reservation::isPending).count();
        long confirmedCount = reservations.stream().filter(Reservation::isConfirmed).count();
        long checkedInCount = reservations.stream().filter(Reservation::isCheckedIn).count();
        long completedCount = reservations.stream().filter(Reservation::isCheckedOut).count();
        long cancelledCount = reservations.stream().filter(Reservation::isCancelled).count();

        request.setAttribute("reservations",   reservations);
        request.setAttribute("pendingCount",   pendingCount);
        request.setAttribute("confirmedCount", confirmedCount);
        request.setAttribute("checkedInCount", checkedInCount);
        request.setAttribute("completedCount", completedCount);
        request.setAttribute("cancelledCount", cancelledCount);

        // Pass through any flash messages set by previous redirect
        String successMsg = (String) session.getAttribute(Constants.ATTR_SUCCESS);
        String errorMsg   = (String) session.getAttribute(Constants.ATTR_ERROR);
        if (successMsg != null) {
            request.setAttribute(Constants.ATTR_SUCCESS, successMsg);
            session.removeAttribute(Constants.ATTR_SUCCESS);
        }
        if (errorMsg != null) {
            request.setAttribute(Constants.ATTR_ERROR, errorMsg);
            session.removeAttribute(Constants.ATTR_ERROR);
        }

        request.getRequestDispatcher("/views/guest/reservations.jsp").forward(request, response);
    }
    
    /**
     * List all reservations for admin view
     */
    private void listAdminReservations(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        List<Reservation> all = reservationService.getAllReservations();

        String statusFilter = request.getParameter("status");
        List<Reservation> reservations;
        if (statusFilter != null && !statusFilter.isEmpty()) {
            final String sf = statusFilter.toUpperCase();
            reservations = all.stream()
                .filter(r -> r.getStatus().name().equals(sf))
                .collect(java.util.stream.Collectors.toList());
        } else {
            reservations = all;
        }

        long pendingCount    = all.stream().filter(Reservation::isPending).count();
        long confirmedCount  = all.stream().filter(Reservation::isConfirmed).count();
        long checkedInCount  = all.stream().filter(Reservation::isCheckedIn).count();
        long checkedOutCount = all.stream().filter(Reservation::isCheckedOut).count();
        long cancelledCount  = all.stream().filter(Reservation::isCancelled).count();

        request.setAttribute("reservations",    reservations);
        request.setAttribute("statusFilter",    statusFilter);
        request.setAttribute("totalCount",      all.size());
        request.setAttribute("pendingCount",    pendingCount);
        request.setAttribute("confirmedCount",  confirmedCount);
        request.setAttribute("checkedInCount",  checkedInCount);
        request.setAttribute("checkedOutCount", checkedOutCount);
        request.setAttribute("cancelledCount",  cancelledCount);

        HttpSession session = request.getSession(false);
        String successMsg = (String) session.getAttribute(Constants.ATTR_SUCCESS);
        String errorMsg   = (String) session.getAttribute(Constants.ATTR_ERROR);
        if (successMsg != null) { request.setAttribute(Constants.ATTR_SUCCESS, successMsg); session.removeAttribute(Constants.ATTR_SUCCESS); }
        if (errorMsg   != null) { request.setAttribute(Constants.ATTR_ERROR,   errorMsg);   session.removeAttribute(Constants.ATTR_ERROR);   }

        request.getRequestDispatcher("/views/admin/reservations.jsp").forward(request, response);
    }

    /**
     * Confirm reservation (GET - admin/staff)
     */
    private void confirmReservation(HttpServletRequest request, HttpServletResponse response, boolean isAdmin)
            throws ServletException, IOException {
        String idStr = request.getParameter("id");
        if (!ValidationUtil.isValidInteger(idStr)) {
            response.sendError(HttpServletResponse.SC_BAD_REQUEST, "Invalid reservation ID");
            return;
        }
        int reservationId = Integer.parseInt(idStr);
        boolean success = reservationService.confirmReservation(reservationId);
        HttpSession session = request.getSession();
        if (success) session.setAttribute(Constants.ATTR_SUCCESS, "Reservation confirmed successfully!");
        else         session.setAttribute(Constants.ATTR_ERROR,   "Failed to confirm reservation.");
        String redirect = isAdmin ? "/admin/reservations" : "/reservation?action=view&id=" + reservationId;
        response.sendRedirect(request.getContextPath() + redirect);
    }

    /**
     * Check-in reservation (GET - admin/staff)
     */
    private void checkInReservation(HttpServletRequest request, HttpServletResponse response, boolean isAdmin)
            throws ServletException, IOException {
        String idStr = request.getParameter("id");
        if (!ValidationUtil.isValidInteger(idStr)) {
            response.sendError(HttpServletResponse.SC_BAD_REQUEST, "Invalid reservation ID");
            return;
        }
        int reservationId = Integer.parseInt(idStr);
        boolean success = reservationService.checkInReservation(reservationId);
        HttpSession session = request.getSession();
        if (success) session.setAttribute(Constants.ATTR_SUCCESS, Constants.MSG_CHECKIN_SUCCESS);
        else         session.setAttribute(Constants.ATTR_ERROR,   "Failed to check-in. Must be CONFIRMED and check-in date reached.");
        String redirect = isAdmin ? "/admin/reservations" : "/reservation?action=view&id=" + reservationId;
        response.sendRedirect(request.getContextPath() + redirect);
    }

    /**
     * Check-out reservation (GET - admin/staff)
     */
    private void checkOutReservation(HttpServletRequest request, HttpServletResponse response, boolean isAdmin)
            throws ServletException, IOException {
        String idStr = request.getParameter("id");
        if (!ValidationUtil.isValidInteger(idStr)) {
            response.sendError(HttpServletResponse.SC_BAD_REQUEST, "Invalid reservation ID");
            return;
        }
        int reservationId = Integer.parseInt(idStr);
        boolean success = reservationService.checkOutReservation(reservationId);
        HttpSession session = request.getSession();
        if (success) session.setAttribute(Constants.ATTR_SUCCESS, Constants.MSG_CHECKOUT_SUCCESS);
        else         session.setAttribute(Constants.ATTR_ERROR,   "Failed to check-out. Must be in CHECKED_IN status.");
        String redirect = isAdmin ? "/admin/reservations" : "/reservation?action=view&id=" + reservationId;
        response.sendRedirect(request.getContextPath() + redirect);
    }

    /**
     * Cancel reservation via GET redirect (admin/staff/guest)
     */
    private void cancelReservation(HttpServletRequest request, HttpServletResponse response, boolean isAdmin)
            throws ServletException, IOException {
        String idStr = request.getParameter("id");
        if (!ValidationUtil.isValidInteger(idStr)) {
            response.sendError(HttpServletResponse.SC_BAD_REQUEST, "Invalid reservation ID");
            return;
        }
        int reservationId = Integer.parseInt(idStr);
        HttpSession session = request.getSession(false);
        User user = (User) session.getAttribute(Constants.SESSION_USER);
        if (user.isGuest() && !ownsReservation(user.getUserId(), reservationId)) {
            response.sendError(HttpServletResponse.SC_FORBIDDEN, "Access denied");
            return;
        }
        boolean success = reservationService.cancelReservation(reservationId);
        if (success) session.setAttribute(Constants.ATTR_SUCCESS, Constants.MSG_RESERVATION_CANCELLED);
        else         session.setAttribute(Constants.ATTR_ERROR,   "Failed to cancel. Already cancelled or checked in.");
        String redirect = isAdmin ? "/admin/reservations" : "/reservation?action=list";
        response.sendRedirect(request.getContextPath() + redirect);
    }

    /**
     * Cancel reservation via POST — responds with JSON for AJAX calls from JSP.
     */
    private void cancelReservationPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        response.setContentType("application/json;charset=UTF-8");
        PrintWriter out = response.getWriter();

        String idStr = request.getParameter("id");
        if (!ValidationUtil.isValidInteger(idStr)) {
            response.setStatus(HttpServletResponse.SC_BAD_REQUEST);
            out.print("{\"success\":false,\"message\":\"Invalid reservation ID\"}");
            return;
        }

        int reservationId = Integer.parseInt(idStr);

        // Ownership guard for guests
        HttpSession session = request.getSession(false);
        User user = (User) session.getAttribute(Constants.SESSION_USER);
        if (user.isGuest() && !ownsReservation(user.getUserId(), reservationId)) {
            response.setStatus(HttpServletResponse.SC_FORBIDDEN);
            out.print("{\"success\":false,\"message\":\"Access denied\"}");
            return;
        }

        boolean success = reservationService.cancelReservation(reservationId);

        if (success) {
            out.print("{\"success\":true,\"message\":\"Reservation cancelled successfully\"}");
        } else {
            response.setStatus(HttpServletResponse.SC_CONFLICT);
            out.print("{\"success\":false,\"message\":\"Cannot cancel this reservation. It may already be cancelled or checked in.\"}");
        }
    }

    /**
     * Helper: check if the given userId owns the given reservationId.
     */
    private boolean ownsReservation(int userId, int reservationId) {
        try {
            // Use a lightweight direct lookup — avoids the heavy findByUserId JOIN query
            java.util.Optional<Reservation> resOpt = DAOFactory.getReservationDAO().findById(reservationId);
            if (resOpt.isEmpty()) return false;
            Reservation res = resOpt.get();
            if (res.getGuestId() == null) return false;
            // Look up guest to verify userId matches
            Guest guest = DAOFactory.getGuestDAO().findById(res.getGuestId()).orElse(null);
            return guest != null && guest.getUserId() != null && guest.getUserId() == userId;
        } catch (Exception e) {
            logger.error("Error checking reservation ownership for userId={}, reservationId={}: {}", userId, reservationId, e.getMessage());
            return false;
        }
    }
    
    /**
     * Confirm reservation via POST (staff form submit)
     */
    private void confirmReservationPost(HttpServletRequest request, HttpServletResponse response, boolean isStaff)
            throws ServletException, IOException {
        String idStr = request.getParameter("reservationId");
        HttpSession session = request.getSession();
        if (!ValidationUtil.isValidInteger(idStr)) {
            session.setAttribute(Constants.ATTR_ERROR, "Invalid reservation ID");
        } else {
            boolean success = reservationService.confirmReservation(Integer.parseInt(idStr));
            if (success) session.setAttribute(Constants.ATTR_SUCCESS, "Reservation confirmed successfully!");
            else         session.setAttribute(Constants.ATTR_ERROR,   "Failed to confirm reservation.");
        }
        response.sendRedirect(request.getContextPath() + (isStaff ? "/staff/reservations" : "/reservation?action=list"));
    }

    /**
     * Check-in reservation via POST (staff form submit)
     */
    private void checkInReservationPost(HttpServletRequest request, HttpServletResponse response, boolean isStaff)
            throws ServletException, IOException {
        String idStr = request.getParameter("reservationId");
        HttpSession session = request.getSession();
        if (!ValidationUtil.isValidInteger(idStr)) {
            session.setAttribute(Constants.ATTR_ERROR, "Invalid reservation ID");
        } else {
            boolean success = reservationService.checkInReservation(Integer.parseInt(idStr));
            if (success) session.setAttribute(Constants.ATTR_SUCCESS, Constants.MSG_CHECKIN_SUCCESS);
            else         session.setAttribute(Constants.ATTR_ERROR,   "Failed to check-in. Reservation must be CONFIRMED and check-in date must be today or earlier.");
        }
        response.sendRedirect(request.getContextPath() + (isStaff ? "/staff/reservations" : "/reservation?action=list"));
    }

    /**
     * Check-out reservation via POST (staff form submit)
     */
    private void checkOutReservationPost(HttpServletRequest request, HttpServletResponse response, boolean isStaff)
            throws ServletException, IOException {
        String idStr = request.getParameter("reservationId");
        HttpSession session = request.getSession();
        if (!ValidationUtil.isValidInteger(idStr)) {
            session.setAttribute(Constants.ATTR_ERROR, "Invalid reservation ID");
        } else {
            boolean success = reservationService.checkOutReservation(Integer.parseInt(idStr));
            if (success) session.setAttribute(Constants.ATTR_SUCCESS, Constants.MSG_CHECKOUT_SUCCESS);
            else         session.setAttribute(Constants.ATTR_ERROR,   "Failed to check-out. Reservation must be in CHECKED_IN status.");
        }
        response.sendRedirect(request.getContextPath() + (isStaff ? "/staff/reservations" : "/reservation?action=list"));
    }

    /**
     * Update reservation (special requests + numberOfGuests by admin)
     */
    private void updateReservation(HttpServletRequest request, HttpServletResponse response, boolean isAdmin)
            throws ServletException, IOException {
        HttpSession session = request.getSession();
        String idStr = request.getParameter("reservationId");
        if (!ValidationUtil.isValidInteger(idStr)) {
            session.setAttribute(Constants.ATTR_ERROR, "Invalid reservation ID");
            response.sendRedirect(request.getContextPath() + (isAdmin ? "/admin/reservations" : "/reservation?action=list"));
            return;
        }
        try {
            int reservationId = Integer.parseInt(idStr);
            Optional<Reservation> opt = reservationService.getReservationById(reservationId);
            if (opt.isEmpty()) {
                session.setAttribute(Constants.ATTR_ERROR, "Reservation not found.");
                response.sendRedirect(request.getContextPath() + (isAdmin ? "/admin/reservations" : "/reservation?action=list"));
                return;
            }
            Reservation res = opt.get();
            String specialRequests = request.getParameter("specialRequests");
            String numGuestsStr    = request.getParameter("numberOfGuests");
            if (specialRequests != null) res.setSpecialRequests(specialRequests);
            if (ValidationUtil.isValidInteger(numGuestsStr)) res.setNumberOfGuests(Integer.parseInt(numGuestsStr));
            boolean success = reservationService.updateReservation(res);
            if (success) session.setAttribute(Constants.ATTR_SUCCESS, "Reservation updated successfully.");
            else         session.setAttribute(Constants.ATTR_ERROR,   "Failed to update reservation.");
        } catch (Exception e) {
            session.setAttribute(Constants.ATTR_ERROR, "Error updating reservation: " + e.getMessage());
        }
        response.sendRedirect(request.getContextPath() + (isAdmin ? "/admin/reservations" : "/reservation?action=list"));
    }
    
    /**
     * Get error message from error code
     */
    private String getErrorMessage(int errorCode) {
        switch (errorCode) {
            case -1: return "Check-in date cannot be in the past";
            case -2: return "Invalid date range";
            case -3: return "Room not found";
            default: return "Failed to create reservation";
        }
    }
}
