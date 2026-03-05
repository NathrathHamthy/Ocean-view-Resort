<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="com.oceanview.model.User, com.oceanview.model.Review, com.oceanview.model.Reservation, java.util.List, java.time.format.DateTimeFormatter" %>
<%
    User currentUser = (User) session.getAttribute("loggedInUser");
    if (currentUser == null) { response.sendRedirect(request.getContextPath() + "/login"); return; }
    String ctx = request.getContextPath();

    @SuppressWarnings("unchecked") List<Review> myReviews = (List<Review>) request.getAttribute("reviews");
    @SuppressWarnings("unchecked") List<Reservation> eligibleRes = (List<Reservation>) request.getAttribute("eligibleReservations");

    String successMsg = (String) request.getAttribute("success");
    String errorMsg   = (String) request.getAttribute("error");
    String preselectedResId = request.getParameter("reservationId");
    if (preselectedResId == null) preselectedResId = (String) request.getAttribute("reservationId");

    DateTimeFormatter dtf     = DateTimeFormatter.ofPattern("dd MMM yyyy");
    DateTimeFormatter dtfFull = DateTimeFormatter.ofPattern("dd MMM yyyy, HH:mm");

    long pendingCount  = myReviews != null ? myReviews.stream().filter(Review::isPending).count()  : 0;
    long approvedCount = myReviews != null ? myReviews.stream().filter(Review::isApproved).count() : 0;
    long rejectedCount = myReviews != null ? myReviews.stream().filter(Review::isRejected).count() : 0;
    int  totalCount    = myReviews != null ? myReviews.size() : 0;
    String initial = (currentUser.getFullName() != null && !currentUser.getFullName().isEmpty())
                     ? currentUser.getFullName().substring(0,1).toUpperCase() : "G";
%>
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>My Reviews - Ocean View Resort</title>
<link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
<style>
:root {
    --ocean-blue:#006994; --ocean-mid:#4A90A4; --ocean-dark:#003d5c;
    --ocean-light:#e8f4f8; --sand:#F5E6D3; --white:#fff;
    --gray-50:#f8f9fa; --gray-100:#f1f3f5; --gray-200:#e9ecef;
    --gray-500:#6c757d; --gray-700:#495057; --gray-900:#212529;
    --success:#28a745; --warning:#f0a500; --danger:#dc3545; --info:#17a2b8;
    --radius-sm:6px; --radius-md:10px; --radius-lg:16px;
    --shadow-sm:0 1px 3px rgba(0,0,0,.08);
    --shadow-md:0 4px 12px rgba(0,0,0,.10);
    --shadow-lg:0 8px 24px rgba(0,0,0,.14);
    --transition:.25s ease;
}
*,*::before,*::after{box-sizing:border-box;margin:0;padding:0}
body{font-family:'Segoe UI',system-ui,sans-serif;background:var(--gray-50);color:var(--gray-900);min-height:100vh}

/* NAVBAR */
.navbar{background:var(--white);box-shadow:var(--shadow-sm);position:sticky;top:0;z-index:200}
.nav-inner{max-width:1280px;margin:0 auto;padding:0 2rem;height:64px;display:flex;align-items:center;justify-content:space-between}
.brand{display:flex;align-items:center;gap:.6rem;text-decoration:none}
.brand-icon{width:36px;height:36px;border-radius:8px;background:linear-gradient(135deg,var(--ocean-blue),var(--ocean-dark));display:flex;align-items:center;justify-content:center;color:#fff;font-size:1rem}
.brand-name{font-size:1.1rem;font-weight:700;color:var(--ocean-dark)}
.nav-links{display:flex;gap:1.8rem;list-style:none}
.nav-links a{text-decoration:none;color:var(--gray-500);font-size:.9rem;font-weight:500;padding:.3rem 0;border-bottom:2px solid transparent;transition:var(--transition)}
.nav-links a:hover,.nav-links a.active{color:var(--ocean-blue);border-bottom-color:var(--ocean-blue)}
.nav-right{display:flex;align-items:center;gap:1rem}
.avatar{width:36px;height:36px;border-radius:50%;background:linear-gradient(135deg,var(--ocean-blue),var(--ocean-mid));color:#fff;font-weight:700;font-size:.9rem;display:flex;align-items:center;justify-content:center}
.btn-logout{padding:.4rem 1rem;border-radius:var(--radius-sm);background:transparent;border:1.5px solid var(--ocean-blue);color:var(--ocean-blue);font-size:.85rem;font-weight:600;cursor:pointer;text-decoration:none;transition:var(--transition)}
.btn-logout:hover{background:var(--ocean-blue);color:#fff}

/* PAGE HERO */
.page-hero{background:linear-gradient(135deg,var(--ocean-dark) 0%,var(--ocean-blue) 60%,var(--ocean-mid) 100%);padding:2.5rem 2rem;color:#fff}
.page-hero-inner{max-width:1280px;margin:0 auto;display:flex;justify-content:space-between;align-items:center;flex-wrap:wrap;gap:1rem}
.page-hero h1{font-size:1.8rem;font-weight:700}
.page-hero p{font-size:.95rem;opacity:.85;margin-top:.3rem}
.btn-write-hero{display:inline-flex;align-items:center;gap:.5rem;padding:.65rem 1.4rem;border-radius:var(--radius-sm);background:#fff;color:var(--ocean-dark);font-weight:700;font-size:.9rem;text-decoration:none;transition:var(--transition);border:none;cursor:pointer}
.btn-write-hero:hover{background:var(--sand);transform:translateY(-1px)}

/* LAYOUT */
.page-body{max-width:1280px;margin:0 auto;padding:2rem}
.two-col{display:grid;grid-template-columns:1fr 400px;gap:2rem;align-items:start}

/* ALERTS */
.alert{padding:.9rem 1.2rem;border-radius:var(--radius-md);margin-bottom:1.5rem;display:flex;align-items:center;gap:.7rem;font-size:.92rem;font-weight:500}
.alert-success{background:#d4edda;color:#155724;border:1px solid #c3e6cb}
.alert-error{background:#f8d7da;color:#721c24;border:1px solid #f5c6cb}

/* STATS */
.stats-row{display:grid;grid-template-columns:repeat(4,1fr);gap:1rem;margin-bottom:2rem}
.stat-box{background:var(--white);border-radius:var(--radius-md);padding:1.1rem 1.2rem;box-shadow:var(--shadow-sm);display:flex;flex-direction:column;gap:.3rem;border-left:4px solid transparent}
.stat-box.all{border-color:var(--ocean-blue)}
.stat-box.approved{border-color:var(--success)}
.stat-box.pending{border-color:var(--warning)}
.stat-box.rejected{border-color:var(--danger)}
.stat-num{font-size:1.8rem;font-weight:800;color:var(--ocean-dark)}
.stat-lbl{font-size:.78rem;color:var(--gray-500);font-weight:600;text-transform:uppercase;letter-spacing:.04em}

/* FILTER BAR */
.filter-bar{display:flex;align-items:center;gap:.5rem;flex-wrap:wrap;margin-bottom:1.5rem}
.tab-btn{padding:.45rem 1.1rem;border-radius:30px;border:1.5px solid var(--gray-200);background:var(--white);color:var(--gray-500);font-size:.85rem;font-weight:600;cursor:pointer;transition:var(--transition)}
.tab-btn:hover{border-color:var(--ocean-blue);color:var(--ocean-blue)}
.tab-btn.active{background:var(--ocean-blue);color:#fff;border-color:var(--ocean-blue)}

/* REVIEW CARD */
.reviews-list{display:flex;flex-direction:column;gap:1.2rem}
.review-card{background:var(--white);border-radius:var(--radius-lg);box-shadow:var(--shadow-sm);padding:1.4rem 1.6rem;border:1.5px solid var(--gray-200);transition:var(--transition);position:relative}
.review-card:hover{box-shadow:var(--shadow-md);transform:translateY(-1px)}
.review-card.status-APPROVED{border-left:5px solid var(--success)}
.review-card.status-PENDING{border-left:5px solid var(--warning)}
.review-card.status-REJECTED{border-left:5px solid var(--danger);opacity:.82}

.review-head{display:flex;justify-content:space-between;align-items:flex-start;gap:1rem;margin-bottom:.9rem;flex-wrap:wrap}
.review-meta{display:flex;flex-direction:column;gap:.2rem}
.review-res{font-size:.8rem;color:var(--gray-500)}
.review-date{font-size:.78rem;color:var(--gray-500)}

/* BADGE */
.badge{display:inline-flex;align-items:center;gap:.3rem;padding:.28rem .8rem;border-radius:30px;font-size:.76rem;font-weight:700;text-transform:uppercase;letter-spacing:.04em;white-space:nowrap}
.badge-APPROVED{background:#d4edda;color:#155724}
.badge-PENDING{background:#fff3cd;color:#856404}
.badge-REJECTED{background:#f8d7da;color:#721c24}

/* STARS */
.stars-section{margin-bottom:.85rem}
.overall-row{display:flex;align-items:center;gap:.5rem;margin-bottom:.5rem}
.overall-score{font-size:1.25rem;font-weight:800;color:var(--ocean-dark)}
.stars{display:flex;gap:2px}
.stars i{font-size:.9rem}
.stars i.filled{color:#f0a500}
.stars i.empty{color:var(--gray-200)}
.overall-row .stars i{font-size:1.1rem}
.sub-row{display:flex;flex-wrap:wrap;gap:.5rem .8rem}
.sub-chip{display:inline-flex;align-items:center;gap:.25rem;font-size:.78rem;color:var(--gray-500);background:var(--gray-50);padding:.2rem .55rem;border-radius:20px;border:1px solid var(--gray-200)}
.sub-chip .stars i{font-size:.7rem}

/* COMMENT */
.review-comment{background:var(--gray-50);border-left:3px solid var(--ocean-mid);border-radius:0 var(--radius-sm) var(--radius-sm) 0;padding:.7rem 1rem;font-size:.9rem;color:var(--gray-700);line-height:1.55;margin-bottom:.85rem;font-style:italic}

/* MANAGEMENT RESPONSE */
.review-response{background:var(--ocean-light);border-radius:var(--radius-sm);padding:.7rem 1rem;font-size:.86rem;color:var(--ocean-dark);display:flex;gap:.5rem;align-items:flex-start;margin-bottom:.85rem}
.review-response i{margin-top:.15rem;flex-shrink:0;color:var(--ocean-blue)}
.response-label{font-weight:700;display:block;margin-bottom:.2rem;font-size:.8rem;text-transform:uppercase;letter-spacing:.03em;color:var(--ocean-blue)}

/* CARD FOOTER */
.review-footer{display:flex;justify-content:flex-end;gap:.6rem;padding-top:.8rem;border-top:1px solid var(--gray-100)}
.btn{display:inline-flex;align-items:center;gap:.4rem;padding:.4rem .95rem;border-radius:var(--radius-sm);font-size:.84rem;font-weight:600;cursor:pointer;border:none;text-decoration:none;transition:var(--transition)}
.btn-primary{background:var(--ocean-blue);color:#fff}
.btn-primary:hover{background:var(--ocean-dark)}
.btn-danger{background:transparent;color:var(--danger);border:1.5px solid var(--danger)}
.btn-danger:hover{background:var(--danger);color:#fff}
.btn-secondary{background:var(--gray-100);color:var(--gray-700);border:1.5px solid var(--gray-200)}
.btn-secondary:hover{background:var(--gray-200)}

/* EMPTY STATE */
.empty-state{text-align:center;padding:4rem 2rem;background:var(--white);border-radius:var(--radius-lg);box-shadow:var(--shadow-sm)}
.empty-icon{width:72px;height:72px;border-radius:50%;background:var(--ocean-light);display:flex;align-items:center;justify-content:center;margin:0 auto 1.2rem;font-size:1.8rem;color:var(--ocean-blue)}
.empty-state h2{color:var(--ocean-dark);margin-bottom:.5rem}
.empty-state p{color:var(--gray-500);margin-bottom:1.5rem;font-size:.95rem}

/* WRITE REVIEW PANEL */
.write-panel{background:var(--white);border-radius:var(--radius-lg);box-shadow:var(--shadow-sm);overflow:hidden;position:sticky;top:80px}
.write-panel-header{background:linear-gradient(135deg,var(--ocean-dark),var(--ocean-blue));padding:1.2rem 1.5rem;color:#fff;display:flex;align-items:flex-start;gap:.7rem}
.write-panel-header i{font-size:1.3rem;margin-top:.1rem}
.write-panel-header h2{font-size:1.05rem;font-weight:700}
.write-panel-header p{font-size:.82rem;opacity:.85;margin-top:.15rem}
.write-panel-body{padding:1.5rem}

/* FORM */
.form-group{margin-bottom:1.1rem}
.form-group label{display:block;font-size:.85rem;font-weight:600;color:var(--gray-700);margin-bottom:.35rem}
.form-group label .req{color:var(--danger);margin-left:2px}
.form-control{width:100%;padding:.55rem .85rem;border:1.5px solid var(--gray-200);border-radius:var(--radius-sm);font-size:.9rem;color:var(--gray-900);background:var(--white);transition:var(--transition);font-family:inherit}
.form-control:focus{outline:none;border-color:var(--ocean-blue);box-shadow:0 0 0 3px rgba(0,105,148,.12)}
textarea.form-control{resize:vertical;min-height:100px}
select.form-control{cursor:pointer;-webkit-appearance:none;appearance:none;background-image:url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='12' height='7' viewBox='0 0 12 7'%3E%3Cpath fill='%236c757d' d='M1 1l5 5 5-5'/%3E%3C/svg%3E");background-repeat:no-repeat;background-position:right .8rem center;padding-right:2.2rem}

/* INTERACTIVE STAR PICKER */
.star-picker{display:flex;gap:.2rem;flex-direction:row-reverse;justify-content:flex-end;margin-top:.3rem}
.star-picker input{display:none}
.star-picker label{font-size:1.6rem;color:var(--gray-200);cursor:pointer;line-height:1;transition:color .12s}
.star-picker input:checked ~ label,
.star-picker label:hover,
.star-picker label:hover ~ label{color:#f0a500}

.sub-ratings{display:grid;grid-template-columns:1fr 1fr;gap:.85rem;margin-top:.2rem}
.sub-rating-group label{font-size:.82rem;font-weight:600;color:var(--gray-700);display:block;margin-bottom:.2rem}
.mini-picker{display:flex;gap:.15rem;flex-direction:row-reverse;justify-content:flex-end}
.mini-picker input{display:none}
.mini-picker label{font-size:1.1rem;color:var(--gray-200);cursor:pointer;line-height:1;transition:color .12s}
.mini-picker input:checked ~ label,
.mini-picker label:hover,
.mini-picker label:hover ~ label{color:#f0a500}

.char-count{font-size:.76rem;color:var(--gray-500);text-align:right;margin-top:.2rem}
.btn-submit{width:100%;padding:.75rem;background:var(--ocean-blue);color:#fff;border:none;border-radius:var(--radius-sm);font-size:1rem;font-weight:700;cursor:pointer;transition:var(--transition);display:flex;align-items:center;justify-content:center;gap:.5rem;margin-top:.5rem}
.btn-submit:hover{background:var(--ocean-dark);transform:translateY(-1px)}
.btn-submit:disabled{opacity:.6;cursor:not-allowed;transform:none}
.no-reservations-note{background:var(--gray-50);border-radius:var(--radius-sm);padding:1.2rem;text-align:center;font-size:.88rem;color:var(--gray-500)}
.no-reservations-note a{color:var(--ocean-blue);text-decoration:none;font-weight:600}

/* MODAL */
.modal-overlay{display:none;position:fixed;inset:0;background:rgba(0,0,0,.5);z-index:500;align-items:center;justify-content:center}
.modal-overlay.open{display:flex}
.modal-box{background:#fff;border-radius:var(--radius-lg);padding:2rem;width:100%;max-width:400px;box-shadow:var(--shadow-lg);animation:popIn .2s ease}
@keyframes popIn{from{transform:scale(.92);opacity:0}to{transform:scale(1);opacity:1}}
.modal-box h3{font-size:1.1rem;color:var(--ocean-dark);margin-bottom:.5rem}
.modal-box p{font-size:.9rem;color:var(--gray-500);margin-bottom:1.4rem}
.modal-actions{display:flex;gap:.7rem;justify-content:flex-end}

/* TOAST */
.toast-container{position:fixed;bottom:1.5rem;right:1.5rem;z-index:600;display:flex;flex-direction:column;gap:.5rem}
.toast{padding:.8rem 1.2rem;border-radius:var(--radius-md);font-size:.88rem;font-weight:600;color:#fff;box-shadow:var(--shadow-md);animation:slideIn .3s ease;display:flex;align-items:center;gap:.6rem}
@keyframes slideIn{from{transform:translateX(100%);opacity:0}to{transform:translateX(0);opacity:1}}
.toast.success{background:var(--success)}
.toast.error{background:var(--danger)}

/* RESPONSIVE */
@media(max-width:900px){.two-col{grid-template-columns:1fr}.write-panel{position:static}.stats-row{grid-template-columns:repeat(2,1fr)}}
@media(max-width:600px){.nav-links{display:none}.page-body{padding:1rem}.sub-ratings{grid-template-columns:1fr}.stats-row{grid-template-columns:repeat(2,1fr)}.review-head{flex-direction:column}}
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
            <li><a href="<%= ctx %>/reservation">My Reservations</a></li>
            <li><a href="<%= ctx %>/review?action=myReviews" class="active">My Reviews</a></li>
            <li><a href="<%= ctx %>/guest/profile">Profile</a></li>
        </ul>
        <div class="nav-right">
            <div class="avatar"><%= initial %></div>
            <span style="font-size:.88rem;font-weight:600;color:var(--gray-700);"><%= currentUser.getFirstName() %></span>
            <a href="<%= ctx %>/logout" class="btn-logout"><i class="fas fa-sign-out-alt"></i> Logout</a>
        </div>
    </div>
</nav>

<!-- PAGE HERO -->
<div class="page-hero">
    <div class="page-hero-inner">
        <div>
            <h1><i class="fas fa-star"></i> My Reviews</h1>
            <p>Share your experience and help other guests choose the perfect stay</p>
        </div>
        <button class="btn-write-hero" onclick="scrollToForm()">
            <i class="fas fa-pen"></i> Write a Review
        </button>
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

    <!-- STATS -->
    <div class="stats-row">
        <div class="stat-box all">
            <span class="stat-num"><%= totalCount %></span>
            <span class="stat-lbl">Total</span>
        </div>
        <div class="stat-box approved">
            <span class="stat-num"><%= approvedCount %></span>
            <span class="stat-lbl">Approved</span>
        </div>
        <div class="stat-box pending">
            <span class="stat-num"><%= pendingCount %></span>
            <span class="stat-lbl">Pending</span>
        </div>
        <div class="stat-box rejected">
            <span class="stat-num"><%= rejectedCount %></span>
            <span class="stat-lbl">Rejected</span>
        </div>
    </div>

    <div class="two-col">

        <!-- ══════ LEFT: REVIEWS LIST ══════ -->
        <div>
            <!-- FILTER TABS -->
            <div class="filter-bar">
                <button class="tab-btn active" data-filter="all">All (<%= totalCount %>)</button>
                <button class="tab-btn" data-filter="APPROVED">Approved (<%= approvedCount %>)</button>
                <button class="tab-btn" data-filter="PENDING">Pending (<%= pendingCount %>)</button>
                <button class="tab-btn" data-filter="REJECTED">Rejected (<%= rejectedCount %>)</button>
            </div>

            <% if (myReviews == null || myReviews.isEmpty()) { %>
            <div class="empty-state">
                <div class="empty-icon"><i class="fas fa-star"></i></div>
                <h2>No Reviews Yet</h2>
                <p>You haven't written any reviews. Share your experience after a completed stay!</p>
                <a href="<%= ctx %>/reservation" class="btn btn-primary" style="font-size:1rem;padding:.7rem 1.8rem;">
                    <i class="fas fa-calendar-alt"></i> View My Reservations
                </a>
            </div>
            <% } else { %>
            <div class="reviews-list" id="reviewsList">
            <% for (Review r : myReviews) {
                String status   = r.getStatus().name();
                String resLabel = "Reservation #" + r.getReservationId();
                if (r.getReservation() != null && r.getReservation().getReservationNumber() != null) {
                    resLabel = r.getReservation().getReservationNumber();
                    if (r.getReservation().getRoom() != null && r.getReservation().getRoom().getRoomNumber() != null) {
                        String rt = r.getReservation().getRoom().getRoomType() != null
                                    ? r.getReservation().getRoom().getRoomType().name() : "Room";
                        String rtLabel = rt.charAt(0) + rt.substring(1).toLowerCase();
                        resLabel = rtLabel + " Room #" + r.getReservation().getRoom().getRoomNumber()
                                   + " &mdash; " + r.getReservation().getReservationNumber();
                    }
                }
                String dateStr = r.getCreatedAt() != null ? r.getCreatedAt().format(dtfFull) : "";
                int rating = r.getRating() != null ? r.getRating() : 0;
            %>
            <div class="review-card status-<%= status %>" data-status="<%= status %>">

                <!-- HEAD: reservation ref + badge -->
                <div class="review-head">
                    <div class="review-meta">
                        <span class="review-res"><i class="fas fa-bed"></i> <%= resLabel %></span>
                        <% if (!dateStr.isEmpty()) { %>
                        <span class="review-date"><i class="fas fa-clock"></i> <%= dateStr %></span>
                        <% } %>
                    </div>
                    <span class="badge badge-<%= status %>">
                        <% if ("APPROVED".equals(status)) { %><i class="fas fa-check-circle"></i>
                        <% } else if ("PENDING".equals(status)) { %><i class="fas fa-clock"></i>
                        <% } else { %><i class="fas fa-times-circle"></i><% } %>
                        <%= status.charAt(0) + status.substring(1).toLowerCase() %>
                    </span>
                </div>

                <!-- STAR RATINGS -->
                <div class="stars-section">
                    <div class="overall-row">
                        <span class="overall-score"><%= rating %>.0</span>
                        <div class="stars">
                            <% for (int s = 1; s <= 5; s++) { %>
                            <i class="fas fa-star <%= s <= rating ? "filled" : "empty" %>"></i>
                            <% } %>
                        </div>
                        <span style="font-size:.82rem;color:var(--gray-500);margin-left:.2rem;">Overall</span>
                    </div>
                    <% boolean hasSub = r.getCleanlinessRating() != null || r.getServiceRating() != null || r.getValueRating() != null; %>
                    <% if (hasSub) { %>
                    <div class="sub-row">
                        <% if (r.getCleanlinessRating() != null) { int cr = r.getCleanlinessRating(); %>
                        <span class="sub-chip">
                            <i class="fas fa-broom" style="color:var(--ocean-blue)"></i> Cleanliness
                            <div class="stars"><% for(int s=1;s<=5;s++){%><i class="fas fa-star <%= s<=cr?"filled":"empty" %>"></i><%}%></div>
                        </span>
                        <% } %>
                        <% if (r.getServiceRating() != null) { int sr = r.getServiceRating(); %>
                        <span class="sub-chip">
                            <i class="fas fa-concierge-bell" style="color:var(--ocean-blue)"></i> Service
                            <div class="stars"><% for(int s=1;s<=5;s++){%><i class="fas fa-star <%= s<=sr?"filled":"empty" %>"></i><%}%></div>
                        </span>
                        <% } %>
                        <% if (r.getValueRating() != null) { int vr = r.getValueRating(); %>
                        <span class="sub-chip">
                            <i class="fas fa-tag" style="color:var(--ocean-blue)"></i> Value
                            <div class="stars"><% for(int s=1;s<=5;s++){%><i class="fas fa-star <%= s<=vr?"filled":"empty" %>"></i><%}%></div>
                        </span>
                        <% } %>
                    </div>
                    <% } %>
                </div>

                <!-- COMMENT -->
                <% if (r.getComment() != null && !r.getComment().isBlank()) { %>
                <div class="review-comment">&ldquo;<%= r.getComment() %>&rdquo;</div>
                <% } %>

                <!-- MANAGEMENT RESPONSE -->
                <% if (r.hasResponse()) { %>
                <div class="review-response">
                    <i class="fas fa-reply"></i>
                    <div>
                        <span class="response-label">Management Response</span>
                        <%= r.getResponse() %>
                    </div>
                </div>
                <% } %>

                <!-- PENDING NOTE -->
                <% if ("PENDING".equals(status)) { %>
                <p style="font-size:.82rem;color:var(--warning);margin-bottom:.8rem;">
                    <i class="fas fa-info-circle"></i> Your review is awaiting moderation and will appear publicly once approved.
                </p>
                <% } %>
                <% if ("REJECTED".equals(status)) { %>
                <p style="font-size:.82rem;color:var(--danger);margin-bottom:.8rem;">
                    <i class="fas fa-exclamation-circle"></i> This review did not meet our community guidelines.
                </p>
                <% } %>

                <!-- FOOTER ACTIONS -->
                <div class="review-footer">
                    <% if ("PENDING".equals(status) || "REJECTED".equals(status)) { %>
                    <button class="btn btn-danger" onclick="openDeleteModal(<%= r.getReviewId() %>)">
                        <i class="fas fa-trash-alt"></i> Delete
                    </button>
                    <% } %>
                    <% if ("APPROVED".equals(status)) { %>
                    <span style="font-size:.8rem;color:var(--gray-500);display:flex;align-items:center;gap:.3rem;">
                        <i class="fas fa-globe"></i> Published
                    </span>
                    <% } %>
                </div>
            </div><!-- /review-card -->
            <% } %>
            </div><!-- /reviews-list -->
            <% } %>
        </div><!-- /left col -->

        <!-- ══════ RIGHT: WRITE REVIEW PANEL ══════ -->
        <div id="writeReviewPanel">
            <div class="write-panel">
                <div class="write-panel-header">
                    <i class="fas fa-pen-fancy"></i>
                    <div>
                        <h2>Write a Review</h2>
                        <p>Share your stay experience with future guests</p>
                    </div>
                </div>
                <div class="write-panel-body">
                <% if (eligibleRes == null || eligibleRes.isEmpty()) { %>
                    <div class="no-reservations-note">
                        <i class="fas fa-info-circle" style="font-size:1.4rem;color:var(--ocean-blue);margin-bottom:.6rem;display:block;"></i>
                        You don't have any completed stays eligible for a review yet.<br><br>
                        <a href="<%= ctx %>/rooms"><i class="fas fa-bed"></i> Browse Rooms</a> and make a booking!
                    </div>
                <% } else { %>
                    <form action="<%= ctx %>/review" method="post" id="reviewForm" onsubmit="return submitReview(event)">
                        <input type="hidden" name="action" value="create">
                        <input type="hidden" name="guestId" value="<%= currentUser.getUserId() %>">

                        <!-- Reservation selector -->
                        <div class="form-group">
                            <label for="reservationId">Reservation <span class="req">*</span></label>
                            <select name="reservationId" id="reservationId" class="form-control" required>
                                <option value="">— Select a completed stay —</option>
                                <% for (Reservation res : eligibleRes) {
                                    String resNum = res.getReservationNumber() != null
                                                    ? res.getReservationNumber() : "RES-" + res.getReservationId();
                                    String roomLabel = "";
                                    if (res.getRoom() != null) {
                                        String rt = res.getRoom().getRoomType() != null
                                                    ? res.getRoom().getRoomType().name() : "Room";
                                        roomLabel = " - " + rt.charAt(0) + rt.substring(1).toLowerCase()
                                                    + " #" + res.getRoom().getRoomNumber();
                                    }
                                    String checkOutStr = res.getCheckOutDate() != null
                                                        ? res.getCheckOutDate().format(dtf) : "";
                                    boolean isPreselected = preselectedResId != null
                                                            && preselectedResId.equals(String.valueOf(res.getReservationId()));
                                %>
                                <option value="<%= res.getReservationId() %>" <%= isPreselected ? "selected" : "" %>>
                                    <%= resNum %><%= roomLabel %><%= checkOutStr.isEmpty() ? "" : " (" + checkOutStr + ")" %>
                                </option>
                                <% } %>
                            </select>
                        </div>

                        <!-- Overall rating -->
                        <div class="form-group">
                            <label>Overall Rating <span class="req">*</span></label>
                            <div class="star-picker" id="overallStarPicker">
                                <input type="radio" name="rating" id="r5" value="5" required><label for="r5" title="Excellent"><i class="fas fa-star"></i></label>
                                <input type="radio" name="rating" id="r4" value="4"><label for="r4" title="Good"><i class="fas fa-star"></i></label>
                                <input type="radio" name="rating" id="r3" value="3"><label for="r3" title="Average"><i class="fas fa-star"></i></label>
                                <input type="radio" name="rating" id="r2" value="2"><label for="r2" title="Poor"><i class="fas fa-star"></i></label>
                                <input type="radio" name="rating" id="r1" value="1"><label for="r1" title="Terrible"><i class="fas fa-star"></i></label>
                            </div>
                            <div id="ratingLabel" style="font-size:.8rem;color:var(--ocean-blue);margin-top:.3rem;min-height:1.1em;"></div>
                        </div>

                        <!-- Sub-ratings -->
                        <div class="form-group">
                            <label>Category Ratings <span style="color:var(--gray-500);font-weight:400">(optional)</span></label>
                            <div class="sub-ratings">
                                <div class="sub-rating-group">
                                    <label><i class="fas fa-broom" style="color:var(--ocean-blue)"></i> Cleanliness</label>
                                    <div class="mini-picker">
                                        <input type="radio" name="cleanlinessRating" id="c5" value="5"><label for="c5"><i class="fas fa-star"></i></label>
                                        <input type="radio" name="cleanlinessRating" id="c4" value="4"><label for="c4"><i class="fas fa-star"></i></label>
                                        <input type="radio" name="cleanlinessRating" id="c3" value="3"><label for="c3"><i class="fas fa-star"></i></label>
                                        <input type="radio" name="cleanlinessRating" id="c2" value="2"><label for="c2"><i class="fas fa-star"></i></label>
                                        <input type="radio" name="cleanlinessRating" id="c1" value="1"><label for="c1"><i class="fas fa-star"></i></label>
                                    </div>
                                </div>
                                <div class="sub-rating-group">
                                    <label><i class="fas fa-concierge-bell" style="color:var(--ocean-blue)"></i> Service</label>
                                    <div class="mini-picker">
                                        <input type="radio" name="serviceRating" id="s5" value="5"><label for="s5"><i class="fas fa-star"></i></label>
                                        <input type="radio" name="serviceRating" id="s4" value="4"><label for="s4"><i class="fas fa-star"></i></label>
                                        <input type="radio" name="serviceRating" id="s3" value="3"><label for="s3"><i class="fas fa-star"></i></label>
                                        <input type="radio" name="serviceRating" id="s2" value="2"><label for="s2"><i class="fas fa-star"></i></label>
                                        <input type="radio" name="serviceRating" id="s1" value="1"><label for="s1"><i class="fas fa-star"></i></label>
                                    </div>
                                </div>
                                <div class="sub-rating-group">
                                    <label><i class="fas fa-tag" style="color:var(--ocean-blue)"></i> Value for Money</label>
                                    <div class="mini-picker">
                                        <input type="radio" name="valueRating" id="v5" value="5"><label for="v5"><i class="fas fa-star"></i></label>
                                        <input type="radio" name="valueRating" id="v4" value="4"><label for="v4"><i class="fas fa-star"></i></label>
                                        <input type="radio" name="valueRating" id="v3" value="3"><label for="v3"><i class="fas fa-star"></i></label>
                                        <input type="radio" name="valueRating" id="v2" value="2"><label for="v2"><i class="fas fa-star"></i></label>
                                        <input type="radio" name="valueRating" id="v1" value="1"><label for="v1"><i class="fas fa-star"></i></label>
                                    </div>
                                </div>
                                <div class="sub-rating-group">
                                    <label><i class="fas fa-wifi" style="color:var(--ocean-blue)"></i> Amenities</label>
                                    <div class="mini-picker">
                                        <input type="radio" name="amenitiesRating" id="a5" value="5"><label for="a5"><i class="fas fa-star"></i></label>
                                        <input type="radio" name="amenitiesRating" id="a4" value="4"><label for="a4"><i class="fas fa-star"></i></label>
                                        <input type="radio" name="amenitiesRating" id="a3" value="3"><label for="a3"><i class="fas fa-star"></i></label>
                                        <input type="radio" name="amenitiesRating" id="a2" value="2"><label for="a2"><i class="fas fa-star"></i></label>
                                        <input type="radio" name="amenitiesRating" id="a1" value="1"><label for="a1"><i class="fas fa-star"></i></label>
                                    </div>
                                </div>
                            </div>
                        </div>

                        <!-- Comment -->
                        <div class="form-group">
                            <label for="comment">Your Review <span class="req">*</span></label>
                            <textarea name="comment" id="comment" class="form-control" maxlength="1000"
                                      placeholder="Describe your stay — what did you love? What could be better?" required
                                      oninput="updateCharCount(this)"></textarea>
                            <div class="char-count" id="charCount">0 / 1000</div>
                        </div>

                        <button type="submit" class="btn-submit" id="submitBtn">
                            <i class="fas fa-paper-plane"></i> Submit Review
                        </button>
                        <p style="font-size:.77rem;color:var(--gray-500);text-align:center;margin-top:.6rem;">
                            <i class="fas fa-shield-alt"></i> Reviews are moderated before being published
                        </p>
                    </form>
                <% } %>
                </div>
            </div>
        </div><!-- /right col -->

    </div><!-- /two-col -->
</div><!-- /page-body -->

<!-- DELETE MODAL -->
<div class="modal-overlay" id="deleteModal">
    <div class="modal-box">
        <h3><i class="fas fa-trash-alt" style="color:var(--danger);margin-right:.4rem;"></i>Delete Review</h3>
        <p>Are you sure you want to delete this review? This action cannot be undone.</p>
        <div class="modal-actions">
            <button class="btn btn-secondary" onclick="closeDeleteModal()"><i class="fas fa-arrow-left"></i> Keep It</button>
            <button class="btn btn-danger" id="confirmDeleteBtn" onclick="doDelete()"><i class="fas fa-trash-alt"></i> Delete</button>
        </div>
    </div>
</div>

<!-- TOAST CONTAINER -->
<div class="toast-container" id="toastContainer"></div>

<script>
const CTX = '<%= ctx %>';
const LABELS = ['','Terrible','Poor','Average','Good','Excellent'];
let deleteTargetId = null;

/* ─── FILTER TABS ─── */
document.querySelectorAll('.tab-btn').forEach(btn => {
    btn.addEventListener('click', function() {
        document.querySelectorAll('.tab-btn').forEach(b => b.classList.remove('active'));
        this.classList.add('active');
        const filter = this.dataset.filter;
        document.querySelectorAll('.review-card').forEach(card => {
            card.style.display = (filter === 'all' || card.dataset.status === filter) ? 'block' : 'none';
        });
        // show/hide empty message
        const list = document.getElementById('reviewsList');
        if (!list) return;
        const visible = [...list.querySelectorAll('.review-card')].filter(c => c.style.display !== 'none');
        let msg = document.getElementById('filterEmpty');
        if (visible.length === 0) {
            if (!msg) {
                msg = document.createElement('div');
                msg.id = 'filterEmpty';
                msg.className = 'empty-state';
                msg.style.marginTop = '1rem';
                msg.innerHTML = '<div class="empty-icon"><i class="fas fa-filter"></i></div><h2>No Results</h2><p>No reviews match this filter.</p>';
                list.after(msg);
            }
        } else if (msg) { msg.remove(); }
    });
});

/* ─── OVERALL RATING LABEL ─── */
document.querySelectorAll('input[name="rating"]').forEach(radio => {
    radio.addEventListener('change', function() {
        const lbl = document.getElementById('ratingLabel');
        if (lbl) lbl.textContent = LABELS[parseInt(this.value)] || '';
    });
});

/* ─── CHAR COUNT ─── */
function updateCharCount(el) {
    const el2 = document.getElementById('charCount');
    if (el2) el2.textContent = el.value.length + ' / 1000';
}

/* ─── SCROLL TO FORM ─── */
function scrollToForm() {
    const panel = document.getElementById('writeReviewPanel');
    if (panel) panel.scrollIntoView({ behavior: 'smooth', block: 'start' });
}

/* ─── SUBMIT REVIEW ─── */
function submitReview(e) {
    const rating = document.querySelector('input[name="rating"]:checked');
    if (!rating) {
        e.preventDefault();
        showToast('Please select an overall rating.', 'error');
        return false;
    }
    const comment = document.getElementById('comment');
    if (!comment || comment.value.trim().length < 10) {
        e.preventDefault();
        showToast('Please write at least 10 characters in your review.', 'error');
        return false;
    }
    const btn = document.getElementById('submitBtn');
    if (btn) {
        btn.disabled = true;
        btn.innerHTML = '<i class="fas fa-spinner fa-spin"></i> Submitting...';
    }
    return true;
}

/* ─── DELETE MODAL ─── */
function openDeleteModal(reviewId) {
    deleteTargetId = reviewId;
    const btn = document.getElementById('confirmDeleteBtn');
    btn.disabled = false;
    btn.innerHTML = '<i class="fas fa-trash-alt"></i> Delete';
    document.getElementById('deleteModal').classList.add('open');
}

function closeDeleteModal() {
    document.getElementById('deleteModal').classList.remove('open');
    deleteTargetId = null;
}

document.getElementById('deleteModal').addEventListener('click', e => {
    if (e.target === document.getElementById('deleteModal')) closeDeleteModal();
});
document.addEventListener('keydown', e => { if (e.key === 'Escape') closeDeleteModal(); });

function doDelete() {
    if (!deleteTargetId) return;
    const btn = document.getElementById('confirmDeleteBtn');
    btn.disabled = true;
    btn.innerHTML = '<i class="fas fa-spinner fa-spin"></i> Deleting...';

    const form = document.createElement('form');
    form.method = 'POST';
    form.action = CTX + '/review';
    const addField = (n, v) => { const i = document.createElement('input'); i.type='hidden'; i.name=n; i.value=v; form.appendChild(i); };
    addField('action', 'delete');
    addField('id', deleteTargetId);
    document.body.appendChild(form);
    form.submit();
}

/* ─── TOAST ─── */
function showToast(msg, type) {
    const c = document.getElementById('toastContainer');
    const t = document.createElement('div');
    t.className = 'toast ' + type;
    t.innerHTML = '<i class="fas fa-' + (type==='success'?'check-circle':'exclamation-circle') + '"></i> ' + msg;
    c.appendChild(t);
    setTimeout(() => { t.style.opacity='0'; t.style.transition='.4s'; setTimeout(()=>t.remove(), 400); }, 4000);
}

/* ─── AUTO-DISMISS ALERTS ─── */
document.querySelectorAll('.alert').forEach(a => {
    setTimeout(() => { a.style.transition='.5s'; a.style.opacity='0'; setTimeout(()=>a.remove(),500); }, 4500);
});

/* ─── AUTO-SCROLL IF PRESELECTED ─── */
<% if (preselectedResId != null && !preselectedResId.isEmpty()) { %>
document.addEventListener('DOMContentLoaded', () => scrollToForm());
<% } %>
</script>

</body>
</html>
