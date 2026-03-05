<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="com.oceanview.model.User" %>
<%@ page import="com.oceanview.model.Reservation" %>
<%@ page import="com.oceanview.util.Constants" %>
<%@ page import="java.util.List" %>
<%@ page import="java.time.format.DateTimeFormatter" %>
<%
    User currentUser = (User) session.getAttribute(Constants.SESSION_USER);
    if (currentUser == null || (!currentUser.isStaff() && !currentUser.isAdmin())) {
        response.sendRedirect(request.getContextPath() + "/login");
        return;
    }

    String ctx     = request.getContextPath();
    String error   = (String) request.getAttribute(Constants.ATTR_ERROR);
    String success = (String) request.getAttribute(Constants.ATTR_SUCCESS);

    List<Reservation> reservations = (List<Reservation>) request.getAttribute("reservations");
    if (reservations == null) reservations = java.util.Collections.emptyList();

    String statusFilter  = (String)  request.getAttribute("statusFilter");
    Integer totalCount   = (Integer) request.getAttribute("totalCount");     if (totalCount   == null) totalCount   = 0;
    Long pendingCount    = (Long)    request.getAttribute("pendingCount");    if (pendingCount    == null) pendingCount    = 0L;
    Long confirmedCount  = (Long)    request.getAttribute("confirmedCount");  if (confirmedCount  == null) confirmedCount  = 0L;
    Long checkedInCount  = (Long)    request.getAttribute("checkedInCount");  if (checkedInCount  == null) checkedInCount  = 0L;
    Long checkedOutCount = (Long)    request.getAttribute("checkedOutCount"); if (checkedOutCount == null) checkedOutCount = 0L;
    Long cancelledCount  = (Long)    request.getAttribute("cancelledCount");  if (cancelledCount  == null) cancelledCount  = 0L;

    DateTimeFormatter displayFmt = DateTimeFormatter.ofPattern("dd MMM yyyy");
    String staffName    = currentUser.getFullName() != null ? currentUser.getFullName() : currentUser.getUsername();
    String staffInitial = staffName.substring(0,1).toUpperCase();
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Reservations - Ocean View Resort</title>
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
    <style>
        /* ============================================================
           STAFF RESERVATIONS PAGE — FULLY SELF-CONTAINED EMBEDDED CSS
           ============================================================ */
        :root {
            --navy:        #0D2137;
            --ocean:       #1A6B8A;
            --ocean-light: #E8F4F8;
            --gold:        #D4AF37;
            --white:       #FFFFFF;
            --off-white:   #F5F7FA;
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
               background: var(--off-white); color: var(--text-dark); min-height: 100vh; display: flex; }

        /* ── SIDEBAR ── */
        .sidebar {
            width: var(--sidebar-w); min-height: 100vh; background: var(--navy);
            display: flex; flex-direction: column;
            position: fixed; left: 0; top: 0; z-index: 300;
            transition: transform var(--tr);
        }
        .sidebar-brand {
            padding: 20px 20px 16px; border-bottom: 1px solid rgba(255,255,255,0.08);
            display: flex; align-items: center; gap: 10px;
        }
        .sidebar-brand i   { color: var(--gold); font-size: 1.4rem; }
        .sidebar-brand span{ color: var(--white); font-size: 0.95rem; font-weight: 700; line-height: 1.2; }
        .sidebar-brand small{ color: rgba(255,255,255,0.45); font-size: 0.7rem; display: block; }
        .sidebar-nav { flex: 1; padding: 12px 0; overflow-y: auto; }
        .nav-section-label {
            padding: 14px 20px 6px; font-size: 0.65rem; font-weight: 700;
            text-transform: uppercase; letter-spacing: 1px; color: rgba(255,255,255,0.3);
        }
        .nav-item {
            display: flex; align-items: center; gap: 12px;
            padding: 11px 20px; margin: 2px 10px; border-radius: var(--radius-sm);
            color: rgba(255,255,255,0.65); font-size: 0.875rem; font-weight: 500;
            text-decoration: none; transition: background var(--tr), color var(--tr);
        }
        .nav-item:hover { background: rgba(255,255,255,0.08); color: var(--white); }
        .nav-item.active{ background: var(--ocean); color: var(--white); box-shadow: 0 2px 8px rgba(26,107,138,0.4); }
        .nav-item i { width: 18px; text-align: center; font-size: 0.9rem; }
        .nav-badge {
            margin-left: auto; background: var(--danger); color: var(--white);
            font-size: 0.7rem; font-weight: 700; padding: 2px 7px; border-radius: 10px; min-width: 20px; text-align: center;
        }
        .nav-badge.gold { background: var(--gold); color: var(--navy); }
        .sidebar-footer { padding: 16px 20px; border-top: 1px solid rgba(255,255,255,0.08); }
        .staff-card {
            display: flex; align-items: center; gap: 10px;
            padding: 10px 12px; border-radius: var(--radius-sm); background: rgba(255,255,255,0.06);
        }
        .staff-avatar {
            width: 36px; height: 36px; border-radius: 50%; background: var(--gold); color: var(--navy);
            display: flex; align-items: center; justify-content: center; font-weight: 700; font-size: 0.85rem; flex-shrink: 0;
        }
        .staff-name { color: var(--white); font-size: 0.82rem; font-weight: 600; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
        .staff-role { color: rgba(255,255,255,0.4); font-size: 0.7rem; }
        .sidebar-toggle {
            display: none; background: none; border: none;
            font-size: 1.2rem; color: var(--text-mid); cursor: pointer; padding: 4px;
        }
        .sidebar-overlay { display: none; position: fixed; inset: 0; z-index: 250; background: rgba(0,0,0,0.5); }

        /* ── MAIN ── */
        .main-area { margin-left: var(--sidebar-w); flex: 1; display: flex; flex-direction: column; min-width: 0; }

        /* ── TOPBAR ── */
        .topbar {
            height: var(--topbar-h); background: var(--white);
            border-bottom: 1px solid var(--border);
            display: flex; align-items: center; justify-content: space-between;
            padding: 0 28px; position: sticky; top: 0; z-index: 200; box-shadow: var(--shadow-sm);
        }
        .topbar-left { display: flex; align-items: center; gap: 12px; }
        .topbar-left h1 { font-size: 1.15rem; font-weight: 700; color: var(--text-dark); }
        .topbar-left p  { font-size: 0.78rem; color: var(--text-light); margin-top: 1px; }
        .topbar-right { display: flex; align-items: center; gap: 10px; }

        /* ── BUTTONS ── */
        .btn {
            display: inline-flex; align-items: center; gap: 6px;
            padding: 8px 16px; border-radius: var(--radius-sm);
            font-size: 0.82rem; font-weight: 500; cursor: pointer; border: none;
            transition: var(--tr); text-decoration: none; white-space: nowrap;
        }
        .btn-primary   { background: var(--ocean);   color: var(--white); }
        .btn-primary:hover   { background: var(--navy); }
        .btn-secondary { background: var(--off-white); color: var(--text-mid); border: 1px solid var(--border); }
        .btn-secondary:hover { background: var(--border); }
        .btn-success   { background: var(--success);  color: var(--white); }
        .btn-success:hover   { background: #276749; }
        .btn-danger    { background: var(--danger);   color: var(--white); }
        .btn-danger:hover    { background: #9B2C2C; }
        .btn-warning   { background: #D69E2E;          color: var(--white); }
        .btn-warning:hover   { background: var(--warning); }
        .btn-info      { background: var(--info);      color: var(--white); }
        .btn-info:hover      { background: #1A4A8A; }
        .btn-sm { padding: 5px 11px; font-size: 0.75rem; }

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

        /* ── STAT CHIPS ── */
        .stat-chips {
            display: flex; gap: 10px; flex-wrap: wrap; margin-bottom: 24px;
        }
        .stat-chip {
            display: flex; align-items: center; gap: 8px;
            padding: 10px 18px; border-radius: 24px;
            font-size: 0.82rem; font-weight: 600; cursor: pointer;
            border: 2px solid; transition: var(--tr); text-decoration: none;
        }
        .stat-chip .chip-count { font-size: 1.1rem; font-weight: 800; }
        .chip-all      { background: var(--off-white);  border-color: var(--border);      color: var(--text-mid); }
        .chip-all.active, .chip-all:hover { background: var(--navy); border-color: var(--navy); color: var(--white); }
        .chip-pending  { background: var(--warning-bg); border-color: var(--warning-bdr); color: var(--warning); }
        .chip-pending.active, .chip-pending:hover { background: var(--warning); border-color: var(--warning); color: var(--white); }
        .chip-confirmed{ background: var(--info-bg);    border-color: var(--info-bdr);    color: var(--info); }
        .chip-confirmed.active, .chip-confirmed:hover { background: var(--info); border-color: var(--info); color: var(--white); }
        .chip-checkedin{ background: var(--success-bg); border-color: var(--success-bdr); color: var(--success); }
        .chip-checkedin.active, .chip-checkedin:hover { background: var(--success); border-color: var(--success); color: var(--white); }
        .chip-checkedout{ background: var(--off-white); border-color: var(--border);      color: var(--text-mid); }
        .chip-checkedout.active, .chip-checkedout:hover { background: var(--text-mid); border-color: var(--text-mid); color: var(--white); }
        .chip-cancelled{ background: var(--danger-bg);  border-color: var(--danger-bdr);  color: var(--danger); }
        .chip-cancelled.active, .chip-cancelled:hover { background: var(--danger); border-color: var(--danger); color: var(--white); }

        /* ── TOOLBAR ── */
        .toolbar {
            display: flex; align-items: center; justify-content: space-between;
            gap: 12px; flex-wrap: wrap; margin-bottom: 18px;
        }
        .search-box {
            display: flex; align-items: center; gap: 0;
            border: 1.5px solid var(--border); border-radius: var(--radius-sm);
            background: var(--white); overflow: hidden; flex: 1; max-width: 360px;
        }
        .search-box i { padding: 0 12px; color: var(--text-light); font-size: 0.85rem; }
        .search-box input {
            flex: 1; border: none; outline: none; padding: 9px 0;
            font-size: 0.875rem; color: var(--text-dark); background: transparent;
        }
        .search-box input::placeholder { color: var(--text-light); }
        .toolbar-right { display: flex; gap: 8px; flex-wrap: wrap; }

        /* ── MAIN CARD ── */
        .main-card {
            background: var(--white); border-radius: var(--radius-md);
            border: 1px solid var(--border); box-shadow: var(--shadow-sm); overflow: hidden;
        }
        .card-head {
            display: flex; align-items: center; justify-content: space-between;
            padding: 16px 20px; border-bottom: 1px solid var(--border);
            background: linear-gradient(to right, #f8fbfd, var(--white));
        }
        .card-head-left { display: flex; align-items: center; gap: 10px; }
        .card-icon {
            width: 36px; height: 36px; border-radius: var(--radius-sm);
            background: var(--ocean-light); color: var(--ocean);
            display: flex; align-items: center; justify-content: center; font-size: 0.9rem;
        }
        .card-title { font-size: 0.9rem; font-weight: 700; color: var(--text-dark); }
        .card-sub   { font-size: 0.72rem; color: var(--text-light); }

        /* ── TABLE ── */
        .table-wrap { overflow-x: auto; }
        table { width: 100%; border-collapse: collapse; min-width: 900px; }
        thead th {
            padding: 11px 16px; text-align: left;
            font-size: 0.71rem; font-weight: 700;
            text-transform: uppercase; letter-spacing: 0.5px;
            color: var(--text-light); background: var(--off-white);
            border-bottom: 1px solid var(--border); white-space: nowrap;
        }
        thead th.chk { width: 40px; }
        tbody td {
            padding: 13px 16px; font-size: 0.82rem;
            color: var(--text-mid); border-bottom: 1px solid var(--border);
            vertical-align: middle;
        }
        tbody tr:last-child td { border-bottom: none; }
        tbody tr:hover td { background: #FAFCFF; }
        tbody tr.hidden-row { display: none; }

        /* ── GUEST CELL ── */
        .guest-cell { display: flex; align-items: center; gap: 10px; }
        .g-avatar {
            width: 32px; height: 32px; border-radius: 50%; flex-shrink: 0;
            background: var(--ocean-light); color: var(--ocean);
            display: flex; align-items: center; justify-content: center;
            font-weight: 700; font-size: 0.78rem;
        }
        .g-name { font-weight: 600; color: var(--text-dark); font-size: 0.82rem; }
        .g-ref  { font-size: 0.7rem; color: var(--text-light); margin-top: 1px; }

        /* ── ROOM CELL ── */
        .room-cell { font-weight: 600; color: var(--text-dark); }
        .room-type { font-size: 0.7rem; color: var(--text-light); }

        /* ── DATE CELL ── */
        .date-cell { white-space: nowrap; }
        .nights-badge {
            display: inline-block; background: var(--ocean-light);
            color: var(--ocean); font-size: 0.68rem; font-weight: 600;
            padding: 1px 6px; border-radius: 8px; margin-top: 2px;
        }

        /* ── AMOUNT CELL ── */
        .amount-val { font-weight: 700; color: var(--text-dark); }
        .amount-disc{ font-size: 0.7rem; color: var(--success); }

        /* ── BADGES ── */
        .badge {
            display: inline-flex; align-items: center; gap: 4px;
            padding: 3px 10px; border-radius: 12px;
            font-size: 0.71rem; font-weight: 600; white-space: nowrap;
        }
        .badge-dot { width: 6px; height: 6px; border-radius: 50%; flex-shrink: 0; }
        .badge-pending     { background: var(--warning-bg); color: var(--warning); border: 1px solid var(--warning-bdr); }
        .badge-pending .badge-dot { background: var(--warning); }
        .badge-confirmed   { background: var(--info-bg);    color: var(--info);    border: 1px solid var(--info-bdr); }
        .badge-confirmed .badge-dot { background: var(--info); }
        .badge-checked-in  { background: var(--success-bg); color: var(--success); border: 1px solid var(--success-bdr); }
        .badge-checked-in .badge-dot { background: var(--success); }
        .badge-checked-out { background: var(--off-white);  color: var(--text-mid); border: 1px solid var(--border); }
        .badge-checked-out .badge-dot { background: var(--text-light); }
        .badge-cancelled   { background: var(--danger-bg);  color: var(--danger);  border: 1px solid var(--danger-bdr); }
        .badge-cancelled .badge-dot { background: var(--danger); }

        /* ── ACTION BUTTONS ── */
        .action-col { display: flex; gap: 5px; flex-wrap: wrap; }

        /* ── EMPTY STATE ── */
        .empty-state {
            padding: 60px 24px; text-align: center; color: var(--text-light);
        }
        .empty-state i { font-size: 2.5rem; margin-bottom: 12px; display: block; opacity: 0.35; }
        .empty-state h3 { font-size: 1rem; margin-bottom: 6px; color: var(--text-mid); }
        .empty-state p  { font-size: 0.85rem; }

        /* ── CHECKBOX ── */
        input[type=checkbox] { width: 15px; height: 15px; cursor: pointer; accent-color: var(--ocean); }

        /* ── MODAL ── */
        .modal-backdrop {
            display: none; position: fixed; inset: 0; z-index: 500;
            background: rgba(0,0,0,0.55); align-items: center; justify-content: center; padding: 24px;
        }
        .modal-backdrop.open { display: flex; }
        .modal-box {
            background: var(--white); border-radius: var(--radius-md);
            box-shadow: var(--shadow-lg); width: 100%; max-width: 560px;
            max-height: 90vh; overflow-y: auto; animation: slideUp 0.25s ease;
        }
        .modal-head {
            display: flex; align-items: center; justify-content: space-between;
            padding: 18px 22px;
            color: var(--white);
        }
        .modal-head.blue   { background: linear-gradient(135deg, var(--navy), var(--ocean)); }
        .modal-head.green  { background: linear-gradient(135deg, #276749, #38A169); }
        .modal-head.orange { background: linear-gradient(135deg, #744210, #D69E2E); }
        .modal-head.red    { background: linear-gradient(135deg, #9B2C2C, var(--danger)); }
        .modal-head-title  { display: flex; align-items: center; gap: 10px; font-size: 0.95rem; font-weight: 600; }
        .modal-close-btn {
            background: rgba(255,255,255,0.15); border: none; color: var(--white);
            width: 30px; height: 30px; border-radius: 50%; cursor: pointer;
            display: flex; align-items: center; justify-content: center;
            font-size: 1rem; transition: background var(--tr);
        }
        .modal-close-btn:hover { background: rgba(255,255,255,0.3); }
        .modal-body { padding: 22px; }
        .detail-row {
            display: flex; justify-content: space-between; align-items: center;
            padding: 10px 0; border-bottom: 1px solid var(--border); font-size: 0.85rem;
        }
        .detail-row:last-child { border-bottom: none; }
        .detail-label { color: var(--text-light); font-weight: 500; }
        .detail-value { color: var(--text-dark); font-weight: 600; text-align: right; }
        .modal-actions { display: flex; gap: 10px; margin-top: 20px; flex-wrap: wrap; }
        .modal-warning {
            display: flex; align-items: flex-start; gap: 10px;
            padding: 12px 16px; border-radius: var(--radius-sm);
            background: var(--danger-bg); border: 1px solid var(--danger-bdr);
            color: var(--danger); font-size: 0.85rem; margin-bottom: 18px;
        }

        @keyframes slideUp { from { transform: translateY(30px); opacity: 0; } to { transform: translateY(0); opacity: 1; } }

        /* ── RESPONSIVE ── */
        @media (max-width: 768px) {
            .sidebar { transform: translateX(-100%); }
            .sidebar.open { transform: translateX(0); }
            .sidebar-overlay.open { display: block; }
            .main-area { margin-left: 0; }
            .sidebar-toggle { display: block; }
            .page-content { padding: 16px; }
            .topbar { padding: 0 16px; }
            .stat-chips { gap: 6px; }
            .stat-chip  { padding: 7px 12px; font-size: 0.75rem; }
        }
    </style>
</head>
<body>

<div class="sidebar-overlay" id="sidebarOverlay" onclick="closeSidebar()"></div>

<!-- ── SIDEBAR ── -->
<aside class="sidebar" id="sidebar">
    <div class="sidebar-brand">
        <i class="fas fa-hotel"></i>
        <div><span>Ocean View<br>Resort</span><small>Staff Portal</small></div>
    </div>
    <nav class="sidebar-nav">
        <div class="nav-section-label">Main</div>
        <a href="<%= ctx %>/dashboard"          class="nav-item"><i class="fas fa-th-large"></i> Dashboard</a>
        <a href="<%= ctx %>/staff/reservations" class="nav-item active">
            <i class="fas fa-calendar-alt"></i> Reservations
            <% if (pendingCount > 0) { %><span class="nav-badge gold"><%= pendingCount %></span><% } %>
        </a>
        <a href="<%= ctx %>/staff/checkin"      class="nav-item"><i class="fas fa-sign-in-alt"></i> Check-In</a>
        <a href="<%= ctx %>/staff/checkout"     class="nav-item"><i class="fas fa-sign-out-alt"></i> Check-Out</a>
        <a href="<%= ctx %>/logout"             class="nav-item"><i class="fas fa-power-off"></i> Logout</a>
    </nav>
    <div class="sidebar-footer">
        <div class="staff-card">
            <div class="staff-avatar"><%= staffInitial %></div>
            <div>
                <div class="staff-name"><%= staffName %></div>
                <div class="staff-role"><%= currentUser.getRole() %></div>
            </div>
        </div>
    </div>
</aside>

<!-- ── MAIN ── -->
<div class="main-area">

    <!-- TOPBAR -->
    <header class="topbar">
        <div class="topbar-left">
            <button class="sidebar-toggle" onclick="toggleSidebar()"><i class="fas fa-bars"></i></button>
            <div>
                <h1>Reservations</h1>
                <p><%= totalCount %> total &bull; <%= reservations.size() %> showing</p>
            </div>
        </div>
        <div class="topbar-right">
            <a href="<%= ctx %>/reservations?action=new&source=staff" class="btn btn-primary">
                <i class="fas fa-plus"></i> New Booking
            </a>
            <a href="<%= ctx %>/dashboard" class="btn btn-secondary">
                <i class="fas fa-arrow-left"></i> Dashboard
            </a>
            <a href="<%= ctx %>/logout" class="btn btn-secondary">
                <i class="fas fa-sign-out-alt"></i> Logout
            </a>
        </div>
    </header>

    <!-- PAGE CONTENT -->
    <div class="page-content">

        <!-- ALERTS -->
        <% if (error != null && !error.isEmpty()) { %>
        <div class="alert alert-danger"><i class="fas fa-exclamation-circle"></i><span><%= error %></span></div>
        <% } %>
        <% if (success != null && !success.isEmpty()) { %>
        <div class="alert alert-success"><i class="fas fa-check-circle"></i><span><%= success %></span></div>
        <% } %>

        <!-- STATUS CHIPS / FILTER BAR -->
        <div class="stat-chips">
            <a href="<%= ctx %>/staff/reservations"
               class="stat-chip chip-all <%= (statusFilter == null || statusFilter.isEmpty()) ? "active" : "" %>">
                <span class="chip-count"><%= totalCount %></span> All
            </a>
            <a href="<%= ctx %>/staff/reservations?status=PENDING"
               class="stat-chip chip-pending <%= "PENDING".equals(statusFilter) ? "active" : "" %>">
                <i class="fas fa-clock"></i>
                <span class="chip-count"><%= pendingCount %></span> Pending
            </a>
            <a href="<%= ctx %>/staff/reservations?status=CONFIRMED"
               class="stat-chip chip-confirmed <%= "CONFIRMED".equals(statusFilter) ? "active" : "" %>">
                <i class="fas fa-check"></i>
                <span class="chip-count"><%= confirmedCount %></span> Confirmed
            </a>
            <a href="<%= ctx %>/staff/reservations?status=CHECKED_IN"
               class="stat-chip chip-checkedin <%= "CHECKED_IN".equals(statusFilter) ? "active" : "" %>">
                <i class="fas fa-sign-in-alt"></i>
                <span class="chip-count"><%= checkedInCount %></span> Checked In
            </a>
            <a href="<%= ctx %>/staff/reservations?status=CHECKED_OUT"
               class="stat-chip chip-checkedout <%= "CHECKED_OUT".equals(statusFilter) ? "active" : "" %>">
                <i class="fas fa-sign-out-alt"></i>
                <span class="chip-count"><%= checkedOutCount %></span> Checked Out
            </a>
            <a href="<%= ctx %>/staff/reservations?status=CANCELLED"
               class="stat-chip chip-cancelled <%= "CANCELLED".equals(statusFilter) ? "active" : "" %>">
                <i class="fas fa-times"></i>
                <span class="chip-count"><%= cancelledCount %></span> Cancelled
            </a>
        </div>

        <!-- TOOLBAR -->
        <div class="toolbar">
            <div class="search-box">
                <i class="fas fa-search"></i>
                <input type="text" id="searchInput" placeholder="Search guest, room, booking number..." oninput="filterTable()">
            </div>
            <div class="toolbar-right">
                <button class="btn btn-secondary btn-sm" onclick="toggleSelectAll()">
                    <i class="fas fa-check-square"></i> Select All
                </button>
                <button class="btn btn-danger btn-sm" id="bulkCancelBtn" style="display:none;" onclick="bulkCancel()">
                    <i class="fas fa-times"></i> Cancel Selected
                </button>
            </div>
        </div>

        <!-- RESERVATIONS TABLE -->
        <div class="main-card">
            <div class="card-head">
                <div class="card-head-left">
                    <div class="card-icon"><i class="fas fa-calendar-alt"></i></div>
                    <div>
                        <div class="card-title">
                            <%= (statusFilter != null && !statusFilter.isEmpty()) ? statusFilter.replace("_"," ") : "All" %> Reservations
                        </div>
                        <div class="card-sub"><%= reservations.size() %> records</div>
                    </div>
                </div>
            </div>

            <div class="table-wrap">
                <% if (reservations.isEmpty()) { %>
                <div class="empty-state">
                    <i class="fas fa-calendar-times"></i>
                    <h3>No reservations found</h3>
                    <p><%= (statusFilter != null && !statusFilter.isEmpty()) ? "No " + statusFilter.replace("_"," ").toLowerCase() + " reservations." : "No reservations in the system yet." %></p>
                </div>
                <% } else { %>
                <table id="resTable">
                    <thead>
                        <tr>
                            <th class="chk"><input type="checkbox" id="selectAllChk" onchange="onSelectAllChange()"></th>
                            <th>Booking #</th>
                            <th>Guest</th>
                            <th>Room</th>
                            <th>Check-In</th>
                            <th>Check-Out</th>
                            <th>Guests</th>
                            <th>Amount</th>
                            <th>Status</th>
                            <th>Actions</th>
                        </tr>
                    </thead>
                    <tbody>
                    <% for (Reservation r : reservations) {
                        String gName   = r.getGuestName()   != null ? r.getGuestName()   : "Guest #" + r.getGuestId();
                        String roomNum = r.getRoomNumber()  != null ? r.getRoomNumber()  : "#" + r.getRoomId();
                        String roomType= (r.getRoom() != null && r.getRoom().getRoomType() != null)
                                        ? r.getRoom().getRoomType().name() : "";
                        String ci      = r.getCheckInDate()  != null ? r.getCheckInDate().format(displayFmt)  : "—";
                        String co      = r.getCheckOutDate() != null ? r.getCheckOutDate().format(displayFmt) : "—";
                        String amt     = r.getFinalAmount()  != null ? String.format("Rs. %.2f", r.getFinalAmount()) : "—";
                        String disc    = (r.getDiscountAmount() != null && r.getDiscountAmount().compareTo(java.math.BigDecimal.ZERO) > 0)
                                        ? String.format("-Rs. %.2f", r.getDiscountAmount()) : "";
                        String resNum  = r.getReservationNumber() != null ? r.getReservationNumber() : "#" + r.getReservationId();
                        String init    = gName.substring(0,1).toUpperCase();
                        int nights     = r.getNumberOfNights() != null ? r.getNumberOfNights() : 0;
                        String status  = r.getStatus().name();
                        String badgeCls= "badge-" + status.toLowerCase().replace("_","-");
                        String statusLabel = status.replace("_"," ");
                        // safe strings for JS
                        String gNameJs = gName.replace("'","\\'");
                        String resNumJs = resNum.replace("'","\\'");
                    %>
                        <tr data-search="<%= (gName + " " + roomNum + " " + resNum).toLowerCase() %>">
                            <td class="chk"><input type="checkbox" class="row-chk" value="<%= r.getReservationId() %>" onchange="onRowCheck()"></td>
                            <td>
                                <div style="font-weight:700;color:var(--text-dark);font-size:0.82rem;"><%= resNum %></div>
                                <div style="font-size:0.68rem;color:var(--text-light);">ID: <%= r.getReservationId() %></div>
                            </td>
                            <td>
                                <div class="guest-cell">
                                    <div class="g-avatar"><%= init %></div>
                                    <div>
                                        <div class="g-name"><%= gName %></div>
                                        <div class="g-ref"><%= resNum %></div>
                                    </div>
                                </div>
                            </td>
                            <td>
                                <div class="room-cell">Room <%= roomNum %></div>
                                <% if (!roomType.isEmpty()) { %><div class="room-type"><%= roomType %></div><% } %>
                            </td>
                            <td class="date-cell">
                                <%= ci %>
                                <div><span class="nights-badge"><%= nights %> night<%= nights != 1 ? "s" : "" %></span></div>
                            </td>
                            <td class="date-cell"><%= co %></td>
                            <td style="text-align:center;font-weight:600;"><%= r.getNumberOfGuests() %></td>
                            <td>
                                <div class="amount-val"><%= amt %></div>
                                <% if (!disc.isEmpty()) { %><div class="amount-disc"><%= disc %> disc.</div><% } %>
                            </td>
                            <td>
                                <span class="badge <%= badgeCls %>">
                                    <span class="badge-dot"></span><%= statusLabel %>
                                </span>
                            </td>
                            <td>
                                <div class="action-col">
                                    <!-- VIEW -->
                                    <button class="btn btn-secondary btn-sm"
                                            onclick="openViewModal(<%= r.getReservationId() %>,'<%= gNameJs %>','Room <%= roomNum %>','<%= ci %>','<%= co %>','<%= status %>','<%= amt %>','<%= resNumJs %>',<%= nights %>,'<%= r.getNumberOfGuests() %>')"
                                            title="View Details">
                                        <i class="fas fa-eye"></i>
                                    </button>
                                    <!-- CONFIRM -->
                                    <% if (r.isPending()) { %>
                                    <form action="<%= ctx %>/staff/reservations" method="post" style="display:inline;">
                                        <input type="hidden" name="action" value="confirm">
                                        <input type="hidden" name="reservationId" value="<%= r.getReservationId() %>">
                                        <button type="submit" class="btn btn-info btn-sm" title="Confirm"
                                                onclick="return confirm('Confirm reservation <%= resNumJs %>?')">
                                            <i class="fas fa-check"></i>
                                        </button>
                                    </form>
                                    <% } %>
                                    <!-- CHECK-IN -->
                                    <% if (r.canCheckIn()) { %>
                                    <form action="<%= ctx %>/staff/reservations" method="post" style="display:inline;">
                                        <input type="hidden" name="action" value="checkin">
                                        <input type="hidden" name="reservationId" value="<%= r.getReservationId() %>">
                                        <button type="submit" class="btn btn-success btn-sm" title="Check In"
                                                onclick="return confirm('Check in guest for <%= resNumJs %>?')">
                                            <i class="fas fa-sign-in-alt"></i>
                                        </button>
                                    </form>
                                    <% } %>
                                    <!-- CHECK-OUT -->
                                    <% if (r.canCheckOut()) { %>
                                    <form action="<%= ctx %>/staff/reservations" method="post" style="display:inline;">
                                        <input type="hidden" name="action" value="checkout">
                                        <input type="hidden" name="reservationId" value="<%= r.getReservationId() %>">
                                        <button type="submit" class="btn btn-warning btn-sm" title="Check Out"
                                                onclick="return confirm('Check out guest for <%= resNumJs %>?')">
                                            <i class="fas fa-sign-out-alt"></i>
                                        </button>
                                    </form>
                                    <% } %>
                                    <!-- CANCEL -->
                                    <% if (r.canCancel()) { %>
                                    <button class="btn btn-danger btn-sm" title="Cancel"
                                            onclick="openCancelModal(<%= r.getReservationId() %>,'<%= resNumJs %>','<%= gNameJs %>')">
                                        <i class="fas fa-times"></i>
                                    </button>
                                    <% } %>
                                </div>
                            </td>
                        </tr>
                    <% } %>
                    </tbody>
                </table>
                <% } %>
            </div>
        </div><!-- /main-card -->

    </div><!-- /page-content -->
</div><!-- /main-area -->

<!-- ── VIEW MODAL ── -->
<div id="viewModal" class="modal-backdrop">
    <div class="modal-box">
        <div class="modal-head blue">
            <div class="modal-head-title"><i class="fas fa-calendar-check"></i> <span id="vm-resnum">Details</span></div>
            <button class="modal-close-btn" onclick="closeModal('viewModal')">&times;</button>
        </div>
        <div class="modal-body">
            <div class="detail-row"><span class="detail-label">Guest</span><span class="detail-value" id="vm-guest"></span></div>
            <div class="detail-row"><span class="detail-label">Room</span><span class="detail-value" id="vm-room"></span></div>
            <div class="detail-row"><span class="detail-label">Check-In</span><span class="detail-value" id="vm-ci"></span></div>
            <div class="detail-row"><span class="detail-label">Check-Out</span><span class="detail-value" id="vm-co"></span></div>
            <div class="detail-row"><span class="detail-label">Nights</span><span class="detail-value" id="vm-nights"></span></div>
            <div class="detail-row"><span class="detail-label">Guests</span><span class="detail-value" id="vm-guests"></span></div>
            <div class="detail-row"><span class="detail-label">Status</span><span class="detail-value" id="vm-status"></span></div>
            <div class="detail-row"><span class="detail-label">Total Amount</span><span class="detail-value" id="vm-amount"></span></div>
            <div class="modal-actions">
                <button class="btn btn-secondary" onclick="closeModal('viewModal')"><i class="fas fa-times"></i> Close</button>
            </div>
        </div>
    </div>
</div>

<!-- ── CANCEL MODAL ── -->
<div id="cancelModal" class="modal-backdrop">
    <div class="modal-box">
        <div class="modal-head red">
            <div class="modal-head-title"><i class="fas fa-exclamation-triangle"></i> Cancel Reservation</div>
            <button class="modal-close-btn" onclick="closeModal('cancelModal')">&times;</button>
        </div>
        <div class="modal-body">
            <div class="modal-warning">
                <i class="fas fa-exclamation-circle" style="flex-shrink:0;margin-top:1px;"></i>
                <span>You are about to cancel reservation <strong id="cm-resnum"></strong> for <strong id="cm-guest"></strong>. This cannot be undone.</span>
            </div>
            <form id="cancelForm" action="<%= ctx %>/staff/reservations" method="post">
                <input type="hidden" name="action" value="cancel">
                <input type="hidden" name="id" id="cm-id">
                <div class="modal-actions">
                    <button type="submit" class="btn btn-danger"><i class="fas fa-times"></i> Yes, Cancel It</button>
                    <button type="button" class="btn btn-secondary" onclick="closeModal('cancelModal')">Keep Reservation</button>
                </div>
            </form>
        </div>
    </div>
</div>

<script>
(function() {
    'use strict';

    /* ── SIDEBAR ── */
    window.toggleSidebar = function() {
        document.getElementById('sidebar').classList.toggle('open');
        document.getElementById('sidebarOverlay').classList.toggle('open');
    };
    window.closeSidebar = function() {
        document.getElementById('sidebar').classList.remove('open');
        document.getElementById('sidebarOverlay').classList.remove('open');
    };

    /* ── CLIENT-SIDE SEARCH FILTER ── */
    window.filterTable = function() {
        var term = document.getElementById('searchInput').value.toLowerCase().trim();
        var rows = document.querySelectorAll('#resTable tbody tr');
        var visible = 0;
        rows.forEach(function(row) {
            var data = row.getAttribute('data-search') || '';
            if (!term || data.indexOf(term) !== -1) {
                row.classList.remove('hidden-row');
                visible++;
            } else {
                row.classList.add('hidden-row');
            }
        });
    };

    /* ── SELECT ALL ── */
    window.toggleSelectAll = function() {
        var chks = document.querySelectorAll('.row-chk');
        var anyUnchecked = Array.from(chks).some(function(c) { return !c.checked; });
        chks.forEach(function(c) { c.checked = anyUnchecked; });
        document.getElementById('selectAllChk').checked = anyUnchecked;
        updateBulkBtn();
    };
    window.onSelectAllChange = function() {
        var all = document.getElementById('selectAllChk').checked;
        document.querySelectorAll('.row-chk').forEach(function(c) { c.checked = all; });
        updateBulkBtn();
    };
    window.onRowCheck = function() {
        var chks = document.querySelectorAll('.row-chk');
        var allChecked = Array.from(chks).every(function(c) { return c.checked; });
        document.getElementById('selectAllChk').checked = allChecked;
        updateBulkBtn();
    };
    function updateBulkBtn() {
        var any = Array.from(document.querySelectorAll('.row-chk')).some(function(c) { return c.checked; });
        document.getElementById('bulkCancelBtn').style.display = any ? '' : 'none';
    }
    window.bulkCancel = function() {
        var ids = Array.from(document.querySelectorAll('.row-chk:checked')).map(function(c) { return c.value; });
        if (!ids.length) return;
        if (!confirm('Cancel ' + ids.length + ' selected reservation(s)? This cannot be undone.')) return;
        // POST each cancel sequentially via form
        ids.forEach(function(id) {
            var f = document.createElement('form');
            f.method = 'post';
            f.action = '<%= ctx %>/staff/reservations';
            f.style.display = 'none';
            var a = document.createElement('input'); a.type='hidden'; a.name='action'; a.value='cancel'; f.appendChild(a);
            var i = document.createElement('input'); i.type='hidden'; i.name='id'; i.value=id; f.appendChild(i);
            document.body.appendChild(f);
            f.submit();
        });
    };

    /* ── MODALS ── */
    window.openViewModal = function(id, guest, room, ci, co, status, amount, resnum, nights, guests) {
        document.getElementById('vm-resnum').textContent  = resnum;
        document.getElementById('vm-guest').textContent   = guest;
        document.getElementById('vm-room').textContent    = room;
        document.getElementById('vm-ci').textContent      = ci;
        document.getElementById('vm-co').textContent      = co;
        document.getElementById('vm-nights').textContent  = nights + ' night' + (nights !== 1 ? 's' : '');
        document.getElementById('vm-guests').textContent  = guests;
        document.getElementById('vm-status').textContent  = status.replace(/_/g,' ');
        document.getElementById('vm-amount').textContent  = amount;
        openModal('viewModal');
    };
    window.openCancelModal = function(id, resnum, guest) {
        document.getElementById('cm-id').value             = id;
        document.getElementById('cm-resnum').textContent   = resnum;
        document.getElementById('cm-guest').textContent    = guest;
        openModal('cancelModal');
    };
    window.openModal = function(id) {
        document.getElementById(id).classList.add('open');
        document.body.style.overflow = 'hidden';
    };
    window.closeModal = function(id) {
        document.getElementById(id).classList.remove('open');
        document.body.style.overflow = '';
    };

    /* close on backdrop click */
    document.querySelectorAll('.modal-backdrop').forEach(function(b) {
        b.addEventListener('click', function(e) { if (e.target === b) closeModal(b.id); });
    });
    /* close on Escape */
    document.addEventListener('keydown', function(e) {
        if (e.key === 'Escape')
            document.querySelectorAll('.modal-backdrop.open').forEach(function(m) { closeModal(m.id); });
    });

    /* ── AUTO-DISMISS ALERTS ── */
    document.querySelectorAll('.alert').forEach(function(el) {
        setTimeout(function() {
            el.style.transition = 'opacity 0.5s';
            el.style.opacity = '0';
            setTimeout(function() { el.remove(); }, 500);
        }, 5000);
    });

})();
</script>
</body>
</html>
