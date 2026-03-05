<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="com.oceanview.model.User" %>
<%@ page import="com.oceanview.model.Guest" %>
<%
    User currentUser = (User) session.getAttribute("loggedInUser");
    if (currentUser == null) currentUser = (User) session.getAttribute(com.oceanview.util.Constants.SESSION_USER);
    if (currentUser == null) { response.sendRedirect(request.getContextPath() + "/login"); return; }
    User user = (User) request.getAttribute("user");
    Guest guest = (Guest) request.getAttribute("guest");
    Boolean hasGuestProfile = (Boolean) request.getAttribute("hasGuestProfile");
    // Support both request attr keys for flash messages
    String error   = (String) request.getAttribute("error");
    if (error   == null) error   = (String) session.getAttribute(com.oceanview.util.Constants.ATTR_ERROR);
    String success = (String) request.getAttribute("success");
    if (success == null) success = (String) session.getAttribute(com.oceanview.util.Constants.ATTR_SUCCESS);
    session.removeAttribute(com.oceanview.util.Constants.ATTR_ERROR);
    session.removeAttribute(com.oceanview.util.Constants.ATTR_SUCCESS);
    String ctx = request.getContextPath();
    if (user == null) user = currentUser;   // always non-null now
    if (hasGuestProfile == null) hasGuestProfile = false;
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>My Profile - Ocean View Resort</title>
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
    <style>
        /* ============================================================
           PROFILE PAGE — FULLY SELF-CONTAINED EMBEDDED CSS
           ============================================================ */
        :root {
            --ocean-blue:  #1A6B8A;
            --ocean-dark:  #0D3F52;
            --ocean-light: #E8F4F8;
            --gold:        #D4AF37;
            --white:       #FFFFFF;
            --off-white:   #F9FAFB;
            --text-dark:   #1A2332;
            --text-mid:    #4A5568;
            --text-light:  #718096;
            --border:      #E2E8F0;
            --success:     #2F855A;
            --success-bg:  #F0FFF4;
            --success-bdr: #9AE6B4;
            --danger:      #C53030;
            --danger-bg:   #FFF5F5;
            --danger-bdr:  #FEB2B2;
            --warning:     #B7791F;
            --warning-bg:  #FFFFF0;
            --warning-bdr: #FAF089;
            --shadow-sm:   0 1px 3px rgba(0,0,0,0.08);
            --shadow-md:   0 4px 16px rgba(0,0,0,0.10);
            --shadow-lg:   0 12px 40px rgba(0,0,0,0.14);
            --radius-sm:   6px;
            --radius-md:   12px;
            --radius-lg:   20px;
            --transition:  0.22s ease;
        }

        *, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }

        body {
            font-family: 'Segoe UI', system-ui, -apple-system, sans-serif;
            background: var(--off-white);
            color: var(--text-dark);
            min-height: 100vh;
            display: flex;
            flex-direction: column;
        }

        a { text-decoration: none; color: inherit; }

        /* ── NAVBAR ── */
        .profile-navbar {
            background: var(--ocean-dark);
            position: sticky; top: 0; z-index: 200;
            box-shadow: var(--shadow-md);
        }
        .nav-inner {
            display: flex; align-items: center; justify-content: space-between;
            height: 64px; max-width: 1100px; margin: 0 auto; padding: 0 24px;
        }
        .nav-brand {
            display: flex; align-items: center; gap: 10px;
            color: var(--white); text-decoration: none;
        }
        .nav-brand i  { color: var(--gold); font-size: 1.5rem; }
        .nav-brand span { font-size: 1.05rem; font-weight: 700; letter-spacing: 0.4px; }
        .nav-right { display: flex; align-items: center; gap: 10px; }
        .nav-btn {
            display: inline-flex; align-items: center; gap: 6px;
            padding: 7px 16px; border-radius: var(--radius-sm);
            font-size: 0.875rem; font-weight: 500; cursor: pointer;
            border: none; transition: var(--transition); text-decoration: none;
        }
        .nav-btn-ghost {
            background: rgba(255,255,255,0.1); color: rgba(255,255,255,0.85);
        }
        .nav-btn-ghost:hover { background: rgba(255,255,255,0.2); color: var(--white); }
        .nav-btn-danger {
            background: rgba(197,48,48,0.75); color: var(--white);
        }
        .nav-btn-danger:hover { background: #C53030; }
        .nav-avatar {
            width: 36px; height: 36px; border-radius: 50%;
            background: var(--gold); color: var(--ocean-dark);
            display: flex; align-items: center; justify-content: center;
            font-weight: 700; font-size: 0.85rem;
        }

        /* ── PAGE WRAPPER ── */
        .profile-wrapper { flex: 1; max-width: 1100px; margin: 0 auto; width: 100%; padding: 32px 24px; }

        /* ── HERO BANNER ── */
        .profile-hero {
            background: linear-gradient(135deg, var(--ocean-dark) 0%, var(--ocean-blue) 100%);
            border-radius: var(--radius-lg);
            padding: 36px 40px;
            margin-bottom: 28px;
            display: flex; align-items: center; gap: 28px;
            box-shadow: var(--shadow-md);
            position: relative; overflow: hidden;
        }
        .profile-hero::after {
            content: '';
            position: absolute; right: -40px; top: -40px;
            width: 200px; height: 200px; border-radius: 50%;
            background: rgba(255,255,255,0.05);
        }
        .hero-avatar {
            width: 80px; height: 80px; border-radius: 50%;
            background: var(--gold); color: var(--ocean-dark);
            display: flex; align-items: center; justify-content: center;
            font-size: 2rem; font-weight: 700;
            border: 4px solid rgba(255,255,255,0.3);
            flex-shrink: 0;
        }
        .hero-info { color: var(--white); }
        .hero-info h1 { font-size: 1.6rem; font-weight: 700; margin-bottom: 4px; }
        .hero-info p  { font-size: 0.9rem; opacity: 0.8; margin-bottom: 10px; }
        .hero-badge {
            display: inline-flex; align-items: center; gap: 5px;
            background: rgba(255,255,255,0.15);
            padding: 4px 12px; border-radius: 20px;
            font-size: 0.8rem; color: var(--white);
        }

        /* ── ALERT MESSAGES ── */
        .alert {
            display: flex; align-items: flex-start; gap: 12px;
            padding: 14px 18px; border-radius: var(--radius-md);
            margin-bottom: 20px; font-size: 0.9rem; border-left: 4px solid;
        }
        .alert i { margin-top: 1px; flex-shrink: 0; }
        .alert-success { background: var(--success-bg); border-color: var(--success); color: var(--success); }
        .alert-danger  { background: var(--danger-bg);  border-color: var(--danger);  color: var(--danger);  }

        /* ── SECTION CARD ── */
        .section-card {
            background: var(--white);
            border-radius: var(--radius-md);
            box-shadow: var(--shadow-sm);
            border: 1px solid var(--border);
            margin-bottom: 24px;
            overflow: hidden;
        }
        .section-header {
            display: flex; align-items: center; justify-content: space-between;
            padding: 20px 28px;
            border-bottom: 1px solid var(--border);
            background: linear-gradient(to right, #f8fbfd, var(--white));
        }
        .section-header-left { display: flex; align-items: center; gap: 12px; }
        .section-icon {
            width: 40px; height: 40px; border-radius: var(--radius-sm);
            background: var(--ocean-light);
            display: flex; align-items: center; justify-content: center;
            color: var(--ocean-blue); font-size: 1rem;
        }
        .section-title { font-size: 1.05rem; font-weight: 600; color: var(--text-dark); }
        .section-subtitle { font-size: 0.8rem; color: var(--text-light); margin-top: 1px; }
        .section-body { padding: 28px; }

        /* ── INFO GRID (view mode) ── */
        .info-grid {
            display: grid;
            grid-template-columns: repeat(auto-fill, minmax(240px, 1fr));
            gap: 16px;
        }
        .info-card {
            background: var(--off-white);
            border: 1px solid var(--border);
            border-radius: var(--radius-sm);
            padding: 14px 16px;
            border-left: 3px solid var(--ocean-blue);
        }
        .info-card-label {
            font-size: 0.75rem; font-weight: 600;
            text-transform: uppercase; letter-spacing: 0.5px;
            color: var(--text-light); margin-bottom: 6px;
        }
        .info-card-value {
            font-size: 0.95rem; font-weight: 600; color: var(--text-dark);
        }
        .info-card-value.empty {
            color: var(--text-light); font-style: italic; font-weight: 400;
        }

        /* ── SECTION DIVIDER ── */
        .divider {
            border: none; height: 1px;
            background: var(--border); margin: 24px 0;
        }
        .sub-section-title {
            font-size: 0.95rem; font-weight: 600; color: var(--text-mid);
            margin-bottom: 16px; display: flex; align-items: center; gap: 8px;
        }
        .sub-section-title i { color: var(--ocean-blue); }

        /* ── BUTTONS ── */
        .btn {
            display: inline-flex; align-items: center; gap: 6px;
            padding: 9px 20px; border-radius: var(--radius-sm);
            font-size: 0.875rem; font-weight: 500;
            cursor: pointer; border: none; transition: var(--transition);
            text-decoration: none; white-space: nowrap;
        }
        .btn-primary   { background: var(--ocean-blue); color: var(--white); }
        .btn-primary:hover   { background: var(--ocean-dark); }
        .btn-secondary { background: var(--off-white); color: var(--text-mid); border: 1px solid var(--border); }
        .btn-secondary:hover { background: var(--border); }
        .btn-outline   { background: transparent; color: var(--ocean-blue); border: 1.5px solid var(--ocean-blue); }
        .btn-outline:hover   { background: var(--ocean-blue); color: var(--white); }
        .btn-danger    { background: var(--danger); color: var(--white); }
        .btn-danger:hover    { background: #9B2C2C; }
        .btn-success   { background: var(--success); color: var(--white); }
        .btn-success:hover   { background: #276749; }
        .btn-group     { display: flex; gap: 10px; flex-wrap: wrap; margin-top: 24px; }

        /* ── FORM ELEMENTS ── */
        .form-row {
            display: grid;
            grid-template-columns: repeat(auto-fill, minmax(220px, 1fr));
            gap: 20px;
        }
        .form-group { display: flex; flex-direction: column; gap: 6px; }
        .form-label {
            font-size: 0.8rem; font-weight: 600;
            color: var(--text-mid); letter-spacing: 0.3px;
        }
        .form-label.required::after { content: " *"; color: var(--danger); }
        .form-control {
            width: 100%; padding: 10px 13px;
            font-size: 0.9rem; color: var(--text-dark);
            background: var(--white); border: 1.5px solid var(--border);
            border-radius: var(--radius-sm);
            transition: border-color var(--transition), box-shadow var(--transition);
            outline: none;
        }
        .form-control:focus {
            border-color: var(--ocean-blue);
            box-shadow: 0 0 0 3px rgba(26,107,138,0.12);
        }
        .form-control:disabled {
            background: var(--off-white); color: var(--text-light); cursor: not-allowed;
        }
        textarea.form-control { resize: vertical; min-height: 90px; }
        select.form-control { cursor: pointer; }
        .help-text { font-size: 0.78rem; color: var(--text-light); }

        /* ── DANGER ZONE ── */
        .danger-zone {
            border: 2px solid var(--danger-bdr);
            border-radius: var(--radius-md);
            padding: 24px 28px;
            background: var(--danger-bg);
            margin-top: 8px;
        }
        .danger-zone-title {
            display: flex; align-items: center; gap: 8px;
            font-size: 1rem; font-weight: 700;
            color: var(--danger); margin-bottom: 8px;
        }
        .danger-zone p { font-size: 0.875rem; color: var(--text-mid); margin-bottom: 16px; }

        /* ── MODAL BACKDROP ── */
        .modal-backdrop {
            display: none; position: fixed;
            inset: 0; z-index: 500;
            background: rgba(0,0,0,0.55);
            align-items: center; justify-content: center;
            padding: 24px;
            animation: fadeIn 0.2s ease;
        }
        .modal-backdrop.open { display: flex; }

        /* ── MODAL BOX ── */
        .modal-box {
            background: var(--white); border-radius: var(--radius-md);
            box-shadow: var(--shadow-lg);
            width: 100%; max-width: 480px;
            max-height: 90vh; overflow-y: auto;
            animation: slideUp 0.25s ease;
        }
        .modal-head {
            display: flex; align-items: center; justify-content: space-between;
            padding: 20px 24px;
            background: linear-gradient(135deg, var(--ocean-dark), var(--ocean-blue));
            color: var(--white);
        }
        .modal-head.danger { background: linear-gradient(135deg, #9B2C2C, var(--danger)); }
        .modal-head-title { display: flex; align-items: center; gap: 10px; font-size: 1rem; font-weight: 600; }
        .modal-close-btn {
            background: rgba(255,255,255,0.15); border: none; color: var(--white);
            width: 32px; height: 32px; border-radius: 50%;
            font-size: 1.1rem; cursor: pointer; display: flex;
            align-items: center; justify-content: center;
            transition: background var(--transition);
        }
        .modal-close-btn:hover { background: rgba(255,255,255,0.3); }
        .modal-body { padding: 24px; }
        .modal-alert {
            display: flex; align-items: flex-start; gap: 10px;
            padding: 12px 16px; border-radius: var(--radius-sm);
            background: var(--danger-bg); border: 1px solid var(--danger-bdr);
            color: var(--danger); font-size: 0.85rem; margin-bottom: 20px;
        }

        /* ── ANIMATIONS ── */
        @keyframes fadeIn  { from { opacity: 0; }                   to { opacity: 1; } }
        @keyframes slideUp { from { transform: translateY(30px); opacity: 0; }
                             to   { transform: translateY(0);    opacity: 1; } }

        /* ── FOOTER ── */
        .profile-footer {
            background: var(--ocean-dark); color: rgba(255,255,255,0.6);
            text-align: center; padding: 20px 24px;
            font-size: 0.82rem; margin-top: auto;
        }

        /* ── RESPONSIVE ── */
        @media (max-width: 768px) {
            .profile-hero  { flex-direction: column; text-align: center; padding: 28px 24px; }
            .hero-avatar   { width: 64px; height: 64px; font-size: 1.5rem; }
            .hero-info h1  { font-size: 1.3rem; }
            .nav-inner     { padding: 0 16px; }
            .profile-wrapper { padding: 20px 16px; }
            .section-body  { padding: 20px; }
            .section-header{ padding: 16px 20px; }
            .form-row      { grid-template-columns: 1fr; }
            .info-grid     { grid-template-columns: 1fr 1fr; }
            .btn-group     { flex-direction: column; }
            .btn-group .btn { justify-content: center; }
        }
        @media (max-width: 480px) {
            .info-grid { grid-template-columns: 1fr; }
        }
    </style>
</head>
<body>

<!-- ── NAVBAR ── -->
<nav class="profile-navbar">
    <div class="nav-inner">
        <a href="<%= ctx %>/guest/home" class="nav-brand">
            <i class="fas fa-hotel"></i>
            <span>Ocean View Resort</span>
        </a>
        <div class="nav-right">
            <div class="nav-avatar">
                <%= user != null && user.getFullName() != null ? user.getFullName().substring(0,1).toUpperCase() : "G" %>
            </div>
            <a href="<%= ctx %>/guest/home" class="nav-btn nav-btn-ghost">
                <i class="fas fa-th-large"></i> Dashboard
            </a>
            <a href="<%= ctx %>/guest/reservations" class="nav-btn nav-btn-ghost">
                <i class="fas fa-calendar-check"></i> Reservations
            </a>
            <a href="<%= ctx %>/logout" class="nav-btn nav-btn-danger">
                <i class="fas fa-sign-out-alt"></i> Logout
            </a>
        </div>
    </div>
</nav>

<!-- ── PAGE WRAPPER ── -->
<div class="profile-wrapper">

    <!-- ── HERO BANNER ── -->
    <div class="profile-hero">
        <div class="hero-avatar">
            <%= user != null && user.getFullName() != null ? user.getFullName().substring(0,1).toUpperCase() : "G" %>
        </div>
        <div class="hero-info">
            <h1><%= (user != null && user.getFullName() != null && !user.getFullName().isEmpty()) ? user.getFullName() : (user != null ? user.getUsername() : "Guest") %></h1>
            <p><%= user != null && user.getEmail() != null ? user.getEmail() : "" %></p>
            <span class="hero-badge">
                <i class="fas fa-user-check"></i>
                <%= (user != null && user.getRole() != null) ? user.getRole() : "GUEST" %> &nbsp;&bull;&nbsp; <%= (user != null && user.getStatus() != null) ? user.getStatus() : "ACTIVE" %>
            </span>
        </div>
    </div>

    <!-- ── ALERTS ── -->
    <% if (success != null) { %>
    <div class="alert alert-success">
        <i class="fas fa-check-circle"></i>
        <span><%= success %></span>
    </div>
    <% } %>
    <% if (error != null) { %>
    <div class="alert alert-danger">
        <i class="fas fa-exclamation-circle"></i>
        <span><%= error %></span>
    </div>
    <% } %>

    <!-- ═══════════════════════════════════════
         PERSONAL INFORMATION CARD
    ════════════════════════════════════════ -->
    <div class="section-card">
        <div class="section-header">
            <div class="section-header-left">
                <div class="section-icon"><i class="fas fa-user"></i></div>
                <div>
                    <div class="section-title">Personal Information</div>
                    <div class="section-subtitle">Your account details and guest profile</div>
                </div>
            </div>
            <button class="btn btn-outline" onclick="toggleEditMode()">
                <i class="fas fa-edit" id="editBtnIcon"></i>
                <span id="editBtnLabel">Edit Profile</span>
            </button>
        </div>
        <div class="section-body">

            <!-- VIEW MODE -->
            <div id="viewMode">
                <p class="sub-section-title"><i class="fas fa-id-card"></i> Account Details</p>
                <div class="info-grid">
                    <div class="info-card">
                        <div class="info-card-label">Username</div>
                        <div class="info-card-value"><%= user.getUsername() %></div>
                    </div>
                    <div class="info-card">
                        <div class="info-card-label">Full Name</div>
                        <div class="info-card-value <%= user.getFullName() == null ? "empty" : "" %>">
                            <%= user.getFullName() != null ? user.getFullName() : "Not set" %>
                        </div>
                    </div>
                    <div class="info-card">
                        <div class="info-card-label">Email Address</div>
                        <div class="info-card-value"><%= user.getEmail() %></div>
                    </div>
                    <div class="info-card">
                        <div class="info-card-label">Phone Number</div>
                        <div class="info-card-value <%= user.getPhone() == null ? "empty" : "" %>">
                            <%= user.getPhone() != null ? user.getPhone() : "Not provided" %>
                        </div>
                    </div>
                    <div class="info-card">
                        <div class="info-card-label">Role</div>
                        <div class="info-card-value"><%= user.getRole() %></div>
                    </div>
                    <div class="info-card">
                        <div class="info-card-label">Account Status</div>
                        <div class="info-card-value"><%= user.getStatus() %></div>
                    </div>
                </div>

                <% if (hasGuestProfile && guest != null) { %>
                <hr class="divider">
                <p class="sub-section-title"><i class="fas fa-address-card"></i> Additional Guest Details</p>
                <div class="info-grid">
                    <div class="info-card">
                        <div class="info-card-label">Date of Birth</div>
                        <div class="info-card-value <%= guest.getDateOfBirth() == null ? "empty" : "" %>">
                            <%= guest.getDateOfBirth() != null ? guest.getDateOfBirth().toString() : "Not provided" %>
                        </div>
                    </div>
                    <div class="info-card">
                        <div class="info-card-label">Gender</div>
                        <div class="info-card-value <%= guest.getGender() == null ? "empty" : "" %>">
                            <%= guest.getGender() != null ? guest.getGender().toString() : "Not provided" %>
                        </div>
                    </div>
                    <div class="info-card">
                        <div class="info-card-label">Address</div>
                        <div class="info-card-value <%= guest.getAddress() == null ? "empty" : "" %>">
                            <%= guest.getAddress() != null ? guest.getAddress() : "Not provided" %>
                        </div>
                    </div>
                    <div class="info-card">
                        <div class="info-card-label">City</div>
                        <div class="info-card-value <%= guest.getCity() == null ? "empty" : "" %>">
                            <%= guest.getCity() != null ? guest.getCity() : "Not provided" %>
                        </div>
                    </div>
                    <div class="info-card">
                        <div class="info-card-label">Country</div>
                        <div class="info-card-value <%= guest.getCountry() == null ? "empty" : "" %>">
                            <%= guest.getCountry() != null ? guest.getCountry() : "Not provided" %>
                        </div>
                    </div>
                    <div class="info-card">
                        <div class="info-card-label">Postal Code</div>
                        <div class="info-card-value <%= guest.getPostalCode() == null ? "empty" : "" %>">
                            <%= guest.getPostalCode() != null ? guest.getPostalCode() : "Not provided" %>
                        </div>
                    </div>
                    <div class="info-card">
                        <div class="info-card-label">ID Type</div>
                        <div class="info-card-value <%= guest.getIdType() == null ? "empty" : "" %>">
                            <%= guest.getIdType() != null ? guest.getIdType() : "Not provided" %>
                        </div>
                    </div>
                    <div class="info-card">
                        <div class="info-card-label">ID Number</div>
                        <div class="info-card-value <%= guest.getIdNumber() == null ? "empty" : "" %>">
                            <%= guest.getIdNumber() != null ? guest.getIdNumber() : "Not provided" %>
                        </div>
                    </div>
                </div>
                <% if (guest.getPreferences() != null && !guest.getPreferences().isEmpty()) { %>
                <div style="margin-top:16px;">
                    <div class="info-card" style="border-left-color:var(--gold);">
                        <div class="info-card-label"><i class="fas fa-star"></i> Preferences</div>
                        <div class="info-card-value" style="font-weight:400;line-height:1.5;"><%= guest.getPreferences() %></div>
                    </div>
                </div>
                <% } %>
                <% } %>
            </div><!-- /viewMode -->

            <!-- EDIT MODE -->
            <div id="editMode" style="display:none;">
                <form action="<%= ctx %>/guest/profile" method="post" id="profileForm">
                    <input type="hidden" name="action" value="update">

                    <p class="sub-section-title"><i class="fas fa-id-card"></i> Basic Information</p>
                    <div class="form-row">
                        <div class="form-group">
                            <label class="form-label">Username</label>
                            <input type="text" class="form-control" value="<%= user.getUsername() %>" disabled>
                            <span class="help-text">Username cannot be changed</span>
                        </div>
                        <div class="form-group">
                            <label class="form-label required">Full Name</label>
                            <input type="text" name="fullName" class="form-control"
                                   value="<%= user.getFullName() != null ? user.getFullName() : "" %>"
                                   required maxlength="100" placeholder="John Smith">
                        </div>
                        <div class="form-group">
                            <label class="form-label required">Email Address</label>
                            <input type="email" name="email" class="form-control"
                                   value="<%= user.getEmail() %>" required maxlength="100">
                        </div>
                        <div class="form-group">
                            <label class="form-label">Phone Number</label>
                            <input type="tel" name="phone" class="form-control"
                                   value="<%= user.getPhone() != null ? user.getPhone() : "" %>"
                                   maxlength="20" placeholder="+1-234-567-8900">
                        </div>
                    </div>

                    <hr class="divider">
                    <p class="sub-section-title"><i class="fas fa-address-card"></i> Additional Details</p>
                    <div class="form-row">
                        <div class="form-group">
                            <label class="form-label">Date of Birth</label>
                            <input type="date" name="dateOfBirth" class="form-control"
                                   value="<%= (guest != null && guest.getDateOfBirth() != null) ? guest.getDateOfBirth().toString() : "" %>">
                        </div>
                        <div class="form-group">
                            <label class="form-label">Gender</label>
                            <select name="gender" class="form-control">
                                <option value="">Select Gender</option>
                                <option value="MALE"   <%= (guest != null && guest.getGender() == Guest.Gender.MALE)   ? "selected" : "" %>>Male</option>
                                <option value="FEMALE" <%= (guest != null && guest.getGender() == Guest.Gender.FEMALE) ? "selected" : "" %>>Female</option>
                                <option value="OTHER"  <%= (guest != null && guest.getGender() == Guest.Gender.OTHER)  ? "selected" : "" %>>Other</option>
                            </select>
                        </div>
                        <div class="form-group">
                            <label class="form-label">Address</label>
                            <input type="text" name="address" class="form-control"
                                   value="<%= (guest != null && guest.getAddress() != null) ? guest.getAddress() : "" %>"
                                   maxlength="200" placeholder="Street address">
                        </div>
                        <div class="form-group">
                            <label class="form-label">City</label>
                            <input type="text" name="city" class="form-control"
                                   value="<%= (guest != null && guest.getCity() != null) ? guest.getCity() : "" %>"
                                   maxlength="50">
                        </div>
                        <div class="form-group">
                            <label class="form-label">Country</label>
                            <input type="text" name="country" class="form-control"
                                   value="<%= (guest != null && guest.getCountry() != null) ? guest.getCountry() : "" %>"
                                   maxlength="50">
                        </div>
                        <div class="form-group">
                            <label class="form-label">Postal Code</label>
                            <input type="text" name="postalCode" class="form-control"
                                   value="<%= (guest != null && guest.getPostalCode() != null) ? guest.getPostalCode() : "" %>"
                                   maxlength="20">
                        </div>
                        <div class="form-group">
                            <label class="form-label">ID Type</label>
                            <select name="idType" class="form-control">
                                <option value="">Select ID Type</option>
                                <option value="Passport"       <%= (guest != null && "Passport".equals(guest.getIdType()))       ? "selected" : "" %>>Passport</option>
                                <option value="Driver License" <%= (guest != null && "Driver License".equals(guest.getIdType())) ? "selected" : "" %>>Driver License</option>
                                <option value="National ID"    <%= (guest != null && "National ID".equals(guest.getIdType()))    ? "selected" : "" %>>National ID</option>
                                <option value="Other"          <%= (guest != null && "Other".equals(guest.getIdType()))          ? "selected" : "" %>>Other</option>
                            </select>
                        </div>
                        <div class="form-group">
                            <label class="form-label">ID Number</label>
                            <input type="text" name="idNumber" class="form-control"
                                   value="<%= (guest != null && guest.getIdNumber() != null) ? guest.getIdNumber() : "" %>"
                                   maxlength="50">
                        </div>
                    </div>

                    <div class="form-group" style="margin-top:20px;">
                        <label class="form-label">Preferences &amp; Special Requests</label>
                        <textarea name="preferences" class="form-control" rows="3"
                                  maxlength="500"
                                  placeholder="Dietary requirements, accessibility needs, room preferences..."><%= (guest != null && guest.getPreferences() != null) ? guest.getPreferences() : "" %></textarea>
                    </div>

                    <div class="btn-group">
                        <button type="submit" class="btn btn-primary">
                            <i class="fas fa-save"></i> Save Changes
                        </button>
                        <button type="button" class="btn btn-secondary" onclick="toggleEditMode()">
                            <i class="fas fa-times"></i> Cancel
                        </button>
                    </div>
                </form>
            </div><!-- /editMode -->

        </div><!-- /section-body -->
    </div><!-- /section-card -->

    <!-- ═══════════════════════════════════════
         SECURITY CARD
    ════════════════════════════════════════ -->
    <div class="section-card">
        <div class="section-header">
            <div class="section-header-left">
                <div class="section-icon"><i class="fas fa-lock"></i></div>
                <div>
                    <div class="section-title">Security &amp; Account</div>
                    <div class="section-subtitle">Manage your password and account access</div>
                </div>
            </div>
        </div>
        <div class="section-body">
            <button class="btn btn-primary" onclick="openModal('passwordModal')">
                <i class="fas fa-key"></i> Change Password
            </button>

            <hr class="divider">

            <div class="danger-zone">
                <div class="danger-zone-title">
                    <i class="fas fa-exclamation-triangle"></i> Danger Zone
                </div>
                <p>Once you delete your account all your data will be permanently removed. This action cannot be undone.</p>
                <button class="btn btn-danger" onclick="openModal('deleteModal')">
                    <i class="fas fa-trash-alt"></i> Delete My Account
                </button>
            </div>
        </div>
    </div>

</div><!-- /profile-wrapper -->

<!-- ── FOOTER ── -->
<footer class="profile-footer">
    &copy; <%= java.time.Year.now().getValue() %> Ocean View Resort. All rights reserved.
</footer>

<!-- ═══════════════════════════════════════
     CHANGE PASSWORD MODAL
════════════════════════════════════════ -->
<div id="passwordModal" class="modal-backdrop">
    <div class="modal-box">
        <div class="modal-head">
            <div class="modal-head-title">
                <i class="fas fa-key"></i> Change Password
            </div>
            <button class="modal-close-btn" onclick="closeModal('passwordModal')">&times;</button>
        </div>
        <div class="modal-body">
            <form action="<%= ctx %>/guest/profile" method="post" id="passwordForm">
                <input type="hidden" name="action" value="changePassword">

                <div class="form-group" style="margin-bottom:16px;">
                    <label class="form-label required">Current Password</label>
                    <input type="password" name="currentPassword" class="form-control" required
                           placeholder="Enter your current password">
                </div>
                <div class="form-group" style="margin-bottom:16px;">
                    <label class="form-label required">New Password</label>
                    <input type="password" name="newPassword" class="form-control"
                           id="newPassword" required minlength="6"
                           placeholder="At least 6 characters">
                    <span class="help-text">Password must be at least 6 characters</span>
                </div>
                <div class="form-group" style="margin-bottom:8px;">
                    <label class="form-label required">Confirm New Password</label>
                    <input type="password" name="confirmPassword" class="form-control"
                           id="confirmPassword" required minlength="6"
                           placeholder="Repeat new password">
                </div>

                <div class="btn-group">
                    <button type="submit" class="btn btn-primary">
                        <i class="fas fa-save"></i> Update Password
                    </button>
                    <button type="button" class="btn btn-secondary" onclick="closeModal('passwordModal')">
                        Cancel
                    </button>
                </div>
            </form>
        </div>
    </div>
</div>

<!-- ═══════════════════════════════════════
     DELETE ACCOUNT MODAL
════════════════════════════════════════ -->
<div id="deleteModal" class="modal-backdrop">
    <div class="modal-box">
        <div class="modal-head danger">
            <div class="modal-head-title">
                <i class="fas fa-exclamation-triangle"></i> Delete Account
            </div>
            <button class="modal-close-btn" onclick="closeModal('deleteModal')">&times;</button>
        </div>
        <div class="modal-body">
            <div class="modal-alert">
                <i class="fas fa-exclamation-circle" style="flex-shrink:0;margin-top:1px;"></i>
                <span><strong>Warning!</strong> This action is permanent and cannot be undone. All your reservations, reviews and personal data will be deleted.</span>
            </div>

            <form action="<%= ctx %>/guest/profile" method="post" id="deleteForm" onsubmit="return confirmDelete()">
                <input type="hidden" name="action" value="delete">

                <div class="form-group" style="margin-bottom:16px;">
                    <label class="form-label required">Enter your password to confirm</label>
                    <input type="password" name="confirmPassword" class="form-control"
                           required placeholder="Your current password">
                </div>
                <div class="form-group" style="margin-bottom:8px;">
                    <label class="form-label required">Type <strong>DELETE</strong> to confirm</label>
                    <input type="text" name="confirmText" class="form-control"
                           required pattern="DELETE" title="Please type DELETE in uppercase"
                           placeholder="DELETE">
                    <span class="help-text">Must be typed in uppercase exactly as shown</span>
                </div>

                <div class="btn-group">
                    <button type="submit" class="btn btn-danger">
                        <i class="fas fa-trash-alt"></i> Permanently Delete Account
                    </button>
                    <button type="button" class="btn btn-secondary" onclick="closeModal('deleteModal')">
                        Cancel
                    </button>
                </div>
            </form>
        </div>
    </div>
</div>

<!-- ═══════════════════════════════════════
     JAVASCRIPT
════════════════════════════════════════ -->
<script>
(function() {
    'use strict';

    /* ── EDIT MODE TOGGLE ── */
    var editing = false;
    window.toggleEditMode = function() {
        editing = !editing;
        var viewMode  = document.getElementById('viewMode');
        var editMode  = document.getElementById('editMode');
        var icon      = document.getElementById('editBtnIcon');
        var label     = document.getElementById('editBtnLabel');
        if (editing) {
            viewMode.style.display = 'none';
            editMode.style.display = 'block';
            icon.className  = 'fas fa-times';
            label.textContent = 'Cancel Edit';
        } else {
            viewMode.style.display = 'block';
            editMode.style.display = 'none';
            icon.className  = 'fas fa-edit';
            label.textContent = 'Edit Profile';
        }
    };

    /* ── MODAL OPEN / CLOSE ── */
    window.openModal = function(id) {
        document.getElementById(id).classList.add('open');
        document.body.style.overflow = 'hidden';
    };
    window.closeModal = function(id) {
        var el = document.getElementById(id);
        el.classList.remove('open');
        document.body.style.overflow = '';
        /* reset forms inside modal */
        var form = el.querySelector('form');
        if (form) form.reset();
    };

    /* Close on backdrop click */
    document.querySelectorAll('.modal-backdrop').forEach(function(backdrop) {
        backdrop.addEventListener('click', function(e) {
            if (e.target === backdrop) closeModal(backdrop.id);
        });
    });

    /* Close on Escape */
    document.addEventListener('keydown', function(e) {
        if (e.key === 'Escape') {
            document.querySelectorAll('.modal-backdrop.open').forEach(function(m) {
                closeModal(m.id);
            });
        }
    });

    /* ── AUTO-OPEN MODAL FROM ?modal= QUERY PARAM ── */
    (function autoOpen() {
        var params = new URLSearchParams(window.location.search);
        var modal  = params.get('modal');
        if (modal === 'password') openModal('passwordModal');
        else if (modal === 'delete') openModal('deleteModal');
    })();

    /* ── PASSWORD MATCH VALIDATION ── */
    document.getElementById('passwordForm').addEventListener('submit', function(e) {
        var np = document.getElementById('newPassword').value;
        var cp = document.getElementById('confirmPassword').value;
        if (np !== cp) {
            e.preventDefault();
            alert('New passwords do not match. Please try again.');
        }
    });

    /* ── EMAIL FORMAT CHECK ── */
    document.getElementById('profileForm').addEventListener('submit', function(e) {
        var email = this.querySelector('input[name="email"]').value;
        if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) {
            e.preventDefault();
            alert('Please enter a valid email address.');
        }
    });

    /* ── DELETE CONFIRM ── */
    window.confirmDelete = function() {
        return confirm('Are you absolutely sure you want to permanently delete your account? This CANNOT be undone.');
    };

})();
</script>
</body>
</html>
