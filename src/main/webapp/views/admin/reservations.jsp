<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.util.List, java.util.ArrayList, com.oceanview.model.Reservation, com.oceanview.model.User, com.oceanview.model.Room, com.oceanview.model.Guest" %>
<%!
    private String safeStr(String s) { return s != null ? s : ""; }
    private String escJ(String s) {
        if (s == null) return "";
        return s.replace("\\","\\\\").replace("\"","\\\"").replace("\r","").replace("\n"," ").replace("'","\\'");
    }
    private String escH(String s) {
        if (s == null) return "";
        return s.replace("&","&amp;").replace("<","&lt;").replace(">","&gt;").replace("\"","&quot;").replace("'","&#39;");
    }
%>
<%
    User currentUser = (User) session.getAttribute("loggedInUser");
    if (currentUser == null) currentUser = (User) session.getAttribute("user");
    if (currentUser == null || !"ADMIN".equals(currentUser.getRole().toString())) {
        response.sendRedirect(request.getContextPath() + "/login");
        return;
    }

    @SuppressWarnings("unchecked")
    List<Reservation> reservations = (List<Reservation>) request.getAttribute("reservations");
    if (reservations == null) reservations = new ArrayList<>();

    long pendingCount    = 0, confirmedCount = 0, checkedInCount = 0, checkedOutCount = 0, cancelledCount = 0;
    Object pObj = request.getAttribute("pendingCount");
    Object cfObj = request.getAttribute("confirmedCount");
    Object ciObj = request.getAttribute("checkedInCount");
    Object coObj = request.getAttribute("checkedOutCount");
    Object caObj = request.getAttribute("cancelledCount");
    if (pObj  != null) pendingCount    = ((Number)pObj).longValue();
    if (cfObj != null) confirmedCount  = ((Number)cfObj).longValue();
    if (ciObj != null) checkedInCount  = ((Number)ciObj).longValue();
    if (coObj != null) checkedOutCount = ((Number)coObj).longValue();
    if (caObj != null) cancelledCount  = ((Number)caObj).longValue();

    String flashSuccess = request.getAttribute("success") != null ? (String)request.getAttribute("success") : (String)session.getAttribute("success");
    String flashError   = request.getAttribute("error")   != null ? (String)request.getAttribute("error")   : (String)session.getAttribute("error");
    session.removeAttribute("success"); session.removeAttribute("error");
    session.removeAttribute("successMessage"); session.removeAttribute("errorMessage");

    String ctx = request.getContextPath();
    String statusFilter = safeStr((String)request.getAttribute("statusFilter"));
%>
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Reservation Management - Ocean View Resort</title>
<link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
<link rel="stylesheet" href="<%= ctx %>/assets/css/main.css">
<link rel="stylesheet" href="<%= ctx %>/assets/css/sidebar.css">
<style>
*,*::before,*::after{box-sizing:border-box;margin:0;padding:0}
body{display:block!important;flex-direction:unset!important;font-family:'Segoe UI',system-ui,sans-serif;background:#eef2f7;color:#343a40;min-height:100vh}
/* ── SIDEBAR VARS ── */
:root{
  --ocean-blue:#006994;--ocean-light:#4A90A4;--ocean-dark:#003d5c;
  --gold-accent:#D4AF37;--white:#fff;--light-gray:#F8F9FA;--gray:#6C757D;--dark-gray:#343A40;--black:#212529;
  --success:#28A745;--warning:#FFC107;--danger:#DC3545;--info:#17A2B8;
  --spacing-xs:.25rem;--spacing-sm:.5rem;--spacing-md:1rem;--spacing-lg:1.5rem;
  --radius-sm:.25rem;--radius-md:.5rem;--transition-fast:.15s ease-in-out;
}
/* ── SIDEBAR EMBED ── */
.sidebar{position:fixed;left:0;top:0;width:280px;height:100vh;background:linear-gradient(180deg,#003d5c 0%,#212529 100%);color:#fff;display:flex;flex-direction:column;box-shadow:2px 0 15px rgba(0,0,0,.2);z-index:1000;overflow-y:auto;overflow-x:hidden;transition:transform .3s ease}
.sidebar::-webkit-scrollbar{width:5px}.sidebar::-webkit-scrollbar-track{background:rgba(255,255,255,.04)}.sidebar::-webkit-scrollbar-thumb{background:rgba(255,255,255,.18);border-radius:3px}
.sidebar-header{padding:1.25rem 1.5rem;display:flex;align-items:center;justify-content:space-between;border-bottom:1px solid rgba(255,255,255,.1);flex-shrink:0}
.sidebar-brand{display:flex;align-items:center;gap:.75rem}
.sidebar-logo{height:38px;width:auto}
.sidebar-brand-text{font-size:1.2rem;font-weight:700;color:#fff;white-space:nowrap}
.sidebar-toggle-btn{background:none;border:none;color:#fff;font-size:1.2rem;cursor:pointer;padding:.3rem;border-radius:.3rem;transition:background .15s ease;display:none}
.sidebar-toggle-btn:hover{background:rgba(255,255,255,.12)}
.sidebar-user{padding:1rem 1.5rem;display:flex;align-items:center;gap:.75rem;background:rgba(255,255,255,.05);border-bottom:1px solid rgba(255,255,255,.08);flex-shrink:0}
.sidebar-user-avatar{width:46px;height:46px;border-radius:50%;background:linear-gradient(135deg,#006994,#D4AF37);display:flex;align-items:center;justify-content:center;font-weight:700;font-size:1rem;color:#fff;flex-shrink:0}
.sidebar-user-info{flex:1;overflow:hidden}
.sidebar-user-name{font-weight:600;font-size:.95rem;color:#fff;white-space:nowrap;overflow:hidden;text-overflow:ellipsis}
.sidebar-user-role{font-size:.72rem;color:rgba(255,255,255,.65);text-transform:uppercase;letter-spacing:.06em;margin-top:.15rem}
.sidebar-nav{flex:1;padding:.75rem 0;overflow-y:auto}
.sidebar-section{margin-bottom:1.25rem}
.sidebar-section-title{padding:.5rem 1.5rem;font-size:.7rem;font-weight:700;color:rgba(255,255,255,.4);text-transform:uppercase;letter-spacing:.1em}
.sidebar-menu{list-style:none;margin:0;padding:0}
.sidebar-menu-item{margin:.15rem .75rem}
.sidebar-link{display:flex;align-items:center;gap:.75rem;padding:.68rem 1rem;color:rgba(255,255,255,.78);text-decoration:none;border-radius:.45rem;transition:all .18s ease;position:relative;font-size:.88rem}
.sidebar-link::before{content:'';position:absolute;left:0;top:20%;height:60%;width:3px;background:#D4AF37;border-radius:0 2px 2px 0;transform:scaleY(0);transition:transform .18s ease}
.sidebar-link:hover{background:rgba(255,255,255,.1);color:#fff;padding-left:1.25rem}
.sidebar-link:hover::before{transform:scaleY(1)}
.sidebar-link.active{background:linear-gradient(90deg,rgba(212,175,55,.22),rgba(212,175,55,.05));color:#D4AF37;font-weight:600}
.sidebar-link.active::before{transform:scaleY(1)}
.sidebar-link i{width:20px;text-align:center;font-size:1rem;flex-shrink:0}
.sidebar-link span{flex:1;white-space:nowrap;overflow:hidden;text-overflow:ellipsis}
.sidebar-footer{border-top:1px solid rgba(255,255,255,.1);padding:.75rem;display:flex;flex-direction:column;gap:.25rem;background:rgba(0,0,0,.25);flex-shrink:0}
.sidebar-footer-link{display:flex;align-items:center;gap:.75rem;padding:.65rem 1rem;color:rgba(255,255,255,.75);text-decoration:none;border-radius:.45rem;transition:all .18s ease;font-size:.88rem}
.sidebar-footer-link:hover{background:rgba(255,255,255,.1);color:#fff}
.sidebar-footer-link i{width:20px;text-align:center}
.sidebar-logout{color:rgba(220,53,69,.85)}
.sidebar-logout:hover{background:rgba(220,53,69,.12)!important;color:#dc3545!important}
.sidebar-overlay{position:fixed;top:0;left:0;width:100%;height:100%;background:rgba(0,0,0,.5);opacity:0;visibility:hidden;transition:all .25s ease;z-index:999}
.sidebar-overlay.active{opacity:1;visibility:visible}
.sidebar-badge{display:inline-flex;align-items:center;justify-content:center;min-width:20px;height:20px;padding:0 6px;background:#dc3545;color:#fff;border-radius:10px;font-size:.68rem;font-weight:700;margin-left:auto}
@media(max-width:992px){.sidebar{transform:translateX(-100%)}.sidebar.open{transform:translateX(0)}.sidebar-toggle-btn{display:block}body.sidebar-open{overflow:hidden}}
@media(max-width:576px){.sidebar{width:82%;max-width:280px}}
/* ── PAGE VARS ── */
:root{
  --pri:#006994;--pri-dk:#004f70;--acc:#4A90A4;
  --ok:#28a745;--er:#dc3545;--warn:#ffc107;--inf:#17a2b8;--pur:#6f42c1;--oran:#fd7e14;
  --g50:#f8f9fa;--g100:#f1f3f5;--g200:#e9ecef;--g300:#dee2e6;--g400:#ced4da;--g500:#adb5bd;--g600:#6c757d;--g700:#495057;--g800:#343a40;
  --sh1:0 1px 4px rgba(0,0,0,.08);--sh2:0 4px 14px rgba(0,0,0,.12);--sh3:0 8px 30px rgba(0,0,0,.18);
  --r:.75rem;--r2:.4rem;--tr:.22s ease;
}
/* ── LAYOUT ── */
.pw{display:flex;min-height:100vh}
.mc{flex:1;margin-left:280px;padding:2rem 2.5rem;transition:margin var(--tr)}
@media(max-width:992px){.mc{margin-left:0;padding:1rem}}
/* ── MOBILE TOPBAR ── */
.mtb{display:none;align-items:center;gap:.75rem;padding:.75rem 1rem;background:#fff;border-bottom:1px solid var(--g200);box-shadow:var(--sh1);position:sticky;top:0;z-index:100;margin-bottom:1.25rem}
.mtb-btn{background:none;border:none;font-size:1.25rem;color:var(--pri);cursor:pointer;padding:.3rem .5rem;border-radius:.35rem;transition:background var(--tr)}
.mtb-btn:hover{background:var(--g100)}
.mtb-title{font-size:1rem;font-weight:700;color:var(--g800)}
.mtb-title i{color:var(--pri);margin-right:.3rem}
@media(max-width:992px){.mtb{display:flex}}
/* ── TOASTS ── */
.tw{position:fixed;top:1.5rem;right:1.5rem;z-index:9999;display:flex;flex-direction:column;gap:.5rem;pointer-events:none}
.toast{display:flex;align-items:center;gap:.75rem;padding:.9rem 1.25rem;border-radius:var(--r2);color:#fff;font-size:.9rem;font-weight:500;min-width:300px;max-width:420px;box-shadow:var(--sh2);animation:tIn .35s ease;pointer-events:all}
.toast.ok{background:var(--ok)}.toast.er{background:var(--er)}
.toast i{font-size:1.1rem;flex-shrink:0}.toast-msg{flex:1}
.toast-x{background:none;border:none;color:#fff;font-size:1.2rem;cursor:pointer;opacity:.75;padding:0;line-height:1;flex-shrink:0}
.toast-x:hover{opacity:1}
@keyframes tIn{from{opacity:0;transform:translateX(110%)}to{opacity:1;transform:translateX(0)}}
@keyframes tOut{from{opacity:1;transform:translateX(0)}to{opacity:0;transform:translateX(110%)}}
/* ── PAGE HEADER ── */
.ph{display:flex;justify-content:space-between;align-items:flex-start;margin-bottom:1.75rem;flex-wrap:wrap;gap:1rem}
.ph h1{font-size:1.75rem;font-weight:700;color:var(--g800);display:flex;align-items:center;gap:.6rem}
.ph h1 i{color:var(--pri)}.ph p{color:var(--g600);font-size:.9rem;margin-top:.3rem}
/* ── STATS ── */
.stats{display:grid;grid-template-columns:repeat(5,1fr);gap:1rem;margin-bottom:1.75rem}
@media(max-width:1100px){.stats{grid-template-columns:repeat(3,1fr)}}
@media(max-width:700px){.stats{grid-template-columns:repeat(2,1fr)}}
@media(max-width:400px){.stats{grid-template-columns:1fr}}
.sc{background:#fff;border-radius:var(--r);padding:1.1rem 1.25rem;display:flex;align-items:center;gap:.9rem;box-shadow:var(--sh1);border-left:4px solid transparent;transition:transform var(--tr),box-shadow var(--tr);cursor:default}
.sc:hover{transform:translateY(-3px);box-shadow:var(--sh2)}
.sc.sp{border-color:var(--warn)}.sc.sc2{border-color:var(--pri)}.sc.si{border-color:var(--ok)}.sc.so{border-color:var(--g500)}.sc.sx{border-color:var(--er)}
.sc-ic{width:46px;height:46px;border-radius:var(--r2);display:flex;align-items:center;justify-content:center;font-size:1.25rem;color:#fff;flex-shrink:0}
.sc.sp .sc-ic{background:var(--warn)}.sc.sc2 .sc-ic{background:var(--pri)}.sc.si .sc-ic{background:var(--ok)}.sc.so .sc-ic{background:var(--g500)}.sc.sx .sc-ic{background:var(--er)}
.sc-info h3{font-size:1.7rem;font-weight:700;line-height:1;color:var(--g800)}
.sc-info p{font-size:.78rem;color:var(--g600);margin-top:.2rem}
/* ── TOOLBAR ── */
.tb{background:#fff;border-radius:var(--r);padding:.9rem 1.25rem;margin-bottom:1.25rem;display:flex;align-items:center;gap:.75rem;flex-wrap:wrap;box-shadow:var(--sh1)}
.tb-l{display:flex;align-items:center;gap:.6rem;flex:1;flex-wrap:wrap}
.tb-r{display:flex;align-items:center;gap:.6rem}
.sb{position:relative}
.sb i{position:absolute;left:.8rem;top:50%;transform:translateY(-50%);color:var(--g500);font-size:.85rem;pointer-events:none}
.sb input{padding:.52rem .9rem .52rem 2.2rem;border:1.5px solid var(--g200);border-radius:var(--r2);font-size:.86rem;width:220px;outline:none;transition:border var(--tr);background:var(--g50);color:var(--g800)}
.sb input:focus{border-color:var(--pri);background:#fff}
.fs{padding:.52rem .9rem;border:1.5px solid var(--g200);border-radius:var(--r2);font-size:.86rem;outline:none;cursor:pointer;background:var(--g50);color:var(--g800);transition:border var(--tr)}
.fs:focus{border-color:var(--pri)}
/* ── SECTION HEADER ── */
.sh{display:flex;justify-content:space-between;align-items:center;margin-bottom:1rem}
.sh h2{font-size:1rem;font-weight:700;color:var(--g700)}
.rc{font-size:.82rem;color:var(--g600);background:var(--g100);padding:.25rem .7rem;border-radius:1rem}
/* ── STATUS BADGES ── */
.badge{display:inline-flex;align-items:center;gap:.3rem;padding:.22rem .7rem;border-radius:1rem;font-size:.7rem;font-weight:700;text-transform:uppercase;letter-spacing:.05em;white-space:nowrap}
.b-pend{background:#fff3cd;color:#856404}.b-conf{background:#d1ecf1;color:#0c5460}
.b-in{background:#d4edda;color:#155724}.b-out{background:#e2d9f3;color:#4a235a}.b-canc{background:#f8d7da;color:#721c24}
/* ── TABLE ── */
.table-wrap{background:#fff;border-radius:var(--r);box-shadow:var(--sh1);overflow:hidden}
.rtbl{width:100%;border-collapse:collapse;font-size:.875rem}
.rtbl thead{background:linear-gradient(135deg,var(--pri),var(--acc))}
.rtbl thead th{padding:.85rem 1rem;text-align:left;font-weight:600;color:#fff;white-space:nowrap;font-size:.8rem;letter-spacing:.03em}
.rtbl thead th:first-child{padding-left:1.4rem}
.rtbl thead th:last-child{padding-right:1.4rem;text-align:center}
.rtbl tbody tr{border-bottom:1px solid var(--g100);transition:background var(--tr)}
.rtbl tbody tr:last-child{border-bottom:none}
.rtbl tbody tr:hover{background:var(--g50)}
.rtbl tbody td{padding:.78rem 1rem;vertical-align:middle}
.rtbl tbody td:first-child{padding-left:1.4rem;color:var(--g500);font-size:.8rem}
.rtbl tbody td:last-child{padding-right:1.4rem;text-align:center}
.res-num{font-weight:700;color:var(--pri);font-size:.88rem}
.guest-name{font-weight:600;color:var(--g800)}
.guest-sub{font-size:.76rem;color:var(--g600);margin-top:.1rem}
.room-num{font-weight:600;color:var(--g700)}
.amount{font-weight:700;color:var(--pri)}
.abtns{display:flex;gap:.35rem;justify-content:center;flex-wrap:wrap}
/* ── BUTTONS ── */
.btn{display:inline-flex;align-items:center;justify-content:center;gap:.35rem;padding:.48rem .9rem;border:none;border-radius:var(--r2);font-size:.82rem;font-weight:600;cursor:pointer;text-decoration:none;transition:all var(--tr);white-space:nowrap;line-height:1.2}
.btn-sm{padding:.3rem .6rem;font-size:.76rem}
.btn-pri{background:var(--pri);color:#fff}.btn-pri:hover{background:var(--pri-dk)}
.btn-ok{background:var(--ok);color:#fff}.btn-ok:hover{filter:brightness(.9)}
.btn-warn{background:var(--warn);color:#000}.btn-warn:hover{filter:brightness(.9)}
.btn-er{background:var(--er);color:#fff}.btn-er:hover{filter:brightness(.9)}
.btn-sec{background:var(--g200);color:var(--g800)}.btn-sec:hover{background:var(--g300)}
.btn-inf{background:var(--inf);color:#fff}.btn-inf:hover{filter:brightness(.9)}
.btn-pur{background:var(--pur);color:#fff}.btn-pur:hover{filter:brightness(.9)}
.btn-oran{background:var(--oran);color:#fff}.btn-oran:hover{filter:brightness(.9)}
/* ── EMPTY STATE ── */
.es{text-align:center;padding:4rem 2rem;color:var(--g600)}
.es i{font-size:3.5rem;color:var(--g300);display:block;margin-bottom:1rem}
.es h3{font-size:1.2rem;margin-bottom:.5rem;color:var(--g700)}
/* ── MODAL ── */
.mo{position:fixed;inset:0;background:rgba(0,0,0,.52);z-index:2000;display:flex;align-items:center;justify-content:center;padding:1rem;opacity:0;visibility:hidden;transition:opacity .28s ease,visibility .28s ease}
.mo.show{opacity:1;visibility:visible}
.md{background:#fff;border-radius:var(--r);width:100%;max-width:680px;max-height:93vh;display:flex;flex-direction:column;box-shadow:var(--sh3);transform:translateY(-18px) scale(.98);transition:transform .28s ease}
.mo.show .md{transform:translateY(0) scale(1)}
.md-sm{max-width:460px}.md-xs{max-width:420px}
.mh{padding:1.1rem 1.5rem;display:flex;align-items:center;justify-content:space-between;background:linear-gradient(135deg,var(--pri),var(--acc));border-radius:var(--r) var(--r) 0 0;color:#fff}
.mh.mh-er{background:linear-gradient(135deg,var(--er),#c82333)}
.mh.mh-ok{background:linear-gradient(135deg,var(--ok),#1e7e34)}
.mh.mh-warn{background:linear-gradient(135deg,#d39e00,var(--warn))}
.mh h2{font-size:1.1rem;font-weight:700;display:flex;align-items:center;gap:.5rem}
.mx{background:none;border:none;font-size:1.5rem;color:#fff;cursor:pointer;opacity:.75;line-height:1;padding:0;transition:opacity var(--tr)}
.mx:hover{opacity:1}
.mb{padding:1.4rem 1.5rem;overflow-y:auto;flex:1}
.mf{padding:.9rem 1.5rem;border-top:1px solid var(--g200);display:flex;justify-content:flex-end;gap:.65rem;background:var(--g50);border-radius:0 0 var(--r) var(--r)}
/* ── DETAIL ROWS in VIEW MODAL ── */
.dg{display:grid;grid-template-columns:1fr 1fr;gap:.75rem}
@media(max-width:540px){.dg{grid-template-columns:1fr}}
.di{display:flex;flex-direction:column;gap:.2rem;padding:.65rem .9rem;background:var(--g50);border-radius:var(--r2);border:1px solid var(--g100)}
.di.fw{grid-column:1/-1}
.di label{font-size:.74rem;font-weight:700;color:var(--g600);text-transform:uppercase;letter-spacing:.05em}
.di span{font-size:.92rem;font-weight:600;color:var(--g800)}
.di span.money{color:var(--pri);font-size:1.05rem}
/* ── FORM ── */
.fg{display:grid;grid-template-columns:1fr 1fr;gap:.85rem}
@media(max-width:520px){.fg{grid-template-columns:1fr}}
.fi{display:flex;flex-direction:column;gap:.3rem}
.fi.fw{grid-column:1/-1}
.fl{font-size:.82rem;font-weight:600;color:var(--g700)}
.fc{padding:.56rem .85rem;border:1.5px solid var(--g300);border-radius:var(--r2);font-size:.88rem;outline:none;transition:border var(--tr),box-shadow var(--tr);width:100%;font-family:inherit;background:#fff;color:var(--g800)}
.fc:focus{border-color:var(--pri);box-shadow:0 0 0 3px rgba(0,105,148,.11)}
textarea.fc{resize:vertical;min-height:75px}
/* ── CONFIRM ACTION MODAL ── */
.ci{text-align:center;font-size:2.8rem;margin-bottom:1rem}
.ct{text-align:center;color:var(--g600);line-height:1.6}
.ct strong{color:var(--g800)}
</style>
</head>
<body>
<div class="pw">
<jsp:include page="../common/sidebar.jsp">
    <jsp:param name="active" value="reservations"/>
</jsp:include>

<div class="mc">

<!-- MOBILE TOPBAR -->
<div class="mtb">
    <button class="mtb-btn" onclick="document.getElementById('sidebar').classList.toggle('open');document.getElementById('sidebarOverlay').classList.toggle('active')">
        <i class="fas fa-bars"></i>
    </button>
    <span class="mtb-title"><i class="fas fa-calendar-alt"></i> Reservation Management</span>
</div>

<!-- TOASTS -->
<div class="tw">
<% if (flashSuccess != null && !flashSuccess.isEmpty()) { %>
<div class="toast ok" id="tOk"><i class="fas fa-check-circle"></i><span class="toast-msg"><%= escH(flashSuccess) %></span><button class="toast-x" onclick="rmToast('tOk')">&times;</button></div>
<% } %>
<% if (flashError != null && !flashError.isEmpty()) { %>
<div class="toast er" id="tEr"><i class="fas fa-exclamation-circle"></i><span class="toast-msg"><%= escH(flashError) %></span><button class="toast-x" onclick="rmToast('tEr')">&times;</button></div>
<% } %>
</div>

<!-- PAGE HEADER -->
<div class="ph">
    <div>
        <h1><i class="fas fa-calendar-alt"></i> Reservation Management</h1>
        <p>View, manage and track all hotel reservations</p>
    </div>
</div>

<!-- STATS -->
<div class="stats">
    <div class="sc sp" onclick="applyStatusFilter('PENDING')" style="cursor:pointer" title="Filter Pending">
        <div class="sc-ic"><i class="fas fa-clock"></i></div>
        <div class="sc-info"><h3><%= pendingCount %></h3><p>Pending</p></div>
    </div>
    <div class="sc sc2" onclick="applyStatusFilter('CONFIRMED')" style="cursor:pointer" title="Filter Confirmed">
        <div class="sc-ic"><i class="fas fa-check"></i></div>
        <div class="sc-info"><h3><%= confirmedCount %></h3><p>Confirmed</p></div>
    </div>
    <div class="sc si" onclick="applyStatusFilter('CHECKED_IN')" style="cursor:pointer" title="Filter Checked In">
        <div class="sc-ic"><i class="fas fa-sign-in-alt"></i></div>
        <div class="sc-info"><h3><%= checkedInCount %></h3><p>Checked In</p></div>
    </div>
    <div class="sc so" onclick="applyStatusFilter('CHECKED_OUT')" style="cursor:pointer" title="Filter Checked Out">
        <div class="sc-ic"><i class="fas fa-sign-out-alt"></i></div>
        <div class="sc-info"><h3><%= checkedOutCount %></h3><p>Checked Out</p></div>
    </div>
    <div class="sc sx" onclick="applyStatusFilter('CANCELLED')" style="cursor:pointer" title="Filter Cancelled">
        <div class="sc-ic"><i class="fas fa-times-circle"></i></div>
        <div class="sc-info"><h3><%= cancelledCount %></h3><p>Cancelled</p></div>
    </div>
</div>

<!-- TOOLBAR -->
<div class="tb">
    <div class="tb-l">
        <div class="sb"><i class="fas fa-search"></i>
            <input type="text" id="srch" placeholder="Search reservation, guest, room..." oninput="doFilter()">
        </div>
        <select class="fs" id="fStat" onchange="doFilter()">
            <option value="">All Status</option>
            <option value="PENDING"     <%= "PENDING".equals(statusFilter)     ? "selected" : "" %>>Pending</option>
            <option value="CONFIRMED"   <%= "CONFIRMED".equals(statusFilter)   ? "selected" : "" %>>Confirmed</option>
            <option value="CHECKED_IN"  <%= "CHECKED_IN".equals(statusFilter)  ? "selected" : "" %>>Checked In</option>
            <option value="CHECKED_OUT" <%= "CHECKED_OUT".equals(statusFilter) ? "selected" : "" %>>Checked Out</option>
            <option value="CANCELLED"   <%= "CANCELLED".equals(statusFilter)   ? "selected" : "" %>>Cancelled</option>
        </select>
        <select class="fs" id="fType" onchange="doFilter()">
            <option value="">All Room Types</option>
            <option value="SINGLE">Single</option>
            <option value="DOUBLE">Double</option>
            <option value="DELUXE">Deluxe</option>
            <option value="SUITE">Suite</option>
            <option value="FAMILY">Family</option>
        </select>
    </div>
    <div class="tb-r">
        <button class="btn btn-sec btn-sm" onclick="clearFilters()"><i class="fas fa-times"></i> Clear</button>
    </div>
</div>

<!-- SECTION HEADING -->
<div class="sh">
    <h2><i class="fas fa-list" style="color:var(--pri);margin-right:.4rem"></i>All Reservations</h2>
    <span class="rc" id="rCount"><%= reservations.size() %> reservation(s)</span>
</div>

<!-- TABLE -->
<% if (reservations.isEmpty()) { %>
<div class="es"><i class="fas fa-calendar-times"></i><h3>No Reservations Found</h3><p>No reservations match your current filters.</p></div>
<% } else { %>
<div class="table-wrap">
<table class="rtbl">
    <thead><tr>
        <th>#</th>
        <th>Res. Number</th>
        <th>Guest</th>
        <th>Room</th>
        <th>Check-In</th>
        <th>Check-Out</th>
        <th>Nights</th>
        <th>Amount</th>
        <th>Status</th>
        <th>Actions</th>
    </tr></thead>
    <tbody id="tBody">
    <%
    int rowN = 1;
    for (Reservation res : reservations) {
        String statCss = "b-pend";
        String statIcon = "fa-clock";
        String statLabel = "PENDING";
        if      (res.isConfirmed())  { statCss="b-conf"; statIcon="fa-check-circle";   statLabel="CONFIRMED";   }
        else if (res.isCheckedIn())  { statCss="b-in";   statIcon="fa-sign-in-alt";    statLabel="CHECKED IN";  }
        else if (res.isCheckedOut()) { statCss="b-out";  statIcon="fa-sign-out-alt";   statLabel="CHECKED OUT"; }
        else if (res.isCancelled())  { statCss="b-canc"; statIcon="fa-times-circle";   statLabel="CANCELLED";   }

        String guestName  = res.getGuestName()   != null ? res.getGuestName()   : "Guest #" + res.getGuestId();
        String roomNum    = res.getRoomNumber()   != null ? res.getRoomNumber()  : "Room #"  + res.getRoomId();
        String roomType   = (res.getRoom() != null && res.getRoom().getRoomType() != null) ? res.getRoom().getRoomType().name() : "";
        String checkIn    = res.getCheckInDate()  != null ? res.getCheckInDate().toString()  : "-";
        String checkOut   = res.getCheckOutDate() != null ? res.getCheckOutDate().toString() : "-";
        int    nights     = res.getNumberOfNights() != null ? res.getNumberOfNights() : 0;
        String amount     = res.getFinalAmount()  != null ? res.getFinalAmount().toPlainString() : "0.00";
        String resNum     = res.getReservationNumber() != null ? res.getReservationNumber() : "#" + res.getReservationId();
        int    resId      = res.getReservationId();
        String statName   = res.getStatus().name();
        String specReq    = res.getSpecialRequests() != null ? res.getSpecialRequests() : "";
        int    numGuests  = res.getNumberOfGuests()  != null ? res.getNumberOfGuests()  : 1;
        String totalAmt   = res.getTotalAmount()    != null ? res.getTotalAmount().toPlainString()    : "0.00";
        String discAmt    = res.getDiscountAmount() != null ? res.getDiscountAmount().toPlainString() : "0.00";
        String taxAmt     = res.getTaxAmount()      != null ? res.getTaxAmount().toPlainString()      : "0.00";
    %>
    <tr data-stat="<%= statName %>" data-type="<%= roomType %>" data-search="<%= escH(guestName.toLowerCase()) %> <%= roomNum.toLowerCase() %> <%= resNum.toLowerCase() %>">
        <td><%= rowN++ %></td>
        <td><span class="res-num"><%= escH(resNum) %></span></td>
        <td>
            <div class="guest-name"><%= escH(guestName) %></div>
            <div class="guest-sub"><i class="fas fa-users" style="font-size:.7rem"></i> <%= numGuests %> guest(s)</div>
        </td>
        <td>
            <div class="room-num">Room <%= escH(roomNum) %></div>
            <% if (!roomType.isEmpty()) { %><div class="guest-sub"><%= roomType %></div><% } %>
        </td>
        <td><i class="fas fa-sign-in-alt" style="color:var(--ok);margin-right:.3rem;font-size:.8rem"></i><%= checkIn %></td>
        <td><i class="fas fa-sign-out-alt" style="color:var(--er);margin-right:.3rem;font-size:.8rem"></i><%= checkOut %></td>
        <td style="text-align:center;font-weight:600"><%= nights %></td>
        <td><span class="amount">Rs. <%= amount %></span></td>
        <td><span class="badge <%= statCss %>"><i class="fas <%= statIcon %>"></i> <%= statLabel %></span></td>
        <td>
            <div class="abtns">
                <button class="btn btn-pri btn-sm" onclick="openViewModal(<%= resId %>)" title="View Details"><i class="fas fa-eye"></i></button>
                <button class="btn btn-inf btn-sm" onclick="openEditModal(<%= resId %>)" title="Edit"><i class="fas fa-edit"></i></button>
                <% if (res.isPending()) { %>
                <button class="btn btn-ok btn-sm" onclick="openActionModal(<%= resId %>,'confirm')" title="Confirm"><i class="fas fa-check"></i></button>
                <% } %>
                <% if (res.canCheckIn()) { %>
                <button class="btn btn-oran btn-sm" onclick="openActionModal(<%= resId %>,'checkin')" title="Check In"><i class="fas fa-sign-in-alt"></i></button>
                <% } %>
                <% if (res.canCheckOut()) { %>
                <button class="btn btn-pur btn-sm" onclick="openActionModal(<%= resId %>,'checkout')" title="Check Out"><i class="fas fa-sign-out-alt"></i></button>
                <% } %>
                <% if (res.canCancel()) { %>
                <button class="btn btn-er btn-sm" onclick="openActionModal(<%= resId %>,'cancel')" title="Cancel"><i class="fas fa-times"></i></button>
                <% } %>
            </div>
        </td>
    </tr>
    <% } %>
    </tbody>
</table>
</div>
<% } %>

</div><!-- /mc -->
</div><!-- /pw -->

<!-- ══ JSON DATA STORE ══ -->
<script id="RDS" type="application/json">
[<%
boolean firstR = true;
for (Reservation res : reservations) {
    if (!firstR) out.print(",");
    firstR = false;
    String gn  = res.getGuestName()  != null ? escJ(res.getGuestName())  : "Guest #"+res.getGuestId();
    String rn  = res.getRoomNumber() != null ? escJ(res.getRoomNumber()) : "Room #"+res.getRoomId();
    String rt  = (res.getRoom()!=null && res.getRoom().getRoomType()!=null) ? res.getRoom().getRoomType().name() : "";
    String ci  = res.getCheckInDate()  != null ? res.getCheckInDate().toString()  : "";
    String co  = res.getCheckOutDate() != null ? res.getCheckOutDate().toString() : "";
    int    ni  = res.getNumberOfNights() != null ? res.getNumberOfNights() : 0;
    String fa  = res.getFinalAmount()    != null ? res.getFinalAmount().toPlainString()    : "0.00";
    String ta  = res.getTotalAmount()    != null ? res.getTotalAmount().toPlainString()    : "0.00";
    String da  = res.getDiscountAmount() != null ? res.getDiscountAmount().toPlainString() : "0.00";
    String xa  = res.getTaxAmount()      != null ? res.getTaxAmount().toPlainString()      : "0.00";
    String num = res.getReservationNumber() != null ? escJ(res.getReservationNumber()) : "#"+res.getReservationId();
    int    ng  = res.getNumberOfGuests()  != null ? res.getNumberOfGuests()  : 1;
    String sr  = escJ(res.getSpecialRequests());
    String st  = res.getStatus().name();
    int    id  = res.getReservationId();
    boolean canCI = res.canCheckIn(), canCO = res.canCheckOut(), canCA = res.canCancel(), isPend = res.isPending();
%>
{"id":<%= id %>,"num":"<%= num %>","guest":"<%= gn %>","room":"<%= rn %>","roomType":"<%= rt %>","checkIn":"<%= ci %>","checkOut":"<%= co %>","nights":<%= ni %>,"guests":<%= ng %>,"total":"<%= ta %>","disc":"<%= da %>","tax":"<%= xa %>","final":"<%= fa %>","status":"<%= st %>","specReq":"<%= sr %>","canCI":<%= canCI %>,"canCO":<%= canCO %>,"canCA":<%= canCA %>,"isPend":<%= isPend %>}
<% } %>
]
</script>

<!-- ══ VIEW MODAL ══ -->
<div class="mo" id="mView">
<div class="md">
    <div class="mh"><h2><i class="fas fa-eye"></i> Reservation Details</h2><button class="mx" onclick="cModal('mView')">&times;</button></div>
    <div class="mb">
        <div class="dg">
            <div class="di"><label>Reservation No.</label><span id="vNum" style="color:var(--pri);font-weight:700"></span></div>
            <div class="di"><label>Status</label><span id="vStat"></span></div>
            <div class="di"><label>Guest Name</label><span id="vGuest"></span></div>
            <div class="di"><label>Number of Guests</label><span id="vNG"></span></div>
            <div class="di"><label>Room</label><span id="vRoom"></span></div>
            <div class="di"><label>Room Type</label><span id="vRoomType"></span></div>
            <div class="di"><label><i class="fas fa-sign-in-alt" style="color:var(--ok)"></i> Check-In</label><span id="vCI"></span></div>
            <div class="di"><label><i class="fas fa-sign-out-alt" style="color:var(--er)"></i> Check-Out</label><span id="vCO"></span></div>
            <div class="di"><label>Number of Nights</label><span id="vNights"></span></div>
            <div class="di"><label>Total Amount</label><span id="vTotal" class="money"></span></div>
            <div class="di"><label>Discount</label><span id="vDisc" class="money"></span></div>
            <div class="di"><label>Tax</label><span id="vTax" class="money"></span></div>
            <div class="di fw"><label>Final Amount</label><span id="vFinal" class="money" style="font-size:1.3rem;color:var(--pri);font-weight:700"></span></div>
            <div class="di fw"><label>Special Requests</label><span id="vSpec" style="white-space:pre-wrap"></span></div>
        </div>
    </div>
    <div class="mf">
        <button type="button" class="btn btn-sec" onclick="cModal('mView')"><i class="fas fa-times"></i> Close</button>
        <button type="button" class="btn btn-inf" id="vEditBtn" onclick="openEditFromView()"><i class="fas fa-edit"></i> Edit</button>
    </div>
</div>
</div>

<!-- ══ EDIT MODAL ══ -->
<div class="mo" id="mEdit">
<div class="md md-sm">
    <div class="mh"><h2><i class="fas fa-edit"></i> Edit Reservation</h2><button class="mx" onclick="cModal('mEdit')">&times;</button></div>
    <div class="mb">
        <form id="editForm" method="post" action="<%= ctx %>/admin/reservations">
            <input type="hidden" name="action" value="update">
            <input type="hidden" name="reservationId" id="eResId">
            <div class="fg">
                <div class="fi">
                    <label class="fl">Reservation No.</label>
                    <input type="text" class="fc" id="eResNum" readonly style="background:var(--g50);color:var(--g600)">
                </div>
                <div class="fi">
                    <label class="fl">Current Status</label>
                    <input type="text" class="fc" id="eResStat" readonly style="background:var(--g50);color:var(--g600)">
                </div>
                <div class="fi">
                    <label class="fl">Number of Guests</label>
                    <input type="number" class="fc" id="eNG" name="numberOfGuests" min="1" max="20">
                </div>
                <div class="fi">
                    <label class="fl">Check-In Date</label>
                    <input type="text" class="fc" id="eCI" readonly style="background:var(--g50);color:var(--g600)">
                </div>
                <div class="fi fw">
                    <label class="fl">Special Requests</label>
                    <textarea class="fc" id="eSR" name="specialRequests" rows="4" placeholder="Enter any special requests..."></textarea>
                </div>
            </div>
        </form>
    </div>
    <div class="mf">
        <button type="button" class="btn btn-sec" onclick="cModal('mEdit')"><i class="fas fa-times"></i> Cancel</button>
        <button type="button" class="btn btn-ok" onclick="document.getElementById('editForm').submit()"><i class="fas fa-save"></i> Save Changes</button>
    </div>
</div>
</div>

<!-- ══ ACTION CONFIRM MODAL ══ -->
<div class="mo" id="mAction">
<div class="md md-xs">
    <div class="mh" id="mActionHdr"><h2 id="mActionTitle"><i class="fas fa-check"></i> Confirm Action</h2><button class="mx" onclick="cModal('mAction')">&times;</button></div>
    <div class="mb" style="padding:2rem 1.5rem;text-align:center">
        <div class="ci" id="mActionIcon"><i class="fas fa-question-circle" style="color:var(--pri)"></i></div>
        <div class="ct" id="mActionBody">Are you sure?</div>
    </div>
    <div class="mf">
        <button type="button" class="btn btn-sec" onclick="cModal('mAction')"><i class="fas fa-times"></i> Cancel</button>
        <a id="mActionLink" href="#" class="btn btn-ok"><i class="fas fa-check"></i> <span id="mActionBtnTxt">Confirm</span></a>
    </div>
</div>
</div>

<script>
/* ── DATA ── */
var RD = JSON.parse(document.getElementById('RDS').textContent);
var RM = {}; RD.forEach(function(r){ RM[r.id]=r; });
var CTX = '<%= ctx %>';
var currentViewId = null;

/* ── TOAST ── */
function rmToast(id){
    var t=document.getElementById(id); if(!t)return;
    t.style.animation='tOut .3s ease forwards';
    setTimeout(function(){if(t.parentNode)t.parentNode.removeChild(t);},320);
}
document.querySelectorAll('.toast').forEach(function(t){
    setTimeout(function(){t.style.animation='tOut .3s ease forwards';setTimeout(function(){if(t.parentNode)t.parentNode.removeChild(t);},320);},5000);
});

/* ── MODAL HELPERS ── */
function oModal(id){document.getElementById(id).classList.add('show');document.body.style.overflow='hidden';}
function cModal(id){document.getElementById(id).classList.remove('show');document.body.style.overflow='';}
document.querySelectorAll('.mo').forEach(function(o){
    o.addEventListener('click',function(e){if(e.target===o)cModal(o.id);});
});
document.addEventListener('keydown',function(e){
    if(e.key==='Escape')document.querySelectorAll('.mo.show').forEach(function(m){cModal(m.id);});
});

/* ── FILTER ── */
function doFilter(){
    var s=document.getElementById('srch').value.toLowerCase().trim();
    var st=document.getElementById('fStat').value.toUpperCase();
    var tp=document.getElementById('fType').value.toUpperCase();
    var vis=0;
    document.querySelectorAll('#tBody tr').forEach(function(r){
        var ds=(r.dataset.search||'').toLowerCase();
        var rs=(r.dataset.stat||'').toUpperCase();
        var rt=(r.dataset.type||'').toUpperCase();
        var show=(!s||ds.includes(s))&&(!st||rs===st)&&(!tp||rt===tp);
        r.style.display=show?'':'none'; if(show)vis++;
    });
    document.getElementById('rCount').textContent=vis+' reservation(s)';
}
function applyStatusFilter(s){
    document.getElementById('fStat').value=s;
    doFilter();
}
function clearFilters(){
    document.getElementById('srch').value='';
    document.getElementById('fStat').value='';
    document.getElementById('fType').value='';
    doFilter();
}

/* ── VIEW MODAL ── */
function openViewModal(id){
    var r=RM[id]; if(!r){alert('Data not found.');return;}
    currentViewId=id;
    document.getElementById('vNum').textContent=r.num;
    // Status badge
    var sc=''; var sl=r.status;
    if(sl==='PENDING')     sc='background:#fff3cd;color:#856404';
    else if(sl==='CONFIRMED')  sc='background:#d1ecf1;color:#0c5460';
    else if(sl==='CHECKED_IN') sc='background:#d4edda;color:#155724';
    else if(sl==='CHECKED_OUT')sc='background:#e2d9f3;color:#4a235a';
    else if(sl==='CANCELLED')  sc='background:#f8d7da;color:#721c24';
    document.getElementById('vStat').innerHTML='<span style="'+sc+';padding:.2rem .7rem;border-radius:1rem;font-size:.8rem;font-weight:700">'+sl.replace('_',' ')+'</span>';
    document.getElementById('vGuest').textContent=r.guest;
    document.getElementById('vNG').textContent=r.guests+' guest(s)';
    document.getElementById('vRoom').textContent='Room '+r.room;
    document.getElementById('vRoomType').textContent=r.roomType||'N/A';
    document.getElementById('vCI').textContent=r.checkIn||'-';
    document.getElementById('vCO').textContent=r.checkOut||'-';
    document.getElementById('vNights').textContent=r.nights+' night(s)';
    document.getElementById('vTotal').textContent='Rs. '+r.total;
    document.getElementById('vDisc').textContent='Rs. '+r.disc;
    document.getElementById('vTax').textContent='Rs. '+r.tax;
    document.getElementById('vFinal').textContent='Rs. '+r.final;
    document.getElementById('vSpec').textContent=r.specReq||'None';
    oModal('mView');
}

/* ── EDIT MODAL ── */
function openEditModal(id){
    var r=RM[id]; if(!r){alert('Data not found.');return;}
    document.getElementById('eResId').value=r.id;
    document.getElementById('eResNum').value=r.num;
    document.getElementById('eResStat').value=r.status.replace('_',' ');
    document.getElementById('eNG').value=r.guests;
    document.getElementById('eCI').value=r.checkIn;
    document.getElementById('eSR').value=r.specReq;
    oModal('mEdit');
}
function openEditFromView(){
    cModal('mView');
    setTimeout(function(){openEditModal(currentViewId);},200);
}

/* ── ACTION MODAL ── */
var actionConfigs = {
    confirm:  { title:'Confirm Reservation', icon:'<i class="fas fa-check-circle" style="color:var(--ok)"></i>', hdrClass:'mh-ok',  btnClass:'btn-ok',  btnTxt:'Yes, Confirm',   body:'Confirm this reservation? The guest will be notified.' },
    checkin:  { title:'Check In Guest',      icon:'<i class="fas fa-sign-in-alt" style="color:var(--oran)"></i>', hdrClass:'mh-warn', btnClass:'btn-oran', btnTxt:'Yes, Check In',   body:'Check in this guest? This will mark the room as occupied.' },
    checkout: { title:'Check Out Guest',     icon:'<i class="fas fa-sign-out-alt" style="color:var(--pur)"></i>', hdrClass:'mh-warn', btnClass:'btn-pur',  btnTxt:'Yes, Check Out',  body:'Check out this guest? The room will be marked as available.' },
    cancel:   { title:'Cancel Reservation',  icon:'<i class="fas fa-times-circle" style="color:var(--er)"></i>',  hdrClass:'mh-er',  btnClass:'btn-er',  btnTxt:'Yes, Cancel',     body:'Cancel this reservation? This action cannot be undone.' }
};
function openActionModal(id, action){
    var r=RM[id]; if(!r){alert('Data not found.');return;}
    var cfg=actionConfigs[action]; if(!cfg)return;
    var hdr=document.getElementById('mActionHdr');
    hdr.className='mh '+cfg.hdrClass;
    document.getElementById('mActionTitle').innerHTML='<i class="fas fa-exclamation-triangle"></i> '+cfg.title;
    document.getElementById('mActionIcon').innerHTML='<div style="font-size:3rem">'+cfg.icon+'</div>';
    document.getElementById('mActionBody').innerHTML='<p style="margin-bottom:.5rem"><strong>'+r.num+'</strong></p><p style="color:var(--g600)">'+cfg.body+'</p>';
    var link=document.getElementById('mActionLink');
    link.href=CTX+'/admin/reservations?action='+action+'&id='+id;
    link.className='btn '+cfg.btnClass;
    document.getElementById('mActionBtnTxt').textContent=cfg.btnTxt;
    oModal('mAction');
}

/* ── STATUS FILTER FROM STAT CARDS ── */
function applyStatusFilter(s){
    document.getElementById('fStat').value=s;
    doFilter();
}

/* ── INIT ── */
(function(){
    var tot=RD.length;
    document.getElementById('rCount').textContent=tot+' reservation(s)';
    doFilter();
})();
</script>
</body>
</html>

