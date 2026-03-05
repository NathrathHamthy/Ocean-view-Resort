<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="com.oceanview.model.User" %>
<%@ page import="com.oceanview.model.Reservation" %>
<%@ page import="com.oceanview.model.Offer" %>
<%@ page import="java.util.List" %>
<%@ page import="java.time.format.DateTimeFormatter" %>
<%
    // Get user from session - authentication already done by GuestHomeServlet
    User currentUser = (User) session.getAttribute("loggedInUser");
    String contextPath = request.getContextPath();
    
    // Get statistics from request attributes
    Integer activeBookingsCount = (Integer) request.getAttribute("activeBookingsCount");
    Integer reviewsWrittenCount = (Integer) request.getAttribute("reviewsWrittenCount");
    Integer totalStaysCount = (Integer) request.getAttribute("totalStaysCount");
    Integer loyaltyPoints = (Integer) request.getAttribute("loyaltyPoints");
    Reservation currentBooking = (Reservation) request.getAttribute("currentBooking");
    List<Offer> activeOffers = (List<Offer>) request.getAttribute("activeOffers");
    String error = (String) request.getAttribute("error");
    
    // Default values if null
    if (activeBookingsCount == null) activeBookingsCount = 0;
    if (reviewsWrittenCount == null) reviewsWrittenCount = 0;
    if (totalStaysCount == null) totalStaysCount = 0;
    if (loyaltyPoints == null) loyaltyPoints = 0;
    
    DateTimeFormatter dateFormatter = DateTimeFormatter.ofPattern("MMM dd, yyyy");
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Guest Home - Ocean View Resort</title>
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/css/all.min.css">
    
    <style>
        /* CSS Variables */
        :root {
            --ocean-blue: #006994;
            --ocean-light: #4A90A4;
            --ocean-dark: #003d5c;
            --sand-beige: #F5E6D3;
            --white: #FFFFFF;
            --light-gray: #F8F9FA;
            --gray: #6C757D;
            --dark-gray: #343A40;
            --success: #28A745;
            --danger: #DC3545;
            --warning: #FFC107;
            --info: #17A2B8;
            --shadow-md: 0 4px 6px rgba(0, 0, 0, 0.1);
            --shadow-lg: 0 10px 15px rgba(0, 0, 0, 0.1);
            --radius-md: 0.5rem;
            --radius-lg: 1rem;
            --transition-base: 0.3s ease-in-out;
        }
        
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background-color: var(--light-gray);
            color: var(--dark-gray);
        }
        
        /* Navbar */
        .navbar {
            background-color: var(--white);
            box-shadow: var(--shadow-md);
            padding: 1rem 0;
            position: sticky;
            top: 0;
            z-index: 100;
        }
        
        .navbar-container {
            max-width: 1400px;
            margin: 0 auto;
            padding: 0 2rem;
            display: flex;
            justify-content: space-between;
            align-items: center;
        }
        
        .navbar-brand {
            font-size: 1.5rem;
            font-weight: 700;
            color: var(--ocean-blue);
            text-decoration: none;
        }
        
        .navbar-user {
            display: flex;
            align-items: center;
            gap: 1rem;
        }
        
        .user-info {
            display: flex;
            align-items: center;
            gap: 0.5rem;
        }
        
        .user-avatar {
            width: 40px;
            height: 40px;
            border-radius: 50%;
            background: var(--ocean-blue);
            color: var(--white);
            display: flex;
            align-items: center;
            justify-content: center;
            font-weight: bold;
        }
        
        .btn {
            padding: 0.5rem 1rem;
            border: none;
            border-radius: var(--radius-md);
            font-weight: 500;
            cursor: pointer;
            text-decoration: none;
            display: inline-flex;
            align-items: center;
            gap: 0.5rem;
            transition: var(--transition-base);
        }
        
        .btn-primary {
            background-color: var(--ocean-blue);
            color: var(--white);
        }
        
        .btn-primary:hover {
            background-color: var(--ocean-dark);
        }
        
        .btn-outline {
            background-color: transparent;
            border: 2px solid var(--ocean-blue);
            color: var(--ocean-blue);
        }
        
        .btn-outline:hover {
            background-color: var(--ocean-blue);
            color: var(--white);
        }
        
        .btn-danger {
            background-color: var(--danger);
            color: var(--white);
        }
        
        .btn-danger:hover {
            background-color: #c82333;
        }
        
        .btn-lg {
            padding: 0.75rem 1.5rem;
            font-size: 1.125rem;
        }
        
        /* Container */
        .container {
            max-width: 1400px;
            margin: 0 auto;
            padding: 2rem;
        }
        
        /* Welcome Banner */
        .welcome-banner {
            background: linear-gradient(135deg, var(--ocean-blue), var(--ocean-dark));
            color: white;
            padding: 3rem 2rem;
            border-radius: var(--radius-lg);
            display: flex;
            justify-content: space-between;
            align-items: center;
            flex-wrap: wrap;
            gap: 2rem;
            margin-bottom: 2rem;
        }
        
        .welcome-content h1 {
            color: white;
            margin-bottom: 0.5rem;
            font-size: 2rem;
        }
        
        .welcome-content .lead {
            color: var(--sand-beige);
            font-size: 1.125rem;
        }
        
        .welcome-actions {
            display: flex;
            gap: 1rem;
            flex-wrap: wrap;
        }
        
        /* Stats Grid */
        .stats-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
            gap: 1.5rem;
            margin-bottom: 2rem;
        }
        
        .stat-card {
            background: var(--white);
            border-radius: var(--radius-lg);
            padding: 1.5rem;
            box-shadow: var(--shadow-md);
            transition: var(--transition-base);
        }
        
        .stat-card:hover {
            transform: translateY(-4px);
            box-shadow: var(--shadow-lg);
        }
        
        .stat-header {
            display: flex;
            align-items: center;
            gap: 1rem;
            margin-bottom: 1rem;
        }
        
        .stat-icon {
            width: 60px;
            height: 60px;
            border-radius: 50%;
            display: flex;
            align-items: center;
            justify-content: center;
            color: var(--white);
            font-size: 1.5rem;
        }
        
        .bg-primary { background-color: var(--ocean-blue); }
        .bg-success { background-color: var(--success); }
        .bg-info { background-color: var(--info); }
        .bg-warning { background-color: var(--warning); }
        .bg-danger { background-color: var(--danger); }
        
        .stat-details {
            flex: 1;
        }
        
        .stat-value {
            font-size: 2rem;
            font-weight: bold;
            color: var(--ocean-dark);
        }
        
        .stat-label {
            color: var(--gray);
            font-size: 0.875rem;
        }
        
        .stat-link {
            display: block;
            padding: 0.75rem;
            text-align: center;
            background-color: rgba(0, 0, 0, 0.05);
            color: var(--ocean-blue);
            text-decoration: none;
            font-size: 0.875rem;
            font-weight: 500;
            border-radius: 0 0 var(--radius-lg) var(--radius-lg);
            margin: 1rem -1.5rem -1.5rem;
            transition: var(--transition-base);
        }
        
        .stat-link:hover {
            background-color: rgba(0, 0, 0, 0.1);
        }
        
        /* Card */
        .card {
            background: var(--white);
            border-radius: var(--radius-lg);
            box-shadow: var(--shadow-md);
            margin-bottom: 2rem;
        }
        
        .card-header {
            padding: 1.5rem;
            border-bottom: 1px solid #e9ecef;
        }
        
        .card-header h3 {
            margin: 0;
            color: var(--ocean-dark);
            font-size: 1.25rem;
        }
        
        .card-body {
            padding: 1.5rem;
        }
        
        /* Current Booking */
        .current-booking-card {
            display: flex;
            gap: 2rem;
        }
        
        .booking-image {
            position: relative;
            width: 300px;
            height: 200px;
            border-radius: var(--radius-md);
            overflow: hidden;
            flex-shrink: 0;
        }
        
        .booking-image img {
            width: 100%;
            height: 100%;
            object-fit: cover;
        }
        
        .booking-status {
            position: absolute;
            top: 1rem;
            right: 1rem;
            padding: 0.5rem 1rem;
            border-radius: var(--radius-md);
            color: white;
            font-weight: 600;
            font-size: 0.875rem;
        }
        
        .badge-success {
            background-color: var(--success);
        }
        
        .booking-details {
            flex: 1;
        }
        
        .booking-details h4 {
            margin-bottom: 1rem;
            color: var(--ocean-dark);
            font-size: 1.5rem;
        }
        
        .booking-info {
            display: grid;
            grid-template-columns: repeat(2, 1fr);
            gap: 1rem;
            margin-bottom: 1rem;
        }
        
        .info-item {
            display: flex;
            align-items: center;
            gap: 0.5rem;
            color: var(--gray);
        }
        
        .info-item i {
            color: var(--ocean-blue);
        }
        
        .booking-actions {
            display: flex;
            gap: 0.5rem;
            flex-wrap: wrap;
        }
        
        /* Offers */
        .offers-list {
            display: flex;
            flex-direction: column;
        }
        
        .offer-item {
            display: flex;
            align-items: center;
            gap: 1rem;
            padding: 1rem;
            border-bottom: 1px solid #e9ecef;
        }
        
        .offer-item:last-child {
            border-bottom: none;
        }
        
        .offer-icon {
            width: 48px;
            height: 48px;
            border-radius: 50%;
            display: flex;
            align-items: center;
            justify-content: center;
            color: white;
            font-size: 1.25rem;
            flex-shrink: 0;
        }
        
        .offer-content {
            flex: 1;
        }
        
        .offer-title {
            font-weight: 600;
            margin-bottom: 0.25rem;
            color: var(--dark-gray);
        }
        
        .offer-desc {
            font-size: 0.875rem;
            color: var(--gray);
        }
        
        /* Quick Actions */
        .quick-actions-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(220px, 1fr));
            gap: 1.5rem;
        }
        
        .quick-action-card {
            display: flex;
            flex-direction: column;
            align-items: center;
            padding: 2rem;
            background-color: #f8f9fa;
            border-radius: var(--radius-lg);
            text-decoration: none;
            color: inherit;
            transition: var(--transition-base);
            text-align: center;
        }
        
        .quick-action-card:hover {
            transform: translateY(-4px);
            box-shadow: var(--shadow-lg);
        }
        
        .quick-action-icon {
            width: 64px;
            height: 64px;
            border-radius: 50%;
            display: flex;
            align-items: center;
            justify-content: center;
            color: white;
            font-size: 1.75rem;
            margin-bottom: 1rem;
        }
        
        .quick-action-content h5 {
            margin-bottom: 0.5rem;
            color: var(--ocean-dark);
        }
        
        .quick-action-content p {
            margin: 0;
            font-size: 0.875rem;
            color: var(--gray);
        }
        
        /* Grid System */
        .row {
            display: flex;
            flex-wrap: wrap;
            margin: 0 -0.75rem;
        }
        
        .col-lg-8 {
            flex: 0 0 66.666667%;
            max-width: 66.666667%;
            padding: 0 0.75rem;
        }
        
        .col-lg-4 {
            flex: 0 0 33.333333%;
            max-width: 33.333333%;
            padding: 0 0.75rem;
        }
        
        .mb-3 {
            margin-bottom: 1rem;
        }
        
        .mb-4 {
            margin-bottom: 2rem;
        }
        
        .mt-3 {
            margin-top: 1rem;
        }
        
        .p-0 {
            padding: 0 !important;
        }
        
        /* Responsive */
        @media (max-width: 992px) {
            .col-lg-8, .col-lg-4 {
                flex: 0 0 100%;
                max-width: 100%;
            }
        }
        
        @media (max-width: 768px) {
            .welcome-banner {
                text-align: center;
                justify-content: center;
            }
            
            .welcome-actions {
                width: 100%;
                flex-direction: column;
            }
            
            .current-booking-card {
                flex-direction: column;
            }
            
            .booking-image {
                width: 100%;
            }
            
            .booking-info {
                grid-template-columns: 1fr;
            }
            
            .container {
                padding: 1rem;
            }
        }
    </style>
</head>
<body>

<!-- Navbar -->
<nav class="navbar">
    <div class="navbar-container">
        <a href="<%= contextPath %>/" class="navbar-brand">
            <i class="fas fa-hotel"></i> Ocean View Resort
        </a>
        <div class="navbar-user">
            <div class="user-info">
                <div class="user-avatar">
                    <%= currentUser.getFullName().substring(0, 1).toUpperCase() %>
                </div>
                <span><strong><%= currentUser.getFullName() %></strong></span>
            </div>
            <a href="<%= contextPath %>/logout" class="btn btn-outline">
                <i class="fas fa-sign-out-alt"></i> Logout
            </a>
        </div>
    </div>
</nav>

<div class="container">
    <!-- Welcome Banner -->
    <div class="welcome-banner">
        <div class="welcome-content">
            <h1><i class="fas fa-home"></i> Welcome back, <%= currentUser.getFirstName() %>!</h1>
            <p class="lead">Enjoy your stay at Ocean View Resort</p>
        </div>
        <div class="welcome-actions">
            <a href="<%= contextPath %>/room" class="btn btn-primary btn-lg">
                <i class="fas fa-search"></i> Browse Rooms
            </a>
            <a href="<%= contextPath %>/reservation" class="btn btn-outline btn-lg">
                <i class="fas fa-calendar-check"></i> My Bookings
            </a>
        </div>
    </div>
    
    <!-- Quick Stats -->
    <% if (error != null) { %>
    <div class="alert alert-danger">
        <i class="fas fa-exclamation-triangle"></i> <%= error %>
    </div>
    <% } %>
    
    <div class="stats-grid">
        <div class="stat-card">
            <div class="stat-header">
                <div class="stat-icon bg-primary">
                    <i class="fas fa-calendar-check"></i>
                </div>
                <div class="stat-details">
                    <div class="stat-value"><%= activeBookingsCount %></div>
                    <div class="stat-label">Active Bookings</div>
                </div>
            </div>
            <a href="<%= contextPath %>/reservation" class="stat-link">
                View All <i class="fas fa-arrow-right"></i>
            </a>
        </div>
        
        <div class="stat-card">
            <div class="stat-header">
                <div class="stat-icon bg-success">
                    <i class="fas fa-star"></i>
                </div>
                <div class="stat-details">
                    <div class="stat-value"><%= reviewsWrittenCount %></div>
                    <div class="stat-label">Reviews Written</div>
                </div>
            </div>
            <a href="<%= contextPath %>/review" class="stat-link">
                View All <i class="fas fa-arrow-right"></i>
            </a>
        </div>
        
    </div>
    
    <!-- Current Booking & Offers -->
    <div class="row mb-4">
        <div class="col-lg-8">
            <div class="card">
                <div class="card-header">
                    <h3><i class="fas fa-calendar-alt"></i> Current Booking</h3>
                </div>
                <div class="card-body">
                    <% if (currentBooking != null) { %>
                    <div class="current-booking-card">
                        <div class="booking-image">
                            <img src="https://images.unsplash.com/photo-1611892440504-42a792e24d32?w=400" alt="Room">
                            <span class="booking-status badge-<%= currentBooking.getStatus().toString().equalsIgnoreCase("CONFIRMED") ? "success" : "info" %>">
                                <%= currentBooking.getStatus() %>
                            </span>
                        </div>
                        <div class="booking-details">
                            <h4>Reservation #<%= currentBooking.getReservationNumber() != null ? currentBooking.getReservationNumber() : currentBooking.getReservationId() %></h4>
                            <div class="booking-info">
                                <div class="info-item">
                                    <i class="fas fa-door-open"></i>
                                    <span>Room <%= currentBooking.getRoomId() %></span>
                                </div>
                                <div class="info-item">
                                    <i class="fas fa-calendar"></i>
                                    <span><%= currentBooking.getCheckInDate().format(dateFormatter) %> - <%= currentBooking.getCheckOutDate().format(dateFormatter) %></span>
                                </div>
                                <div class="info-item">
                                    <i class="fas fa-moon"></i>
                                    <span><%= java.time.temporal.ChronoUnit.DAYS.between(currentBooking.getCheckInDate(), currentBooking.getCheckOutDate()) %> Nights</span>
                                </div>
                                <div class="info-item">
                                    <i class="fas fa-users"></i>
                                    <span><%= currentBooking.getNumberOfGuests() %> Guests</span>
                                </div>
                            </div>
                            <div class="booking-actions mt-3">
                                <a href="<%= contextPath %>/reservation" class="btn btn-primary">
                                    <i class="fas fa-eye"></i> View Details
                                </a>
                                <button class="btn btn-outline" onclick="alert('Modification feature coming soon!')">
                                    <i class="fas fa-edit"></i> Modify
                                </button>
                                <button class="btn btn-danger" onclick="confirmCancel()">
                                    <i class="fas fa-times"></i> Cancel
                                </button>
                            </div>
                        </div>
                    </div>
                    <% } else { %>
                    <div class="text-center py-5">
                        <i class="fas fa-calendar-times fa-3x text-muted mb-3"></i>
                        <p class="text-muted">No current bookings</p>
                        <a href="<%= contextPath %>/room" class="btn btn-primary mt-3">
                            <i class="fas fa-search"></i> Browse Available Rooms
                        </a>
                    </div>
                    <% } %>
                </div>
            </div>
        </div>
        
        <div class="col-lg-4">
            <div class="card mb-3">
                <div class="card-header">
                    <h3><i class="fas fa-tags"></i> Special Offers</h3>
                </div>
                <div class="card-body p-0">
                    <div class="offers-list">
                        <% if (activeOffers != null && !activeOffers.isEmpty()) { 
                            String[] iconColors = {"bg-danger", "bg-success", "bg-info"};
                            for (int i = 0; i < activeOffers.size(); i++) { 
                                Offer offer = activeOffers.get(i);
                        %>
                        <div class="offer-item">
                            <div class="offer-icon <%= iconColors[i % 3] %>">
                                <i class="fas fa-percent"></i>
                            </div>
                            <div class="offer-content">
                                <div class="offer-title"><%= offer.getOfferName() %></div>
                                <div class="offer-desc"><%= offer.getDescription() %></div>
                            </div>
                        </div>
                        <% } 
                        } else { %>
                        <div class="text-center py-4">
                            <i class="fas fa-tag fa-2x text-muted mb-2"></i>
                            <p class="text-muted">No active offers at the moment</p>
                        </div>
                        <% } %>
                    </div>
                </div>
            </div>
        </div>
    </div>
    
    <!-- Quick Actions -->
    <div class="card">
        <div class="card-header">
            <h3><i class="fas fa-bolt"></i> Quick Actions</h3>
        </div>
        <div class="card-body">
            <div class="quick-actions-grid">
                <a href="<%= contextPath %>/room" class="quick-action-card">
                    <div class="quick-action-icon bg-primary">
                        <i class="fas fa-search"></i>
                    </div>
                    <div class="quick-action-content">
                        <h5>Search Rooms</h5>
                        <p>Find your perfect room</p>
                    </div>
                </a>
                
                <a href="<%= contextPath %>/reservation" class="quick-action-card">
                    <div class="quick-action-icon bg-success">
                        <i class="fas fa-calendar-alt"></i>
                    </div>
                    <div class="quick-action-content">
                        <h5>My Bookings</h5>
                        <p>View all reservations</p>
                    </div>
                </a>
                
                <a href="<%= contextPath %>/guest/profile" class="quick-action-card">
                    <div class="quick-action-icon bg-info">
                        <i class="fas fa-user"></i>
                    </div>
                    <div class="quick-action-content">
                        <h5>My Profile</h5>
                        <p>Update your information</p>
                    </div>
                </a>
                
                <a href="<%= contextPath %>/review" class="quick-action-card">
                    <div class="quick-action-icon bg-warning">
                        <i class="fas fa-star"></i>
                    </div>
                    <div class="quick-action-content">
                        <h5>My Reviews</h5>
                        <p>Rate your experiences</p>
                    </div>
                </a>
            </div>
        </div>
    </div>
</div>

<script>
function confirmCancel() {
    if (confirm('Are you sure you want to cancel this booking? This action cannot be undone.')) {
        alert('Cancellation request submitted. You will receive a confirmation email shortly.');
        // TODO: Send cancellation request to server
    }
}
</script>

</body>
</html>
