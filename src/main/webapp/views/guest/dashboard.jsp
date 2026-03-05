<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="com.oceanview.model.User, com.oceanview.model.Reservation, com.oceanview.model.Review, com.oceanview.util.Constants, java.util.List, java.time.format.DateTimeFormatter" %>
<%
    User currentUser = (User) session.getAttribute(Constants.SESSION_USER);
    if (currentUser == null) currentUser = (User) session.getAttribute("loggedInUser");
    if (currentUser == null) { response.sendRedirect(request.getContextPath() + "/login"); return; }

    String ctx = request.getContextPath();
    String displayName = currentUser.getFirstName() != null && !currentUser.getFirstName().isEmpty()
                         ? currentUser.getFirstName() : currentUser.getUsername();

    // Safe attribute reads
    @SuppressWarnings("unchecked")
    List<Reservation> currentReservations = (List<Reservation>) request.getAttribute("currentReservations");
    @SuppressWarnings("unchecked")
    List<Review> recentReviews = (List<Review>) request.getAttribute("recentReviews");

    long upcomingCount  = 0L, completedCount = 0L, cancelledCount = 0L, availableOffers = 0L;
    Object upObj = request.getAttribute("upcomingReservations");
    Object cpObj = request.getAttribute("completedReservations");
    Object aoObj = request.getAttribute("availableOffers");
    Object caObj = request.getAttribute("cancelledReservations");
    if (upObj instanceof Number) upcomingCount  = ((Number)upObj).longValue();
    if (cpObj instanceof Number) completedCount = ((Number)cpObj).longValue();
    if (aoObj instanceof Number) availableOffers= ((Number)aoObj).longValue();
    if (caObj instanceof Number) cancelledCount = ((Number)caObj).longValue();

    DateTimeFormatter dtf = DateTimeFormatter.ofPattern("dd MMM yyyy");

    String flashOk  = (String) session.getAttribute(Constants.ATTR_SUCCESS);
    String flashErr = (String) session.getAttribute(Constants.ATTR_ERROR);
    session.removeAttribute(Constants.ATTR_SUCCESS);
    session.removeAttribute(Constants.ATTR_ERROR);
%>
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>My Dashboard - Ocean View Resort</title>
<link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
<style>
:root{--pri:#006994;--pri-dk:#004f70;--acc:#4A90A4;--ok:#28a745;--er:#dc3545;--warn:#f0a500;--gold:#D4AF37;--g50:#f8f9fa;--g100:#f1f3f5;--g200:#e9ecef;--g300:#dee2e6;--g500:#6c757d;--g700:#495057;--g800:#343a40;--sh1:0 2px 8px rgba(0,0,0,.08);--sh2:0 6px 20px rgba(0,0,0,.12);--r:.75rem;--r2:.4rem;--tr:.22s ease}
*,*::before,*::after{box-sizing:border-box;margin:0;padding:0}
body{font-family:'Segoe UI',system-ui,sans-serif;background:#eef2f7;color:var(--g800);min-height:100vh}
a{text-decoration:none;color:inherit}
.navbar{background:#fff;box-shadow:var(--sh1);position:sticky;top:0;z-index:200}
.nav-in{max-width:1280px;margin:0 auto;padding:0 2rem;height:64px;display:flex;align-items:center;justify-content:space-between}
.brand{display:flex;align-items:center;gap:.6rem}
.brand-icon{width:36px;height:36px;border-radius:8px;background:linear-gradient(135deg,var(--pri),#003d5c);display:flex;align-items:center;justify-content:center;color:#fff;font-size:1rem}
.brand-name{font-size:1.1rem;font-weight:700;color:#003d5c}
.nav-links{display:flex;gap:1.8rem;list-style:none}
.nav-links a{color:var(--g500);font-size:.9rem;font-weight:500;padding:.3rem 0;border-bottom:2px solid transparent;transition:var(--tr)}
.nav-links a:hover,.nav-links a.active{color:var(--pri);border-bottom-color:var(--pri)}
.nav-right{display:flex;align-items:center;gap:.75rem}
.avatar{width:36px;height:36px;border-radius:50%;background:linear-gradient(135deg,var(--pri),var(--acc));color:#fff;font-weight:700;font-size:.9rem;display:flex;align-items:center;justify-content:center;flex-shrink:0}
.btn-logout{padding:.4rem 1rem;border-radius:var(--r2);background:transparent;border:1.5px solid var(--pri);color:var(--pri);font-size:.85rem;font-weight:600;cursor:pointer;transition:var(--tr)}
.btn-logout:hover{background:var(--pri);color:#fff}
.page-hero{background:linear-gradient(135deg,#003d5c 0%,var(--pri) 60%,var(--acc) 100%);padding:2.5rem 2rem;color:#fff}
.ph-in{max-width:1280px;margin:0 auto;display:flex;justify-content:space-between;align-items:center;flex-wrap:wrap;gap:1rem}
.ph-in h1{font-size:1.8rem;font-weight:700}
.ph-in p{font-size:.95rem;opacity:.85;margin-top:.3rem}
.btn-new{display:inline-flex;align-items:center;gap:.5rem;padding:.65rem 1.4rem;border-radius:var(--r2);background:#fff;color:#003d5c;font-weight:700;font-size:.9rem;transition:var(--tr)}
.btn-new:hover{background:var(--gold);transform:translateY(-1px)}
.body-wrap{max-width:1280px;margin:0 auto;padding:2rem}
.alert{padding:.9rem 1.2rem;border-radius:var(--r);margin-bottom:1.5rem;display:flex;align-items:center;gap:.7rem;font-size:.92rem;font-weight:500}
.alert-ok{background:#d4edda;color:#155724;border:1px solid #c3e6cb}
.alert-er{background:#f8d7da;color:#721c24;border:1px solid #f5c6cb}
.stats-grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(200px,1fr));gap:1rem;margin-bottom:2rem}
.stat-card{background:#fff;border-radius:var(--r);box-shadow:var(--sh1);padding:1.25rem 1.4rem;display:flex;align-items:center;gap:1rem;transition:var(--tr)}
.stat-card:hover{box-shadow:var(--sh2);transform:translateY(-2px)}
.stat-icon{width:52px;height:52px;border-radius:var(--r);display:flex;align-items:center;justify-content:center;font-size:1.3rem;color:#fff;flex-shrink:0}
.stat-num{font-size:1.9rem;font-weight:800;color:#003d5c;line-height:1}
.stat-lbl{font-size:.78rem;color:var(--g500);font-weight:600;text-transform:uppercase;letter-spacing:.04em;margin-top:.25rem}
.dash-grid{display:grid;grid-template-columns:1fr 340px;gap:1.5rem;margin-bottom:1.5rem}
@media(max-width:1000px){.dash-grid{grid-template-columns:1fr}}
.card{background:#fff;border-radius:var(--r);box-shadow:var(--sh1);overflow:hidden}
.card-hdr{padding:1rem 1.4rem;border-bottom:1px solid var(--g200);display:flex;justify-content:space-between;align-items:center}
.card-hdr h2{font-size:1rem;font-weight:700;color:var(--g800);display:flex;align-items:center;gap:.5rem}
.card-hdr h2 i{color:var(--pri)}
.btn-sm{padding:.35rem .9rem;border-radius:var(--r2);background:var(--g100);color:var(--g700);border:1.5px solid var(--g200);font-size:.8rem;font-weight:600;cursor:pointer;transition:var(--tr)}
.btn-sm:hover{background:var(--pri);color:#fff;border-color:var(--pri)}
.card-body{padding:1.2rem 1.4rem}
.res-item{display:flex;gap:1rem;padding:.9rem 0;border-bottom:1px solid var(--g100);align-items:flex-start}
.res-item:last-child{border-bottom:none}
.res-thumb{width:64px;height:64px;border-radius:var(--r2);object-fit:cover;flex-shrink:0;background:linear-gradient(135deg,var(--pri),var(--acc))}
.res-thumb-ph{width:64px;height:64px;border-radius:var(--r2);background:linear-gradient(135deg,var(--pri),var(--acc));display:flex;align-items:center;justify-content:center;color:#fff;font-size:1.4rem;flex-shrink:0}
.res-info{flex:1;min-width:0}
.res-title{font-size:.9rem;font-weight:700;color:#003d5c;margin-bottom:.25rem;white-space:nowrap;overflow:hidden;text-overflow:ellipsis}
.res-meta-row{display:flex;gap:1rem;flex-wrap:wrap;font-size:.78rem;color:var(--g500);margin-bottom:.4rem}
.res-meta-row i{color:var(--pri);width:12px}
.res-price{font-size:.88rem;font-weight:700;color:var(--pri)}
.res-badges{display:flex;gap:.4rem;flex-wrap:wrap;margin-top:.35rem}
.badge{display:inline-flex;align-items:center;padding:.18rem .6rem;border-radius:1rem;font-size:.7rem;font-weight:700;text-transform:uppercase}
.b-PENDING{background:#fff3cd;color:#856404}
.b-CONFIRMED{background:#d1ecf1;color:#0c5460}
.b-CHECKED_IN{background:#d4edda;color:#155724}
.b-CHECKED_OUT{background:#e2d9f3;color:#432874}
.b-CANCELLED{background:#f8d7da;color:#721c24}
.b-APPROVED{background:#d4edda;color:#155724}
.b-REJECTED{background:#f8d7da;color:#721c24}
.res-actions{display:flex;gap:.4rem;margin-top:.5rem;flex-wrap:wrap}
.btn-act{padding:.28rem .7rem;font-size:.75rem;border-radius:var(--r2);cursor:pointer;border:none;font-weight:600;transition:var(--tr)}
.btn-pri{background:var(--pri);color:#fff}.btn-pri:hover{background:var(--pri-dk)}
.btn-er{background:transparent;color:var(--er);border:1.5px solid var(--er)}.btn-er:hover{background:var(--er);color:#fff}
.empty-s{text-align:center;padding:2.5rem 1rem;color:var(--g500)}
.empty-s i{font-size:2.5rem;color:var(--g200);margin-bottom:.75rem;display:block}
.empty-s p{font-size:.88rem;margin-bottom:.75rem}
.qa-grid{display:flex;flex-direction:column;gap:.5rem}
.qa-item{display:flex;align-items:center;gap:.75rem;padding:.75rem 1rem;border-radius:var(--r2);background:var(--g50);border:1px solid var(--g100);transition:var(--tr)}
.qa-item:hover{background:var(--pri);color:#fff;border-color:var(--pri)}
.qa-item:hover .qa-icon,.qa-item:hover .qa-arrow{color:#fff}
.qa-icon{width:36px;height:36px;border-radius:var(--r2);background:var(--pri);color:#fff;display:flex;align-items:center;justify-content:center;font-size:.95rem;flex-shrink:0;transition:var(--tr)}
.qa-item:hover .qa-icon{background:rgba(255,255,255,.2)}
.qa-text h4{font-size:.88rem;font-weight:700;margin-bottom:.1rem}
.qa-text p{font-size:.76rem;color:var(--g500);transition:var(--tr)}
.qa-item:hover .qa-text p{color:rgba(255,255,255,.8)}
.qa-arrow{margin-left:auto;color:var(--g300);font-size:.8rem;transition:var(--tr)}
.rev-item{padding:.9rem 0;border-bottom:1px solid var(--g100)}
.rev-item:last-child{border-bottom:none}
.rev-stars{color:var(--gold);font-size:.8rem;margin-bottom:.3rem}
.rev-comment{font-size:.85rem;color:var(--g700);margin-bottom:.3rem;display:-webkit-box;-webkit-line-clamp:2;-webkit-box-orient:vertical;overflow:hidden}
.rev-footer{display:flex;justify-content:space-between;align-items:center;font-size:.75rem;color:var(--g500)}
.toast-c{position:fixed;bottom:1.5rem;right:1.5rem;z-index:600;display:flex;flex-direction:column;gap:.5rem}
.toast{padding:.8rem 1.2rem;border-radius:var(--r);font-size:.88rem;font-weight:600;color:#fff;box-shadow:var(--sh2);animation:tIn .3s ease;display:flex;align-items:center;gap:.6rem}
.toast.ok{background:var(--ok)}.toast.er{background:var(--er)}
@keyframes tIn{from{transform:translateX(100%);opacity:0}to{transform:translateX(0);opacity:1}}
@media(max-width:768px){.nav-links{display:none}.body-wrap{padding:1rem}.stats-grid{grid-template-columns:1fr 1fr}}
@media(max-width:480px){.stats-grid{grid-template-columns:1fr}}
</style>
</head>
<body>
<!-- NAVBAR -->
<nav class="navbar">
  <div class="nav-in">
    <a href="<%= ctx %>/guest/home" class="brand">
      <div class="brand-icon"><i class="fas fa-hotel"></i></div>
      <span class="brand-name">Ocean View Resort</span>
    </a>
    <ul class="nav-links">
      <li><a href="<%= ctx %>/guest/home">Home</a></li>
      <li><a href="<%= ctx %>/rooms">Browse Rooms</a></li>
      <li><a href="<%= ctx %>/reservation" >My Reservations</a></li>
      <li><a href="<%= ctx %>/review">My Reviews</a></li>
      <li><a href="<%= ctx %>/guest/profile">Profile</a></li>
    </ul>
    <div class="nav-right">
      <div class="avatar"><%= (currentUser.getFullName()!=null&&!currentUser.getFullName().isEmpty())?currentUser.getFullName().substring(0,1).toUpperCase():"G" %></div>
      <span style="font-size:.88rem;font-weight:600;color:var(--g700)"><%= displayName %></span>
      <a href="<%= ctx %>/logout" class="btn-logout"><i class="fas fa-sign-out-alt"></i> Logout</a>
    </div>
  </div>
</nav>

<!-- HERO -->
<div class="page-hero">
  <div class="ph-in">
    <div>
      <h1><i class="fas fa-tachometer-alt"></i> Welcome back, <%= displayName %>!</h1>
      <p>Manage your reservations and explore our services</p>
    </div>
    <a href="<%= ctx %>/rooms" class="btn-new"><i class="fas fa-plus"></i> New Booking</a>
  </div>
</div>

<!-- BODY -->
<div class="body-wrap">

<!-- FLASH MESSAGES -->
<% if (flashOk != null) { %><div class="alert alert-ok"><i class="fas fa-check-circle"></i> <%= flashOk %></div><% } %>
<% if (flashErr != null) { %><div class="alert alert-er"><i class="fas fa-exclamation-circle"></i> <%= flashErr %></div><% } %>

<!-- STATS -->
<div class="stats-grid">
  <div class="stat-card">
    <div class="stat-icon" style="background:linear-gradient(135deg,var(--pri),var(--acc))"><i class="fas fa-calendar-check"></i></div>
    <div><div class="stat-num"><%= upcomingCount %></div><div class="stat-lbl">Upcoming</div></div>
  </div>
  <div class="stat-card">
    <div class="stat-icon" style="background:linear-gradient(135deg,#28A745,#20c997)"><i class="fas fa-check-circle"></i></div>
    <div><div class="stat-num"><%= completedCount %></div><div class="stat-lbl">Completed Stays</div></div>
  </div>
  <div class="stat-card">
    <div class="stat-icon" style="background:linear-gradient(135deg,var(--er),#c0392b)"><i class="fas fa-times-circle"></i></div>
    <div><div class="stat-num"><%= cancelledCount %></div><div class="stat-lbl">Cancelled</div></div>
  </div>
  <div class="stat-card">
    <div class="stat-icon" style="background:linear-gradient(135deg,#FF6B6B,#ee5a6f)"><i class="fas fa-tags"></i></div>
    <div><div class="stat-num"><%= availableOffers %></div><div class="stat-lbl">Special Offers</div></div>
  </div>
</div>

<!-- MAIN GRID -->
<div class="dash-grid">

  <!-- CURRENT RESERVATIONS -->
  <div class="card">
    <div class="card-hdr">
      <h2><i class="fas fa-calendar-alt"></i> Current Reservations</h2>
      <a href="<%= ctx %>/reservation" class="btn-sm">View All</a>
    </div>
    <div class="card-body">
    <% if (currentReservations == null || currentReservations.isEmpty()) { %>
      <div class="empty-s">
        <i class="fas fa-calendar-times"></i>
        <p>No active reservations yet.</p>
        <a href="<%= ctx %>/rooms" class="btn-act btn-pri"><i class="fas fa-bed"></i> Browse Rooms</a>
      </div>
    <% } else {
         int shown = 0;
         for (Reservation r : currentReservations) {
           if (shown >= 3) break;
           shown++;
           String rStatus = r.getStatus() != null ? r.getStatus().name() : "PENDING";
           String rType   = (r.getRoom()!=null&&r.getRoom().getRoomType()!=null) ? r.getRoom().getRoomType().name() : "ROOM";
           String rNum    = (r.getRoom()!=null&&r.getRoom().getRoomNumber()!=null) ? r.getRoom().getRoomNumber() : "";
           String rCI     = r.getCheckInDate()  != null ? r.getCheckInDate().format(dtf)  : "—";
           String rCO     = r.getCheckOutDate() != null ? r.getCheckOutDate().format(dtf) : "—";
           int rNights    = r.getNumberOfNights()!=null&&r.getNumberOfNights()>0 ? r.getNumberOfNights() : 0;
           String rAmt    = r.getFinalAmount()!=null ? String.format("Rs. %,.0f", r.getFinalAmount().doubleValue()) : "—";
           int rId        = r.getReservationId()!=null ? r.getReservationId() : 0;
           String rResNum = r.getReservationNumber()!=null ? r.getReservationNumber() : "RES-"+rId;
           String imgSrc  = ctx + "/assets/images/rooms/" + rType.toLowerCase() + ".jpg";
    %>
      <div class="res-item">
        <img class="res-thumb" src="<%= imgSrc %>" alt="<%= rType %>"
             onerror="this.style.display='none';this.nextElementSibling.style.display='flex'">
        <div class="res-thumb-ph" style="display:none"><i class="fas fa-bed"></i></div>
        <div class="res-info">
          <div class="res-title"><%= rType.charAt(0)+rType.substring(1).toLowerCase() %> Room &mdash; #<%= rNum %></div>
          <div class="res-meta-row">
            <span><i class="fas fa-sign-in-alt"></i> <%= rCI %></span>
            <span><i class="fas fa-sign-out-alt"></i> <%= rCO %></span>
            <span><i class="fas fa-moon"></i> <%= rNights %> night<%= rNights!=1?"s":"" %></span>
          </div>
          <div class="res-price"><%= rAmt %></div>
          <div class="res-badges">
            <span class="badge b-<%= rStatus %>"><%= rStatus.replace("_"," ") %></span>
          </div>
          <div class="res-actions">
            <a href="<%= ctx %>/reservation?action=view&id=<%= rId %>" class="btn-act btn-pri"><i class="fas fa-eye"></i> View</a>
            <% if ("PENDING".equals(rStatus)||"CONFIRMED".equals(rStatus)) { %>
            <button class="btn-act btn-er" onclick="cancelRes(<%= rId %>,'<%= rResNum %>')"><i class="fas fa-times"></i> Cancel</button>
            <% } %>
          </div>
        </div>
      </div>
    <% } } %>
    </div>
  </div>

  <!-- QUICK ACTIONS -->
  <div class="card">
    <div class="card-hdr"><h2><i class="fas fa-bolt"></i> Quick Actions</h2></div>
    <div class="card-body">
      <div class="qa-grid">
        <a href="<%= ctx %>/rooms" class="qa-item">
          <div class="qa-icon"><i class="fas fa-bed"></i></div>
          <div class="qa-text"><h4>Book a Room</h4><p>Find your perfect stay</p></div>
          <i class="fas fa-chevron-right qa-arrow"></i>
        </a>
        <a href="<%= ctx %>/reservation" class="qa-item">
          <div class="qa-icon"><i class="fas fa-list"></i></div>
          <div class="qa-text"><h4>My Reservations</h4><p>View all bookings</p></div>
          <i class="fas fa-chevron-right qa-arrow"></i>
        </a>
        <a href="<%= ctx %>/review" class="qa-item">
          <div class="qa-icon"><i class="fas fa-star"></i></div>
          <div class="qa-text"><h4>Write a Review</h4><p>Share your experience</p></div>
          <i class="fas fa-chevron-right qa-arrow"></i>
        </a>
        <a href="<%= ctx %>/guest/profile" class="qa-item">
          <div class="qa-icon"><i class="fas fa-user-edit"></i></div>
          <div class="qa-text"><h4>Update Profile</h4><p>Manage your account</p></div>
          <i class="fas fa-chevron-right qa-arrow"></i>
        </a>
        <a href="<%= ctx %>/offer" class="qa-item">
          <div class="qa-icon" style="background:#FF6B6B"><i class="fas fa-gift"></i></div>
          <div class="qa-text"><h4>Special Offers</h4><p>Exclusive deals for you</p></div>
          <i class="fas fa-chevron-right qa-arrow"></i>
        </a>
      </div>
    </div>
  </div>
</div><!-- /dash-grid -->

<!-- RECENT REVIEWS -->
<div class="card" style="margin-bottom:2rem">
  <div class="card-hdr">
    <h2><i class="fas fa-comment-dots"></i> Recent Reviews</h2>
    <a href="<%= ctx %>/review" class="btn-sm">View All</a>
  </div>
  <div class="card-body">
  <% if (recentReviews == null || recentReviews.isEmpty()) { %>
    <div class="empty-s">
      <i class="fas fa-star"></i>
      <p>You haven't written any reviews yet.</p>
      <a href="<%= ctx %>/review" class="btn-act btn-pri"><i class="fas fa-star"></i> Write a Review</a>
    </div>
  <% } else {
       int rShown = 0;
       for (Review rv : recentReviews) {
         if (rShown >= 3) break; rShown++;
         int rating = rv.getRating() != null ? rv.getRating() : 0;
         String rvStatus = rv.getStatus() != null ? rv.getStatus().name() : "PENDING";
         String rvComment = rv.getComment() != null ? rv.getComment() : "";
         String rvDate = rv.getCreatedAt() != null ? rv.getCreatedAt().toLocalDate().format(dtf) : "";
  %>
    <div class="rev-item">
      <div class="rev-stars">
        <% for (int s=1;s<=5;s++) { %><i class="<%= s<=rating?"fas":"far" %> fa-star"></i><% } %>
        <span style="font-size:.75rem;color:var(--g500);margin-left:.4rem">(<%= rating %>/5)</span>
      </div>
      <div class="rev-comment"><%= rvComment.length()>150 ? rvComment.substring(0,150)+"…" : rvComment %></div>
      <div class="rev-footer">
        <span class="badge b-<%= rvStatus %>"><%= rvStatus %></span>
        <span><%= rvDate %></span>
      </div>
    </div>
  <% } } %>
  </div>
</div>

</div><!-- /body-wrap -->

<!-- CANCEL MODAL -->
<div id="cancelModal" style="display:none;position:fixed;inset:0;background:rgba(0,0,0,.5);z-index:500;align-items:center;justify-content:center">
  <div style="background:#fff;border-radius:.75rem;padding:2rem;max-width:420px;width:100%;box-shadow:0 8px 24px rgba(0,0,0,.15)">
    <h3 style="margin-bottom:.5rem;color:#003d5c"><i class="fas fa-exclamation-triangle" style="color:var(--er)"></i> Cancel Reservation</h3>
    <p id="cancelTxt" style="color:var(--g500);font-size:.9rem;margin-bottom:1.25rem">Are you sure you want to cancel this reservation?</p>
    <div style="display:flex;gap:.75rem;justify-content:flex-end">
      <button onclick="document.getElementById('cancelModal').style.display='none'" style="padding:.5rem 1rem;border-radius:.4rem;background:var(--g100);border:1.5px solid var(--g200);cursor:pointer;font-weight:600">Keep It</button>
      <button id="cancelConfirmBtn" onclick="doCancel()" style="padding:.5rem 1rem;border-radius:.4rem;background:var(--er);color:#fff;border:none;cursor:pointer;font-weight:600"><i class="fas fa-times-circle"></i> Yes, Cancel</button>
    </div>
  </div>
</div>

<div class="toast-c" id="toastC"></div>

<script>
var ctx = '<%= ctx %>';
var cancelId = null;

function cancelRes(id, resNum) {
    cancelId = id;
    document.getElementById('cancelTxt').textContent = 'Cancel reservation ' + resNum + '? This cannot be undone.';
    var m = document.getElementById('cancelModal');
    m.style.display = 'flex';
}

function doCancel() {
    if (!cancelId) return;
    var btn = document.getElementById('cancelConfirmBtn');
    btn.disabled = true; btn.innerHTML = '<i class="fas fa-spinner fa-spin"></i>';
    var fd = new FormData(); fd.append('action','cancel'); fd.append('id', cancelId);
    fetch(ctx + '/reservation', {method:'POST', body:fd})
        .then(function(r){ return r.json(); })
        .then(function(d){
            document.getElementById('cancelModal').style.display = 'none';
            if (d.success) { showToast('Reservation cancelled.','ok'); setTimeout(function(){ location.reload(); },1300); }
            else { showToast(d.message||'Could not cancel.','er'); btn.disabled=false; btn.innerHTML='<i class="fas fa-times-circle"></i> Yes, Cancel'; }
        })
        .catch(function(){ document.getElementById('cancelModal').style.display='none'; showToast('Network error. Please try again.','er'); btn.disabled=false; btn.innerHTML='<i class="fas fa-times-circle"></i> Yes, Cancel'; });
}

function showToast(msg, type) {
    var c = document.getElementById('toastC');
    var t = document.createElement('div');
    t.className = 'toast ' + type;
    t.innerHTML = '<i class="fas fa-' + (type==='ok'?'check-circle':'exclamation-circle') + '"></i> ' + msg;
    c.appendChild(t);
    setTimeout(function(){ t.style.opacity='0'; t.style.transition='.4s'; setTimeout(function(){ t.remove(); },400); }, 4000);
}

// Auto-dismiss flash alerts
document.querySelectorAll('.alert').forEach(function(a){
    setTimeout(function(){ a.style.transition='.5s'; a.style.opacity='0'; setTimeout(function(){ a.remove(); },500); }, 5000);
});
</script>
</body>
</html>
