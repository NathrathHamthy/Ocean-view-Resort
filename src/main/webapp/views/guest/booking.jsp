<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="com.oceanview.model.User, com.oceanview.model.Room, com.oceanview.model.Reservation, com.oceanview.util.Constants, java.time.LocalDate, java.time.format.DateTimeFormatter, java.time.temporal.ChronoUnit, java.math.BigDecimal, java.math.RoundingMode" %>
<%!
    private String esc(String s){ if(s==null)return ""; return s.replace("&","&amp;").replace("<","&lt;").replace(">","&gt;").replace("\"","&quot;"); }
    private String fmt(BigDecimal v){ if(v==null)return "0.00"; return String.format("%,.2f",v.doubleValue()); }
    private String roomLbl(String t){
        if(t==null)return "Room";
        switch(t){
            case "SINGLE": return "Standard Single Room";
            case "DOUBLE": return "Double Room";
            case "DELUXE": return "Deluxe Room";
            case "SUITE":  return "Luxury Suite";
            case "FAMILY": return "Family Room";
            default: return t.charAt(0)+t.substring(1).toLowerCase()+" Room";
        }
    }
%>
<%
    User cu = (User) session.getAttribute(Constants.SESSION_USER);
    if(cu==null) cu=(User)session.getAttribute("loggedInUser");
    if(cu==null){ response.sendRedirect(request.getContextPath()+"/login"); return; }

    String ctx = request.getContextPath();
    String navFirst = (cu.getFirstName()!=null&&!cu.getFirstName().isEmpty()) ? cu.getFirstName() : cu.getUsername();
    String navInit  = (navFirst!=null&&!navFirst.isEmpty()) ? String.valueOf(navFirst.charAt(0)).toUpperCase() : "G";

    // Room and dates from servlet attributes / request params
    Room room = (Room) request.getAttribute("room");
    String roomIdParam  = request.getParameter("roomId");
    String checkInParam  = request.getParameter("checkIn")  != null ? request.getParameter("checkIn")  : "";
    String checkOutParam = request.getParameter("checkOut") != null ? request.getParameter("checkOut") : "";
    String guestsParam   = request.getParameter("guests")   != null ? request.getParameter("guests")   : "2";

    LocalDate checkInDate  = null;
    LocalDate checkOutDate = null;
    try { if(!checkInParam.isEmpty())  checkInDate  = LocalDate.parse(checkInParam);  } catch(Exception e){}
    try { if(!checkOutParam.isEmpty()) checkOutDate = LocalDate.parse(checkOutParam); } catch(Exception e){}

    DateTimeFormatter dtf = DateTimeFormatter.ofPattern("dd MMM yyyy");
    String checkInDisp  = checkInDate  != null ? checkInDate.format(dtf)  : "";
    String checkOutDisp = checkOutDate != null ? checkOutDate.format(dtf) : "";
    long numNights = (checkInDate!=null&&checkOutDate!=null&&checkOutDate.isAfter(checkInDate))
                     ? ChronoUnit.DAYS.between(checkInDate,checkOutDate) : 0;

    // Price calculations
    BigDecimal pricePerNight = (room!=null&&room.getPricePerNight()!=null) ? room.getPricePerNight() : BigDecimal.ZERO;
    BigDecimal baseAmount    = pricePerNight.multiply(BigDecimal.valueOf(numNights));
    BigDecimal taxRate       = new BigDecimal("0.10");   // 10%
    BigDecimal svcRate       = new BigDecimal("0.05");   // 5%
    BigDecimal taxAmount     = baseAmount.multiply(taxRate).setScale(2,RoundingMode.HALF_UP);
    BigDecimal svcAmount     = baseAmount.multiply(svcRate).setScale(2,RoundingMode.HALF_UP);
    BigDecimal totalAmount   = baseAmount.add(taxAmount).add(svcAmount);

    // Room info
    String rType   = (room!=null&&room.getRoomType()!=null)   ? room.getRoomType().name()   : "";
    String rNum    = (room!=null&&room.getRoomNumber()!=null)  ? room.getRoomNumber()         : "";
    String rFloor  = (room!=null&&room.getFloor()!=null)       ? room.getFloor().toString()   : "—";
    String rCap    = (room!=null&&room.getCapacity()!=null)    ? room.getCapacity().toString(): "2";
    String rDesc   = (room!=null&&room.getDescription()!=null) ? room.getDescription()        : "";
    String rAmen   = (room!=null&&room.getAmenities()!=null)   ? room.getAmenities()          : "Free WiFi,Air Conditioning,Smart TV,Room Service";
    String rImgSrc = ctx+"/assets/images/rooms/"+(rType.isEmpty()?"single":rType.toLowerCase())+".jpg";
    int    rId     = (room!=null&&room.getRoomId()!=null)      ? room.getRoomId()             : 0;

    // Guest info pre-populated
    String guestName  = cu.getFullName()!=null ? cu.getFullName() : cu.getUsername();
    String guestEmail = cu.getEmail()!=null    ? cu.getEmail()    : "";
    String guestPhone = cu.getPhone()!=null    ? cu.getPhone()    : "";

    // Flash messages
    String flashOk  = (String) session.getAttribute(Constants.ATTR_SUCCESS);
    String flashErr = (String) session.getAttribute(Constants.ATTR_ERROR);
    if(flashOk==null)  flashOk  = (String) request.getAttribute(Constants.ATTR_SUCCESS);
    if(flashErr==null) flashErr = (String) request.getAttribute(Constants.ATTR_ERROR);
    session.removeAttribute(Constants.ATTR_SUCCESS);
    session.removeAttribute(Constants.ATTR_ERROR);

    boolean canBook = (room!=null && room.isAvailable() && numNights>0);
%>
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1.0">
<title>Book Room - Ocean View Resort</title>
<link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
<style>
:root{
  --pri:#006994;--pri-dk:#004f70;--acc:#4A90A4;--gold:#D4AF37;
  --ok:#28a745;--er:#dc3545;--warn:#ffc107;--inf:#17a2b8;
  --g50:#f8f9fa;--g100:#f1f3f5;--g200:#e9ecef;--g300:#dee2e6;
  --g500:#6c757d;--g700:#495057;--g800:#343a40;--wh:#fff;
  --sh1:0 2px 8px rgba(0,0,0,.08);--sh2:0 6px 20px rgba(0,0,0,.12);--sh3:0 12px 40px rgba(0,0,0,.15);
  --r:.75rem;--r2:.4rem;--tr:.22s ease;
}
*,*::before,*::after{box-sizing:border-box;margin:0;padding:0}
body{font-family:'Segoe UI',system-ui,sans-serif;background:#eef2f7;color:var(--g800);min-height:100vh}
a{text-decoration:none;color:inherit}
/* NAV */
.bnav{background:var(--pri-dk);position:sticky;top:0;z-index:200;box-shadow:0 2px 10px rgba(0,0,0,.2)}
.bnav-in{max-width:1280px;margin:0 auto;padding:0 24px;height:62px;display:flex;align-items:center;justify-content:space-between}
.b-brand{display:flex;align-items:center;gap:10px;color:#fff;font-weight:700;font-size:1.05rem}
.b-brand i{color:var(--gold)}
.b-links{display:flex;align-items:center;gap:4px}
.b-links a{color:rgba(255,255,255,.82);padding:6px 13px;border-radius:var(--r2);font-size:.88rem;transition:var(--tr)}
.b-links a:hover,.b-links a.act{background:rgba(255,255,255,.15);color:#fff}
.b-right{display:flex;align-items:center;gap:10px;color:rgba(255,255,255,.9);font-size:.88rem}
.b-avatar{width:34px;height:34px;border-radius:50%;background:var(--gold);color:var(--pri-dk);display:flex;align-items:center;justify-content:center;font-weight:700;font-size:.82rem}
/* BREADCRUMB */
.breadcrumb{max-width:1280px;margin:0 auto;padding:14px 24px;font-size:.85rem;color:var(--g500);display:flex;align-items:center;gap:6px}
.breadcrumb a{color:var(--pri)}.breadcrumb a:hover{text-decoration:underline}
.breadcrumb i{font-size:.7rem;color:var(--g300)}
/* HERO */
.book-hero{background:linear-gradient(135deg,#003d5c,var(--pri),var(--acc));padding:32px 24px 32px;color:#fff;text-align:center}
.book-hero h1{font-size:2rem;font-weight:800;margin-bottom:6px}
.book-hero p{font-size:.95rem;opacity:.85}
/* PROGRESS STEPS */
.steps{display:flex;justify-content:center;gap:0;margin:28px 0 0}
.step{display:flex;align-items:center;gap:8px;padding:8px 18px;font-size:.85rem;font-weight:600;color:rgba(255,255,255,.6)}
.step.active{color:#fff}
.step-num{width:28px;height:28px;border-radius:50%;border:2px solid rgba(255,255,255,.4);display:flex;align-items:center;justify-content:center;font-size:.8rem}
.step.active .step-num{background:#fff;color:var(--pri);border-color:#fff}
.step.done .step-num{background:var(--gold);border-color:var(--gold);color:#fff}
.step-div{width:40px;height:2px;background:rgba(255,255,255,.25)}
/* BODY */
.book-body{max-width:1280px;margin:0 auto;padding:28px 24px 60px;display:grid;grid-template-columns:1fr 380px;gap:28px;align-items:start}
@media(max-width:960px){.book-body{grid-template-columns:1fr}}
/* CARDS */
.bk-card{background:var(--wh);border-radius:var(--r);box-shadow:var(--sh1);margin-bottom:20px;overflow:hidden}
.bk-card-hdr{padding:14px 20px;border-bottom:1px solid var(--g200);display:flex;align-items:center;gap:10px;background:var(--g50)}
.bk-card-hdr h2{font-size:.95rem;font-weight:700;color:var(--g700);display:flex;align-items:center;gap:8px}
.bk-card-hdr h2 i{color:var(--pri)}
.bk-card-body{padding:20px}
/* FORM */
.fg{display:grid;grid-template-columns:1fr 1fr;gap:14px}
@media(max-width:640px){.fg{grid-template-columns:1fr}}
.fi{display:flex;flex-direction:column;gap:5px}
.fi.fw{grid-column:1/-1}
.fl{font-size:.8rem;font-weight:600;color:var(--g700);text-transform:uppercase;letter-spacing:.04em}
.fl .req{color:var(--er)}
.fc{padding:10px 12px;border:1.5px solid var(--g300);border-radius:var(--r2);font-size:.9rem;color:var(--g800);background:var(--wh);outline:none;transition:border var(--tr),box-shadow var(--tr);width:100%;font-family:inherit}
.fc:focus{border-color:var(--pri);box-shadow:0 0 0 3px rgba(0,105,148,.1)}
.fc[readonly]{background:var(--g50);color:var(--g500);cursor:not-allowed}
.fc-err{border-color:var(--er)!important;box-shadow:0 0 0 3px rgba(220,53,69,.1)!important}
.err-msg{font-size:.75rem;color:var(--er);margin-top:2px;display:none}
/* DATE ROW */
.date-info{background:var(--g50);border:1px solid var(--g200);border-radius:var(--r2);padding:10px 14px;font-size:.88rem;color:var(--pri);display:flex;align-items:center;gap:8px;flex-wrap:wrap;margin-top:4px}
.date-info strong{color:var(--pri-dk)}
/* PAYMENT METHOD */
.pay-opts{display:flex;flex-direction:column;gap:10px;margin-top:6px}
.pay-opt{display:flex;align-items:center;gap:12px;padding:12px 16px;border:1.5px solid var(--g200);border-radius:var(--r2);cursor:pointer;transition:var(--tr)}
.pay-opt:hover{border-color:var(--pri);background:rgba(0,105,148,.03)}
.pay-opt.selected{border-color:var(--pri);background:rgba(0,105,148,.06)}
.pay-opt input[type="radio"]{accent-color:var(--pri);width:16px;height:16px;flex-shrink:0}
.pay-icon{width:38px;height:28px;background:var(--g100);border-radius:4px;display:flex;align-items:center;justify-content:center;font-size:.85rem;color:var(--pri)}
.pay-lbl{font-size:.88rem;font-weight:600;color:var(--g800);flex:1}
.pay-sub{font-size:.75rem;color:var(--g500);margin-top:1px}
/* PROMO */
.promo-row{display:flex;gap:8px;margin-top:4px}
.promo-row input{flex:1;padding:9px 12px;border:1.5px solid var(--g300);border-radius:var(--r2);font-size:.88rem;outline:none;transition:border var(--tr)}
.promo-row input:focus{border-color:var(--pri);box-shadow:0 0 0 3px rgba(0,105,148,.1)}
.btn-promo{padding:9px 16px;background:var(--g200);border:none;border-radius:var(--r2);font-size:.85rem;font-weight:600;cursor:pointer;color:var(--g700);transition:var(--tr);white-space:nowrap}
.btn-promo:hover{background:var(--pri);color:#fff}
.promo-result{font-size:.8rem;margin-top:5px;padding:6px 10px;border-radius:var(--r2);display:none}
.promo-ok{background:#D4EDDA;color:#155724;display:flex!important;align-items:center;gap:6px}
.promo-er{background:#F8D7DA;color:#721C24;display:flex!important;align-items:center;gap:6px}
/* TERMS */
.terms-row{display:flex;align-items:flex-start;gap:10px;padding:14px 0;border-top:1px solid var(--g100);margin-top:6px}
.terms-row input[type="checkbox"]{accent-color:var(--pri);width:16px;height:16px;margin-top:2px;flex-shrink:0}
.terms-row label{font-size:.85rem;color:var(--g700);cursor:pointer}
.terms-row label a{color:var(--pri);text-decoration:underline}
/* SUBMIT BTN */
.btn-submit{width:100%;padding:14px;background:linear-gradient(135deg,var(--pri),var(--pri-dk));color:#fff;border:none;border-radius:var(--r2);font-size:1rem;font-weight:700;cursor:pointer;transition:var(--tr);display:flex;align-items:center;justify-content:center;gap:10px;margin-top:8px}
.btn-submit:hover:not(:disabled){transform:translateY(-1px);box-shadow:0 6px 16px rgba(0,105,148,.35)}
.btn-submit:disabled{opacity:.55;cursor:not-allowed;transform:none}
/* SUMMARY CARD */
.sum-card{background:var(--wh);border-radius:var(--r);box-shadow:var(--sh2);overflow:hidden;position:sticky;top:80px}
.sum-img{height:180px;position:relative}
.sum-img img{width:100%;height:100%;object-fit:cover}
.sum-img-ph{width:100%;height:100%;background:linear-gradient(135deg,#e8f4f8,#d4e8f0);display:flex;align-items:center;justify-content:center;color:var(--pri);font-size:3rem;opacity:.4}
.sum-type{position:absolute;top:12px;left:12px;background:var(--pri);color:#fff;padding:4px 12px;border-radius:999px;font-size:.75rem;font-weight:700}
.sum-body{padding:18px}
.sum-title{font-size:1.05rem;font-weight:700;color:var(--g800);margin-bottom:2px}
.sum-num{font-size:.8rem;color:var(--g500)}
.sum-divider{height:1px;background:var(--g100);margin:12px 0}
.sum-row{display:flex;justify-content:space-between;align-items:center;padding:4px 0;font-size:.88rem}
.sum-lbl{color:var(--g500)}
.sum-val{font-weight:600;color:var(--g800)}
.sum-row.total{font-size:1.05rem;padding-top:10px;border-top:2px solid var(--g200);margin-top:8px}
.sum-row.total .sum-lbl{color:var(--g700);font-weight:700}
.sum-row.total .sum-val{color:var(--pri);font-size:1.15rem}
.sum-nights{background:var(--g50);border-radius:var(--r2);padding:10px 14px;margin-bottom:10px;text-align:center;font-size:.88rem;color:var(--g700)}
.sum-nights strong{color:var(--pri);font-size:1.1rem}
.discount-row{color:var(--ok);font-size:.85rem}
.badge-avail{display:inline-flex;align-items:center;gap:5px;padding:4px 10px;background:#D4EDDA;color:#155724;border-radius:999px;font-size:.75rem;font-weight:700;margin-top:8px}
.badge-unavail{display:inline-flex;align-items:center;gap:5px;padding:4px 10px;background:#F8D7DA;color:#721C24;border-radius:999px;font-size:.75rem;font-weight:700;margin-top:8px}
/* ALERTS */
.alert{padding:12px 18px;border-radius:var(--r2);margin-bottom:18px;display:flex;align-items:center;gap:10px;font-size:.9rem}
.alert-ok{background:#D4EDDA;color:#155724;border-left:4px solid var(--ok)}
.alert-er{background:#F8D7DA;color:#721C24;border-left:4px solid var(--er)}
/* MODAL */
.modal-bg{display:none;position:fixed;inset:0;background:rgba(0,0,0,.55);z-index:500;align-items:center;justify-content:center;padding:16px}
.modal-bg.open{display:flex}
.modal-box{background:var(--wh);border-radius:var(--r);max-width:500px;width:100%;padding:28px;box-shadow:var(--sh3);position:relative}
.modal-close{position:absolute;top:14px;right:16px;background:none;border:none;font-size:1.5rem;cursor:pointer;color:var(--g500);line-height:1}
.modal-close:hover{color:var(--er)}
.modal-icon{width:56px;height:56px;border-radius:50%;display:flex;align-items:center;justify-content:center;font-size:1.5rem;margin:0 auto 16px}
.modal-ok-icon{background:#D4EDDA;color:var(--ok)}
.modal-er-icon{background:#F8D7DA;color:var(--er)}
.modal-title{font-size:1.15rem;font-weight:700;color:var(--g800);text-align:center;margin-bottom:8px}
.modal-msg{font-size:.9rem;color:var(--g600);text-align:center;line-height:1.5;margin-bottom:20px}
.modal-actions{display:flex;gap:10px;justify-content:center}
/* TOAST */
.tw-cont{position:fixed;top:1.5rem;right:1.5rem;z-index:600;display:flex;flex-direction:column;gap:8px}
.tst{display:flex;align-items:center;gap:8px;padding:10px 16px;border-radius:var(--r2);color:#fff;font-size:.88rem;font-weight:500;box-shadow:var(--sh2);animation:tIn .3s ease;min-width:260px}
.tst-ok{background:var(--ok)}.tst-er{background:var(--er)}
@keyframes tIn{from{opacity:0;transform:translateX(110%)}to{opacity:1;transform:translateX(0)}}
.btn{display:inline-flex;align-items:center;gap:6px;padding:9px 20px;border-radius:var(--r2);font-size:.88rem;font-weight:600;cursor:pointer;border:none;transition:var(--tr)}
.btn-pri{background:var(--pri);color:#fff}.btn-pri:hover{background:var(--pri-dk)}
.btn-sec{background:var(--g200);color:var(--g800)}.btn-sec:hover{background:var(--g300)}
@media(max-width:768px){.b-links{display:none}.book-hero h1{font-size:1.6rem}}
</style>
</head>
<body>
<div class="tw-cont" id="twCont"></div>

<!-- NAVBAR -->
<nav class="bnav">
  <div class="bnav-in">
    <a href="<%= ctx %>/" class="b-brand"><i class="fas fa-umbrella-beach"></i> Ocean View Resort</a>
    <div class="b-links">
      <a href="<%= ctx %>/">Home</a>
      <a href="<%= ctx %>/rooms">Rooms</a>
      <a href="<%= ctx %>/reservation" class="act">My Reservations</a>
      <a href="<%= ctx %>/guest/dashboard">Dashboard</a>
    </div>
    <div class="b-right">
      <div class="b-avatar"><%= navInit %></div>
      <span><%= esc(navFirst) %></span>
      <a href="<%= ctx %>/logout" style="background:rgba(255,255,255,.1);color:rgba(255,255,255,.85);border:none;padding:5px 12px;border-radius:var(--r2);font-size:.85rem;cursor:pointer;transition:var(--tr)">
        <i class="fas fa-sign-out-alt"></i> Logout
      </a>
    </div>
  </div>
</nav>

<!-- BREADCRUMB -->
<div class="breadcrumb">
  <a href="<%= ctx %>/">Home</a>
  <i class="fas fa-chevron-right"></i>
  <a href="<%= ctx %>/rooms">Rooms</a>
  <i class="fas fa-chevron-right"></i>
  <span>Book Room</span>
</div>

<!-- HERO -->
<div class="book-hero">
  <h1><i class="fas fa-calendar-check"></i> Complete Your Booking</h1>
  <p>Fill in the details below to confirm your reservation</p>
  <div class="steps">
    <div class="step done"><div class="step-num"><i class="fas fa-check"></i></div><span>Choose Room</span></div>
    <div class="step-div"></div>
    <div class="step active"><div class="step-num">2</div><span>Book Now</span></div>
    <div class="step-div"></div>
    <div class="step"><div class="step-num">3</div><span>Confirm</span></div>
  </div>
</div>

<!-- BODY -->
<div class="book-body">

<!-- LEFT: FORM -->
<div class="book-form-col">

<% if(flashOk!=null&&!flashOk.isEmpty()){ %>
<div class="alert alert-ok"><i class="fas fa-check-circle"></i> <%= esc(flashOk) %></div>
<% } %>
<% if(flashErr!=null&&!flashErr.isEmpty()){ %>
<div class="alert alert-er"><i class="fas fa-exclamation-circle"></i> <%= esc(flashErr) %></div>
<% } %>

<% if(room==null){ %>
<div class="bk-card">
  <div class="bk-card-body" style="text-align:center;padding:40px">
    <i class="fas fa-exclamation-triangle" style="font-size:3rem;color:var(--warn);margin-bottom:16px;display:block"></i>
    <h2 style="margin-bottom:8px;color:var(--g800)">No Room Selected</h2>
    <p style="color:var(--g500);margin-bottom:20px;font-size:.9rem">Please select a room first before proceeding to booking.</p>
    <a href="<%= ctx %>/rooms" class="btn btn-pri"><i class="fas fa-bed"></i> Browse Rooms</a>
  </div>
</div>
<% } else { %>

<form id="bookingForm" action="<%= ctx %>/reservation" method="post" onsubmit="return validateAndSubmit(event)">
  <input type="hidden" name="action"  value="create">
  <input type="hidden" name="roomId"  value="<%= rId %>">
  <input type="hidden" name="checkIn"  id="hCheckIn"  value="<%= esc(checkInParam) %>">
  <input type="hidden" name="checkOut" id="hCheckOut" value="<%= esc(checkOutParam) %>">
  <input type="hidden" name="promoCode" id="hPromoCode" value="">
  <input type="hidden" name="discountPct" id="hDiscountPct" value="0">
  <input type="hidden" name="discountFixed" id="hDiscountFixed" value="0">
  <input type="hidden" name="paymentMethod" id="hPayMethod" value="CREDIT_CARD">

  <!-- STAY DETAILS -->
  <div class="bk-card">
    <div class="bk-card-hdr"><h2><i class="fas fa-calendar-alt"></i> Stay Details</h2></div>
    <div class="bk-card-body">
      <div class="fg">
        <div class="fi">
          <label class="fl">Check-in Date <span class="req">*</span></label>
          <input type="date" class="fc" id="checkInVis" value="<%= esc(checkInParam) %>" onchange="updateDates()">
          <span class="err-msg" id="errCI">Please select check-in date.</span>
        </div>
        <div class="fi">
          <label class="fl">Check-out Date <span class="req">*</span></label>
          <input type="date" class="fc" id="checkOutVis" value="<%= esc(checkOutParam) %>" onchange="updateDates()">
          <span class="err-msg" id="errCO">Check-out must be after check-in.</span>
        </div>
        <div class="fi">
          <label class="fl">Number of Guests <span class="req">*</span></label>
          <select class="fc" id="guestsVis" name="numberOfGuests">
            <% for(int g=1;g<=Integer.parseInt(rCap.isEmpty()?"4":rCap);g++) { %>
            <option value="<%= g %>" <%= String.valueOf(g).equals(guestsParam)?"selected":"" %>><%= g %> Guest<%= g>1?"s":"" %></option>
            <% } %>
          </select>
        </div>
        <div class="fi">
          <label class="fl">Nights</label>
          <div class="fc" style="background:var(--g50);color:var(--g500);cursor:not-allowed" id="nightsDisplay"><%= numNights > 0 ? numNights+" night"+(numNights>1?"s":"") : "Select dates above" %></div>
        </div>
      </div>
      <% if(checkInDisp!=null&&!checkInDisp.isEmpty()&&checkOutDisp!=null&&!checkOutDisp.isEmpty()) { %>
      <div class="date-info">
        <i class="fas fa-info-circle"></i>
        <strong><%= checkInDisp %></strong> &rarr; <strong><%= checkOutDisp %></strong>
        &bull; <strong><%= numNights %></strong> night<%= numNights!=1?"s":"" %>
      </div>
      <% } %>
    </div>
  </div>

  <!-- GUEST DETAILS -->
  <div class="bk-card">
    <div class="bk-card-hdr"><h2><i class="fas fa-user"></i> Guest Information</h2></div>
    <div class="bk-card-body">
      <div class="fg">
        <div class="fi">
          <label class="fl">Full Name <span class="req">*</span></label>
          <input type="text" class="fc" name="guestName" id="guestName" value="<%= esc(guestName) %>" placeholder="Your full name" required>
          <span class="err-msg" id="errName">Full name is required.</span>
        </div>
        <div class="fi">
          <label class="fl">Email Address <span class="req">*</span></label>
          <input type="email" class="fc" name="guestEmail" id="guestEmail" value="<%= esc(guestEmail) %>" placeholder="your@email.com" required>
          <span class="err-msg" id="errEmail">Valid email is required.</span>
        </div>
        <div class="fi">
          <label class="fl">Phone Number</label>
          <input type="tel" class="fc" name="guestPhone" id="guestPhone" value="<%= esc(guestPhone) %>" placeholder="+94 XX XXX XXXX">
        </div>
        <div class="fi">
          <label class="fl">ID / Passport Number</label>
          <input type="text" class="fc" name="idNumber" placeholder="Optional — for verification">
        </div>
        <div class="fi fw">
          <label class="fl">Special Requests</label>
          <textarea class="fc" name="specialRequests" rows="3" placeholder="Any special requests, dietary needs, room preferences…" style="resize:vertical"></textarea>
        </div>
      </div>
    </div>
  </div>

  <!-- PAYMENT METHOD -->
  <div class="bk-card">
    <div class="bk-card-hdr"><h2><i class="fas fa-credit-card"></i> Payment Method</h2></div>
    <div class="bk-card-body">
      <div class="pay-opts" id="payOpts">
        <div class="pay-opt selected" onclick="selectPay(this,'CREDIT_CARD')">
          <input type="radio" name="_pm" value="CREDIT_CARD" checked>
          <div class="pay-icon"><i class="fas fa-credit-card"></i></div>
          <div><div class="pay-lbl">Credit / Debit Card</div><div class="pay-sub">Visa, MasterCard, Amex</div></div>
        </div>
        <div class="pay-opt" onclick="selectPay(this,'CASH')">
          <input type="radio" name="_pm" value="CASH">
          <div class="pay-icon"><i class="fas fa-money-bill-wave"></i></div>
          <div><div class="pay-lbl">Pay at Hotel</div><div class="pay-sub">Cash or card on arrival</div></div>
        </div>
        <div class="pay-opt" onclick="selectPay(this,'BANK_TRANSFER')">
          <input type="radio" name="_pm" value="BANK_TRANSFER">
          <div class="pay-icon"><i class="fas fa-university"></i></div>
          <div><div class="pay-lbl">Bank Transfer</div><div class="pay-sub">Direct bank payment</div></div>
        </div>
      </div>
    </div>
  </div>

  <!-- PROMO CODE -->
  <div class="bk-card">
    <div class="bk-card-hdr"><h2><i class="fas fa-tag"></i> Promo Code</h2></div>
    <div class="bk-card-body">
      <label class="fl" style="margin-bottom:6px">Have a promo code?</label>
      <div class="promo-row">
        <input type="text" id="promoInput" placeholder="Enter promo code…" style="text-transform:uppercase">
        <button type="button" class="btn-promo" onclick="applyPromo()"><i class="fas fa-tag"></i> Apply</button>
      </div>
      <div class="promo-result" id="promoResult"></div>
    </div>
  </div>

  <!-- TERMS & SUBMIT -->
  <div class="bk-card">
    <div class="bk-card-body">
      <div class="terms-row">
        <input type="checkbox" id="termsChk" required>
        <label for="termsChk">
          I agree to the <a href="<%= ctx %>/terms" target="_blank">Terms &amp; Conditions</a> and
          <a href="<%= ctx %>/cancellation" target="_blank">Cancellation Policy</a>. I confirm all details are correct.
        </label>
      </div>
      <% if(canBook) { %>
      <button type="submit" class="btn-submit" id="submitBtn">
        <i class="fas fa-lock"></i> Confirm Booking &mdash; Rs. <span id="btnTotal"><%= fmt(totalAmount) %></span>
      </button>
      <% } else if(room!=null && !room.isAvailable()) { %>
      <button type="button" class="btn-submit" disabled style="background:#dc3545">
        <i class="fas fa-ban"></i> Room Not Available
      </button>
      <% } else { %>
      <button type="button" class="btn-submit" id="submitBtn" onclick="submitIfDates()">
        <i class="fas fa-lock"></i> Confirm Booking
      </button>
      <% } %>
      <p style="text-align:center;font-size:.78rem;color:var(--g500);margin-top:10px">
        <i class="fas fa-shield-alt" style="color:var(--ok)"></i> Secure &amp; encrypted booking &bull; Free cancellation within 24 hours
      </p>
    </div>
  </div>

</form>
<% } %>
</div><!-- /book-form-col -->

<!-- RIGHT: SUMMARY CARD -->
<div class="book-sum-col">
  <div class="sum-card">
    <div class="sum-img">
      <img src="<%= rImgSrc %>" alt="<%= esc(roomLbl(rType)) %>"
           onerror="this.style.display='none';this.nextElementSibling.style.display='flex'">
      <div class="sum-img-ph" style="display:none"><i class="fas fa-bed"></i></div>
      <span class="sum-type"><%= rType %></span>
    </div>
    <div class="sum-body">
      <div class="sum-title"><%= esc(roomLbl(rType)) %></div>
      <div class="sum-num">Room <%= esc(rNum) %> &bull; Floor <%= rFloor %> &bull; Up to <%= rCap %> guests</div>
      <% if(room!=null&&room.isAvailable()) { %>
      <span class="badge-avail"><i class="fas fa-check-circle"></i> Available</span>
      <% } else if(room!=null) { %>
      <span class="badge-unavail"><i class="fas fa-times-circle"></i> Not Available</span>
      <% } %>

      <div class="sum-divider"></div>

      <% if(numNights > 0) { %>
      <div class="sum-nights">
        <strong><%= numNights %></strong> night<%= numNights!=1?"s":"" %>
        <% if(checkInDisp!=null&&!checkInDisp.isEmpty()) { %>
        &bull; <%= checkInDisp %> &rarr; <%= checkOutDisp %>
        <% } %>
      </div>
      <% } %>

      <div class="sum-row">
        <span class="sum-lbl">Rs. <%= fmt(pricePerNight) %> &times; <span id="sumNights"><%= numNights %></span> night<%= numNights!=1?"s":"" %></span>
        <span class="sum-val" id="sumBase">Rs. <%= fmt(baseAmount) %></span>
      </div>
      <div class="sum-row">
        <span class="sum-lbl">Tax (10%)</span>
        <span class="sum-val" id="sumTax">Rs. <%= fmt(taxAmount) %></span>
      </div>
      <div class="sum-row">
        <span class="sum-lbl">Service Charge (5%)</span>
        <span class="sum-val" id="sumSvc">Rs. <%= fmt(svcAmount) %></span>
      </div>
      <div class="sum-row discount-row" id="discountRow" style="display:none">
        <span class="sum-lbl">Discount</span>
        <span class="sum-val" id="sumDiscount" style="color:var(--ok)">- Rs. 0.00</span>
      </div>
      <div class="sum-row total">
        <span class="sum-lbl">Total</span>
        <span class="sum-val" id="sumTotal">Rs. <%= fmt(totalAmount) %></span>
      </div>

      <div class="sum-divider"></div>
      <div style="font-size:.78rem;color:var(--g500)">
        <p style="margin-bottom:4px"><i class="fas fa-info-circle" style="color:var(--pri)"></i> Prices include all taxes and charges</p>
        <p><i class="fas fa-undo" style="color:var(--ok)"></i> Free cancellation within 24 hours of booking</p>
      </div>

      <!-- AMENITIES -->
      <div class="sum-divider"></div>
      <div style="font-size:.8rem;font-weight:700;color:var(--g700);margin-bottom:8px;text-transform:uppercase;letter-spacing:.04em">Included Amenities</div>
      <div style="display:flex;flex-wrap:wrap;gap:6px">
        <% for(String am : rAmen.split(",")) {
             am = am.trim();
             if(!am.isEmpty()) { %>
        <span style="display:inline-flex;align-items:center;gap:4px;padding:3px 8px;background:var(--g50);border:1px solid var(--g200);border-radius:999px;font-size:.74rem;color:var(--g700)">
          <i class="fas fa-check" style="color:var(--ok)"></i> <%= esc(am) %>
        </span>
        <% } } %>
      </div>
    </div>
  </div>
</div><!-- /sum-col -->

</div><!-- /book-body -->

<!-- CONFIRM MODAL -->
<div class="modal-bg" id="confirmModal">
  <div class="modal-box">
    <button class="modal-close" onclick="closeModal('confirmModal')">&times;</button>
    <div class="modal-icon modal-ok-icon"><i class="fas fa-calendar-check"></i></div>
    <div class="modal-title">Confirm Your Booking</div>
    <div class="modal-msg" id="confirmMsg">Please review your booking details before confirming.</div>
    <div class="modal-actions">
      <button class="btn btn-sec" onclick="closeModal('confirmModal')"><i class="fas fa-arrow-left"></i> Go Back</button>
      <button class="btn btn-pri" id="finalSubmitBtn" onclick="doSubmit()"><i class="fas fa-check"></i> Confirm &amp; Book</button>
    </div>
  </div>
</div>

<script>
(function(){
'use strict';

/* ── CONSTANTS from JSP ── */
var ctx          = '<%= ctx %>';
var pricePerNight= <%= pricePerNight.doubleValue() %>;
var taxRate      = 0.10;
var svcRate      = 0.05;
var discountPct   = 0;
var discountFixed = 0;
var rId           = '<%= rId %>';

/* ── DATE SETUP ── */
var today = new Date().toISOString().split('T')[0];
var ciVis = document.getElementById('checkInVis');
var coVis = document.getElementById('checkOutVis');
if(ciVis){ ciVis.min = today; }
if(coVis){ coVis.min = today; }
if(ciVis && coVis){
    ciVis.addEventListener('change', function(){
        var nxt = new Date(this.value);
        nxt.setDate(nxt.getDate()+1);
        coVis.min = nxt.toISOString().split('T')[0];
        if(coVis.value && coVis.value <= this.value) coVis.value = coVis.min;
        updateDates();
    });
}

/* ── UPDATE DATES & PRICES ── */
window.updateDates = function(){
    var ci = ciVis ? ciVis.value : '';
    var co = coVis ? coVis.value : '';
    document.getElementById('hCheckIn').value  = ci;
    document.getElementById('hCheckOut').value = co;

    var nights = 0;
    if(ci && co){
        var d1 = new Date(ci), d2 = new Date(co);
        nights = Math.round((d2-d1)/(1000*60*60*24));
        if(nights < 0) nights = 0;
    }

    var nd = document.getElementById('nightsDisplay');
    if(nd) nd.textContent = nights > 0 ? nights+' night'+(nights>1?'s':'') : 'Select dates above';

    recalc(nights);
};

function recalc(nights){
    var base     = pricePerNight * nights;
    var tax      = base * taxRate;
    var svc      = base * svcRate;
    var disc     = (discountPct > 0) ? base * (discountPct/100) : discountFixed;
    if(disc > base) disc = base; // cap discount at base price
    var total    = base + tax + svc - disc;

    function fmt(v){ return 'Rs. '+v.toLocaleString('en-US',{minimumFractionDigits:2,maximumFractionDigits:2}); }

    var sn = document.getElementById('sumNights');
    var sb = document.getElementById('sumBase');
    var st = document.getElementById('sumTax');
    var ss = document.getElementById('sumSvc');
    var stot = document.getElementById('sumTotal');
    var sd   = document.getElementById('sumDiscount');
    var drow = document.getElementById('discountRow');
    var btot = document.getElementById('btnTotal');

    if(sn)   sn.textContent   = String(nights);
    if(sb)   sb.textContent   = fmt(base);
    if(st)   st.textContent   = fmt(tax);
    if(ss)   ss.textContent   = fmt(svc);
    if(stot) stot.textContent = fmt(total);
    if(btot) btot.textContent = total.toLocaleString('en-US',{minimumFractionDigits:2,maximumFractionDigits:2});
    if(disc > 0 && drow && sd){
        drow.style.display = '';
        sd.textContent     = '- '+fmt(disc);
    }

    // Update hidden discount
    document.getElementById('hDiscountPct').value = discountPct;
}

/* ── PAYMENT METHOD ── */
window.selectPay = function(el, method){
    document.querySelectorAll('.pay-opt').forEach(function(o){ o.classList.remove('selected'); });
    el.classList.add('selected');
    var radio = el.querySelector('input[type="radio"]');
    if(radio) radio.checked = true;
    document.getElementById('hPayMethod').value = method;
};

/* ── PROMO CODE ── */
window.applyPromo = function(){
    var code = document.getElementById('promoInput').value.trim().toUpperCase();
    var res  = document.getElementById('promoResult');
    if(!code){ showToast('Please enter a promo code.','er'); return; }

    // Validate via offer endpoint
    var ci = ciVis ? ciVis.value : '<%= checkInParam %>';
    var co = coVis ? coVis.value : '<%= checkOutParam %>';

    fetch(ctx+'/offer?action=validate&code='+encodeURIComponent(code)+'&roomId='+rId+'&checkIn='+ci+'&checkOut='+co, {
        headers:{'X-Requested-With':'XMLHttpRequest'}
    })
    .then(function(r){ return r.json(); })
    .then(function(data){
        res.className='promo-result';
        if(data.valid){
            var dtype = data.discountType || 'PERCENTAGE';
            if(dtype === 'PERCENTAGE'){
                discountPct   = parseFloat(data.discountPercentage || data.discountValue || 0);
                discountFixed = 0;
                document.getElementById('hPromoCode').value    = code;
                document.getElementById('hDiscountPct').value  = discountPct;
                document.getElementById('hDiscountFixed') && (document.getElementById('hDiscountFixed').value = 0);
                res.classList.add('promo-ok');
                res.innerHTML='<i class="fas fa-check-circle"></i> '+data.offerTitle+' — '+discountPct+'% off applied!';
                showToast('Promo code applied — '+discountPct+'% discount!','ok');
            } else {
                discountFixed = parseFloat(data.discountAmount || data.discountValue || 0);
                discountPct   = 0;
                document.getElementById('hPromoCode').value    = code;
                document.getElementById('hDiscountPct').value  = 0;
                document.getElementById('hDiscountFixed') && (document.getElementById('hDiscountFixed').value = discountFixed);
                res.classList.add('promo-ok');
                res.innerHTML='<i class="fas fa-check-circle"></i> '+data.offerTitle+' — Rs. '+discountFixed.toLocaleString()+' off applied!';
                showToast('Promo code applied — Rs. '+discountFixed.toLocaleString()+' off!','ok');
            }
            res.style.display='flex';
            // Recalculate summary
            var ci2=ciVis?ciVis.value:''; var co2=coVis?coVis.value:'';
            var n=0; if(ci2&&co2){var d1=new Date(ci2),d2=new Date(co2);n=Math.round((d2-d1)/(1000*60*60*24));if(n<0)n=0;}
            recalc(n);
        } else {
            discountPct   = 0;
            discountFixed = 0;
            document.getElementById('hPromoCode').value   = '';
            document.getElementById('hDiscountPct').value = 0;
            document.getElementById('hDiscountFixed') && (document.getElementById('hDiscountFixed').value = 0);
            res.classList.add('promo-er');
            res.innerHTML='<i class="fas fa-times-circle"></i> '+(data.message||'Invalid promo code');
            res.style.display='flex';
            var drow=document.getElementById('discountRow');
            if(drow) drow.style.display='none';
            showToast(data.message||'Invalid promo code.','er');
        }
    })
    .catch(function(){
        // Offline fallback — clear discount
        res.className='promo-result promo-er';
        res.innerHTML='<i class="fas fa-times-circle"></i> Could not validate code. Try again.';
        res.style.display='flex';
    });
};

/* ── FORM VALIDATION ── */
function showErr(id, show){
    var el=document.getElementById(id);
    if(el) el.style.display=show?'block':'none';
}
function setErr(id, hasErr){
    var el=document.getElementById(id);
    if(el){ if(hasErr) el.classList.add('fc-err'); else el.classList.remove('fc-err'); }
}

window.validateAndSubmit = function(e){
    if(e) e.preventDefault();
    var ok = true;

    // Check-in
    var ci = ciVis ? ciVis.value : '';
    var co = coVis ? coVis.value : '';
    if(!ci){ setErr('checkInVis',true); showErr('errCI',true); ok=false; }
    else   { setErr('checkInVis',false); showErr('errCI',false); }

    // Check-out
    if(!co){ setErr('checkOutVis',true); showErr('errCO',true); ok=false; }
    else if(ci && new Date(co)<=new Date(ci)){ setErr('checkOutVis',true); showErr('errCO',true); ok=false; }
    else { setErr('checkOutVis',false); showErr('errCO',false); }

    // Name
    var nm = document.getElementById('guestName').value.trim();
    if(!nm){ setErr('guestName',true); showErr('errName',true); ok=false; }
    else   { setErr('guestName',false); showErr('errName',false); }

    // Email
    var em = document.getElementById('guestEmail').value.trim();
    var emailOk = /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(em);
    if(!emailOk){ setErr('guestEmail',true); showErr('errEmail',true); ok=false; }
    else        { setErr('guestEmail',false); showErr('errEmail',false); }

    // Terms
    var terms = document.getElementById('termsChk');
    if(terms && !terms.checked){ showToast('Please accept the Terms & Conditions.','er'); ok=false; }

    if(!ok){ showToast('Please fix the highlighted fields.','er'); return false; }

    // Show confirm modal
    var nights = 0;
    if(ci&&co){ var d1=new Date(ci),d2=new Date(co); nights=Math.round((d2-d1)/(1000*60*60*24)); }
    var base = pricePerNight*nights;
    var tax  = base*taxRate; var svc=base*svcRate;
    var disc = (discountPct > 0) ? base*(discountPct/100) : discountFixed;
    if(disc > base) disc = base;
    var tot  = base+tax+svc-disc;
    var fmt2 = function(v){ return 'Rs. '+v.toLocaleString('en-US',{minimumFractionDigits:2,maximumFractionDigits:2}); };
    var d = new Date(ci);
    var months=['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    var ciStr = d.getDate()+' '+months[d.getMonth()]+' '+d.getFullYear();
    var d2b   = new Date(co);
    var coStr = d2b.getDate()+' '+months[d2b.getMonth()]+' '+d2b.getFullYear();
    var msg = document.getElementById('confirmMsg');
    if(msg) msg.innerHTML =
        '<strong><%= esc(roomLbl(rType)) %></strong><br>'+
        'Room <%= esc(rNum) %> &bull; '+nights+' night'+(nights>1?'s':'')+'<br>'+
        ciStr+' &rarr; '+coStr+'<br><br>'+
        '<strong style="font-size:1.1rem;color:#006994">Total: '+fmt2(tot)+'</strong>';
    openModal('confirmModal');
    return false;
};

window.doSubmit = function(){
    var btn = document.getElementById('finalSubmitBtn');
    if(btn){ btn.disabled=true; btn.innerHTML='<i class="fas fa-spinner fa-spin"></i> Processing…'; }
    document.getElementById('bookingForm').submit();
};

window.submitIfDates = function(){
    var ci = ciVis ? ciVis.value : '';
    var co = coVis ? coVis.value : '';
    if(!ci||!co){ showToast('Please select check-in and check-out dates.','er'); return; }
    validateAndSubmit(null);
};

/* ── MODAL ── */
window.openModal = function(id){
    var m=document.getElementById(id); if(m){ m.classList.add('open'); document.body.style.overflow='hidden'; }
};
window.closeModal = function(id){
    var m=document.getElementById(id); if(m){ m.classList.remove('open'); document.body.style.overflow=''; }
};
document.querySelectorAll('.modal-bg').forEach(function(m){
    m.addEventListener('click',function(e){ if(e.target===this) closeModal(this.id); });
});
document.addEventListener('keydown',function(e){ if(e.key==='Escape') document.querySelectorAll('.modal-bg.open').forEach(function(m){closeModal(m.id);}); });

/* ── TOAST ── */
function showToast(msg, type){
    var tw=document.getElementById('twCont');
    var t=document.createElement('div');
    t.className='tst tst-'+(type==='ok'?'ok':'er');
    t.innerHTML='<i class="fas fa-'+(type==='ok'?'check-circle':'exclamation-circle')+'"></i> '+msg+
        ' <button onclick="this.parentNode.remove()" style="background:none;border:none;color:#fff;margin-left:auto;font-size:1.1rem;cursor:pointer;line-height:1">&times;</button>';
    tw.appendChild(t);
    setTimeout(function(){ if(t.parentNode){t.style.transition='.4s';t.style.opacity='0';setTimeout(function(){t.remove();},420);} },5000);
}

/* ── INIT ── */
(function init(){
    // Set dates min values
    if(ciVis) ciVis.min = today;
    if(coVis) coVis.min = today;
    // Auto-dismiss flash alerts
    document.querySelectorAll('.alert').forEach(function(a){
        setTimeout(function(){ a.style.transition='.5s'; a.style.opacity='0'; setTimeout(function(){ a.remove(); },500); },6000);
    });
    // Trigger initial recalc if dates are pre-set
    <% if(numNights > 0) { %>
    recalc(<%= numNights %>);
    <% } %>
})();

})();
</script>

</body>
</html>
