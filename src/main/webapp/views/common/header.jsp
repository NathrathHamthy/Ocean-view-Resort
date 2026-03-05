<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="com.oceanview.model.User, com.oceanview.util.Constants" %>
<%
    // Fix: use correct session key (Constants.SESSION_USER = "loggedInUser")
    User currentUser = (User) session.getAttribute(Constants.SESSION_USER);
    if (currentUser == null) currentUser = (User) session.getAttribute("user"); // fallback
    String contextPath = request.getContextPath();
    String pageTitle = request.getParameter("title");
    String pageCss = request.getParameter("css");
    String activeMenu = request.getParameter("active");
    
    if (pageTitle == null) pageTitle = "Ocean View Resort";
    
    // Support both old and new message key conventions
    String successMsg = (String) session.getAttribute("successMessage");
    if (successMsg == null) successMsg = (String) session.getAttribute(Constants.ATTR_SUCCESS);
    String errorMsg = (String) session.getAttribute("errorMessage");
    if (errorMsg == null) errorMsg = (String) session.getAttribute(Constants.ATTR_ERROR);
    String infoMsg = (String) session.getAttribute("infoMessage");
    
    // Clear messages after reading
    session.removeAttribute("successMessage");
    session.removeAttribute("errorMessage");
    session.removeAttribute("infoMessage");
    session.removeAttribute(Constants.ATTR_SUCCESS);
    session.removeAttribute(Constants.ATTR_ERROR);

    // Safe user info helpers
    String userInitials = "?";
    String userRole = "";
    if (currentUser != null) {
        String fn = currentUser.getFirstName();
        String ln = currentUser.getLastName();
        char c1 = (fn != null && !fn.isEmpty()) ? fn.charAt(0) : (currentUser.getUsername() != null && !currentUser.getUsername().isEmpty() ? currentUser.getUsername().charAt(0) : '?');
        char c2 = (ln != null && !ln.isEmpty()) ? ln.charAt(0) : ' ';
        userInitials = String.valueOf(c1) + (c2 != ' ' ? String.valueOf(c2) : "");
        userRole = currentUser.getRole() != null ? currentUser.getRole().toString() : "";
    }
%>

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta name="description" content="Ocean View Resort - Luxury Hotel Booking System">
    <meta name="keywords" content="hotel, resort, booking, ocean view, luxury accommodation">
    <meta name="author" content="Ocean View Resort">
    
    <title><%= pageTitle %> - Hotel Booking System</title>
    
    <!-- Favicon -->
    <link rel="icon" type="image/x-icon" href="<%= contextPath %>/assets/images/logo/favicon.ico">
    
    <!-- CSS Files -->
    <link rel="stylesheet" href="<%= contextPath %>/assets/css/main.css">
    <link rel="stylesheet" href="<%= contextPath %>/assets/css/header.css">
    <link rel="stylesheet" href="<%= contextPath %>/assets/css/footer.css">
    
    <!-- Font Awesome for Icons -->
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
    
    <!-- Additional Page-Specific CSS -->
    <% if (pageCss != null && !pageCss.isEmpty()) { %>
        <link rel="stylesheet" href="<%= contextPath %>/assets/css/<%= pageCss %>.css">
    <% } %>
</head>
<body>
    <!-- Header -->
    <header class="header">
        <!-- Top Bar -->
        <div class="header-top">
            <div class="container">
                <div class="header-contact">
                    <a href="tel:+94112345678">
                        <i class="fas fa-phone"></i>
                        <span>+94 11 234 5678</span>
                    </a>
                    <a href="mailto:info@oceanviewresort.com">
                        <i class="fas fa-envelope"></i>
                        <span>info@oceanviewresort.com</span>
                    </a>
                </div>
                <div class="header-links">
                    <% if (currentUser != null) { %>
                        <span>Welcome, <%= currentUser.getFirstName() != null ? currentUser.getFirstName() : currentUser.getUsername() %>!</span>
                    <% } else { %>
                        <a href="<%= contextPath %>/login">Login</a>
                        <span>|</span>
                        <a href="<%= contextPath %>/register">Register</a>
                    <% } %>
                </div>
            </div>
        </div>
        
        <!-- Main Header -->
        <div class="header-main">
            <div class="container">
                <a href="<%= contextPath %>/" class="logo">
                    <img src="<%= contextPath %>/assets/images/logo/logo.png" alt="Ocean View Resort" onerror="this.style.display='none'">
                    <span>Ocean View Resort</span>
                </a>
                
                <button class="menu-toggle" id="menuToggle">
                    <i class="fas fa-bars"></i>
                </button>
                
                <nav class="nav">
                    <ul class="nav-menu" id="navMenu">
                        <li><a href="<%= contextPath %>/" class="<%= "home".equals(activeMenu) ? "active" : "" %>">Home</a></li>
                        <li><a href="<%= contextPath %>/rooms" class="<%= "rooms".equals(activeMenu) ? "active" : "" %>">Rooms</a></li>
                        <li><a href="<%= contextPath %>/about" class="<%= "about".equals(activeMenu) ? "active" : "" %>">About</a></li>
                        <li><a href="<%= contextPath %>/contact" class="<%= "contact".equals(activeMenu) ? "active" : "" %>">Contact</a></li>
                        
                        <% if (currentUser != null) {
                            if ("ADMIN".equals(userRole)) { %>
                                <li><a href="<%= contextPath %>/admin/dashboard" class="<%= "admin".equals(activeMenu) ? "active" : "" %>">Admin</a></li>
                            <% } else if ("STAFF".equals(userRole)) { %>
                                <li><a href="<%= contextPath %>/staff/dashboard" class="<%= "staff".equals(activeMenu) ? "active" : "" %>">Staff</a></li>
                            <% } else { %>
                                <li><a href="<%= contextPath %>/guest/home" class="<%= "guest".equals(activeMenu) ? "active" : "" %>">My Account</a></li>
                            <% }
                        } %>
                    </ul>
                    
                    <% if (currentUser != null) { %>
                        <div class="nav-user">
                            <div class="user-dropdown">
                                <div class="user-avatar">
                                    <%= userInitials %>
                                </div>
                                <div class="dropdown-menu">
                                    <a href="<%= contextPath %>/guest/profile">
                                        <i class="fas fa-user"></i> My Profile
                                    </a>
                                    <% if ("GUEST".equals(userRole)) { %>
                                        <a href="<%= contextPath %>/reservation">
                                            <i class="fas fa-calendar-check"></i> My Reservations
                                        </a>
                                        <a href="<%= contextPath %>/review">
                                            <i class="fas fa-star"></i> My Reviews
                                        </a>
                                    <% } %>
                                    <% if ("ADMIN".equals(userRole)) { %>
                                        <a href="<%= contextPath %>/admin/settings">
                                            <i class="fas fa-cog"></i> Settings
                                        </a>
                                    <% } %>
                                    <a href="<%= contextPath %>/logout">
                                        <i class="fas fa-sign-out-alt"></i> Logout
                                    </a>
                                </div>
                            </div>
                        </div>
                    <% } %>
                </nav>
            </div>
        </div>
    </header>
    
    <!-- Alert Messages -->
    <% if (successMsg != null) { %>
        <div class="container mt-2">
            <div class="alert alert-success">
                <i class="fas fa-check-circle"></i>
                <%= successMsg %>
            </div>
        </div>
    <% } %>
    
    <% if (errorMsg != null) { %>
        <div class="container mt-2">
            <div class="alert alert-danger">
                <i class="fas fa-exclamation-circle"></i>
                <%= errorMsg %>
            </div>
        </div>
    <% } %>
    
    <% if (infoMsg != null) { %>
        <div class="container mt-2">
            <div class="alert alert-info">
                <i class="fas fa-info-circle"></i>
                <%= infoMsg %>
            </div>
        </div>
    <% } %>
    
    <!-- Main Content Start -->
    <main>
