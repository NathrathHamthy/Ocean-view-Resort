<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="com.oceanview.model.User,com.oceanview.util.Constants,java.util.List,java.util.Collections,java.time.format.DateTimeFormatter" %>
<%
    User currentUser = (User) session.getAttribute(Constants.SESSION_USER);
    if (currentUser == null || !currentUser.isAdmin()) {
        response.sendRedirect(request.getContextPath() + "/login"); return;
    }
    String ctx = request.getContextPath();
    String errorMsg   = (String) request.getAttribute(Constants.ATTR_ERROR);
    String successMsg = (String) request.getAttribute(Constants.ATTR_SUCCESS);

    List<User> users    = (List<User>) request.getAttribute("users");
    if (users == null) users = Collections.emptyList();

    int totalUsers  = request.getAttribute("totalUsers")  != null ? (Integer)request.getAttribute("totalUsers")  : 0;
    int totalAdmins = request.getAttribute("totalAdmins") != null ? (Integer)request.getAttribute("totalAdmins") : 0;
    int totalStaff  = request.getAttribute("totalStaff")  != null ? (Integer)request.getAttribute("totalStaff")  : 0;
    int totalGuests = request.getAttribute("totalGuests") != null ? (Integer)request.getAttribute("totalGuests") : 0;
    int activeUsers = request.getAttribute("activeUsers") != null ? (Integer)request.getAttribute("activeUsers") : 0;
    int suspended   = request.getAttribute("suspended")   != null ? (Integer)request.getAttribute("suspended")   : 0;

    String staffName = currentUser.getFullName() != null ? currentUser.getFullName() : currentUser.getUsername();
    String staffInitials;
    try {
        int sp = staffName.indexOf(' ');
        staffInitials = sp > 0 ? ("" + staffName.charAt(0) + staffName.charAt(sp+1)).toUpperCase() : staffName.substring(0,1).toUpperCase();
    } catch(Exception e) { staffInitials = staffName.substring(0,1).toUpperCase(); }

    DateTimeFormatter dtFmt = DateTimeFormatter.ofPattern("dd MMM yyyy");
    String todayStr = java.time.LocalDate.now().format(DateTimeFormatter.ofPattern("EEEE, MMMM dd, yyyy"));
%>
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>User Management | Ocean View Resort</title>
<link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
<style>
*,*::before,*::after{box-sizing:border-box;margin:0;padding:0}
html{font-size:15px;scroll-behavior:smooth}
body{font-family:'Segoe UI',system-ui,-apple-system,sans-serif;background:#f0f4f8;color:#1e2a38;min-height:100vh;display:flex}
::-webkit-scrollbar{width:6px;height:6px}
::-webkit-scrollbar-track{background:#f0f4f8}
::-webkit-scrollbar-thumb{background:#b0bec5;border-radius:3px}
::-webkit-scrollbar-thumb:hover{background:#78909c}

/* SIDEBAR */
.sidebar{width:260px;min-height:100vh;background:linear-gradient(180deg,#0d1b2e 0%,#1a2f4e 100%);display:flex;flex-direction:column;position:fixed;top:0;left:0;z-index:100;transition:transform .3s ease;box-shadow:3px 0 20px rgba(0,0,0,.25)}
.sidebar-brand{padding:22px 20px;display:flex;align-items:center;gap:12px;border-bottom:1px solid rgba(255,255,255,.08)}
.brand-logo{width:44px;height:44px;background:linear-gradient(135deg,#f59e0b,#d97706);border-radius:12px;display:flex;align-items:center;justify-content:center;font-size:1.2rem;color:#fff;font-weight:800;flex-shrink:0}
.brand-name{font-size:.95rem;font-weight:700;color:#fff}.brand-sub{font-size:.68rem;color:rgba(255,255,255,.45);text-transform:uppercase;letter-spacing:1.2px}
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
.nav-badge{margin-left:auto;background:#ef4444;color:#fff;font-size:.63rem;font-weight:700;border-radius:10px;padding:2px 7px}
.sidebar-footer{padding:14px 20px;border-top:1px solid rgba(255,255,255,.07)}
.sidebar-footer a{display:flex;align-items:center;gap:10px;color:rgba(255,255,255,.45);font-size:.82rem;text-decoration:none;padding:7px 0;transition:color .2s}
.sidebar-footer a:hover{color:#fff}
.sidebar-overlay{position:fixed;inset:0;background:rgba(0,0,0,.5);z-index:99;display:none}
.sidebar-overlay.visible{display:block}

/* MAIN */
.main-content{margin-left:260px;flex:1;display:flex;flex-direction:column;min-height:100vh}

/* TOPBAR */
.topbar{background:#fff;padding:0 28px;height:64px;display:flex;align-items:center;justify-content:space-between;border-bottom:1px solid #e2e8f0;box-shadow:0 1px 6px rgba(0,0,0,.05);position:sticky;top:0;z-index:50}
.topbar-left{display:flex;align-items:center;gap:16px}
.sidebar-toggle{display:none;background:none;border:none;cursor:pointer;font-size:1.2rem;color:#64748b;padding:6px;border-radius:6px}
.page-title{font-size:1.1rem;font-weight:700;color:#1e2a38}
.page-subtitle{font-size:.76rem;color:#64748b;margin-top:1px}
.topbar-right{display:flex;align-items:center;gap:10px}
.topbar-btn{display:flex;align-items:center;gap:7px;padding:8px 16px;border-radius:8px;font-size:.82rem;font-weight:600;cursor:pointer;border:none;transition:all .2s;text-decoration:none;font-family:inherit;white-space:nowrap}
.btn-amber{background:linear-gradient(135deg,#f59e0b,#d97706);color:#fff;box-shadow:0 2px 8px rgba(245,158,11,.3)}
.btn-amber:hover{transform:translateY(-1px);box-shadow:0 4px 14px rgba(245,158,11,.4)}
.btn-outline{background:transparent;border:1.5px solid #e2e8f0;color:#374151}
.btn-outline:hover{border-color:#f59e0b;color:#d97706;background:#fffbeb}

/* PAGE */
.page-content{flex:1;padding:26px}

/* ALERTS */
.alert{display:flex;align-items:center;gap:12px;padding:13px 18px;border-radius:10px;margin-bottom:20px;font-size:.87rem;font-weight:500;animation:slideDown .3s ease}
@keyframes slideDown{from{opacity:0;transform:translateY(-8px)}to{opacity:1;transform:translateY(0)}}
.alert-success{background:#ecfdf5;color:#065f46;border:1px solid #6ee7b7}
.alert-error{background:#fef2f2;color:#991b1b;border:1px solid #fca5a5}
.alert-close{margin-left:auto;background:none;border:none;cursor:pointer;font-size:1.1rem;color:inherit;opacity:.6}
.alert-close:hover{opacity:1}

/* STATS */
.stats-grid{display:grid;grid-template-columns:repeat(6,1fr);gap:14px;margin-bottom:24px}
.stat-card{background:#fff;border-radius:12px;padding:16px 18px;display:flex;align-items:center;gap:12px;box-shadow:0 1px 4px rgba(0,0,0,.06);border:1px solid #e8eef5;transition:transform .2s,box-shadow .2s;cursor:default}
.stat-card:hover{transform:translateY(-2px);box-shadow:0 5px 18px rgba(0,0,0,.1)}
.stat-icon{width:44px;height:44px;border-radius:10px;display:flex;align-items:center;justify-content:center;font-size:1.1rem;flex-shrink:0}
.si-amber{background:#fef3c7;color:#d97706}.si-red{background:#fee2e2;color:#dc2626}.si-blue{background:#dbeafe;color:#2563eb}.si-green{background:#d1fae5;color:#059669}.si-purple{background:#ede9fe;color:#7c3aed}.si-gray{background:#f1f5f9;color:#475569}
.stat-value{font-size:1.5rem;font-weight:800;color:#1e2a38;line-height:1}
.stat-label{font-size:.72rem;color:#64748b;margin-top:2px;font-weight:500}

/* TOOLBAR */
.toolbar{background:#fff;border-radius:12px;padding:16px 20px;margin-bottom:18px;display:flex;align-items:center;gap:12px;box-shadow:0 1px 4px rgba(0,0,0,.06);border:1px solid #e8eef5;flex-wrap:wrap}
.search-wrap{flex:1;min-width:200px;position:relative}
.search-wrap i{position:absolute;left:12px;top:50%;transform:translateY(-50%);color:#94a3b8;font-size:.9rem;pointer-events:none}
.search-input{width:100%;padding:9px 13px 9px 36px;border:1.5px solid #e2e8f0;border-radius:8px;font-size:.87rem;color:#1e2a38;background:#f8fafc;outline:none;transition:all .2s;font-family:inherit}
.search-input:focus{border-color:#f59e0b;background:#fff;box-shadow:0 0 0 3px rgba(245,158,11,.1)}
.search-input::placeholder{color:#94a3b8}
.filter-select{padding:9px 13px;border:1.5px solid #e2e8f0;border-radius:8px;font-size:.85rem;color:#374151;background:#f8fafc;outline:none;cursor:pointer;transition:all .2s;font-family:inherit}
.filter-select:focus{border-color:#f59e0b;background:#fff}
.toolbar-right{display:flex;align-items:center;gap:8px;margin-left:auto}
.count-badge{font-size:.78rem;color:#64748b;font-weight:500;white-space:nowrap}

/* TABLE CARD */
.table-card{background:#fff;border-radius:14px;box-shadow:0 1px 4px rgba(0,0,0,.06);border:1px solid #e8eef5;overflow:hidden}
.table-card-header{padding:16px 22px;display:flex;align-items:center;justify-content:space-between;border-bottom:1px solid #f0f4f8}
.table-card-title{font-size:.95rem;font-weight:700;color:#1e2a38;display:flex;align-items:center;gap:8px}
.table-card-title i{color:#f59e0b}
table{width:100%;border-collapse:collapse}
thead th{padding:11px 16px;font-size:.7rem;font-weight:700;color:#64748b;text-transform:uppercase;letter-spacing:.8px;background:#f8fafc;border-bottom:1px solid #e8eef5;text-align:left;white-space:nowrap}
tbody tr{border-bottom:1px solid #f1f5f9;transition:background .15s}
tbody tr:last-child{border-bottom:none}
tbody tr:hover{background:#fafbfd}
td{padding:12px 16px;font-size:.85rem;color:#374151;vertical-align:middle}
.user-cell{display:flex;align-items:center;gap:10px}
.avatar{width:36px;height:36px;border-radius:50%;display:flex;align-items:center;justify-content:center;font-size:.78rem;font-weight:700;color:#fff;flex-shrink:0;text-transform:uppercase}
.avatar-admin{background:linear-gradient(135deg,#f59e0b,#d97706)}
.avatar-staff{background:linear-gradient(135deg,#3b82f6,#2563eb)}
.avatar-guest{background:linear-gradient(135deg,#10b981,#059669)}
.user-fullname{font-weight:600;color:#1e2a38;font-size:.87rem}
.user-username{font-size:.73rem;color:#94a3b8;margin-top:1px}

/* BADGES */
.badge{display:inline-flex;align-items:center;gap:4px;padding:3px 10px;border-radius:20px;font-size:.7rem;font-weight:700;letter-spacing:.3px;white-space:nowrap}
.badge-dot{width:5px;height:5px;border-radius:50%;background:currentColor}
.badge-admin{background:#fef3c7;color:#92400e}
.badge-staff{background:#dbeafe;color:#1d4ed8}
.badge-guest{background:#d1fae5;color:#065f46}
.badge-active{background:#d1fae5;color:#065f46}
.badge-inactive{background:#f3f4f6;color:#4b5563}
.badge-suspended{background:#fee2e2;color:#991b1b}

/* ACTION BUTTONS */
.actions-cell{display:flex;gap:5px;flex-wrap:wrap}
.action-btn{padding:5px 11px;border-radius:6px;border:none;font-size:.74rem;font-weight:600;cursor:pointer;display:inline-flex;align-items:center;gap:4px;transition:all .2s;font-family:inherit;text-decoration:none;white-space:nowrap}
.btn-view{background:#f1f5f9;color:#475569}.btn-view:hover{background:#475569;color:#fff}
.btn-edit{background:#dbeafe;color:#1d4ed8}.btn-edit:hover{background:#1d4ed8;color:#fff}
.btn-suspend{background:#fef3c7;color:#92400e}.btn-suspend:hover{background:#f59e0b;color:#fff}
.btn-activate{background:#d1fae5;color:#065f46}.btn-activate:hover{background:#059669;color:#fff}
.btn-delete{background:#fee2e2;color:#dc2626}.btn-delete:hover{background:#dc2626;color:#fff}
.btn-pwd{background:#ede9fe;color:#7c3aed}.btn-pwd:hover{background:#7c3aed;color:#fff}

/* EMPTY STATE */
.empty-state{text-align:center;padding:50px 20px;color:#94a3b8}
.empty-state i{font-size:2.5rem;margin-bottom:12px;display:block;color:#cbd5e1}
.empty-state p{font-size:.9rem;color:#64748b}

/* MODAL */
.modal-overlay{position:fixed;inset:0;background:rgba(10,20,40,.65);z-index:1000;display:flex;align-items:center;justify-content:center;padding:20px;opacity:0;pointer-events:none;transition:opacity .25s;backdrop-filter:blur(4px)}
.modal-overlay.open{opacity:1;pointer-events:all}
.modal-box{background:#fff;border-radius:18px;box-shadow:0 25px 60px rgba(0,0,0,.2);width:100%;max-width:520px;max-height:92vh;overflow-y:auto;transform:translateY(16px) scale(.97);transition:transform .25s}
.modal-overlay.open .modal-box{transform:translateY(0) scale(1)}
.modal-box.wide{max-width:620px}
.modal-header{padding:20px 24px;display:flex;align-items:center;justify-content:space-between;border-bottom:1px solid #f0f4f8;position:sticky;top:0;background:#fff;z-index:1;border-radius:18px 18px 0 0}
.modal-header-left{display:flex;align-items:center;gap:12px}
.modal-icon{width:42px;height:42px;background:linear-gradient(135deg,#f59e0b,#d97706);border-radius:10px;display:flex;align-items:center;justify-content:center;color:#fff;font-size:1rem;flex-shrink:0}
.modal-icon.red{background:linear-gradient(135deg,#ef4444,#dc2626)}
.modal-icon.blue{background:linear-gradient(135deg,#3b82f6,#2563eb)}
.modal-icon.purple{background:linear-gradient(135deg,#8b5cf6,#7c3aed)}
.modal-icon.green{background:linear-gradient(135deg,#10b981,#059669)}
.modal-title{font-size:1rem;font-weight:700;color:#1e2a38}
.modal-subtitle{font-size:.76rem;color:#64748b;margin-top:2px}
.modal-close{width:32px;height:32px;border-radius:7px;border:none;background:#f1f5f9;color:#64748b;cursor:pointer;display:flex;align-items:center;justify-content:center;transition:all .2s;font-size:.95rem}
.modal-close:hover{background:#e2e8f0;color:#1e2a38}
.modal-body{padding:22px 24px}
.modal-footer{padding:16px 24px;display:flex;justify-content:flex-end;gap:10px;border-top:1px solid #f0f4f8;background:#f8fafc;border-radius:0 0 18px 18px;flex-wrap:wrap}
.modal-btn{padding:9px 18px;border-radius:8px;border:none;font-size:.85rem;font-weight:600;cursor:pointer;display:flex;align-items:center;gap:7px;transition:all .2s;font-family:inherit}
.modal-btn-cancel{background:#f1f5f9;color:#475569}.modal-btn-cancel:hover{background:#e2e8f0}
.modal-btn-primary{background:linear-gradient(135deg,#f59e0b,#d97706);color:#fff;box-shadow:0 2px 8px rgba(245,158,11,.3)}.modal-btn-primary:hover{transform:translateY(-1px)}
.modal-btn-danger{background:linear-gradient(135deg,#ef4444,#dc2626);color:#fff}.modal-btn-danger:hover{transform:translateY(-1px);box-shadow:0 4px 12px rgba(239,68,68,.35)}
.modal-btn-purple{background:linear-gradient(135deg,#8b5cf6,#7c3aed);color:#fff}.modal-btn-purple:hover{transform:translateY(-1px)}

/* FORM */
.form-group{margin-bottom:15px}
.form-label{display:block;font-size:.79rem;font-weight:600;color:#374151;margin-bottom:5px}
.form-label .req{color:#ef4444;margin-left:2px}
.form-control{width:100%;padding:9px 13px;border:1.5px solid #e2e8f0;border-radius:8px;font-size:.87rem;color:#1e2a38;background:#f8fafc;outline:none;transition:all .2s;font-family:inherit}
.form-control:focus{border-color:#f59e0b;background:#fff;box-shadow:0 0 0 3px rgba(245,158,11,.1)}
.form-row{display:grid;grid-template-columns:1fr 1fr;gap:13px}
.form-hint{font-size:.72rem;color:#94a3b8;margin-top:4px}

/* VIEW USER DETAILS */
.detail-grid{display:grid;grid-template-columns:1fr 1fr;gap:14px}
.detail-item{display:flex;flex-direction:column;gap:3px}
.detail-label{font-size:.7rem;font-weight:700;color:#94a3b8;text-transform:uppercase;letter-spacing:.8px}
.detail-value{font-size:.88rem;font-weight:600;color:#1e2a38}
.detail-divider{height:1px;background:#f0f4f8;margin:16px 0;grid-column:1/-1}

/* CONFIRM DELETE */
.confirm-box{background:#fef2f2;border:1.5px solid #fca5a5;border-radius:12px;padding:16px 18px;margin-bottom:16px}
.confirm-text{font-size:.87rem;color:#991b1b;line-height:1.6}
.confirm-name{font-weight:700}

/* RESPONSIVE */
@media(max-width:1100px){.stats-grid{grid-template-columns:repeat(3,1fr)}}
@media(max-width:900px){.sidebar{transform:translateX(-100%)}.sidebar.open{transform:translateX(0)}.main-content{margin-left:0}.sidebar-toggle{display:flex!important}}
@media(max-width:640px){.stats-grid{grid-template-columns:repeat(2,1fr)}.page-content{padding:14px}.form-row{grid-template-columns:1fr}.detail-grid{grid-template-columns:1fr}}
</style>
</head>
<body>
<div class="sidebar-overlay" id="sidebarOverlay"></div>

<!-- SIDEBAR -->
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
    <a class="nav-link" href="<%= ctx %>/admin/dashboard"><span class="nav-icon"><i class="fas fa-th-large"></i></span> Dashboard</a>
    <div class="nav-label">Management</div>
    <a class="nav-link active" href="<%= ctx %>/admin/users"><span class="nav-icon"><i class="fas fa-users"></i></span> Users</a>
    <a class="nav-link" href="<%= ctx %>/admin/rooms"><span class="nav-icon"><i class="fas fa-bed"></i></span> Rooms</a>
    <a class="nav-link" href="<%= ctx %>/admin/reservations"><span class="nav-icon"><i class="fas fa-calendar-alt"></i></span> Reservations</a>
    <a class="nav-link" href="<%= ctx %>/admin/reviews"><span class="nav-icon"><i class="fas fa-star"></i></span> Reviews</a>
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

<!-- MAIN CONTENT -->
<div class="main-content">

  <!-- TOPBAR -->
  <header class="topbar">
    <div class="topbar-left">
      <button class="sidebar-toggle" id="sidebarToggle" style="display:none;"><i class="fas fa-bars"></i></button>
      <div>
        <div class="page-title"><i class="fas fa-users" style="color:#f59e0b;margin-right:8px;"></i>User Management</div>
        <div class="page-subtitle">Create, manage and control user accounts</div>
      </div>
    </div>
    <div class="topbar-right">
      <a href="<%= ctx %>/admin/dashboard" class="topbar-btn btn-outline"><i class="fas fa-arrow-left"></i> Dashboard</a>
      <button class="topbar-btn btn-amber" onclick="openModal('addUserModal')">
        <i class="fas fa-user-plus"></i> Add New User
      </button>
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

    <!-- STATS -->
    <div class="stats-grid">
      <div class="stat-card">
        <div class="stat-icon si-amber"><i class="fas fa-users"></i></div>
        <div><div class="stat-value"><%= totalUsers %></div><div class="stat-label">Total Users</div></div>
      </div>
      <div class="stat-card">
        <div class="stat-icon si-red"><i class="fas fa-crown"></i></div>
        <div><div class="stat-value"><%= totalAdmins %></div><div class="stat-label">Admins</div></div>
      </div>
      <div class="stat-card">
        <div class="stat-icon si-blue"><i class="fas fa-user-tie"></i></div>
        <div><div class="stat-value"><%= totalStaff %></div><div class="stat-label">Staff</div></div>
      </div>
      <div class="stat-card">
        <div class="stat-icon si-green"><i class="fas fa-user"></i></div>
        <div><div class="stat-value"><%= totalGuests %></div><div class="stat-label">Guests</div></div>
      </div>
      <div class="stat-card">
        <div class="stat-icon si-purple"><i class="fas fa-check-circle"></i></div>
        <div><div class="stat-value"><%= activeUsers %></div><div class="stat-label">Active</div></div>
      </div>
      <div class="stat-card">
        <div class="stat-icon si-gray"><i class="fas fa-ban"></i></div>
        <div><div class="stat-value"><%= suspended %></div><div class="stat-label">Suspended</div></div>
      </div>
    </div>

    <!-- TOOLBAR -->
    <div class="toolbar">
      <div class="search-wrap">
        <i class="fas fa-search"></i>
        <input type="text" class="search-input" id="searchInput" placeholder="Search by name, username or email..." oninput="filterTable()">
      </div>
      <select class="filter-select" id="roleFilter" onchange="filterTable()">
        <option value="">All Roles</option>
        <option value="ADMIN">Admin</option>
        <option value="STAFF">Staff</option>
        <option value="GUEST">Guest</option>
      </select>
      <select class="filter-select" id="statusFilter" onchange="filterTable()">
        <option value="">All Status</option>
        <option value="ACTIVE">Active</option>
        <option value="SUSPENDED">Suspended</option>
        <option value="INACTIVE">Inactive</option>
      </select>
      <div class="toolbar-right">
        <span class="count-badge" id="countBadge">Showing <strong><%= users.size() %></strong> users</span>
        <button class="topbar-btn btn-outline" onclick="clearFilters()"><i class="fas fa-times"></i> Clear</button>
      </div>
    </div>

    <!-- TABLE CARD -->
    <div class="table-card">
      <div class="table-card-header">
        <div class="table-card-title"><i class="fas fa-list"></i> All Users</div>
        <span style="font-size:.76rem;color:#64748b;"><%= todayStr %></span>
      </div>
      <% if (users.isEmpty()) { %>
      <div class="empty-state">
        <i class="fas fa-users-slash"></i>
        <p>No users found</p>
      </div>
      <% } else { %>
      <div style="overflow-x:auto;">
      <table id="usersTable">
        <thead>
          <tr>
            <th>#</th>
            <th>User</th>
            <th>Email</th>
            <th>Phone</th>
            <th>Role</th>
            <th>Status</th>
            <th>Registered</th>
            <th>Actions</th>
          </tr>
        </thead>
        <tbody>
        <%
        int rowNum = 0;
        for (User u : users) {
            rowNum++;
            String uName    = u.getFullName()  != null ? u.getFullName()  : u.getUsername();
            String uUsername= u.getUsername()  != null ? u.getUsername()  : "";
            String uEmail   = u.getEmail()     != null ? u.getEmail()     : "";
            String uPhone   = u.getPhone()     != null ? u.getPhone()     : "-";
            String uRole    = u.getRole()      != null ? u.getRole().name()   : "GUEST";
            String uStatus  = u.getStatus()    != null ? u.getStatus().name() : "ACTIVE";
            String uInit    = uName.length()>0 ? uName.substring(0,1).toUpperCase() : "?";
            String avatarCss= "avatar-" + uRole.toLowerCase();
            String roleCss  = "badge-" + uRole.toLowerCase();
            String statusCss= "badge-" + uStatus.toLowerCase();
            String regDate  = u.getCreatedAt() != null ? u.getCreatedAt().format(dtFmt) : "-";
            boolean isSelf  = u.getUserId() == currentUser.getUserId();
            boolean isActive = u.getStatus() == User.Status.ACTIVE;
        %>
          <tr data-role="<%= uRole %>" data-status="<%= uStatus %>" data-search="<%= uName.toLowerCase() %> <%= uUsername.toLowerCase() %> <%= uEmail.toLowerCase() %>">
            <td style="color:#94a3b8;font-size:.78rem;"><%= rowNum %></td>
            <td>
              <div class="user-cell">
                <div class="avatar <%= avatarCss %>"><%= uInit %></div>
                <div>
                  <div class="user-fullname"><%= uName %><% if(isSelf){%> <span style="font-size:.65rem;background:#fef3c7;color:#92400e;padding:1px 6px;border-radius:10px;">You</span><%}%></div>
                  <div class="user-username">@<%= uUsername %></div>
                </div>
              </div>
            </td>
            <td style="font-size:.82rem;"><%= uEmail %></td>
            <td style="font-size:.82rem;"><%= uPhone %></td>
            <td><span class="badge <%= roleCss %>"><span class="badge-dot"></span><%= uRole %></span></td>
            <td><span class="badge <%= statusCss %>"><span class="badge-dot"></span><%= uStatus %></span></td>
            <td style="font-size:.78rem;color:#64748b;"><%= regDate %></td>
            <td>
              <div class="actions-cell">
                <button class="action-btn btn-view" onclick="openViewModal(<%= u.getUserId() %>)" title="View Details"><i class="fas fa-eye"></i></button>
                <button class="action-btn btn-edit" onclick="openEditModal(<%= u.getUserId() %>,'<%= uUsername %>','<%= uName.replace("'","\\'") %>','<%= uEmail %>','<%= uPhone %>','<%= uRole %>','<%= uStatus %>')" title="Edit User"><i class="fas fa-edit"></i></button>
                <button class="action-btn btn-pwd" onclick="openPwdModal(<%= u.getUserId() %>,'<%= uName.replace("'","\\'") %>')" title="Reset Password"><i class="fas fa-key"></i></button>
                <% if (!isSelf) { %>
                  <% if (isActive) { %>
                  <button class="action-btn btn-suspend" onclick="openToggleModal(<%= u.getUserId() %>,'<%= uName.replace("'","\\'") %>','SUSPEND')" title="Suspend User"><i class="fas fa-ban"></i></button>
                  <% } else { %>
                  <button class="action-btn btn-activate" onclick="openToggleModal(<%= u.getUserId() %>,'<%= uName.replace("'","\\'") %>','ACTIVATE')" title="Activate User"><i class="fas fa-check-circle"></i></button>
                  <% } %>
                  <button class="action-btn btn-delete" onclick="openDeleteModal(<%= u.getUserId() %>,'<%= uName.replace("'","\\'") %>')" title="Delete User"><i class="fas fa-trash"></i></button>
                <% } %>
              </div>
            </td>
          </tr>
        <% } %>
        </tbody>
      </table>
      </div>
      <% } %>
    </div>

  </main>
</div>

<!-- ===== ADD USER MODAL ===== -->
<div class="modal-overlay" id="addUserModal">
  <div class="modal-box wide">
    <div class="modal-header">
      <div class="modal-header-left">
        <div class="modal-icon"><i class="fas fa-user-plus"></i></div>
        <div><div class="modal-title">Add New User</div><div class="modal-subtitle">Create a new user account</div></div>
      </div>
      <button class="modal-close" onclick="closeModal('addUserModal')"><i class="fas fa-times"></i></button>
    </div>
    <form method="POST" action="<%= ctx %>/admin/users" onsubmit="return validateAddForm()">
      <input type="hidden" name="action" value="create">
      <div class="modal-body">
        <div class="form-row">
          <div class="form-group">
            <label class="form-label">Username <span class="req">*</span></label>
            <input type="text" class="form-control" name="username" id="addUsername" placeholder="e.g. john_doe" required autocomplete="off">
            <div class="form-hint">Lowercase letters, numbers, underscores only</div>
          </div>
          <div class="form-group">
            <label class="form-label">Full Name <span class="req">*</span></label>
            <input type="text" class="form-control" name="fullName" placeholder="e.g. John Doe" required>
          </div>
        </div>
        <div class="form-row">
          <div class="form-group">
            <label class="form-label">Email Address <span class="req">*</span></label>
            <input type="email" class="form-control" name="email" placeholder="john@example.com" required>
          </div>
          <div class="form-group">
            <label class="form-label">Phone Number</label>
            <input type="text" class="form-control" name="phone" placeholder="+94 77 123 4567">
          </div>
        </div>
        <div class="form-row">
          <div class="form-group">
            <label class="form-label">Role <span class="req">*</span></label>
            <select class="form-control" name="role" required>
              <option value="GUEST">Guest</option>
              <option value="STAFF">Staff</option>
              <option value="ADMIN">Admin</option>
            </select>
          </div>
          <div class="form-group">
            <label class="form-label">Password <span class="req">*</span></label>
            <div style="position:relative;">
              <input type="password" class="form-control" name="password" id="addPassword" placeholder="Min. 6 characters" required style="padding-right:40px;">
              <button type="button" onclick="togglePwd('addPassword',this)" style="position:absolute;right:10px;top:50%;transform:translateY(-50%);background:none;border:none;cursor:pointer;color:#94a3b8;font-size:.9rem;"><i class="fas fa-eye"></i></button>
            </div>
          </div>
        </div>
      </div>
      <div class="modal-footer">
        <button type="button" class="modal-btn modal-btn-cancel" onclick="closeModal('addUserModal')"><i class="fas fa-times"></i> Cancel</button>
        <button type="submit" class="modal-btn modal-btn-primary"><i class="fas fa-user-plus"></i> Create User</button>
      </div>
    </form>
  </div>
</div>

<!-- ===== EDIT USER MODAL ===== -->
<div class="modal-overlay" id="editUserModal">
  <div class="modal-box wide">
    <div class="modal-header">
      <div class="modal-header-left">
        <div class="modal-icon blue"><i class="fas fa-user-edit"></i></div>
        <div><div class="modal-title">Edit User</div><div class="modal-subtitle" id="editModalSubtitle">Update user information</div></div>
      </div>
      <button class="modal-close" onclick="closeModal('editUserModal')"><i class="fas fa-times"></i></button>
    </div>
    <form method="POST" action="<%= ctx %>/admin/users">
      <input type="hidden" name="action" value="update">
      <input type="hidden" name="userId" id="editUserId">
      <div class="modal-body">
        <div class="form-group">
          <label class="form-label">Username</label>
          <input type="text" class="form-control" id="editUsername" disabled style="background:#f1f5f9;color:#64748b;">
          <div class="form-hint">Username cannot be changed</div>
        </div>
        <div class="form-row">
          <div class="form-group">
            <label class="form-label">Full Name <span class="req">*</span></label>
            <input type="text" class="form-control" name="fullName" id="editFullName" required>
          </div>
          <div class="form-group">
            <label class="form-label">Email Address <span class="req">*</span></label>
            <input type="email" class="form-control" name="email" id="editEmail" required>
          </div>
        </div>
        <div class="form-row">
          <div class="form-group">
            <label class="form-label">Phone Number</label>
            <input type="text" class="form-control" name="phone" id="editPhone">
          </div>
          <div class="form-group">
            <label class="form-label">Role <span class="req">*</span></label>
            <select class="form-control" name="role" id="editRole">
              <option value="GUEST">Guest</option>
              <option value="STAFF">Staff</option>
              <option value="ADMIN">Admin</option>
            </select>
          </div>
        </div>
        <div class="form-group">
          <label class="form-label">Account Status <span class="req">*</span></label>
          <select class="form-control" name="status" id="editStatus">
            <option value="ACTIVE">Active</option>
            <option value="SUSPENDED">Suspended</option>
            <option value="INACTIVE">Inactive</option>
          </select>
        </div>
      </div>
      <div class="modal-footer">
        <button type="button" class="modal-btn modal-btn-cancel" onclick="closeModal('editUserModal')"><i class="fas fa-times"></i> Cancel</button>
        <button type="submit" class="modal-btn modal-btn-primary"><i class="fas fa-save"></i> Save Changes</button>
      </div>
    </form>
  </div>
</div>

<!-- ===== VIEW USER MODAL ===== -->
<div class="modal-overlay" id="viewUserModal">
  <div class="modal-box">
    <div class="modal-header">
      <div class="modal-header-left">
        <div class="modal-icon green"><i class="fas fa-user"></i></div>
        <div><div class="modal-title">User Details</div><div class="modal-subtitle" id="viewModalSubtitle">Loading...</div></div>
      </div>
      <button class="modal-close" onclick="closeModal('viewUserModal')"><i class="fas fa-times"></i></button>
    </div>
    <div class="modal-body" id="viewModalBody">
      <div style="text-align:center;padding:30px;color:#94a3b8;"><i class="fas fa-spinner fa-spin fa-2x"></i><br><br>Loading...</div>
    </div>
    <div class="modal-footer">
      <button class="modal-btn modal-btn-cancel" onclick="closeModal('viewUserModal')">Close</button>
      <button class="modal-btn modal-btn-primary" id="viewEditBtn" onclick=""><i class="fas fa-edit"></i> Edit User</button>
    </div>
  </div>
</div>

<!-- ===== RESET PASSWORD MODAL ===== -->
<div class="modal-overlay" id="pwdModal">
  <div class="modal-box">
    <div class="modal-header">
      <div class="modal-header-left">
        <div class="modal-icon purple"><i class="fas fa-key"></i></div>
        <div><div class="modal-title">Reset Password</div><div class="modal-subtitle" id="pwdModalSubtitle">Set new password</div></div>
      </div>
      <button class="modal-close" onclick="closeModal('pwdModal')"><i class="fas fa-times"></i></button>
    </div>
    <form method="POST" action="<%= ctx %>/admin/users">
      <input type="hidden" name="action" value="resetPassword">
      <input type="hidden" name="userId" id="pwdUserId">
      <div class="modal-body">
        <div class="form-group">
          <label class="form-label">New Password <span class="req">*</span></label>
          <div style="position:relative;">
            <input type="password" class="form-control" name="newPassword" id="newPwdInput" placeholder="Min. 6 characters" required style="padding-right:40px;">
            <button type="button" onclick="togglePwd('newPwdInput',this)" style="position:absolute;right:10px;top:50%;transform:translateY(-50%);background:none;border:none;cursor:pointer;color:#94a3b8;font-size:.9rem;"><i class="fas fa-eye"></i></button>
          </div>
          <div class="form-hint">Password must be at least 6 characters long</div>
        </div>
        <div class="form-group">
          <label class="form-label">Confirm Password <span class="req">*</span></label>
          <input type="password" class="form-control" id="confirmPwdInput" placeholder="Re-enter password" required>
        </div>
      </div>
      <div class="modal-footer">
        <button type="button" class="modal-btn modal-btn-cancel" onclick="closeModal('pwdModal')"><i class="fas fa-times"></i> Cancel</button>
        <button type="submit" class="modal-btn modal-btn-purple" onclick="return validatePwd()"><i class="fas fa-key"></i> Reset Password</button>
      </div>
    </form>
  </div>
</div>

<!-- ===== TOGGLE STATUS MODAL ===== -->
<div class="modal-overlay" id="toggleModal">
  <div class="modal-box">
    <div class="modal-header">
      <div class="modal-header-left">
        <div class="modal-icon" id="toggleModalIcon"><i class="fas fa-ban"></i></div>
        <div><div class="modal-title" id="toggleModalTitle">Suspend User</div><div class="modal-subtitle">Change account status</div></div>
      </div>
      <button class="modal-close" onclick="closeModal('toggleModal')"><i class="fas fa-times"></i></button>
    </div>
    <form method="POST" action="<%= ctx %>/admin/users">
      <input type="hidden" name="action" value="toggleStatus">
      <input type="hidden" name="userId" id="toggleUserId">
      <div class="modal-body">
        <p style="font-size:.88rem;color:#374151;line-height:1.6;" id="toggleModalMsg"></p>
      </div>
      <div class="modal-footer">
        <button type="button" class="modal-btn modal-btn-cancel" onclick="closeModal('toggleModal')"><i class="fas fa-times"></i> Cancel</button>
        <button type="submit" class="modal-btn modal-btn-primary" id="toggleSubmitBtn"><i class="fas fa-check"></i> Confirm</button>
      </div>
    </form>
  </div>
</div>

<!-- ===== DELETE USER MODAL ===== -->
<div class="modal-overlay" id="deleteModal">
  <div class="modal-box">
    <div class="modal-header">
      <div class="modal-header-left">
        <div class="modal-icon red"><i class="fas fa-trash-alt"></i></div>
        <div><div class="modal-title">Delete User</div><div class="modal-subtitle">This action cannot be undone</div></div>
      </div>
      <button class="modal-close" onclick="closeModal('deleteModal')"><i class="fas fa-times"></i></button>
    </div>
    <form method="POST" action="<%= ctx %>/admin/users">
      <input type="hidden" name="action" value="delete">
      <input type="hidden" name="userId" id="deleteUserId">
      <div class="modal-body">
        <div class="confirm-box">
          <div class="confirm-text">Are you sure you want to permanently delete user <span class="confirm-name" id="deleteUserName"></span>?<br><br>
          This will remove all their data. <strong>Users with active reservations cannot be deleted.</strong></div>
        </div>
      </div>
      <div class="modal-footer">
        <button type="button" class="modal-btn modal-btn-cancel" onclick="closeModal('deleteModal')"><i class="fas fa-times"></i> Cancel</button>
        <button type="submit" class="modal-btn modal-btn-danger"><i class="fas fa-trash-alt"></i> Delete Permanently</button>
      </div>
    </form>
  </div>
</div>

<!-- ===== JAVASCRIPT ===== -->
<script>
  var CTX = '<%= ctx %>';

  /* ── SIDEBAR ── */
  var sidebar = document.getElementById('sidebar');
  var overlay = document.getElementById('sidebarOverlay');
  var toggle  = document.getElementById('sidebarToggle');
  if (toggle) toggle.addEventListener('click', function() { sidebar.classList.toggle('open'); overlay.classList.toggle('visible'); });
  if (overlay) overlay.addEventListener('click', function() { sidebar.classList.remove('open'); overlay.classList.remove('visible'); });

  /* ── ALERT AUTO-DISMISS ── */
  setTimeout(function() {
    ['alertSuccess','alertError'].forEach(function(id) {
      var el = document.getElementById(id);
      if (el) { el.style.transition='opacity .5s'; el.style.opacity='0'; setTimeout(function(){ if(el.parentNode) el.remove(); },500); }
    });
  }, 5000);

  /* ── MODALS ── */
  function openModal(id) { document.getElementById(id).classList.add('open'); document.body.style.overflow='hidden'; }
  function closeModal(id) { document.getElementById(id).classList.remove('open'); document.body.style.overflow=''; }
  document.querySelectorAll('.modal-overlay').forEach(function(m) {
    m.addEventListener('click', function(e) { if (e.target===m) closeModal(m.id); });
  });
  document.addEventListener('keydown', function(e) {
    if (e.key==='Escape') document.querySelectorAll('.modal-overlay.open').forEach(function(m){ closeModal(m.id); });
  });

  /* ── VIEW USER MODAL ── */
  function openViewModal(id) {
    document.getElementById('viewModalBody').innerHTML = '<div style="text-align:center;padding:30px;color:#94a3b8;"><i class="fas fa-spinner fa-spin fa-2x"></i><br><br>Loading...</div>';
    openModal('viewUserModal');
    fetch(CTX + '/admin/users?action=view&id=' + id)
      .then(function(r){ return r.json(); })
      .then(function(d) {
        document.getElementById('viewModalSubtitle').textContent = '@' + d.username;
        var roleClass = 'badge-' + d.role.toLowerCase();
        var statusClass = 'badge-' + d.status.toLowerCase();
        var avatarClass = 'avatar-' + d.role.toLowerCase();
        var body = '<div style="text-align:center;margin-bottom:20px;">' +
          '<div class="avatar ' + avatarClass + '" style="width:60px;height:60px;font-size:1.4rem;margin:0 auto 10px;">' + d.fullName.charAt(0).toUpperCase() + '</div>' +
          '<div style="font-size:1.05rem;font-weight:700;color:#1e2a38;">' + esc(d.fullName) + '</div>' +
          '<div style="font-size:.8rem;color:#94a3b8;">@' + esc(d.username) + '</div>' +
          '<div style="margin-top:8px;display:flex;gap:6px;justify-content:center;">' +
          '<span class="badge ' + roleClass + '"><span class="badge-dot"></span>' + d.role + '</span>' +
          '<span class="badge ' + statusClass + '"><span class="badge-dot"></span>' + d.status + '</span></div>' +
          '</div>' +
          '<div class="detail-grid">' +
          '<div class="detail-item"><div class="detail-label">Email</div><div class="detail-value">' + esc(d.email) + '</div></div>' +
          '<div class="detail-item"><div class="detail-label">Phone</div><div class="detail-value">' + (d.phone || '-') + '</div></div>' +
          '<div class="detail-item"><div class="detail-label">Registered</div><div class="detail-value">' + esc(d.createdAt).substring(0,10) + '</div></div>' +
          '<div class="detail-item"><div class="detail-label">Last Login</div><div class="detail-value">' + esc(d.lastLogin) + '</div></div>' +
          '</div>';
        document.getElementById('viewModalBody').innerHTML = body;
        document.getElementById('viewEditBtn').onclick = function() {
          closeModal('viewUserModal');
          openEditModal(d.id, d.username, d.fullName, d.email, d.phone||'', d.role, d.status);
        };
      })
      .catch(function() {
        document.getElementById('viewModalBody').innerHTML = '<div class="empty-state"><i class="fas fa-exclamation-triangle"></i><p>Failed to load user details.</p></div>';
      });
  }

  /* ── EDIT MODAL ── */
  function openEditModal(id, username, fullName, email, phone, role, status) {
    document.getElementById('editUserId').value   = id;
    document.getElementById('editUsername').value = username;
    document.getElementById('editFullName').value = fullName;
    document.getElementById('editEmail').value    = email;
    document.getElementById('editPhone').value    = phone;
    document.getElementById('editRole').value     = role;
    document.getElementById('editStatus').value   = status;
    document.getElementById('editModalSubtitle').textContent = 'Editing: ' + fullName;
    openModal('editUserModal');
  }

  /* ── PASSWORD MODAL ── */
  function openPwdModal(id, name) {
    document.getElementById('pwdUserId').value = id;
    document.getElementById('pwdModalSubtitle').textContent = 'Reset password for: ' + name;
    document.getElementById('newPwdInput').value = '';
    document.getElementById('confirmPwdInput').value = '';
    openModal('pwdModal');
  }
  function validatePwd() {
    var p1 = document.getElementById('newPwdInput').value;
    var p2 = document.getElementById('confirmPwdInput').value;
    if (p1.length < 6) { alert('Password must be at least 6 characters.'); return false; }
    if (p1 !== p2) { alert('Passwords do not match.'); return false; }
    return true;
  }

  /* ── TOGGLE STATUS MODAL ── */
  function openToggleModal(id, name, action) {
    document.getElementById('toggleUserId').value = id;
    var isSuspend = action === 'SUSPEND';
    document.getElementById('toggleModalTitle').textContent = isSuspend ? 'Suspend User' : 'Activate User';
    document.getElementById('toggleModalIcon').style.background = isSuspend ? 'linear-gradient(135deg,#f59e0b,#d97706)' : 'linear-gradient(135deg,#10b981,#059669)';
    document.getElementById('toggleModalMsg').innerHTML = isSuspend
      ? 'Are you sure you want to <strong>suspend</strong> user <strong>' + esc(name) + '</strong>? They will not be able to login.'
      : 'Are you sure you want to <strong>activate</strong> user <strong>' + esc(name) + '</strong>? They will be able to login again.';
    document.getElementById('toggleSubmitBtn').innerHTML = isSuspend
      ? '<i class="fas fa-ban"></i> Suspend User'
      : '<i class="fas fa-check-circle"></i> Activate User';
    openModal('toggleModal');
  }

  /* ── DELETE MODAL ── */
  function openDeleteModal(id, name) {
    document.getElementById('deleteUserId').value = id;
    document.getElementById('deleteUserName').textContent = '"' + name + '"';
    openModal('deleteModal');
  }

  /* ── ADD FORM VALIDATION ── */
  function validateAddForm() {
    var username = document.getElementById('addUsername').value.trim();
    var pwd = document.getElementById('addPassword').value;
    if (!/^[a-zA-Z0-9_]{3,30}$/.test(username)) { alert('Username must be 3-30 chars: letters, numbers, underscores only.'); return false; }
    if (pwd.length < 6) { alert('Password must be at least 6 characters.'); return false; }
    return true;
  }

  /* ── PASSWORD TOGGLE VISIBILITY ── */
  function togglePwd(inputId, btn) {
    var inp = document.getElementById(inputId);
    var icon = btn.querySelector('i');
    if (inp.type === 'password') { inp.type = 'text'; icon.className = 'fas fa-eye-slash'; }
    else { inp.type = 'password'; icon.className = 'fas fa-eye'; }
  }

  /* ── TABLE FILTER ── */
  function filterTable() {
    var q       = document.getElementById('searchInput').value.toLowerCase().trim();
    var role    = document.getElementById('roleFilter').value;
    var status  = document.getElementById('statusFilter').value;
    var rows    = document.querySelectorAll('#usersTable tbody tr');
    var visible = 0;
    rows.forEach(function(row) {
      var search = row.getAttribute('data-search') || '';
      var rRole  = row.getAttribute('data-role')   || '';
      var rStat  = row.getAttribute('data-status') || '';
      var show   = (!q || search.indexOf(q) >= 0) &&
                   (!role   || rRole   === role)   &&
                   (!status || rStat   === status);
      row.style.display = show ? '' : 'none';
      if (show) visible++;
    });
    var badge = document.getElementById('countBadge');
    if (badge) badge.innerHTML = 'Showing <strong>' + visible + '</strong> users';
  }

  function clearFilters() {
    document.getElementById('searchInput').value = '';
    document.getElementById('roleFilter').value  = '';
    document.getElementById('statusFilter').value= '';
    filterTable();
  }

  /* ── ESCAPE HTML ── */
  function esc(s) {
    if (!s) return '';
    return String(s).replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;').replace(/"/g,'&quot;').replace(/'/g,'&#39;');
  }
</script>
</body>
</html>
