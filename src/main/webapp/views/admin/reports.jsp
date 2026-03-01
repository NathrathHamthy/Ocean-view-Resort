<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.util.*, com.oceanview.model.*, java.time.LocalDate" %>
<%!
    private String sH(String s){ if(s==null)return ""; return s.replace("&","&amp;").replace("<","&lt;").replace(">","&gt;").replace("\"","&quot;"); }
    private String safe(Object o){ return o != null ? o.toString() : "0"; }
    private String safeStr(Object o){ return o != null ? o.toString() : ""; }
%>
<%
    User cu = (User) session.getAttribute("loggedInUser");
    if (cu == null) cu = (User) session.getAttribute("user");
    if (cu == null || !"ADMIN".equals(cu.getRole().toString())) {
        response.sendRedirect(request.getContextPath() + "/login"); return;
    }

    // ── Reservation stats ──
    int    totalRes      = request.getAttribute("totalReservations") != null ? ((Number)request.getAttribute("totalReservations")).intValue()  : 0;
    long   pendingRes    = request.getAttribute("pendingRes")    != null ? ((Number)request.getAttribute("pendingRes")).longValue()    : 0;
    long   confirmedRes  = request.getAttribute("confirmedRes")  != null ? ((Number)request.getAttribute("confirmedRes")).longValue()  : 0;
    long   checkedInRes  = request.getAttribute("checkedInRes")  != null ? ((Number)request.getAttribute("checkedInRes")).longValue()  : 0;
    long   checkedOutRes = request.getAttribute("checkedOutRes") != null ? ((Number)request.getAttribute("checkedOutRes")).longValue() : 0;
    long   cancelledRes  = request.getAttribute("cancelledRes")  != null ? ((Number)request.getAttribute("cancelledRes")).longValue()  : 0;

    // ── Room stats ──
    int    totalRooms    = request.getAttribute("totalRooms")      != null ? ((Number)request.getAttribute("totalRooms")).intValue()      : 0;
    int    availableRms  = request.getAttribute("availableRooms")  != null ? ((Number)request.getAttribute("availableRooms")).intValue()  : 0;
    int    occupiedRms   = request.getAttribute("occupiedRooms")   != null ? ((Number)request.getAttribute("occupiedRooms")).intValue()   : 0;
    int    reservedRms   = request.getAttribute("reservedRooms")   != null ? ((Number)request.getAttribute("reservedRooms")).intValue()   : 0;
    int    maintRms      = request.getAttribute("maintenanceRooms")!= null ? ((Number)request.getAttribute("maintenanceRooms")).intValue(): 0;
    String occRate       = safeStr(request.getAttribute("occupancyRate"));

    // ── Revenue stats ──
    String totalRev   = safeStr(request.getAttribute("totalRevenue"));
    String todayRev   = safeStr(request.getAttribute("todayRevenue"));
    String monthRev   = safeStr(request.getAttribute("monthRevenue"));
    String yearRev    = safeStr(request.getAttribute("yearRevenue"));

    // ── Review stats ──
    int    totalRev2     = request.getAttribute("totalReviews")    != null ? ((Number)request.getAttribute("totalReviews")).intValue()    : 0;
    long   approvedRevs  = request.getAttribute("approvedReviews") != null ? ((Number)request.getAttribute("approvedReviews")).longValue(): 0;
    long   pendingRevs   = request.getAttribute("pendingReviews")  != null ? ((Number)request.getAttribute("pendingReviews")).longValue() : 0;
    String avgRating     = safeStr(request.getAttribute("avgRating"));

    // ── Today ──
    int todayCI  = request.getAttribute("todayCheckIns")  != null ? ((Number)request.getAttribute("todayCheckIns")).intValue()  : 0;
    int todayCO  = request.getAttribute("todayCheckOuts") != null ? ((Number)request.getAttribute("todayCheckOuts")).intValue() : 0;

    // ── Collections ──
    @SuppressWarnings("unchecked") List<Reservation> recentRes  = (List<Reservation>) request.getAttribute("recentReservations");
    @SuppressWarnings("unchecked") List<Payment>     recentPay  = (List<Payment>)     request.getAttribute("recentPayments");
    @SuppressWarnings("unchecked") Map<String,Double> revByMeth  = (Map<String,Double>) request.getAttribute("revenueByMethod");
    @SuppressWarnings("unchecked") Map<String,Long>   roomsByTyp = (Map<String,Long>)   request.getAttribute("roomsByType");
    @SuppressWarnings("unchecked") Map<String,Double> monthlyRev = (Map<String,Double>) request.getAttribute("monthlyRevMap");
    if (recentRes  == null) recentRes  = new ArrayList<>();
    if (recentPay  == null) recentPay  = new ArrayList<>();
    if (revByMeth  == null) revByMeth  = new LinkedHashMap<>();
    if (roomsByTyp == null) roomsByTyp = new LinkedHashMap<>();
    if (monthlyRev == null) monthlyRev = new LinkedHashMap<>();

    String flashErr = (String) session.getAttribute("error");
    session.removeAttribute("error"); session.removeAttribute("success");

    String ctx = request.getContextPath();
%>
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Reports & Analytics - Ocean View Resort</title>
<link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
<link rel="stylesheet" href="<%= ctx %>/assets/css/main.css">
<link rel="stylesheet" href="<%= ctx %>/assets/css/sidebar.css">
<script src="https://cdnjs.cloudflare.com/ajax/libs/Chart.js/4.4.0/chart.umd.min.js"></script>
<style>
*,*::before,*::after{box-sizing:border-box;margin:0;padding:0}
body{display:block!important;flex-direction:unset!important;font-family:'Segoe UI',system-ui,sans-serif;background:#eef2f7;color:#343a40;min-height:100vh}
:root{
  --ocean-dark:#003d5c;--gold-accent:#D4AF37;
  --spacing-xs:.25rem;--spacing-sm:.5rem;--spacing-md:1rem;--spacing-lg:1.5rem;
  --radius-sm:.25rem;--radius-md:.5rem;--transition-fast:.15s ease-in-out;
  --danger:#DC3545;--success:#28A745;--warning:#FFC107;
}
/* ── SIDEBAR ── */
.sidebar{position:fixed;left:0;top:0;width:280px;height:100vh;background:linear-gradient(180deg,#003d5c 0%,#212529 100%);color:#fff;display:flex;flex-direction:column;box-shadow:2px 0 15px rgba(0,0,0,.2);z-index:1000;overflow-y:auto;overflow-x:hidden;transition:transform .3s ease}
.sidebar::-webkit-scrollbar{width:5px}.sidebar::-webkit-scrollbar-track{background:rgba(255,255,255,.04)}.sidebar::-webkit-scrollbar-thumb{background:rgba(255,255,255,.18);border-radius:3px}
.sidebar-header{padding:1.25rem 1.5rem;display:flex;align-items:center;justify-content:space-between;border-bottom:1px solid rgba(255,255,255,.1);flex-shrink:0}
.sidebar-brand{display:flex;align-items:center;gap:.75rem}
.sidebar-logo{height:38px;width:auto}
.sidebar-brand-text{font-size:1.2rem;font-weight:700;color:#fff;white-space:nowrap}
.sidebar-toggle-btn{background:none;border:none;color:#fff;font-size:1.2rem;cursor:pointer;padding:.3rem;border-radius:.3rem;display:none}
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
.sidebar-link:hover::before,.sidebar-link.active::before{transform:scaleY(1)}
.sidebar-link.active{background:linear-gradient(90deg,rgba(212,175,55,.22),rgba(212,175,55,.05));color:#D4AF37;font-weight:600}
.sidebar-link i{width:20px;text-align:center;font-size:1rem;flex-shrink:0}
.sidebar-link span{flex:1;white-space:nowrap;overflow:hidden;text-overflow:ellipsis}
.sidebar-footer{border-top:1px solid rgba(255,255,255,.1);padding:.75rem;display:flex;flex-direction:column;gap:.25rem;background:rgba(0,0,0,.25);flex-shrink:0}
.sidebar-footer-link{display:flex;align-items:center;gap:.75rem;padding:.65rem 1rem;color:rgba(255,255,255,.75);text-decoration:none;border-radius:.45rem;transition:all .18s ease;font-size:.88rem}
.sidebar-footer-link:hover{background:rgba(255,255,255,.1);color:#fff}
.sidebar-footer-link i{width:20px;text-align:center}
.sidebar-logout{color:rgba(220,53,69,.85)}.sidebar-logout:hover{background:rgba(220,53,69,.12)!important;color:#dc3545!important}
.sidebar-overlay{position:fixed;top:0;left:0;width:100%;height:100%;background:rgba(0,0,0,.5);opacity:0;visibility:hidden;transition:all .25s ease;z-index:999}
.sidebar-overlay.active{opacity:1;visibility:visible}
.sidebar-badge{display:inline-flex;align-items:center;justify-content:center;min-width:20px;height:20px;padding:0 6px;background:#dc3545;color:#fff;border-radius:10px;font-size:.68rem;font-weight:700;margin-left:auto}
@media(max-width:992px){.sidebar{transform:translateX(-100%)}.sidebar.open{transform:translateX(0)}.sidebar-toggle-btn{display:block}body.sidebar-open{overflow:hidden}}
@media(max-width:576px){.sidebar{width:82%;max-width:280px}}
/* ── PAGE VARS ── */
:root{
  --pri:#006994;--pri-dk:#004f70;--acc:#4A90A4;
  --ok:#28a745;--er:#dc3545;--warn:#ffc107;--inf:#17a2b8;--pur:#6f42c1;--indigo:#3d5af1;
  --g50:#f8f9fa;--g100:#f1f3f5;--g200:#e9ecef;--g300:#dee2e6;--g400:#ced4da;
  --g500:#adb5bd;--g600:#6c757d;--g700:#495057;--g800:#343a40;
  --sh1:0 1px 4px rgba(0,0,0,.08);--sh2:0 4px 14px rgba(0,0,0,.12);--sh3:0 8px 30px rgba(0,0,0,.18);
  --r:.75rem;--r2:.4rem;--tr:.22s ease;
}
/* ── LAYOUT ── */
.pw{display:flex;min-height:100vh}
.mc{flex:1;margin-left:280px;padding:2rem 2.5rem;transition:margin var(--tr)}
@media(max-width:992px){.mc{margin-left:0;padding:1rem}}
/* ── MOBILE TOPBAR ── */
.mtb{display:none;align-items:center;gap:.75rem;padding:.75rem 1rem;background:#fff;border-bottom:1px solid var(--g200);box-shadow:var(--sh1);position:sticky;top:0;z-index:100;margin-bottom:1.25rem}
.mtb-btn{background:none;border:none;font-size:1.25rem;color:var(--pri);cursor:pointer;padding:.3rem .5rem;border-radius:.35rem}
.mtb-title{font-size:1rem;font-weight:700;color:var(--g800)}
.mtb-title i{color:var(--indigo);margin-right:.3rem}
@media(max-width:992px){.mtb{display:flex}}
/* ── TOAST ── */
.tw{position:fixed;top:1.5rem;right:1.5rem;z-index:9999;display:flex;flex-direction:column;gap:.5rem;pointer-events:none}
.toast{display:flex;align-items:center;gap:.75rem;padding:.9rem 1.25rem;border-radius:var(--r2);color:#fff;font-size:.9rem;font-weight:500;min-width:300px;max-width:420px;box-shadow:var(--sh2);animation:tIn .35s ease;pointer-events:all}
.toast.er{background:var(--er)}.toast i{font-size:1.1rem;flex-shrink:0}.toast-msg{flex:1}
.toast-x{background:none;border:none;color:#fff;font-size:1.2rem;cursor:pointer;opacity:.75;padding:0;line-height:1}
@keyframes tIn{from{opacity:0;transform:translateX(110%)}to{opacity:1;transform:translateX(0)}}
@keyframes tOut{from{opacity:1;transform:translateX(0)}to{opacity:0;transform:translateX(110%)}}
/* ── PAGE HEADER ── */
.ph{display:flex;justify-content:space-between;align-items:flex-start;margin-bottom:1.75rem;flex-wrap:wrap;gap:1rem}
.ph h1{font-size:1.75rem;font-weight:700;color:var(--g800);display:flex;align-items:center;gap:.6rem}
.ph h1 i{color:var(--indigo)}.ph p{color:var(--g600);font-size:.9rem;margin-top:.3rem}
.date-badge{display:inline-flex;align-items:center;gap:.5rem;background:#fff;border:1px solid var(--g200);padding:.5rem 1rem;border-radius:var(--r2);font-size:.85rem;color:var(--g600);box-shadow:var(--sh1)}
.date-badge i{color:var(--indigo)}
/* ── KPI CARDS ── */
.kpi-grid{display:grid;grid-template-columns:repeat(4,1fr);gap:1.1rem;margin-bottom:1.5rem}
@media(max-width:1100px){.kpi-grid{grid-template-columns:repeat(2,1fr)}}
@media(max-width:560px){.kpi-grid{grid-template-columns:1fr}}
.kpi{background:#fff;border-radius:var(--r);padding:1.25rem 1.4rem;box-shadow:var(--sh1);border-left:4px solid transparent;transition:transform var(--tr),box-shadow var(--tr);position:relative;overflow:hidden}
.kpi:hover{transform:translateY(-3px);box-shadow:var(--sh2)}
.kpi::after{content:'';position:absolute;right:-15px;top:-15px;width:80px;height:80px;border-radius:50%;opacity:.06}
.kpi.k1{border-color:var(--pri)}.kpi.k1::after{background:var(--pri)}
.kpi.k2{border-color:var(--ok)}.kpi.k2::after{background:var(--ok)}
.kpi.k3{border-color:var(--warn)}.kpi.k3::after{background:var(--warn)}
.kpi.k4{border-color:var(--pur)}.kpi.k4::after{background:var(--pur)}
.kpi-top{display:flex;justify-content:space-between;align-items:flex-start;margin-bottom:.75rem}
.kpi-icon{width:44px;height:44px;border-radius:var(--r2);display:flex;align-items:center;justify-content:center;font-size:1.2rem;color:#fff}
.kpi.k1 .kpi-icon{background:var(--pri)}.kpi.k2 .kpi-icon{background:var(--ok)}
.kpi.k3 .kpi-icon{background:var(--warn)}.kpi.k4 .kpi-icon{background:var(--pur)}
.kpi-val{font-size:1.9rem;font-weight:700;color:var(--g800);line-height:1}
.kpi-sub{font-size:.9rem;font-weight:500;color:var(--g800);margin-top:.3rem}
.kpi-label{font-size:.78rem;color:var(--g600);margin-top:.15rem}
.kpi-trend{display:inline-flex;align-items:center;gap:.25rem;font-size:.75rem;font-weight:600;padding:.15rem .45rem;border-radius:1rem;margin-top:.5rem}
.kpi-trend.up{background:#d4edda;color:#155724}.kpi-trend.neutral{background:var(--g100);color:var(--g600)}
/* ── SECTION TITLE ── */
.sec-title{font-size:1rem;font-weight:700;color:var(--g700);display:flex;align-items:center;gap:.5rem;margin-bottom:1rem;padding-bottom:.5rem;border-bottom:2px solid var(--g100)}
.sec-title i{color:var(--indigo)}
/* ── CHARTS ROW ── */
.charts-row{display:grid;grid-template-columns:2fr 1fr;gap:1.25rem;margin-bottom:1.5rem}
@media(max-width:900px){.charts-row{grid-template-columns:1fr}}
.chart-card{background:#fff;border-radius:var(--r);padding:1.25rem 1.4rem;box-shadow:var(--sh1)}
.chart-card h3{font-size:.95rem;font-weight:700;color:var(--g700);margin-bottom:1rem;display:flex;align-items:center;gap:.5rem}
.chart-card h3 i{color:var(--indigo)}
.chart-wrap{position:relative;height:220px}
/* ── STATS GRID ── */
.stats-row{display:grid;grid-template-columns:repeat(3,1fr);gap:1.1rem;margin-bottom:1.5rem}
@media(max-width:900px){.stats-row{grid-template-columns:repeat(2,1fr)}}
@media(max-width:500px){.stats-row{grid-template-columns:1fr}}
.stat-card{background:#fff;border-radius:var(--r);padding:1.1rem 1.25rem;box-shadow:var(--sh1)}
.stat-card h3{font-size:.88rem;font-weight:700;color:var(--g600);text-transform:uppercase;letter-spacing:.05em;margin-bottom:.85rem;display:flex;align-items:center;gap:.4rem}
.stat-card h3 i{font-size:.9rem}
.stat-row{display:flex;justify-content:space-between;align-items:center;padding:.38rem 0;border-bottom:1px solid var(--g100);font-size:.85rem}
.stat-row:last-child{border-bottom:none}
.stat-row .label{color:var(--g600)}
.stat-row .val{font-weight:700;color:var(--g800)}
.stat-row .val.green{color:var(--ok)}.stat-row .val.red{color:var(--er)}.stat-row .val.blue{color:var(--pri)}.stat-row .val.amber{color:#d97706}
/* ── PROGRESS BAR ── */
.prog-wrap{margin-top:.5rem}
.prog-label{display:flex;justify-content:space-between;font-size:.78rem;color:var(--g600);margin-bottom:.3rem}
.prog-bar{height:8px;background:var(--g100);border-radius:4px;overflow:hidden}
.prog-fill{height:100%;border-radius:4px;transition:width .6s ease}
/* ── TABLE ── */
.tbl-card{background:#fff;border-radius:var(--r);box-shadow:var(--sh1);overflow:hidden;margin-bottom:1.5rem}
.tbl-card-hdr{padding:.9rem 1.25rem;border-bottom:1px solid var(--g100);display:flex;justify-content:space-between;align-items:center}
.tbl-card-hdr h3{font-size:.95rem;font-weight:700;color:var(--g700);display:flex;align-items:center;gap:.5rem}
.tbl-card-hdr h3 i{color:var(--indigo)}
.rtbl{width:100%;border-collapse:collapse;font-size:.85rem}
.rtbl thead{background:var(--g50);border-bottom:2px solid var(--g200)}
.rtbl thead th{padding:.7rem 1rem;text-align:left;font-weight:700;color:var(--g600);font-size:.76rem;text-transform:uppercase;letter-spacing:.04em;white-space:nowrap}
.rtbl thead th:first-child{padding-left:1.25rem}
.rtbl thead th:last-child{padding-right:1.25rem;text-align:right}
.rtbl tbody tr{border-bottom:1px solid var(--g100);transition:background var(--tr)}
.rtbl tbody tr:last-child{border-bottom:none}
.rtbl tbody tr:hover{background:var(--g50)}
.rtbl tbody td{padding:.72rem 1rem;vertical-align:middle}
.rtbl tbody td:first-child{padding-left:1.25rem}
.rtbl tbody td:last-child{padding-right:1.25rem;text-align:right}
/* ── BADGES ── */
.badge{display:inline-flex;align-items:center;gap:.3rem;padding:.2rem .65rem;border-radius:1rem;font-size:.7rem;font-weight:700;text-transform:uppercase;letter-spacing:.04em}
.b-pend{background:#fff3cd;color:#856404}.b-conf{background:#d1ecf1;color:#0c5460}
.b-in{background:#d4edda;color:#155724}.b-out{background:#e2d9f3;color:#4a235a}.b-canc{background:#f8d7da;color:#721c24}
.b-comp{background:#d4edda;color:#155724}.b-ref{background:#f8d7da;color:#721c24}
/* ── TODAY BOX ── */
.today-grid{display:grid;grid-template-columns:1fr 1fr;gap:1rem;margin-bottom:1.5rem}
@media(max-width:600px){.today-grid{grid-template-columns:1fr}}
.today-card{background:linear-gradient(135deg,var(--pri),var(--acc));color:#fff;border-radius:var(--r);padding:1.25rem 1.4rem;box-shadow:var(--sh2)}
.today-card.checkout-card{background:linear-gradient(135deg,var(--pur),#8b5cf6)}
.today-card h3{font-size:.85rem;font-weight:600;opacity:.9;margin-bottom:.5rem;display:flex;align-items:center;gap:.4rem}
.today-card .big-num{font-size:2.5rem;font-weight:700;line-height:1}
.today-card p{font-size:.8rem;opacity:.8;margin-top:.3rem}
/* ── PAYMENT METHOD ── */
.method-row{display:flex;align-items:center;gap:.75rem;padding:.55rem 0;border-bottom:1px solid var(--g100)}
.method-row:last-child{border-bottom:none}
.method-icon{width:32px;height:32px;border-radius:var(--r2);display:flex;align-items:center;justify-content:center;font-size:.85rem;color:#fff;flex-shrink:0}
.method-icon.cash{background:#28a745}.method-icon.card{background:#007bff}
.method-icon.online{background:#6f42c1}.method-icon.bank{background:#fd7e14}
.method-name{flex:1;font-size:.85rem;font-weight:600;color:var(--g800)}
.method-amount{font-weight:700;color:var(--pri);font-size:.88rem}
/* ── REFRESH BTN ── */
.btn-refresh{display:inline-flex;align-items:center;gap:.4rem;padding:.5rem 1.1rem;background:var(--indigo);color:#fff;border:none;border-radius:var(--r2);font-size:.85rem;font-weight:600;cursor:pointer;text-decoration:none;transition:all var(--tr)}
.btn-refresh:hover{filter:brightness(.9)}
/* ── PRINT ── */
@media print{
  .sidebar,.mtb,.tw,.btn-refresh,.no-print{display:none!important}
  .mc{margin-left:0!important;padding:0!important}
  .pw{display:block!important}
  .kpi-grid{grid-template-columns:repeat(4,1fr)!important}
}
</style>
</head>
<body>
<div class="pw">
<jsp:include page="../common/sidebar.jsp">
    <jsp:param name="active" value="reports"/>
</jsp:include>

<div class="mc">

<!-- MOBILE TOPBAR -->
<div class="mtb">
    <button class="mtb-btn" onclick="document.getElementById('sidebar').classList.toggle('open');document.getElementById('sidebarOverlay').classList.toggle('active')"><i class="fas fa-bars"></i></button>
    <span class="mtb-title"><i class="fas fa-chart-bar"></i> Reports & Analytics</span>
</div>

<!-- TOAST -->
<div class="tw">
<% if (flashErr != null && !flashErr.isEmpty()) { %>
<div class="toast er" id="tEr"><i class="fas fa-exclamation-circle"></i><span class="toast-msg"><%= sH(flashErr) %></span><button class="toast-x" onclick="rmT('tEr')">&times;</button></div>
<% } %>
</div>

<!-- PAGE HEADER -->
<div class="ph">
    <div>
        <h1><i class="fas fa-chart-bar"></i> Reports &amp; Analytics</h1>
        <p>Real-time hotel performance insights and data analytics</p>
    </div>
    <div style="display:flex;align-items:center;gap:.75rem;flex-wrap:wrap">
        <div class="date-badge"><i class="fas fa-calendar-alt"></i> <%= LocalDate.now().toString() %></div>
        <button class="btn-refresh" onclick="window.location.reload()"><i class="fas fa-sync-alt"></i> Refresh</button>
        <button class="btn-refresh no-print" onclick="window.print()" style="background:var(--g600)"><i class="fas fa-print"></i> Print</button>
    </div>
</div>

<!-- ══ KPI CARDS ══ -->
<div class="kpi-grid">
    <div class="kpi k1">
        <div class="kpi-top">
            <div>
                <div class="kpi-val">Rs. <%= totalRev %></div>
                <div class="kpi-sub">Total Revenue</div>
                <div class="kpi-label">All time collected</div>
            </div>
            <div class="kpi-icon"><i class="fas fa-rupee-sign"></i></div>
        </div>
        <div class="kpi-trend neutral"><i class="fas fa-calendar-alt"></i> This Month: Rs. <%= monthRev %></div>
    </div>
    <div class="kpi k2">
        <div class="kpi-top">
            <div>
                <div class="kpi-val"><%= totalRes %></div>
                <div class="kpi-sub">Total Reservations</div>
                <div class="kpi-label">All reservations</div>
            </div>
            <div class="kpi-icon"><i class="fas fa-calendar-check"></i></div>
        </div>
        <div class="kpi-trend up"><i class="fas fa-sign-in-alt"></i> Active: <%= checkedInRes %></div>
    </div>
    <div class="kpi k3">
        <div class="kpi-top">
            <div>
                <div class="kpi-val"><%= occRate %>%</div>
                <div class="kpi-sub">Occupancy Rate</div>
                <div class="kpi-label"><%= occupiedRms %> of <%= totalRooms %> rooms</div>
            </div>
            <div class="kpi-icon"><i class="fas fa-bed"></i></div>
        </div>
        <div class="kpi-trend neutral"><i class="fas fa-door-open"></i> Available: <%= availableRms %></div>
    </div>
    <div class="kpi k4">
        <div class="kpi-top">
            <div>
                <div class="kpi-val"><%= avgRating.isEmpty() ? "N/A" : avgRating %>/5</div>
                <div class="kpi-sub">Avg Guest Rating</div>
                <div class="kpi-label"><%= approvedRevs %> approved reviews</div>
            </div>
            <div class="kpi-icon"><i class="fas fa-star"></i></div>
        </div>
        <div class="kpi-trend neutral"><i class="fas fa-clock"></i> Pending: <%= pendingRevs %></div>
    </div>
</div>

<!-- ══ TODAY BOX ══ -->
<div class="today-grid">
    <div class="today-card">
        <h3><i class="fas fa-sign-in-alt"></i> Today's Check-Ins</h3>
        <div class="big-num"><%= todayCI %></div>
        <p>Guests arriving today</p>
    </div>
    <div class="today-card checkout-card">
        <h3><i class="fas fa-sign-out-alt"></i> Today's Check-Outs</h3>
        <div class="big-num"><%= todayCO %></div>
        <p>Guests departing today</p>
    </div>
</div>

<!-- ══ CHARTS ROW ══ -->
<div class="charts-row">
    <!-- Monthly Revenue Chart -->
    <div class="chart-card">
        <h3><i class="fas fa-chart-line"></i> Monthly Revenue (Last 6 Months)</h3>
        <div class="chart-wrap"><canvas id="revenueChart"></canvas></div>
    </div>
    <!-- Room Distribution Chart -->
    <div class="chart-card">
        <h3><i class="fas fa-chart-doughnut"></i> Room Status Distribution</h3>
        <div class="chart-wrap"><canvas id="roomChart"></canvas></div>
    </div>
</div>

<!-- ══ STATS ROW ══ -->
<div class="stats-row">
    <!-- Reservation Status -->
    <div class="stat-card">
        <h3><i class="fas fa-calendar-alt" style="color:var(--pri)"></i> Reservation Status</h3>
        <div class="stat-row"><span class="label">Pending</span><span class="val amber"><%= pendingRes %></span></div>
        <div class="stat-row"><span class="label">Confirmed</span><span class="val blue"><%= confirmedRes %></span></div>
        <div class="stat-row"><span class="label">Checked In</span><span class="val green"><%= checkedInRes %></span></div>
        <div class="stat-row"><span class="label">Checked Out</span><span class="val"><%= checkedOutRes %></span></div>
        <div class="stat-row"><span class="label">Cancelled</span><span class="val red"><%= cancelledRes %></span></div>
        <div class="prog-wrap">
            <div class="prog-label"><span>Completion Rate</span><span><% long comp = checkedOutRes; int compPct = totalRes > 0 ? (int)(comp*100/totalRes) : 0; %><%= compPct %>%</span></div>
            <div class="prog-bar"><div class="prog-fill" style="width:<%= compPct %>%;background:var(--ok)"></div></div>
        </div>
    </div>

    <!-- Room Status -->
    <div class="stat-card">
        <h3><i class="fas fa-bed" style="color:var(--acc)"></i> Room Status</h3>
        <div class="stat-row"><span class="label">Available</span><span class="val green"><%= availableRms %></span></div>
        <div class="stat-row"><span class="label">Occupied</span><span class="val red"><%= occupiedRms %></span></div>
        <div class="stat-row"><span class="label">Reserved</span><span class="val blue"><%= reservedRms %></span></div>
        <div class="stat-row"><span class="label">Maintenance</span><span class="val amber"><%= maintRms %></span></div>
        <div class="stat-row"><span class="label">Total Rooms</span><span class="val"><%= totalRooms %></span></div>
        <div class="prog-wrap">
            <div class="prog-label"><span>Occupancy</span><span><%= occRate %>%</span></div>
            <div class="prog-bar"><div class="prog-fill" style="width:<%= occRate %>%;background:var(--pri)"></div></div>
        </div>
    </div>

    <!-- Revenue Summary -->
    <div class="stat-card">
        <h3><i class="fas fa-rupee-sign" style="color:var(--ok)"></i> Revenue Summary</h3>
        <div class="stat-row"><span class="label">Today</span><span class="val green">Rs. <%= todayRev %></span></div>
        <div class="stat-row"><span class="label">This Month</span><span class="val blue">Rs. <%= monthRev %></span></div>
        <div class="stat-row"><span class="label">This Year</span><span class="val">Rs. <%= yearRev %></span></div>
        <div class="stat-row"><span class="label">All Time</span><span class="val">Rs. <%= totalRev %></span></div>
        <div class="stat-row"><span class="label">Avg Rating</span><span class="val amber"><i class="fas fa-star" style="font-size:.8rem"></i> <%= avgRating.isEmpty()?"N/A":avgRating %></span></div>
    </div>
</div>

<!-- ══ PAYMENT METHOD BREAKDOWN ══ -->
<div style="display:grid;grid-template-columns:1fr 1fr;gap:1.25rem;margin-bottom:1.5rem">
    <div class="tbl-card" style="margin-bottom:0">
        <div class="tbl-card-hdr">
            <h3><i class="fas fa-credit-card"></i> Revenue by Payment Method</h3>
        </div>
        <div style="padding:1rem 1.25rem">
        <% if (revByMeth.isEmpty()) { %>
        <p style="color:var(--g500);font-size:.85rem;text-align:center;padding:1rem">No payment data available.</p>
        <% } else { for (Map.Entry<String,Double> e : revByMeth.entrySet()) {
            String mName = e.getKey(); double mVal = e.getValue();
            String mIcon = "fas fa-money-bill-wave", mCls = "cash";
            if ("CARD".equals(mName))          { mIcon="fas fa-credit-card";  mCls="card"; }
            else if ("ONLINE".equals(mName))   { mIcon="fas fa-globe";        mCls="online"; }
            else if ("BANK_TRANSFER".equals(mName)){ mIcon="fas fa-university"; mCls="bank"; }
        %>
        <div class="method-row">
            <div class="method-icon <%= mCls %>"><i class="<%= mIcon %>"></i></div>
            <span class="method-name"><%= mName.replace("_"," ") %></span>
            <span class="method-amount">Rs. <%= String.format("%.2f", mVal) %></span>
        </div>
        <% }} %>
        </div>
    </div>

    <!-- Room Type Distribution -->
    <div class="tbl-card" style="margin-bottom:0">
        <div class="tbl-card-hdr">
            <h3><i class="fas fa-layer-group"></i> Room Type Distribution</h3>
        </div>
        <div style="padding:1rem 1.25rem">
        <% if (roomsByTyp.isEmpty()) { %>
        <p style="color:var(--g500);font-size:.85rem;text-align:center;padding:1rem">No room data available.</p>
        <% } else { for (Map.Entry<String,Long> e : roomsByTyp.entrySet()) {
            String rType = e.getKey(); long rCnt = e.getValue();
            int pct = totalRooms > 0 ? (int)(rCnt * 100 / totalRooms) : 0;
        %>
        <div class="prog-wrap" style="margin-bottom:.75rem">
            <div class="prog-label"><span style="font-weight:600;color:var(--g800)"><%= rType %></span><span style="font-weight:700;color:var(--pri)"><%= rCnt %> (<%= pct %>%)</span></div>
            <div class="prog-bar"><div class="prog-fill" style="width:<%= pct %>%;background:var(--pri)"></div></div>
        </div>
        <% }} %>
        </div>
    </div>
</div>

<!-- ══ RECENT RESERVATIONS TABLE ══ -->
<div class="tbl-card">
    <div class="tbl-card-hdr">
        <h3><i class="fas fa-calendar-alt"></i> Recent Reservations</h3>
        <a href="<%= ctx %>/admin/reservations" class="btn-refresh" style="font-size:.78rem;padding:.35rem .75rem"><i class="fas fa-external-link-alt"></i> View All</a>
    </div>
    <% if (recentRes.isEmpty()) { %>
    <p style="text-align:center;padding:2rem;color:var(--g500)">No reservations found.</p>
    <% } else { %>
    <div style="overflow-x:auto">
    <table class="rtbl">
        <thead><tr>
            <th>Res. No.</th><th>Guest</th><th>Room</th>
            <th>Check-In</th><th>Check-Out</th><th>Amount</th><th>Status</th>
        </tr></thead>
        <tbody>
        <% for (Reservation res : recentRes) {
            String rStat="b-pend", rLbl="PENDING", rIco="fa-clock";
            if (res.isConfirmed())  { rStat="b-conf"; rLbl="CONFIRMED";   rIco="fa-check-circle"; }
            else if (res.isCheckedIn())  { rStat="b-in";   rLbl="CHECKED IN";  rIco="fa-sign-in-alt"; }
            else if (res.isCheckedOut()) { rStat="b-out";  rLbl="CHECKED OUT"; rIco="fa-sign-out-alt"; }
            else if (res.isCancelled())  { rStat="b-canc"; rLbl="CANCELLED";   rIco="fa-times-circle"; }
            String rGuest = res.getGuestName() != null ? res.getGuestName() : "Guest #"+res.getGuestId();
            String rRoom  = res.getRoomNumber() != null ? "Room "+res.getRoomNumber() : "Room #"+res.getRoomId();
            String rCI    = res.getCheckInDate()  != null ? res.getCheckInDate().toString()  : "-";
            String rCO    = res.getCheckOutDate() != null ? res.getCheckOutDate().toString() : "-";
            String rAmt   = res.getFinalAmount()  != null ? "Rs. "+res.getFinalAmount().toPlainString() : "-";
            String rNum   = res.getReservationNumber() != null ? res.getReservationNumber() : "#"+res.getReservationId();
        %>
        <tr>
            <td style="font-weight:700;color:var(--pri)"><%= sH(rNum) %></td>
            <td style="font-weight:600"><%= sH(rGuest) %></td>
            <td style="color:var(--g700)"><%= sH(rRoom) %></td>
            <td style="font-size:.82rem"><%= rCI %></td>
            <td style="font-size:.82rem"><%= rCO %></td>
            <td style="font-weight:700;color:var(--pri)"><%= rAmt %></td>
            <td><span class="badge <%= rStat %>"><i class="fas <%= rIco %>"></i> <%= rLbl %></span></td>
        </tr>
        <% } %>
        </tbody>
    </table>
    </div>
    <% } %>
</div>

<!-- ══ RECENT PAYMENTS TABLE ══ -->
<div class="tbl-card">
    <div class="tbl-card-hdr">
        <h3><i class="fas fa-receipt"></i> Recent Payments</h3>
    </div>
    <% if (recentPay.isEmpty()) { %>
    <p style="text-align:center;padding:2rem;color:var(--g500)">No payment data found.</p>
    <% } else { %>
    <div style="overflow-x:auto">
    <table class="rtbl">
        <thead><tr>
            <th>Payment No.</th><th>Reservation</th><th>Method</th>
            <th>Date</th><th>Amount</th><th>Status</th>
        </tr></thead>
        <tbody>
        <% for (Payment pay : recentPay) {
            String pStat="b-pend", pLbl="PENDING";
            if (pay.isCompleted()) { pStat="b-comp"; pLbl="COMPLETED"; }
            else if (pay.isRefunded()) { pStat="b-ref"; pLbl="REFUNDED"; }
            else if (pay.isFailed())   { pStat="b-canc"; pLbl="FAILED"; }
            String pNum  = pay.getPaymentNumber() != null ? pay.getPaymentNumber() : "#"+pay.getPaymentId();
            String pRes  = "#"+pay.getReservationId();
            String pMeth = pay.getPaymentMethod() != null ? pay.getPaymentMethod().name().replace("_"," ") : "-";
            String pDate = pay.getPaymentDate() != null ? pay.getPaymentDate().toString().substring(0,10) : "-";
            String pAmt  = pay.getAmount() != null ? "Rs. "+pay.getAmount().toPlainString() : "-";
        %>
        <tr>
            <td style="font-weight:700;color:var(--pri)"><%= sH(pNum) %></td>
            <td style="color:var(--g700)">Res. <%= pRes %></td>
            <td style="font-size:.82rem"><%= pMeth %></td>
            <td style="font-size:.82rem"><%= pDate %></td>
            <td style="font-weight:700;color:var(--pri)"><%= pAmt %></td>
            <td><span class="badge <%= pStat %>"><%= pLbl %></span></td>
        </tr>
        <% } %>
        </tbody>
    </table>
    </div>
    <% } %>
</div>

</div><!-- /mc -->
</div><!-- /pw -->

<!-- ══ CHART DATA FROM SERVER ══ -->
<script id="CHART_DATA" type="application/json">
{
  "months": [<%
    boolean fM = true;
    for (String m : monthlyRev.keySet()) {
        if (!fM) out.print(",");
        fM = false;
        out.print("\"" + m + "\"");
    }
  %>],
  "revenue": [<%
    boolean fR = true;
    for (Double v : monthlyRev.values()) {
        if (!fR) out.print(",");
        fR = false;
        out.print(String.format("%.2f", v));
    }
  %>],
  "roomLabels": ["Available","Occupied","Reserved","Maintenance"],
  "roomData": [<%= availableRms %>,<%= occupiedRms %>,<%= reservedRms %>,<%= maintRms %>],
  "resLabels": ["Pending","Confirmed","Checked In","Checked Out","Cancelled"],
  "resData": [<%= pendingRes %>,<%= confirmedRes %>,<%= checkedInRes %>,<%= checkedOutRes %>,<%= cancelledRes %>]
}
</script>

<script>
/* ── TOAST ── */
function rmT(id){
    var t=document.getElementById(id); if(!t)return;
    t.style.animation='tOut .3s ease forwards';
    setTimeout(function(){if(t.parentNode)t.parentNode.removeChild(t);},320);
}
document.querySelectorAll('.toast').forEach(function(t){
    setTimeout(function(){t.style.animation='tOut .3s ease forwards';setTimeout(function(){if(t.parentNode)t.parentNode.removeChild(t);},320);},6000);
});

/* ── CHARTS ── */
var CD = JSON.parse(document.getElementById('CHART_DATA').textContent);

// Revenue Line Chart
var revCtx = document.getElementById('revenueChart').getContext('2d');
new Chart(revCtx, {
    type: 'line',
    data: {
        labels: CD.months,
        datasets: [{
            label: 'Revenue (Rs.)',
            data: CD.revenue,
            fill: true,
            backgroundColor: 'rgba(0,105,148,.12)',
            borderColor: '#006994',
            borderWidth: 2.5,
            pointBackgroundColor: '#006994',
            pointRadius: 5,
            pointHoverRadius: 7,
            tension: 0.4
        }]
    },
    options: {
        responsive: true,
        maintainAspectRatio: false,
        plugins: {
            legend: { display: false },
            tooltip: {
                callbacks: {
                    label: function(ctx) { return ' Rs. ' + parseFloat(ctx.raw).toLocaleString('en-IN', {minimumFractionDigits:2}); }
                }
            }
        },
        scales: {
            x: { grid: { display: false }, ticks: { font: { size: 11 } } },
            y: {
                grid: { color: 'rgba(0,0,0,.05)' },
                ticks: {
                    font: { size: 11 },
                    callback: function(v) { return 'Rs. ' + v.toLocaleString('en-IN'); }
                }
            }
        }
    }
});

// Room Status Doughnut Chart
var roomCtx = document.getElementById('roomChart').getContext('2d');
new Chart(roomCtx, {
    type: 'doughnut',
    data: {
        labels: CD.roomLabels,
        datasets: [{
            data: CD.roomData,
            backgroundColor: ['#28a745','#dc3545','#6f42c1','#ffc107'],
            borderWidth: 2,
            borderColor: '#fff',
            hoverOffset: 6
        }]
    },
    options: {
        responsive: true,
        maintainAspectRatio: false,
        plugins: {
            legend: {
                position: 'bottom',
                labels: { font: { size: 11 }, padding: 12, boxWidth: 14 }
            },
            tooltip: {
                callbacks: {
                    label: function(ctx) {
                        var total = ctx.dataset.data.reduce(function(a,b){return a+b;},0);
                        var pct = total > 0 ? Math.round(ctx.raw/total*100) : 0;
                        return ' ' + ctx.label + ': ' + ctx.raw + ' (' + pct + '%)';
                    }
                }
            }
        },
        cutout: '65%'
    }
});

/* ── ANIMATE PROGRESS BARS ── */
document.addEventListener('DOMContentLoaded', function() {
    document.querySelectorAll('.prog-fill').forEach(function(bar) {
        var w = bar.style.width;
        bar.style.width = '0';
        setTimeout(function() { bar.style.width = w; }, 300);
    });
});
</script>
</body>
</html>

