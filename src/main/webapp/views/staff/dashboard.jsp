<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="com.oceanview.model.User" %>
<%@ page import="com.oceanview.model.Reservation" %>
<%@ page import="com.oceanview.util.Constants" %>
<%@ page import="java.util.List" %>
<%@ page import="java.time.LocalDate" %>
<%@ page import="java.time.format.DateTimeFormatter" %>
<%
    User currentUser = (User) session.getAttribute(Constants.SESSION_USER);
    if (currentUser == null || (!currentUser.isStaff() && !currentUser.isAdmin())) {
        response.sendRedirect(request.getContextPath() + "/login");
        return;
    }

    String ctx = request.getContextPath();
    String error   = (String) request.getAttribute(Constants.ATTR_ERROR);
    String success = (String) request.getAttribute(Constants.ATTR_SUCCESS);

    // Stat counts
    Integer todayCheckInCount  = (Integer) request.getAttribute("todayCheckInCount");
    Integer todayCheckOutCount = (Integer) request.getAttribute("todayCheckOutCount");
    Integer activeCount        = (Integer) request.getAttribute("activeCount");
    Integer pendingCount       = (Integer) request.getAttribute("pendingCount");
    Integer availableRooms     = (Integer) request.getAttribute("availableRooms");
    Integer occupiedRooms      = (Integer) request.getAttribute("occupiedRooms");
    Integer reservedRooms      = (Integer) request.getAttribute("reservedRooms");
    Integer maintenanceRooms   = (Integer) request.getAttribute("maintenanceRooms");
    Integer totalRooms         = (Integer) request.getAttribute("totalRooms");
    Double  occupancyRate      = (Double)  request.getAttribute("occupancyRate");

    if (todayCheckInCount  == null) todayCheckInCount  = 0;
    if (todayCheckOutCount == null) todayCheckOutCount = 0;
    if (activeCount        == null) activeCount        = 0;
    if (pendingCount       == null) pendingCount       = 0;
    if (availableRooms     == null) availableRooms     = 0;
    if (occupiedRooms      == null) occupiedRooms      = 0;
    if (reservedRooms      == null) reservedRooms      = 0;
    if (maintenanceRooms   == null) maintenanceRooms   = 0;
    if (totalRooms         == null) totalRooms         = 0;
    if (occupancyRate      == null) occupancyRate      = 0.0;

    // Lists
    List<Reservation> todayCheckIns     = (List<Reservation>) request.getAttribute("todayCheckIns");
    List<Reservation> todayCheckOuts    = (List<Reservation>) request.getAttribute("todayCheckOuts");
    List<Reservation> recentReservations= (List<Reservation>) request.getAttribute("recentReservations");
    if (todayCheckIns      == null) todayCheckIns      = java.util.Collections.emptyList();
    if (todayCheckOuts     == null) todayCheckOuts     = java.util.Collections.emptyList();
    if (recentReservations == null) recentReservations = java.util.Collections.emptyList();

    DateTimeFormatter displayFmt = DateTimeFormatter.ofPattern("dd MMM yyyy");
    String today = LocalDate.now().format(DateTimeFormatter.ofPattern("EEEE, MMMM dd, yyyy"));
    String staffName = currentUser.getFullName() != null ? currentUser.getFullName() : currentUser.getUsername();
    String staffInitial = staffName.substring(0, 1).toUpperCase();
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Staff Dashboard - Ocean View Resort</title>
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
    <style>
        /* ============================================================
           STAFF DASHBOARD — FULLY SELF-CONTAINED EMBEDDED CSS
           ============================================================ */
        :root {
            --navy:        #0D2137;
            --ocean:       #1A6B8A;
            --ocean-mid:   #2589A8;
            --ocean-light: #E8F4F8;
            --gold:        #D4AF37;
            --gold-light:  #FFF8E1;
            --white:       #FFFFFF;
            --off-white:   #F5F7FA;
            --surface:     #FFFFFF;
            --text-dark:   #1A2332;
            --text-mid:    #4A5568;
            --text-light:  #718096;
            --border:      #E2E8F0;
            --success:     #276749;
            --success-bg:  #F0FFF4;
            --success-bdr: #9AE6B4;
            --danger:      #C53030;
            --danger-bg:   #FFF5F5;
            --danger-bdr:  #FEB2B2;
            --warning:     #B7791F;
            --warning-bg:  #FFFFF0;
            --warning-bdr: #FAF089;
            --info:        #2B6CB0;
            --info-bg:     #EBF8FF;
            --info-bdr:    #90CDF4;
            --purple:      #553C9A;
            --purple-bg:   #FAF5FF;
            --purple-bdr:  #D6BCFA;
            --sidebar-w:   240px;
            --topbar-h:    64px;
            --shadow-sm:   0 1px 3px rgba(0,0,0,0.08);
            --shadow-md:   0 4px 16px rgba(0,0,0,0.10);
            --shadow-lg:   0 12px 40px rgba(0,0,0,0.14);
            --radius-sm:   6px;
            --radius-md:   12px;
            --radius-lg:   20px;
            --tr:          0.2s ease;
        }

        *, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }
        body { font-family: 'Segoe UI', system-ui, -apple-system, sans-serif;
               background: var(--off-white); color: var(--text-dark);
               min-height: 100vh; display: flex; }

        /* ── SIDEBAR ── */
        .sidebar {
            width: var(--sidebar-w); min-height: 100vh;
            background: var(--navy);
            display: flex; flex-direction: column;
            position: fixed; left: 0; top: 0; z-index: 300;
            transition: transform var(--tr);
        }
        .sidebar-brand {
            padding: 20px 20px 16px;
            border-bottom: 1px solid rgba(255,255,255,0.08);
            display: flex; align-items: center; gap: 10px;
        }
        .sidebar-brand i  { color: var(--gold); font-size: 1.4rem; }
        .sidebar-brand span { color: var(--white); font-size: 0.95rem; font-weight: 700; line-height: 1.2; }
        .sidebar-brand small { color: rgba(255,255,255,0.45); font-size: 0.7rem; display: block; }

        .sidebar-nav { flex: 1; padding: 12px 0; overflow-y: auto; }
        .nav-section-label {
            padding: 14px 20px 6px;
            font-size: 0.65rem; font-weight: 700;
            text-transform: uppercase; letter-spacing: 1px;
            color: rgba(255,255,255,0.3);
        }
        .nav-item {
            display: flex; align-items: center; gap: 12px;
            padding: 11px 20px; margin: 2px 10px;
            border-radius: var(--radius-sm);
            color: rgba(255,255,255,0.65);
            font-size: 0.875rem; font-weight: 500;
            text-decoration: none; cursor: pointer;
            transition: background var(--tr), color var(--tr);
        }
        .nav-item:hover { background: rgba(255,255,255,0.08); color: var(--white); }
        .nav-item.active {
            background: var(--ocean); color: var(--white);
            box-shadow: 0 2px 8px rgba(26,107,138,0.4);
        }
        .nav-item i { width: 18px; text-align: center; font-size: 0.9rem; }
        .nav-badge {
            margin-left: auto; background: var(--danger);
            color: var(--white); font-size: 0.7rem; font-weight: 700;
            padding: 2px 7px; border-radius: 10px; min-width: 20px; text-align: center;
        }
        .nav-badge.gold { background: var(--gold); color: var(--navy); }

        .sidebar-footer {
            padding: 16px 20px;
            border-top: 1px solid rgba(255,255,255,0.08);
        }
        .staff-card {
            display: flex; align-items: center; gap: 10px;
            padding: 10px 12px; border-radius: var(--radius-sm);
            background: rgba(255,255,255,0.06);
        }
        .staff-avatar {
            width: 36px; height: 36px; border-radius: 50%;
            background: var(--gold); color: var(--navy);
            display: flex; align-items: center; justify-content: center;
            font-weight: 700; font-size: 0.85rem; flex-shrink: 0;
        }
        .staff-info { overflow: hidden; }
        .staff-name { color: var(--white); font-size: 0.82rem; font-weight: 600;
                      white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
        .staff-role { color: rgba(255,255,255,0.4); font-size: 0.7rem; }

        /* ── MAIN AREA ── */
        .main-area {
            margin-left: var(--sidebar-w);
            flex: 1; display: flex; flex-direction: column; min-width: 0;
        }

        /* ── TOPBAR ── */
        .topbar {
            height: var(--topbar-h); background: var(--white);
            border-bottom: 1px solid var(--border);
            display: flex; align-items: center; justify-content: space-between;
            padding: 0 28px; position: sticky; top: 0; z-index: 200;
            box-shadow: var(--shadow-sm);
        }
        .topbar-left h1 { font-size: 1.15rem; font-weight: 700; color: var(--text-dark); }
        .topbar-left p  { font-size: 0.78rem; color: var(--text-light); margin-top: 1px; }
        .topbar-right { display: flex; align-items: center; gap: 12px; }
        .topbar-btn {
            display: inline-flex; align-items: center; gap: 6px;
            padding: 8px 16px; border-radius: var(--radius-sm);
            font-size: 0.82rem; font-weight: 500; cursor: pointer;
            border: none; transition: var(--tr); text-decoration: none;
        }
        .btn-primary  { background: var(--ocean);   color: var(--white); }
        .btn-primary:hover  { background: var(--navy); }
        .btn-secondary{ background: var(--off-white); color: var(--text-mid); border: 1px solid var(--border); }
        .btn-secondary:hover{ background: var(--border); }
        .btn-success  { background: var(--success);  color: var(--white); }
        .btn-success:hover  { background: #276749; }
        .btn-danger   { background: var(--danger);   color: var(--white); }
        .btn-danger:hover   { background: #9B2C2C; }
        .btn-warning  { background: #D69E2E;          color: var(--white); }
        .btn-warning:hover  { background: var(--warning); }
        .btn-sm { padding: 5px 12px; font-size: 0.78rem; }
        .btn-icon { padding: 8px; width: 36px; height: 36px; justify-content: center; }

        /* ── PAGE CONTENT ── */
        .page-content { padding: 28px; flex: 1; }

        /* ── ALERTS ── */
        .alert {
            display: flex; align-items: flex-start; gap: 12px;
            padding: 14px 18px; border-radius: var(--radius-md);
            margin-bottom: 20px; font-size: 0.875rem; border-left: 4px solid;
        }
        .alert-success { background: var(--success-bg); border-color: var(--success); color: var(--success); }
        .alert-danger  { background: var(--danger-bg);  border-color: var(--danger);  color: var(--danger);  }
        .alert i { margin-top: 1px; flex-shrink: 0; }

        /* ── STAT CARDS ── */
        .stats-grid {
            display: grid;
            grid-template-columns: repeat(4, 1fr);
            gap: 18px; margin-bottom: 24px;
        }
        .stat-card {
            background: var(--white); border-radius: var(--radius-md);
            padding: 22px 24px; box-shadow: var(--shadow-sm);
            border: 1px solid var(--border);
            display: flex; align-items: flex-start; gap: 16px;
            transition: box-shadow var(--tr), transform var(--tr);
        }
        .stat-card:hover { box-shadow: var(--shadow-md); transform: translateY(-2px); }
        .stat-icon {
            width: 52px; height: 52px; border-radius: var(--radius-sm);
            display: flex; align-items: center; justify-content: center;
            font-size: 1.3rem; flex-shrink: 0;
        }
        .stat-icon.blue   { background: var(--info-bg);    color: var(--info); }
        .stat-icon.green  { background: var(--success-bg); color: var(--success); }
        .stat-icon.orange { background: var(--warning-bg); color: var(--warning); }
        .stat-icon.purple { background: var(--purple-bg);  color: var(--purple); }
        .stat-body { min-width: 0; }
        .stat-value { font-size: 2rem; font-weight: 800; color: var(--text-dark); line-height: 1; }
        .stat-label { font-size: 0.78rem; color: var(--text-light); margin-top: 4px; font-weight: 500; }
        .stat-sub   { font-size: 0.72rem; color: var(--text-light); margin-top: 6px; }
        .stat-sub span { font-weight: 600; }

        /* ── ROOM STATUS BAR ── */
        .room-status-card {
            background: var(--white); border-radius: var(--radius-md);
            border: 1px solid var(--border); box-shadow: var(--shadow-sm);
            padding: 22px 24px; margin-bottom: 24px;
        }
        .room-status-header {
            display: flex; align-items: center; justify-content: space-between;
            margin-bottom: 18px;
        }
        .room-status-title { font-size: 1rem; font-weight: 700; color: var(--text-dark); }
        .room-status-subtitle { font-size: 0.78rem; color: var(--text-light); margin-top: 2px; }
        .occupancy-bar-wrap { margin-bottom: 18px; }
        .occupancy-bar-labels {
            display: flex; justify-content: space-between;
            font-size: 0.78rem; color: var(--text-light); margin-bottom: 6px;
        }
        .occupancy-bar {
            height: 12px; border-radius: 6px;
            background: var(--border); overflow: hidden;
            display: flex;
        }
        .occ-seg { height: 100%; transition: width 0.6s ease; }
        .occ-seg.occupied    { background: var(--danger); }
        .occ-seg.reserved    { background: var(--warning); }
        .occ-seg.maintenance { background: var(--text-light); }
        .occ-seg.available   { background: var(--success); }
        .room-legend {
            display: flex; gap: 20px; flex-wrap: wrap; margin-top: 14px;
        }
        .legend-item {
            display: flex; align-items: center; gap: 7px;
            font-size: 0.8rem; color: var(--text-mid);
        }
        .legend-dot {
            width: 10px; height: 10px; border-radius: 50%;
        }
        .legend-dot.occupied    { background: var(--danger); }
        .legend-dot.reserved    { background: var(--warning); }
        .legend-dot.maintenance { background: var(--text-light); }
        .legend-dot.available   { background: var(--success); }
        .room-stat-pills { display: flex; gap: 12px; flex-wrap: wrap; margin-top: 4px; }
        .room-pill {
            display: flex; align-items: center; gap: 8px;
            padding: 8px 16px; border-radius: 20px;
            font-size: 0.82rem; font-weight: 600; border: 1px solid;
        }
        .room-pill.occupied    { background: var(--danger-bg);  color: var(--danger);  border-color: var(--danger-bdr); }
        .room-pill.available   { background: var(--success-bg); color: var(--success); border-color: var(--success-bdr); }
        .room-pill.reserved    { background: var(--warning-bg); color: var(--warning); border-color: var(--warning-bdr); }
        .room-pill.maintenance { background: var(--off-white);  color: var(--text-mid); border-color: var(--border); }

        /* ── TWO-COLUMN LAYOUT ── */
        .two-col { display: grid; grid-template-columns: 1fr 1fr; gap: 20px; margin-bottom: 24px; }

        /* ── SECTION CARD ── */
        .section-card {
            background: var(--white); border-radius: var(--radius-md);
            border: 1px solid var(--border); box-shadow: var(--shadow-sm);
            overflow: hidden;
        }
        .section-head {
            display: flex; align-items: center; justify-content: space-between;
            padding: 16px 20px; border-bottom: 1px solid var(--border);
            background: linear-gradient(to right, #f8fbfd, var(--white));
        }
        .section-head-left { display: flex; align-items: center; gap: 10px; }
        .section-icon {
            width: 36px; height: 36px; border-radius: var(--radius-sm);
            background: var(--ocean-light); color: var(--ocean);
            display: flex; align-items: center; justify-content: center;
            font-size: 0.9rem;
        }
        .section-icon.green  { background: var(--success-bg); color: var(--success); }
        .section-icon.orange { background: var(--warning-bg); color: var(--warning); }
        .section-icon.purple { background: var(--purple-bg);  color: var(--purple); }
        .section-title { font-size: 0.9rem; font-weight: 700; color: var(--text-dark); }
        .section-sub   { font-size: 0.72rem; color: var(--text-light); }

        /* ── DATA TABLE ── */
        .data-table { width: 100%; border-collapse: collapse; }
        .data-table th {
            padding: 10px 16px; text-align: left;
            font-size: 0.72rem; font-weight: 700;
            text-transform: uppercase; letter-spacing: 0.5px;
            color: var(--text-light); background: var(--off-white);
            border-bottom: 1px solid var(--border);
        }
        .data-table td {
            padding: 12px 16px; font-size: 0.82rem;
            color: var(--text-mid); border-bottom: 1px solid var(--border);
            vertical-align: middle;
        }
        .data-table tr:last-child td { border-bottom: none; }
        .data-table tr:hover td { background: var(--off-white); }
        .table-empty {
            padding: 36px 20px; text-align: center;
            color: var(--text-light); font-size: 0.85rem;
        }
        .table-empty i { font-size: 2rem; display: block; margin-bottom: 10px; opacity: 0.4; }

        /* ── BADGES / STATUS CHIPS ── */
        .badge {
            display: inline-flex; align-items: center; gap: 4px;
            padding: 3px 10px; border-radius: 12px;
            font-size: 0.72rem; font-weight: 600; white-space: nowrap;
        }
        .badge-pending     { background: var(--warning-bg); color: var(--warning); border: 1px solid var(--warning-bdr); }
        .badge-confirmed   { background: var(--info-bg);    color: var(--info);    border: 1px solid var(--info-bdr); }
        .badge-checked-in  { background: var(--success-bg); color: var(--success); border: 1px solid var(--success-bdr); }
        .badge-checked-out { background: var(--off-white);  color: var(--text-mid); border: 1px solid var(--border); }
        .badge-cancelled   { background: var(--danger-bg);  color: var(--danger);  border: 1px solid var(--danger-bdr); }

        /* ── GUEST NAME CELL ── */
        .guest-cell { display: flex; align-items: center; gap: 10px; }
        .guest-avatar-sm {
            width: 30px; height: 30px; border-radius: 50%;
            background: var(--ocean-light); color: var(--ocean);
            display: flex; align-items: center; justify-content: center;
            font-size: 0.78rem; font-weight: 700; flex-shrink: 0;
        }
        .guest-name { font-weight: 600; color: var(--text-dark); font-size: 0.82rem; }
        .guest-ref  { font-size: 0.7rem; color: var(--text-light); }

        /* ── ACTION BUTTONS IN TABLE ── */
        .action-btns { display: flex; gap: 6px; flex-wrap: wrap; }

        /* ── QUICK ACTIONS ── */
        .quick-actions-grid {
            display: grid; grid-template-columns: 1fr 1fr; gap: 10px; padding: 16px 20px;
        }
        .quick-action-btn {
            display: flex; flex-direction: column; align-items: center; gap: 8px;
            padding: 16px 12px; border-radius: var(--radius-md);
            background: var(--off-white); border: 1.5px solid var(--border);
            color: var(--text-mid); font-size: 0.78rem; font-weight: 600;
            text-decoration: none; text-align: center;
            transition: background var(--tr), border-color var(--tr), color var(--tr), box-shadow var(--tr);
            cursor: pointer;
        }
        .quick-action-btn i { font-size: 1.3rem; }
        .quick-action-btn:hover {
            background: var(--ocean-light); border-color: var(--ocean);
            color: var(--ocean); box-shadow: var(--shadow-sm);
        }
        .quick-action-btn.red:hover   { background: var(--danger-bg);  border-color: var(--danger);  color: var(--danger);  }
        .quick-action-btn.green:hover { background: var(--success-bg); border-color: var(--success); color: var(--success); }
        .quick-action-btn.gold:hover  { background: var(--gold-light); border-color: var(--gold);    color: var(--warning); }

        /* ── RECENT RESERVATIONS FULL-WIDTH TABLE ── */
        .full-width-card {
            background: var(--white); border-radius: var(--radius-md);
            border: 1px solid var(--border); box-shadow: var(--shadow-sm);
            overflow: hidden; margin-bottom: 24px;
        }

        /* ── MODAL ── */
        .modal-backdrop {
            display: none; position: fixed;
            inset: 0; z-index: 500;
            background: rgba(0,0,0,0.55);
            align-items: center; justify-content: center; padding: 24px;
        }
        .modal-backdrop.open { display: flex; }
        .modal-box {
            background: var(--white); border-radius: var(--radius-md);
            box-shadow: var(--shadow-lg); width: 100%; max-width: 500px;
            max-height: 90vh; overflow-y: auto;
            animation: slideUp 0.25s ease;
        }
        .modal-head {
            display: flex; align-items: center; justify-content: space-between;
            padding: 18px 22px;
            background: linear-gradient(135deg, var(--navy), var(--ocean));
            color: var(--white);
        }
        .modal-head-title { display: flex; align-items: center; gap: 10px; font-size: 0.95rem; font-weight: 600; }
        .modal-close-btn {
            background: rgba(255,255,255,0.15); border: none; color: var(--white);
            width: 30px; height: 30px; border-radius: 50%;
            cursor: pointer; display: flex; align-items: center; justify-content: center;
            font-size: 1rem; transition: background var(--tr);
        }
        .modal-close-btn:hover { background: rgba(255,255,255,0.3); }
        .modal-body { padding: 22px; }
        .detail-row {
            display: flex; justify-content: space-between; align-items: flex-start;
            padding: 10px 0; border-bottom: 1px solid var(--border); font-size: 0.85rem;
        }
        .detail-row:last-child { border-bottom: none; }
        .detail-label { color: var(--text-light); font-weight: 500; }
        .detail-value { color: var(--text-dark); font-weight: 600; text-align: right; }
        .modal-actions { display: flex; gap: 10px; margin-top: 20px; flex-wrap: wrap; }

        /* ── ANIMATIONS ── */
        @keyframes slideUp { from { transform: translateY(30px); opacity: 0; }
                             to   { transform: translateY(0);    opacity: 1; } }

        /* ── MOBILE SIDEBAR TOGGLE ── */
        .sidebar-toggle {
            display: none; background: none; border: none;
            font-size: 1.2rem; color: var(--text-mid); cursor: pointer; padding: 4px;
        }
        .sidebar-overlay {
            display: none; position: fixed; inset: 0; z-index: 250;
            background: rgba(0,0,0,0.5);
        }

        /* ── RESPONSIVE ── */
        @media (max-width: 1100px) {
            .stats-grid { grid-template-columns: repeat(2, 1fr); }
        }
        @media (max-width: 900px) {
            .two-col { grid-template-columns: 1fr; }
        }
        @media (max-width: 768px) {
            .sidebar { transform: translateX(-100%); }
            .sidebar.open { transform: translateX(0); }
            .sidebar-overlay.open { display: block; }
            .main-area { margin-left: 0; }
            .sidebar-toggle { display: block; }
            .stats-grid { grid-template-columns: 1fr 1fr; gap: 12px; }
            .topbar { padding: 0 16px; }
            .page-content { padding: 16px; }
        }
        @media (max-width: 480px) {
            .stats-grid { grid-template-columns: 1fr; }
            .quick-actions-grid { grid-template-columns: repeat(2, 1fr); }
        }
    </style>
</head>
<body>

<!-- Sidebar Overlay (mobile) -->
<div class="sidebar-overlay" id="sidebarOverlay" onclick="closeSidebar()"></div>

<!-- ── SIDEBAR ── -->
<aside class="sidebar" id="sidebar">
    <div class="sidebar-brand">
        <i class="fas fa-hotel"></i>
        <div>
            <span>Ocean View<br>Resort</span>
            <small>Staff Portal</small>
        </div>
    </div>

    <nav class="sidebar-nav">
        <div class="nav-section-label">Main</div>
        <a href="<%= ctx %>/dashboard" class="nav-item active">
            <i class="fas fa-th-large"></i> Dashboard
        </a>
        <a href="<%= ctx %>/staff/reservations" class="nav-item">
            <i class="fas fa-calendar-alt"></i> Reservations
            <% if (pendingCount > 0) { %>
            <span class="nav-badge gold"><%= pendingCount %></span>
            <% } %>
        </a>
        <a href="<%= ctx %>/staff/checkin" class="nav-item">
            <i class="fas fa-sign-in-alt"></i> Check-In
            <% if (todayCheckInCount > 0) { %>
            <span class="nav-badge"><%= todayCheckInCount %></span>
            <% } %>
        </a>
        <a href="<%= ctx %>/staff/checkout" class="nav-item">
            <i class="fas fa-sign-out-alt"></i> Check-Out
            <% if (todayCheckOutCount > 0) { %>
            <span class="nav-badge"><%= todayCheckOutCount %></span>
            <% } %>
        </a>

        <a href="<%= ctx %>/logout" class="nav-item">
            <i class="fas fa-power-off"></i> Logout
        </a>
    </nav>

    <div class="sidebar-footer">
        <div class="staff-card">
            <div class="staff-avatar"><%= staffInitial %></div>
            <div class="staff-info">
                <div class="staff-name"><%= staffName %></div>
                <div class="staff-role"><%= currentUser.getRole() %></div>
            </div>
        </div>
    </div>
</aside>

<!-- ── MAIN AREA ── -->
<div class="main-area">

    <!-- TOPBAR -->
    <header class="topbar">
        <div class="topbar-left" style="display:flex;align-items:center;gap:12px;">
            <button class="sidebar-toggle" onclick="toggleSidebar()">
                <i class="fas fa-bars"></i>
            </button>
            <div>
                <h1>Staff Dashboard</h1>
                <p><i class="fas fa-calendar-day" style="margin-right:4px;"></i><%= today %></p>
            </div>
        </div>
        <div class="topbar-right">
            <a href="<%= ctx %>/reservations?action=create" class="topbar-btn btn-primary">
                <i class="fas fa-plus"></i> New Booking
            </a>
            <a href="<%= ctx %>/staff/checkin" class="topbar-btn btn-success">
                <i class="fas fa-sign-in-alt"></i> Check-In
            </a>
            <a href="<%= ctx %>/logout" class="topbar-btn btn-secondary">
                <i class="fas fa-sign-out-alt"></i> Logout
            </a>
        </div>
    </header>

    <!-- PAGE CONTENT -->
    <div class="page-content">

        <!-- ALERTS -->
        <% if (error != null && !error.isEmpty()) { %>
        <div class="alert alert-danger">
            <i class="fas fa-exclamation-circle"></i>
            <span><%= error %></span>
        </div>
        <% } %>
        <% if (success != null && !success.isEmpty()) { %>
        <div class="alert alert-success">
            <i class="fas fa-check-circle"></i>
            <span><%= success %></span>
        </div>
        <% } %>

        <!-- ── STAT CARDS ── -->
        <div class="stats-grid">
            <div class="stat-card">
                <div class="stat-icon blue"><i class="fas fa-sign-in-alt"></i></div>
                <div class="stat-body">
                    <div class="stat-value"><%= todayCheckInCount %></div>
                    <div class="stat-label">Today's Check-Ins</div>
                    <div class="stat-sub">Arrivals expected today</div>
                </div>
            </div>
            <div class="stat-card">
                <div class="stat-icon green"><i class="fas fa-sign-out-alt"></i></div>
                <div class="stat-body">
                    <div class="stat-value"><%= todayCheckOutCount %></div>
                    <div class="stat-label">Today's Check-Outs</div>
                    <div class="stat-sub">Departures today</div>
                </div>
            </div>
            <div class="stat-card">
                <div class="stat-icon purple"><i class="fas fa-bed"></i></div>
                <div class="stat-body">
                    <div class="stat-value"><%= activeCount %></div>
                    <div class="stat-label">Active Stays</div>
                    <div class="stat-sub">Currently checked-in</div>
                </div>
            </div>
            <div class="stat-card">
                <div class="stat-icon orange"><i class="fas fa-clock"></i></div>
                <div class="stat-body">
                    <div class="stat-value"><%= pendingCount %></div>
                    <div class="stat-label">Pending Requests</div>
                    <div class="stat-sub">Awaiting confirmation</div>
                </div>
            </div>
        </div>

        <!-- ── ROOM STATUS BAR ── -->
        <div class="room-status-card">
            <div class="room-status-header">
                <div>
                    <div class="room-status-title">Room Occupancy</div>
                    <div class="room-status-subtitle">
                        <%= totalRooms %> total rooms &mdash;
                        <strong style="color:var(--ocean);"><%= String.format("%.1f", occupancyRate) %>%</strong> occupancy rate
                    </div>
                </div>
                <a href="<%= ctx %>/rooms" class="topbar-btn btn-secondary" style="font-size:0.78rem;padding:7px 14px;">
                    <i class="fas fa-door-open"></i> Manage Rooms
                </a>
            </div>
            <%
                int oOccupied    = totalRooms > 0 ? (int)((double)occupiedRooms    / totalRooms * 100) : 0;
                int oReserved    = totalRooms > 0 ? (int)((double)reservedRooms    / totalRooms * 100) : 0;
                int oMaintenance = totalRooms > 0 ? (int)((double)maintenanceRooms / totalRooms * 100) : 0;
                int oAvailable   = 100 - oOccupied - oReserved - oMaintenance;
                if (oAvailable < 0) oAvailable = 0;
            %>
            <div class="occupancy-bar-wrap">
                <div class="occupancy-bar-labels">
                    <span>Occupied (<%= occupiedRooms %>)</span>
                    <span>Reserved (<%= reservedRooms %>)</span>
                    <span>Maintenance (<%= maintenanceRooms %>)</span>
                    <span>Available (<%= availableRooms %>)</span>
                </div>
                <div class="occupancy-bar">
                    <div class="occ-seg occupied"    style="width:<%= oOccupied %>%"></div>
                    <div class="occ-seg reserved"    style="width:<%= oReserved %>%"></div>
                    <div class="occ-seg maintenance" style="width:<%= oMaintenance %>%"></div>
                    <div class="occ-seg available"   style="width:<%= oAvailable %>%"></div>
                </div>
                <div class="room-legend">
                    <div class="legend-item"><div class="legend-dot occupied"></div> Occupied</div>
                    <div class="legend-item"><div class="legend-dot reserved"></div> Reserved</div>
                    <div class="legend-item"><div class="legend-dot maintenance"></div> Maintenance</div>
                    <div class="legend-item"><div class="legend-dot available"></div> Available</div>
                </div>
            </div>
            <div class="room-stat-pills">
                <div class="room-pill occupied">   <i class="fas fa-circle" style="font-size:0.6rem;"></i> <%= occupiedRooms %> Occupied</div>
                <div class="room-pill available">  <i class="fas fa-circle" style="font-size:0.6rem;"></i> <%= availableRooms %> Available</div>
                <div class="room-pill reserved">   <i class="fas fa-circle" style="font-size:0.6rem;"></i> <%= reservedRooms %> Reserved</div>
                <div class="room-pill maintenance"><i class="fas fa-circle" style="font-size:0.6rem;"></i> <%= maintenanceRooms %> Maintenance</div>
            </div>
        </div>

        <!-- ── TWO COLUMN: CHECK-INS | CHECK-OUTS ── -->
        <div class="two-col">

            <!-- TODAY'S CHECK-INS -->
            <div class="section-card">
                <div class="section-head">
                    <div class="section-head-left">
                        <div class="section-icon blue"><i class="fas fa-sign-in-alt"></i></div>
                        <div>
                            <div class="section-title">Today's Arrivals</div>
                            <div class="section-sub"><%= todayCheckIns.size() %> guests arriving</div>
                        </div>
                    </div>
                    <a href="<%= ctx %>/staff/checkin" class="topbar-btn btn-sm btn-primary">View All</a>
                </div>
                <% if (todayCheckIns.isEmpty()) { %>
                <div class="table-empty">
                    <i class="fas fa-calendar-check"></i>
                    No arrivals scheduled for today
                </div>
                <% } else { %>
                <table class="data-table">
                    <thead>
                        <tr>
                            <th>Guest</th>
                            <th>Room</th>
                            <th>Status</th>
                            <th>Action</th>
                        </tr>
                    </thead>
                    <tbody>
                    <% for (Reservation r : todayCheckIns) {
                        String guestName = r.getGuestName() != null ? r.getGuestName() : "Guest #" + r.getGuestId();
                        String roomNum   = r.getRoomNumber() != null ? r.getRoomNumber() : "#" + r.getRoomId();
                        String initial   = guestName.substring(0,1).toUpperCase();
                    %>
                        <tr>
                            <td>
                                <div class="guest-cell">
                                    <div class="guest-avatar-sm"><%= initial %></div>
                                    <div>
                                        <div class="guest-name"><%= guestName %></div>
                                        <div class="guest-ref"><%= r.getReservationNumber() != null ? r.getReservationNumber() : "" %></div>
                                    </div>
                                </div>
                            </td>
                            <td>Room <%= roomNum %></td>
                            <td><span class="badge badge-confirmed"><i class="fas fa-circle" style="font-size:0.5rem;"></i> Confirmed</span></td>
                            <td>
                                <form action="<%= ctx %>/reservations" method="post" style="display:inline;">
                                    <input type="hidden" name="action" value="checkin">
                                    <input type="hidden" name="reservationId" value="<%= r.getReservationId() %>">
                                    <button type="submit" class="topbar-btn btn-sm btn-success">
                                        <i class="fas fa-sign-in-alt"></i> Check In
                                    </button>
                                </form>
                            </td>
                        </tr>
                    <% } %>
                    </tbody>
                </table>
                <% } %>
            </div>

            <!-- TODAY'S CHECK-OUTS -->
            <div class="section-card">
                <div class="section-head">
                    <div class="section-head-left">
                        <div class="section-icon orange"><i class="fas fa-sign-out-alt"></i></div>
                        <div>
                            <div class="section-title">Today's Departures</div>
                            <div class="section-sub"><%= todayCheckOuts.size() %> guests departing</div>
                        </div>
                    </div>
                    <a href="<%= ctx %>/staff/checkout" class="topbar-btn btn-sm btn-warning">View All</a>
                </div>
                <% if (todayCheckOuts.isEmpty()) { %>
                <div class="table-empty">
                    <i class="fas fa-calendar-minus"></i>
                    No departures scheduled for today
                </div>
                <% } else { %>
                <table class="data-table">
                    <thead>
                        <tr>
                            <th>Guest</th>
                            <th>Room</th>
                            <th>Amount</th>
                            <th>Action</th>
                        </tr>
                    </thead>
                    <tbody>
                    <% for (Reservation r : todayCheckOuts) {
                        String guestName = r.getGuestName() != null ? r.getGuestName() : "Guest #" + r.getGuestId();
                        String roomNum   = r.getRoomNumber() != null ? r.getRoomNumber() : "#" + r.getRoomId();
                        String initial   = guestName.substring(0,1).toUpperCase();
                        String amount    = r.getFinalAmount() != null ? String.format("Rs. %.2f", r.getFinalAmount()) : "—";
                    %>
                        <tr>
                            <td>
                                <div class="guest-cell">
                                    <div class="guest-avatar-sm"><%= initial %></div>
                                    <div>
                                        <div class="guest-name"><%= guestName %></div>
                                        <div class="guest-ref"><%= r.getReservationNumber() != null ? r.getReservationNumber() : "" %></div>
                                    </div>
                                </div>
                            </td>
                            <td>Room <%= roomNum %></td>
                            <td><strong><%= amount %></strong></td>
                            <td>
                                <form action="<%= ctx %>/reservations" method="post" style="display:inline;">
                                    <input type="hidden" name="action" value="checkout">
                                    <input type="hidden" name="reservationId" value="<%= r.getReservationId() %>">
                                    <button type="submit" class="topbar-btn btn-sm btn-warning">
                                        <i class="fas fa-sign-out-alt"></i> Check Out
                                    </button>
                                </form>
                            </td>
                        </tr>
                    <% } %>
                    </tbody>
                </table>
                <% } %>
            </div>
        </div>

        <!-- ── TWO COLUMN: RECENT RESERVATIONS | QUICK ACTIONS ── -->
        <div class="two-col">

            <!-- RECENT RESERVATIONS -->
            <div class="section-card">
                <div class="section-head">
                    <div class="section-head-left">
                        <div class="section-icon purple"><i class="fas fa-list-alt"></i></div>
                        <div>
                            <div class="section-title">Recent Reservations</div>
                            <div class="section-sub">Latest activity</div>
                        </div>
                    </div>
                    <a href="<%= ctx %>/staff/reservations" class="topbar-btn btn-sm btn-secondary">View All</a>
                </div>
                <% if (recentReservations.isEmpty()) { %>
                <div class="table-empty">
                    <i class="fas fa-calendar-times"></i>
                    No reservations found
                </div>
                <% } else { %>
                <table class="data-table">
                    <thead>
                        <tr>
                            <th>Guest</th>
                            <th>Room</th>
                            <th>Check-In</th>
                            <th>Status</th>
                            <th>Actions</th>
                        </tr>
                    </thead>
                    <tbody>
                    <% for (Reservation r : recentReservations) {
                        String guestName = r.getGuestName() != null ? r.getGuestName() : "Guest #" + r.getGuestId();
                        String roomNum   = r.getRoomNumber() != null ? r.getRoomNumber() : "#" + r.getRoomId();
                        String initial   = guestName.substring(0,1).toUpperCase();
                        String checkIn   = r.getCheckInDate() != null ? r.getCheckInDate().format(displayFmt) : "—";
                        String statusCls = "badge-" + r.getStatus().name().toLowerCase().replace("_", "-");
                        String statusLbl = r.getStatus().name().replace("_", " ");
                    %>
                        <tr>
                            <td>
                                <div class="guest-cell">
                                    <div class="guest-avatar-sm"><%= initial %></div>
                                    <div>
                                        <div class="guest-name"><%= guestName %></div>
                                        <div class="guest-ref"><%= r.getReservationNumber() != null ? r.getReservationNumber() : "" %></div>
                                    </div>
                                </div>
                            </td>
                            <td>Rm <%= roomNum %></td>
                            <td><%= checkIn %></td>
                            <td><span class="badge <%= statusCls %>"><%= statusLbl %></span></td>
                            <td>
                                <div class="action-btns">
                                    <button class="topbar-btn btn-sm btn-secondary"
                                            onclick="viewReservation(<%= r.getReservationId() %>, '<%= guestName.replace("'","\'") %>', 'Rm <%= roomNum %>', '<%= checkIn %>', '<%= r.getCheckOutDate() != null ? r.getCheckOutDate().format(displayFmt) : "" %>', '<%= r.getStatus().name() %>', '<%= r.getFinalAmount() != null ? String.format("%.2f", r.getFinalAmount()) : "0.00" %>', '<%= r.getReservationNumber() != null ? r.getReservationNumber() : "" %>')">
                                        <i class="fas fa-eye"></i>
                                    </button>
                                    <% if (r.canCancel()) { %>
                                    <form action="<%= ctx %>/reservations" method="post" style="display:inline;"
                                          onsubmit="return confirm('Cancel reservation <%= r.getReservationNumber() %>?')">
                                        <input type="hidden" name="action" value="cancel">
                                        <input type="hidden" name="reservationId" value="<%= r.getReservationId() %>">
                                        <button type="submit" class="topbar-btn btn-sm btn-danger">
                                            <i class="fas fa-times"></i>
                                        </button>
                                    </form>
                                    <% } %>
                                    <% if (r.canCheckIn()) { %>
                                    <form action="<%= ctx %>/reservations" method="post" style="display:inline;">
                                        <input type="hidden" name="action" value="checkin">
                                        <input type="hidden" name="reservationId" value="<%= r.getReservationId() %>">
                                        <button type="submit" class="topbar-btn btn-sm btn-success">
                                            <i class="fas fa-sign-in-alt"></i>
                                        </button>
                                    </form>
                                    <% } %>
                                    <% if (r.canCheckOut()) { %>
                                    <form action="<%= ctx %>/reservations" method="post" style="display:inline;">
                                        <input type="hidden" name="action" value="checkout">
                                        <input type="hidden" name="reservationId" value="<%= r.getReservationId() %>">
                                        <button type="submit" class="topbar-btn btn-sm btn-warning">
                                            <i class="fas fa-sign-out-alt"></i>
                                        </button>
                                    </form>
                                    <% } %>
                                </div>
                            </td>
                        </tr>
                    <% } %>
                    </tbody>
                </table>
                <% } %>
            </div>

            <!-- QUICK ACTIONS -->
            <div class="section-card">
                <div class="section-head">
                    <div class="section-head-left">
                        <div class="section-icon"><i class="fas fa-bolt"></i></div>
                        <div>
                            <div class="section-title">Quick Actions</div>
                            <div class="section-sub">Common staff tasks</div>
                        </div>
                    </div>
                </div>
                <div class="quick-actions-grid">
                    <a href="<%= ctx %>/reservations?action=create" class="quick-action-btn green">
                        <i class="fas fa-plus-circle"></i>
                        New Booking
                    </a>
                    <a href="<%= ctx %>/staff/checkin" class="quick-action-btn">
                        <i class="fas fa-sign-in-alt"></i>
                        Process Check-In
                    </a>
                    <a href="<%= ctx %>/staff/checkout" class="quick-action-btn">
                        <i class="fas fa-sign-out-alt"></i>
                        Process Check-Out
                    </a>
                    <a href="<%= ctx %>/staff/search" class="quick-action-btn">
                        <i class="fas fa-search"></i>
                        Search Guest
                    </a>
                    <a href="<%= ctx %>/staff/reservations" class="quick-action-btn gold">
                        <i class="fas fa-calendar-alt"></i>
                        All Reservations
                    </a>
                    <a href="<%= ctx %>/rooms" class="quick-action-btn">
                        <i class="fas fa-door-open"></i>
                        Room Status
                    </a>
                </div>
            </div>
        </div>

    </div><!-- /page-content -->
</div><!-- /main-area -->

<!-- ── RESERVATION DETAIL MODAL ── -->
<div id="reservationModal" class="modal-backdrop">
    <div class="modal-box">
        <div class="modal-head">
            <div class="modal-head-title">
                <i class="fas fa-calendar-check"></i>
                <span id="modal-res-number">Reservation Details</span>
            </div>
            <button class="modal-close-btn" onclick="closeModal()">&times;</button>
        </div>
        <div class="modal-body">
            <div class="detail-row">
                <span class="detail-label">Guest Name</span>
                <span class="detail-value" id="modal-guest-name">—</span>
            </div>
            <div class="detail-row">
                <span class="detail-label">Room</span>
                <span class="detail-value" id="modal-room">—</span>
            </div>
            <div class="detail-row">
                <span class="detail-label">Check-In</span>
                <span class="detail-value" id="modal-checkin">—</span>
            </div>
            <div class="detail-row">
                <span class="detail-label">Check-Out</span>
                <span class="detail-value" id="modal-checkout">—</span>
            </div>
            <div class="detail-row">
                <span class="detail-label">Status</span>
                <span class="detail-value" id="modal-status">—</span>
            </div>
            <div class="detail-row">
                <span class="detail-label">Total Amount</span>
                <span class="detail-value" id="modal-amount">—</span>
            </div>
            <div class="modal-actions">
                <button class="topbar-btn btn-secondary" onclick="closeModal()">
                    <i class="fas fa-times"></i> Close
                </button>
                <a id="modal-view-link" href="#" class="topbar-btn btn-primary">
                    <i class="fas fa-external-link-alt"></i> Full Details
                </a>
            </div>
        </div>
    </div>
</div>

<script>
(function() {
    'use strict';

    /* ── SIDEBAR TOGGLE (mobile) ── */
    window.toggleSidebar = function() {
        document.getElementById('sidebar').classList.toggle('open');
        document.getElementById('sidebarOverlay').classList.toggle('open');
    };
    window.closeSidebar = function() {
        document.getElementById('sidebar').classList.remove('open');
        document.getElementById('sidebarOverlay').classList.remove('open');
    };

    /* ── RESERVATION DETAIL MODAL ── */
    window.viewReservation = function(id, guest, room, checkIn, checkOut, status, amount, resNum) {
        document.getElementById('modal-res-number').textContent = resNum || ('Reservation #' + id);
        document.getElementById('modal-guest-name').textContent = guest;
        document.getElementById('modal-room').textContent       = room;
        document.getElementById('modal-checkin').textContent    = checkIn;
        document.getElementById('modal-checkout').textContent   = checkOut;
        document.getElementById('modal-status').textContent     = status.replace(/_/g, ' ');
        document.getElementById('modal-amount').textContent     = 'Rs. ' + amount;
        document.getElementById('modal-view-link').href         = '<%= ctx %>/reservations?action=view&id=' + id;
        document.getElementById('reservationModal').classList.add('open');
        document.body.style.overflow = 'hidden';
    };

    window.closeModal = function() {
        document.getElementById('reservationModal').classList.remove('open');
        document.body.style.overflow = '';
    };

    /* Close on backdrop click */
    document.getElementById('reservationModal').addEventListener('click', function(e) {
        if (e.target === this) closeModal();
    });

    /* Close on Escape */
    document.addEventListener('keydown', function(e) {
        if (e.key === 'Escape') closeModal();
    });

    /* ── AUTO-DISMISS ALERTS after 5s ── */
    document.querySelectorAll('.alert').forEach(function(el) {
        setTimeout(function() {
            el.style.transition = 'opacity 0.5s';
            el.style.opacity = '0';
            setTimeout(function() { el.remove(); }, 500);
        }, 5000);
    });

    /* ── ANIMATE OCCUPANCY BAR on load ── */
    document.querySelectorAll('.occ-seg').forEach(function(seg) {
        var target = seg.style.width;
        seg.style.width = '0';
        setTimeout(function() { seg.style.width = target; }, 100);
    });

})();
</script>
</body>
</html>
