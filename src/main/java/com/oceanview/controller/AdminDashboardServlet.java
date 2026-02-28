package com.oceanview.controller;

import com.oceanview.config.DatabaseConfig;
import com.oceanview.model.Reservation;
import com.oceanview.model.Room;
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
import java.math.BigDecimal;
import java.math.RoundingMode;
import java.sql.*;
import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.Collections;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/**
 * AdminDashboardServlet — Full Admin Dashboard with real DB stats
 *
 * GET /admin/dashboard → Load all stats and forward to dashboard.jsp
 *
 * Stats loaded:
 *  - User stats     : total, active, guests, staff, new this month
 *  - Room stats     : total, available, occupied, maintenance, reserved, occupancy %
 *  - Reservation stats: total, confirmed, checkedIn, pending, cancelled, today check-ins/outs
 *  - Revenue stats  : today, this month, this year, total
 *  - Review stats   : total, pending, avg rating
 *  - Recent reservations (10)
 *  - Room occupancy by type (for chart)
 *  - Monthly revenue last 6 months (for chart)
 *
 * @author Ocean View Resort Dev Team
 * @version 2.0.0
 */
public class AdminDashboardServlet extends HttpServlet {

    private static final Logger logger = LoggerFactory.getLogger(AdminDashboardServlet.class);

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        HttpSession session = request.getSession(false);
        if (session == null || session.getAttribute(Constants.SESSION_USER) == null) {
            response.sendRedirect(request.getContextPath() + "/login");
            return;
        }
        User currentUser = (User) session.getAttribute(Constants.SESSION_USER);
        if (!currentUser.isAdmin()) {
            response.sendError(HttpServletResponse.SC_FORBIDDEN, "Admin access required");
            return;
        }

        // Transfer flash messages
        transferFlash(request);

        try {
            loadAllStats(request);
        } catch (SQLException e) {
            logger.error("Error loading admin dashboard stats", e);
            request.setAttribute(Constants.ATTR_ERROR, "Error loading dashboard data.");
        }

        request.setAttribute("currentUser", currentUser);
        request.getRequestDispatcher("/views/admin/dashboard.jsp").forward(request, response);
    }

    // ─────────────────────────── LOAD ALL STATS ─────────────────────────────

    private void loadAllStats(HttpServletRequest request) throws SQLException {
        Connection conn = null;
        try {
            conn = DatabaseConfig.getInstance().getConnection();

            // User stats
            loadUserStats(conn, request);

            // Room stats
            loadRoomStats(conn, request);

            // Reservation stats
            loadReservationStats(conn, request);

            // Revenue stats
            loadRevenueStats(conn, request);

            // Review stats
            loadReviewStats(conn, request);

            // Recent reservations list
            loadRecentReservations(conn, request);

            // Monthly revenue (last 6 months) for chart
            loadMonthlyRevenue(conn, request);

            // Reservation status breakdown for pie chart
            loadReservationStatusBreakdown(conn, request);

            // Room type occupancy for bar chart
            loadRoomTypeOccupancy(conn, request);

        } finally {
            if (conn != null) try { conn.close(); } catch (Exception ignored) {}
        }
    }

    // ─────────────────────────── USER STATS ─────────────────────────────────

    private void loadUserStats(Connection conn, HttpServletRequest request) throws SQLException {
        String sql =
            "SELECT " +
            "  COUNT(*) AS total, " +
            "  SUM(CASE WHEN status='ACTIVE' THEN 1 ELSE 0 END) AS active, " +
            "  SUM(CASE WHEN role='GUEST' THEN 1 ELSE 0 END) AS guests, " +
            "  SUM(CASE WHEN role='STAFF' THEN 1 ELSE 0 END) AS staff, " +
            "  SUM(CASE WHEN role='ADMIN' THEN 1 ELSE 0 END) AS admins, " +
            "  SUM(CASE WHEN MONTH(created_at)=MONTH(CURDATE()) AND YEAR(created_at)=YEAR(CURDATE()) THEN 1 ELSE 0 END) AS newThisMonth " +
            "FROM users";
        try (PreparedStatement st = conn.prepareStatement(sql);
             ResultSet rs = st.executeQuery()) {
            if (rs.next()) {
                request.setAttribute("totalUsers",    rs.getInt("total"));
                request.setAttribute("activeUsers",   rs.getInt("active"));
                request.setAttribute("totalGuests",   rs.getInt("guests"));
                request.setAttribute("totalStaff",    rs.getInt("staff"));
                request.setAttribute("totalAdmins",   rs.getInt("admins"));
                request.setAttribute("newUsersMonth", rs.getInt("newThisMonth"));
            }
        }
    }

    // ─────────────────────────── ROOM STATS ─────────────────────────────────

    private void loadRoomStats(Connection conn, HttpServletRequest request) throws SQLException {
        String sql =
            "SELECT " +
            "  COUNT(*) AS total, " +
            "  SUM(CASE WHEN status='AVAILABLE'   THEN 1 ELSE 0 END) AS available, " +
            "  SUM(CASE WHEN status='OCCUPIED'    THEN 1 ELSE 0 END) AS occupied, " +
            "  SUM(CASE WHEN status='MAINTENANCE' THEN 1 ELSE 0 END) AS maintenance, " +
            "  SUM(CASE WHEN status='RESERVED'    THEN 1 ELSE 0 END) AS reserved " +
            "FROM rooms";
        try (PreparedStatement st = conn.prepareStatement(sql);
             ResultSet rs = st.executeQuery()) {
            if (rs.next()) {
                int total       = rs.getInt("total");
                int available   = rs.getInt("available");
                int occupied    = rs.getInt("occupied");
                int maintenance = rs.getInt("maintenance");
                int reserved    = rs.getInt("reserved");
                double occupancy = total > 0 ? Math.round((double)(occupied + reserved) / total * 1000.0) / 10.0 : 0.0;
                request.setAttribute("totalRooms",       total);
                request.setAttribute("availableRooms",   available);
                request.setAttribute("occupiedRooms",    occupied);
                request.setAttribute("maintenanceRooms", maintenance);
                request.setAttribute("reservedRooms",    reserved);
                request.setAttribute("occupancyRate",    occupancy);
            }
        }
    }

    // ─────────────────────────── RESERVATION STATS ──────────────────────────

    private void loadReservationStats(Connection conn, HttpServletRequest request) throws SQLException {
        String sql =
            "SELECT " +
            "  COUNT(*) AS total, " +
            "  SUM(CASE WHEN status='PENDING'     THEN 1 ELSE 0 END) AS pending, " +
            "  SUM(CASE WHEN status='CONFIRMED'   THEN 1 ELSE 0 END) AS confirmed, " +
            "  SUM(CASE WHEN status='CHECKED_IN'  THEN 1 ELSE 0 END) AS checkedIn, " +
            "  SUM(CASE WHEN status='CHECKED_OUT' THEN 1 ELSE 0 END) AS checkedOut, " +
            "  SUM(CASE WHEN status='CANCELLED'   THEN 1 ELSE 0 END) AS cancelled, " +
            "  SUM(CASE WHEN status='CONFIRMED' AND DATE(check_in_date)=CURDATE() THEN 1 ELSE 0 END) AS todayCheckIns, " +
            "  SUM(CASE WHEN status='CHECKED_IN'  AND DATE(check_out_date)=CURDATE() THEN 1 ELSE 0 END) AS todayCheckOuts, " +
            "  SUM(CASE WHEN MONTH(created_at)=MONTH(CURDATE()) AND YEAR(created_at)=YEAR(CURDATE()) THEN 1 ELSE 0 END) AS thisMonth " +
            "FROM reservations";
        try (PreparedStatement st = conn.prepareStatement(sql);
             ResultSet rs = st.executeQuery()) {
            if (rs.next()) {
                request.setAttribute("totalReservations",   rs.getInt("total"));
                request.setAttribute("pendingReservations", rs.getInt("pending"));
                request.setAttribute("confirmedReservations", rs.getInt("confirmed"));
                request.setAttribute("checkedInCount",      rs.getInt("checkedIn"));
                request.setAttribute("checkedOutCount",     rs.getInt("checkedOut"));
                request.setAttribute("cancelledReservations", rs.getInt("cancelled"));
                request.setAttribute("todayCheckIns",       rs.getInt("todayCheckIns"));
                request.setAttribute("todayCheckOuts",      rs.getInt("todayCheckOuts"));
                request.setAttribute("reservationsThisMonth", rs.getInt("thisMonth"));
            }
        }
    }

    // ─────────────────────────── REVENUE STATS ──────────────────────────────

    private void loadRevenueStats(Connection conn, HttpServletRequest request) throws SQLException {
        String sql =
            "SELECT " +
            "  COALESCE(SUM(CASE WHEN DATE(created_at)=CURDATE() THEN final_amount ELSE 0 END), 0) AS today, " +
            "  COALESCE(SUM(CASE WHEN MONTH(created_at)=MONTH(CURDATE()) AND YEAR(created_at)=YEAR(CURDATE()) THEN final_amount ELSE 0 END), 0) AS thisMonth, " +
            "  COALESCE(SUM(CASE WHEN YEAR(created_at)=YEAR(CURDATE()) THEN final_amount ELSE 0 END), 0) AS thisYear, " +
            "  COALESCE(SUM(final_amount), 0) AS total " +
            "FROM reservations WHERE status IN ('CONFIRMED','CHECKED_IN','CHECKED_OUT')";
        try (PreparedStatement st = conn.prepareStatement(sql);
             ResultSet rs = st.executeQuery()) {
            if (rs.next()) {
                request.setAttribute("revenueToday",     formatMoney(rs.getBigDecimal("today")));
                request.setAttribute("revenueThisMonth", formatMoney(rs.getBigDecimal("thisMonth")));
                request.setAttribute("revenueThisYear",  formatMoney(rs.getBigDecimal("thisYear")));
                request.setAttribute("revenueTotal",     formatMoney(rs.getBigDecimal("total")));
            }
        }
    }

    // ─────────────────────────── REVIEW STATS ───────────────────────────────

    private void loadReviewStats(Connection conn, HttpServletRequest request) throws SQLException {
        String sql =
            "SELECT COUNT(*) AS total, " +
            "  SUM(CASE WHEN status='PENDING' THEN 1 ELSE 0 END) AS pending, " +
            "  SUM(CASE WHEN status='APPROVED' THEN 1 ELSE 0 END) AS approved, " +
            "  ROUND(AVG(rating), 1) AS avgRating " +
            "FROM reviews";
        try (PreparedStatement st = conn.prepareStatement(sql);
             ResultSet rs = st.executeQuery()) {
            if (rs.next()) {
                request.setAttribute("totalReviews",    rs.getInt("total"));
                request.setAttribute("pendingReviews",  rs.getInt("pending"));
                request.setAttribute("approvedReviews", rs.getInt("approved"));
                double avg = rs.getDouble("avgRating");
                request.setAttribute("avgRating", rs.wasNull() ? "0.0" : String.valueOf(avg));
            }
        }
    }

    // ─────────────────────────── RECENT RESERVATIONS ────────────────────────

    private void loadRecentReservations(Connection conn, HttpServletRequest request) throws SQLException {
        String sql =
            "SELECT r.reservation_id, r.reservation_number, r.check_in_date, r.check_out_date, " +
            "  r.number_of_nights, r.final_amount, r.status, r.created_at, " +
            "  u.full_name AS guest_name, u.email AS guest_email, " +
            "  rm.room_number, rm.room_type " +
            "FROM reservations r " +
            "LEFT JOIN guests g  ON r.guest_id = g.guest_id " +
            "LEFT JOIN users  u  ON g.user_id  = u.user_id " +
            "LEFT JOIN rooms  rm ON r.room_id  = rm.room_id " +
            "ORDER BY r.created_at DESC LIMIT 10";

        List<Map<String, Object>> recent = new ArrayList<>();
        DateTimeFormatter fmt = DateTimeFormatter.ofPattern("dd MMM yyyy");

        try (PreparedStatement st = conn.prepareStatement(sql);
             ResultSet rs = st.executeQuery()) {
            while (rs.next()) {
                Map<String, Object> row = new LinkedHashMap<>();
                row.put("id",                rs.getInt("reservation_id"));
                row.put("reservationNumber", rs.getString("reservation_number"));
                row.put("guestName",         rs.getString("guest_name") != null ? rs.getString("guest_name") : "Unknown");
                row.put("guestEmail",        rs.getString("guest_email") != null ? rs.getString("guest_email") : "");
                row.put("roomNumber",        rs.getString("room_number") != null ? rs.getString("room_number") : "-");
                row.put("roomType",          rs.getString("room_type")   != null ? rs.getString("room_type")   : "");
                java.sql.Date ci = rs.getDate("check_in_date");
                java.sql.Date co = rs.getDate("check_out_date");
                row.put("checkInDate",  ci != null ? ci.toLocalDate().format(fmt) : "-");
                row.put("checkOutDate", co != null ? co.toLocalDate().format(fmt) : "-");
                row.put("nights",       rs.getInt("number_of_nights"));
                BigDecimal amt = rs.getBigDecimal("final_amount");
                row.put("amount",       amt != null ? String.format("Rs. %.2f", amt) : "Rs. 0.00");
                row.put("status",       rs.getString("status"));
                Timestamp created = rs.getTimestamp("created_at");
                row.put("createdAt",    created != null ? created.toLocalDateTime().format(DateTimeFormatter.ofPattern("dd MMM HH:mm")) : "");
                recent.add(row);
            }
        }
        request.setAttribute("recentReservations", recent);
    }

    // ─────────────────────────── MONTHLY REVENUE CHART ──────────────────────

    private void loadMonthlyRevenue(Connection conn, HttpServletRequest request) throws SQLException {
        String sql =
            "SELECT DATE_FORMAT(created_at, '%b %Y') AS month_label, " +
            "       DATE_FORMAT(created_at, '%Y-%m') AS month_key, " +
            "       COALESCE(SUM(final_amount), 0) AS revenue " +
            "FROM reservations " +
            "WHERE status IN ('CONFIRMED','CHECKED_IN','CHECKED_OUT') " +
            "  AND created_at >= DATE_SUB(CURDATE(), INTERVAL 6 MONTH) " +
            "GROUP BY month_key, month_label " +
            "ORDER BY month_key";

        List<String> labels  = new ArrayList<>();
        List<String> amounts = new ArrayList<>();

        try (PreparedStatement st = conn.prepareStatement(sql);
             ResultSet rs = st.executeQuery()) {
            while (rs.next()) {
                labels.add(rs.getString("month_label"));
                amounts.add(rs.getBigDecimal("revenue").setScale(2, RoundingMode.HALF_UP).toString());
            }
        }

        // Build JS arrays
        StringBuilder labelsJs  = new StringBuilder("[");
        StringBuilder amountsJs = new StringBuilder("[");
        for (int i = 0; i < labels.size(); i++) {
            if (i > 0) { labelsJs.append(","); amountsJs.append(","); }
            labelsJs.append("'").append(labels.get(i)).append("'");
            amountsJs.append(amounts.get(i));
        }
        labelsJs.append("]"); amountsJs.append("]");

        request.setAttribute("chartMonthLabels",  labelsJs.toString());
        request.setAttribute("chartMonthRevenue", amountsJs.toString());
    }

    // ─────────────────────────── STATUS BREAKDOWN ───────────────────────────

    private void loadReservationStatusBreakdown(Connection conn, HttpServletRequest request) throws SQLException {
        String sql =
            "SELECT status, COUNT(*) AS cnt FROM reservations GROUP BY status";
        Map<String, Integer> breakdown = new LinkedHashMap<>();
        for (String s : new String[]{"PENDING","CONFIRMED","CHECKED_IN","CHECKED_OUT","CANCELLED"})
            breakdown.put(s, 0);

        try (PreparedStatement st = conn.prepareStatement(sql);
             ResultSet rs = st.executeQuery()) {
            while (rs.next()) {
                breakdown.put(rs.getString("status"), rs.getInt("cnt"));
            }
        }

        StringBuilder vals = new StringBuilder("[");
        boolean first = true;
        for (int v : breakdown.values()) {
            if (!first) vals.append(",");
            vals.append(v);
            first = false;
        }
        vals.append("]");
        request.setAttribute("chartStatusData", vals.toString());
    }

    // ─────────────────────────── ROOM TYPE OCCUPANCY ────────────────────────

    private void loadRoomTypeOccupancy(Connection conn, HttpServletRequest request) throws SQLException {
        String sql =
            "SELECT room_type, " +
            "  COUNT(*) AS total, " +
            "  SUM(CASE WHEN status='OCCUPIED' OR status='RESERVED' THEN 1 ELSE 0 END) AS occupied " +
            "FROM rooms GROUP BY room_type ORDER BY room_type";

        List<String> types    = new ArrayList<>();
        List<Integer> totals  = new ArrayList<>();
        List<Integer> occupied = new ArrayList<>();

        try (PreparedStatement st = conn.prepareStatement(sql);
             ResultSet rs = st.executeQuery()) {
            while (rs.next()) {
                types.add(rs.getString("room_type"));
                totals.add(rs.getInt("total"));
                occupied.add(rs.getInt("occupied"));
            }
        }

        StringBuilder typesJs    = new StringBuilder("[");
        StringBuilder totalsJs   = new StringBuilder("[");
        StringBuilder occupiedJs = new StringBuilder("[");
        for (int i = 0; i < types.size(); i++) {
            if (i > 0) { typesJs.append(","); totalsJs.append(","); occupiedJs.append(","); }
            typesJs.append("'").append(types.get(i)).append("'");
            totalsJs.append(totals.get(i));
            occupiedJs.append(occupied.get(i));
        }
        typesJs.append("]"); totalsJs.append("]"); occupiedJs.append("]");

        request.setAttribute("chartRoomTypes",    typesJs.toString());
        request.setAttribute("chartRoomTotals",   totalsJs.toString());
        request.setAttribute("chartRoomOccupied", occupiedJs.toString());
    }

    // ─────────────────────────── UTILS ──────────────────────────────────────

    private String formatMoney(BigDecimal val) {
        if (val == null) return "Rs. 0.00";
        return String.format("Rs. %,.2f", val.doubleValue());
    }

    private void transferFlash(HttpServletRequest request) {
        HttpSession s = request.getSession(false);
        if (s == null) return;
        String ok  = (String) s.getAttribute(Constants.ATTR_SUCCESS);
        String err = (String) s.getAttribute(Constants.ATTR_ERROR);
        if (ok  != null) { request.setAttribute(Constants.ATTR_SUCCESS, ok);  s.removeAttribute(Constants.ATTR_SUCCESS); }
        if (err != null) { request.setAttribute(Constants.ATTR_ERROR,   err); s.removeAttribute(Constants.ATTR_ERROR);   }
    }
}
