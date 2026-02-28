package com.oceanview.controller;

import com.oceanview.dao.ReservationDAO;
import com.oceanview.dao.RoomDAO;
import com.oceanview.model.Reservation;
import com.oceanview.model.Room;
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
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;

/**
 * CheckInServlet — Staff Guest Check-In Management
 *
 * Handles:
 *   GET  /staff/checkin              → Show today's check-ins list
 *   GET  /staff/checkin?action=search&q=... → Search reservations
 *   GET  /staff/checkin?action=view&id=...  → View single reservation detail (AJAX JSON)
 *   POST /staff/checkin              action=checkin   → Process check-in
 *   POST /staff/checkin              action=confirm   → Confirm a pending reservation
 *
 * @author Ocean View Resort Development Team
 * @version 1.0.0
 */
public class CheckInServlet extends HttpServlet {

    private static final Logger logger = LoggerFactory.getLogger(CheckInServlet.class);

    private ReservationService reservationService;
    private ReservationDAO     reservationDAO;
    private RoomDAO            roomDAO;

    @Override
    public void init() throws ServletException {
        reservationService = new ReservationService();
        reservationDAO     = new ReservationDAO();
        roomDAO            = new RoomDAO();
        logger.info("CheckInServlet initialized");
    }

    // ─────────────────────────── GET ────────────────────────────────────────

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        HttpSession session = request.getSession(false);
        if (session == null || session.getAttribute(Constants.SESSION_USER) == null) {
            response.sendRedirect(request.getContextPath() + "/login");
            return;
        }

        User currentUser = (User) session.getAttribute(Constants.SESSION_USER);
        if (!currentUser.isStaff() && !currentUser.isAdmin()) {
            response.sendError(HttpServletResponse.SC_FORBIDDEN, "Access denied");
            return;
        }

        String action = request.getParameter("action");
        if (action == null) action = "list";

        switch (action) {
            case "search":
                searchReservations(request, response);
                break;
            case "view":
                viewReservationJson(request, response);
                break;
            case "list":
            default:
                showCheckInPage(request, response);
        }
    }

    // ─────────────────────────── POST ───────────────────────────────────────

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        HttpSession session = request.getSession(false);
        if (session == null || session.getAttribute(Constants.SESSION_USER) == null) {
            response.sendRedirect(request.getContextPath() + "/login");
            return;
        }

        User currentUser = (User) session.getAttribute(Constants.SESSION_USER);
        if (!currentUser.isStaff() && !currentUser.isAdmin()) {
            response.sendError(HttpServletResponse.SC_FORBIDDEN, "Access denied");
            return;
        }

        String action = request.getParameter("action");
        if (action == null) action = "";

        switch (action) {
            case "checkin":
                processCheckIn(request, response);
                break;
            case "confirm":
                processConfirm(request, response);
                break;
            default:
                response.sendError(HttpServletResponse.SC_BAD_REQUEST, "Invalid action");
        }
    }

    // ─────────────────────────── HANDLERS ───────────────────────────────────

    /**
     * Load the main check-in page with today's arrivals and statistics.
     */
    private void showCheckInPage(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        try {
            // Today's expected check-ins (CONFIRMED, check_in_date = today)
            List<Reservation> todayCheckIns = findTodayCheckInsWithDetails();

            // All upcoming confirmed reservations (next 7 days)
            List<Reservation> upcomingCheckIns = findUpcomingCheckInsWithDetails(7);

            // Currently checked-in guests
            List<Reservation> activeStays = findActiveStaysWithDetails();

            // Stats
            int todayTotal    = todayCheckIns.size();
            int processedToday = (int) todayCheckIns.stream()
                    .filter(Reservation::isCheckedIn).count();
            int pendingToday  = (int) todayCheckIns.stream()
                    .filter(r -> !r.isCheckedIn()).count();
            int activeCount   = activeStays.size();

            request.setAttribute("todayCheckIns",    todayCheckIns);
            request.setAttribute("upcomingCheckIns", upcomingCheckIns);
            request.setAttribute("activeStays",      activeStays);
            request.setAttribute("todayTotal",       todayTotal);
            request.setAttribute("processedToday",   processedToday);
            request.setAttribute("pendingToday",     pendingToday);
            request.setAttribute("activeCount",      activeCount);

            // Flash messages
            transferFlashMessages(request);

            request.getRequestDispatcher("/views/staff/checkin.jsp")
                   .forward(request, response);

        } catch (SQLException e) {
            logger.error("Error loading check-in page", e);
            request.setAttribute(Constants.ATTR_ERROR,
                "Error loading check-in data. Please try again.");
            request.getRequestDispatcher("/views/staff/checkin.jsp")
                   .forward(request, response);
        }
    }

    /**
     * Search reservations by booking ID, guest name, or phone number.
     * Returns JSON array for AJAX.
     */
    private void searchReservations(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        String query = request.getParameter("q");
        if (query == null) query = "";
        query = query.trim();

        response.setContentType("application/json;charset=UTF-8");
        java.io.PrintWriter out = response.getWriter();

        if (query.isEmpty()) {
            out.print("[]");
            return;
        }

        try {
            List<Reservation> results = searchReservationsDB(query);
            StringBuilder json = new StringBuilder("[");
            for (int i = 0; i < results.size(); i++) {
                Reservation r = results.get(i);
                if (i > 0) json.append(",");
                json.append("{");
                json.append("\"id\":").append(r.getReservationId()).append(",");
                json.append("\"reservationNumber\":\"").append(escJson(r.getReservationNumber())).append("\",");
                String gn1 = r.getGuest() != null ? (r.getGuest().getFirstName() + " " + r.getGuest().getLastName()).trim() : "Guest #" + r.getGuestId();
                json.append("\"guestName\":\"").append(escJson(gn1)).append("\",");
                json.append("\"roomNumber\":\"").append(escJson(r.getRoom() != null ? r.getRoom().getRoomNumber() : "")).append("\",");
                json.append("\"roomType\":\"").append(escJson(r.getRoom() != null && r.getRoom().getRoomType() != null ? r.getRoom().getRoomType().name() : "")).append("\",");
                json.append("\"checkInDate\":\"").append(r.getCheckInDate() != null ? r.getCheckInDate().toString() : "").append("\",");
                json.append("\"checkOutDate\":\"").append(r.getCheckOutDate() != null ? r.getCheckOutDate().toString() : "").append("\",");
                json.append("\"nights\":").append(r.getNumberOfNights() != null ? r.getNumberOfNights() : 0).append(",");
                json.append("\"guests\":").append(r.getNumberOfGuests() != null ? r.getNumberOfGuests() : 1).append(",");
                json.append("\"finalAmount\":").append(r.getFinalAmount() != null ? r.getFinalAmount() : 0).append(",");
                json.append("\"status\":\"").append(escJson(r.getStatus().name())).append("\",");
                json.append("\"specialRequests\":\"").append(escJson(r.getSpecialRequests())).append("\",");
                json.append("\"canCheckIn\":").append(r.canCheckIn()).append(",");
                json.append("\"canConfirm\":").append(r.isPending());
                json.append("}");
            }
            json.append("]");
            out.print(json.toString());

        } catch (SQLException e) {
            logger.error("Error searching reservations", e);
            response.setStatus(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
            out.print("[]");
        }
    }

    /**
     * Return a single reservation as JSON for the detail modal.
     */
    private void viewReservationJson(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        response.setContentType("application/json;charset=UTF-8");
        java.io.PrintWriter out = response.getWriter();

        String idStr = request.getParameter("id");
        if (!ValidationUtil.isValidInteger(idStr)) {
            response.setStatus(HttpServletResponse.SC_BAD_REQUEST);
            out.print("{\"error\":\"Invalid ID\"}");
            return;
        }

        try {
            int id = Integer.parseInt(idStr);
            Reservation r = findReservationWithDetails(id);
            if (r == null) {
                response.setStatus(HttpServletResponse.SC_NOT_FOUND);
                out.print("{\"error\":\"Not found\"}");
                return;
            }

            out.print("{");
            out.print("\"id\":" + r.getReservationId() + ",");
            out.print("\"reservationNumber\":\"" + escJson(r.getReservationNumber()) + "\",");
            String gn2 = r.getGuest() != null ? (r.getGuest().getFirstName() + " " + r.getGuest().getLastName()).trim() : "Guest #" + r.getGuestId();
            out.print("\"guestName\":\"" + escJson(gn2) + "\",");
            out.print("\"roomNumber\":\"" + escJson(r.getRoom() != null ? r.getRoom().getRoomNumber() : "") + "\",");
            out.print("\"roomType\":\"" + escJson(r.getRoom() != null && r.getRoom().getRoomType() != null ? r.getRoom().getRoomType().name() : "") + "\",");
            out.print("\"floor\":" + (r.getRoom() != null ? r.getRoom().getFloor() : 0) + ",");
            out.print("\"checkInDate\":\"" + (r.getCheckInDate() != null ? r.getCheckInDate().toString() : "") + "\",");
            out.print("\"checkOutDate\":\"" + (r.getCheckOutDate() != null ? r.getCheckOutDate().toString() : "") + "\",");
            out.print("\"nights\":" + (r.getNumberOfNights() != null ? r.getNumberOfNights() : 0) + ",");
            out.print("\"guests\":" + (r.getNumberOfGuests() != null ? r.getNumberOfGuests() : 1) + ",");
            out.print("\"totalAmount\":" + (r.getTotalAmount() != null ? r.getTotalAmount() : 0) + ",");
            out.print("\"discountAmount\":" + (r.getDiscountAmount() != null ? r.getDiscountAmount() : 0) + ",");
            out.print("\"taxAmount\":" + (r.getTaxAmount() != null ? r.getTaxAmount() : 0) + ",");
            out.print("\"finalAmount\":" + (r.getFinalAmount() != null ? r.getFinalAmount() : 0) + ",");
            out.print("\"status\":\"" + escJson(r.getStatus().name()) + "\",");
            out.print("\"specialRequests\":\"" + escJson(r.getSpecialRequests()) + "\",");
            out.print("\"canCheckIn\":" + r.canCheckIn() + ",");
            out.print("\"canConfirm\":" + r.isPending());
            out.print("}");

        } catch (SQLException e) {
            logger.error("Error fetching reservation detail", e);
            response.setStatus(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
            out.print("{\"error\":\"Server error\"}");
        }
    }

    /**
     * Process guest check-in (POST action=checkin).
     */
    private void processCheckIn(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        HttpSession session = request.getSession();
        String idStr = request.getParameter("reservationId");

        if (!ValidationUtil.isValidInteger(idStr)) {
            session.setAttribute(Constants.ATTR_ERROR, "Invalid reservation ID.");
            response.sendRedirect(request.getContextPath() + "/staff/checkin");
            return;
        }

        int reservationId = Integer.parseInt(idStr);
        boolean success   = reservationService.checkInReservation(reservationId);

        if (success) {
            logger.info("Staff checked-in reservation ID={}", reservationId);
            session.setAttribute(Constants.ATTR_SUCCESS,
                "✓ Guest successfully checked in! Room is now marked as Occupied.");
        } else {
            session.setAttribute(Constants.ATTR_ERROR,
                "Check-in failed. The reservation must be CONFIRMED and check-in date must be today or earlier.");
        }

        response.sendRedirect(request.getContextPath() + "/staff/checkin");
    }

    /**
     * Process confirm a pending reservation (POST action=confirm).
     */
    private void processConfirm(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        HttpSession session = request.getSession();
        String idStr = request.getParameter("reservationId");

        if (!ValidationUtil.isValidInteger(idStr)) {
            session.setAttribute(Constants.ATTR_ERROR, "Invalid reservation ID.");
            response.sendRedirect(request.getContextPath() + "/staff/checkin");
            return;
        }

        int reservationId = Integer.parseInt(idStr);
        boolean success   = reservationService.confirmReservation(reservationId);

        if (success) {
            logger.info("Staff confirmed reservation ID={}", reservationId);
            session.setAttribute(Constants.ATTR_SUCCESS,
                "✓ Reservation confirmed successfully! Guest can now be checked in.");
        } else {
            session.setAttribute(Constants.ATTR_ERROR,
                "Confirmation failed. The reservation must be in PENDING status.");
        }

        response.sendRedirect(request.getContextPath() + "/staff/checkin");
    }

    // ─────────────────────────── DB HELPERS ─────────────────────────────────

    /**
     * Today's check-ins: CONFIRMED reservations with check_in_date = today,
     * joined with guest name and room number.
     */
    private List<Reservation> findTodayCheckInsWithDetails() throws SQLException {
        String sql =
            "SELECT r.*, u.full_name AS guest_name, " +
            "       rm.room_number, rm.room_type, rm.floor, rm.capacity, rm.price_per_night, rm.amenities " +
            "FROM reservations r " +
            "LEFT JOIN guests g  ON r.guest_id = g.guest_id " +
            "LEFT JOIN users  u  ON g.user_id  = u.user_id " +
            "LEFT JOIN rooms  rm ON r.room_id  = rm.room_id " +
            "WHERE r.status = 'CONFIRMED' AND DATE(r.check_in_date) = CURDATE() " +
            "ORDER BY r.check_in_date";
        return executeDetailQuery(sql, null);
    }

    /**
     * Upcoming confirmed check-ins within the next N days (excluding today).
     */
    private List<Reservation> findUpcomingCheckInsWithDetails(int days) throws SQLException {
        String sql =
            "SELECT r.*, u.full_name AS guest_name, " +
            "       rm.room_number, rm.room_type, rm.floor, rm.capacity, rm.price_per_night, rm.amenities " +
            "FROM reservations r " +
            "LEFT JOIN guests g  ON r.guest_id = g.guest_id " +
            "LEFT JOIN users  u  ON g.user_id  = u.user_id " +
            "LEFT JOIN rooms  rm ON r.room_id  = rm.room_id " +
            "WHERE r.status = 'CONFIRMED' " +
            "  AND r.check_in_date > CURDATE() " +
            "  AND r.check_in_date <= DATE_ADD(CURDATE(), INTERVAL ? DAY) " +
            "ORDER BY r.check_in_date LIMIT 20";
        return executeDetailQuery(sql, days);
    }

    /**
     * Active stays: CHECKED_IN reservations.
     */
    private List<Reservation> findActiveStaysWithDetails() throws SQLException {
        String sql =
            "SELECT r.*, u.full_name AS guest_name, " +
            "       rm.room_number, rm.room_type, rm.floor, rm.capacity, rm.price_per_night, rm.amenities " +
            "FROM reservations r " +
            "LEFT JOIN guests g  ON r.guest_id = g.guest_id " +
            "LEFT JOIN users  u  ON g.user_id  = u.user_id " +
            "LEFT JOIN rooms  rm ON r.room_id  = rm.room_id " +
            "WHERE r.status = 'CHECKED_IN' " +
            "ORDER BY r.check_in_date DESC LIMIT 20";
        return executeDetailQuery(sql, null);
    }

    /**
     * Search by booking number, guest name, or room number.
     */
    private List<Reservation> searchReservationsDB(String query) throws SQLException {
        String like = "%" + query + "%";
        String sql =
            "SELECT r.*, u.full_name AS guest_name, " +
            "       rm.room_number, rm.room_type, rm.floor, rm.capacity, rm.price_per_night, rm.amenities " +
            "FROM reservations r " +
            "LEFT JOIN guests g  ON r.guest_id = g.guest_id " +
            "LEFT JOIN users  u  ON g.user_id  = u.user_id " +
            "LEFT JOIN rooms  rm ON r.room_id  = rm.room_id " +
            "WHERE r.status IN ('PENDING','CONFIRMED','CHECKED_IN') " +
            "  AND (r.reservation_number LIKE ? " +
            "       OR u.full_name LIKE ? " +
            "       OR rm.room_number LIKE ?) " +
            "ORDER BY r.check_in_date LIMIT 20";

        com.oceanview.config.DatabaseConfig dbConfig = com.oceanview.config.DatabaseConfig.getInstance();
        Connection conn = null;
        PreparedStatement stmt = null;
        ResultSet rs = null;
        List<Reservation> list = new ArrayList<>();
        try {
            conn = dbConfig.getConnection();
            stmt = conn.prepareStatement(sql);
            stmt.setString(1, like);
            stmt.setString(2, like);
            stmt.setString(3, like);
            rs = stmt.executeQuery();
            while (rs.next()) {
                list.add(mapRow(rs));
            }
        } finally {
            closeQuietly(rs, stmt, conn);
        }
        return list;
    }

    /**
     * Find a single reservation with full guest + room details.
     */
    private Reservation findReservationWithDetails(int reservationId) throws SQLException {
        String sql =
            "SELECT r.*, u.full_name AS guest_name, " +
            "       rm.room_number, rm.room_type, rm.floor, rm.capacity, rm.price_per_night, rm.amenities " +
            "FROM reservations r " +
            "LEFT JOIN guests g  ON r.guest_id = g.guest_id " +
            "LEFT JOIN users  u  ON g.user_id  = u.user_id " +
            "LEFT JOIN rooms  rm ON r.room_id  = rm.room_id " +
            "WHERE r.reservation_id = ?";

        com.oceanview.config.DatabaseConfig dbConfig = com.oceanview.config.DatabaseConfig.getInstance();
        Connection conn = null;
        PreparedStatement stmt = null;
        ResultSet rs = null;
        try {
            conn = dbConfig.getConnection();
            stmt = conn.prepareStatement(sql);
            stmt.setInt(1, reservationId);
            rs = stmt.executeQuery();
            if (rs.next()) return mapRow(rs);
            return null;
        } finally {
            closeQuietly(rs, stmt, conn);
        }
    }

    /**
     * Execute a parameterized detail-query and return list of Reservations.
     * @param param optional integer parameter (null = no param)
     */
    private List<Reservation> executeDetailQuery(String sql, Integer param) throws SQLException {
        com.oceanview.config.DatabaseConfig dbConfig = com.oceanview.config.DatabaseConfig.getInstance();
        Connection conn = null;
        PreparedStatement stmt = null;
        ResultSet rs = null;
        List<Reservation> list = new ArrayList<>();
        try {
            conn = dbConfig.getConnection();
            stmt = conn.prepareStatement(sql);
            if (param != null) stmt.setInt(1, param);
            rs = stmt.executeQuery();
            while (rs.next()) {
                list.add(mapRow(rs));
            }
        } finally {
            closeQuietly(rs, stmt, conn);
        }
        return list;
    }

    /**
     * Map a ResultSet row to a Reservation with embedded Guest and Room.
     */
    private Reservation mapRow(ResultSet rs) throws SQLException {
        Reservation r = new Reservation();
        r.setReservationId(rs.getInt("reservation_id"));
        r.setReservationNumber(rs.getString("reservation_number"));
        r.setGuestId(rs.getInt("guest_id"));
        r.setRoomId(rs.getInt("room_id"));

        java.sql.Date ci = rs.getDate("check_in_date");
        if (ci != null) r.setCheckInDate(ci.toLocalDate());

        java.sql.Date co = rs.getDate("check_out_date");
        if (co != null) r.setCheckOutDate(co.toLocalDate());

        r.setNumberOfGuests(rs.getInt("number_of_guests"));
        r.setNumberOfNights(rs.getInt("number_of_nights"));
        r.setTotalAmount(rs.getBigDecimal("total_amount"));
        r.setDiscountAmount(rs.getBigDecimal("discount_amount"));
        r.setTaxAmount(rs.getBigDecimal("tax_amount"));
        r.setFinalAmount(rs.getBigDecimal("final_amount"));
        r.setStatus(Reservation.ReservationStatus.valueOf(rs.getString("status")));
        r.setSpecialRequests(rs.getString("special_requests"));
        r.setCreatedBy(rs.getInt("created_by"));

        java.sql.Timestamp createdAt = rs.getTimestamp("created_at");
        if (createdAt != null) r.setCreatedAt(createdAt.toLocalDateTime());

        // Guest — store full name in firstName field for display (Guest has no getFullName())
        String guestName = rs.getString("guest_name");
        if (guestName != null) {
            com.oceanview.model.Guest guest = new com.oceanview.model.Guest();
            guest.setGuestId(r.getGuestId());
            String trimmed = guestName.trim();
            int spaceIdx = trimmed.indexOf(' ');
            if (spaceIdx > 0) {
                guest.setFirstName(trimmed.substring(0, spaceIdx));
                guest.setLastName(trimmed.substring(spaceIdx + 1));
            } else {
                guest.setFirstName(trimmed);
                guest.setLastName("");
            }
            r.setGuest(guest);
        }

        // Room
        String roomNumber = rs.getString("room_number");
        if (roomNumber != null) {
            Room room = new Room();
            room.setRoomId(r.getRoomId());
            room.setRoomNumber(roomNumber);
            room.setFloor(rs.getInt("floor"));
            room.setCapacity(rs.getInt("capacity"));
            java.math.BigDecimal price = rs.getBigDecimal("price_per_night");
            if (price != null) room.setPricePerNight(price);
            room.setAmenities(rs.getString("amenities"));
            String typeStr = rs.getString("room_type");
            if (typeStr != null) {
                try { room.setRoomType(Room.RoomType.valueOf(typeStr)); } catch (Exception ignored) {}
            }
            r.setRoom(room);
        }

        return r;
    }

    // ─────────────────────────── UTILS ──────────────────────────────────────

    private void transferFlashMessages(HttpServletRequest request) {
        HttpSession session = request.getSession(false);
        if (session == null) return;
        String success = (String) session.getAttribute(Constants.ATTR_SUCCESS);
        String error   = (String) session.getAttribute(Constants.ATTR_ERROR);
        if (success != null) { request.setAttribute(Constants.ATTR_SUCCESS, success); session.removeAttribute(Constants.ATTR_SUCCESS); }
        if (error   != null) { request.setAttribute(Constants.ATTR_ERROR,   error);   session.removeAttribute(Constants.ATTR_ERROR);   }
    }

    private String escJson(String s) {
        if (s == null) return "";
        return s.replace("\\", "\\\\")
                .replace("\"", "\\\"")
                .replace("\n", "\\n")
                .replace("\r", "\\r")
                .replace("\t", "\\t");
    }

    private void closeQuietly(ResultSet rs, PreparedStatement stmt, Connection conn) {
        try { if (rs   != null) rs.close();   } catch (Exception ignored) {}
        try { if (stmt != null) stmt.close(); } catch (Exception ignored) {}
        try { if (conn != null) conn.close(); } catch (Exception ignored) {}
    }
}
