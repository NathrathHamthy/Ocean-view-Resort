<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="com.oceanview.model.User, com.oceanview.model.Reservation, com.oceanview.util.Constants, java.util.List, java.time.format.DateTimeFormatter, java.time.temporal.ChronoUnit" %>
<%!
    // Safe cast helper – avoids ClassCastException / NPE on Long attributes
    private long safeLong(Object obj) { return obj instanceof Number ? ((Number)obj).longValue() : 0L; }
    // Safe XSS escape
    private String esc(String s) { return s == null ? "" : s.replace("&","&amp;").replace("<","&lt;").replace(">","&gt;"); }
    // Title-case first letter only
    private String titleCase(String s) {
        if (s == null || s.isEmpty()) return s;
        String lower = s.toLowerCase();
        return Character.toUpperCase(lower.charAt(0)) + lower.substring(1);
    }
%>
<%
    User currentUser = (User) session.getAttribute(Constants.SESSION_USER);
    if (currentUser == null) currentUser = (User) session.getAttribute("loggedInUser");
    if (currentUser == null) { response.sendRedirect(request.getContextPath() + "/login"); return; }

    String ctx = request.getContextPath();

    @SuppressWarnings("unchecked")
    List<Reservation> reservations = (List<Reservation>) request.getAttribute("reservations");

    // Flash messages – servlet puts them in request attributes after removing from session
    String successMsg = (String) request.getAttribute(Constants.ATTR_SUCCESS);
    String errorMsg   = (String) request.getAttribute(Constants.ATTR_ERROR);
    // Also check session-level in case of direct JSP access
    if (successMsg == null) { successMsg = (String) session.getAttribute(Constants.ATTR_SUCCESS); session.removeAttribute(Constants.ATTR_SUCCESS); }
    if (errorMsg   == null) { errorMsg   = (String) session.getAttribute(Constants.ATTR_ERROR);   session.removeAttribute(Constants.ATTR_ERROR);   }

    // Safe stat counts – servlet sets these as long (autoboxed to Long)
    long pendingCount   = safeLong(request.getAttribute("pendingCount"));
    long confirmedCount = safeLong(request.getAttribute("confirmedCount"));
    long checkedInCount = safeLong(request.getAttribute("checkedInCount"));
    long completedCount = safeLong(request.getAttribute("completedCount"));
    long cancelledCount = safeLong(request.getAttribute("cancelledCount"));
    long totalCount     = reservations != null ? reservations.size() : 0;

    DateTimeFormatter dtf = DateTimeFormatter.ofPattern("dd MMM yyyy");

    // Currency from app settings (fall back to Rs.)
    String currencySymbol = "Rs.";
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>My Reservations - Ocean View Resort</title>
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
    <style>
        :root {
            --ocean-blue:   #006994;
            --ocean-mid:    #4A90A4;
            --ocean-dark:   #003d5c;
            --ocean-light:  #e8f4f8;
            --sand:         #F5E6D3;
            --white:        #ffffff;
            --gray-50:      #f8f9fa;
            --gray-100:     #f1f3f5;
            --gray-200:     #e9ecef;
            --gray-500:     #6c757d;
            --gray-700:     #495057;
            --gray-900:     #212529;
            --success:      #28a745;
            --warning:      #f0a500;
            --danger:       #dc3545;
            --info:         #17a2b8;
            --purple:       #6f42c1;
            --radius-sm:    6px;
            --radius-md:    10px;
            --radius-lg:    16px;
            --shadow-sm:    0 1px 3px rgba(0,0,0,.08);
            --shadow-md:    0 4px 12px rgba(0,0,0,.10);
            --shadow-lg:    0 8px 24px rgba(0,0,0,.12);
            --transition:   .25s ease;
        }
        *, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }
        body {
            font-family: 'Segoe UI', system-ui, sans-serif;
            background: var(--gray-50);
            color: var(--gray-900);
            min-height: 100vh;
        }

        /* ── NAVBAR ── */
        .navbar {
            background: var(--white);
            box-shadow: var(--shadow-sm);
            position: sticky; top: 0; z-index: 200;
        }
        .nav-inner {
            max-width: 1280px; margin: 0 auto;
            padding: 0 2rem;
            height: 64px;
            display: flex; align-items: center; justify-content: space-between;
        }
        .brand { display: flex; align-items: center; gap: .6rem; text-decoration: none; }
        .brand-icon {
            width: 36px; height: 36px; border-radius: 8px;
            background: linear-gradient(135deg, var(--ocean-blue), var(--ocean-dark));
            display: flex; align-items: center; justify-content: center;
            color: #fff; font-size: 1rem;
        }
        .brand-name { font-size: 1.1rem; font-weight: 700; color: var(--ocean-dark); }
        .nav-links { display: flex; gap: 1.8rem; list-style: none; }
        .nav-links a {
            text-decoration: none; color: var(--gray-500); font-size: .9rem;
            font-weight: 500; padding: .3rem 0;
            border-bottom: 2px solid transparent; transition: var(--transition);
        }
        .nav-links a:hover, .nav-links a.active {
            color: var(--ocean-blue);
            border-bottom-color: var(--ocean-blue);
        }
        .nav-right { display: flex; align-items: center; gap: 1rem; }
        .avatar {
            width: 36px; height: 36px; border-radius: 50%;
            background: linear-gradient(135deg, var(--ocean-blue), var(--ocean-mid));
            color: #fff; font-weight: 700; font-size: .9rem;
            display: flex; align-items: center; justify-content: center;
        }
        .btn-logout {
            padding: .4rem 1rem; border-radius: var(--radius-sm);
            background: transparent; border: 1.5px solid var(--ocean-blue);
            color: var(--ocean-blue); font-size: .85rem; font-weight: 600;
            cursor: pointer; text-decoration: none; transition: var(--transition);
        }
        .btn-logout:hover { background: var(--ocean-blue); color: #fff; }

        /* ── PAGE HEADER ── */
        .page-hero {
            background: linear-gradient(135deg, var(--ocean-dark) 0%, var(--ocean-blue) 60%, var(--ocean-mid) 100%);
            padding: 2.5rem 2rem;
            color: #fff;
        }
        .page-hero-inner {
            max-width: 1280px; margin: 0 auto;
            display: flex; justify-content: space-between; align-items: center; flex-wrap: wrap; gap: 1rem;
        }
        .page-hero h1 { font-size: 1.8rem; font-weight: 700; }
        .page-hero p  { font-size: .95rem; opacity: .85; margin-top: .3rem; }
        .btn-book {
            display: inline-flex; align-items: center; gap: .5rem;
            padding: .65rem 1.4rem; border-radius: var(--radius-sm);
            background: #fff; color: var(--ocean-dark);
            font-weight: 700; font-size: .9rem; text-decoration: none;
            transition: var(--transition); border: none; cursor: pointer;
        }
        .btn-book:hover { background: var(--sand); transform: translateY(-1px); }

        /* ── MAIN LAYOUT ── */
        .page-body {
            max-width: 1280px; margin: 0 auto;
            padding: 2rem;
        }

        /* ── FLASH MESSAGES ── */
        .alert {
            padding: .9rem 1.2rem; border-radius: var(--radius-md);
            margin-bottom: 1.5rem; display: flex; align-items: center; gap: .7rem;
            font-size: .92rem; font-weight: 500;
        }
        .alert-success { background: #d4edda; color: #155724; border: 1px solid #c3e6cb; }
        .alert-error   { background: #f8d7da; color: #721c24; border: 1px solid #f5c6cb; }

        /* ── SUMMARY STATS ── */
        .stats-row {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(140px, 1fr));
            gap: 1rem; margin-bottom: 2rem;
        }
        .stat-box {
            background: var(--white); border-radius: var(--radius-md);
            padding: 1.1rem 1.2rem; box-shadow: var(--shadow-sm);
            display: flex; flex-direction: column; gap: .3rem;
            border-left: 4px solid transparent; cursor: pointer; transition: var(--transition);
        }
        .stat-box:hover { transform: translateY(-2px); box-shadow: var(--shadow-md); }
        .stat-box.all     { border-color: var(--ocean-blue); }
        .stat-box.pending { border-color: var(--warning); }
        .stat-box.confirmed { border-color: var(--info); }
        .stat-box.checked-in { border-color: var(--success); }
        .stat-box.completed  { border-color: var(--purple); }
        .stat-box.cancelled  { border-color: var(--danger); }
        .stat-num { font-size: 1.8rem; font-weight: 800; color: var(--ocean-dark); }
        .stat-lbl { font-size: .78rem; color: var(--gray-500); font-weight: 600; text-transform: uppercase; letter-spacing: .04em; }

        /* ── FILTER TABS ── */
        .filter-bar {
            display: flex; align-items: center; gap: .5rem;
            flex-wrap: wrap; margin-bottom: 1.5rem;
        }
        .tab-btn {
            padding: .5rem 1.1rem; border-radius: 30px;
            border: 1.5px solid var(--gray-200);
            background: var(--white); color: var(--gray-500);
            font-size: .85rem; font-weight: 600; cursor: pointer;
            transition: var(--transition);
        }
        .tab-btn:hover { border-color: var(--ocean-blue); color: var(--ocean-blue); }
        .tab-btn.active {
            background: var(--ocean-blue); color: #fff;
            border-color: var(--ocean-blue);
        }
        .sort-wrap { margin-left: auto; display: flex; align-items: center; gap: .5rem; }
        .sort-wrap label { font-size: .85rem; color: var(--gray-500); }
        .sort-wrap select {
            padding: .4rem .8rem; border-radius: var(--radius-sm);
            border: 1.5px solid var(--gray-200); font-size: .85rem;
            color: var(--gray-700); background: var(--white); cursor: pointer;
        }

        /* ── RESERVATION CARD ── */
        .reservations-list { display: flex; flex-direction: column; gap: 1.2rem; }
        .res-card {
            background: var(--white); border-radius: var(--radius-lg);
            box-shadow: var(--shadow-sm); overflow: hidden;
            display: flex; transition: var(--transition);
            border: 1.5px solid var(--gray-200);
        }
        .res-card:hover { box-shadow: var(--shadow-md); transform: translateY(-2px); }

        /* coloured left stripe by status */
        .res-card.status-PENDING    { border-left: 5px solid var(--warning); }
        .res-card.status-CONFIRMED  { border-left: 5px solid var(--info); }
        .res-card.status-CHECKED_IN { border-left: 5px solid var(--success); }
        .res-card.status-CHECKED_OUT{ border-left: 5px solid var(--purple); }
        .res-card.status-CANCELLED  { border-left: 5px solid var(--danger); opacity: .75; }

        .res-img-wrap {
            width: 220px; min-height: 180px; flex-shrink: 0;
            position: relative; overflow: hidden;
        }
        .res-img-wrap img {
            width: 100%; height: 100%; object-fit: cover;
            transition: transform .4s ease;
        }
        .res-card:hover .res-img-wrap img { transform: scale(1.05); }
        .res-img-placeholder {
            width: 100%; height: 100%; min-height: 180px;
            background: linear-gradient(135deg, var(--ocean-light), var(--ocean-mid));
            display: flex; align-items: center; justify-content: center;
            font-size: 3rem; color: rgba(255,255,255,.6);
        }

        .res-body { flex: 1; padding: 1.4rem 1.6rem; display: flex; flex-direction: column; gap: .9rem; }

        .res-head {
            display: flex; justify-content: space-between; align-items: flex-start; flex-wrap: wrap; gap: .5rem;
        }
        .res-title { font-size: 1.1rem; font-weight: 700; color: var(--ocean-dark); }
        .res-num   { font-size: .82rem; color: var(--gray-500); margin-top: .15rem; }

        .status-badge {
            padding: .3rem .9rem; border-radius: 30px;
            font-size: .78rem; font-weight: 700; text-transform: uppercase; letter-spacing: .05em;
        }
        .badge-PENDING    { background: #fff3cd; color: #856404; }
        .badge-CONFIRMED  { background: #d1ecf1; color: #0c5460; }
        .badge-CHECKED_IN { background: #d4edda; color: #155724; }
        .badge-CHECKED_OUT{ background: #e2d9f3; color: #432874; }
        .badge-CANCELLED  { background: #f8d7da; color: #721c24; }

        .res-meta {
            display: grid; grid-template-columns: repeat(auto-fit, minmax(130px, 1fr)); gap: .7rem;
        }
        .meta-item { display: flex; align-items: center; gap: .5rem; font-size: .88rem; }
        .meta-item i { color: var(--ocean-blue); width: 16px; text-align: center; }
        .meta-label { display: block; font-size: .74rem; color: var(--gray-500); font-weight: 600; text-transform: uppercase; }
        .meta-val   { display: block; font-weight: 600; color: var(--gray-700); }

        .res-footer {
            display: flex; align-items: center; justify-content: space-between; flex-wrap: wrap; gap: .7rem;
            padding-top: .7rem; border-top: 1px solid var(--gray-200);
        }
        .res-price .amount { font-size: 1.35rem; font-weight: 800; color: var(--ocean-dark); }
        .res-price .period { font-size: .8rem; color: var(--gray-500); }
        .res-price .final-note { font-size: .78rem; color: var(--gray-500); display: block; }

        .actions { display: flex; gap: .6rem; flex-wrap: wrap; }
        .btn {
            display: inline-flex; align-items: center; gap: .4rem;
            padding: .45rem 1rem; border-radius: var(--radius-sm);
            font-size: .84rem; font-weight: 600; cursor: pointer;
            border: none; text-decoration: none; transition: var(--transition);
        }
        .btn-primary  { background: var(--ocean-blue); color: #fff; }
        .btn-primary:hover  { background: var(--ocean-dark); }
        .btn-success  { background: var(--success); color: #fff; }
        .btn-success:hover  { background: #1e7e34; }
        .btn-warning  { background: var(--warning); color: #fff; }
        .btn-warning:hover  { background: #c58800; }
        .btn-danger   { background: transparent; color: var(--danger); border: 1.5px solid var(--danger); }
        .btn-danger:hover   { background: var(--danger); color: #fff; }
        .btn-secondary{ background: var(--gray-100); color: var(--gray-700); border: 1.5px solid var(--gray-200); }
        .btn-secondary:hover{ background: var(--gray-200); }
        .btn-info     { background: var(--info); color: #fff; }
        .btn-info:hover     { background: #138496; }
        .btn:disabled { opacity: .5; cursor: not-allowed; }

        .special-req {
            background: var(--gray-50); border-left: 3px solid var(--ocean-mid);
            padding: .5rem .8rem; border-radius: 0 var(--radius-sm) var(--radius-sm) 0;
            font-size: .84rem; color: var(--gray-700);
        }
        .special-req strong { color: var(--ocean-dark); }

        /* ── EMPTY STATE ── */
        .empty-state {
            text-align: center; padding: 5rem 2rem;
            background: var(--white); border-radius: var(--radius-lg);
            box-shadow: var(--shadow-sm);
        }
        .empty-state .empty-icon {
            width: 80px; height: 80px; border-radius: 50%;
            background: var(--ocean-light);
            display: flex; align-items: center; justify-content: center;
            margin: 0 auto 1.2rem;
            font-size: 2rem; color: var(--ocean-blue);
        }
        .empty-state h2 { color: var(--ocean-dark); margin-bottom: .5rem; }
        .empty-state p  { color: var(--gray-500); margin-bottom: 1.5rem; }

        /* ── MODALS (cancel + details) ── */
        .modal-overlay {
            display: none; position: fixed; inset: 0;
            background: rgba(0,0,0,.55); z-index: 500;
            align-items: center; justify-content: center;
            padding: 1rem;
        }
        .modal-overlay.open { display: flex; }
        .modal-box {
            background: #fff; border-radius: var(--radius-lg);
            padding: 2rem; width: 100%; max-width: 420px;
            box-shadow: var(--shadow-lg); animation: popIn .2s ease;
        }
        @keyframes popIn {
            from { transform: scale(.92); opacity: 0; }
            to   { transform: scale(1);  opacity: 1; }
        }
        .modal-box h3 { font-size: 1.1rem; color: var(--ocean-dark); margin-bottom: .5rem; }
        .modal-box p  { font-size: .9rem; color: var(--gray-500); margin-bottom: 1.4rem; }
        .modal-actions { display: flex; gap: .7rem; justify-content: flex-end; }

        /* ── DETAILS MODAL ── */
        .details-modal-box {
            background: #fff; border-radius: var(--radius-lg);
            width: 100%; max-width: 720px; max-height: 90vh;
            overflow-y: auto; box-shadow: var(--shadow-lg);
            animation: popIn .2s ease; display: flex; flex-direction: column;
        }
        .dm-header {
            position: relative;
            height: 220px; flex-shrink: 0; overflow: hidden;
            border-radius: var(--radius-lg) var(--radius-lg) 0 0;
        }
        .dm-header img {
            width: 100%; height: 100%; object-fit: cover;
        }
        .dm-header-placeholder {
            width: 100%; height: 100%;
            background: linear-gradient(135deg, var(--ocean-dark), var(--ocean-mid));
            display: flex; align-items: center; justify-content: center;
            font-size: 4rem; color: rgba(255,255,255,.5);
        }
        .dm-header-overlay {
            position: absolute; inset: 0;
            background: linear-gradient(to top, rgba(0,0,0,.65) 0%, transparent 55%);
            display: flex; align-items: flex-end;
            padding: 1.2rem 1.4rem;
        }
        .dm-header-overlay h2 {
            color: #fff; font-size: 1.4rem; font-weight: 800;
            text-shadow: 0 1px 4px rgba(0,0,0,.4);
        }
        .dm-header-overlay .dm-res-num {
            color: rgba(255,255,255,.8); font-size: .82rem;
            margin-top: .2rem;
        }
        .dm-close {
            position: absolute; top: .8rem; right: .9rem;
            width: 32px; height: 32px; border-radius: 50%;
            background: rgba(0,0,0,.45); border: none;
            color: #fff; font-size: 1rem; cursor: pointer;
            display: flex; align-items: center; justify-content: center;
            transition: background .2s;
        }
        .dm-close:hover { background: rgba(0,0,0,.7); }
        .dm-body { padding: 1.5rem; display: flex; flex-direction: column; gap: 1.4rem; }
        .dm-status-row {
            display: flex; align-items: center; gap: .8rem; flex-wrap: wrap;
        }
        .dm-section-title {
            font-size: .72rem; font-weight: 700; text-transform: uppercase;
            letter-spacing: .07em; color: var(--ocean-blue);
            margin-bottom: .6rem; display: flex; align-items: center; gap: .4rem;
        }
        .dm-grid {
            display: grid; grid-template-columns: repeat(auto-fit, minmax(150px, 1fr));
            gap: .8rem;
        }
        .dm-item {
            background: var(--gray-50); border-radius: var(--radius-md);
            padding: .7rem .9rem;
        }
        .dm-item .lbl { font-size: .72rem; color: var(--gray-500); font-weight: 600; text-transform: uppercase; display: block; margin-bottom: .2rem; }
        .dm-item .val { font-size: .95rem; font-weight: 700; color: var(--gray-900); }
        .dm-desc {
            background: var(--gray-50); border-radius: var(--radius-md);
            padding: .9rem 1rem; font-size: .88rem; color: var(--gray-700); line-height: 1.6;
        }
        .dm-amenities { display: flex; flex-wrap: wrap; gap: .5rem; }
        .dm-amenity-chip {
            background: var(--ocean-light); color: var(--ocean-dark);
            padding: .3rem .8rem; border-radius: 30px;
            font-size: .8rem; font-weight: 600;
            display: inline-flex; align-items: center; gap: .35rem;
        }
        .dm-billing {
            background: var(--gray-50); border-radius: var(--radius-md); overflow: hidden;
        }
        .dm-billing-row {
            display: flex; justify-content: space-between;
            padding: .6rem 1rem; font-size: .9rem; border-bottom: 1px solid var(--gray-200);
        }
        .dm-billing-row:last-child { border-bottom: none; }
        .dm-billing-row.total-row {
            font-weight: 800; font-size: 1rem;
            background: var(--ocean-light); color: var(--ocean-dark);
        }
        .dm-special {
            background: #fff8e1; border-left: 3px solid var(--warning);
            padding: .7rem 1rem; border-radius: 0 var(--radius-sm) var(--radius-sm) 0;
            font-size: .88rem; color: var(--gray-700); line-height: 1.5;
        }
        .dm-footer {
            padding: 1rem 1.5rem; border-top: 1px solid var(--gray-200);
            display: flex; gap: .7rem; justify-content: flex-end; flex-wrap: wrap;
            background: var(--white);
        }
        @media (max-width: 600px) {
            .dm-header { height: 160px; }
            .details-modal-box { max-height: 95vh; }
            .dm-body { padding: 1rem; }
            .dm-footer { padding: .8rem 1rem; }
        }

        /* ── TOAST ── */
        .toast-container { position: fixed; bottom: 1.5rem; right: 1.5rem; z-index: 600; display: flex; flex-direction: column; gap: .5rem; }
        .toast {
            padding: .8rem 1.2rem; border-radius: var(--radius-md);
            font-size: .88rem; font-weight: 600; color: #fff;
            box-shadow: var(--shadow-md); animation: slideIn .3s ease;
            display: flex; align-items: center; gap: .6rem;
        }
        @keyframes slideIn { from { transform: translateX(100%); opacity: 0; } to { transform: translateX(0); opacity: 1; } }
        .toast.success { background: var(--success); }
        .toast.error   { background: var(--danger); }

        /* ── RESPONSIVE ── */
        @media (max-width: 768px) {
            .res-card { flex-direction: column; }
            .res-img-wrap { width: 100%; height: 180px; }
            .res-img-placeholder { min-height: 180px; }
            .nav-links { display: none; }
            .sort-wrap { margin-left: 0; width: 100%; }
            .stats-row { grid-template-columns: repeat(3, 1fr); }
        }
        @media (max-width: 480px) {
            .page-body { padding: 1rem; }
            .stats-row { grid-template-columns: repeat(2, 1fr); }
            .res-body  { padding: 1rem; }
        }
    </style>
</head>
<body>

<!-- NAVBAR -->
<nav class="navbar">
    <div class="nav-inner">
        <a href="<%= ctx %>/guest/home" class="brand">
            <div class="brand-icon"><i class="fas fa-hotel"></i></div>
            <span class="brand-name">Ocean View Resort</span>
        </a>
        <ul class="nav-links">
            <li><a href="<%= ctx %>/guest/home">Home</a></li>
            <li><a href="<%= ctx %>/rooms">Browse Rooms</a></li>
            <li><a href="<%= ctx %>/reservation" class="active">My Reservations</a></li>
            <li><a href="<%= ctx %>/review">My Reviews</a></li>
            <li><a href="<%= ctx %>/guest/profile">Profile</a></li>
        </ul>
        <div class="nav-right">
            <div class="avatar"><%= (currentUser.getFullName() != null && !currentUser.getFullName().isEmpty()) ? currentUser.getFullName().substring(0,1).toUpperCase() : "G" %></div>
            <span style="font-size:.88rem;font-weight:600;color:var(--gray-700);"><%= esc(currentUser.getFirstName() != null ? currentUser.getFirstName() : currentUser.getUsername()) %></span>
            <a href="<%= ctx %>/logout" class="btn-logout"><i class="fas fa-sign-out-alt"></i> Logout</a>
        </div>
    </div>
</nav>

<!-- PAGE HERO -->
<div class="page-hero">
    <div class="page-hero-inner">
        <div>
            <h1><i class="fas fa-calendar-alt"></i> My Reservations</h1>
            <p>Manage all your bookings in one place</p>
        </div>
        <a href="<%= ctx %>/rooms" class="btn-book">
            <i class="fas fa-plus"></i> New Booking
        </a>
    </div>
</div>

<div class="page-body">

    <!-- FLASH MESSAGES -->
    <% if (successMsg != null) { %>
    <div class="alert alert-success"><i class="fas fa-check-circle"></i> <%= successMsg %></div>
    <% } %>
    <% if (errorMsg != null) { %>
    <div class="alert alert-error"><i class="fas fa-exclamation-circle"></i> <%= errorMsg %></div>
    <% } %>

    <!-- STATS SUMMARY -->
    <div class="stats-row">
        <div class="stat-box all" onclick="filterCards('all')">
            <span class="stat-num"><%= totalCount %></span>
            <span class="stat-lbl">Total</span>
        </div>
        <div class="stat-box pending" onclick="filterCards('PENDING')">
            <span class="stat-num"><%= pendingCount %></span>
            <span class="stat-lbl">Pending</span>
        </div>
        <div class="stat-box confirmed" onclick="filterCards('CONFIRMED')">
            <span class="stat-num"><%= confirmedCount %></span>
            <span class="stat-lbl">Confirmed</span>
        </div>
        <div class="stat-box checked-in" onclick="filterCards('CHECKED_IN')">
            <span class="stat-num"><%= checkedInCount %></span>
            <span class="stat-lbl">Checked In</span>
        </div>
        <div class="stat-box completed" onclick="filterCards('CHECKED_OUT')">
            <span class="stat-num"><%= completedCount %></span>
            <span class="stat-lbl">Completed</span>
        </div>
        <div class="stat-box cancelled" onclick="filterCards('CANCELLED')">
            <span class="stat-num"><%= cancelledCount %></span>
            <span class="stat-lbl">Cancelled</span>
        </div>
    </div>

    <!-- FILTER TABS + SORT -->
    <div class="filter-bar">
        <button class="tab-btn active" data-filter="all">All</button>
        <button class="tab-btn" data-filter="PENDING">Pending</button>
        <button class="tab-btn" data-filter="CONFIRMED">Confirmed</button>
        <button class="tab-btn" data-filter="CHECKED_IN">Checked In</button>
        <button class="tab-btn" data-filter="CHECKED_OUT">Completed</button>
        <button class="tab-btn" data-filter="CANCELLED">Cancelled</button>
        <div class="sort-wrap">
            <label for="sortSel"><i class="fas fa-sort"></i> Sort:</label>
            <select id="sortSel" onchange="sortCards(this.value)">
                <option value="newest">Newest First</option>
                <option value="oldest">Oldest First</option>
                <option value="checkin">Check-in Date</option>
                <option value="amount">Amount (High-Low)</option>
            </select>
        </div>
    </div>

    <!-- RESERVATIONS LIST -->
    <% if (reservations == null || reservations.isEmpty()) { %>
    <div class="empty-state">
        <div class="empty-icon"><i class="fas fa-calendar-times"></i></div>
        <h2>No Reservations Yet</h2>
        <p>You haven't made any bookings. Explore our beautiful rooms and make your first reservation!</p>
        <a href="<%= ctx %>/rooms" class="btn btn-primary" style="font-size:1rem;padding:.7rem 1.8rem;">
            <i class="fas fa-bed"></i> Browse Rooms
        </a>
    </div>
    <% } else { %>
    <div class="reservations-list" id="reservationsList">
    <%
        for (Reservation r : reservations) {
            // Null-safe status
            String status = (r.getStatus() != null) ? r.getStatus().name() : "PENDING";

            // Null-safe room info
            String roomType = (r.getRoom() != null && r.getRoom().getRoomType() != null)
                              ? r.getRoom().getRoomType().name() : "STANDARD";
            String roomNum  = (r.getRoom() != null && r.getRoom().getRoomNumber() != null)
                              ? r.getRoom().getRoomNumber()
                              : (r.getRoomId() != null && r.getRoomId() > 0 ? String.valueOf(r.getRoomId()) : "—");

            // Null-safe dates
            String checkIn  = r.getCheckInDate()  != null ? r.getCheckInDate().format(dtf)  : "—";
            String checkOut = r.getCheckOutDate() != null ? r.getCheckOutDate().format(dtf) : "—";

            // Null-safe nights/guests
            int nights = 0;
            if (r.getNumberOfNights() != null && r.getNumberOfNights() > 0) {
                nights = r.getNumberOfNights();
            } else if (r.getCheckInDate() != null && r.getCheckOutDate() != null) {
                nights = (int) ChronoUnit.DAYS.between(r.getCheckInDate(), r.getCheckOutDate());
            }
            int guests = r.getNumberOfGuests() != null ? r.getNumberOfGuests() : 1;

            // Null-safe amounts
            String total   = r.getFinalAmount()  != null ? String.format("%,.2f", r.getFinalAmount())  : "0.00";
            String baseAmt = r.getTotalAmount()  != null ? String.format("%,.2f", r.getTotalAmount())  : "0.00";

            // Null-safe reservation number
            String resNum = (r.getReservationNumber() != null && !r.getReservationNumber().isEmpty())
                            ? r.getReservationNumber()
                            : "RES-" + (r.getReservationId() != null ? r.getReservationId() : 0);

            int resId = r.getReservationId() != null ? r.getReservationId() : 0;

            // Image path: use DB image_url first, then fallback to type-based asset
            String dbImgUrl  = (r.getRoom() != null && r.getRoom().getImageUrl() != null && !r.getRoom().getImageUrl().isEmpty())
                               ? r.getRoom().getImageUrl() : null;
            String imgPath   = (dbImgUrl != null)
                               ? (dbImgUrl.startsWith("http") ? dbImgUrl : ctx + "/" + dbImgUrl)
                               : ctx + "/assets/images/rooms/" + roomType.toLowerCase() + ".jpg";
            String roomLabel = titleCase(roomType);

            // Details popup data
            String descText  = (r.getRoom() != null && r.getRoom().getDescription() != null)
                               ? esc(r.getRoom().getDescription()) : "";
            String amenText  = (r.getRoom() != null && r.getRoom().getAmenities() != null)
                               ? esc(r.getRoom().getAmenities()) : "";
            String priceNight = (r.getRoom() != null && r.getRoom().getPricePerNight() != null)
                               ? String.format("%,.2f", r.getRoom().getPricePerNight()) : "—";
            String discAmt   = r.getDiscountAmount() != null && r.getDiscountAmount().compareTo(java.math.BigDecimal.ZERO) > 0
                               ? String.format("%,.2f", r.getDiscountAmount()) : null;
            String taxAmt    = r.getTaxAmount() != null ? String.format("%,.2f", r.getTaxAmount()) : "0.00";
            String createdStr = r.getCreatedAt() != null
                               ? r.getCreatedAt().format(java.time.format.DateTimeFormatter.ofPattern("dd MMM yyyy, HH:mm")) : "—";
    %>
    <div class="res-card status-<%= status %>"
         data-status="<%= status %>"
         data-checkin="<%= r.getCheckInDate()  != null ? r.getCheckInDate().toString()  : "" %>"
         data-amount="<%= r.getFinalAmount()   != null ? r.getFinalAmount().doubleValue() : 0 %>"
         data-created="<%= r.getCreatedAt()    != null ? r.getCreatedAt().toString()     : "" %>"
         data-resid="<%= resId %>"
         data-resnum="<%= esc(resNum) %>"
         data-roomlabel="<%= roomLabel %>"
         data-roomnum="<%= esc(roomNum) %>"
         data-roomtype="<%= roomType %>"
         data-imgpath="<%= imgPath %>"
         data-checkinstr="<%= esc(checkIn) %>"
         data-checkoutstr="<%= esc(checkOut) %>"
         data-nights="<%= nights %>"
         data-guests="<%= guests %>"
         data-floor="<%= (r.getRoom() != null && r.getRoom().getFloor() != null) ? r.getRoom().getFloor() : 0 %>"
         data-size="<%= (r.getRoom() != null && r.getRoom().getSize() != null) ? r.getRoom().getSize() : 0 %>"
         data-price-night="<%= priceNight %>"
         data-total="<%= total %>"
         data-base="<%= baseAmt %>"
         data-discount="<%= discAmt != null ? discAmt : "" %>"
         data-tax="<%= taxAmt %>"
         data-desc="<%= descText %>"
         data-amenities="<%= amenText %>"
         data-special="<%= r.getSpecialRequests() != null ? esc(r.getSpecialRequests().trim()) : "" %>"
         data-created-str="<%= esc(createdStr) %>"
         data-status-label="<%= status.replace("_", " ") %>"
         data-currency="<%= currencySymbol %>">

        <!-- Room Image -->
        <div class="res-img-wrap">
            <img src="<%= imgPath %>" alt="<%= roomType %>"
                 onerror="this.style.display='none';this.nextElementSibling.style.display='flex';">
            <div class="res-img-placeholder" style="display:none;">
                <i class="fas fa-bed"></i>
            </div>
        </div>

        <!-- Card Body -->
        <div class="res-body">
            <!-- Header row -->
            <div class="res-head">
                <div>
                    <div class="res-title"><%= roomLabel %> Room &mdash; #<%= roomNum %></div>
                    <div class="res-num"><i class="fas fa-hashtag" style="font-size:.7rem;"></i> <%= resNum %></div>
                </div>
                <span class="status-badge badge-<%= status %>"><%= status.replace("_", " ") %></span>
            </div>

            <!-- Meta details grid -->
            <div class="res-meta">
                <div class="meta-item">
                    <i class="fas fa-sign-in-alt"></i>
                    <div>
                        <span class="meta-label">Check-in</span>
                        <span class="meta-val"><%= checkIn %></span>
                    </div>
                </div>
                <div class="meta-item">
                    <i class="fas fa-sign-out-alt"></i>
                    <div>
                        <span class="meta-label">Check-out</span>
                        <span class="meta-val"><%= checkOut %></span>
                    </div>
                </div>
                <div class="meta-item">
                    <i class="fas fa-moon"></i>
                    <div>
                        <span class="meta-label">Nights</span>
                        <span class="meta-val"><%= nights %> night<%= nights != 1 ? "s" : "" %></span>
                    </div>
                </div>
                <div class="meta-item">
                    <i class="fas fa-users"></i>
                    <div>
                        <span class="meta-label">Guests</span>
                        <span class="meta-val"><%= guests %> guest<%= guests != 1 ? "s" : "" %></span>
                    </div>
                </div>
                <% if (r.getRoom() != null && r.getRoom().getFloor() != null && r.getRoom().getFloor() > 0) { %>
                <div class="meta-item">
                    <i class="fas fa-layer-group"></i>
                    <div>
                        <span class="meta-label">Floor</span>
                        <span class="meta-val">Floor <%= r.getRoom().getFloor() %></span>
                    </div>
                </div>
                <% } %>
                <% if (r.getRoom() != null && r.getRoom().getSize() != null && r.getRoom().getSize() > 0) { %>
                <div class="meta-item">
                    <i class="fas fa-ruler-combined"></i>
                    <div>
                        <span class="meta-label">Size</span>
                        <span class="meta-val"><%= r.getRoom().getSize() %> m&sup2;</span>
                    </div>
                </div>
                <% } %>
            </div>

            <!-- Special requests -->
            <% if (r.getSpecialRequests() != null && !r.getSpecialRequests().trim().isEmpty()) { %>
            <div class="special-req">
                <strong><i class="fas fa-comment-dots"></i> Special Requests:</strong>
                <%= r.getSpecialRequests() %>
            </div>
            <% } %>

            <!-- Footer: price + action buttons -->
            <div class="res-footer">
                <div class="res-price">
                    <span class="amount"><%= currencySymbol %> <%= total %></span>
                    <span class="period"> total</span>
                    <span class="final-note">Base: <%= currencySymbol %> <%= baseAmt %> &bull; incl. tax &amp; service charge</span>
                </div>
                <div class="actions">
                    <!-- Cancel: PENDING or CONFIRMED -->
                    <% if ("PENDING".equals(status) || "CONFIRMED".equals(status)) { %>
                    <button class="btn btn-danger"
                            data-resid="<%= resId %>"
                            data-resnum="<%= resNum.replace("'", "\\'") %>"
                            onclick="openCancelModal(this.dataset.resid, this.dataset.resnum)">
                        <i class="fas fa-times-circle"></i> Cancel
                    </button>
                    <% } %>

                    <!-- Write review + invoice: CHECKED_OUT -->
                    <% if ("CHECKED_OUT".equals(status)) { %>
                    <a href="<%= ctx %>/review?action=create&reservationId=<%= resId %>" class="btn btn-success">
                        <i class="fas fa-star"></i> Write Review
                    </a>
                    <a href="<%= ctx %>/billing?action=invoice&reservationId=<%= resId %>" class="btn btn-secondary">
                        <i class="fas fa-file-invoice"></i> Invoice
                    </a>
                    <% } %>

                    <!-- Details popup button (always shown) -->
                    <button class="btn btn-info" onclick="openDetailsModal(this.closest('.res-card'))">
                        <i class="fas fa-eye"></i> Details
                    </button>
                </div>
            </div>
        </div><!-- /res-body -->
    </div><!-- /res-card -->
    <% } %>
    </div><!-- /reservations-list -->
    <% } %>

</div><!-- /page-body -->

<!-- CANCEL CONFIRMATION MODAL -->
<div class="modal-overlay" id="cancelModal">
    <div class="modal-box">
        <h3><i class="fas fa-exclamation-triangle" style="color:var(--danger);margin-right:.4rem;"></i>Cancel Reservation</h3>
        <p id="cancelModalText">Are you sure you want to cancel this reservation? This cannot be undone.</p>
        <div class="modal-actions">
            <button class="btn btn-secondary" onclick="closeCancelModal()">
                <i class="fas fa-arrow-left"></i> Keep It
            </button>
            <button class="btn btn-danger" id="confirmCancelBtn" onclick="doCancel()">
                <i class="fas fa-times-circle"></i> Yes, Cancel
            </button>
        </div>
    </div>
</div>

<!-- RESERVATION DETAILS MODAL -->
<div class="modal-overlay" id="detailsModal">
    <div class="details-modal-box">
        <!-- Header: room image + title overlay -->
        <div class="dm-header" id="dmHeader">
            <img id="dmImg" src="" alt="Room" onerror="this.style.display='none';document.getElementById('dmImgPlaceholder').style.display='flex';">
            <div class="dm-header-placeholder" id="dmImgPlaceholder" style="display:none;">
                <i class="fas fa-bed"></i>
            </div>
            <div class="dm-header-overlay">
                <div>
                    <h2 id="dmTitle"></h2>
                    <div class="dm-res-num" id="dmResNum"></div>
                </div>
            </div>
            <button class="dm-close" onclick="closeDetailsModal()" title="Close"><i class="fas fa-times"></i></button>
        </div>

        <!-- Body -->
        <div class="dm-body">

            <!-- Status + booking ref -->
            <div class="dm-status-row">
                <span id="dmStatusBadge" class="status-badge"></span>
                <span style="font-size:.83rem;color:var(--gray-500);">Booked on <strong id="dmCreated"></strong></span>
            </div>

            <!-- Stay details -->
            <div>
                <div class="dm-section-title"><i class="fas fa-calendar-alt"></i> Stay Details</div>
                <div class="dm-grid">
                    <div class="dm-item"><span class="lbl">Check-in</span><span class="val" id="dmCheckin"></span></div>
                    <div class="dm-item"><span class="lbl">Check-out</span><span class="val" id="dmCheckout"></span></div>
                    <div class="dm-item"><span class="lbl">Duration</span><span class="val" id="dmNights"></span></div>
                    <div class="dm-item"><span class="lbl">Guests</span><span class="val" id="dmGuests"></span></div>
                </div>
            </div>

            <!-- Room details -->
            <div>
                <div class="dm-section-title"><i class="fas fa-door-open"></i> Room Details</div>
                <div class="dm-grid" id="dmRoomGrid">
                    <div class="dm-item"><span class="lbl">Room Type</span><span class="val" id="dmRoomType"></span></div>
                    <div class="dm-item"><span class="lbl">Room Number</span><span class="val" id="dmRoomNum"></span></div>
                    <div class="dm-item" id="dmFloorItem"><span class="lbl">Floor</span><span class="val" id="dmFloor"></span></div>
                    <div class="dm-item" id="dmSizeItem"><span class="lbl">Size</span><span class="val" id="dmSize"></span></div>
                    <div class="dm-item"><span class="lbl">Rate / Night</span><span class="val" id="dmPriceNight"></span></div>
                </div>
            </div>

            <!-- Description -->
            <div id="dmDescSection">
                <div class="dm-section-title"><i class="fas fa-info-circle"></i> About This Room</div>
                <div class="dm-desc" id="dmDesc"></div>
            </div>

            <!-- Amenities -->
            <div id="dmAmenSection">
                <div class="dm-section-title"><i class="fas fa-star"></i> Amenities</div>
                <div class="dm-amenities" id="dmAmenities"></div>
            </div>

            <!-- Special requests -->
            <div id="dmSpecialSection">
                <div class="dm-section-title"><i class="fas fa-comment-dots"></i> Special Requests</div>
                <div class="dm-special" id="dmSpecial"></div>
            </div>

            <!-- Billing breakdown -->
            <div>
                <div class="dm-section-title"><i class="fas fa-receipt"></i> Billing Summary</div>
                <div class="dm-billing">
                    <div class="dm-billing-row"><span>Base Amount</span><span id="dmBase"></span></div>
                    <div class="dm-billing-row" id="dmDiscountRow"><span>Discount</span><span id="dmDiscount"></span></div>
                    <div class="dm-billing-row"><span>Tax &amp; Service Charge</span><span id="dmTax"></span></div>
                    <div class="dm-billing-row total-row"><span>Total Payable</span><span id="dmTotal"></span></div>
                </div>
            </div>

        </div><!-- /dm-body -->

        <!-- Footer actions -->
        <div class="dm-footer" id="dmFooter"></div>
    </div>
</div>

<!-- TOAST CONTAINER -->
<div class="toast-container" id="toastContainer"></div>

<script>
const ctx = '<%= ctx %>';
let cancelTargetId = null;

/* ─── FILTER ─── */
function filterCards(status) {
    document.querySelectorAll('.tab-btn').forEach(b =>
        b.classList.toggle('active', b.dataset.filter === status));
    document.querySelectorAll('.res-card').forEach(card => {
        card.style.display = (status === 'all' || card.dataset.status === status) ? 'flex' : 'none';
    });
    checkEmpty();
}

document.querySelectorAll('.tab-btn').forEach(btn => {
    btn.addEventListener('click', function () {
        document.querySelectorAll('.tab-btn').forEach(b => b.classList.remove('active'));
        this.classList.add('active');
        filterCards(this.dataset.filter);
    });
});

function checkEmpty() {
    const list = document.getElementById('reservationsList');
    if (!list) return;
    const visible = [...list.querySelectorAll('.res-card')].filter(c => c.style.display !== 'none');
    let msg = document.getElementById('filterEmptyMsg');
    if (visible.length === 0) {
        if (!msg) {
            msg = document.createElement('div');
            msg.id = 'filterEmptyMsg';
            msg.className = 'empty-state';
            msg.innerHTML = '<div class="empty-icon"><i class="fas fa-filter"></i></div><h2>No Results</h2><p>No reservations match this filter.</p>';
            list.after(msg);
        }
    } else if (msg) {
        msg.remove();
    }
}

/* ─── SORT ─── */
function sortCards(by) {
    const list = document.getElementById('reservationsList');
    if (!list) return;
    const cards = [...list.querySelectorAll('.res-card')];
    cards.sort((a, b) => {
        const ciA = a.dataset.checkin || '';
        const ciB = b.dataset.checkin || '';
        const amA = parseFloat(a.dataset.amount || 0);
        const amB = parseFloat(b.dataset.amount || 0);
        const crA = a.dataset.created || '';
        const crB = b.dataset.created || '';
        if (by === 'checkin')  return ciA.localeCompare(ciB);
        if (by === 'amount')   return amB - amA;
        if (by === 'oldest')   return crA.localeCompare(crB);
        if (by === 'newest')   return crB.localeCompare(crA);
        return crB.localeCompare(crA); // default: newest first
    });
    cards.forEach(c => list.appendChild(c));
}

/* ─── CANCEL MODAL ─── */
function openCancelModal(resId, resNum) {
    cancelTargetId = resId;
    document.getElementById('cancelModalText').textContent =
        'Are you sure you want to cancel reservation ' + resNum + '? This action cannot be undone.';
    const btn = document.getElementById('confirmCancelBtn');
    btn.disabled = false;
    btn.innerHTML = '<i class="fas fa-times-circle"></i> Yes, Cancel';
    document.getElementById('cancelModal').classList.add('open');
}

function closeCancelModal() {
    document.getElementById('cancelModal').classList.remove('open');
    cancelTargetId = null;
}

document.getElementById('cancelModal').addEventListener('click', e => {
    if (e.target === document.getElementById('cancelModal')) closeCancelModal();
});
document.addEventListener('keydown', e => {
    if (e.key === 'Escape') { closeCancelModal(); closeDetailsModal(); }
});

function doCancel() {
    if (!cancelTargetId) return;
    const btn = document.getElementById('confirmCancelBtn');
    btn.disabled = true;
    btn.innerHTML = '<i class="fas fa-spinner fa-spin"></i> Cancelling...';

    const formData = new FormData();
    formData.append('action', 'cancel');
    formData.append('id', cancelTargetId);

    fetch(ctx + '/reservation', { method: 'POST', body: formData })
        .then(res => {
            // Always try to parse JSON — server returns JSON for all cases
            return res.text().then(text => {
                let data;
                try { data = JSON.parse(text); } catch(e) { data = { success: false, message: 'Unexpected server response.' }; }
                return { status: res.status, data };
            });
        })
        .then(({ status, data }) => {
            closeCancelModal();
            if (data.success) {
                showToast('Reservation cancelled successfully.', 'success');
                // Update card UI immediately — no need to wait for reload
                const card = document.querySelector('.res-card[data-resid="' + cancelTargetId + '"]');
                if (card) {
                    card.dataset.status = 'CANCELLED';
                    card.className = card.className.replace(/status-\S+/, 'status-CANCELLED');
                    const badge = card.querySelector('.status-badge');
                    if (badge) { badge.className = 'status-badge badge-CANCELLED'; badge.textContent = 'CANCELLED'; }
                    // Hide cancel button inside this card
                    const cancelBtn = card.querySelector('.btn-danger');
                    if (cancelBtn) cancelBtn.remove();
                    card.style.opacity = '0.75';
                }
                setTimeout(() => location.reload(), 1500);
            } else {
                const msg = data.message || (status === 403 ? 'Access denied.' : status === 400 ? 'Invalid request.' : 'Could not cancel reservation.');
                showToast(msg, 'error');
                btn.disabled = false;
                btn.innerHTML = '<i class="fas fa-times-circle"></i> Yes, Cancel';
            }
        })
        .catch(() => {
            closeCancelModal();
            showToast('Network error. Please try again.', 'error');
            btn.disabled = false;
            btn.innerHTML = '<i class="fas fa-times-circle"></i> Yes, Cancel';
        });
}

/* ─── DETAILS MODAL ─── */
function openDetailsModal(card) {
    const d = card.dataset;
    const cur = d.currency || 'Rs.';
    const status = d.status || '';

    // Image
    const img = document.getElementById('dmImg');
    const placeholder = document.getElementById('dmImgPlaceholder');
    img.style.display = '';
    placeholder.style.display = 'none';
    img.src = d.imgpath || '';
    img.alt = d.roomlabel + ' Room';

    // Title / res number
    document.getElementById('dmTitle').textContent = (d.roomlabel || '') + ' Room — #' + (d.roomnum || '');
    document.getElementById('dmResNum').textContent = 'Booking Ref: ' + (d.resnum || '');

    // Status badge
    const badge = document.getElementById('dmStatusBadge');
    badge.textContent = status.replace(/_/g, ' ');
    badge.className = 'status-badge badge-' + status;

    // Booked on
    document.getElementById('dmCreated').textContent = d.createdStr || '—';

    // Stay details
    document.getElementById('dmCheckin').textContent  = d.checkinstr  || '—';
    document.getElementById('dmCheckout').textContent = d.checkoutstr || '—';
    const nights = parseInt(d.nights) || 0;
    document.getElementById('dmNights').textContent = nights + ' night' + (nights !== 1 ? 's' : '');
    const guests = parseInt(d.guests) || 1;
    document.getElementById('dmGuests').textContent = guests + ' guest' + (guests !== 1 ? 's' : '');

    // Room details
    document.getElementById('dmRoomType').textContent = d.roomlabel || '—';
    document.getElementById('dmRoomNum').textContent  = d.roomnum   || '—';
    const floor = parseInt(d.floor) || 0;
    const floorItem = document.getElementById('dmFloorItem');
    if (floor > 0) { document.getElementById('dmFloor').textContent = 'Floor ' + floor; floorItem.style.display = ''; }
    else { floorItem.style.display = 'none'; }
    const size = parseInt(d.size) || 0;
    const sizeItem = document.getElementById('dmSizeItem');
    if (size > 0) { document.getElementById('dmSize').textContent = size + ' m²'; sizeItem.style.display = ''; }
    else { sizeItem.style.display = 'none'; }
    document.getElementById('dmPriceNight').textContent = cur + ' ' + (d.priceNight || '—');

    // Description
    const descSection = document.getElementById('dmDescSection');
    const desc = d.desc || '';
    if (desc) { document.getElementById('dmDesc').textContent = desc; descSection.style.display = ''; }
    else { descSection.style.display = 'none'; }

    // Amenities — split by comma or semicolon
    const amenSection = document.getElementById('dmAmenSection');
    const amenRaw = d.amenities || '';
    if (amenRaw) {
        const chips = amenRaw.split(/[,;]/).map(a => a.trim()).filter(Boolean);
        const container = document.getElementById('dmAmenities');
        container.innerHTML = chips.map(a =>
            '<span class="dm-amenity-chip"><i class="fas fa-check-circle"></i>' + escHtml(a) + '</span>'
        ).join('');
        amenSection.style.display = '';
    } else { amenSection.style.display = 'none'; }

    // Special requests
    const specialSection = document.getElementById('dmSpecialSection');
    const special = d.special || '';
    if (special) { document.getElementById('dmSpecial').textContent = special; specialSection.style.display = ''; }
    else { specialSection.style.display = 'none'; }

    // Billing
    document.getElementById('dmBase').textContent    = cur + ' ' + (d.base    || '0.00');
    document.getElementById('dmTax').textContent     = cur + ' ' + (d.tax     || '0.00');
    document.getElementById('dmTotal').textContent   = cur + ' ' + (d.total   || '0.00');
    const discountRow = document.getElementById('dmDiscountRow');
    const disc = d.discount || '';
    if (disc) { document.getElementById('dmDiscount').textContent = '- ' + cur + ' ' + disc; discountRow.style.display = ''; }
    else { discountRow.style.display = 'none'; }

    // Footer action buttons
    const footer = document.getElementById('dmFooter');
    footer.innerHTML = '';
    const resId = d.resid || '';

    if (status === 'PENDING' || status === 'CONFIRMED') {
        const cancelBtn = document.createElement('button');
        cancelBtn.className = 'btn btn-danger';
        cancelBtn.innerHTML = '<i class="fas fa-times-circle"></i> Cancel Reservation';
        cancelBtn.onclick = () => { closeDetailsModal(); openCancelModal(resId, d.resnum); };
        footer.appendChild(cancelBtn);
    }
    if (status === 'CHECKED_OUT') {
        const reviewLink = document.createElement('a');
        reviewLink.className = 'btn btn-success';
        reviewLink.href = ctx + '/review?action=create&reservationId=' + resId;
        reviewLink.innerHTML = '<i class="fas fa-star"></i> Write Review';
        footer.appendChild(reviewLink);

        const invoiceLink = document.createElement('a');
        invoiceLink.className = 'btn btn-secondary';
        invoiceLink.href = ctx + '/billing?action=invoice&reservationId=' + resId;
        invoiceLink.innerHTML = '<i class="fas fa-file-invoice"></i> Invoice';
        footer.appendChild(invoiceLink);
    }
    const closeBtn = document.createElement('button');
    closeBtn.className = 'btn btn-secondary';
    closeBtn.innerHTML = '<i class="fas fa-times"></i> Close';
    closeBtn.onclick = closeDetailsModal;
    footer.appendChild(closeBtn);

    document.getElementById('detailsModal').classList.add('open');
    document.body.style.overflow = 'hidden';
}

function closeDetailsModal() {
    document.getElementById('detailsModal').classList.remove('open');
    document.body.style.overflow = '';
}

function escHtml(str) {
    return str.replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;').replace(/"/g,'&quot;');
}

document.getElementById('detailsModal').addEventListener('click', function(e) {
    if (e.target === this) closeDetailsModal();
});

/* ─── TOAST ─── */
function showToast(msg, type) {
    const c = document.getElementById('toastContainer');
    const t = document.createElement('div');
    t.className = 'toast ' + type;
    t.innerHTML = '<i class="fas fa-' + (type==='success'?'check-circle':'exclamation-circle') + '"></i> ' + msg;
    c.appendChild(t);
    setTimeout(() => { t.style.opacity='0'; t.style.transition='.4s'; setTimeout(()=>t.remove(),400); }, 3800);
}

/* ─── AUTO-DISMISS FLASH ALERTS ─── */
document.querySelectorAll('.alert').forEach(a => {
    setTimeout(() => { a.style.transition='.5s'; a.style.opacity='0'; setTimeout(()=>a.remove(),500); }, 4500);
});
</script>

</body>
</html>
