<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="com.oceanview.model.User,com.oceanview.util.Constants,java.util.List,java.util.Map,java.util.Collections" %>
<%
    User currentUser = (User) session.getAttribute(Constants.SESSION_USER);
    if (currentUser == null || !currentUser.isAdmin()) {
        response.sendRedirect(request.getContextPath() + "/login"); return;
    }
    String ctx = request.getContextPath();
    String errorMsg   = (String) request.getAttribute(Constants.ATTR_ERROR);
    String successMsg = (String) request.getAttribute(Constants.ATTR_SUCCESS);

    // User stats
    int totalUsers    = request.getAttribute("totalUsers")    != null ? (Integer)request.getAttribute("totalUsers")    : 0;
    int activeUsers   = request.getAttribute("activeUsers")   != null ? (Integer)request.getAttribute("activeUsers")   : 0;
    int totalGuests   = request.getAttribute("totalGuests")   != null ? (Integer)request.getAttribute("totalGuests")   : 0;
    int totalStaff    = request.getAttribute("totalStaff")    != null ? (Integer)request.getAttribute("totalStaff")    : 0;
    int newUsersMonth = request.getAttribute("newUsersMonth") != null ? (Integer)request.getAttribute("newUsersMonth") : 0;

    // Room stats
    int totalRooms       = request.getAttribute("totalRooms")       != null ? (Integer)request.getAttribute("totalRooms")       : 0;
    int availableRooms   = request.getAttribute("availableRooms")   != null ? (Integer)request.getAttribute("availableRooms")   : 0;
    int occupiedRooms    = request.getAttribute("occupiedRooms")    != null ? (Integer)request.getAttribute("occupiedRooms")    : 0;
    int maintenanceRooms = request.getAttribute("maintenanceRooms") != null ? (Integer)request.getAttribute("maintenanceRooms") : 0;
    int reservedRooms    = request.getAttribute("reservedRooms")    != null ? (Integer)request.getAttribute("reservedRooms")    : 0;
    double occupancyRate = request.getAttribute("occupancyRate")    != null ? (Double)request.getAttribute("occupancyRate")     : 0.0;

    // Reservation stats
    int totalReservations     = request.getAttribute("totalReservations")     != null ? (Integer)request.getAttribute("totalReservations")     : 0;
    int pendingReservations   = request.getAttribute("pendingReservations")   != null ? (Integer)request.getAttribute("pendingReservations")   : 0;
    int confirmedReservations = request.getAttribute("confirmedReservations") != null ? (Integer)request.getAttribute("confirmedReservations") : 0;
    int checkedInCount        = request.getAttribute("checkedInCount")        != null ? (Integer)request.getAttribute("checkedInCount")        : 0;
    int cancelledReservations = request.getAttribute("cancelledReservations") != null ? (Integer)request.getAttribute("cancelledReservations") : 0;
    int todayCheckIns         = request.getAttribute("todayCheckIns")         != null ? (Integer)request.getAttribute("todayCheckIns")         : 0;
    int todayCheckOuts        = request.getAttribute("todayCheckOuts")        != null ? (Integer)request.getAttribute("todayCheckOuts")        : 0;
    int reservationsThisMonth = request.getAttribute("reservationsThisMonth") != null ? (Integer)request.getAttribute("reservationsThisMonth") : 0;

    // Revenue
    String revenueToday     = request.getAttribute("revenueToday")     != null ? (String)request.getAttribute("revenueToday")     : "Rs. 0.00";
    String revenueThisMonth = request.getAttribute("revenueThisMonth") != null ? (String)request.getAttribute("revenueThisMonth") : "Rs. 0.00";
    String revenueThisYear  = request.getAttribute("revenueThisYear")  != null ? (String)request.getAttribute("revenueThisYear")  : "Rs. 0.00";
    String revenueTotal     = request.getAttribute("revenueTotal")     != null ? (String)request.getAttribute("revenueTotal")     : "Rs. 0.00";

    // Review stats
    int totalReviews   = request.getAttribute("totalReviews")   != null ? (Integer)request.getAttribute("totalReviews")   : 0;
    int pendingReviews = request.getAttribute("pendingReviews")  != null ? (Integer)request.getAttribute("pendingReviews")  : 0;
    String avgRating   = request.getAttribute("avgRating")      != null ? (String)request.getAttribute("avgRating")       : "0.0";

    // Chart data
    String chartMonthLabels  = request.getAttribute("chartMonthLabels")  != null ? (String)request.getAttribute("chartMonthLabels")  : "[]";
    String chartMonthRevenue = request.getAttribute("chartMonthRevenue") != null ? (String)request.getAttribute("chartMonthRevenue") : "[]";
    String chartStatusData   = request.getAttribute("chartStatusData")   != null ? (String)request.getAttribute("chartStatusData")   : "[0,0,0,0,0]";
    String chartRoomTypes    = request.getAttribute("chartRoomTypes")    != null ? (String)request.getAttribute("chartRoomTypes")    : "[]";
    String chartRoomTotals   = request.getAttribute("chartRoomTotals")   != null ? (String)request.getAttribute("chartRoomTotals")   : "[]";
    String chartRoomOccupied = request.getAttribute("chartRoomOccupied") != null ? (String)request.getAttribute("chartRoomOccupied") : "[]";

    // Recent reservations
    List<Map<String,Object>> recentReservations = (List<Map<String,Object>>) request.getAttribute("recentReservations");
    if (recentReservations == null) recentReservations = Collections.emptyList();

    String staffName = currentUser.getFullName() != null ? currentUser.getFullName() : currentUser.getUsername();
    String staffInitials;
    try {
        int sp = staffName.indexOf(' ');
        staffInitials = sp > 0 ? ("" + staffName.charAt(0) + staffName.charAt(sp+1)).toUpperCase() : staffName.substring(0,1).toUpperCase();
    } catch(Exception e) { staffInitials = staffName.substring(0,1).toUpperCase(); }

    java.time.LocalDate today = java.time.LocalDate.now();
    String todayStr = today.format(java.time.format.DateTimeFormatter.ofPattern("EEEE, MMMM dd, yyyy"));
%>
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Admin Dashboard | Ocean View Resort</title>
<link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
<script src="https://cdn.jsdelivr.net/npm/chart.js@4.4.0/dist/chart.umd.min.js"></script>
<style>
/* ===== RESET & BASE ===== */
*,*::before,*::after{box-sizing:border-box;margin:0;padding:0}
html{font-size:15px;scroll-behavior:smooth}
body{font-family:'Segoe UI',system-ui,-apple-system,sans-serif;background:#f0f4f8;color:#1e2a38;min-height:100vh;display:flex}
::-webkit-scrollbar{width:6px;height:6px}
::-webkit-scrollbar-track{background:#f0f4f8}
::-webkit-scrollbar-thumb{background:#b0bec5;border-radius:3px}
::-webkit-scrollbar-thumb:hover{background:#78909c}

/* ===== SIDEBAR ===== */
.sidebar{width:260px;min-height:100vh;background:linear-gradient(180deg,#0d1b2e 0%,#1a2f4e 100%);display:flex;flex-direction:column;position:fixed;top:0;left:0;z-index:100;transition:transform .3s ease;box-shadow:3px 0 20px rgba(0,0,0,.25)}
.sidebar-brand{padding:22px 20px;display:flex;align-items:center;gap:12px;border-bottom:1px solid rgba(255,255,255,.08)}
.brand-logo{width:44px;height:44px;background:linear-gradient(135deg,#f59e0b,#d97706);border-radius:12px;display:flex;align-items:center;justify-content:center;font-size:1.2rem;color:#fff;font-weight:800;flex-shrink:0}
.brand-name{font-size:.95rem;font-weight:700;color:#fff;letter-spacing:.5px}
.brand-sub{font-size:.68rem;color:rgba(255,255,255,.45);text-transform:uppercase;letter-spacing:1.2px}
.sidebar-user{padding:18px 20px;display:flex;align-items:center;gap:12px;border-bottom:1px solid rgba(255,255,255,.06);background:rgba(0,0,0,.15)}
.user-avatar{width:40px;height:40px;background:linear-gradient(135deg,#f59e0b,#d97706);border-radius:50%;display:flex;align-items:center;justify-content:center;font-size:.88rem;font-weight:700;color:#fff;flex-shrink:0}
.user-name{font-size:.85rem;font-weight:600;color:#fff;white-space:nowrap;overflow:hidden;text-overflow:ellipsis}
.user-role{font-size:.68rem;color:rgba(255,255,255,.45);text-transform:uppercase;letter-spacing:.8px}
.sidebar-nav{flex:1;padding:14px 0;overflow-y:auto}
.nav-label{font-size:.63rem;font-weight:700;color:rgba(255,255,255,.3);text-transform:uppercase;letter-spacing:1.5px;padding:14px 20px 5px}
.nav-link{display:flex;align-items:center;gap:12px;padding:11px 20px;color:rgba(255,255,255,.65);text-decoration:none;font-size:.87rem;font-weight:500;transition:all .2s;border-left:3px solid transparent}
.nav-link:hover{color:#fff;background:rgba(255,255,255,.07);border-left-color:rgba(245,158,11,.5)}
.nav-link.active{color:#fff;background:rgba(245,158,11,.18);border-left-color:#f59e0b}
.nav-icon{width:20px;text-align:center;font-size:.9rem}
.nav-badge{margin-left:auto;background:#ef4444;color:#fff;font-size:.63rem;font-weight:700;border-radius:10px;padding:2px 7px;min-width:20px;text-align:center}
.nav-badge.amber{background:#f59e0b}
.sidebar-footer{padding:14px 20px;border-top:1px solid rgba(255,255,255,.07)}
.sidebar-footer a{display:flex;align-items:center;gap:10px;color:rgba(255,255,255,.45);font-size:.82rem;text-decoration:none;padding:7px 0;transition:color .2s}
.sidebar-footer a:hover{color:#fff}
.sidebar-overlay{position:fixed;inset:0;background:rgba(0,0,0,.5);z-index:99;display:none}
.sidebar-overlay.visible{display:block}

/* ===== MAIN ===== */
.main-content{margin-left:260px;flex:1;display:flex;flex-direction:column;min-height:100vh}

/* ===== TOPBAR ===== */
.topbar{background:#fff;padding:0 28px;height:64px;display:flex;align-items:center;justify-content:space-between;border-bottom:1px solid #e2e8f0;box-shadow:0 1px 6px rgba(0,0,0,.05);position:sticky;top:0;z-index:50}
.topbar-left{display:flex;align-items:center;gap:16px}
.sidebar-toggle{display:none;background:none;border:none;cursor:pointer;font-size:1.2rem;color:#64748b;padding:6px;border-radius:6px}
.page-title{font-size:1.1rem;font-weight:700;color:#1e2a38}
.page-subtitle{font-size:.76rem;color:#64748b;margin-top:1px}
.topbar-right{display:flex;align-items:center;gap:12px}
.topbar-date{font-size:.78rem;color:#64748b;font-weight:500}
.topbar-btn{display:flex;align-items:center;gap:7px;padding:8px 14px;border-radius:8px;font-size:.82rem;font-weight:600;cursor:pointer;border:none;transition:all .2s;text-decoration:none;font-family:inherit;white-space:nowrap}
.btn-amber{background:linear-gradient(135deg,#f59e0b,#d97706);color:#fff;box-shadow:0 2px 8px rgba(245,158,11,.3)}
.btn-amber:hover{transform:translateY(-1px);box-shadow:0 4px 14px rgba(245,158,11,.4)}
.btn-outline-dark{background:transparent;border:1.5px solid #e2e8f0;color:#374151}
.btn-outline-dark:hover{border-color:#f59e0b;color:#d97706;background:#fffbeb}

/* ===== PAGE CONTENT ===== */
.page-content{flex:1;padding:26px}

/* ===== ALERTS ===== */
.alert{display:flex;align-items:center;gap:12px;padding:13px 18px;border-radius:10px;margin-bottom:20px;font-size:.87rem;font-weight:500;animation:slideDown .3s ease}
@keyframes slideDown{from{opacity:0;transform:translateY(-8px)}to{opacity:1;transform:translateY(0)}}
.alert-success{background:#ecfdf5;color:#065f46;border:1px solid #6ee7b7}
.alert-error{background:#fef2f2;color:#991b1b;border:1px solid #fca5a5}
.alert-close{margin-left:auto;background:none;border:none;cursor:pointer;font-size:1.1rem;color:inherit;opacity:.6}
.alert-close:hover{opacity:1}

/* ===== WELCOME BANNER ===== */
.welcome-banner{background:linear-gradient(135deg,#0d1b2e 0%,#1a3a5c 50%,#0d2137 100%);border-radius:16px;padding:24px 28px;margin-bottom:24px;display:flex;align-items:center;justify-content:space-between;flex-wrap:wrap;gap:16px}
.welcome-text h2{font-size:1.3rem;font-weight:700;color:#fff;margin-bottom:4px}
.welcome-text p{font-size:.85rem;color:rgba(255,255,255,.6)}
.welcome-stats{display:flex;gap:20px;flex-wrap:wrap}
.w-stat{text-align:center}
.w-stat-val{font-size:1.4rem;font-weight:800;color:#f59e0b}
.w-stat-lbl{font-size:.7rem;color:rgba(255,255,255,.5);text-transform:uppercase;letter-spacing:.8px}

/* ===== STATS GRID (primary) ===== */
.stats-grid{display:grid;grid-template-columns:repeat(4,1fr);gap:18px;margin-bottom:22px}
.stat-card{background:#fff;border-radius:14px;padding:20px 22px;display:flex;align-items:center;gap:16px;box-shadow:0 1px 4px rgba(0,0,0,.06);border:1px solid #e8eef5;transition:transform .2s,box-shadow .2s;cursor:pointer;position:relative;overflow:hidden}
.stat-card::after{content:'';position:absolute;top:0;right:0;width:4px;height:100%;background:var(--accent)}
.stat-card:hover{transform:translateY(-2px);box-shadow:0 6px 20px rgba(0,0,0,.1)}
.stat-card.amber{--accent:#f59e0b}.stat-card.blue{--accent:#3b82f6}.stat-card.green{--accent:#10b981}.stat-card.purple{--accent:#8b5cf6}.stat-card.red{--accent:#ef4444}.stat-card.teal{--accent:#06b6d4}
.stat-icon{width:52px;height:52px;border-radius:12px;display:flex;align-items:center;justify-content:center;font-size:1.25rem;flex-shrink:0}
.stat-icon.amber{background:#fef3c7;color:#d97706}.stat-icon.blue{background:#dbeafe;color:#2563eb}.stat-icon.green{background:#d1fae5;color:#059669}.stat-icon.purple{background:#ede9fe;color:#7c3aed}.stat-icon.red{background:#fee2e2;color:#dc2626}.stat-icon.teal{background:#cffafe;color:#0891b2}
.stat-value{font-size:1.75rem;font-weight:800;color:#1e2a38;line-height:1}
.stat-label{font-size:.76rem;color:#64748b;margin-top:3px;font-weight:500}
.stat-sub{font-size:.7rem;color:#94a3b8;margin-top:2px}

/* ===== SECONDARY STATS ROW ===== */
.secondary-stats{display:grid;grid-template-columns:repeat(6,1fr);gap:14px;margin-bottom:24px}
.mini-stat{background:#fff;border-radius:11px;padding:14px 16px;text-align:center;box-shadow:0 1px 3px rgba(0,0,0,.05);border:1px solid #e8eef5}
.mini-stat-val{font-size:1.2rem;font-weight:800;color:#1e2a38}
.mini-stat-lbl{font-size:.7rem;color:#64748b;margin-top:3px}
.mini-stat-icon{font-size:1.1rem;margin-bottom:6px}

/* ===== GRID LAYOUT ===== */
.grid-2{display:grid;grid-template-columns:1fr 1fr;gap:20px;margin-bottom:22px}
.grid-3-1{display:grid;grid-template-columns:2fr 1fr;gap:20px;margin-bottom:22px}

/* ===== CARD ===== */
.card{background:#fff;border-radius:14px;box-shadow:0 1px 4px rgba(0,0,0,.06);border:1px solid #e8eef5;overflow:hidden}
.card-header{padding:16px 22px;display:flex;align-items:center;justify-content:space-between;border-bottom:1px solid #f0f4f8;flex-wrap:wrap;gap:8px}
.card-title{font-size:.95rem;font-weight:700;color:#1e2a38;display:flex;align-items:center;gap:8px}
.card-title i{color:#f59e0b}
.card-body{padding:20px 22px}
.card-link{font-size:.78rem;font-weight:600;color:#f59e0b;text-decoration:none;display:flex;align-items:center;gap:5px}
.card-link:hover{color:#d97706}

/* ===== CHART CONTAINERS ===== */
.chart-wrap{position:relative;height:220px;padding:4px}

/* ===== TABLE ===== */
table{width:100%;border-collapse:collapse}
thead th{padding:11px 14px;font-size:.7rem;font-weight:700;color:#64748b;text-transform:uppercase;letter-spacing:.8px;background:#f8fafc;border-bottom:1px solid #e8eef5;text-align:left;white-space:nowrap}
tbody tr{border-bottom:1px solid #f1f5f9;transition:background .15s}
tbody tr:last-child{border-bottom:none}
tbody tr:hover{background:#f8fafc}
td{padding:12px 14px;font-size:.83rem;color:#374151;vertical-align:middle}
.guest-cell{display:flex;align-items:center;gap:9px}
.guest-avatar{width:32px;height:32px;border-radius:50%;background:linear-gradient(135deg,#f59e0b,#d97706);display:flex;align-items:center;justify-content:center;font-size:.72rem;font-weight:700;color:#fff;flex-shrink:0;text-transform:uppercase}
.guest-name{font-weight:600;color:#1e2a38;font-size:.85rem}
.guest-email{font-size:.72rem;color:#94a3b8}
.room-tag{display:inline-flex;align-items:center;gap:4px;padding:3px 9px;border-radius:5px;font-size:.74rem;font-weight:600;background:#e0f2fe;color:#0077b6}
.amount-val{font-weight:700;color:#059669;font-size:.85rem}

/* ===== STATUS BADGES ===== */
.badge{display:inline-flex;align-items:center;gap:4px;padding:3px 10px;border-radius:20px;font-size:.7rem;font-weight:700;letter-spacing:.3px;white-space:nowrap}
.badge-dot{width:5px;height:5px;border-radius:50%;background:currentColor}
.badge-pending{background:#fef3c7;color:#92400e}
.badge-confirmed{background:#dbeafe;color:#1d4ed8}
.badge-checked_in{background:#d1fae5;color:#065f46}
.badge-checked_out{background:#f3f4f6;color:#4b5563}
.badge-cancelled{background:#fee2e2;color:#991b1b}

/* ===== ACTION BUTTONS ===== */
.action-btn{padding:5px 11px;border-radius:6px;border:none;font-size:.74rem;font-weight:600;cursor:pointer;display:inline-flex;align-items:center;gap:4px;transition:all .2s;font-family:inherit;text-decoration:none}
.btn-view{background:#f1f5f9;color:#475569}.btn-view:hover{background:#475569;color:#fff}
.btn-edit{background:#dbeafe;color:#1d4ed8}.btn-edit:hover{background:#1d4ed8;color:#fff}
.btn-delete{background:#fee2e2;color:#dc2626}.btn-delete:hover{background:#dc2626;color:#fff}

/* ===== QUICK ACTIONS ===== */
.quick-actions{display:grid;grid-template-columns:repeat(3,1fr);gap:12px}
.qa-btn{display:flex;flex-direction:column;align-items:center;gap:8px;padding:16px 10px;border-radius:12px;border:1.5px solid #e2e8f0;background:#fff;cursor:pointer;transition:all .2s;text-decoration:none;font-family:inherit}
.qa-btn:hover{border-color:#f59e0b;background:#fffbeb;transform:translateY(-2px);box-shadow:0 4px 12px rgba(245,158,11,.15)}
.qa-icon{width:40px;height:40px;border-radius:10px;display:flex;align-items:center;justify-content:center;font-size:1rem}
.qa-label{font-size:.74rem;font-weight:600;color:#374151;text-align:center}

/* ===== ALERTS PANEL ===== */
.alert-item{display:flex;align-items:flex-start;gap:10px;padding:12px 14px;border-radius:9px;margin-bottom:10px;font-size:.83rem;border-left:3px solid}
.alert-item:last-child{margin-bottom:0}
.alert-item.warning{background:#fffbeb;border-color:#f59e0b;color:#92400e}
.alert-item.info{background:#eff6ff;border-color:#3b82f6;color:#1e40af}
.alert-item.danger{background:#fef2f2;border-color:#ef4444;color:#991b1b}
.alert-item.success{background:#f0fdf4;border-color:#10b981;color:#065f46}
.alert-item-icon{font-size:.9rem;margin-top:1px;flex-shrink:0}
.alert-item-text{flex:1}
.alert-item-title{font-weight:700;margin-bottom:2px}
.alert-item-sub{font-size:.75rem;opacity:.8}

/* ===== OCCUPANCY BAR ===== */
.occ-bar-wrap{margin-bottom:14px}
.occ-bar-label{display:flex;justify-content:space-between;font-size:.78rem;margin-bottom:5px;font-weight:500;color:#374151}
.occ-bar-track{height:8px;background:#f1f5f9;border-radius:4px;overflow:hidden}
.occ-bar-fill{height:100%;border-radius:4px;transition:width .6s ease}

/* ===== EMPTY STATE ===== */
.empty-state{text-align:center;padding:40px 20px;color:#94a3b8}
.empty-state i{font-size:2rem;margin-bottom:10px;display:block;color:#cbd5e1}
.empty-state p{font-size:.88rem;color:#64748b}

/* ===== MODAL ===== */
.modal-overlay{position:fixed;inset:0;background:rgba(10,20,40,.65);z-index:1000;display:flex;align-items:center;justify-content:center;padding:20px;opacity:0;pointer-events:none;transition:opacity .25s;backdrop-filter:blur(4px)}
.modal-overlay.open{opacity:1;pointer-events:all}
.modal-box{background:#fff;border-radius:18px;box-shadow:0 25px 60px rgba(0,0,0,.2);width:100%;max-width:560px;max-height:90vh;overflow-y:auto;transform:translateY(16px) scale(.97);transition:transform .25s}
.modal-overlay.open .modal-box{transform:translateY(0) scale(1)}
.modal-header{padding:20px 24px;display:flex;align-items:center;justify-content:space-between;border-bottom:1px solid #f0f4f8;position:sticky;top:0;background:#fff;z-index:1;border-radius:18px 18px 0 0}
.modal-icon-wrap{width:42px;height:42px;background:linear-gradient(135deg,#f59e0b,#d97706);border-radius:10px;display:flex;align-items:center;justify-content:center;color:#fff;font-size:1rem;margin-right:12px;flex-shrink:0}
.modal-title{font-size:1rem;font-weight:700;color:#1e2a38}
.modal-subtitle{font-size:.76rem;color:#64748b;margin-top:2px}
.modal-close{width:32px;height:32px;border-radius:7px;border:none;background:#f1f5f9;color:#64748b;cursor:pointer;display:flex;align-items:center;justify-content:center;transition:all .2s;font-size:.95rem}
.modal-close:hover{background:#e2e8f0;color:#1e2a38}
.modal-body{padding:22px 24px}
.modal-footer{padding:16px 24px;display:flex;justify-content:flex-end;gap:10px;border-top:1px solid #f0f4f8;background:#f8fafc;border-radius:0 0 18px 18px;flex-wrap:wrap}
.modal-btn{padding:9px 18px;border-radius:8px;border:none;font-size:.85rem;font-weight:600;cursor:pointer;display:flex;align-items:center;gap:7px;transition:all .2s;font-family:inherit}
.modal-btn-cancel{background:#f1f5f9;color:#475569}.modal-btn-cancel:hover{background:#e2e8f0}
.modal-btn-primary{background:linear-gradient(135deg,#f59e0b,#d97706);color:#fff;box-shadow:0 2px 8px rgba(245,158,11,.3)}.modal-btn-primary:hover{transform:translateY(-1px);box-shadow:0 4px 14px rgba(245,158,11,.4)}
.modal-btn-danger{background:linear-gradient(135deg,#ef4444,#dc2626);color:#fff}.modal-btn-danger:hover{transform:translateY(-1px);box-shadow:0 4px 14px rgba(239,68,68,.35)}
.form-group{margin-bottom:15px}
.form-label{display:block;font-size:.79rem;font-weight:600;color:#374151;margin-bottom:5px}
.form-label .req{color:#ef4444;margin-left:2px}
.form-control{width:100%;padding:9px 13px;border:1.5px solid #e2e8f0;border-radius:8px;font-size:.87rem;color:#1e2a38;background:#f8fafc;outline:none;transition:all .2s;font-family:inherit}
.form-control:focus{border-color:#f59e0b;background:#fff;box-shadow:0 0 0 3px rgba(245,158,11,.12)}
.form-row{display:grid;grid-template-columns:1fr 1fr;gap:13px}

/* ===== RESPONSIVE ===== */
@media(max-width:1200px){.stats-grid{grid-template-columns:repeat(2,1fr)}.secondary-stats{grid-template-columns:repeat(3,1fr)}}
@media(max-width:1024px){.grid-2,.grid-3-1{grid-template-columns:1fr}.secondary-stats{grid-template-columns:repeat(3,1fr)}}
@media(max-width:900px){.sidebar{transform:translateX(-100%)}.sidebar.open{transform:translateX(0)}.main-content{margin-left:0}.sidebar-toggle{display:flex!important}}
@media(max-width:640px){.stats-grid{grid-template-columns:1fr 1fr}.secondary-stats{grid-template-columns:repeat(2,1fr)}.page-content{padding:14px}.quick-actions{grid-template-columns:repeat(2,1fr)}.form-row{grid-template-columns:1fr}.topbar-date{display:none}}
</style>
</head>
<body>
<div class="sidebar-overlay" id="sidebarOverlay"></div>

<!-- ===== SIDEBAR ===== -->
<aside class="sidebar" id="sidebar">
  <div class="sidebar-brand">
    <div class="brand-logo"><i class="fas fa-crown"></i></div>
    <div><div class="brand-name">Ocean View</div><div class="brand-sub">Admin Panel</div></div>
  </div>
  <div class="sidebar-user">
    <div class="user-avatar"><%= staffInitials %></div>
    <div style="min-width:0">
      <div class="user-name"><%= staffName %></div>
      <div class="user-role">Administrator</div>
    </div>
  </div>
  <nav class="sidebar-nav">
    <div class="nav-label">Main</div>
    <a class="nav-link active" href="<%= ctx %>/admin/dashboard"><span class="nav-icon"><i class="fas fa-th-large"></i></span> Dashboard</a>

    <div class="nav-label">Management</div>
    <a class="nav-link" href="<%= ctx %>/admin/users"><span class="nav-icon"><i class="fas fa-users"></i></span> Users
      <% if(totalUsers>0){%><span class="nav-badge amber"><%= totalUsers %></span><%}%>
    </a>
    <a class="nav-link" href="<%= ctx %>/admin/rooms"><span class="nav-icon"><i class="fas fa-bed"></i></span> Rooms</a>
    <a class="nav-link" href="<%= ctx %>/admin/reservations"><span class="nav-icon"><i class="fas fa-calendar-alt"></i></span> Reservations
      <% if(pendingReservations>0){%><span class="nav-badge"><%= pendingReservations %></span><%}%>
    </a>
    <a class="nav-link" href="<%= ctx %>/admin/reviews"><span class="nav-icon"><i class="fas fa-star"></i></span> Reviews
      <% if(pendingReviews>0){%><span class="nav-badge"><%= pendingReviews %></span><%}%>
    </a>
    <a class="nav-link" href="<%= ctx %>/admin/offers"><span class="nav-icon"><i class="fas fa-tag"></i></span> Offers</a>

    <div class="nav-label">Reports</div>
    <a class="nav-link" href="<%= ctx %>/admin/reports"><span class="nav-icon"><i class="fas fa-chart-bar"></i></span> Reports</a>

    <div class="nav-label">System</div>
    <a class="nav-link" href="<%= ctx %>/admin/settings"><span class="nav-icon"><i class="fas fa-cog"></i></span> Settings</a>
  </nav>
  <div class="sidebar-footer">
    <a href="<%= ctx %>/logout"><i class="fas fa-power-off"></i> Logout</a>
  </div>
</aside>

<!-- ===== MAIN CONTENT ===== -->
<div class="main-content">

  <!-- TOPBAR -->
  <header class="topbar">
    <div class="topbar-left">
      <button class="sidebar-toggle" id="sidebarToggle" style="display:none;"><i class="fas fa-bars"></i></button>
      <div>
        <div class="page-title"><i class="fas fa-crown" style="color:#f59e0b;margin-right:8px;"></i>Admin Dashboard</div>
        <div class="page-subtitle"><%= todayStr %></div>
      </div>
    </div>
    <div class="topbar-right">
      <a href="<%= ctx %>/admin/users" class="topbar-btn btn-outline-dark"><i class="fas fa-user-plus"></i> New User</a>
      <a href="<%= ctx %>/admin/rooms" class="topbar-btn btn-outline-dark"><i class="fas fa-bed"></i> Rooms</a>
      <a href="<%= ctx %>/admin/reports" class="topbar-btn btn-amber"><i class="fas fa-chart-bar"></i> Reports</a>
    </div>
  </header>

  <!-- PAGE CONTENT -->
  <main class="page-content">

    <!-- ALERTS -->
    <% if (successMsg != null && !successMsg.isEmpty()) { %>
    <div class="alert alert-success" id="alertSuccess">
      <i class="fas fa-check-circle"></i><span><%= successMsg %></span>
      <button class="alert-close" onclick="this.parentElement.remove()">&times;</button>
    </div>
    <% } %>
    <% if (errorMsg != null && !errorMsg.isEmpty()) { %>
    <div class="alert alert-error" id="alertError">
      <i class="fas fa-exclamation-circle"></i><span><%= errorMsg %></span>
      <button class="alert-close" onclick="this.parentElement.remove()">&times;</button>
    </div>
    <% } %>

    <!-- WELCOME BANNER -->
    <div class="welcome-banner">
      <div class="welcome-text">
        <h2>Welcome back, <%= staffName.split(" ")[0] %>! 👋</h2>
        <p>Here's what's happening at Ocean View Resort today.</p>
      </div>
      <div class="welcome-stats">
        <div class="w-stat"><div class="w-stat-val"><%= todayCheckIns %></div><div class="w-stat-lbl">Today's Check-Ins</div></div>
        <div class="w-stat"><div class="w-stat-val"><%= todayCheckOuts %></div><div class="w-stat-lbl">Today's Check-Outs</div></div>
        <div class="w-stat"><div class="w-stat-val"><%= checkedInCount %></div><div class="w-stat-lbl">Active Stays</div></div>
        <div class="w-stat"><div class="w-stat-val"><%= String.format("%.0f", occupancyRate) %>%</div><div class="w-stat-lbl">Occupancy</div></div>
      </div>
    </div>

    <!-- PRIMARY STATS GRID -->
    <div class="stats-grid">
      <div class="stat-card amber" onclick="location.href='<%= ctx %>/admin/reports'">
        <div class="stat-icon amber"><i class="fas fa-dollar-sign"></i></div>
        <div>
          <div class="stat-value"><%= revenueThisMonth %></div>
          <div class="stat-label">Revenue This Month</div>
          <div class="stat-sub">Total: <%= revenueTotal %></div>
        </div>
      </div>
      <div class="stat-card blue" onclick="location.href='<%= ctx %>/admin/reservations'">
        <div class="stat-icon blue"><i class="fas fa-calendar-check"></i></div>
        <div>
          <div class="stat-value"><%= totalReservations %></div>
          <div class="stat-label">Total Reservations</div>
          <div class="stat-sub"><%= reservationsThisMonth %> this month</div>
        </div>
      </div>
      <div class="stat-card green" onclick="location.href='<%= ctx %>/admin/users'">
        <div class="stat-icon green"><i class="fas fa-users"></i></div>
        <div>
          <div class="stat-value"><%= totalUsers %></div>
          <div class="stat-label">Total Users</div>
          <div class="stat-sub"><%= newUsersMonth %> new this month</div>
        </div>
      </div>
      <div class="stat-card purple" onclick="location.href='<%= ctx %>/admin/rooms'">
        <div class="stat-icon purple"><i class="fas fa-bed"></i></div>
        <div>
          <div class="stat-value"><%= String.format("%.1f", occupancyRate) %>%</div>
          <div class="stat-label">Occupancy Rate</div>
          <div class="stat-sub"><%= occupiedRooms %>/<%= totalRooms %> rooms occupied</div>
        </div>
      </div>
    </div>

    <!-- SECONDARY STATS ROW -->
    <div class="secondary-stats">
      <div class="mini-stat">
        <div class="mini-stat-icon" style="color:#f59e0b;"><i class="fas fa-clock"></i></div>
        <div class="mini-stat-val" style="color:#d97706;"><%= pendingReservations %></div>
        <div class="mini-stat-lbl">Pending</div>
      </div>
      <div class="mini-stat">
        <div class="mini-stat-icon" style="color:#3b82f6;"><i class="fas fa-check-circle"></i></div>
        <div class="mini-stat-val" style="color:#2563eb;"><%= confirmedReservations %></div>
        <div class="mini-stat-lbl">Confirmed</div>
      </div>
      <div class="mini-stat">
        <div class="mini-stat-icon" style="color:#10b981;"><i class="fas fa-door-open"></i></div>
        <div class="mini-stat-val" style="color:#059669;"><%= checkedInCount %></div>
        <div class="mini-stat-lbl">Checked In</div>
      </div>
      <div class="mini-stat">
        <div class="mini-stat-icon" style="color:#06b6d4;"><i class="fas fa-bed"></i></div>
        <div class="mini-stat-val" style="color:#0891b2;"><%= availableRooms %></div>
        <div class="mini-stat-lbl">Available Rooms</div>
      </div>
      <div class="mini-stat">
        <div class="mini-stat-icon" style="color:#8b5cf6;"><i class="fas fa-star"></i></div>
        <div class="mini-stat-val" style="color:#7c3aed;"><%= avgRating %></div>
        <div class="mini-stat-lbl">Avg Rating</div>
      </div>
      <div class="mini-stat">
        <div class="mini-stat-icon" style="color:#ef4444;"><i class="fas fa-tools"></i></div>
        <div class="mini-stat-val" style="color:#dc2626;"><%= maintenanceRooms %></div>
        <div class="mini-stat-lbl">Maintenance</div>
      </div>
    </div>

    <!-- CHARTS ROW -->
    <div class="grid-2">

      <!-- Revenue Chart -->
      <div class="card">
        <div class="card-header">
          <div class="card-title"><i class="fas fa-chart-line"></i> Monthly Revenue</div>
          <a href="<%= ctx %>/admin/reports" class="card-link"><i class="fas fa-arrow-right"></i> Full Report</a>
        </div>
        <div class="card-body">
          <div class="chart-wrap"><canvas id="revenueChart"></canvas></div>
        </div>
      </div>

      <!-- Reservation Status Pie -->
      <div class="card">
        <div class="card-header">
          <div class="card-title"><i class="fas fa-chart-pie"></i> Reservation Status</div>
          <a href="<%= ctx %>/admin/reservations" class="card-link"><i class="fas fa-arrow-right"></i> View All</a>
        </div>
        <div class="card-body">
          <div class="chart-wrap"><canvas id="statusChart"></canvas></div>
        </div>
      </div>
    </div>

    <!-- ROOM OCCUPANCY + ALERTS ROW -->
    <div class="grid-3-1">

      <!-- Room Type Occupancy Bar Chart -->
      <div class="card">
        <div class="card-header">
          <div class="card-title"><i class="fas fa-hotel"></i> Room Type Occupancy</div>
          <a href="<%= ctx %>/admin/rooms" class="card-link"><i class="fas fa-arrow-right"></i> Manage Rooms</a>
        </div>
        <div class="card-body">
          <div class="chart-wrap" style="height:190px;"><canvas id="roomChart"></canvas></div>
          <div style="margin-top:18px;">
            <div class="occ-bar-wrap">
              <div class="occ-bar-label"><span><i class="fas fa-door-open" style="margin-right:5px;color:#10b981;"></i>Available</span><span><%= availableRooms %> / <%= totalRooms %></span></div>
              <div class="occ-bar-track"><div class="occ-bar-fill" style="width:<%= totalRooms>0 ? (availableRooms*100/totalRooms) : 0 %>%;background:#10b981;"></div></div>
            </div>
            <div class="occ-bar-wrap">
              <div class="occ-bar-label"><span><i class="fas fa-bed" style="margin-right:5px;color:#3b82f6;"></i>Occupied</span><span><%= occupiedRooms %> / <%= totalRooms %></span></div>
              <div class="occ-bar-track"><div class="occ-bar-fill" style="width:<%= totalRooms>0 ? (occupiedRooms*100/totalRooms) : 0 %>%;background:#3b82f6;"></div></div>
            </div>
            <div class="occ-bar-wrap">
              <div class="occ-bar-label"><span><i class="fas fa-bookmark" style="margin-right:5px;color:#f59e0b;"></i>Reserved</span><span><%= reservedRooms %> / <%= totalRooms %></span></div>
              <div class="occ-bar-track"><div class="occ-bar-fill" style="width:<%= totalRooms>0 ? (reservedRooms*100/totalRooms) : 0 %>%;background:#f59e0b;"></div></div>
            </div>
            <div class="occ-bar-wrap">
              <div class="occ-bar-label"><span><i class="fas fa-tools" style="margin-right:5px;color:#ef4444;"></i>Maintenance</span><span><%= maintenanceRooms %> / <%= totalRooms %></span></div>
              <div class="occ-bar-track"><div class="occ-bar-fill" style="width:<%= totalRooms>0 ? (maintenanceRooms*100/totalRooms) : 0 %>%;background:#ef4444;"></div></div>
            </div>
          </div>
        </div>
      </div>

      <!-- System Alerts -->
      <div class="card">
        <div class="card-header">
          <div class="card-title"><i class="fas fa-bell"></i> System Alerts</div>
        </div>
        <div class="card-body" style="padding:14px;">
          <% if (pendingReservations > 0) { %>
          <div class="alert-item warning">
            <div class="alert-item-icon"><i class="fas fa-clock"></i></div>
            <div class="alert-item-text">
              <div class="alert-item-title"><%= pendingReservations %> Pending Reservations</div>
              <div class="alert-item-sub">Require confirmation</div>
            </div>
          </div>
          <% } %>
          <% if (pendingReviews > 0) { %>
          <div class="alert-item info">
            <div class="alert-item-icon"><i class="fas fa-star"></i></div>
            <div class="alert-item-text">
              <div class="alert-item-title"><%= pendingReviews %> Pending Reviews</div>
              <div class="alert-item-sub">Awaiting moderation</div>
            </div>
          </div>
          <% } %>
          <% if (maintenanceRooms > 0) { %>
          <div class="alert-item danger">
            <div class="alert-item-icon"><i class="fas fa-tools"></i></div>
            <div class="alert-item-text">
              <div class="alert-item-title"><%= maintenanceRooms %> Rooms in Maintenance</div>
              <div class="alert-item-sub">Not available for booking</div>
            </div>
          </div>
          <% } %>
          <% if (todayCheckIns > 0) { %>
          <div class="alert-item success">
            <div class="alert-item-icon"><i class="fas fa-sign-in-alt"></i></div>
            <div class="alert-item-text">
              <div class="alert-item-title"><%= todayCheckIns %> Check-Ins Today</div>
              <div class="alert-item-sub">Expected arrivals</div>
            </div>
          </div>
          <% } %>
          <% if (todayCheckOuts > 0) { %>
          <div class="alert-item warning">
            <div class="alert-item-icon"><i class="fas fa-sign-out-alt"></i></div>
            <div class="alert-item-text">
              <div class="alert-item-title"><%= todayCheckOuts %> Check-Outs Today</div>
              <div class="alert-item-sub">Expected departures</div>
            </div>
          </div>
          <% } %>
          <% if (pendingReservations==0 && pendingReviews==0 && maintenanceRooms==0 && todayCheckIns==0 && todayCheckOuts==0) { %>
          <div class="empty-state"><i class="fas fa-check-circle" style="color:#10b981;"></i><p>All systems normal</p></div>
          <% } %>
        </div>
      </div>
    </div>

    <!-- RECENT RESERVATIONS TABLE -->
    <div class="card" style="margin-bottom:22px;">
      <div class="card-header">
        <div class="card-title"><i class="fas fa-list-alt"></i> Recent Reservations</div>
        <a href="<%= ctx %>/admin/reservations" class="card-link"><i class="fas fa-arrow-right"></i> View All</a>
      </div>
      <% if (recentReservations.isEmpty()) { %>
      <div class="empty-state"><i class="fas fa-calendar-times"></i><p>No reservations found</p></div>
      <% } else { %>
      <div style="overflow-x:auto;">
      <table>
        <thead>
          <tr>
            <th>Guest</th>
            <th>Booking ID</th>
            <th>Room</th>
            <th>Check-In</th>
            <th>Check-Out</th>
            <th>Nights</th>
            <th>Amount</th>
            <th>Status</th>
            <th>Actions</th>
          </tr>
        </thead>
        <tbody>
        <% for (Map<String,Object> r : recentReservations) {
             String gName  = (String)r.get("guestName");
             String gEmail = (String)r.get("guestEmail");
             String gInit  = gName != null && gName.length()>0 ? gName.substring(0,1).toUpperCase() : "?";
             String rNum   = (String)r.get("roomNumber");
             String rType  = (String)r.get("roomType");
             String status = (String)r.get("status");
             String badgeCss = "badge-" + (status != null ? status.toLowerCase() : "pending");
             String statusLbl = status != null ? status.replace("_"," ") : "";
             int resId = (Integer)r.get("id");
        %>
          <tr>
            <td>
              <div class="guest-cell">
                <div class="guest-avatar"><%= gInit %></div>
                <div>
                  <div class="guest-name"><%= gName != null ? gName : "Unknown" %></div>
                  <div class="guest-email"><%= gEmail != null ? gEmail : "" %></div>
                </div>
              </div>
            </td>
            <td><code style="font-size:.73rem;background:#f1f5f9;padding:3px 7px;border-radius:5px;"><%= r.get("reservationNumber") %></code></td>
            <td>
              <span class="room-tag"><i class="fas fa-bed"></i> <%= rNum %></span>
              <% if(rType!=null && !rType.isEmpty()){ %><div style="font-size:.7rem;color:#94a3b8;margin-top:2px;"><%= rType %></div><% } %>
            </td>
            <td style="font-size:.82rem;"><%= r.get("checkInDate") %></td>
            <td style="font-size:.82rem;"><%= r.get("checkOutDate") %></td>
            <td style="text-align:center;"><%= r.get("nights") %>n</td>
            <td><span class="amount-val"><%= r.get("amount") %></span></td>
            <td><span class="badge <%= badgeCss %>"><span class="badge-dot"></span><%= statusLbl %></span></td>
            <td>
              <div style="display:flex;gap:5px;flex-wrap:wrap;">
                <a href="<%= ctx %>/admin/reservations?action=view&id=<%= resId %>" class="action-btn btn-view"><i class="fas fa-eye"></i></a>
                <a href="<%= ctx %>/admin/reservations?action=edit&id=<%= resId %>" class="action-btn btn-edit"><i class="fas fa-edit"></i></a>
              </div>
            </td>
          </tr>
        <% } %>
        </tbody>
      </table>
      </div>
      <% } %>
    </div>

    <!-- BOTTOM ROW: Quick Actions + Revenue Summary -->
    <div class="grid-2">

      <!-- Quick Actions -->
      <div class="card">
        <div class="card-header">
          <div class="card-title"><i class="fas fa-bolt"></i> Quick Actions</div>
        </div>
        <div class="card-body">
          <div class="quick-actions">
            <a href="<%= ctx %>/admin/users" class="qa-btn">
              <div class="qa-icon" style="background:#dbeafe;color:#2563eb;"><i class="fas fa-user-plus"></i></div>
              <span class="qa-label">Manage Users</span>
            </a>
            <a href="<%= ctx %>/admin/rooms" class="qa-btn">
              <div class="qa-icon" style="background:#d1fae5;color:#059669;"><i class="fas fa-bed"></i></div>
              <span class="qa-label">Manage Rooms</span>
            </a>
            <a href="<%= ctx %>/admin/reservations" class="qa-btn">
              <div class="qa-icon" style="background:#ede9fe;color:#7c3aed;"><i class="fas fa-calendar-alt"></i></div>
              <span class="qa-label">Reservations</span>
            </a>
            <a href="<%= ctx %>/admin/reviews" class="qa-btn">
              <div class="qa-icon" style="background:#fef3c7;color:#d97706;"><i class="fas fa-star"></i></div>
              <span class="qa-label">Reviews</span>
            </a>
            <a href="<%= ctx %>/admin/offers" class="qa-btn">
              <div class="qa-icon" style="background:#fee2e2;color:#dc2626;"><i class="fas fa-tag"></i></div>
              <span class="qa-label">Offers</span>
            </a>
            <a href="<%= ctx %>/admin/reports" class="qa-btn">
              <div class="qa-icon" style="background:#cffafe;color:#0891b2;"><i class="fas fa-chart-bar"></i></div>
              <span class="qa-label">Reports</span>
            </a>
            <a href="<%= ctx %>/staff/checkin" class="qa-btn">
              <div class="qa-icon" style="background:#d1fae5;color:#059669;"><i class="fas fa-sign-in-alt"></i></div>
              <span class="qa-label">Check-In</span>
            </a>
            <a href="<%= ctx %>/staff/checkout" class="qa-btn">
              <div class="qa-icon" style="background:#fee2e2;color:#dc2626;"><i class="fas fa-sign-out-alt"></i></div>
              <span class="qa-label">Check-Out</span>
            </a>
            <a href="<%= ctx %>/admin/settings" class="qa-btn">
              <div class="qa-icon" style="background:#f1f5f9;color:#475569;"><i class="fas fa-cog"></i></div>
              <span class="qa-label">Settings</span>
            </a>
          </div>
        </div>
      </div>

      <!-- Revenue Summary Card -->
      <div class="card">
        <div class="card-header">
          <div class="card-title"><i class="fas fa-dollar-sign"></i> Revenue Summary</div>
          <a href="<%= ctx %>/admin/reports" class="card-link"><i class="fas fa-arrow-right"></i> Details</a>
        </div>
        <div class="card-body">
          <div style="display:flex;flex-direction:column;gap:16px;">
            <div style="display:flex;justify-content:space-between;align-items:center;padding:14px 16px;background:#fffbeb;border-radius:10px;border-left:4px solid #f59e0b;">
              <div>
                <div style="font-size:.72rem;color:#92400e;font-weight:700;text-transform:uppercase;letter-spacing:.8px;">Today</div>
                <div style="font-size:1.4rem;font-weight:800;color:#1e2a38;"><%= revenueToday %></div>
              </div>
              <i class="fas fa-sun" style="font-size:1.6rem;color:#f59e0b;opacity:.6;"></i>
            </div>
            <div style="display:flex;justify-content:space-between;align-items:center;padding:14px 16px;background:#eff6ff;border-radius:10px;border-left:4px solid #3b82f6;">
              <div>
                <div style="font-size:.72rem;color:#1e40af;font-weight:700;text-transform:uppercase;letter-spacing:.8px;">This Month</div>
                <div style="font-size:1.4rem;font-weight:800;color:#1e2a38;"><%= revenueThisMonth %></div>
              </div>
              <i class="fas fa-calendar" style="font-size:1.6rem;color:#3b82f6;opacity:.6;"></i>
            </div>
            <div style="display:flex;justify-content:space-between;align-items:center;padding:14px 16px;background:#f0fdf4;border-radius:10px;border-left:4px solid #10b981;">
              <div>
                <div style="font-size:.72rem;color:#065f46;font-weight:700;text-transform:uppercase;letter-spacing:.8px;">This Year</div>
                <div style="font-size:1.4rem;font-weight:800;color:#1e2a38;"><%= revenueThisYear %></div>
              </div>
              <i class="fas fa-chart-line" style="font-size:1.6rem;color:#10b981;opacity:.6;"></i>
            </div>
            <div style="display:flex;justify-content:space-between;align-items:center;padding:14px 16px;background:#f5f3ff;border-radius:10px;border-left:4px solid #8b5cf6;">
              <div>
                <div style="font-size:.72rem;color:#5b21b6;font-weight:700;text-transform:uppercase;letter-spacing:.8px;">All Time Total</div>
                <div style="font-size:1.4rem;font-weight:800;color:#1e2a38;"><%= revenueTotal %></div>
              </div>
              <i class="fas fa-infinity" style="font-size:1.6rem;color:#8b5cf6;opacity:.6;"></i>
            </div>
          </div>
        </div>
      </div>
    </div>

  </main>
</div><!-- /main-content -->

<!-- ===== JAVASCRIPT ===== -->
<script>
  var CTX = '<%= ctx %>';

  /* ── SIDEBAR ── */
  var sidebar = document.getElementById('sidebar');
  var overlay = document.getElementById('sidebarOverlay');
  var toggle  = document.getElementById('sidebarToggle');
  if (toggle) {
    toggle.addEventListener('click', function() {
      sidebar.classList.toggle('open');
      overlay.classList.toggle('visible');
    });
  }
  if (overlay) {
    overlay.addEventListener('click', function() {
      sidebar.classList.remove('open');
      overlay.classList.remove('visible');
    });
  }

  /* ── ALERT AUTO-DISMISS ── */
  setTimeout(function() {
    ['alertSuccess','alertError'].forEach(function(id) {
      var el = document.getElementById(id);
      if (el) { el.style.transition='opacity .5s'; el.style.opacity='0'; setTimeout(function(){ if(el.parentNode) el.remove(); }, 500); }
    });
  }, 5000);

  /* ── REVENUE LINE CHART ── */
  (function() {
    var ctx = document.getElementById('revenueChart');
    if (!ctx) return;
    var labels  = <%= chartMonthLabels %>;
    var amounts = <%= chartMonthRevenue %>;
    if (labels.length === 0) { labels = ['No Data']; amounts = [0]; }
    new Chart(ctx, {
      type: 'line',
      data: {
        labels: labels,
        datasets: [{
          label: 'Revenue (Rs.)',
          data: amounts,
          borderColor: '#f59e0b',
          backgroundColor: 'rgba(245,158,11,0.08)',
          borderWidth: 2.5,
          pointBackgroundColor: '#f59e0b',
          pointRadius: 4,
          pointHoverRadius: 6,
          tension: 0.35,
          fill: true
        }]
      },
      options: {
        responsive: true, maintainAspectRatio: false,
        plugins: { legend: { display: false } },
        scales: {
          x: { grid: { display: false }, ticks: { font: { size: 11 } } },
          y: { grid: { color: '#f1f5f9' }, ticks: { font: { size: 11 }, callback: function(v){ return 'Rs. '+v.toLocaleString(); } } }
        }
      }
    });
  })();

  /* ── STATUS PIE CHART ── */
  (function() {
    var ctx = document.getElementById('statusChart');
    if (!ctx) return;
    var data = <%= chartStatusData %>;
    new Chart(ctx, {
      type: 'doughnut',
      data: {
        labels: ['Pending','Confirmed','Checked In','Checked Out','Cancelled'],
        datasets: [{
          data: data,
          backgroundColor: ['#fbbf24','#3b82f6','#10b981','#94a3b8','#ef4444'],
          borderWidth: 2,
          borderColor: '#fff',
          hoverOffset: 6
        }]
      },
      options: {
        responsive: true, maintainAspectRatio: false,
        plugins: {
          legend: { position: 'bottom', labels: { font: { size: 11 }, padding: 12, usePointStyle: true } }
        },
        cutout: '62%'
      }
    });
  })();

  /* ── ROOM TYPE BAR CHART ── */
  (function() {
    var ctx = document.getElementById('roomChart');
    if (!ctx) return;
    var types    = <%= chartRoomTypes %>;
    var totals   = <%= chartRoomTotals %>;
    var occupied = <%= chartRoomOccupied %>;
    if (types.length === 0) { types=['No Data']; totals=[0]; occupied=[0]; }
    new Chart(ctx, {
      type: 'bar',
      data: {
        labels: types,
        datasets: [
          { label: 'Total',    data: totals,   backgroundColor: 'rgba(59,130,246,0.15)', borderColor: '#3b82f6', borderWidth: 1.5, borderRadius: 5 },
          { label: 'Occupied', data: occupied,  backgroundColor: 'rgba(239,68,68,0.7)',   borderColor: '#ef4444', borderWidth: 1.5, borderRadius: 5 }
        ]
      },
      options: {
        responsive: true, maintainAspectRatio: false,
        plugins: { legend: { position: 'top', labels: { font: { size: 11 }, usePointStyle: true } } },
        scales: {
          x: { grid: { display: false }, ticks: { font: { size: 11 } } },
          y: { beginAtZero: true, grid: { color: '#f1f5f9' }, ticks: { font: { size: 11 }, stepSize: 1 } }
        }
      }
    });
  })();
</script>
</body>
</html>
