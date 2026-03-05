<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="com.oceanview.model.User, com.oceanview.model.Room, com.oceanview.util.Constants, java.util.List, java.time.LocalDate, java.time.format.DateTimeFormatter, java.time.temporal.ChronoUnit" %>
<%!
    private String esc(String s){ if(s==null)return ""; return s.replace("&","&amp;").replace("<","&lt;").replace(">","&gt;").replace("\"","&quot;"); }
    private String roomLabel(String type){
        if(type==null)return "Room";
        switch(type){
            case "SINGLE": return "Standard Single Room";
            case "DOUBLE": return "Double Room";
            case "DELUXE": return "Deluxe Room";
            case "SUITE":  return "Luxury Suite";
            case "FAMILY": return "Family Room";
            default: return type.charAt(0)+type.substring(1).toLowerCase()+" Room";
        }
    }
    private String roomDesc(String type){
        if(type==null)return "Beautifully appointed room with modern amenities.";
        switch(type){
            case "SINGLE": return "Comfortable single room with modern amenities, perfect for solo travelers.";
            case "DOUBLE": return "Spacious double room ideal for couples, featuring a king-size bed and ocean views.";
            case "DELUXE": return "Deluxe room with premium furnishings, private balcony and stunning ocean panorama.";
            case "SUITE":  return "Luxurious suite with separate living area, jacuzzi and butler service.";
            case "FAMILY": return "Spacious family room with multiple beds and family-friendly amenities.";
            default: return "Beautifully appointed room with modern amenities and stunning resort views.";
        }
    }
    private String typeTagClass(String type){
        if(type==null)return "type-single";
        switch(type){
            case "DOUBLE": return "type-double";
            case "DELUXE": return "type-deluxe";
            case "SUITE":  return "type-suite";
            case "FAMILY": return "type-family";
            default: return "type-single";
        }
    }
%>
<%
    User currentUser = (User) session.getAttribute(Constants.SESSION_USER);
    if(currentUser==null) currentUser=(User)session.getAttribute("loggedInUser");
    if(currentUser==null){ response.sendRedirect(request.getContextPath()+"/login"); return; }

    String ctx = request.getContextPath();
    String navRole  = currentUser.getRole()!=null ? currentUser.getRole().toString() : "GUEST";
    String navFirst = currentUser.getFirstName()!=null&&!currentUser.getFirstName().isEmpty()
                      ? currentUser.getFirstName() : currentUser.getUsername();
    String navInit  = (navFirst!=null&&!navFirst.isEmpty()) ? String.valueOf(navFirst.charAt(0)).toUpperCase() : "?";

    LocalDate checkInDate  = (LocalDate) request.getAttribute("checkIn");
    LocalDate checkOutDate = (LocalDate) request.getAttribute("checkOut");
    DateTimeFormatter dtf  = DateTimeFormatter.ofPattern("dd MMM yyyy");
    String checkInStr  = checkInDate  != null ? checkInDate.toString()  : "";
    String checkOutStr = checkOutDate != null ? checkOutDate.toString() : "";
    String checkInDisp  = checkInDate  != null ? checkInDate.format(dtf)  : null;
    String checkOutDisp = checkOutDate != null ? checkOutDate.format(dtf) : null;
    long numNights = (checkInDate!=null&&checkOutDate!=null)
                     ? ChronoUnit.DAYS.between(checkInDate,checkOutDate) : 0;

    @SuppressWarnings("unchecked")
    List<Room> rooms = (List<Room>) request.getAttribute("rooms");
    if(rooms==null) rooms = new java.util.ArrayList<>();

    String selType   = request.getParameter("roomType") != null ? request.getParameter("roomType") : "";
    if(selType==null||selType.isEmpty()) {
        Object st = request.getAttribute("selectedType");
        selType = st!=null ? st.toString() : "";
    }
    String selGuests = request.getParameter("guests") != null ? request.getParameter("guests") : "2";

    // Flash messages
    String flashOk  = (String) session.getAttribute(Constants.ATTR_SUCCESS);
    String flashErr = (String) session.getAttribute(Constants.ATTR_ERROR);
    session.removeAttribute(Constants.ATTR_SUCCESS);
    session.removeAttribute(Constants.ATTR_ERROR);
    if(flashOk==null) flashOk=(String)request.getAttribute(Constants.ATTR_SUCCESS);
    if(flashErr==null) flashErr=(String)request.getAttribute(Constants.ATTR_ERROR);
%>
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1.0">
<title>Rooms &amp; Suites - Ocean View Resort</title>
<link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
<style>
:root{
  --od:#0D3F52;--ob:#1A6B8A;--ol:#E8F4F8;--gold:#D4AF37;--gl:#F5E98A;
  --coral:#E07B5A;--sand:#F5ECD7;--wh:#fff;--off:#F9FAFB;
  --td:#1A2332;--tm:#4A5568;--tl:#718096;--bd:#E2E8F0;
  --ss:0 1px 3px rgba(0,0,0,.08);--sm:0 4px 16px rgba(0,0,0,.12);--sl:0 12px 40px rgba(0,0,0,.16);
  --rsm:6px;--rmd:12px;--rlg:20px;--tr:.25s ease;
}
*,*::before,*::after{box-sizing:border-box;margin:0;padding:0}
body{font-family:'Segoe UI',system-ui,sans-serif;background:var(--off);color:var(--td);min-height:100vh}
a{text-decoration:none;color:inherit}
/* NAVBAR */
.rooms-navbar{background:var(--od);position:sticky;top:0;z-index:200;box-shadow:var(--sm)}
.nav-inner{display:flex;align-items:center;justify-content:space-between;height:64px;padding:0 24px;max-width:1280px;margin:0 auto}
.nav-brand{display:flex;align-items:center;gap:10px;color:var(--wh)}
.nav-brand i{color:var(--gold);font-size:1.4rem}
.nav-brand span{font-size:1.1rem;font-weight:700;letter-spacing:.5px}
.nav-links{display:flex;align-items:center;gap:6px}
.nav-links a{color:rgba(255,255,255,.8);padding:6px 14px;border-radius:var(--rsm);font-size:.9rem;transition:var(--tr)}
.nav-links a:hover,.nav-links a.active{background:rgba(255,255,255,.15);color:var(--wh)}
.nav-links a.active{color:var(--gold)}
.nav-right{display:flex;align-items:center;gap:10px;color:rgba(255,255,255,.9);font-size:.9rem}
.nav-avatar{width:36px;height:36px;border-radius:50%;background:var(--gold);color:var(--od);display:flex;align-items:center;justify-content:center;font-weight:700;font-size:.85rem}
.nav-btn{background:rgba(255,255,255,.1);color:rgba(255,255,255,.85);border:none;padding:6px 12px;border-radius:var(--rsm);cursor:pointer;font-size:.85rem;transition:var(--tr)}
.nav-btn:hover{background:var(--coral);color:var(--wh)}
/* HERO */
.rooms-hero{background:linear-gradient(135deg,var(--od) 0%,var(--ob) 60%,#2D9CDB 100%);padding:56px 24px 48px;text-align:center;color:var(--wh);position:relative;overflow:hidden}
.rooms-hero h1{font-size:2.6rem;font-weight:800;margin-bottom:10px;position:relative}
.rooms-hero p{font-size:1.1rem;opacity:.85;position:relative}
.hero-accent{color:var(--gold)}
/* CONTAINER */
.container{max-width:1280px;margin:0 auto;padding:0 24px}
/* ALERT */
.alert-bar{padding:12px 20px;margin:14px auto;max-width:1240px;border-radius:var(--rsm);font-size:.9rem;display:flex;align-items:center;gap:10px}
.alert-ok{background:#F0FDF4;border-left:4px solid #22C55E;color:#15803D}
.alert-er{background:#FEF2F2;border-left:4px solid #EF4444;color:#B91C1C}
/* SEARCH CARD */
.search-card{background:var(--wh);border-radius:var(--rlg);box-shadow:var(--sl);padding:28px 32px;margin:-28px auto 36px;position:relative;z-index:10;max-width:1200px}
.search-card h3{font-size:1rem;color:var(--od);font-weight:700;margin-bottom:16px;display:flex;align-items:center;gap:8px}
.search-card h3 i{color:var(--ob)}
.search-form{display:grid;grid-template-columns:1fr 1fr 1fr 1fr auto;gap:14px;align-items:end}
@media(max-width:800px){.search-form{grid-template-columns:1fr 1fr}}
@media(max-width:500px){.search-form{grid-template-columns:1fr}}
.form-field{display:flex;flex-direction:column;gap:5px}
.form-field label{font-size:.78rem;font-weight:600;color:var(--tm);text-transform:uppercase;letter-spacing:.5px}
.form-field input,.form-field select{padding:10px 12px;border:1.5px solid var(--bd);border-radius:var(--rsm);font-size:.92rem;color:var(--td);background:var(--wh);outline:none;width:100%;transition:border var(--tr),box-shadow var(--tr)}
.form-field input:focus,.form-field select:focus{border-color:var(--ob);box-shadow:0 0 0 3px rgba(26,107,138,.12)}
.btn-search{background:linear-gradient(135deg,var(--ob),var(--od));color:var(--wh);border:none;padding:10px 24px;border-radius:var(--rsm);font-size:.95rem;font-weight:600;cursor:pointer;white-space:nowrap;display:flex;align-items:center;gap:8px;transition:var(--tr)}
.btn-search:hover{transform:translateY(-1px);box-shadow:0 4px 12px rgba(26,107,138,.35)}
/* FILTER BAR */
.filter-bar{display:flex;align-items:center;justify-content:space-between;flex-wrap:wrap;gap:12px;margin-top:16px;padding-top:16px;border-top:1px solid var(--bd)}
.filter-chips{display:flex;align-items:center;gap:8px;flex-wrap:wrap}
.chip{padding:5px 14px;border-radius:999px;border:1.5px solid var(--bd);background:var(--wh);font-size:.82rem;font-weight:500;color:var(--tm);cursor:pointer;transition:var(--tr)}
.chip:hover,.chip.active{border-color:var(--ob);background:var(--ol);color:var(--od)}
.chip.active{font-weight:700}
.sort-row{display:flex;align-items:center;gap:8px;font-size:.85rem;color:var(--tl)}
.sort-row select{padding:5px 10px;border:1.5px solid var(--bd);border-radius:var(--rsm);font-size:.85rem;color:var(--td);outline:none;cursor:pointer}
.results-count{font-size:.85rem;color:var(--tl);background:var(--off);padding:4px 12px;border-radius:999px}
.results-count strong{color:var(--od)}
/* ROOMS SECTION */
.rooms-section{padding:0 0 60px}
.rooms-grid{display:grid;grid-template-columns:repeat(auto-fill,minmax(360px,1fr));gap:28px}
@media(max-width:800px){.rooms-grid{grid-template-columns:1fr 1fr}}
@media(max-width:560px){.rooms-grid{grid-template-columns:1fr}}
/* ROOM CARD */
.room-card{background:var(--wh);border-radius:var(--rmd);overflow:hidden;box-shadow:var(--ss);border:1px solid var(--bd);transition:transform var(--tr),box-shadow var(--tr);display:flex;flex-direction:column}
.room-card:hover{transform:translateY(-6px);box-shadow:var(--sl)}
.card-img{position:relative;height:220px;overflow:hidden;background:linear-gradient(135deg,var(--ol),var(--sand))}
.card-img img{width:100%;height:100%;object-fit:cover;transition:transform .4s ease}
.room-card:hover .card-img img{transform:scale(1.06)}
.card-img-ph{width:100%;height:100%;display:flex;flex-direction:column;align-items:center;justify-content:center;gap:8px;color:var(--ob)}
.card-img-ph i{font-size:3rem;opacity:.4}
.card-img-ph span{font-size:.85rem;opacity:.6;font-weight:500}
.status-badge{position:absolute;top:12px;left:12px;padding:4px 12px;border-radius:999px;font-size:.75rem;font-weight:700}
.badge-available{background:#D1FAE5;color:#065F46}
.badge-occupied{background:#FEE2E2;color:#991B1B}
.badge-reserved{background:#FEF3C7;color:#92400E}
.badge-maintenance{background:#E0E7FF;color:#3730A3}
.type-tag{position:absolute;top:12px;right:12px;padding:4px 12px;border-radius:999px;font-size:.72rem;font-weight:700;letter-spacing:.5px;text-transform:uppercase}
.type-single{background:#DBEAFE;color:#1E40AF}
.type-double{background:#D1FAE5;color:#065F46}
.type-deluxe{background:#FEF3C7;color:#92400E}
.type-suite{background:var(--gl);color:#78350F}
.type-family{background:#FCE7F3;color:#831843}
.card-overlay{position:absolute;inset:0;background:rgba(13,63,82,.6);display:flex;align-items:center;justify-content:center;opacity:0;transition:opacity var(--tr)}
.room-card:hover .card-overlay{opacity:1}
.btn-view-details{background:var(--wh);color:var(--od);border:none;padding:10px 22px;border-radius:var(--rsm);font-size:.9rem;font-weight:600;cursor:pointer;transition:var(--tr);display:flex;align-items:center;gap:8px}
.btn-view-details:hover{background:var(--gold);color:var(--od)}
.card-body{padding:20px;flex:1;display:flex;flex-direction:column;gap:12px}
.card-room-name{font-size:1.1rem;font-weight:700;color:var(--td)}
.card-room-num{font-size:.8rem;color:var(--tl);margin-top:3px}
.card-desc{font-size:.85rem;color:var(--tm);line-height:1.5;display:-webkit-box;-webkit-line-clamp:2;-webkit-box-orient:vertical;overflow:hidden}
.feature-pills{display:flex;gap:6px;flex-wrap:wrap}
.feature-pill{display:inline-flex;align-items:center;gap:5px;padding:3px 10px;background:var(--ol);color:var(--ob);border-radius:999px;font-size:.76rem;font-weight:500}
.amenities-row{display:flex;gap:14px;flex-wrap:wrap}
.amenity-icon{display:flex;flex-direction:column;align-items:center;gap:3px;color:var(--tl);font-size:.7rem}
.amenity-icon i{font-size:1rem;color:var(--ob)}
.card-footer{padding:16px 20px;border-top:1px solid var(--bd);display:flex;align-items:center;justify-content:space-between;gap:10px}
.price-block{}
.price-currency{font-size:.85rem;font-weight:600;color:var(--tm);vertical-align:top;margin-top:4px;display:inline-block}
.price-amount{font-size:1.6rem;font-weight:800;color:var(--od)}
.price-label{font-size:.75rem;color:var(--tl);margin-top:2px}
.btn-book{background:linear-gradient(135deg,var(--ob),var(--od));color:var(--wh);border:none;padding:10px 22px;border-radius:var(--rsm);font-size:.88rem;font-weight:600;cursor:pointer;transition:var(--tr);display:flex;align-items:center;gap:7px}
.btn-book:hover{transform:translateY(-1px);box-shadow:0 4px 12px rgba(26,107,138,.35)}
.btn-unavailable{background:var(--bd);color:var(--tm);border:none;padding:10px 22px;border-radius:var(--rsm);font-size:.88rem;font-weight:600;cursor:not-allowed;display:flex;align-items:center;gap:7px}
/* EMPTY STATE */
.empty-state{text-align:center;padding:60px 20px;color:var(--tl)}
.empty-state i{font-size:4rem;opacity:.2;margin-bottom:16px;display:block;color:var(--ob)}
.empty-state h2{font-size:1.4rem;color:var(--td);margin-bottom:8px}
.empty-state p{font-size:.9rem;max-width:400px;margin:0 auto}
/* DATE BANNER */
.date-banner{background:var(--ol);border:1px solid #B0D8E8;border-radius:var(--rsm);padding:10px 16px;margin-bottom:20px;font-size:.88rem;color:var(--od);display:flex;align-items:center;gap:8px;flex-wrap:wrap}
/* MODAL */
.modal-overlay{display:none;position:fixed;inset:0;background:rgba(0,0,0,.55);z-index:500;align-items:center;justify-content:center;padding:16px}
.modal-overlay.open{display:flex}
.modal-box{background:var(--wh);border-radius:var(--rmd);max-width:600px;width:100%;max-height:90vh;overflow-y:auto;box-shadow:var(--sl)}
.modal-header{display:flex;align-items:center;justify-content:space-between;padding:18px 20px;border-bottom:1px solid var(--bd)}
.modal-header h2{font-size:1.1rem;font-weight:700;color:var(--od)}
.modal-close{background:none;border:none;font-size:1.5rem;cursor:pointer;color:var(--tl);line-height:1;transition:var(--tr)}
.modal-close:hover{color:var(--coral)}
.modal-img{width:100%;height:200px;object-fit:cover}
.modal-img-ph{width:100%;height:200px;background:linear-gradient(135deg,var(--ol),var(--sand));display:flex;align-items:center;justify-content:center;color:var(--ob);font-size:4rem;opacity:.4}
.modal-body{padding:20px}
.modal-info-grid{display:grid;grid-template-columns:1fr 1fr;gap:12px;margin-bottom:16px}
.modal-info-item{background:var(--off);border-radius:var(--rsm);padding:10px 14px}
.modal-info-label{display:block;font-size:.72rem;text-transform:uppercase;letter-spacing:.05em;color:var(--tl);font-weight:600;margin-bottom:3px}
.modal-info-value{font-size:.9rem;font-weight:700;color:var(--od)}
.modal-desc{font-size:.88rem;color:var(--tm);line-height:1.6;margin-bottom:14px}
.modal-amenities{display:flex;flex-wrap:wrap;gap:8px}
.modal-amenity{display:inline-flex;align-items:center;gap:5px;padding:4px 10px;background:var(--ol);color:var(--ob);border-radius:999px;font-size:.78rem;font-weight:500}
.modal-footer{padding:16px 20px;border-top:1px solid var(--bd);display:flex;align-items:center;justify-content:space-between;gap:10px}
.modal-price{font-size:1.3rem;font-weight:800;color:var(--od)}
.btn-book-modal{background:linear-gradient(135deg,var(--ob),var(--od));color:var(--wh);border:none;padding:11px 28px;border-radius:var(--rsm);font-size:.95rem;font-weight:700;cursor:pointer;transition:var(--tr);display:flex;align-items:center;gap:8px}
.btn-book-modal:hover{transform:translateY(-1px);box-shadow:0 4px 12px rgba(26,107,138,.35)}
.btn-book-modal:disabled{opacity:.5;cursor:not-allowed;transform:none;box-shadow:none}
/* FOOTER */
.rooms-footer{background:var(--od);color:rgba(255,255,255,.7);text-align:center;padding:24px;font-size:.85rem}
/* TOAST */
.toast-wrapper{position:fixed;top:1.5rem;right:1.5rem;z-index:600;display:flex;flex-direction:column;gap:8px}
.toast{display:flex;align-items:center;gap:10px;padding:12px 18px;border-radius:var(--rsm);color:var(--wh);font-size:.9rem;font-weight:500;min-width:280px;box-shadow:var(--sm);animation:tIn .3s ease}
.toast-ok{background:#28a745}.toast-er{background:#dc3545}
@keyframes tIn{from{opacity:0;transform:translateX(100%)}to{opacity:1;transform:translateX(0)}}
@media(max-width:768px){.nav-links{display:none}}
</style>
</head>
<body>
<div class="rooms-page-wrapper">
<div class="toast-wrapper" id="toastWrapper"></div>

<!-- NAVBAR -->
<nav class="rooms-navbar">
  <div class="nav-inner">
    <a href="<%= ctx %>/" class="nav-brand"><i class="fas fa-umbrella-beach"></i><span>Ocean View Resort</span></a>
    <div class="nav-links">
      <a href="<%= ctx %>/">Home</a>
      <a href="<%= ctx %>/rooms" class="active">Rooms</a>
      <% if ("ADMIN".equals(navRole)) { %><a href="<%= ctx %>/admin/dashboard">Admin</a>
      <% } else if ("STAFF".equals(navRole)) { %><a href="<%= ctx %>/staff/dashboard">Staff</a>
      <% } else { %><a href="<%= ctx %>/guest/dashboard">My Account</a><% } %>
    </div>
    <div class="nav-right">
      <div class="nav-avatar"><%= navInit %></div>
      <span>Welcome, <%= esc(navFirst) %>!</span>
      <a href="<%= ctx %>/logout" class="nav-btn"><i class="fas fa-sign-out-alt"></i> Logout</a>
    </div>
  </div>
</nav>

<!-- HERO -->
<section class="rooms-hero">
  <h1>Rooms &amp; <span class="hero-accent">Suites</span></h1>
  <p>Discover your perfect accommodation at Ocean View Resort</p>
</section>

<!-- ALERTS -->
<% if (flashOk!=null&&!flashOk.isEmpty()) { %>
<div class="container"><div class="alert-bar alert-ok"><i class="fas fa-check-circle"></i> <%= esc(flashOk) %></div></div>
<% } %>
<% if (flashErr!=null&&!flashErr.isEmpty()) { %>
<div class="container"><div class="alert-bar alert-er"><i class="fas fa-exclamation-circle"></i> <%= esc(flashErr) %></div></div>
<% } %>

<!-- SEARCH CARD -->
<div class="container">
<div class="search-card">
  <h3><i class="fas fa-search"></i> Find Your Perfect Room</h3>
  <form action="<%= ctx %>/rooms" method="get" class="search-form">
    <div class="form-field">
      <label for="checkIn">Check-in Date</label>
      <input type="date" id="checkIn" name="checkIn" value="<%= checkInStr %>" min="<%= java.time.LocalDate.now() %>">
    </div>
    <div class="form-field">
      <label for="checkOut">Check-out Date</label>
      <input type="date" id="checkOut" name="checkOut" value="<%= checkOutStr %>" min="<%= java.time.LocalDate.now().plusDays(1) %>">
    </div>
    <div class="form-field">
      <label for="guests">Guests</label>
      <select id="guests" name="guests">
        <option value="1" <%= "1".equals(selGuests)?"selected":"" %>>1 Guest</option>
        <option value="2" <%= "2".equals(selGuests)||selGuests==null||selGuests.isEmpty()?"selected":"" %>>2 Guests</option>
        <option value="3" <%= "3".equals(selGuests)?"selected":"" %>>3 Guests</option>
        <option value="4" <%= "4".equals(selGuests)?"selected":"" %>>4 Guests</option>
        <option value="5" <%= "5".equals(selGuests)?"selected":"" %>>5+ Guests</option>
      </select>
    </div>
    <div class="form-field">
      <label for="roomType">Room Type</label>
      <select id="roomType" name="roomType">
        <option value="" <%= selType.isEmpty()?"selected":"" %>>All Types</option>
        <option value="SINGLE"  <%= "SINGLE".equals(selType)?"selected":"" %>>Single</option>
        <option value="DOUBLE"  <%= "DOUBLE".equals(selType)?"selected":"" %>>Double</option>
        <option value="DELUXE"  <%= "DELUXE".equals(selType)?"selected":"" %>>Deluxe</option>
        <option value="SUITE"   <%= "SUITE".equals(selType)?"selected":"" %>>Suite</option>
        <option value="FAMILY"  <%= "FAMILY".equals(selType)?"selected":"" %>>Family</option>
      </select>
    </div>
    <button type="submit" class="btn-search"><i class="fas fa-search"></i> Search</button>
  </form>

  <!-- FILTER / SORT BAR -->
  <div class="filter-bar">
    <div class="filter-chips">
      <span class="chip <%= selType.isEmpty()?"active":"" %>" onclick="filterByType('')">All</span>
      <span class="chip <%= "SINGLE".equals(selType)?"active":"" %>" onclick="filterByType('SINGLE')">Single</span>
      <span class="chip <%= "DOUBLE".equals(selType)?"active":"" %>" onclick="filterByType('DOUBLE')">Double</span>
      <span class="chip <%= "DELUXE".equals(selType)?"active":"" %>" onclick="filterByType('DELUXE')">Deluxe</span>
      <span class="chip <%= "SUITE".equals(selType)?"active":"" %>"  onclick="filterByType('SUITE')">Suite</span>
      <span class="chip <%= "FAMILY".equals(selType)?"active":"" %>" onclick="filterByType('FAMILY')">Family</span>
    </div>
    <div style="display:flex;align-items:center;gap:16px;flex-wrap:wrap">
      <span class="results-count"><strong><%= rooms.size() %></strong> room<%= rooms.size()!=1?"s":"" %> found</span>
      <div class="sort-row">
        <i class="fas fa-sort"></i> Sort:
        <select id="sortSelect" onchange="sortRooms(this.value)">
          <option value="default">Default</option>
          <option value="price-asc">Price: Low to High</option>
          <option value="price-desc">Price: High to Low</option>
          <option value="capacity-asc">Capacity: Low to High</option>
          <option value="capacity-desc">Capacity: High to Low</option>
        </select>
      </div>
    </div>
  </div>
</div>
</div>

<!-- ROOMS SECTION -->
<div class="rooms-section">
<div class="container">

<% if (checkInDisp!=null&&checkOutDisp!=null) { %>
<div class="date-banner">
  <i class="fas fa-calendar-check" style="color:var(--ob)"></i>
  Showing rooms for <strong><%= checkInDisp %></strong> &rarr; <strong><%= checkOutDisp %></strong>
  &bull; <strong><%= numNights %></strong> night<%= numNights!=1?"s":"" %>
</div>
<% } %>

<% if (rooms.isEmpty()) { %>
<div class="empty-state">
  <i class="fas fa-bed"></i>
  <h2>No Rooms Found</h2>
  <p><%= checkInDate!=null ? "No rooms available for your selected dates. Try different dates or remove filters." : "No rooms are currently listed. Please check back later." %></p>
</div>
<% } else { %>
<div class="rooms-grid" id="roomsGrid">
<% for(Room room : rooms) {
     String rType   = room.getRoomType()!=null ? room.getRoomType().name() : "SINGLE";
     String rNum    = room.getRoomNumber()!=null ? room.getRoomNumber() : "";
     String rFloor  = room.getFloor()!=null ? room.getFloor().toString() : "—";
     String rCap    = room.getCapacity()!=null ? room.getCapacity().toString() : "2";
     String rPrice  = room.getPricePerNight()!=null ? String.format("%,.0f", room.getPricePerNight().doubleValue()) : "0";
     String rSize   = room.getSize()!=null&&room.getSize()>0 ? room.getSize()+" m²" : "—";
     String rDesc   = room.getDescription()!=null&&!room.getDescription().isEmpty() ? room.getDescription() : roomDesc(rType);
     String rAmen   = room.getAmenities()!=null&&!room.getAmenities().isEmpty() ? room.getAmenities() : "Free WiFi,Air Conditioning,Smart TV,Room Service";
     String rStatus = room.getStatus()!=null ? room.getStatus().name() : "AVAILABLE";
     String rImg    = room.getImageUrl()!=null&&!room.getImageUrl().isEmpty() ? room.getImageUrl() : "";
     // Prefer DB image_url, fall back to local asset path
     String rImgSrc = !rImg.isEmpty() ? rImg : ctx+"/assets/images/rooms/"+rType.toLowerCase()+".jpg";
     boolean avail  = room.isAvailable();
     int rId        = room.getRoomId()!=null ? room.getRoomId() : 0;
     String badgeClass = "badge-"+rStatus.toLowerCase().replace("_","-");
%>
<div class="room-card"
     data-price="<%= room.getPricePerNight()!=null?room.getPricePerNight().doubleValue():0 %>"
     data-type="<%= rType %>"
     data-capacity="<%= room.getCapacity()!=null?room.getCapacity():0 %>"
     data-roomid="<%= rId %>">

  <!-- IMAGE -->
  <div class="card-img">
    <img src="<%= rImgSrc %>" alt="<%= esc(roomLabel(rType)) %>"
         onerror="this.style.display='none';this.nextElementSibling.style.display='flex'">
    <div class="card-img-ph" style="display:none"><i class="fas fa-bed"></i><span><%= rType.toLowerCase() %></span></div>
    <!-- STATUS BADGE -->
    <span class="status-badge <%= badgeClass %>">
      <i class="fas fa-<%= "AVAILABLE".equals(rStatus)?"check-circle":"OCCUPIED".equals(rStatus)?"times-circle":"RESERVED".equals(rStatus)?"clock":"tools" %>"></i>
      <%= rStatus.replace("_"," ") %>
    </span>
    <!-- TYPE TAG -->
    <span class="type-tag <%= typeTagClass(rType) %>"><%= rType %></span>
    <!-- OVERLAY -->
    <div class="card-overlay">
      <button class="btn-view-details" onclick="openModal(this)"
        data-roomid="<%= rId %>"
        data-type="<%= rType %>"
        data-label="<%= esc(roomLabel(rType)) %>"
        data-number="<%= esc(rNum) %>"
        data-price="<%= room.getPricePerNight()!=null?room.getPricePerNight().toPlainString():"0" %>"
        data-capacity="<%= rCap %>"
        data-floor="<%= rFloor %>"
        data-status="<%= rStatus %>"
        data-desc="<%= esc(rDesc) %>"
        data-amenities="<%= esc(rAmen) %>"
        data-imgurl="<%= esc(rImgSrc) %>">
        <i class="fas fa-eye"></i> View Details
      </button>
    </div>
  </div>

  <!-- CARD BODY -->
  <div class="card-body">
    <div>
      <div class="card-room-name"><%= roomLabel(rType) %></div>
      <div class="card-room-num">Room <%= esc(rNum) %> &bull; Floor <%= rFloor %></div>
    </div>
    <p class="card-desc"><%= esc(rDesc) %></p>
    <div class="feature-pills">
      <span class="feature-pill"><i class="fas fa-users"></i> Up to <%= rCap %> guests</span>
      <span class="feature-pill"><i class="fas fa-layer-group"></i> Floor <%= rFloor %></span>
      <span class="feature-pill"><i class="fas fa-ruler-combined"></i> <%= rSize %></span>
    </div>
    <div class="amenities-row">
      <div class="amenity-icon"><i class="fas fa-wifi"></i><span>WiFi</span></div>
      <div class="amenity-icon"><i class="fas fa-snowflake"></i><span>A/C</span></div>
      <div class="amenity-icon"><i class="fas fa-tv"></i><span>TV</span></div>
      <div class="amenity-icon"><i class="fas fa-concierge-bell"></i><span>Service</span></div>
      <% if("DELUXE".equals(rType)||"SUITE".equals(rType)) { %>
      <div class="amenity-icon"><i class="fas fa-water"></i><span>Ocean View</span></div>
      <% } %>
      <% if("SUITE".equals(rType)) { %>
      <div class="amenity-icon"><i class="fas fa-spa"></i><span>Spa</span></div>
      <% } %>
    </div>
  </div>

  <!-- CARD FOOTER -->
  <div class="card-footer">
    <div class="price-block">
      <div><span class="price-currency">Rs.</span><span class="price-amount"><%= rPrice %></span></div>
      <div class="price-label">per night &bull; excl. tax</div>
    </div>
    <% if(avail) { %>
    <button class="btn-book" onclick="bookRoom(<%= rId %>)"><i class="fas fa-calendar-check"></i> Book Now</button>
    <% } else { %>
    <button class="btn-unavailable" disabled><i class="fas fa-ban"></i> Not Available</button>
    <% } %>
  </div>
</div>
<% } %>
</div>
<% } %>

</div>
</div>

<!-- ROOM DETAIL MODAL -->
<div class="modal-overlay" id="roomModal">
  <div class="modal-box">
    <div class="modal-header">
      <h2 id="modalTitle">Room Details</h2>
      <button class="modal-close" onclick="closeModal()">&times;</button>
    </div>
    <div id="modalImageArea"></div>
    <div class="modal-body">
      <div class="modal-info-grid">
        <div class="modal-info-item"><span class="modal-info-label">Room Number</span><span class="modal-info-value" id="modalRoomNum">-</span></div>
        <div class="modal-info-item"><span class="modal-info-label">Room Type</span><span class="modal-info-value" id="modalRoomType">-</span></div>
        <div class="modal-info-item"><span class="modal-info-label">Floor</span><span class="modal-info-value" id="modalFloor">-</span></div>
        <div class="modal-info-item"><span class="modal-info-label">Max Guests</span><span class="modal-info-value" id="modalCapacity">-</span></div>
      </div>
      <p class="modal-desc" id="modalDesc"></p>
      <div class="modal-amenities" id="modalAmenities"></div>
    </div>
    <div class="modal-footer">
      <div class="modal-price"><span id="modalPrice">-</span> <span style="font-size:.85rem;font-weight:400;color:#718096">/ night</span></div>
      <button class="btn-book-modal" id="modalBookBtn"><i class="fas fa-calendar-check"></i> Book This Room</button>
    </div>
  </div>
</div>

<!-- FOOTER -->
<footer class="rooms-footer">
  <p>&copy; <%= java.time.Year.now().getValue() %> Ocean View Resort. All rights reserved.</p>
</footer>
</div><!-- /.rooms-page-wrapper -->

<script>
(function(){
'use strict';
var ctx  = '<%= ctx %>';
var ci   = '<%= checkInStr %>';
var co   = '<%= checkOutStr %>';
var gsts = '<%= selGuests %>';
var selRoomId = null;

/* ── DATE INPUT SETUP ── */
var today = new Date().toISOString().split('T')[0];
var ciEl  = document.getElementById('checkIn');
var coEl  = document.getElementById('checkOut');
if(ciEl){ ciEl.min = today; if(!ci) ciEl.value=''; }
if(coEl){ coEl.min = today; if(!co) coEl.value=''; }
if(ciEl && coEl){
    ciEl.addEventListener('change', function(){
        var nxt = new Date(this.value); nxt.setDate(nxt.getDate()+1);
        coEl.min = nxt.toISOString().split('T')[0];
        if(coEl.value && coEl.value <= this.value) coEl.value = coEl.min;
    });
}

/* ── TOAST ── */
function showToast(msg, type){
    var tw = document.getElementById('toastWrapper');
    var t  = document.createElement('div');
    t.className = 'toast toast-'+(type==='error'?'er':'ok');
    t.innerHTML = '<i class="fas fa-'+(type==='error'?'exclamation-circle':'check-circle')+'"></i> '+msg+
        '<button onclick="this.parentNode.remove()" style="background:none;border:none;color:#fff;margin-left:auto;font-size:1.2rem;cursor:pointer;line-height:1">&times;</button>';
    tw.appendChild(t);
    setTimeout(function(){ if(t.parentNode){t.style.opacity='0';t.style.transition='.4s';setTimeout(function(){t.remove();},400);} },5000);
}

/* ── FILTER BY TYPE ── */
window.filterByType = function(type){
    var url = ctx+'/rooms';
    var params = [];
    if(ci)   params.push('checkIn='+encodeURIComponent(ci));
    if(co)   params.push('checkOut='+encodeURIComponent(co));
    if(gsts) params.push('guests='+encodeURIComponent(gsts));
    if(type) params.push('roomType='+encodeURIComponent(type));
    if(params.length) url += '?'+params.join('&');
    window.location.href = url;
};

/* ── SORT ROOMS ── */
window.sortRooms = function(by){
    var grid  = document.getElementById('roomsGrid');
    if(!grid) return;
    var cards = Array.prototype.slice.call(grid.querySelectorAll('.room-card'));
    cards.sort(function(a,b){
        var pA=parseFloat(a.dataset.price||0), pB=parseFloat(b.dataset.price||0);
        var cA=parseInt(a.dataset.capacity||0), cB=parseInt(b.dataset.capacity||0);
        if(by==='price-asc')      return pA-pB;
        if(by==='price-desc')     return pB-pA;
        if(by==='capacity-asc')   return cA-cB;
        if(by==='capacity-desc')  return cB-cA;
        return 0;
    });
    cards.forEach(function(c){ grid.appendChild(c); });
};

/* ── OPEN MODAL ── */
window.openModal = function(btn){
    var d = btn.dataset;
    selRoomId = d.roomid;
    document.getElementById('modalTitle').textContent = d.label || d.type;
    document.getElementById('modalRoomNum').textContent  = 'Room '+(d.number||'—');
    document.getElementById('modalRoomType').textContent = d.label || d.type;
    document.getElementById('modalFloor').textContent    = 'Floor '+(d.floor||'—');
    document.getElementById('modalCapacity').textContent = (d.capacity||'—')+' guest(s)';
    document.getElementById('modalDesc').textContent     = d.desc || '';
    document.getElementById('modalPrice').textContent    = 'Rs. '+parseFloat(d.price||0).toLocaleString('en-US',{minimumFractionDigits:0,maximumFractionDigits:0});

    /* Image */
    var imgArea = document.getElementById('modalImageArea');
    if(d.imgurl && d.imgurl.trim()){
        imgArea.innerHTML = '<img class="modal-img" src="'+d.imgurl+'" alt="'+d.label+'" '+
            'onerror="this.style.display=\'none\';this.nextElementSibling.style.display=\'flex\'">' +
            '<div class="modal-img-ph" style="display:none"><i class="fas fa-bed"></i></div>';
    } else {
        imgArea.innerHTML = '<div class="modal-img-ph"><i class="fas fa-bed"></i></div>';
    }

    /* Amenities */
    var amenDiv = document.getElementById('modalAmenities');
    amenDiv.innerHTML = '';
    var iconMap = {wifi:'wifi',air:'snowflake',conditioning:'snowflake',tv:'tv',pool:'swimming-pool',service:'concierge-bell',ocean:'water',view:'water',spa:'spa',parking:'parking',breakfast:'coffee',bar:'glass-martini',gym:'dumbbell'};
    var amenList = (d.amenities&&d.amenities.trim()) ? d.amenities.split(',') : ['Free WiFi','Air Conditioning','Smart TV','Room Service'];
    amenList.forEach(function(a){
        a = a.trim(); if(!a) return;
        var icon = 'star';
        var al   = a.toLowerCase();
        Object.keys(iconMap).forEach(function(k){ if(al.indexOf(k)!==-1) icon=iconMap[k]; });
        var chip = document.createElement('span');
        chip.className = 'modal-amenity';
        chip.innerHTML = '<i class="fas fa-'+icon+'"></i> '+a;
        amenDiv.appendChild(chip);
    });

    /* Book button */
    var bookBtn = document.getElementById('modalBookBtn');
    if(d.status==='AVAILABLE'){
        bookBtn.disabled   = false;
        bookBtn.style.opacity = '1';
        bookBtn.style.cursor  = 'pointer';
        bookBtn.innerHTML  = '<i class="fas fa-calendar-check"></i> Book This Room';
        bookBtn.onclick    = function(){ bookRoom(selRoomId); };
    } else {
        bookBtn.disabled   = true;
        bookBtn.style.opacity = '0.5';
        bookBtn.style.cursor  = 'not-allowed';
        bookBtn.innerHTML  = '<i class="fas fa-ban"></i> Not Available';
        bookBtn.onclick    = null;
    }

    document.getElementById('roomModal').classList.add('open');
    document.body.style.overflow = 'hidden';
};

/* ── CLOSE MODAL ── */
window.closeModal = function(){
    document.getElementById('roomModal').classList.remove('open');
    document.body.style.overflow = '';
};
document.getElementById('roomModal').addEventListener('click', function(e){ if(e.target===this) closeModal(); });
document.addEventListener('keydown', function(e){ if(e.key==='Escape') closeModal(); });

/* ── BOOK ROOM ── */
window.bookRoom = function(roomId){
    var ciVal = ciEl ? ciEl.value : ci;
    var coVal = coEl ? coEl.value : co;
    var gVal  = document.getElementById('guests') ? document.getElementById('guests').value : gsts;

    if(!ciVal || !coVal){
        showToast('Please select check-in and check-out dates before booking.','error');
        closeModal();
        setTimeout(function(){ if(ciEl) ciEl.focus(); }, 300);
        return;
    }
    if(new Date(coVal) <= new Date(ciVal)){
        showToast('Check-out date must be after check-in date.','error');
        return;
    }

    var url = ctx+'/reservation?action=new'
              +'&roomId='+encodeURIComponent(roomId)
              +'&checkIn='+encodeURIComponent(ciVal)
              +'&checkOut='+encodeURIComponent(coVal)
              +'&guests='+encodeURIComponent(gVal||2);
    window.location.href = url;
};

})();
</script>
</body>
</html>
