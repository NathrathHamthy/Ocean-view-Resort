<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="com.oceanview.model.User" %>
<%
    User currentUser = (User) session.getAttribute("loggedInUser");
    if (currentUser == null) currentUser = (User) session.getAttribute("user"); // fallback
    String contextPath = request.getContextPath();
    String activePage = request.getParameter("active");
    if (activePage == null) activePage = "";
    
    String userRole = "";
    String userFullName = "";
    String userInitials = "";
    
    if (currentUser != null) {
        userRole = currentUser.getRole() != null ? currentUser.getRole().toString() : "";
        userFullName = currentUser.getFirstName() + " " + currentUser.getLastName();
        userInitials = String.valueOf(currentUser.getFirstName().charAt(0)) + 
                      String.valueOf(currentUser.getLastName().charAt(0));
    }
%>

<!-- Sidebar Component -->
<aside class="sidebar" id="sidebar" role="complementary">
    <!-- Sidebar Header -->
    <div class="sidebar-header">
        <div class="sidebar-brand">
            <img src="<%= contextPath %>/assets/images/logo/logo.png" 
                 alt="Ocean View Resort" 
                 class="sidebar-logo"
                 onerror="this.style.display='none'">
            <span class="sidebar-brand-text">Ocean View</span>
        </div>
        <button class="sidebar-toggle-btn" id="sidebarToggle" aria-label="Toggle sidebar">
            <i class="fas fa-bars"></i>
        </button>
    </div>
    
    <!-- User Profile Section -->
    <% if (currentUser != null) { %>
    <div class="sidebar-user">
        <div class="sidebar-user-avatar">
            <%= userInitials %>
        </div>
        <div class="sidebar-user-info">
            <div class="sidebar-user-name"><%= userFullName %></div>
            <div class="sidebar-user-role"><%= userRole %></div>
        </div>
    </div>
    <% } %>
    
    <!-- Sidebar Navigation -->
    <nav class="sidebar-nav" role="navigation">
        <% if ("ADMIN".equals(userRole)) { %>
            <!-- Admin Navigation -->
            <div class="sidebar-section">
                <div class="sidebar-section-title">Dashboard</div>
                <ul class="sidebar-menu">
                    <li class="sidebar-menu-item">
                        <a href="<%= contextPath %>/admin/dashboard" 
                           class="sidebar-link <%= "dashboard".equals(activePage) ? "active" : "" %>">
                            <i class="fas fa-tachometer-alt"></i>
                            <span>Overview</span>
                        </a>
                    </li>
                </ul>
            </div>
            
            <div class="sidebar-section">
                <div class="sidebar-section-title">Management</div>
                <ul class="sidebar-menu">
                    <li class="sidebar-menu-item">
                        <a href="<%= contextPath %>/admin/rooms" 
                           class="sidebar-link <%= "rooms".equals(activePage) ? "active" : "" %>">
                            <i class="fas fa-bed"></i>
                            <span>Rooms</span>
                        </a>
                    </li>
                    <li class="sidebar-menu-item">
                        <a href="<%= contextPath %>/admin/users" 
                           class="sidebar-link <%= "users".equals(activePage) ? "active" : "" %>">
                            <i class="fas fa-users"></i>
                            <span>Users</span>
                        </a>
                    </li>
                    <li class="sidebar-menu-item">
                        <a href="<%= contextPath %>/admin/reservations" 
                           class="sidebar-link <%= "reservations".equals(activePage) ? "active" : "" %>">
                            <i class="fas fa-calendar-alt"></i>
                            <span>Reservations</span>
                        </a>
                    </li>
                    <li class="sidebar-menu-item">
                        <a href="<%= contextPath %>/admin/reviews" 
                           class="sidebar-link <%= "reviews".equals(activePage) ? "active" : "" %>">
                            <i class="fas fa-star"></i>
                            <span>Reviews</span>
                        </a>
                    </li>
                    <li class="sidebar-menu-item">
                        <a href="<%= contextPath %>/admin/offers" 
                           class="sidebar-link <%= "offers".equals(activePage) ? "active" : "" %>">
                            <i class="fas fa-tags"></i>
                            <span>Special Offers</span>
                        </a>
                    </li>
                </ul>
            </div>
            
            <div class="sidebar-section">
                <div class="sidebar-section-title">Reports</div>
                <ul class="sidebar-menu">
                    <li class="sidebar-menu-item">
                        <a href="<%= contextPath %>/admin/reports" 
                           class="sidebar-link <%= "reports".equals(activePage) ? "active" : "" %>">
                            <i class="fas fa-chart-bar"></i>
                            <span>Reports</span>
                        </a>
                    </li>
                </ul>
            </div>
            
            <div class="sidebar-section">
                <div class="sidebar-section-title">System</div>
                <ul class="sidebar-menu">
                    <li class="sidebar-menu-item">
                        <a href="<%= contextPath %>/admin/settings" 
                           class="sidebar-link <%= "settings".equals(activePage) ? "active" : "" %>">
                            <i class="fas fa-cog"></i>
                            <span>Settings</span>
                        </a>
                    </li>
                </ul>
            </div>
            
        <% } else if ("STAFF".equals(userRole)) { %>
            <!-- Staff Navigation -->
            <div class="sidebar-section">
                <div class="sidebar-section-title">Dashboard</div>
                <ul class="sidebar-menu">
                    <li class="sidebar-menu-item">
                        <a href="<%= contextPath %>/staff/dashboard" 
                           class="sidebar-link <%= "dashboard".equals(activePage) ? "active" : "" %>">
                            <i class="fas fa-tachometer-alt"></i>
                            <span>Overview</span>
                        </a>
                    </li>
                </ul>
            </div>
            
            <div class="sidebar-section">
                <ul class="sidebar-menu">
                    <li class="sidebar-menu-item">
                        <a href="<%= contextPath %>/staff/reservations" 
                           class="sidebar-link <%= "reservations".equals(activePage) ? "active" : "" %>">
                            <i class="fas fa-calendar-check"></i>
                            <span>Reservations</span>
                        </a>
                    </li>
                    <li class="sidebar-menu-item">
                        <a href="<%= contextPath %>/staff/check-in" 
                           class="sidebar-link <%= "check-in".equals(activePage) ? "active" : "" %>">
                            <i class="fas fa-sign-in-alt"></i>
                            <span>Check-In</span>
                        </a>
                    </li>
                    <li class="sidebar-menu-item">
                        <a href="<%= contextPath %>/staff/check-out" 
                           class="sidebar-link <%= "check-out".equals(activePage) ? "active" : "" %>">
                            <i class="fas fa-sign-out-alt"></i>
                            <span>Check-Out</span>
                        </a>
                    </li>
                </ul>
            </div>
            
        <% } else if ("GUEST".equals(userRole)) { %>
            <!-- Guest Navigation -->
            <div class="sidebar-section">
                <div class="sidebar-section-title">My Account</div>
                <ul class="sidebar-menu">
                    <li class="sidebar-menu-item">
                        <a href="<%= contextPath %>/guest/dashboard" 
                           class="sidebar-link <%= "dashboard".equals(activePage) ? "active" : "" %>">
                            <i class="fas fa-tachometer-alt"></i>
                            <span>Dashboard</span>
                        </a>
                    </li>
                    <li class="sidebar-menu-item">
                        <a href="<%= contextPath %>/guest/profile" 
                           class="sidebar-link <%= "profile".equals(activePage) ? "active" : "" %>">
                            <i class="fas fa-user"></i>
                            <span>My Profile</span>
                        </a>
                    </li>
                </ul>
            </div>
            
            <div class="sidebar-section">
                <div class="sidebar-section-title">Bookings</div>
                <ul class="sidebar-menu">
                    <li class="sidebar-menu-item">
                        <a href="<%= contextPath %>/guest/rooms" 
                           class="sidebar-link <%= "rooms".equals(activePage) ? "active" : "" %>">
                            <i class="fas fa-bed"></i>
                            <span>Browse Rooms</span>
                        </a>
                    </li>
                    <li class="sidebar-menu-item">
                        <a href="<%= contextPath %>/guest/reservations" 
                           class="sidebar-link <%= "reservations".equals(activePage) ? "active" : "" %>">
                            <i class="fas fa-calendar-check"></i>
                            <span>My Reservations</span>
                        </a>
                    </li>
                    <li class="sidebar-menu-item">
                        <a href="<%= contextPath %>/guest/bookings/new" 
                           class="sidebar-link <%= "new-booking".equals(activePage) ? "active" : "" %>">
                            <i class="fas fa-plus-circle"></i>
                            <span>New Booking</span>
                        </a>
                    </li>
                </ul>
            </div>
            
            <div class="sidebar-section">
                <div class="sidebar-section-title">Activity</div>
                <ul class="sidebar-menu">
                    <li class="sidebar-menu-item">
                        <a href="<%= contextPath %>/guest/reviews" 
                           class="sidebar-link <%= "reviews".equals(activePage) ? "active" : "" %>">
                            <i class="fas fa-star"></i>
                            <span>My Reviews</span>
                        </a>
                    </li>
                    <li class="sidebar-menu-item">
                        <a href="<%= contextPath %>/guest/payments" 
                           class="sidebar-link <%= "payments".equals(activePage) ? "active" : "" %>">
                            <i class="fas fa-credit-card"></i>
                            <span>Payment History</span>
                        </a>
                    </li>
                </ul>
            </div>
        <% } else { %>
            <!-- Public/Default Navigation -->
            <div class="sidebar-section">
                <div class="sidebar-section-title">Explore</div>
                <ul class="sidebar-menu">
                    <li class="sidebar-menu-item">
                        <a href="<%= contextPath %>/" 
                           class="sidebar-link <%= "home".equals(activePage) ? "active" : "" %>">
                            <i class="fas fa-home"></i>
                            <span>Home</span>
                        </a>
                    </li>
                    <li class="sidebar-menu-item">
                        <a href="<%= contextPath %>/rooms" 
                           class="sidebar-link <%= "rooms".equals(activePage) ? "active" : "" %>">
                            <i class="fas fa-bed"></i>
                            <span>Rooms & Suites</span>
                        </a>
                    </li>
                    <li class="sidebar-menu-item">
                        <a href="<%= contextPath %>/offers" 
                           class="sidebar-link <%= "offers".equals(activePage) ? "active" : "" %>">
                            <i class="fas fa-tags"></i>
                            <span>Special Offers</span>
                        </a>
                    </li>
                    <li class="sidebar-menu-item">
                        <a href="<%= contextPath %>/about" 
                           class="sidebar-link <%= "about".equals(activePage) ? "active" : "" %>">
                            <i class="fas fa-info-circle"></i>
                            <span>About Us</span>
                        </a>
                    </li>
                    <li class="sidebar-menu-item">
                        <a href="<%= contextPath %>/contact" 
                           class="sidebar-link <%= "contact".equals(activePage) ? "active" : "" %>">
                            <i class="fas fa-envelope"></i>
                            <span>Contact</span>
                        </a>
                    </li>
                </ul>
            </div>
        <% } %>
    </nav>
    
    <!-- Sidebar Footer -->
    <div class="sidebar-footer">
        <% if (currentUser != null) { %>
            <a href="<%= contextPath %>/settings" class="sidebar-footer-link">
                <i class="fas fa-cog"></i>
                <span>Settings</span>
            </a>
            <a href="<%= contextPath %>/logout" class="sidebar-footer-link sidebar-logout">
                <i class="fas fa-sign-out-alt"></i>
                <span>Logout</span>
            </a>
        <% } else { %>
            <a href="<%= contextPath %>/login" class="sidebar-footer-link">
                <i class="fas fa-sign-in-alt"></i>
                <span>Login</span>
            </a>
            <a href="<%= contextPath %>/register" class="sidebar-footer-link">
                <i class="fas fa-user-plus"></i>
                <span>Register</span>
            </a>
        <% } %>
    </div>
</aside>

<!-- Sidebar Overlay for Mobile -->
<div class="sidebar-overlay" id="sidebarOverlay"></div>

<!-- Sidebar JavaScript -->
<script>
(function() {
    'use strict';
    
    const sidebar = document.getElementById('sidebar');
    const sidebarToggle = document.getElementById('sidebarToggle');
    const sidebarOverlay = document.getElementById('sidebarOverlay');
    
    // Toggle sidebar
    function toggleSidebar() {
        if (sidebar && sidebarOverlay) {
            const isOpen = sidebar.classList.toggle('open');
            sidebarOverlay.classList.toggle('active', isOpen);
            document.body.classList.toggle('sidebar-open', isOpen);
        }
    }
    
    // Close sidebar
    function closeSidebar() {
        if (sidebar && sidebarOverlay) {
            sidebar.classList.remove('open');
            sidebarOverlay.classList.remove('active');
            document.body.classList.remove('sidebar-open');
        }
    }
    
    // Event listeners
    if (sidebarToggle) {
        sidebarToggle.addEventListener('click', toggleSidebar);
    }
    
    if (sidebarOverlay) {
        sidebarOverlay.addEventListener('click', closeSidebar);
    }
    
    // Close sidebar when clicking on links (mobile)
    const sidebarLinks = document.querySelectorAll('.sidebar-link');
    sidebarLinks.forEach(function(link) {
        link.addEventListener('click', function() {
            if (window.innerWidth <= 992) {
                closeSidebar();
            }
        });
    });
    
    // Handle window resize
    let resizeTimer;
    window.addEventListener('resize', function() {
        clearTimeout(resizeTimer);
        resizeTimer = setTimeout(function() {
            if (window.innerWidth > 992) {
                closeSidebar();
            }
        }, 250);
    });
})();
</script>
