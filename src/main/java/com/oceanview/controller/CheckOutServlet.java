package com.oceanview.controller;

import com.oceanview.config.DatabaseConfig;
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
import java.io.PrintWriter;
import java.math.BigDecimal;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.List;

/**
 * CheckOutServlet — Staff Guest Check-Out Management
 *
 * GET  /staff/checkout                     → Main checkout page
 * GET  /staff/checkout?action=search&q=   → AJAX search (JSON)
 * GET  /staff/checkout?action=view&id=    → AJAX single reservation detail (JSON)
 * POST /staff/checkout  action=checkout   → Process check-out
 *
 * @author Ocean View Resort Development Team
 * @version 1.0.0
 */
public class CheckOutServlet extends HttpServlet {

    private static final Logger logger = LoggerFactory.getLogger(CheckOutServlet.class);

    private ReservationService reservationService;

    @Override
    public void init() throws ServletException {
        reservationService = new ReservationService();
        logger.info("CheckOutServlet initialized");
    }

    // ─────────────────────────── GET ────────────────────────────────────────

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        if (!isAuthorized(request, response)) return;

        String action = request.getParameter("action");
        if (action == null) action = "list";

        switch (action) {
            case "search":
                handleSearch(request, response);
                break;
            case "view":
                handleViewJson(request, response);
                break;
            default:
                showCheckOutPage(request, response);
        }
    }

    // ─────────────────────────── POST ───────────────────────────────────────

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        if (!isAuthorized(request, response)) return;

        String action = request.getParameter("action");
        if ("checkout".equals(action)) {
            processCheckOut(request, response);
        } else {
            response.sendError(HttpServletResponse.SC_BAD_REQUEST, "Invalid action");
        }
    }

    // ─────────────────────────── AUTH ───────────────────────────────────────

    private boolean isAuthorized(HttpServletRequest request, HttpServletResponse response)
            throws IOException {
        HttpSession session = request.getSession(false);
        if (session == null || session.getAttribute(Constants.SESSION_USER) == null) {
            response.sendRedirect(request.getContextPath() + "/login");
            return false;
        }
        User u = (User) session.getAttribute(Constants.SESSION_USER);
        if (!u.isStaff() && !u.isAdmin()) {
            try { response.sendError(HttpServletResponse.SC_FORBIDDEN); } catch (Exception ignored) {}
            return false;
        }
        return true;
    }

    // ─────────────────────────── MAIN PAGE ──────────────────────────────────

    private void showCheckOutPage(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        try {
            List<Reservation> todayCheckOuts     = findTodayCheckOutsWithDetails();
            List<Reservation> activeStays        = findActiveStaysWithDetails();
            List<Reservation> recentCheckOuts    = findRecentCheckOutsWithDetails(7);

            int todayTotal      = todayCheckOuts.size();
            int pendingToday    = (int) todayCheckOuts.stream().filter(Reservation::isCheckedIn).count();
            int completedToday  = (int) todayCheckOuts.stream()
                    .filter(r -> r.getStatus() == Reservation.ReservationStatus.CHECKED_OUT).count();
            int activeCount     = activeStays.size();

            request.setAttribute("todayCheckOuts",  todayCheckOuts);
            request.setAttribute("activeStays",     activeStays);
            request.setAttribute("recentCheckOuts", recentCheckOuts);
            request.setAttribute("todayTotal",      todayTotal);
            request.setAttribute("pendingToday",    pendingToday);
            request.setAttribute("completedToday",  completedToday);
            request.setAttribute("activeCount",     activeCount);

            transferFlash(request);
            request.getRequestDispatcher("/views/staff/checkout.jsp").forward(request, response);

        } catch (SQLException e) {
            logger.error("Error loading check-out page", e);
            request.setAttribute(Constants.ATTR_ERROR, "Error loading check-out data. Please try again.");
            request.getRequestDispatcher("/views/staff/checkout.jsp").forward(request, response);
        }
    }

    // ─────────────────────────── SEARCH ─────────────────────────────────────

    private void handleSearch(HttpServletRequest request, HttpServletResponse response)
            throws IOException {
        response.setContentType("application/json;charset=UTF-8");
        PrintWriter out = response.getWriter();
        String q = request.getParameter("q");
        if (q == null || q.trim().isEmpty()) { out.print("[]"); return; }
        q = q.trim();

        try {
            List<Reservation> results = searchReservations(q);
            StringBuilder json = new StringBuilder("[");
            for (int i = 0; i < results.size(); i++) {
                Reservation r = results.get(i);
                if (i > 0) json.append(",");
                appendReservationJson(json, r);
            }
            json.append("]");
            out.print(json.toString());
        } catch (SQLException e) {
            logger.error("Search error", e);
            response.setStatus(500);
            out.print("[]");
        }
    }

    // ─────────────────────────── VIEW JSON ──────────────────────────────────

    private void handleViewJson(HttpServletRequest request, HttpServletResponse response)
            throws IOException {
        response.setContentType("application/json;charset=UTF-8");
        PrintWriter out = response.getWriter();
        String idStr = request.getParameter("id");
        if (!ValidationUtil.isValidInteger(idStr)) {
            response.setStatus(400); out.print("{\"error\":\"Invalid ID\"}"); return;
        }
        try {
            int id = Integer.parseInt(idStr);
            Reservation r = findByIdWithDetails(id);
            if (r == null) { response.setStatus(404); out.print("{\"error\":\"Not found\"}"); return; }
            StringBuilder json = new StringBuilder("{");
            appendReservationJson(json, r);
            // remove trailing comma if present, then close
            String s = json.toString();
            if (s.endsWith(",")) s = s.substring(0, s.length() - 1);
            out.print(s + "}");
        } catch (SQLException e) {
            logger.error("View JSON error", e);
            response.setStatus(500); out.print("{\"error\":\"Server error\"}");
        }
    }

    // ─────────────────────────── PROCESS CHECKOUT ───────────────────────────

    private void processCheckOut(HttpServletRequest request, HttpServletResponse response)
            throws IOException {
        HttpSession session = request.getSession();
        String idStr = request.getParameter("reservationId");
        if (!ValidationUtil.isValidInteger(idStr)) {
            session.setAttribute(Constants.ATTR_ERROR, "Invalid reservation ID.");
            response.sendRedirect(request.getContextPath() + "/staff/checkout");
            return;
        }
        int reservationId = Integer.parseInt(idStr);
        boolean success = reservationService.checkOutReservation(reservationId);
        if (success) {
            logger.info("Staff checked-out reservation ID={}", reservationId);
            session.setAttribute(Constants.ATTR_SUCCESS,
                "✓ Guest successfully checked out! Room is now marked as Available.");
        } else {
            session.setAttribute(Constants.ATTR_ERROR,
                "Check-out failed. The reservation must be in CHECKED_IN status.");
        }
        response.sendRedirect(request.getContextPath() + "/staff/checkout");
    }

    // ─────────────────────────── DB HELPERS ─────────────────────────────────

    /** Today's check-outs: CHECKED_IN with check_out_date = today, plus already CHECKED_OUT today */
    private List<Reservation> findTodayCheckOutsWithDetails() throws SQLException {
        String sql =
            "SELECT r.*, u.full_name AS guest_name," +
            " rm.room_number, rm.room_type, rm.floor, rm.capacity, rm.price_per_night, rm.amenities" +
            " FROM reservations r" +
            " LEFT JOIN guests g  ON r.guest_id = g.guest_id" +
            " LEFT JOIN users  u  ON g.user_id  = u.user_id" +
            " LEFT JOIN rooms  rm ON r.room_id  = rm.room_id" +
            " WHERE (r.status = 'CHECKED_IN' AND DATE(r.check_out_date) = CURDATE())" +
            "    OR (r.status = 'CHECKED_OUT' AND DATE(r.updated_at) = CURDATE())" +
            " ORDER BY r.check_out_date";
        return execQuery(sql, null);
    }

    /** All currently checked-in guests (for active stays tab) */
    private List<Reservation> findActiveStaysWithDetails() throws SQLException {
        String sql =
            "SELECT r.*, u.full_name AS guest_name," +
            " rm.room_number, rm.room_type, rm.floor, rm.capacity, rm.price_per_night, rm.amenities" +
            " FROM reservations r" +
            " LEFT JOIN guests g  ON r.guest_id = g.guest_id" +
            " LEFT JOIN users  u  ON g.user_id  = u.user_id" +
            " LEFT JOIN rooms  rm ON r.room_id  = rm.room_id" +
            " WHERE r.status = 'CHECKED_IN'" +
            " ORDER BY r.check_out_date LIMIT 30";
        return execQuery(sql, null);
    }

    /** Recently checked-out in last N days */
    private List<Reservation> findRecentCheckOutsWithDetails(int days) throws SQLException {
        String sql =
            "SELECT r.*, u.full_name AS guest_name," +
            " rm.room_number, rm.room_type, rm.floor, rm.capacity, rm.price_per_night, rm.amenities" +
            " FROM reservations r" +
            " LEFT JOIN guests g  ON r.guest_id = g.guest_id" +
            " LEFT JOIN users  u  ON g.user_id  = u.user_id" +
            " LEFT JOIN rooms  rm ON r.room_id  = rm.room_id" +
            " WHERE r.status = 'CHECKED_OUT'" +
            "   AND r.check_out_date >= DATE_SUB(CURDATE(), INTERVAL ? DAY)" +
            " ORDER BY r.check_out_date DESC LIMIT 20";
        return execQuery(sql, days);
    }

    /** Search by booking number, guest name, or room number — CHECKED_IN only */
    private List<Reservation> searchReservations(String q) throws SQLException {
        String like = "%" + q + "%";
        String sql =
            "SELECT r.*, u.full_name AS guest_name," +
            " rm.room_number, rm.room_type, rm.floor, rm.capacity, rm.price_per_night, rm.amenities" +
            " FROM reservations r" +
            " LEFT JOIN guests g  ON r.guest_id = g.guest_id" +
            " LEFT JOIN users  u  ON g.user_id  = u.user_id" +
            " LEFT JOIN rooms  rm ON r.room_id  = rm.room_id" +
            " WHERE r.status IN ('CHECKED_IN','CHECKED_OUT')" +
            "   AND (r.reservation_number LIKE ? OR u.full_name LIKE ? OR rm.room_number LIKE ?)" +
            " ORDER BY r.check_out_date LIMIT 20";
        Connection conn = null; PreparedStatement stmt = null; ResultSet rs = null;
        List<Reservation> list = new ArrayList<>();
        try {
            conn = DatabaseConfig.getInstance().getConnection();
            stmt = conn.prepareStatement(sql);
            stmt.setString(1, like); stmt.setString(2, like); stmt.setString(3, like);
            rs = stmt.executeQuery();
            while (rs.next()) list.add(mapRow(rs));
        } finally { closeQ(rs, stmt, conn); }
        return list;
    }

    /** Single reservation by ID with guest+room details */
    private Reservation findByIdWithDetails(int id) throws SQLException {
        String sql =
            "SELECT r.*, u.full_name AS guest_name," +
            " rm.room_number, rm.room_type, rm.floor, rm.capacity, rm.price_per_night, rm.amenities" +
            " FROM reservations r" +
            " LEFT JOIN guests g  ON r.guest_id = g.guest_id" +
            " LEFT JOIN users  u  ON g.user_id  = u.user_id" +
            " LEFT JOIN rooms  rm ON r.room_id  = rm.room_id" +
            " WHERE r.reservation_id = ?";
        Connection conn = null; PreparedStatement stmt = null; ResultSet rs = null;
        try {
            conn = DatabaseConfig.getInstance().getConnection();
            stmt = conn.prepareStatement(sql);
            stmt.setInt(1, id);
            rs = stmt.executeQuery();
            return rs.next() ? mapRow(rs) : null;
        } finally { closeQ(rs, stmt, conn); }
    }

    private List<Reservation> execQuery(String sql, Integer param) throws SQLException {
        Connection conn = null; PreparedStatement stmt = null; ResultSet rs = null;
        List<Reservation> list = new ArrayList<>();
        try {
            conn = DatabaseConfig.getInstance().getConnection();
            stmt = conn.prepareStatement(sql);
            if (param != null) stmt.setInt(1, param);
            rs = stmt.executeQuery();
            while (rs.next()) list.add(mapRow(rs));
        } finally { closeQ(rs, stmt, conn); }
        return list;
    }

    // ─────────────────────────── ROW MAPPER ─────────────────────────────────

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

        // Guest name → split into first/last
        String guestName = rs.getString("guest_name");
        if (guestName != null) {
            com.oceanview.model.Guest g = new com.oceanview.model.Guest();
            g.setGuestId(r.getGuestId());
            String trimmed = guestName.trim();
            int sp = trimmed.indexOf(' ');
            g.setFirstName(sp > 0 ? trimmed.substring(0, sp) : trimmed);
            g.setLastName(sp > 0 ? trimmed.substring(sp + 1) : "");
            r.setGuest(g);
        }

        // Room
        String roomNumber = rs.getString("room_number");
        if (roomNumber != null) {
            Room room = new Room();
            room.setRoomId(r.getRoomId());
            room.setRoomNumber(roomNumber);
            room.setFloor(rs.getInt("floor"));
            room.setCapacity(rs.getInt("capacity"));
            BigDecimal price = rs.getBigDecimal("price_per_night");
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

    // ─────────────────────────── JSON BUILDER ───────────────────────────────

    private void appendReservationJson(StringBuilder sb, Reservation r) {
        String gName = r.getGuest() != null
            ? (r.getGuest().getFirstName() + " " + r.getGuest().getLastName()).trim()
            : "Guest #" + r.getGuestId();
        String rNum  = r.getRoom() != null ? r.getRoom().getRoomNumber() : "";
        String rType = r.getRoom() != null && r.getRoom().getRoomType() != null
            ? r.getRoom().getRoomType().name() : "";
        int floor    = r.getRoom() != null ? r.getRoom().getFloor() : 0;

        sb.append("\"id\":").append(r.getReservationId()).append(",");
        sb.append("\"reservationNumber\":\"").append(esc(r.getReservationNumber())).append("\",");
        sb.append("\"guestName\":\"").append(esc(gName)).append("\",");
        sb.append("\"roomNumber\":\"").append(esc(rNum)).append("\",");
        sb.append("\"roomType\":\"").append(esc(rType)).append("\",");
        sb.append("\"floor\":").append(floor).append(",");
        sb.append("\"checkInDate\":\"").append(r.getCheckInDate() != null ? r.getCheckInDate().toString() : "").append("\",");
        sb.append("\"checkOutDate\":\"").append(r.getCheckOutDate() != null ? r.getCheckOutDate().toString() : "").append("\",");
        sb.append("\"nights\":").append(r.getNumberOfNights() != null ? r.getNumberOfNights() : 0).append(",");
        sb.append("\"guests\":").append(r.getNumberOfGuests() != null ? r.getNumberOfGuests() : 1).append(",");
        sb.append("\"totalAmount\":").append(r.getTotalAmount() != null ? r.getTotalAmount() : BigDecimal.ZERO).append(",");
        sb.append("\"discountAmount\":").append(r.getDiscountAmount() != null ? r.getDiscountAmount() : BigDecimal.ZERO).append(",");
        sb.append("\"taxAmount\":").append(r.getTaxAmount() != null ? r.getTaxAmount() : BigDecimal.ZERO).append(",");
        sb.append("\"finalAmount\":").append(r.getFinalAmount() != null ? r.getFinalAmount() : BigDecimal.ZERO).append(",");
        sb.append("\"status\":\"").append(esc(r.getStatus().name())).append("\",");
        sb.append("\"specialRequests\":\"").append(esc(r.getSpecialRequests())).append("\",");
        sb.append("\"canCheckOut\":").append(r.canCheckOut());
    }

    // ─────────────────────────── UTILS ──────────────────────────────────────

    private void transferFlash(HttpServletRequest request) {
        HttpSession s = request.getSession(false);
        if (s == null) return;
        String ok  = (String) s.getAttribute(Constants.ATTR_SUCCESS);
        String err = (String) s.getAttribute(Constants.ATTR_ERROR);
        if (ok  != null) { request.setAttribute(Constants.ATTR_SUCCESS, ok);  s.removeAttribute(Constants.ATTR_SUCCESS); }
        if (err != null) { request.setAttribute(Constants.ATTR_ERROR,   err); s.removeAttribute(Constants.ATTR_ERROR); }
    }

    private String esc(String s) {
        if (s == null) return "";
        return s.replace("\\", "\\\\").replace("\"", "\\\"")
                .replace("\n", "\\n").replace("\r", "\\r").replace("\t", "\\t");
    }

    private void closeQ(ResultSet rs, PreparedStatement stmt, Connection conn) {
        try { if (rs   != null) rs.close();   } catch (Exception ignored) {}
        try { if (stmt != null) stmt.close(); } catch (Exception ignored) {}
        try { if (conn != null) conn.close(); } catch (Exception ignored) {}
    }
}
