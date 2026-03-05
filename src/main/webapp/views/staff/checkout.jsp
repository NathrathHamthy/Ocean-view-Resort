<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="com.oceanview.model.User,com.oceanview.model.Reservation,com.oceanview.model.Room,com.oceanview.util.Constants,java.util.List,java.util.Collections,java.time.LocalDate,java.time.format.DateTimeFormatter" %>
<%
    User currentUser = (User) session.getAttribute(Constants.SESSION_USER);
    if (currentUser == null || (!currentUser.isStaff() && !currentUser.isAdmin())) {
        response.sendRedirect(request.getContextPath() + "/login"); return;
    }
    String ctx = request.getContextPath();
    String errorMsg   = (String) request.getAttribute(Constants.ATTR_ERROR);
    String successMsg = (String) request.getAttribute(Constants.ATTR_SUCCESS);

    List<Reservation> todayCheckOuts  = (List<Reservation>) request.getAttribute("todayCheckOuts");
    List<Reservation> activeStays     = (List<Reservation>) request.getAttribute("activeStays");
    List<Reservation> recentCheckOuts = (List<Reservation>) request.getAttribute("recentCheckOuts");
    if (todayCheckOuts  == null) todayCheckOuts  = Collections.emptyList();
    if (activeStays     == null) activeStays     = Collections.emptyList();
    if (recentCheckOuts == null) recentCheckOuts = Collections.emptyList();

    int todayTotal     = request.getAttribute("todayTotal")     != null ? (Integer)request.getAttribute("todayTotal")     : 0;
    int pendingToday   = request.getAttribute("pendingToday")   != null ? (Integer)request.getAttribute("pendingToday")   : 0;
    int completedToday = request.getAttribute("completedToday") != null ? (Integer)request.getAttribute("completedToday") : 0;
    int activeCount    = request.getAttribute("activeCount")    != null ? (Integer)request.getAttribute("activeCount")    : 0;

    DateTimeFormatter displayFmt = DateTimeFormatter.ofPattern("dd MMM yyyy");
    String todayStr  = LocalDate.now().format(DateTimeFormatter.ofPattern("EEEE, MMMM dd, yyyy"));
    String staffName = currentUser.getFullName() != null ? currentUser.getFullName() : currentUser.getUsername();
    String staffInitials;
    try {
        int sp = staffName.indexOf(' ');
        staffInitials = sp > 0
            ? ("" + staffName.charAt(0) + staffName.charAt(sp + 1)).toUpperCase()
            : staffName.substring(0, 1).toUpperCase();
    } catch (Exception e) { staffInitials = staffName.substring(0, 1).toUpperCase(); }
%>
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Check-Out Management | Ocean View Resort</title>
<link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
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
.sidebar{width:260px;min-height:100vh;background:linear-gradient(180deg,#0d2137 0%,#1a3a5c 100%);display:flex;flex-direction:column;position:fixed;top:0;left:0;z-index:100;transition:transform .3s ease;box-shadow:3px 0 15px rgba(0,0,0,.2)}
.sidebar-brand{padding:24px 20px;display:flex;align-items:center;gap:12px;border-bottom:1px solid rgba(255,255,255,.1)}
.brand-logo{width:42px;height:42px;background:linear-gradient(135deg,#00acc1,#0077b6);border-radius:10px;display:flex;align-items:center;justify-content:center;font-size:1.2rem;color:#fff;font-weight:700;flex-shrink:0}
.brand-text{display:flex;flex-direction:column}
.brand-name{font-size:.95rem;font-weight:700;color:#fff;letter-spacing:.5px}
.brand-sub{font-size:.7rem;color:rgba(255,255,255,.5);text-transform:uppercase;letter-spacing:1px}
.sidebar-user{padding:20px;display:flex;align-items:center;gap:12px;border-bottom:1px solid rgba(255,255,255,.08);background:rgba(0,0,0,.15)}
.user-avatar{width:40px;height:40px;background:linear-gradient(135deg,#e53935,#b71c1c);border-radius:50%;display:flex;align-items:center;justify-content:center;font-size:.9rem;font-weight:700;color:#fff;flex-shrink:0}
.user-info{min-width:0}
.user-name{font-size:.85rem;font-weight:600;color:#fff;white-space:nowrap;overflow:hidden;text-overflow:ellipsis}
.user-role{font-size:.7rem;color:rgba(255,255,255,.5);text-transform:uppercase;letter-spacing:.8px}
.sidebar-nav{flex:1;padding:16px 0;overflow-y:auto}
.nav-section-label{font-size:.65rem;font-weight:700;color:rgba(255,255,255,.35);text-transform:uppercase;letter-spacing:1.5px;padding:14px 20px 6px}
.nav-link{display:flex;align-items:center;gap:12px;padding:11px 20px;color:rgba(255,255,255,.7);text-decoration:none;font-size:.88rem;font-weight:500;transition:all .2s}
.nav-link:hover{color:#fff;background:rgba(255,255,255,.08)}
.nav-link.active{color:#fff;background:rgba(229,57,53,.25);border-left:3px solid #e53935}
.nav-icon{width:20px;text-align:center;font-size:.95rem}
.nav-badge{margin-left:auto;background:#e53935;color:#fff;font-size:.65rem;font-weight:700;border-radius:10px;padding:2px 7px;min-width:20px;text-align:center}
.sidebar-footer{padding:16px 20px;border-top:1px solid rgba(255,255,255,.08)}
.sidebar-footer a{display:flex;align-items:center;gap:10px;color:rgba(255,255,255,.5);font-size:.82rem;text-decoration:none;padding:8px 0;transition:color .2s}
.sidebar-footer a:hover{color:#fff}
.sidebar-overlay{position:fixed;inset:0;background:rgba(0,0,0,.45);z-index:99;display:none}
.sidebar-overlay.visible{display:block}

/* ===== MAIN CONTENT ===== */
.main-content{margin-left:260px;flex:1;display:flex;flex-direction:column;min-height:100vh}

/* ===== TOPBAR ===== */
.topbar{background:#fff;padding:0 28px;height:64px;display:flex;align-items:center;justify-content:space-between;border-bottom:1px solid #e2e8f0;box-shadow:0 2px 8px rgba(0,0,0,.04);position:sticky;top:0;z-index:50}
.topbar-left{display:flex;align-items:center;gap:16px}
.sidebar-toggle{display:none;background:none;border:none;cursor:pointer;font-size:1.2rem;color:#64748b;padding:6px;border-radius:6px;transition:background .2s}
.sidebar-toggle:hover{background:#f1f5f9}
.page-title{font-size:1.15rem;font-weight:700;color:#1e2a38}
.page-subtitle{font-size:.78rem;color:#64748b;margin-top:1px}
.topbar-right{display:flex;align-items:center;gap:12px}
.topbar-date{font-size:.8rem;color:#64748b;font-weight:500}
.topbar-btn{display:flex;align-items:center;gap:7px;padding:8px 14px;border-radius:8px;font-size:.82rem;font-weight:600;cursor:pointer;border:none;transition:all .2s;text-decoration:none;font-family:inherit}
.btn-outline{background:transparent;border:1.5px solid #e2e8f0;color:#374151}
.btn-outline:hover{border-color:#e53935;color:#e53935;background:#fff5f5}
.btn-primary{background:linear-gradient(135deg,#e53935,#c62828);color:#fff;box-shadow:0 2px 8px rgba(229,57,53,.3)}
.btn-primary:hover{transform:translateY(-1px);box-shadow:0 4px 12px rgba(229,57,53,.4)}

/* ===== PAGE CONTENT ===== */
.page-content{flex:1;padding:28px}

/* ===== ALERTS ===== */
.alert{display:flex;align-items:center;gap:12px;padding:14px 18px;border-radius:10px;margin-bottom:20px;font-size:.88rem;font-weight:500;animation:slideDown .3s ease}
@keyframes slideDown{from{opacity:0;transform:translateY(-10px)}to{opacity:1;transform:translateY(0)}}
.alert-success{background:#ecfdf5;color:#065f46;border:1px solid #6ee7b7}
.alert-error{background:#fef2f2;color:#991b1b;border:1px solid #fca5a5}
.alert-close{margin-left:auto;background:none;border:none;cursor:pointer;font-size:1.1rem;color:inherit;opacity:.6;transition:opacity .2s}
.alert-close:hover{opacity:1}

/* ===== STATS ===== */
.stats-grid{display:grid;grid-template-columns:repeat(4,1fr);gap:18px;margin-bottom:28px}
.stat-card{background:#fff;border-radius:14px;padding:20px 22px;display:flex;align-items:center;gap:16px;box-shadow:0 1px 4px rgba(0,0,0,.06);border:1px solid #e8eef5;transition:transform .2s,box-shadow .2s}
.stat-card:hover{transform:translateY(-2px);box-shadow:0 6px 20px rgba(0,0,0,.1)}
.stat-icon{width:52px;height:52px;border-radius:12px;display:flex;align-items:center;justify-content:center;font-size:1.3rem;flex-shrink:0}
.stat-icon.red{background:#fee2e2;color:#dc2626}
.stat-icon.green{background:#d1fae5;color:#059669}
.stat-icon.amber{background:#fef3c7;color:#d97706}
.stat-icon.blue{background:#e0f2fe;color:#0077b6}
.stat-value{font-size:1.8rem;font-weight:800;color:#1e2a38;line-height:1}
.stat-label{font-size:.78rem;color:#64748b;margin-top:3px;font-weight:500}

/* ===== SEARCH SECTION ===== */
.search-section{background:#fff;border-radius:14px;padding:22px;margin-bottom:24px;box-shadow:0 1px 4px rgba(0,0,0,.06);border:1px solid #e8eef5}
.search-title{font-size:1rem;font-weight:700;color:#1e2a38;margin-bottom:14px;display:flex;align-items:center;gap:8px}
.search-title i{color:#e53935}
.search-form{display:flex;gap:12px;flex-wrap:wrap}
.search-input-wrap{flex:1;min-width:220px;position:relative}
.search-input-wrap i{position:absolute;left:13px;top:50%;transform:translateY(-50%);color:#94a3b8;font-size:.95rem;pointer-events:none}
.search-input{width:100%;padding:10px 14px 10px 38px;border:1.5px solid #e2e8f0;border-radius:8px;font-size:.88rem;color:#1e2a38;background:#f8fafc;transition:all .2s;outline:none;font-family:inherit}
.search-input:focus{border-color:#e53935;background:#fff;box-shadow:0 0 0 3px rgba(229,57,53,.1)}
.search-input::placeholder{color:#94a3b8}
.search-btn{padding:10px 20px;background:linear-gradient(135deg,#e53935,#c62828);color:#fff;border:none;border-radius:8px;font-size:.88rem;font-weight:600;cursor:pointer;display:flex;align-items:center;gap:7px;transition:all .2s;white-space:nowrap;font-family:inherit}
.search-btn:hover{transform:translateY(-1px);box-shadow:0 4px 12px rgba(229,57,53,.35)}
.search-results-wrap{margin-top:14px;display:none}
.search-results-wrap.visible{display:block}
.search-result-item{display:flex;align-items:center;justify-content:space-between;padding:12px 16px;border:1.5px solid #e8eef5;border-radius:9px;margin-bottom:8px;background:#f8fafc;transition:all .2s;gap:12px;flex-wrap:wrap}
.search-result-item:hover{border-color:#e53935;background:#fff5f5}
.search-result-info{display:flex;flex-direction:column;gap:3px}
.search-result-name{font-size:.92rem;font-weight:700;color:#1e2a38}
.search-result-meta{font-size:.78rem;color:#64748b}
.search-result-actions{display:flex;gap:8px;flex-shrink:0}
.search-spinner{display:none;text-align:center;padding:14px;color:#64748b;font-size:.85rem}
.search-spinner.visible{display:block}
.search-no-results{display:none;text-align:center;padding:14px;color:#94a3b8;font-size:.85rem}
.search-no-results.visible{display:block}

/* ===== TABS ===== */
.tabs-bar{display:flex;gap:4px;margin-bottom:20px;background:#fff;padding:6px;border-radius:12px;box-shadow:0 1px 4px rgba(0,0,0,.06);border:1px solid #e8eef5;width:fit-content}
.tab-btn{padding:9px 18px;border-radius:8px;border:none;background:transparent;font-size:.85rem;font-weight:600;color:#64748b;cursor:pointer;transition:all .2s;display:flex;align-items:center;gap:7px;font-family:inherit}
.tab-btn:hover{background:#f1f5f9;color:#1e2a38}
.tab-btn.active{background:linear-gradient(135deg,#e53935,#c62828);color:#fff;box-shadow:0 2px 8px rgba(229,57,53,.3)}
.tab-count{font-size:.7rem;font-weight:700;padding:2px 7px;border-radius:10px;background:rgba(255,255,255,.25)}
.tab-btn:not(.active) .tab-count{background:#e8eef5;color:#64748b}

/* ===== TABLE CARD ===== */
.table-card{background:#fff;border-radius:14px;box-shadow:0 1px 4px rgba(0,0,0,.06);border:1px solid #e8eef5;overflow:hidden}
.table-card-header{padding:18px 22px;display:flex;align-items:center;justify-content:space-between;border-bottom:1px solid #f0f4f8;flex-wrap:wrap;gap:10px}
.table-card-title{font-size:1rem;font-weight:700;color:#1e2a38;display:flex;align-items:center;gap:8px}
.table-card-title i{color:#e53935}
.tab-panel{display:none}
.tab-panel.active{display:block}
table{width:100%;border-collapse:collapse}
thead th{padding:12px 16px;font-size:.72rem;font-weight:700;color:#64748b;text-transform:uppercase;letter-spacing:.8px;background:#f8fafc;border-bottom:1px solid #e8eef5;text-align:left;white-space:nowrap}
tbody tr{border-bottom:1px solid #f1f5f9;transition:background .15s}
tbody tr:last-child{border-bottom:none}
tbody tr:hover{background:#f8fafc}
td{padding:13px 16px;font-size:.85rem;color:#374151;vertical-align:middle}
.guest-cell{display:flex;align-items:center;gap:10px}
.guest-avatar{width:36px;height:36px;border-radius:50%;background:linear-gradient(135deg,#e53935,#c62828);display:flex;align-items:center;justify-content:center;font-size:.78rem;font-weight:700;color:#fff;flex-shrink:0;text-transform:uppercase}
.guest-name{font-weight:600;color:#1e2a38;font-size:.88rem}
.guest-id{font-size:.73rem;color:#94a3b8;margin-top:2px}
.room-badge{display:inline-flex;align-items:center;gap:5px;padding:4px 10px;border-radius:6px;font-size:.78rem;font-weight:600;background:#e0f2fe;color:#0077b6}
.dates-cell{font-size:.82rem;color:#374151}
.dates-cell .nights{font-size:.72rem;color:#94a3b8;margin-top:2px;display:flex;align-items:center;gap:4px}
.amount-display{font-size:.88rem;font-weight:600;color:#059669}
.overdue-badge{font-size:.72rem;font-weight:700;padding:2px 8px;border-radius:20px;background:#fee2e2;color:#dc2626;display:inline-flex;align-items:center;gap:4px;margin-top:3px}

/* ===== STATUS BADGES ===== */
.status-badge{display:inline-flex;align-items:center;gap:5px;padding:4px 11px;border-radius:20px;font-size:.73rem;font-weight:700;letter-spacing:.3px;white-space:nowrap}
.status-confirmed{background:#dbeafe;color:#1d4ed8}
.status-pending{background:#fef3c7;color:#92400e}
.status-checked_in{background:#d1fae5;color:#065f46}
.status-checked_out{background:#f3f4f6;color:#4b5563}
.status-cancelled{background:#fee2e2;color:#991b1b}
.status-dot{width:6px;height:6px;border-radius:50%;background:currentColor}

/* ===== ACTION BUTTONS ===== */
.actions-cell{display:flex;gap:6px;flex-wrap:wrap}
.action-btn{padding:6px 12px;border-radius:7px;border:none;font-size:.78rem;font-weight:600;cursor:pointer;display:flex;align-items:center;gap:5px;transition:all .2s;white-space:nowrap;font-family:inherit}
.btn-checkout{background:#fee2e2;color:#dc2626}
.btn-checkout:hover{background:#dc2626;color:#fff}
.btn-view{background:#f1f5f9;color:#475569}
.btn-view:hover{background:#475569;color:#fff}
.btn-receipt{background:#d1fae5;color:#065f46}
.btn-receipt:hover{background:#059669;color:#fff}

/* ===== EMPTY STATE ===== */
.empty-state{text-align:center;padding:50px 20px;color:#94a3b8}
.empty-state i{font-size:2.5rem;margin-bottom:12px;display:block;color:#cbd5e1}
.empty-state p{font-size:.9rem;margin-bottom:6px;color:#64748b;font-weight:500}
.empty-state small{font-size:.78rem;color:#94a3b8}

/* ===== MODAL ===== */
.modal-overlay{position:fixed;inset:0;background:rgba(10,20,40,.6);z-index:1000;display:flex;align-items:center;justify-content:center;padding:20px;opacity:0;pointer-events:none;transition:opacity .25s ease;backdrop-filter:blur(4px)}
.modal-overlay.open{opacity:1;pointer-events:all}
.modal-box{background:#fff;border-radius:18px;box-shadow:0 25px 60px rgba(0,0,0,.2);width:100%;max-width:680px;max-height:92vh;overflow-y:auto;transform:translateY(20px) scale(.97);transition:transform .25s ease}
.modal-overlay.open .modal-box{transform:translateY(0) scale(1)}
.modal-header{padding:22px 26px;display:flex;align-items:center;justify-content:space-between;border-bottom:1px solid #f0f4f8;position:sticky;top:0;background:#fff;z-index:1;border-radius:18px 18px 0 0}
.modal-header-left{display:flex;align-items:center;gap:12px}
.modal-icon{width:44px;height:44px;background:linear-gradient(135deg,#e53935,#c62828);border-radius:10px;display:flex;align-items:center;justify-content:center;color:#fff;font-size:1.1rem}
.modal-icon.view{background:linear-gradient(135deg,#0077b6,#023e8a)}
.modal-title{font-size:1.05rem;font-weight:700;color:#1e2a38}
.modal-subtitle{font-size:.78rem;color:#64748b;margin-top:2px}
.modal-close{width:34px;height:34px;border-radius:8px;border:none;background:#f1f5f9;color:#64748b;font-size:1rem;cursor:pointer;display:flex;align-items:center;justify-content:center;transition:all .2s}
.modal-close:hover{background:#e2e8f0;color:#1e2a38}
.modal-body{padding:24px 26px}
.modal-footer{padding:18px 26px;display:flex;justify-content:flex-end;gap:10px;border-top:1px solid #f0f4f8;background:#f8fafc;border-radius:0 0 18px 18px;flex-wrap:wrap}

/* ===== MODAL INTERNALS ===== */
.billing-summary{background:linear-gradient(135deg,#0d2137,#1a3a5c);border-radius:12px;padding:18px 20px;margin-bottom:20px;color:#fff}
.billing-row{display:flex;justify-content:space-between;align-items:center;padding:7px 0;font-size:.85rem;border-bottom:1px solid rgba(255,255,255,.08)}
.billing-row:last-child{border-bottom:none;padding-top:10px;margin-top:4px;border-top:1px solid rgba(255,255,255,.2)}
.billing-label{color:rgba(255,255,255,.7)}
.billing-value{font-weight:700;color:#fff}
.billing-value.total{font-size:1.1rem;color:#4dd0e1}
.billing-value.due{font-size:1.1rem;color:#f87171}
.extra-charge-row{display:flex;align-items:center;gap:10px}
.extra-input{padding:5px 10px;border:1.5px solid rgba(255,255,255,.2);border-radius:7px;background:rgba(255,255,255,.1);color:#fff;font-size:.82rem;width:100px;outline:none;font-family:inherit}
.extra-input:focus{border-color:#4dd0e1;background:rgba(255,255,255,.15)}
.extra-input::placeholder{color:rgba(255,255,255,.4)}

.section-divider{height:1px;background:#f0f4f8;margin:18px 0}
.section-subtitle{font-size:.82rem;font-weight:700;color:#475569;text-transform:uppercase;letter-spacing:.8px;margin-bottom:14px;display:flex;align-items:center;gap:7px}
.section-subtitle i{color:#e53935;font-size:.88rem}

.form-group{margin-bottom:16px}
.form-label{display:block;font-size:.8rem;font-weight:600;color:#374151;margin-bottom:6px}
.form-label .req{color:#ef4444;margin-left:2px}
.form-control{width:100%;padding:10px 13px;border:1.5px solid #e2e8f0;border-radius:8px;font-size:.88rem;color:#1e2a38;background:#f8fafc;outline:none;transition:all .2s;font-family:inherit}
.form-control:focus{border-color:#e53935;background:#fff;box-shadow:0 0 0 3px rgba(229,57,53,.1)}
.form-row{display:grid;grid-template-columns:1fr 1fr;gap:14px}

/* ===== CHECKLIST ===== */
.checklist{display:flex;flex-direction:column;gap:10px}
.check-item{display:flex;align-items:center;gap:10px;padding:10px 14px;border:1.5px solid #e2e8f0;border-radius:9px;cursor:pointer;transition:all .2s;user-select:none}
.check-item:hover{border-color:#e53935;background:#fff5f5}
.check-item input[type=checkbox]{width:18px;height:18px;accent-color:#e53935;cursor:pointer}
.check-item-label{font-size:.88rem;font-weight:500;color:#374151}
.check-item.checked{border-color:#059669;background:#f0fdf4}
.check-item.checked .check-item-label{color:#065f46}

/* ===== STAR RATING ===== */
.star-rating{display:flex;gap:6px;margin-bottom:12px}
.star{font-size:1.6rem;color:#d1d5db;cursor:pointer;transition:all .2s;line-height:1}
.star.active{color:#f59e0b}
.star:hover{transform:scale(1.15);color:#f59e0b}

/* ===== MODAL BUTTONS ===== */
.modal-btn{padding:10px 20px;border-radius:9px;border:none;font-size:.88rem;font-weight:600;cursor:pointer;display:flex;align-items:center;gap:7px;transition:all .2s;font-family:inherit}
.modal-btn-cancel{background:#f1f5f9;color:#475569}
.modal-btn-cancel:hover{background:#e2e8f0}
.modal-btn-checkout{background:linear-gradient(135deg,#e53935,#c62828);color:#fff;box-shadow:0 2px 8px rgba(229,57,53,.3)}
.modal-btn-checkout:hover{transform:translateY(-1px);box-shadow:0 4px 14px rgba(229,57,53,.4)}
.modal-btn-loading{opacity:.7;cursor:not-allowed;pointer-events:none}

.info-grid{display:grid;grid-template-columns:1fr 1fr;gap:16px;margin-bottom:20px}
.info-item{display:flex;flex-direction:column;gap:4px}
.info-label-sm{font-size:.72rem;font-weight:700;color:#94a3b8;text-transform:uppercase;letter-spacing:.8px}
.info-value-sm{font-size:.9rem;font-weight:600;color:#1e2a38}
.info-value-sm.big{font-size:1.2rem;color:#e53935}

/* ===== RESPONSIVE ===== */
@media(max-width:1100px){.stats-grid{grid-template-columns:repeat(2,1fr)}}
@media(max-width:900px){
    .sidebar{transform:translateX(-100%)}
    .sidebar.open{transform:translateX(0)}
    .main-content{margin-left:0}
    .sidebar-toggle{display:flex}
}
@media(max-width:640px){
    .stats-grid{grid-template-columns:1fr 1fr}
    .page-content{padding:16px}
    .info-grid,.form-row{grid-template-columns:1fr}
    .topbar-date{display:none}
    .modal-box{max-width:100%}
}
</style>
</head>
<body>
<div class="sidebar-overlay" id="sidebarOverlay"></div>

<!-- ===== SIDEBAR ===== -->
<aside class="sidebar" id="sidebar">
  <div class="sidebar-brand">
    <div class="brand-logo"><i class="fas fa-water"></i></div>
    <div class="brand-text">
      <span class="brand-name">Ocean View</span>
      <span class="brand-sub">Resort</span>
    </div>
  </div>
  <div class="sidebar-user">
    <div class="user-avatar"><%= staffInitials %></div>
    <div class="user-info">
      <div class="user-name"><%= staffName %></div>
      <div class="user-role"><%= currentUser.isAdmin() ? "Administrator" : "Staff" %></div>
    </div>
  </div>
  <nav class="sidebar-nav">
    <a class="nav-link" href="<%= ctx %>/dashboard"><span class="nav-icon"><i class="fas fa-th-large"></i></span> Dashboard</a>
    <a class="nav-link" href="<%= ctx %>/staff/reservations"><span class="nav-icon"><i class="fas fa-calendar-alt"></i></span> Reservations</a>
    <a class="nav-link" href="<%= ctx %>/staff/checkin"><span class="nav-icon"><i class="fas fa-sign-in-alt"></i></span> Check-In</a>
    <a class="nav-link active" href="<%= ctx %>/staff/checkout"><span class="nav-icon"><i class="fas fa-sign-out-alt"></i></span> Check-Out <span class="nav-badge"><%= pendingToday %></span></a>
    <a class="nav-link" href="<%= ctx %>/staff/bookings"><span class="nav-icon"><i class="fas fa-book-open"></i></span> All Bookings</a>
  </nav>
  <div class="sidebar-footer">
    <a href="<%= ctx %>/settings"><i class="fas fa-cog"></i> Settings</a>
    <a href="<%= ctx %>/logout"><i class="fas fa-power-off"></i> Logout</a>
  </div>
</aside>

<!-- ===== MAIN CONTENT ===== -->
<div class="main-content">

  <!-- TOPBAR -->
  <header class="topbar">
    <div class="topbar-left">
      <button class="sidebar-toggle" id="sidebarToggle"><i class="fas fa-bars"></i></button>
      <div>
        <div class="page-title"><i class="fas fa-sign-out-alt" style="color:#e53935;margin-right:8px;"></i>Check-Out Management</div>
        <div class="page-subtitle">Process guest departures and final billing</div>
      </div>
    </div>
    <div class="topbar-right">
      <span class="topbar-date"><i class="fas fa-calendar" style="margin-right:5px;color:#e53935;"></i><%= todayStr %></span>
      <a href="<%= ctx %>/staff/checkin" class="topbar-btn btn-outline"><i class="fas fa-sign-in-alt"></i> Check-In</a>
      <a href="<%= ctx %>/staff/reservations" class="topbar-btn btn-primary"><i class="fas fa-calendar-alt"></i> Reservations</a>
    </div>
  </header>

  <!-- PAGE CONTENT -->
  <main class="page-content">

    <!-- ALERTS -->
    <% if (successMsg != null && !successMsg.isEmpty()) { %>
    <div class="alert alert-success" id="alertSuccess">
      <i class="fas fa-check-circle"></i>
      <span><%= successMsg %></span>
      <button class="alert-close" onclick="this.parentElement.remove()">&times;</button>
    </div>
    <% } %>
    <% if (errorMsg != null && !errorMsg.isEmpty()) { %>
    <div class="alert alert-error" id="alertError">
      <i class="fas fa-exclamation-circle"></i>
      <span><%= errorMsg %></span>
      <button class="alert-close" onclick="this.parentElement.remove()">&times;</button>
    </div>
    <% } %>

    <!-- STATS GRID -->
    <div class="stats-grid">
      <div class="stat-card">
        <div class="stat-icon red"><i class="fas fa-calendar-minus"></i></div>
        <div>
          <div class="stat-value"><%= todayTotal %></div>
          <div class="stat-label">Today's Departures</div>
        </div>
      </div>
      <div class="stat-card">
        <div class="stat-icon amber"><i class="fas fa-clock"></i></div>
        <div>
          <div class="stat-value"><%= pendingToday %></div>
          <div class="stat-label">Awaiting Check-Out</div>
        </div>
      </div>
      <div class="stat-card">
        <div class="stat-icon green"><i class="fas fa-check-double"></i></div>
        <div>
          <div class="stat-value"><%= completedToday %></div>
          <div class="stat-label">Completed Today</div>
        </div>
      </div>
      <div class="stat-card">
        <div class="stat-icon blue"><i class="fas fa-door-open"></i></div>
        <div>
          <div class="stat-value"><%= activeCount %></div>
          <div class="stat-label">Active Stays</div>
        </div>
      </div>
    </div>

    <!-- SEARCH SECTION -->
    <div class="search-section">
      <div class="search-title"><i class="fas fa-search"></i> Quick Search</div>
      <div class="search-form">
        <div class="search-input-wrap">
          <i class="fas fa-search"></i>
          <input type="text" class="search-input" id="searchInput"
                 placeholder="Search by booking ID, guest name, or room number..." autocomplete="off">
        </div>
        <button class="search-btn" onclick="doSearch()">
          <i class="fas fa-search"></i> Search
        </button>
      </div>
      <div class="search-results-wrap" id="searchResultsWrap">
        <div class="search-spinner" id="searchSpinner"><i class="fas fa-spinner fa-spin"></i> Searching...</div>
        <div class="search-no-results" id="searchNoResults"><i class="fas fa-inbox"></i> No reservations found.</div>
        <div id="searchResults"></div>
      </div>
    </div>

    <!-- TABS -->
    <div class="tabs-bar">
      <button class="tab-btn active" onclick="switchTab('today',this)">
        <i class="fas fa-calendar-day"></i> Today's Check-Outs
        <span class="tab-count"><%= todayCheckOuts.size() %></span>
      </button>
      <button class="tab-btn" onclick="switchTab('active',this)">
        <i class="fas fa-door-open"></i> All Active Stays
        <span class="tab-count"><%= activeStays.size() %></span>
      </button>
      <button class="tab-btn" onclick="switchTab('recent',this)">
        <i class="fas fa-history"></i> Recently Checked Out
        <span class="tab-count"><%= recentCheckOuts.size() %></span>
      </button>
    </div>

    <!-- TABLE CARD -->
    <div class="table-card">

      <!-- ── TAB: TODAY ── -->
      <div class="tab-panel active" id="tab-today">
        <div class="table-card-header">
          <div class="table-card-title"><i class="fas fa-calendar-minus"></i> Today's Expected Departures</div>
          <span style="font-size:.78rem;color:#64748b;"><%= todayStr %></span>
        </div>
        <% if (todayCheckOuts.isEmpty()) { %>
        <div class="empty-state">
          <i class="fas fa-calendar-check"></i>
          <p>No check-outs scheduled for today</p>
          <small>Today's departures will appear here</small>
        </div>
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
              <th>Amount Due</th>
              <th>Status</th>
              <th>Actions</th>
            </tr>
          </thead>
          <tbody>
          <%
          for (Reservation r : todayCheckOuts) {
              String gName = r.getGuest() != null ? (r.getGuest().getFirstName() + " " + r.getGuest().getLastName()).trim() : "Guest #" + r.getGuestId();
              String gInit = gName.length() > 0 ? gName.substring(0,1).toUpperCase() : "G";
              String rNum  = r.getRoom() != null ? r.getRoom().getRoomNumber() : "-";
              String rType = r.getRoom() != null && r.getRoom().getRoomType() != null ? r.getRoom().getRoomType().name() : "";
              String ci    = r.getCheckInDate()  != null ? r.getCheckInDate().format(displayFmt)  : "-";
              String co    = r.getCheckOutDate() != null ? r.getCheckOutDate().format(displayFmt) : "-";
              int nts      = r.getNumberOfNights() != null ? r.getNumberOfNights() : 0;
              String amt   = r.getFinalAmount() != null ? String.format("Rs. %.2f", r.getFinalAmount()) : "-";
              String stCss = "status-" + r.getStatus().name().toLowerCase();
              String stLbl = r.getStatus().name().replace("_"," ");
              boolean isCheckedOut = r.getStatus() == Reservation.ReservationStatus.CHECKED_OUT;
              boolean isOverdue    = !isCheckedOut && r.getCheckOutDate() != null && r.getCheckOutDate().isBefore(LocalDate.now());
          %>
            <tr>
              <td>
                <div class="guest-cell">
                  <div class="guest-avatar" style="<%= isCheckedOut ? "background:linear-gradient(135deg,#4b5563,#374151);" : "" %>"><%= gInit %></div>
                  <div>
                    <div class="guest-name"><%= gName %></div>
                    <% if (isOverdue) { %><div class="overdue-badge"><i class="fas fa-exclamation-triangle"></i> Overdue</div><% } %>
                  </div>
                </div>
              </td>
              <td><code style="font-size:.78rem;background:#f1f5f9;padding:3px 7px;border-radius:5px;"><%= r.getReservationNumber() %></code></td>
              <td>
                <span class="room-badge"><i class="fas fa-bed"></i> <%= rNum %></span>
                <% if (!rType.isEmpty()) { %><div style="font-size:.72rem;color:#94a3b8;margin-top:3px;"><%= rType %></div><% } %>
              </td>
              <td class="dates-cell"><%= ci %></td>
              <td class="dates-cell"><%= co %></td>
              <td style="text-align:center;"><%= nts %> night<%= nts!=1?"s":"" %></td>
              <td><span class="amount-display"><%= amt %></span></td>
              <td><span class="status-badge <%= stCss %>"><span class="status-dot"></span><%= stLbl %></span></td>
              <td>
                <div class="actions-cell">
                  <% if (r.canCheckOut()) { %>
                  <button class="action-btn btn-checkout" onclick="openCheckOutModal(<%= r.getReservationId() %>)">
                    <i class="fas fa-sign-out-alt"></i> Check-Out
                  </button>
                  <% } %>
                  <% if (isCheckedOut) { %>
                  <button class="action-btn btn-receipt" onclick="openViewModal(<%= r.getReservationId() %>)">
                    <i class="fas fa-receipt"></i> Receipt
                  </button>
                  <% } %>
                  <button class="action-btn btn-view" onclick="openViewModal(<%= r.getReservationId() %>)">
                    <i class="fas fa-eye"></i>
                  </button>
                </div>
              </td>
            </tr>
          <% } %>
          </tbody>
        </table>
        </div>
        <% } %>
      </div>

      <!-- ── TAB: ACTIVE STAYS ── -->
      <div class="tab-panel" id="tab-active">
        <div class="table-card-header">
          <div class="table-card-title"><i class="fas fa-door-open"></i> All Currently Checked-In Guests</div>
        </div>
        <% if (activeStays.isEmpty()) { %>
        <div class="empty-state">
          <i class="fas fa-bed"></i>
          <p>No active stays at the moment</p>
          <small>Checked-in guests will appear here</small>
        </div>
        <% } else { %>
        <div style="overflow-x:auto;">
        <table>
          <thead>
            <tr>
              <th>Guest</th>
              <th>Booking ID</th>
              <th>Room</th>
              <th>Check-In</th>
              <th>Check-Out Due</th>
              <th>Nights</th>
              <th>Amount</th>
              <th>Actions</th>
            </tr>
          </thead>
          <tbody>
          <%
          for (Reservation r : activeStays) {
              String gName = r.getGuest() != null ? (r.getGuest().getFirstName() + " " + r.getGuest().getLastName()).trim() : "Guest #" + r.getGuestId();
              String gInit = gName.length() > 0 ? gName.substring(0,1).toUpperCase() : "G";
              String rNum  = r.getRoom() != null ? r.getRoom().getRoomNumber() : "-";
              String rType = r.getRoom() != null && r.getRoom().getRoomType() != null ? r.getRoom().getRoomType().name() : "";
              String ci    = r.getCheckInDate()  != null ? r.getCheckInDate().format(displayFmt)  : "-";
              String co    = r.getCheckOutDate() != null ? r.getCheckOutDate().format(displayFmt) : "-";
              int nts      = r.getNumberOfNights() != null ? r.getNumberOfNights() : 0;
              String amt   = r.getFinalAmount() != null ? String.format("Rs. %.2f", r.getFinalAmount()) : "-";
              boolean isOverdue = r.getCheckOutDate() != null && r.getCheckOutDate().isBefore(LocalDate.now());
          %>
            <tr style="<%= isOverdue ? "background:#fff5f5;" : "" %>">
              <td>
                <div class="guest-cell">
                  <div class="guest-avatar" style="background:linear-gradient(135deg,#059669,#047857);"><%= gInit %></div>
                  <div>
                    <div class="guest-name"><%= gName %></div>
                    <% if (isOverdue) { %><div class="overdue-badge"><i class="fas fa-exclamation-triangle"></i> Overdue</div><% } %>
                  </div>
                </div>
              </td>
              <td><code style="font-size:.78rem;background:#f1f5f9;padding:3px 7px;border-radius:5px;"><%= r.getReservationNumber() %></code></td>
              <td>
                <span class="room-badge" style="background:#d1fae5;color:#065f46;"><i class="fas fa-door-open"></i> <%= rNum %></span>
                <% if (!rType.isEmpty()) { %><div style="font-size:.72rem;color:#94a3b8;margin-top:3px;"><%= rType %></div><% } %>
              </td>
              <td class="dates-cell"><%= ci %></td>
              <td class="dates-cell" style="<%= isOverdue ? "color:#dc2626;font-weight:700;" : "" %>"><%= co %></td>
              <td style="text-align:center;"><%= nts %> night<%= nts!=1?"s":"" %></td>
              <td><span class="amount-display"><%= amt %></span></td>
              <td>
                <div class="actions-cell">
                  <button class="action-btn btn-checkout" onclick="openCheckOutModal(<%= r.getReservationId() %>)">
                    <i class="fas fa-sign-out-alt"></i> Check-Out
                  </button>
                  <button class="action-btn btn-view" onclick="openViewModal(<%= r.getReservationId() %>)">
                    <i class="fas fa-eye"></i>
                  </button>
                </div>
              </td>
            </tr>
          <% } %>
          </tbody>
        </table>
        </div>
        <% } %>
      </div>

      <!-- ── TAB: RECENT ── -->
      <div class="tab-panel" id="tab-recent">
        <div class="table-card-header">
          <div class="table-card-title"><i class="fas fa-history"></i> Recently Checked Out (Last 7 Days)</div>
        </div>
        <% if (recentCheckOuts.isEmpty()) { %>
        <div class="empty-state">
          <i class="fas fa-clipboard-check"></i>
          <p>No recent check-outs in the past 7 days</p>
          <small>Completed check-outs will appear here</small>
        </div>
        <% } else { %>
        <div style="overflow-x:auto;">
        <table>
          <thead>
            <tr>
              <th>Guest</th>
              <th>Booking ID</th>
              <th>Room</th>
              <th>Check-In</th>
              <th>Checked Out</th>
              <th>Nights</th>
              <th>Total Paid</th>
              <th>Actions</th>
            </tr>
          </thead>
          <tbody>
          <%
          for (Reservation r : recentCheckOuts) {
              String gName = r.getGuest() != null ? (r.getGuest().getFirstName() + " " + r.getGuest().getLastName()).trim() : "Guest #" + r.getGuestId();
              String gInit = gName.length() > 0 ? gName.substring(0,1).toUpperCase() : "G";
              String rNum  = r.getRoom() != null ? r.getRoom().getRoomNumber() : "-";
              String rType = r.getRoom() != null && r.getRoom().getRoomType() != null ? r.getRoom().getRoomType().name() : "";
              String ci    = r.getCheckInDate()  != null ? r.getCheckInDate().format(displayFmt)  : "-";
              String co    = r.getCheckOutDate() != null ? r.getCheckOutDate().format(displayFmt) : "-";
              int nts      = r.getNumberOfNights() != null ? r.getNumberOfNights() : 0;
              String amt   = r.getFinalAmount() != null ? String.format("Rs. %.2f", r.getFinalAmount()) : "-";
          %>
            <tr>
              <td>
                <div class="guest-cell">
                  <div class="guest-avatar" style="background:linear-gradient(135deg,#4b5563,#374151);"><%= gInit %></div>
                  <div>
                    <div class="guest-name"><%= gName %></div>
                    <div class="guest-id">#<%= r.getReservationNumber() %></div>
                  </div>
                </div>
              </td>
              <td><code style="font-size:.78rem;background:#f1f5f9;padding:3px 7px;border-radius:5px;"><%= r.getReservationNumber() %></code></td>
              <td>
                <span class="room-badge" style="background:#f3f4f6;color:#4b5563;"><i class="fas fa-bed"></i> <%= rNum %></span>
                <% if (!rType.isEmpty()) { %><div style="font-size:.72rem;color:#94a3b8;margin-top:3px;"><%= rType %></div><% } %>
              </td>
              <td class="dates-cell"><%= ci %></td>
              <td class="dates-cell"><%= co %></td>
              <td style="text-align:center;"><%= nts %> night<%= nts!=1?"s":"" %></td>
              <td><span class="amount-display"><%= amt %></span></td>
              <td>
                <div class="actions-cell">
                  <button class="action-btn btn-receipt" onclick="openViewModal(<%= r.getReservationId() %>)">
                    <i class="fas fa-receipt"></i> View
                  </button>
                </div>
              </td>
            </tr>
          <% } %>
          </tbody>
        </table>
        </div>
        <% } %>
      </div>

    </div><!-- /table-card -->
  </main>
</div><!-- /main-content -->

<!-- ===== VIEW MODAL ===== -->
<div class="modal-overlay" id="viewModal">
  <div class="modal-box">
    <div class="modal-header">
      <div class="modal-header-left">
        <div class="modal-icon view"><i class="fas fa-file-invoice"></i></div>
        <div>
          <div class="modal-title">Reservation Details</div>
          <div class="modal-subtitle" id="viewModalSubtitle">Loading...</div>
        </div>
      </div>
      <button class="modal-close" onclick="closeModal('viewModal')"><i class="fas fa-times"></i></button>
    </div>
    <div class="modal-body" id="viewModalBody">
      <div style="text-align:center;padding:40px;color:#94a3b8;">
        <i class="fas fa-spinner fa-spin fa-2x"></i><br><br>Loading...
      </div>
    </div>
    <div class="modal-footer" id="viewModalFooter">
      <button class="modal-btn modal-btn-cancel" onclick="closeModal('viewModal')">Close</button>
    </div>
  </div>
</div>

<!-- ===== CHECK-OUT MODAL ===== -->
<div class="modal-overlay" id="checkOutModal">
  <div class="modal-box">
    <div class="modal-header">
      <div class="modal-header-left">
        <div class="modal-icon"><i class="fas fa-sign-out-alt"></i></div>
        <div>
          <div class="modal-title">Process Check-Out</div>
          <div class="modal-subtitle" id="coModalSubtitle">Complete guest departure</div>
        </div>
      </div>
      <button class="modal-close" onclick="closeModal('checkOutModal')"><i class="fas fa-times"></i></button>
    </div>
    <div class="modal-body">

      <!-- Billing Summary -->
      <div class="section-subtitle"><i class="fas fa-receipt"></i> Billing Summary</div>
      <div class="billing-summary">
        <div class="billing-row">
          <span class="billing-label"><i class="fas fa-user" style="margin-right:6px;"></i>Guest</span>
          <span class="billing-value" id="coGuestName">-</span>
        </div>
        <div class="billing-row">
          <span class="billing-label"><i class="fas fa-bed" style="margin-right:6px;"></i>Room</span>
          <span class="billing-value" id="coRoom">-</span>
        </div>
        <div class="billing-row">
          <span class="billing-label"><i class="fas fa-moon" style="margin-right:6px;"></i>Stay Duration</span>
          <span class="billing-value" id="coNights">-</span>
        </div>
        <div class="billing-row">
          <span class="billing-label">Room Charges</span>
          <span class="billing-value" id="coTotalAmount">-</span>
        </div>
        <div class="billing-row">
          <span class="billing-label">Discount Applied</span>
          <span class="billing-value" style="color:#4ade80;" id="coDiscount">-</span>
        </div>
        <div class="billing-row">
          <span class="billing-label">Tax (10%)</span>
          <span class="billing-value" id="coTax">-</span>
        </div>
        <div class="billing-row">
          <span class="billing-label">Extra Charges</span>
          <span class="billing-value extra-charge-row">
            <span style="color:#f87171;">Rs.</span>
            <input type="number" class="extra-input" id="coExtraCharge" min="0" value="0" step="0.01" placeholder="0.00" oninput="recalcTotal()">
          </span>
        </div>
        <div class="billing-row">
          <span class="billing-label" style="font-size:1rem;font-weight:700;color:#fff;">Total Amount Due</span>
          <span class="billing-value total" id="coFinalAmount">-</span>
        </div>
      </div>

      <!-- Check-Out Form -->
      <form id="checkOutForm" method="POST" action="">
        <input type="hidden" name="action" value="checkout">
        <input type="hidden" name="reservationId" id="coReservationId" value="">
        <input type="hidden" id="coBaseFinal" value="0">

        <div class="section-subtitle"><i class="fas fa-credit-card"></i> Payment Settlement</div>
        <div class="form-row">
          <div class="form-group">
            <label class="form-label">Payment Method <span class="req">*</span></label>
            <select class="form-control" name="paymentMethod" required>
              <option value="">Select Method</option>
              <option value="CASH">Cash</option>
              <option value="CREDIT_CARD">Credit Card</option>
              <option value="DEBIT_CARD">Debit Card</option>
              <option value="BANK_TRANSFER">Bank Transfer</option>
              <option value="ONLINE">Online Payment</option>
            </select>
          </div>
          <div class="form-group">
            <label class="form-label">Reference / Receipt No.</label>
            <input type="text" class="form-control" name="paymentRef" placeholder="e.g. TXN-20240001">
          </div>
        </div>

        <div class="section-divider"></div>
        <div class="section-subtitle"><i class="fas fa-clipboard-check"></i> Room Inspection</div>
        <div class="checklist" id="roomChecklist">
          <label class="check-item" id="ci1">
            <input type="checkbox" name="check_keycards" onchange="toggleCheck('ci1',this)"> 
            <span class="check-item-label"><i class="fas fa-key" style="margin-right:6px;color:#e53935;"></i>Key cards returned</span>
          </label>
          <label class="check-item" id="ci2">
            <input type="checkbox" name="check_minibar" onchange="toggleCheck('ci2',this)"> 
            <span class="check-item-label"><i class="fas fa-wine-bottle" style="margin-right:6px;color:#e53935;"></i>Minibar checked &amp; charged</span>
          </label>
          <label class="check-item" id="ci3">
            <input type="checkbox" name="check_damage" onchange="toggleCheck('ci3',this)"> 
            <span class="check-item-label"><i class="fas fa-shield-alt" style="margin-right:6px;color:#e53935;"></i>No visible damage to room</span>
          </label>
          <label class="check-item" id="ci4">
            <input type="checkbox" name="check_belongings" onchange="toggleCheck('ci4',this)"> 
            <span class="check-item-label"><i class="fas fa-suitcase" style="margin-right:6px;color:#e53935;"></i>Guest belongings checked</span>
          </label>
        </div>

        <div class="section-divider"></div>
        <div class="section-subtitle"><i class="fas fa-star"></i> Guest Feedback (Optional)</div>
        <div class="star-rating" id="starRating">
          <span class="star" onclick="setRating(1)" data-val="1">&#9733;</span>
          <span class="star" onclick="setRating(2)" data-val="2">&#9733;</span>
          <span class="star" onclick="setRating(3)" data-val="3">&#9733;</span>
          <span class="star" onclick="setRating(4)" data-val="4">&#9733;</span>
          <span class="star" onclick="setRating(5)" data-val="5">&#9733;</span>
        </div>
        <input type="hidden" name="rating" id="ratingInput" value="0">
        <div class="form-group">
          <label class="form-label">Check-Out Notes</label>
          <textarea class="form-control" name="checkOutNotes" rows="2"
                    placeholder="Any special notes or observations about this check-out..." style="resize:vertical;"></textarea>
        </div>

      </form>
    </div>
    <div class="modal-footer">
      <button class="modal-btn modal-btn-cancel" onclick="closeModal('checkOutModal')">
        <i class="fas fa-times"></i> Cancel
      </button>
      <button class="modal-btn modal-btn-checkout" id="confirmCheckOutBtn" onclick="submitCheckOut()">
        <i class="fas fa-sign-out-alt"></i> Confirm Check-Out
      </button>
    </div>
  </div>
</div>

<!-- ===== JAVASCRIPT ===== -->
<script>
  var CTX = '<%= ctx %>';

  /* ── SIDEBAR ── */
  var sidebar = document.getElementById('sidebar');
  var overlay = document.getElementById('sidebarOverlay');
  document.getElementById('sidebarToggle').addEventListener('click', function() {
    sidebar.classList.toggle('open');
    overlay.classList.toggle('visible');
  });
  overlay.addEventListener('click', function() {
    sidebar.classList.remove('open');
    overlay.classList.remove('visible');
  });

  /* ── ALERT AUTO-DISMISS ── */
  setTimeout(function() {
    ['alertSuccess','alertError'].forEach(function(id) {
      var el = document.getElementById(id);
      if (el) {
        el.style.transition = 'opacity 0.5s';
        el.style.opacity = '0';
        setTimeout(function() { if (el.parentNode) el.remove(); }, 500);
      }
    });
  }, 5000);

  /* ── TABS ── */
  function switchTab(name, btn) {
    document.querySelectorAll('.tab-panel').forEach(function(p) { p.classList.remove('active'); });
    document.querySelectorAll('.tab-btn').forEach(function(b) { b.classList.remove('active'); });
    document.getElementById('tab-' + name).classList.add('active');
    btn.classList.add('active');
  }

  /* ── MODALS ── */
  function openModal(id) {
    document.getElementById(id).classList.add('open');
    document.body.style.overflow = 'hidden';
  }
  function closeModal(id) {
    document.getElementById(id).classList.remove('open');
    document.body.style.overflow = '';
  }
  document.querySelectorAll('.modal-overlay').forEach(function(m) {
    m.addEventListener('click', function(e) { if (e.target === m) closeModal(m.id); });
  });
  document.addEventListener('keydown', function(e) {
    if (e.key === 'Escape') {
      document.querySelectorAll('.modal-overlay.open').forEach(function(m) { closeModal(m.id); });
    }
  });

  /* ── VIEW MODAL ── */
  function openViewModal(id) {
    document.getElementById('viewModalBody').innerHTML =
      '<div style="text-align:center;padding:40px;color:#94a3b8;"><i class="fas fa-spinner fa-spin fa-2x"></i><br><br>Loading details...</div>';
    document.getElementById('viewModalFooter').innerHTML =
      '<button class="modal-btn modal-btn-cancel" onclick="closeModal(\'viewModal\')">Close</button>';
    openModal('viewModal');

    fetch(CTX + '/staff/checkout?action=view&id=' + id)
      .then(function(r) { return r.json(); })
      .then(function(d) {
        document.getElementById('viewModalSubtitle').textContent = d.reservationNumber || '';
        var stCss = 'status-' + (d.status || '').toLowerCase();
        var stLbl = (d.status || '').replace(/_/g, ' ');
        var body =
          '<div class="info-grid">' +
            '<div class="info-item"><div class="info-label-sm">Guest</div><div class="info-value-sm">' + esc(d.guestName) + '</div></div>' +
            '<div class="info-item"><div class="info-label-sm">Booking ID</div><div class="info-value-sm"><code>' + esc(d.reservationNumber) + '</code></div></div>' +
            '<div class="info-item"><div class="info-label-sm">Room</div><div class="info-value-sm">' + esc(d.roomNumber) + ' &mdash; ' + esc(d.roomType) + '</div></div>' +
            '<div class="info-item"><div class="info-label-sm">Floor</div><div class="info-value-sm">' + d.floor + '</div></div>' +
            '<div class="info-item"><div class="info-label-sm">Check-In</div><div class="info-value-sm">' + esc(d.checkInDate) + '</div></div>' +
            '<div class="info-item"><div class="info-label-sm">Check-Out</div><div class="info-value-sm">' + esc(d.checkOutDate) + '</div></div>' +
            '<div class="info-item"><div class="info-label-sm">Nights</div><div class="info-value-sm">' + d.nights + '</div></div>' +
            '<div class="info-item"><div class="info-label-sm">Guests</div><div class="info-value-sm">' + d.guests + '</div></div>' +
          '</div>' +
          '<div class="section-divider"></div>' +
          '<div class="section-subtitle"><i class="fas fa-receipt"></i> Billing Breakdown</div>' +
          '<div class="billing-summary">' +
            '<div class="billing-row"><span class="billing-label">Room Charges</span><span class="billing-value">Rs. ' + Number(d.totalAmount).toFixed(2) + '</span></div>' +
            '<div class="billing-row"><span class="billing-label">Discount</span><span class="billing-value" style="color:#4ade80;">-Rs. ' + Number(d.discountAmount).toFixed(2) + '</span></div>' +
            '<div class="billing-row"><span class="billing-label">Tax</span><span class="billing-value">Rs. ' + Number(d.taxAmount).toFixed(2) + '</span></div>' +
            '<div class="billing-row"><span class="billing-label" style="font-weight:700;color:#fff;">Total Due</span><span class="billing-value total">Rs. ' + Number(d.finalAmount).toFixed(2) + '</span></div>' +
          '</div>';
        if (d.specialRequests) {
          body += '<div class="section-divider"></div><div class="section-subtitle"><i class="fas fa-comment"></i> Special Requests</div>' +
                  '<p style="font-size:.88rem;color:#374151;line-height:1.6;">' + esc(d.specialRequests) + '</p>';
        }
        body += '<div class="section-divider"></div><div class="info-item"><div class="info-label-sm">Status</div>' +
                '<div class="info-value-sm"><span class="status-badge ' + stCss + '"><span class="status-dot"></span>' + stLbl + '</span></div></div>';
        document.getElementById('viewModalBody').innerHTML = body;

        var footer = '<button class="modal-btn modal-btn-cancel" onclick="closeModal(\'viewModal\')">Close</button>';
        if (d.canCheckOut) {
          footer += '<button class="modal-btn modal-btn-checkout" onclick="closeModal(\'viewModal\');openCheckOutModal(' + d.id + ')">' +
                    '<i class="fas fa-sign-out-alt"></i> Check-Out</button>';
        }
        document.getElementById('viewModalFooter').innerHTML = footer;
      })
      .catch(function() {
        document.getElementById('viewModalBody').innerHTML =
          '<div class="empty-state"><i class="fas fa-exclamation-triangle"></i><p>Failed to load reservation details.</p></div>';
      });
  }

  /* ── CHECK-OUT MODAL ── */
  function openCheckOutModal(id) {
    document.getElementById('coReservationId').value = id;
    document.getElementById('checkOutForm').action = CTX + '/staff/checkout';
    document.getElementById('coExtraCharge').value = '0';
    resetChecklist();
    resetStars();

    fetch(CTX + '/staff/checkout?action=view&id=' + id)
      .then(function(r) { return r.json(); })
      .then(function(d) {
        document.getElementById('coModalSubtitle').textContent = d.reservationNumber || 'Check-Out';
        document.getElementById('coGuestName').textContent = d.guestName || '-';
        document.getElementById('coRoom').textContent = 'Room ' + d.roomNumber + ' (' + d.roomType + ') — Floor ' + d.floor;
        document.getElementById('coNights').textContent = d.nights + ' Night(s): ' + d.checkInDate + ' → ' + d.checkOutDate;
        var total    = Number(d.totalAmount)    || 0;
        var discount = Number(d.discountAmount) || 0;
        var tax      = Number(d.taxAmount)      || 0;
        var final_   = Number(d.finalAmount)    || 0;
        document.getElementById('coTotalAmount').textContent = 'Rs. ' + total.toFixed(2);
        document.getElementById('coDiscount').textContent    = '-Rs. ' + discount.toFixed(2);
        document.getElementById('coTax').textContent         = 'Rs. ' + tax.toFixed(2);
        document.getElementById('coBaseFinal').value         = final_;
        document.getElementById('coFinalAmount').textContent = 'Rs. ' + final_.toFixed(2);
      })
      .catch(function() {
        document.getElementById('coGuestName').textContent = 'Guest #' + id;
      });

    openModal('checkOutModal');
  }

  function recalcTotal() {
    var base  = parseFloat(document.getElementById('coBaseFinal').value) || 0;
    var extra = parseFloat(document.getElementById('coExtraCharge').value) || 0;
    var total = base + extra;
    document.getElementById('coFinalAmount').textContent = 'Rs. ' + total.toFixed(2);
  }

  function submitCheckOut() {
    var btn = document.getElementById('confirmCheckOutBtn');
    btn.classList.add('modal-btn-loading');
    btn.innerHTML = '<i class="fas fa-spinner fa-spin"></i> Processing...';
    document.getElementById('checkOutForm').submit();
  }

  /* ── CHECKLIST ── */
  function toggleCheck(itemId, checkbox) {
    var el = document.getElementById(itemId);
    if (checkbox.checked) {
      el.classList.add('checked');
    } else {
      el.classList.remove('checked');
    }
  }
  function resetChecklist() {
    ['ci1','ci2','ci3','ci4'].forEach(function(id) {
      var el = document.getElementById(id);
      if (el) {
        el.classList.remove('checked');
        var cb = el.querySelector('input[type=checkbox]');
        if (cb) cb.checked = false;
      }
    });
  }

  /* ── STAR RATING ── */
  var currentRating = 0;
  function setRating(val) {
    currentRating = val;
    document.getElementById('ratingInput').value = val;
    document.querySelectorAll('#starRating .star').forEach(function(s) {
      s.classList.toggle('active', parseInt(s.getAttribute('data-val')) <= val);
    });
  }
  function resetStars() {
    currentRating = 0;
    document.getElementById('ratingInput').value = 0;
    document.querySelectorAll('#starRating .star').forEach(function(s) { s.classList.remove('active'); });
  }
  document.querySelectorAll('#starRating .star').forEach(function(s) {
    s.addEventListener('mouseover', function() {
      var v = parseInt(s.getAttribute('data-val'));
      document.querySelectorAll('#starRating .star').forEach(function(x) {
        x.classList.toggle('active', parseInt(x.getAttribute('data-val')) <= v);
      });
    });
    s.addEventListener('mouseout', function() {
      document.querySelectorAll('#starRating .star').forEach(function(x) {
        x.classList.toggle('active', parseInt(x.getAttribute('data-val')) <= currentRating);
      });
    });
  });

  /* ── SEARCH ── */
  var searchTimeout = null;
  document.getElementById('searchInput').addEventListener('keydown', function(e) {
    if (e.key === 'Enter') doSearch();
  });
  document.getElementById('searchInput').addEventListener('input', function() {
    clearTimeout(searchTimeout);
    var q = this.value.trim();
    if (q.length >= 2) {
      searchTimeout = setTimeout(doSearch, 500);
    } else if (q.length === 0) {
      document.getElementById('searchResultsWrap').classList.remove('visible');
    }
  });

  function doSearch() {
    var q = document.getElementById('searchInput').value.trim();
    var wrap     = document.getElementById('searchResultsWrap');
    var spinner  = document.getElementById('searchSpinner');
    var noRes    = document.getElementById('searchNoResults');
    var results  = document.getElementById('searchResults');
    if (!q) { wrap.classList.remove('visible'); return; }

    wrap.classList.add('visible');
    spinner.classList.add('visible');
    noRes.classList.remove('visible');
    results.innerHTML = '';

    fetch(CTX + '/staff/checkout?action=search&q=' + encodeURIComponent(q))
      .then(function(r) { return r.json(); })
      .then(function(data) {
        spinner.classList.remove('visible');
        if (!data || data.length === 0) { noRes.classList.add('visible'); return; }
        data.forEach(function(d) {
          var stCss = 'status-' + d.status.toLowerCase();
          var stLbl = d.status.replace(/_/g, ' ');
          var html =
            '<div class="search-result-item">' +
              '<div class="search-result-info">' +
                '<div class="search-result-name"><i class="fas fa-user" style="margin-right:5px;color:#e53935;"></i>' + esc(d.guestName) + '</div>' +
                '<div class="search-result-meta">' +
                  '<span style="margin-right:12px;"><i class="fas fa-hashtag" style="margin-right:3px;"></i>' + esc(d.reservationNumber) + '</span>' +
                  '<span style="margin-right:12px;"><i class="fas fa-bed" style="margin-right:3px;"></i>Room ' + esc(d.roomNumber) + ' (' + esc(d.roomType) + ')</span>' +
                  '<span><i class="fas fa-calendar" style="margin-right:3px;"></i>' + d.checkInDate + ' &rarr; ' + d.checkOutDate + '</span>' +
                '</div>' +
              '</div>' +
              '<div class="search-result-actions">' +
                '<span class="status-badge ' + stCss + '"><span class="status-dot"></span>' + stLbl + '</span>';
          if (d.canCheckOut) {
            html += '<button class="action-btn btn-checkout" onclick="openCheckOutModal(' + d.id + ')">' +
                    '<i class="fas fa-sign-out-alt"></i> Check-Out</button>';
          }
          html += '<button class="action-btn btn-view" onclick="openViewModal(' + d.id + ')"><i class="fas fa-eye"></i></button>';
          html += '</div></div>';
          results.insertAdjacentHTML('beforeend', html);
        });
      })
      .catch(function() {
        spinner.classList.remove('visible');
        results.innerHTML = '<div class="empty-state"><i class="fas fa-exclamation-triangle"></i><p>Search failed. Please try again.</p></div>';
      });
  }

  /* ── ESCAPE HTML ── */
  function esc(s) {
    if (!s) return '';
    return String(s)
      .replace(/&/g, '&amp;')
      .replace(/</g, '&lt;')
      .replace(/>/g, '&gt;')
      .replace(/"/g, '&quot;')
      .replace(/'/g, '&#39;');
  }
</script>
</body>
</html>

