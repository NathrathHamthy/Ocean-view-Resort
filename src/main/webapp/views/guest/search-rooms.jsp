<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="com.oceanview.model.User, com.oceanview.model.Room, com.oceanview.util.Constants, java.util.List, java.time.LocalDate" %>
<%!
    private String esc(String s){ if(s==null)return ""; return s.replace("&","&amp;").replace("<","&lt;").replace(">","&gt;").replace("\"","&quot;"); }
    private String roomLbl(String t){
        if(t==null)return "Room";
        switch(t){
            case "SINGLE": return "Standard Single";
            case "DOUBLE": return "Double Room";
            case "DELUXE": return "Deluxe Room";
            case "SUITE":  return "Luxury Suite";
            case "FAMILY": return "Family Room";
            default: return t.charAt(0)+t.substring(1).toLowerCase()+" Room";
        }
    }
    private String roomDescShort(String t){
        if(t==null)return "Modern room with resort amenities.";
        switch(t){
            case "SINGLE": return "Perfect for solo travellers. Modern amenities, comfortable bed, city or ocean view.";
            case "DOUBLE": return "Ideal for couples. King-size bed, premium linen, private balcony available.";
            case "DELUXE": return "Elevated experience with sea views, premium furnishings and exclusive services.";
            case "SUITE":  return "Luxurious suite with living room, jacuzzi, ocean panorama and butler service.";
            case "FAMILY": return "Spacious family room with multiple beds and all family-friendly amenities.";
            default: return "Beautifully appointed room with modern amenities and resort views.";
        }
    }
%>
<%
    User currentUser = (User) session.getAttribute(Constants.SESSION_USER);
    if(currentUser==null) currentUser=(User)session.getAttribute("loggedInUser");
    if(currentUser==null){ response.sendRedirect(request.getContextPath()+"/login"); return; }

    String ctx      = request.getContextPath();
    String navRole  = currentUser.getRole()!=null ? currentUser.getRole().toString() : "GUEST";
    String navFirst = (currentUser.getFirstName()!=null&&!currentUser.getFirstName().isEmpty())
                      ? currentUser.getFirstName() : currentUser.getUsername();
    String navInit  = (navFirst!=null&&!navFirst.isEmpty()) ? String.valueOf(navFirst.charAt(0)).toUpperCase() : "G";

    // Get search params
    String checkIn    = request.getParameter("checkIn")   != null ? request.getParameter("checkIn")   : "";
    String checkOut   = request.getParameter("checkOut")  != null ? request.getParameter("checkOut")  : "";
    String guests     = request.getParameter("guests")    != null ? request.getParameter("guests")    : "2";
    String typeFilter = request.getParameter("type")      != null ? request.getParameter("type")      : "";
    String maxPrice   = request.getParameter("maxPrice")  != null ? request.getParameter("maxPrice")  : "";
    String minPrice   = request.getParameter("minPrice")  != null ? request.getParameter("minPrice")  : "";

    // Real room list from servlet attribute
    @SuppressWarnings("unchecked")
    List<Room> roomList = (List<Room>) request.getAttribute("rooms");
    if(roomList==null) roomList = new java.util.ArrayList<>();

    // Flash messages
    String flashOk  = (String) session.getAttribute(Constants.ATTR_SUCCESS);
    String flashErr = (String) session.getAttribute(Constants.ATTR_ERROR);
    session.removeAttribute(Constants.ATTR_SUCCESS);
    session.removeAttribute(Constants.ATTR_ERROR);
%>
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1.0">
<title>Search Rooms - Ocean View Resort</title>
<link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
<style>
:root{--pri:#006994;--pri-dk:#004f70;--acc:#4A90A4;--gold:#D4AF37;--ok:#28a745;--er:#dc3545;--warn:#ffc107;--g50:#f8f9fa;--g100:#f1f3f5;--g200:#e9ecef;--g300:#dee2e6;--g500:#6c757d;--g700:#495057;--g800:#343a40;--sh1:0 2px 8px rgba(0,0,0,.08);--sh2:0 6px 20px rgba(0,0,0,.12);--r:.75rem;--r2:.4rem;--tr:.22s ease}
*,*::before,*::after{box-sizing:border-box;margin:0;padding:0}
body{font-family:'Segoe UI',system-ui,sans-serif;background:#eef2f7;color:var(--g800);min-height:100vh}
a{text-decoration:none;color:inherit}
/* NAV */
.snav{background:var(--pri-dk);position:sticky;top:0;z-index:200;box-shadow:0 2px 8px rgba(0,0,0,.15)}
.snav-in{max-width:1280px;margin:0 auto;padding:0 24px;height:62px;display:flex;align-items:center;justify-content:space-between}
.s-brand{display:flex;align-items:center;gap:10px;color:#fff;font-weight:700;font-size:1.05rem}
.s-brand i{color:var(--gold)}
.s-links{display:flex;align-items:center;gap:4px}
.s-links a{color:rgba(255,255,255,.82);padding:6px 13px;border-radius:var(--r2);font-size:.88rem;transition:var(--tr)}
.s-links a:hover,.s-links a.act{background:rgba(255,255,255,.15);color:#fff}
.s-right{display:flex;align-items:center;gap:10px;font-size:.88rem;color:rgba(255,255,255,.9)}
.s-avatar{width:34px;height:34px;border-radius:50%;background:var(--gold);color:var(--pri-dk);display:flex;align-items:center;justify-content:center;font-weight:700;font-size:.82rem}
.s-logout{background:rgba(255,255,255,.1);color:rgba(255,255,255,.85);border:none;padding:5px 12px;border-radius:var(--r2);cursor:pointer;font-size:.85rem;transition:var(--tr)}
.s-logout:hover{background:rgba(220,53,69,.7);color:#fff}
/* HERO */
.sr-hero{background:linear-gradient(135deg,#003d5c,var(--pri),var(--acc));padding:40px 24px 80px;text-align:center;color:#fff}
.sr-hero h1{font-size:2.2rem;font-weight:800;margin-bottom:8px}
.sr-hero p{font-size:1rem;opacity:.85}
/* LAYOUT */
.sr-wrap{max-width:1280px;margin:-48px auto 0;padding:0 24px 60px;position:relative}
/* SEARCH SIDEBAR */
.sr-layout{display:grid;grid-template-columns:300px 1fr;gap:24px;align-items:start}
@media(max-width:900px){.sr-layout{grid-template-columns:1fr}}
/* FILTER PANEL */
.filter-panel{background:#fff;border-radius:var(--r);box-shadow:var(--sh2);position:sticky;top:80px}
.fp-hdr{background:linear-gradient(135deg,var(--pri),var(--acc));color:#fff;padding:14px 18px;border-radius:var(--r) var(--r) 0 0;display:flex;align-items:center;justify-content:space-between}
.fp-hdr h3{font-size:.95rem;font-weight:700;display:flex;align-items:center;gap:8px}
.fp-body{padding:18px}
.fp-section{margin-bottom:18px;padding-bottom:18px;border-bottom:1px solid var(--g200)}
.fp-section:last-child{border-bottom:none;margin-bottom:0;padding-bottom:0}
.fp-section h4{font-size:.8rem;font-weight:700;text-transform:uppercase;letter-spacing:.05em;color:var(--g500);margin-bottom:10px}
.fp-field{display:flex;flex-direction:column;gap:5px;margin-bottom:10px}
.fp-field label{font-size:.8rem;font-weight:600;color:var(--g700)}
.fp-field input,.fp-field select{padding:8px 10px;border:1.5px solid var(--g300);border-radius:var(--r2);font-size:.88rem;outline:none;transition:border var(--tr),box-shadow var(--tr)}
.fp-field input:focus,.fp-field select:focus{border-color:var(--pri);box-shadow:0 0 0 3px rgba(0,105,148,.1)}
.type-chk{display:flex;align-items:center;gap:8px;padding:6px 0;cursor:pointer;font-size:.88rem;color:var(--g700)}
.type-chk input[type="radio"]{accent-color:var(--pri);width:15px;height:15px}
.btn-apply{width:100%;background:var(--pri);color:#fff;border:none;padding:10px;border-radius:var(--r2);font-size:.9rem;font-weight:600;cursor:pointer;transition:var(--tr);display:flex;align-items:center;justify-content:center;gap:8px}
.btn-apply:hover{background:var(--pri-dk)}
.btn-reset{width:100%;background:var(--g100);color:var(--g700);border:1.5px solid var(--g200);padding:8px;border-radius:var(--r2);font-size:.85rem;font-weight:500;cursor:pointer;margin-top:8px;transition:var(--tr)}
.btn-reset:hover{background:var(--g200)}
/* RESULTS */
.results-hdr{display:flex;align-items:center;justify-content:space-between;margin-bottom:20px;flex-wrap:wrap;gap:10px}
.results-hdr h2{font-size:1.1rem;font-weight:700;color:var(--g800)}
.results-count{font-size:.85rem;color:var(--g500);background:#fff;padding:4px 14px;border-radius:999px;border:1.5px solid var(--g200)}
.sort-bar{display:flex;align-items:center;gap:8px;font-size:.85rem;color:var(--g500)}
.sort-bar select{padding:6px 10px;border:1.5px solid var(--g200);border-radius:var(--r2);font-size:.85rem;outline:none;cursor:pointer}
/* ROOM CARDS */
.sr-grid{display:grid;grid-template-columns:repeat(auto-fill,minmax(280px,1fr));gap:20px}
@media(max-width:600px){.sr-grid{grid-template-columns:1fr}}
.sr-card{background:#fff;border-radius:var(--r);overflow:hidden;box-shadow:var(--sh1);border:1px solid var(--g200);transition:transform var(--tr),box-shadow var(--tr);display:flex;flex-direction:column}
.sr-card:hover{transform:translateY(-4px);box-shadow:var(--sh2)}
.sr-img{height:180px;position:relative;background:linear-gradient(135deg,#e8f4f8,#f5e9d7);overflow:hidden}
.sr-img img{width:100%;height:100%;object-fit:cover;transition:transform .4s ease}
.sr-card:hover .sr-img img{transform:scale(1.05)}
.sr-img-ph{width:100%;height:100%;display:flex;flex-direction:column;align-items:center;justify-content:center;color:var(--acc);gap:6px}
.sr-img-ph i{font-size:2.5rem;opacity:.35}
.sr-img-ph span{font-size:.75rem;opacity:.6;font-weight:500}
.sr-status{position:absolute;top:10px;left:10px;padding:3px 10px;border-radius:999px;font-size:.72rem;font-weight:700}
.ss-avail{background:#D1FAE5;color:#065F46}
.ss-occup{background:#FEE2E2;color:#991B1B}
.ss-reserv{background:#FEF3C7;color:#92400E}
.ss-maint{background:#E0E7FF;color:#3730A3}
.sr-type{position:absolute;top:10px;right:10px;padding:3px 10px;border-radius:999px;font-size:.7rem;font-weight:700;letter-spacing:.5px;text-transform:uppercase;background:var(--pri);color:#fff}
.sr-body{padding:16px;flex:1;display:flex;flex-direction:column;gap:8px}
.sr-name{font-size:.98rem;font-weight:700;color:var(--g800)}
.sr-num{font-size:.76rem;color:var(--g500)}
.sr-desc{font-size:.82rem;color:var(--g700);line-height:1.5;display:-webkit-box;-webkit-line-clamp:2;-webkit-box-orient:vertical;overflow:hidden}
.sr-feats{display:flex;gap:8px;flex-wrap:wrap}
.sr-feat{display:inline-flex;align-items:center;gap:4px;padding:2px 8px;background:var(--g100);color:var(--g700);border-radius:999px;font-size:.74rem}
.sr-feat i{color:var(--pri)}
.sr-footer{padding:12px 16px;border-top:1px solid var(--g100);display:flex;align-items:center;justify-content:space-between}
.sr-price-amt{font-size:1.3rem;font-weight:800;color:var(--pri-dk)}
.sr-price-lbl{font-size:.72rem;color:var(--g500);margin-top:2px}
.btn-sr-book{background:var(--pri);color:#fff;border:none;padding:8px 16px;border-radius:var(--r2);font-size:.82rem;font-weight:600;cursor:pointer;transition:var(--tr);display:flex;align-items:center;gap:6px}
.btn-sr-book:hover{background:var(--pri-dk)}
.btn-sr-unavail{background:var(--g200);color:var(--g500);border:none;padding:8px 16px;border-radius:var(--r2);font-size:.82rem;font-weight:600;cursor:not-allowed;display:flex;align-items:center;gap:6px}
/* ALERTS */
.s-alert{padding:10px 16px;border-radius:var(--r2);margin-bottom:16px;font-size:.88rem;display:flex;align-items:center;gap:8px}
.s-ok{background:#D4EDDA;color:#155724;border-left:4px solid var(--ok)}
.s-er{background:#F8D7DA;color:#721C24;border-left:4px solid var(--er)}
/* EMPTY */
.empty-s{text-align:center;padding:60px 20px;background:#fff;border-radius:var(--r);border:2px dashed var(--g200)}
.empty-s i{font-size:3rem;color:var(--g200);display:block;margin-bottom:14px}
.empty-s h3{color:var(--g700);margin-bottom:6px}
.empty-s p{font-size:.88rem;color:var(--g500)}
/* TOAST */
.tw{position:fixed;top:1.5rem;right:1.5rem;z-index:600;display:flex;flex-direction:column;gap:8px}
.tst{display:flex;align-items:center;gap:8px;padding:10px 16px;border-radius:var(--r2);color:#fff;font-size:.88rem;box-shadow:var(--sh2);animation:tIn .3s ease}
.tst-ok{background:var(--ok)}.tst-er{background:var(--er)}
@keyframes tIn{from{opacity:0;transform:translateX(110%)}to{opacity:1;transform:translateX(0)}}
@media(max-width:768px){.s-links{display:none}}
</style>
</head>
<body>
<div class="tw" id="tw"></div>

<!-- NAVBAR -->
<nav class="snav">
  <div class="snav-in">
    <a href="<%= ctx %>/" class="s-brand"><i class="fas fa-umbrella-beach"></i> Ocean View Resort</a>
    <div class="s-links">
      <a href="<%= ctx %>/">Home</a>
      <a href="<%= ctx %>/rooms">Browse Rooms</a>
      <a href="<%= ctx %>/guest/search-rooms" class="act">Search</a>
      <% if("ADMIN".equals(navRole)){%><a href="<%= ctx %>/admin/dashboard">Admin</a>
      <%}else if("STAFF".equals(navRole)){%><a href="<%= ctx %>/staff/dashboard">Staff</a>
      <%}else{%><a href="<%= ctx %>/guest/dashboard">My Account</a><%}%>
    </div>
    <div class="s-right">
      <div class="s-avatar"><%= navInit %></div>
      <span><%= esc(navFirst) %></span>
      <button class="s-logout" onclick="window.location='<%= ctx %>/logout'"><i class="fas fa-sign-out-alt"></i> Logout</button>
    </div>
  </div>
</nav>

<!-- HERO -->
<div class="sr-hero">
  <h1><i class="fas fa-search" style="font-size:1.8rem;color:var(--gold)"></i> Search Rooms</h1>
  <p>Find the perfect room for your stay at Ocean View Resort</p>
</div>

<div class="sr-wrap">
<div class="sr-layout">

<!-- ═══ FILTER PANEL ═══ -->
<aside class="filter-panel">
  <div class="fp-hdr">
    <h3><i class="fas fa-sliders-h"></i> Search Filters</h3>
    <button onclick="resetFilters()" style="background:rgba(255,255,255,.15);border:none;color:#fff;padding:3px 10px;border-radius:4px;cursor:pointer;font-size:.78rem">Reset</button>
  </div>
  <div class="fp-body">
    <form id="searchForm" action="<%= ctx %>/rooms" method="get">
      <div class="fp-section">
        <h4><i class="fas fa-calendar-alt"></i> Dates</h4>
        <div class="fp-field">
          <label>Check-in Date</label>
          <input type="date" id="checkIn" name="checkIn" value="<%= esc(checkIn) %>">
        </div>
        <div class="fp-field">
          <label>Check-out Date</label>
          <input type="date" id="checkOut" name="checkOut" value="<%= esc(checkOut) %>">
        </div>
      </div>
      <div class="fp-section">
        <h4><i class="fas fa-users"></i> Guests</h4>
        <div class="fp-field">
          <label>Number of Guests</label>
          <select name="guests">
            <option value="1" <%="1".equals(guests)?"selected":""%>>1 Guest</option>
            <option value="2" <%=("2".equals(guests)||guests.isEmpty())?"selected":""%>>2 Guests</option>
            <option value="3" <%="3".equals(guests)?"selected":""%>>3 Guests</option>
            <option value="4" <%="4".equals(guests)?"selected":""%>>4 Guests</option>
            <option value="5" <%="5".equals(guests)?"selected":""%>>5+ Guests</option>
          </select>
        </div>
      </div>
      <div class="fp-section">
        <h4><i class="fas fa-bed"></i> Room Type</h4>
        <label class="type-chk"><input type="radio" name="type" value="" <%=typeFilter.isEmpty()?"checked":""%>> All Types</label>
        <label class="type-chk"><input type="radio" name="type" value="SINGLE"  <%="SINGLE".equals(typeFilter)?"checked":""%>> Single Room</label>
        <label class="type-chk"><input type="radio" name="type" value="DOUBLE"  <%="DOUBLE".equals(typeFilter)?"checked":""%>> Double Room</label>
        <label class="type-chk"><input type="radio" name="type" value="DELUXE"  <%="DELUXE".equals(typeFilter)?"checked":""%>> Deluxe Room</label>
        <label class="type-chk"><input type="radio" name="type" value="SUITE"   <%="SUITE".equals(typeFilter)?"checked":""%>> Luxury Suite</label>
        <label class="type-chk"><input type="radio" name="type" value="FAMILY"  <%="FAMILY".equals(typeFilter)?"checked":""%>> Family Room</label>
      </div>
      <div class="fp-section">
        <h4><i class="fas fa-rupee-sign"></i> Price Range (Rs. / night)</h4>
        <div class="fp-field">
          <label>Min Price</label>
          <input type="number" name="minPrice" value="<%= esc(minPrice) %>" placeholder="0" min="0" step="500">
        </div>
        <div class="fp-field">
          <label>Max Price</label>
          <input type="number" name="maxPrice" value="<%= esc(maxPrice) %>" placeholder="Any" min="0" step="500">
        </div>
      </div>
      <button type="submit" class="btn-apply"><i class="fas fa-search"></i> Apply Filters</button>
      <button type="button" class="btn-reset" onclick="resetFilters()"><i class="fas fa-undo"></i> Reset All</button>
    </form>
  </div>
</aside>

<!-- ═══ RESULTS PANEL ═══ -->
<div>
  <% if(flashOk!=null&&!flashOk.isEmpty()){%><div class="s-alert s-ok"><i class="fas fa-check-circle"></i> <%=esc(flashOk)%></div><%}%>
  <% if(flashErr!=null&&!flashErr.isEmpty()){%><div class="s-alert s-er"><i class="fas fa-exclamation-circle"></i> <%=esc(flashErr)%></div><%}%>

  <div class="results-hdr">
    <div>
      <h2><i class="fas fa-hotel" style="color:var(--pri)"></i> Available Rooms</h2>
      <span class="results-count"><strong><%= roomList.size() %></strong> room<%= roomList.size()!=1?"s":"" %> found</span>
    </div>
    <div class="sort-bar">
      <i class="fas fa-sort"></i> Sort:
      <select id="sortSel" onchange="sortCards(this.value)">
        <option value="default">Default</option>
        <option value="price-asc">Price &#8593;</option>
        <option value="price-desc">Price &#8595;</option>
        <option value="cap-asc">Capacity &#8593;</option>
        <option value="cap-desc">Capacity &#8595;</option>
      </select>
    </div>
  </div>

  <% if(roomList.isEmpty()){ %>
  <div class="empty-s">
    <i class="fas fa-bed"></i>
    <h3>No Rooms Found</h3>
    <p><%= (!checkIn.isEmpty()) ? "No rooms available for your selected dates. Try different dates or adjust filters." : "No rooms match your search criteria. Try adjusting or resetting your filters." %></p>
  </div>
  <% } else { %>
  <div class="sr-grid" id="srGrid">
  <% for(Room rm : roomList) {
       String rType   = rm.getRoomType()!=null  ? rm.getRoomType().name()  : "SINGLE";
       String rStatus = rm.getStatus()!=null     ? rm.getStatus().name()    : "AVAILABLE";
       String rNum    = rm.getRoomNumber()!=null ? rm.getRoomNumber()        : "—";
       String rFloor  = rm.getFloor()!=null      ? rm.getFloor().toString() : "—";
       String rCap    = rm.getCapacity()!=null   ? rm.getCapacity().toString() : "2";
       String rSize   = rm.getSize()!=null && rm.getSize()>0 ? rm.getSize()+" m²" : "—";
       String rPrice  = rm.getPricePerNight()!=null ? String.format("%,.0f", rm.getPricePerNight().doubleValue()) : "0";
       double rPriceD = rm.getPricePerNight()!=null ? rm.getPricePerNight().doubleValue() : 0;
       String rDesc   = (rm.getDescription()!=null&&!rm.getDescription().isEmpty()) ? rm.getDescription() : roomDescShort(rType);
       String rAmen   = (rm.getAmenities()!=null&&!rm.getAmenities().isEmpty()) ? rm.getAmenities() : "Free WiFi,Air Conditioning,Smart TV";
       String rImgSrc = ctx+"/assets/images/rooms/"+rType.toLowerCase()+".jpg";
       boolean avail  = rm.isAvailable();
       int rId        = rm.getRoomId()!=null ? rm.getRoomId() : 0;
       String statusClass = "AVAILABLE".equals(rStatus)?"ss-avail":"OCCUPIED".equals(rStatus)?"ss-occup":"RESERVED".equals(rStatus)?"ss-reserv":"ss-maint";
       String bookUrl = ctx+"/reservation?action=new&roomId="+rId
                        +(!checkIn.isEmpty()?"&checkIn="+checkIn:"")
                        +(!checkOut.isEmpty()?"&checkOut="+checkOut:"")
                        +"&guests="+guests;
  %>
  <div class="sr-card"
       data-price="<%= rPriceD %>"
       data-capacity="<%= rm.getCapacity()!=null?rm.getCapacity():0 %>"
       data-type="<%= rType %>">
    <div class="sr-img">
      <img src="<%= rImgSrc %>" alt="<%= esc(roomLbl(rType)) %>"
           onerror="this.style.display='none';this.nextElementSibling.style.display='flex'">
      <div class="sr-img-ph" style="display:none"><i class="fas fa-bed"></i><span><%= rType.toLowerCase() %></span></div>
      <span class="sr-status <%= statusClass %>">
        <i class="fas fa-<%= "AVAILABLE".equals(rStatus)?"check-circle":"OCCUPIED".equals(rStatus)?"times-circle":"RESERVED".equals(rStatus)?"clock":"tools" %>"></i>
        <%= rStatus.replace("_"," ") %>
      </span>
      <span class="sr-type"><%= rType %></span>
    </div>
    <div class="sr-body">
      <div>
        <div class="sr-name"><%= roomLbl(rType) %></div>
        <div class="sr-num">Room <%= esc(rNum) %> &bull; Floor <%= rFloor %></div>
      </div>
      <p class="sr-desc"><%= esc(rDesc) %></p>
      <div class="sr-feats">
        <span class="sr-feat"><i class="fas fa-users"></i> <%= rCap %> guests</span>
        <span class="sr-feat"><i class="fas fa-ruler-combined"></i> <%= rSize %></span>
        <span class="sr-feat"><i class="fas fa-layer-group"></i> Floor <%= rFloor %></span>
      </div>
    </div>
    <div class="sr-footer">
      <div>
        <div class="sr-price-amt">Rs. <%= rPrice %></div>
        <div class="sr-price-lbl">per night</div>
      </div>
      <% if(avail) { %>
      <a href="<%= bookUrl %>" class="btn-sr-book"><i class="fas fa-calendar-check"></i> Book Now</a>
      <% } else { %>
      <button class="btn-sr-unavail" disabled><i class="fas fa-ban"></i> Unavailable</button>
      <% } %>
    </div>
  </div>
  <% } %>
  </div>
  <% } %>
</div><!-- /results -->
</div><!-- /layout -->
</div><!-- /wrap -->

<footer style="background:#003d5c;color:rgba(255,255,255,.7);text-align:center;padding:20px;font-size:.85rem;margin-top:40px">
  &copy; <%= java.time.Year.now().getValue() %> Ocean View Resort. All rights reserved.
</footer>

<script>
(function(){
'use strict';
var ctx = '<%= ctx %>';

/* ── DATE SETUP ── */
var today = new Date().toISOString().split('T')[0];
var ciEl  = document.getElementById('checkIn');
var coEl  = document.getElementById('checkOut');
if(ciEl){ ciEl.min = today; }
if(coEl){ coEl.min = today; }
if(ciEl && coEl){
    ciEl.addEventListener('change', function(){
        var nxt = new Date(this.value); nxt.setDate(nxt.getDate()+1);
        coEl.min = nxt.toISOString().split('T')[0];
        if(coEl.value && coEl.value <= this.value) coEl.value = coEl.min;
    });
}

/* ── FORM VALIDATE ── */
document.getElementById('searchForm').addEventListener('submit', function(e){
    var ci = ciEl ? ciEl.value : '';
    var co = coEl ? coEl.value : '';
    if(ci && co && new Date(co) <= new Date(ci)){
        e.preventDefault();
        showToast('Check-out date must be after check-in date.','er');
        return false;
    }
});

/* ── RESET FILTERS ── */
window.resetFilters = function(){
    window.location.href = ctx + '/guest/search-rooms';
};

/* ── SORT CARDS ── */
window.sortCards = function(by){
    var grid  = document.getElementById('srGrid');
    if(!grid) return;
    var cards = Array.prototype.slice.call(grid.querySelectorAll('.sr-card'));
    cards.sort(function(a,b){
        var pA=parseFloat(a.dataset.price||0), pB=parseFloat(b.dataset.price||0);
        var cA=parseInt(a.dataset.capacity||0), cB=parseInt(b.dataset.capacity||0);
        if(by==='price-asc')  return pA-pB;
        if(by==='price-desc') return pB-pA;
        if(by==='cap-asc')    return cA-cB;
        if(by==='cap-desc')   return cB-cA;
        return 0;
    });
    cards.forEach(function(c){ grid.appendChild(c); });
};

/* ── TOAST ── */
function showToast(msg, type){
    var tw = document.getElementById('tw');
    var t  = document.createElement('div');
    t.className = 'tst tst-'+(type==='ok'?'ok':'er');
    t.innerHTML = '<i class="fas fa-'+(type==='ok'?'check-circle':'exclamation-circle')+'"></i> '+msg+
        ' <button onclick="this.parentNode.remove()" style="background:none;border:none;color:#fff;margin-left:auto;font-size:1.1rem;cursor:pointer">&times;</button>';
    tw.appendChild(t);
    setTimeout(function(){ if(t.parentNode){t.style.opacity='0';t.style.transition='.4s';setTimeout(function(){t.remove();},400);} },5000);
}

})();
</script>
</body>
</html>
