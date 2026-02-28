package com.oceanview.controller;

import com.oceanview.dao.OfferDAO;
import com.oceanview.model.Offer;
import com.oceanview.model.User;
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
import java.math.BigDecimal;
import java.math.RoundingMode;
import java.sql.SQLException;
import java.time.LocalDate;
import java.time.temporal.ChronoUnit;
import java.util.List;
import java.util.Optional;

/**
 * Offer Servlet
 * Handles special offers and promotions management
 * URL Mapping: /offer (configured in web.xml)
 * 
 * @author Ocean View Resort Development Team
 * @version 1.0.0
 */
public class OfferServlet extends HttpServlet {
    
    private static final Logger logger = LoggerFactory.getLogger(OfferServlet.class);
    private OfferDAO offerDAO;
    
    @Override
    public void init() throws ServletException {
        offerDAO = new OfferDAO();
        logger.info("OfferServlet initialized");
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
        
        String action = request.getParameter("action");
        String reqURI = request.getRequestURI();
        boolean isAdmin = reqURI.contains("/admin/");

        try {
            if (action == null) action = "list";

            switch (action) {
                case "list":
                    listOffers(request, response);
                    break;
                case "view":
                    viewOffer(request, response);
                    break;
                case "edit":
                    showEditForm(request, response);
                    break;
                case "delete":
                    deleteOffer(request, response, isAdmin);
                    break;
                case "active":
                    listActiveOffers(request, response);
                    break;
                case "validate":
                    validatePromoCode(request, response);
                    break;
                default:
                    listOffers(request, response);
            }
        } catch (Exception e) {
            logger.error("Error in OfferServlet doGet", e);
            request.setAttribute(Constants.ATTR_ERROR, "An error occurred: " + e.getMessage());
            request.getRequestDispatcher("/views/error.jsp").forward(request, response);
        }
    }
    
    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        
        HttpSession session = request.getSession();
        User user = (User) session.getAttribute(Constants.SESSION_USER);
        
        if (user == null || !user.isAdmin()) {
            response.sendError(HttpServletResponse.SC_FORBIDDEN);
            return;
        }
        
        String action = request.getParameter("action");
        
        String postURI = request.getRequestURI();
        boolean isAdminPost = postURI.contains("/admin/");

        try {
            if ("create".equals(action)) {
                createOffer(request, response, isAdminPost);
            } else if ("update".equals(action)) {
                updateOffer(request, response, isAdminPost);
            } else if ("delete".equals(action)) {
                deleteOffer(request, response, isAdminPost);
            } else if ("toggleStatus".equals(action)) {
                toggleStatus(request, response, isAdminPost);
            } else {
                response.sendError(HttpServletResponse.SC_BAD_REQUEST, "Invalid action");
            }
        } catch (Exception e) {
            logger.error("Error in OfferServlet doPost", e);
            request.getSession().setAttribute(Constants.ATTR_ERROR, "An error occurred: " + e.getMessage());
            response.sendRedirect(request.getContextPath() + (isAdminPost ? "/admin/offers" : "/offer?action=list"));
        }
    }
    
    /**
     * List all offers (Admin view)
     */
    private void listOffers(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        
        try {
            List<Offer> offers = offerDAO.findAll();
            
            // Calculate statistics
            long activeCount = offers.stream()
                .filter(o -> o.getOfferStatus() == Offer.OfferStatus.ACTIVE)
                .count();
            long scheduledCount = offers.stream()
                .filter(o -> o.getOfferStatus() == Offer.OfferStatus.SCHEDULED)
                .count();
            long expiredCount = offers.stream()
                .filter(o -> o.getOfferStatus() == Offer.OfferStatus.EXPIRED)
                .count();
            int totalRedemptions = offers.stream()
                .mapToInt(Offer::getUsedCount)
                .sum();
            
            request.setAttribute("offers", offers);
            request.setAttribute("activeOffers", activeCount);
            request.setAttribute("scheduledOffers", scheduledCount);
            request.setAttribute("expiredOffers", expiredCount);
            request.setAttribute("totalRedemptions", totalRedemptions);
            
            request.getRequestDispatcher("/views/admin/offers.jsp").forward(request, response);
            
        } catch (SQLException e) {
            logger.error("Error listing offers", e);
            request.setAttribute(Constants.ATTR_ERROR, "Error loading offers");
            request.getRequestDispatcher("/views/admin/offers.jsp").forward(request, response);
        }
    }
    
    /**
     * List active offers (Guest view)
     */
    private void listActiveOffers(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        
        try {
            List<Offer> offers = offerDAO.findActiveOffers();
            request.setAttribute("offers", offers);
            request.getRequestDispatcher("/views/guest/offers.jsp").forward(request, response);
            
        } catch (SQLException e) {
            logger.error("Error listing active offers", e);
            request.setAttribute(Constants.ATTR_ERROR, "Error loading offers");
            request.getRequestDispatcher("/views/guest/offers.jsp").forward(request, response);
        }
    }
    
    /**
     * View offer details
     */
    private void viewOffer(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        
        String idStr = request.getParameter("id");
        
        if (!ValidationUtil.isValidInteger(idStr)) {
            response.sendError(HttpServletResponse.SC_BAD_REQUEST, "Invalid offer ID");
            return;
        }
        
        try {
            int offerId = Integer.parseInt(idStr);
            Optional<Offer> offerOpt = offerDAO.findById(offerId);
            
            if (offerOpt.isPresent()) {
                request.setAttribute("offer", offerOpt.get());
                request.getRequestDispatcher("/views/offer-details.jsp").forward(request, response);
            } else {
                request.setAttribute(Constants.ATTR_ERROR, "Offer not found");
                response.sendRedirect(request.getContextPath() + "/offer?action=list");
            }
            
        } catch (SQLException e) {
            logger.error("Error viewing offer", e);
            request.setAttribute(Constants.ATTR_ERROR, "Error loading offer");
            response.sendRedirect(request.getContextPath() + "/offer?action=list");
        }
    }
    
    /**
     * Show edit form
     */
    private void showEditForm(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        
        String idStr = request.getParameter("id");
        
        if (!ValidationUtil.isValidInteger(idStr)) {
            response.sendError(HttpServletResponse.SC_BAD_REQUEST, "Invalid offer ID");
            return;
        }
        
        try {
            int offerId = Integer.parseInt(idStr);
            Optional<Offer> offerOpt = offerDAO.findById(offerId);
            
            if (offerOpt.isPresent()) {
                request.setAttribute("offer", offerOpt.get());
                request.getRequestDispatcher("/views/admin/offer-form.jsp").forward(request, response);
            } else {
                request.setAttribute(Constants.ATTR_ERROR, "Offer not found");
                response.sendRedirect(request.getContextPath() + "/offer?action=list");
            }
            
        } catch (SQLException e) {
            logger.error("Error loading offer for edit", e);
            request.setAttribute(Constants.ATTR_ERROR, "Error loading offer");
            response.sendRedirect(request.getContextPath() + "/offer?action=list");
        }
    }
    
    /**
     * Create new offer
     */
    private void createOffer(HttpServletRequest request, HttpServletResponse response, boolean isAdmin)
            throws ServletException, IOException {
        String redirect = isAdmin ? "/admin/offers" : "/offer?action=list";
        try {
            Offer offer = new Offer();
            offer.setOfferName(request.getParameter("offerName"));
            offer.setDescription(request.getParameter("description"));
            offer.setDiscountType(Offer.DiscountType.valueOf(request.getParameter("discountType")));
            offer.setDiscountValue(new BigDecimal(request.getParameter("discountValue")));
            offer.setStartDate(LocalDate.parse(request.getParameter("startDate")));
            offer.setEndDate(LocalDate.parse(request.getParameter("endDate")));
            String minStayStr = request.getParameter("minStay");
            if (minStayStr != null && !minStayStr.isEmpty()) offer.setMinStayNights(Integer.parseInt(minStayStr));
            String maxUsesStr = request.getParameter("maxUses");
            if (maxUsesStr != null && !maxUsesStr.isEmpty()) offer.setMaxUses(Integer.parseInt(maxUsesStr));
            offer.setPromoCode(request.getParameter("promoCode"));
            offer.setOfferStatus(Offer.OfferStatus.valueOf(request.getParameter("status")));
            offer.setUsedCount(0);
            int offerId = offerDAO.create(offer);
            if (offerId > 0) { logger.info("Offer created: ID={}", offerId); request.getSession().setAttribute(Constants.ATTR_SUCCESS, "Offer created successfully!"); }
            else              { request.getSession().setAttribute(Constants.ATTR_ERROR, "Failed to create offer"); }
            response.sendRedirect(request.getContextPath() + redirect);
        } catch (Exception e) {
            logger.error("Error creating offer", e);
            request.getSession().setAttribute(Constants.ATTR_ERROR, "Error creating offer: " + e.getMessage());
            response.sendRedirect(request.getContextPath() + redirect);
        }
    }

    /**
     * Update existing offer
     */
    private void updateOffer(HttpServletRequest request, HttpServletResponse response, boolean isAdmin)
            throws ServletException, IOException {
        String redirect = isAdmin ? "/admin/offers" : "/offer?action=list";
        try {
            int offerId = Integer.parseInt(request.getParameter("id"));
            Optional<Offer> offerOpt = offerDAO.findById(offerId);
            if (!offerOpt.isPresent()) {
                request.getSession().setAttribute(Constants.ATTR_ERROR, "Offer not found");
                response.sendRedirect(request.getContextPath() + redirect); return;
            }
            Offer offer = offerOpt.get();
            offer.setOfferName(request.getParameter("offerName"));
            offer.setDescription(request.getParameter("description"));
            offer.setDiscountType(Offer.DiscountType.valueOf(request.getParameter("discountType")));
            offer.setDiscountValue(new BigDecimal(request.getParameter("discountValue")));
            offer.setStartDate(LocalDate.parse(request.getParameter("startDate")));
            offer.setEndDate(LocalDate.parse(request.getParameter("endDate")));
            String minStayStr = request.getParameter("minStay");
            if (minStayStr != null && !minStayStr.isEmpty()) offer.setMinStayNights(Integer.parseInt(minStayStr));
            String maxUsesStr = request.getParameter("maxUses");
            if (maxUsesStr != null && !maxUsesStr.isEmpty()) offer.setMaxUses(Integer.parseInt(maxUsesStr));
            offer.setPromoCode(request.getParameter("promoCode"));
            offer.setOfferStatus(Offer.OfferStatus.valueOf(request.getParameter("status")));
            boolean success = offerDAO.update(offer);
            if (success) { logger.info("Offer updated: ID={}", offerId); request.getSession().setAttribute(Constants.ATTR_SUCCESS, "Offer updated successfully!"); }
            else          { request.getSession().setAttribute(Constants.ATTR_ERROR, "Failed to update offer"); }
            response.sendRedirect(request.getContextPath() + redirect);
        } catch (Exception e) {
            logger.error("Error updating offer", e);
            request.getSession().setAttribute(Constants.ATTR_ERROR, "Error updating offer: " + e.getMessage());
            response.sendRedirect(request.getContextPath() + redirect);
        }
    }

    /**
     * Toggle offer status (ACTIVE <-> INACTIVE)
     */
    private void toggleStatus(HttpServletRequest request, HttpServletResponse response, boolean isAdmin)
            throws ServletException, IOException {
        String redirect = isAdmin ? "/admin/offers" : "/offer?action=list";
        String idStr = request.getParameter("id");
        if (!ValidationUtil.isValidInteger(idStr)) { response.sendError(HttpServletResponse.SC_BAD_REQUEST, "Invalid offer ID"); return; }
        try {
            int offerId = Integer.parseInt(idStr);
            Optional<Offer> offerOpt = offerDAO.findById(offerId);
            if (offerOpt.isPresent()) {
                Offer offer = offerOpt.get();
                offer.setOfferStatus(offer.getOfferStatus() == Offer.OfferStatus.ACTIVE ? Offer.OfferStatus.INACTIVE : Offer.OfferStatus.ACTIVE);
                boolean success = offerDAO.update(offer);
                if (success) { logger.info("Offer toggled: ID={}", offerId); request.getSession().setAttribute(Constants.ATTR_SUCCESS, "Offer status updated!"); }
                else          { request.getSession().setAttribute(Constants.ATTR_ERROR, "Failed to update status"); }
            }
            response.sendRedirect(request.getContextPath() + redirect);
        } catch (SQLException e) {
            logger.error("Error toggling offer status", e);
            request.getSession().setAttribute(Constants.ATTR_ERROR, "Error updating status");
            response.sendRedirect(request.getContextPath() + redirect);
        }
    }
    
    /**
     * Validate promo code — AJAX endpoint (GET /offer?action=validate&code=...&checkIn=...&checkOut=...)
     *
     * Response JSON:
     *   { "valid": true,  "discountAmount": 45.00, "discountType": "PERCENTAGE",
     *     "discountValue": 10, "offerTitle": "Summer Deal", "message": "10% off – saves $45.00" }
     *   { "valid": false, "message": "Promo code is invalid or has expired." }
     */
    private void validatePromoCode(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");

        // Disable caching so browsers always get a fresh answer
        response.setHeader("Cache-Control", "no-cache, no-store, must-revalidate");
        response.setHeader("Pragma", "no-cache");

        PrintWriter out = response.getWriter();

        String code = request.getParameter("code");
        if (code == null || code.trim().isEmpty()) {
            out.print("{\"valid\":false,\"message\":\"Please enter a promo code.\"}");
            return;
        }
        code = code.trim().toUpperCase();

        // Parse optional stay dates to compute an actual discount amount
        LocalDate checkIn  = null;
        LocalDate checkOut = null;
        try {
            String ciParam = request.getParameter("checkIn");
            String coParam = request.getParameter("checkOut");
            if (ciParam != null && !ciParam.isBlank()) checkIn  = LocalDate.parse(ciParam.trim());
            if (coParam != null && !coParam.isBlank()) checkOut = LocalDate.parse(coParam.trim());
        } catch (Exception ignored) {
            // Invalid date strings – we still validate the code, just won't compute a precise amount
        }

        try {
            Offer offer = offerDAO.findByPromoCode(code);

            if (offer == null) {
                logger.debug("Promo code not found: {}", code);
                out.print("{\"valid\":false,\"message\":\"Promo code is invalid or has expired.\"}");
                return;
            }

            // Check usage cap
            if (offer.getMaxUses() != null && offer.getUsedCount() >= offer.getMaxUses()) {
                logger.debug("Promo code usage limit reached: {}", code);
                out.print("{\"valid\":false,\"message\":\"This promo code has reached its usage limit.\"}");
                return;
            }

            // Check minimum stay requirement
            long nights = 1;
            if (checkIn != null && checkOut != null && checkOut.isAfter(checkIn)) {
                nights = ChronoUnit.DAYS.between(checkIn, checkOut);
            }

            if (offer.getMinNights() != null && offer.getMinNights() > 1 && nights < offer.getMinNights()) {
                logger.debug("Promo code minimum nights not met: code={}, required={}, actual={}", code, offer.getMinNights(), nights);
                out.print("{\"valid\":false,\"message\":\"This promo code requires a minimum stay of "
                        + offer.getMinNights() + " night(s).\"}");
                return;
            }

            // Calculate the discount amount based on stay dates when available.
            // We use a placeholder nightly rate of 0 when no room price is known yet;
            // the actual reduction is recalculated client-side with the real base amount.
            // discountAmount here is the server-authoritative figure for FIXED discounts,
            // or a percentage value the client multiplies against the base for PERCENTAGE ones.
            BigDecimal discountAmount = BigDecimal.ZERO;

            if (offer.getDiscountType() == Offer.DiscountType.FIXED) {
                discountAmount = offer.getDiscountValue().setScale(2, RoundingMode.HALF_UP);
            } else {
                // PERCENTAGE – return the percentage value; client applies it to the computed base price.
                // Also compute an indicative dollar amount if dates are available.
                // (The booking.jsp already has PRICE_PER_NIGHT so its recalc() will be accurate.)
                discountAmount = offer.getDiscountValue().setScale(2, RoundingMode.HALF_UP);
            }

            // Human-readable description
            String discountDesc = offer.getDiscountDescription(); // e.g. "10% off" or "$50 off"
            String message = offer.getTitle() + " applied – " + discountDesc;

            logger.info("Promo code validated successfully: code={}, offer={}", code, offer.getOfferId());

            // Build JSON manually – avoids a JSON library dependency
            boolean isPct = offer.getDiscountType() == Offer.DiscountType.PERCENTAGE;
            BigDecimal discountPct  = isPct ? offer.getDiscountValue().setScale(2, RoundingMode.HALF_UP) : BigDecimal.ZERO;
            BigDecimal fixedAmt     = isPct ? BigDecimal.ZERO : offer.getDiscountValue().setScale(2, RoundingMode.HALF_UP);

            out.print("{" +
                "\"valid\":true," +
                "\"discountType\":\"" + offer.getDiscountType().name() + "\"," +
                "\"discountValue\":" + offer.getDiscountValue().setScale(2, RoundingMode.HALF_UP) + "," +
                "\"discountPercentage\":" + discountPct + "," +
                "\"discountAmount\":" + fixedAmt + "," +
                "\"offerTitle\":\"" + escapeJson(offer.getTitle()) + "\"," +
                "\"message\":\"" + escapeJson(message) + "\"" +
            "}");

        } catch (SQLException e) {
            logger.error("Database error validating promo code: {}", code, e);
            response.setStatus(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
            out.print("{\"valid\":false,\"message\":\"Unable to validate promo code. Please try again.\"}");
        }
    }

    /**
     * Minimal JSON string escaper – handles the characters that matter in offer titles/messages.
     */
    private static String escapeJson(String value) {
        if (value == null) return "";
        return value.replace("\\", "\\\\")
                    .replace("\"", "\\\"")
                    .replace("\n", "\\n")
                    .replace("\r", "\\r")
                    .replace("\t", "\\t");
    }

    /**
     * Delete offer - admin aware
     */
    private void deleteOffer(HttpServletRequest request, HttpServletResponse response, boolean isAdmin)
            throws ServletException, IOException {
        String redirect = isAdmin ? "/admin/offers" : "/offer?action=list";
        String idStr = request.getParameter("id");
        if (!ValidationUtil.isValidInteger(idStr)) { response.sendError(HttpServletResponse.SC_BAD_REQUEST, "Invalid offer ID"); return; }
        try {
            int offerId = Integer.parseInt(idStr);
            boolean success = offerDAO.delete(offerId);
            if (success) { logger.info("Offer deleted: ID={}", offerId); request.getSession().setAttribute(Constants.ATTR_SUCCESS, "Offer deleted successfully!"); }
            else          { request.getSession().setAttribute(Constants.ATTR_ERROR, "Failed to delete offer"); }
            response.sendRedirect(request.getContextPath() + redirect);
        } catch (SQLException e) {
            logger.error("Error deleting offer", e);
            request.getSession().setAttribute(Constants.ATTR_ERROR, "Error deleting offer");
            response.sendRedirect(request.getContextPath() + redirect);
        }
    }
}
