<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.util.List, java.util.ArrayList, com.oceanview.model.Offer, com.oceanview.model.User, java.time.LocalDate" %>
<%!
    private String sJ(String s) {
        if (s == null) return "";
        return s.replace("\\","\\\\").replace("\"","\\\"").replace("\r","").replace("\n"," ").replace("'","\\'");
    }
    private String sH(String s) {
        if (s == null) return "";
        return s.replace("&","&amp;").replace("<","&lt;").replace(">","&gt;").replace("\"","&quot;").replace("'","&#39;");
    }
    private boolean isOfferExpired(Offer o) {
        if (o.getEndDate() == null) return false;
        return o.getEndDate().isBefore(LocalDate.now());
    }
    private boolean isOfferActive(Offer o) {
        if (o.getOfferStatus() == null) return false;
        return o.getOfferStatus() == Offer.OfferStatus.ACTIVE && !isOfferExpired(o);
    }
%>
<%
    User cu = (User) session.getAttribute("loggedInUser");
    if (cu == null) cu = (User) session.getAttribute("user");
    if (cu == null || !"ADMIN".equals(cu.getRole().toString())) {
        response.sendRedirect(request.getContextPath() + "/login");
        return;
    }

    @SuppressWarnings("unchecked")
    List<Offer> offers = (List<Offer>) request.getAttribute("offers");
    if (offers == null) offers = new ArrayList<>();

    long activeCount = 0, inactiveCount = 0, expiredCount = 0;
    for (Offer o : offers) {
        if (isOfferExpired(o))                                               expiredCount++;
        else if (o.getOfferStatus() == Offer.OfferStatus.ACTIVE)            activeCount++;
        else                                                                  inactiveCount++;
    }

    String flashOk  = request.getAttribute("success") != null ? (String)request.getAttribute("success") : (String)session.getAttribute("success");
    String flashErr = request.getAttribute("error")   != null ? (String)request.getAttribute("error")   : (String)session.getAttribute("error");
    session.removeAttribute("success"); session.removeAttribute("successMessage");
    session.removeAttribute("error");   session.removeAttribute("errorMessage");

    String ctx = request.getContextPath();
    LocalDate today = LocalDate.now();
%>
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Offers Management - Ocean View Resort</title>
<link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
<link rel="stylesheet" href="<%= ctx %>/assets/css/main.css">
<link rel="stylesheet" href="<%= ctx %>/assets/css/sidebar.css">
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
  --ok:#28a745;--er:#dc3545;--warn:#ffc107;--inf:#17a2b8;--pur:#6f42c1;--teal:#20c997;
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
.mtb-btn{background:none;border:none;font-size:1.25rem;color:var(--pri);cursor:pointer;padding:.3rem .5rem;border-radius:.35rem;transition:background var(--tr)}
.mtb-btn:hover{background:var(--g100)}
.mtb-title{font-size:1rem;font-weight:700;color:var(--g800)}
.mtb-title i{color:var(--teal);margin-right:.3rem}
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
.ph h1 i{color:var(--teal)}.ph p{color:var(--g600);font-size:.9rem;margin-top:.3rem}
.btn-add{display:inline-flex;align-items:center;gap:.5rem;padding:.72rem 1.4rem;background:var(--teal);color:#fff;border:none;border-radius:var(--r2);font-size:.92rem;font-weight:600;cursor:pointer;transition:all var(--tr);box-shadow:0 2px 8px rgba(32,201,151,.3)}
.btn-add:hover{background:#1aad81;box-shadow:0 4px 12px rgba(32,201,151,.4)}
/* ── STATS ── */
.stats{display:grid;grid-template-columns:repeat(4,1fr);gap:1.1rem;margin-bottom:1.75rem}
@media(max-width:1000px){.stats{grid-template-columns:repeat(2,1fr)}}
@media(max-width:480px){.stats{grid-template-columns:1fr}}
.sc{background:#fff;border-radius:var(--r);padding:1.1rem 1.25rem;display:flex;align-items:center;gap:.9rem;box-shadow:var(--sh1);border-left:4px solid transparent;transition:transform var(--tr),box-shadow var(--tr);cursor:pointer}
.sc:hover{transform:translateY(-3px);box-shadow:var(--sh2)}
.sc.sa{border-color:var(--ok)}.sc.si{border-color:var(--g400)}.sc.se{border-color:var(--er)}.sc.st{border-color:var(--teal)}
.sc-ic{width:46px;height:46px;border-radius:var(--r2);display:flex;align-items:center;justify-content:center;font-size:1.25rem;color:#fff;flex-shrink:0}
.sc.sa .sc-ic{background:var(--ok)}.sc.si .sc-ic{background:var(--g500)}.sc.se .sc-ic{background:var(--er)}.sc.st .sc-ic{background:var(--teal)}
.sc-info h3{font-size:1.7rem;font-weight:700;line-height:1;color:var(--g800)}
.sc-info p{font-size:.78rem;color:var(--g600);margin-top:.2rem}
/* ── TOOLBAR ── */
.tb{background:#fff;border-radius:var(--r);padding:.9rem 1.25rem;margin-bottom:1.25rem;display:flex;align-items:center;gap:.75rem;flex-wrap:wrap;box-shadow:var(--sh1)}
.tb-l{display:flex;align-items:center;gap:.6rem;flex:1;flex-wrap:wrap}
.tb-r{display:flex;align-items:center;gap:.6rem}
.sb{position:relative}
.sb i{position:absolute;left:.8rem;top:50%;transform:translateY(-50%);color:var(--g500);font-size:.85rem;pointer-events:none}
.sb input{padding:.52rem .9rem .52rem 2.2rem;border:1.5px solid var(--g200);border-radius:var(--r2);font-size:.86rem;width:240px;outline:none;transition:border var(--tr);background:var(--g50);color:var(--g800)}
.sb input:focus{border-color:var(--pri);background:#fff}
.fs{padding:.52rem .9rem;border:1.5px solid var(--g200);border-radius:var(--r2);font-size:.86rem;outline:none;cursor:pointer;background:var(--g50);color:var(--g800);transition:border var(--tr)}
.fs:focus{border-color:var(--pri)}
/* ── SECTION HEADER ── */
.sh{display:flex;justify-content:space-between;align-items:center;margin-bottom:1rem}
.sh h2{font-size:1rem;font-weight:700;color:var(--g700)}
.rc{font-size:.82rem;color:var(--g600);background:var(--g100);padding:.25rem .7rem;border-radius:1rem}
/* ── STATUS BADGES ── */
.badge{display:inline-flex;align-items:center;gap:.3rem;padding:.22rem .7rem;border-radius:1rem;font-size:.7rem;font-weight:700;text-transform:uppercase;letter-spacing:.05em;white-space:nowrap}
.b-act{background:#d4edda;color:#155724}.b-ina{background:#e2e3e5;color:#383d41}.b-exp{background:#f8d7da;color:#721c24}
/* ── DISCOUNT BADGE ── */
.disc-badge{display:inline-flex;align-items:center;gap:.3rem;padding:.3rem .75rem;border-radius:var(--r2);font-weight:700;font-size:.85rem}
.disc-pct{background:linear-gradient(135deg,#d97706,#f59e0b);color:#fff}
.disc-fix{background:linear-gradient(135deg,var(--pri),var(--acc));color:#fff}
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
.offer-name{font-weight:700;color:var(--g800);font-size:.9rem}
.offer-desc{font-size:.78rem;color:var(--g600);margin-top:.15rem;max-width:180px;white-space:nowrap;overflow:hidden;text-overflow:ellipsis}
.promo-code{display:inline-flex;align-items:center;gap:.3rem;background:var(--g100);border:1.5px dashed var(--g400);padding:.18rem .6rem;border-radius:var(--r2);font-family:monospace;font-size:.8rem;font-weight:700;color:var(--g700);letter-spacing:.05em}
.usage-bar{width:80px;height:6px;background:var(--g200);border-radius:3px;overflow:hidden;display:inline-block;vertical-align:middle;margin-right:.4rem}
.usage-fill{height:100%;background:var(--teal);border-radius:3px;transition:width .3s ease}
.date-cell{font-size:.8rem;white-space:nowrap}
/* ── BUTTONS ── */
.btn{display:inline-flex;align-items:center;justify-content:center;gap:.35rem;padding:.48rem .9rem;border:none;border-radius:var(--r2);font-size:.82rem;font-weight:600;cursor:pointer;text-decoration:none;transition:all var(--tr);white-space:nowrap;line-height:1.2}
.btn-sm{padding:.3rem .6rem;font-size:.76rem}
.btn-pri{background:var(--pri);color:#fff}.btn-pri:hover{background:var(--pri-dk)}
.btn-ok{background:var(--ok);color:#fff}.btn-ok:hover{filter:brightness(.9)}
.btn-warn{background:var(--warn);color:#000}.btn-warn:hover{filter:brightness(.9)}
.btn-er{background:var(--er);color:#fff}.btn-er:hover{filter:brightness(.9)}
.btn-sec{background:var(--g200);color:var(--g800)}.btn-sec:hover{background:var(--g300)}
.btn-teal{background:var(--teal);color:#fff}.btn-teal:hover{filter:brightness(.9)}
.abtns{display:flex;gap:.35rem;justify-content:center;flex-wrap:wrap}
/* ── EMPTY STATE ── */
.es{text-align:center;padding:4rem 2rem;color:var(--g600)}
.es i{font-size:3.5rem;color:var(--g300);display:block;margin-bottom:1rem}
.es h3{font-size:1.2rem;margin-bottom:.5rem;color:var(--g700)}
/* ── MODAL ── */
.mo{position:fixed;inset:0;background:rgba(0,0,0,.52);z-index:2000;display:flex;align-items:center;justify-content:center;padding:1rem;opacity:0;visibility:hidden;transition:opacity .28s ease,visibility .28s ease}
.mo.show{opacity:1;visibility:visible}
.md{background:#fff;border-radius:var(--r);width:100%;max-width:720px;max-height:93vh;display:flex;flex-direction:column;box-shadow:var(--sh3);transform:translateY(-18px) scale(.98);transition:transform .28s ease}
.mo.show .md{transform:translateY(0) scale(1)}
.md-sm{max-width:480px}.md-xs{max-width:420px}
.mh{padding:1.1rem 1.5rem;display:flex;align-items:center;justify-content:space-between;background:linear-gradient(135deg,var(--teal),#1aad81);border-radius:var(--r) var(--r) 0 0;color:#fff}
.mh.mh-pri{background:linear-gradient(135deg,var(--pri),var(--acc))}
.mh.mh-er{background:linear-gradient(135deg,var(--er),#c82333)}
.mh h2{font-size:1.1rem;font-weight:700;display:flex;align-items:center;gap:.5rem}
.mx{background:none;border:none;font-size:1.5rem;color:#fff;cursor:pointer;opacity:.75;line-height:1;padding:0;transition:opacity var(--tr)}
.mx:hover{opacity:1}
.mb{padding:1.4rem 1.5rem;overflow-y:auto;flex:1}
.mf{padding:.9rem 1.5rem;border-top:1px solid var(--g200);display:flex;justify-content:flex-end;gap:.65rem;background:var(--g50);border-radius:0 0 var(--r) var(--r)}
/* ── FORM ── */
.fg{display:grid;grid-template-columns:1fr 1fr;gap:.85rem}
@media(max-width:540px){.fg{grid-template-columns:1fr}}
.fi{display:flex;flex-direction:column;gap:.3rem}
.fi.fw{grid-column:1/-1}
.fl{font-size:.82rem;font-weight:600;color:var(--g700)}
.fl .rq{color:var(--er);margin-left:.15rem}
.fc{padding:.56rem .85rem;border:1.5px solid var(--g300);border-radius:var(--r2);font-size:.88rem;outline:none;transition:border var(--tr),box-shadow var(--tr);width:100%;font-family:inherit;background:#fff;color:var(--g800)}
.fc:focus{border-color:var(--teal);box-shadow:0 0 0 3px rgba(32,201,151,.12)}
.fc.fe{border-color:var(--er)}
.fe-msg{font-size:.76rem;color:var(--er);min-height:.85rem}
textarea.fc{resize:vertical;min-height:75px}
/* ── DELETE CONFIRM ── */
.di-icon{text-align:center;font-size:2.8rem;margin-bottom:1rem}
.di-txt{text-align:center;color:var(--g600);line-height:1.6}
.di-txt strong{color:var(--g800)}
</style>
</head>
<body>
<div class="pw">
<jsp:include page="../common/sidebar.jsp">
    <jsp:param name="active" value="offers"/>
</jsp:include>

<div class="mc">

<!-- MOBILE TOPBAR -->
<div class="mtb">
    <button class="mtb-btn" onclick="document.getElementById('sidebar').classList.toggle('open');document.getElementById('sidebarOverlay').classList.toggle('active')">
        <i class="fas fa-bars"></i>
    </button>
    <span class="mtb-title"><i class="fas fa-tags"></i> Offers Management</span>
</div>

<!-- TOASTS -->
<div class="tw">
<% if (flashOk  != null && !flashOk.isEmpty())  { %><div class="toast ok" id="tOk"><i class="fas fa-check-circle"></i><span class="toast-msg"><%= sH(flashOk) %></span><button class="toast-x" onclick="rmT('tOk')">&times;</button></div><% } %>
<% if (flashErr != null && !flashErr.isEmpty()) { %><div class="toast er" id="tEr"><i class="fas fa-exclamation-circle"></i><span class="toast-msg"><%= sH(flashErr) %></span><button class="toast-x" onclick="rmT('tEr')">&times;</button></div><% } %>
</div>

<!-- PAGE HEADER -->
<div class="ph">
    <div>
        <h1><i class="fas fa-tags"></i> Offers Management</h1>
        <p>Create and manage special offers, promotions and promo codes</p>
    </div>
    <button class="btn-add" onclick="openAddModal()"><i class="fas fa-plus"></i> Add New Offer</button>
</div>

<!-- STATS -->
<div class="stats">
    <div class="sc sa" onclick="applyFilter('ACTIVE')" title="Show Active">
        <div class="sc-ic"><i class="fas fa-check-circle"></i></div>
        <div class="sc-info"><h3><%= activeCount %></h3><p>Active</p></div>
    </div>
    <div class="sc si" onclick="applyFilter('INACTIVE')" title="Show Inactive">
        <div class="sc-ic"><i class="fas fa-pause-circle"></i></div>
        <div class="sc-info"><h3><%= inactiveCount %></h3><p>Inactive</p></div>
    </div>
    <div class="sc se" onclick="applyFilter('EXPIRED')" title="Show Expired">
        <div class="sc-ic"><i class="fas fa-clock"></i></div>
        <div class="sc-info"><h3><%= expiredCount %></h3><p>Expired</p></div>
    </div>
    <div class="sc st" onclick="applyFilter('')" title="Show All">
        <div class="sc-ic"><i class="fas fa-tags"></i></div>
        <div class="sc-info"><h3><%= offers.size() %></h3><p>Total Offers</p></div>
    </div>
</div>

<!-- TOOLBAR -->
<div class="tb">
    <div class="tb-l">
        <div class="sb"><i class="fas fa-search"></i>
            <input type="text" id="srch" placeholder="Search offer name, promo code..." oninput="doFilter()">
        </div>
        <select class="fs" id="fStat" onchange="doFilter()">
            <option value="">All Status</option>
            <option value="ACTIVE">Active</option>
            <option value="INACTIVE">Inactive</option>
            <option value="EXPIRED">Expired</option>
        </select>
        <select class="fs" id="fType" onchange="doFilter()">
            <option value="">All Discount Types</option>
            <option value="PERCENTAGE">Percentage</option>
            <option value="FIXED_AMOUNT">Fixed Amount</option>
        </select>
    </div>
    <div class="tb-r">
        <button class="btn btn-sec btn-sm" onclick="clearFilters()"><i class="fas fa-times"></i> Clear</button>
    </div>
</div>

<!-- SECTION HEADER -->
<div class="sh">
    <h2><i class="fas fa-list" style="color:var(--teal);margin-right:.4rem"></i>All Offers</h2>
    <span class="rc" id="rCount"><%= offers.size() %> offer(s)</span>
</div>

<!-- TABLE -->
<% if (offers.isEmpty()) { %>
<div class="es"><i class="fas fa-tags"></i><h3>No Offers Found</h3><p>Click "Add New Offer" to create your first promotion.</p></div>
<% } else { %>
<div class="table-wrap">
<table class="rtbl">
    <thead><tr>
        <th>#</th>
        <th>Offer Name</th>
        <th>Discount</th>
        <th>Promo Code</th>
        <th>Valid Period</th>
        <th>Min Stay</th>
        <th>Usage</th>
        <th>Status</th>
        <th>Actions</th>
    </tr></thead>
    <tbody id="tBody">
    <%
    int rowN = 1;
    for (Offer o : offers) {
        boolean expired = isOfferExpired(o);
        boolean active  = isOfferActive(o);
        String statCss, statLbl, statIco;
        String filterStat;
        if (expired) {
            statCss="b-exp"; statLbl="EXPIRED"; statIco="fa-clock"; filterStat="EXPIRED";
        } else if (o.getOfferStatus() == Offer.OfferStatus.ACTIVE) {
            statCss="b-act"; statLbl="ACTIVE"; statIco="fa-check-circle"; filterStat="ACTIVE";
        } else {
            statCss="b-ina"; statLbl="INACTIVE"; statIco="fa-pause-circle"; filterStat="INACTIVE";
        }

        int    oid     = o.getOfferId();
        String oName   = o.getOfferName()   != null ? o.getOfferName()   : "";
        String oDesc   = o.getDescription() != null ? o.getDescription() : "";
        String oPromo  = o.getPromoCode()   != null ? o.getPromoCode()   : "";
        String oDType  = o.getDiscountType() != null ? o.getDiscountType().name() : "PERCENTAGE";
        String oDVal   = o.getDiscountValue() != null ? o.getDiscountValue().toPlainString() : "0";
        String oStart  = o.getStartDate()   != null ? o.getStartDate().toString()  : "";
        String oEnd    = o.getEndDate()     != null ? o.getEndDate().toString()    : "";
        int    oMinSt  = o.getMinStayNights() != null ? o.getMinStayNights() : 0;
        int    oMaxUs  = o.getMaxUses()     != null ? o.getMaxUses()     : 0;
        int    oUsed   = o.getUsedCount()   != null ? o.getUsedCount()   : 0;
        int    usagePct = oMaxUs > 0 ? Math.min(100, oUsed * 100 / oMaxUs) : 0;
        String discDisplay = oDType.equals("PERCENTAGE") ? oDVal + "%" : "Rs. " + oDVal;
        String oStatName = o.getOfferStatus() != null ? o.getOfferStatus().name() : "INACTIVE";
    %>
    <tr data-stat="<%= filterStat %>" data-type="<%= oDType %>"
        data-search="<%= sH(oName.toLowerCase()) %> <%= sH(oPromo.toLowerCase()) %>">
        <td><%= rowN++ %></td>
        <td>
            <div class="offer-name"><%= sH(oName) %></div>
            <div class="offer-desc" title="<%= sH(oDesc) %>"><%= sH(oDesc) %></div>
        </td>
        <td>
            <span class="disc-badge <%= oDType.equals("PERCENTAGE") ? "disc-pct" : "disc-fix" %>">
                <i class="fas <%= oDType.equals("PERCENTAGE") ? "fa-percent" : "fa-rupee-sign" %>"></i>
                <%= discDisplay %>
            </span>
        </td>
        <td>
            <% if (!oPromo.isEmpty()) { %>
            <span class="promo-code"><i class="fas fa-ticket-alt"></i><%= sH(oPromo) %></span>
            <% } else { %><span style="color:var(--g400);font-size:.8rem">None</span><% } %>
        </td>
        <td>
            <div class="date-cell"><i class="fas fa-calendar-alt" style="color:var(--ok);margin-right:.3rem;font-size:.75rem"></i><%= oStart %></div>
            <div class="date-cell" style="margin-top:.2rem"><i class="fas fa-calendar-times" style="color:var(--er);margin-right:.3rem;font-size:.75rem"></i><%= oEnd %></div>
        </td>
        <td style="text-align:center;font-weight:600;color:var(--g700)">
            <%= oMinSt > 0 ? oMinSt + " night(s)" : "-" %>
        </td>
        <td>
            <% if (oMaxUs > 0) { %>
            <div style="display:flex;align-items:center;gap:.4rem">
                <div class="usage-bar"><div class="usage-fill" style="width:<%= usagePct %>%"></div></div>
                <span style="font-size:.78rem;color:var(--g600)"><%= oUsed %>/<%= oMaxUs %></span>
            </div>
            <% } else { %>
            <span style="font-size:.78rem;color:var(--g500)"><%= oUsed %> used</span>
            <% } %>
        </td>
        <td><span class="badge <%= statCss %>"><i class="fas <%= statIco %>"></i> <%= statLbl %></span></td>
        <td>
            <div class="abtns">
                <button class="btn btn-pri btn-sm" onclick="openEditModal(<%= oid %>)" title="Edit"><i class="fas fa-edit"></i></button>
                <button class="btn btn-warn btn-sm" onclick="openToggle(<%= oid %>)" title="Toggle Status"><i class="fas fa-sync-alt"></i></button>
                <button class="btn btn-er btn-sm" onclick="openDelete(<%= oid %>)" title="Delete"><i class="fas fa-trash-alt"></i></button>
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
<script id="ODS" type="application/json">
[<%
boolean firstO = true;
for (Offer o : offers) {
    if (!firstO) out.print(",");
    firstO = false;
    int    oid    = o.getOfferId();
    String oName  = o.getOfferName()    != null ? sJ(o.getOfferName())    : "";
    String oDesc  = o.getDescription()  != null ? sJ(o.getDescription())  : "";
    String oPromo = o.getPromoCode()    != null ? sJ(o.getPromoCode())    : "";
    String oDType = o.getDiscountType() != null ? o.getDiscountType().name() : "PERCENTAGE";
    String oDVal  = o.getDiscountValue()!= null ? o.getDiscountValue().toPlainString() : "0";
    String oStart = o.getStartDate()    != null ? o.getStartDate().toString()  : "";
    String oEnd   = o.getEndDate()      != null ? o.getEndDate().toString()    : "";
    int    oMinSt = o.getMinStayNights()!= null ? o.getMinStayNights() : 0;
    int    oMaxUs = o.getMaxUses()      != null ? o.getMaxUses()       : 0;
    int    oUsed  = o.getUsedCount()    != null ? o.getUsedCount()     : 0;
    String oStat  = o.getOfferStatus()  != null ? o.getOfferStatus().name() : "INACTIVE";
    boolean exp   = isOfferExpired(o);
%>
{"id":<%= oid %>,"name":"<%= oName %>","desc":"<%= oDesc %>","promo":"<%= oPromo %>","dtype":"<%= oDType %>","dval":"<%= oDVal %>","start":"<%= oStart %>","end":"<%= oEnd %>","minSt":<%= oMinSt %>,"maxUs":<%= oMaxUs %>,"used":<%= oUsed %>,"status":"<%= oStat %>","expired":<%= exp %>}
<% } %>
]
</script>

<!-- ══ ADD / EDIT MODAL ══ -->
<div class="mo" id="mOffer">
<div class="md">
    <div class="mh" id="mOfferHdr"><h2 id="mOfferTitle"><i class="fas fa-plus-circle"></i> Add New Offer</h2><button class="mx" onclick="cM('mOffer')">&times;</button></div>
    <div class="mb">
        <form id="offerForm" method="post" action="<%= ctx %>/admin/offers" autocomplete="off">
            <input type="hidden" name="action" id="fAction" value="create">
            <input type="hidden" name="id"     id="fId">
            <div class="fg">
                <!-- Offer Name -->
                <div class="fi fw">
                    <label class="fl" for="fName">Offer Name <span class="rq">*</span></label>
                    <input type="text" class="fc" id="fName" name="offerName" placeholder="e.g. Summer Special 2026" maxlength="100">
                    <span class="fe-msg" id="eName"></span>
                </div>
                <!-- Discount Type -->
                <div class="fi">
                    <label class="fl" for="fDType">Discount Type <span class="rq">*</span></label>
                    <select class="fc" id="fDType" name="discountType" onchange="updateDiscLabel()">
                        <option value="PERCENTAGE">Percentage (%)</option>
                        <option value="FIXED_AMOUNT">Fixed Amount (Rs.)</option>
                    </select>
                </div>
                <!-- Discount Value -->
                <div class="fi">
                    <label class="fl" for="fDVal"><span id="dValLabel">Discount Value (%)</span> <span class="rq">*</span></label>
                    <input type="number" class="fc" id="fDVal" name="discountValue" min="0" step="0.01" placeholder="e.g. 20">
                    <span class="fe-msg" id="eDVal"></span>
                </div>
                <!-- Start Date -->
                <div class="fi">
                    <label class="fl" for="fStart">Start Date <span class="rq">*</span></label>
                    <input type="date" class="fc" id="fStart" name="startDate">
                    <span class="fe-msg" id="eStart"></span>
                </div>
                <!-- End Date -->
                <div class="fi">
                    <label class="fl" for="fEnd">End Date <span class="rq">*</span></label>
                    <input type="date" class="fc" id="fEnd" name="endDate">
                    <span class="fe-msg" id="eEnd"></span>
                </div>
                <!-- Min Stay -->
                <div class="fi">
                    <label class="fl" for="fMinSt">Minimum Stay (nights)</label>
                    <input type="number" class="fc" id="fMinSt" name="minStay" min="0" placeholder="e.g. 2 (0 = no min)">
                </div>
                <!-- Max Uses -->
                <div class="fi">
                    <label class="fl" for="fMaxUs">Maximum Uses</label>
                    <input type="number" class="fc" id="fMaxUs" name="maxUses" min="0" placeholder="e.g. 100 (0 = unlimited)">
                </div>
                <!-- Promo Code -->
                <div class="fi">
                    <label class="fl" for="fPromo">Promo Code</label>
                    <input type="text" class="fc" id="fPromo" name="promoCode" placeholder="e.g. SUMMER20" maxlength="50" style="text-transform:uppercase">
                </div>
                <!-- Status -->
                <div class="fi">
                    <label class="fl" for="fStat2">Status <span class="rq">*</span></label>
                    <select class="fc" id="fStat2" name="status">
                        <option value="ACTIVE">Active</option>
                        <option value="INACTIVE">Inactive</option>
                    </select>
                </div>
                <!-- Description -->
                <div class="fi fw">
                    <label class="fl" for="fDesc">Description</label>
                    <textarea class="fc" id="fDesc" name="description" rows="3" placeholder="Describe this offer..."></textarea>
                </div>
            </div>
        </form>
    </div>
    <div class="mf">
        <button type="button" class="btn btn-sec" onclick="cM('mOffer')"><i class="fas fa-times"></i> Cancel</button>
        <button type="button" class="btn btn-teal" onclick="doSubmit()"><i class="fas fa-save"></i> <span id="saveTxt">Save Offer</span></button>
    </div>
</div>
</div>

<!-- ══ TOGGLE STATUS MODAL ══ -->
<div class="mo" id="mToggle">
<div class="md md-xs">
    <div class="mh mh-pri"><h2><i class="fas fa-sync-alt"></i> Toggle Offer Status</h2><button class="mx" onclick="cM('mToggle')">&times;</button></div>
    <div class="mb" style="padding:2rem 1.5rem;text-align:center">
        <div class="di-icon"><i class="fas fa-exchange-alt" style="color:var(--pri)"></i></div>
        <div class="di-txt" id="tToggleBody">Toggle this offer status?</div>
    </div>
    <div class="mf">
        <button type="button" class="btn btn-sec" onclick="cM('mToggle')"><i class="fas fa-times"></i> Cancel</button>
        <form id="toggleForm" method="post" action="<%= ctx %>/admin/offers" style="display:inline">
            <input type="hidden" name="action" value="toggleStatus">
            <input type="hidden" name="id"     id="tToggleId">
            <button type="submit" class="btn btn-warn"><i class="fas fa-sync-alt"></i> Yes, Toggle</button>
        </form>
    </div>
</div>
</div>

<!-- ══ DELETE MODAL ══ -->
<div class="mo" id="mDel">
<div class="md md-xs">
    <div class="mh mh-er"><h2><i class="fas fa-trash-alt"></i> Delete Offer</h2><button class="mx" onclick="cM('mDel')">&times;</button></div>
    <div class="mb" style="padding:2rem 1.5rem;text-align:center">
        <div class="di-icon"><i class="fas fa-exclamation-triangle" style="color:var(--er)"></i></div>
        <div class="di-txt">
            <p>Are you sure you want to permanently delete <strong id="dOfferLbl">this offer</strong>?</p>
            <p style="margin-top:.6rem;font-size:.82rem;color:var(--er)"><i class="fas fa-info-circle"></i> This action cannot be undone.</p>
        </div>
    </div>
    <div class="mf">
        <button type="button" class="btn btn-sec" onclick="cM('mDel')"><i class="fas fa-times"></i> Cancel</button>
        <form id="delForm" method="post" action="<%= ctx %>/admin/offers" style="display:inline">
            <input type="hidden" name="action" value="delete">
            <input type="hidden" name="id" id="dOfferId">
            <button type="submit" class="btn btn-er"><i class="fas fa-trash-alt"></i> Yes, Delete</button>
        </form>
    </div>
</div>
</div>

<script>
/* ── DATA ── */
var OD = JSON.parse(document.getElementById('ODS').textContent);
var OM = {}; OD.forEach(function(o){ OM[o.id]=o; });
var CTX = '<%= ctx %>';

/* ── TOAST ── */
function rmT(id){
    var t=document.getElementById(id); if(!t)return;
    t.style.animation='tOut .3s ease forwards';
    setTimeout(function(){if(t.parentNode)t.parentNode.removeChild(t);},320);
}
document.querySelectorAll('.toast').forEach(function(t){
    setTimeout(function(){t.style.animation='tOut .3s ease forwards';setTimeout(function(){if(t.parentNode)t.parentNode.removeChild(t);},320);},5000);
});

/* ── MODAL ── */
function oM(id){document.getElementById(id).classList.add('show');document.body.style.overflow='hidden';}
function cM(id){document.getElementById(id).classList.remove('show');document.body.style.overflow='';}
document.querySelectorAll('.mo').forEach(function(o){
    o.addEventListener('click',function(e){if(e.target===o)cM(o.id);});
});
document.addEventListener('keydown',function(e){
    if(e.key==='Escape')document.querySelectorAll('.mo.show').forEach(function(m){cM(m.id);});
});

/* ── DISC LABEL ── */
function updateDiscLabel(){
    var dt=document.getElementById('fDType').value;
    document.getElementById('dValLabel').textContent=dt==='PERCENTAGE'?'Discount Value (%)':'Discount Value (Rs.)';
}

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
    document.getElementById('rCount').textContent=vis+' offer(s)';
}
function applyFilter(s){document.getElementById('fStat').value=s;doFilter();}
function clearFilters(){
    document.getElementById('srch').value='';
    document.getElementById('fStat').value='';
    document.getElementById('fType').value='';
    doFilter();
}

/* ── FORM RESET ── */
function resetForm(){
    document.getElementById('offerForm').reset();
    document.querySelectorAll('.fe-msg').forEach(function(e){e.textContent='';});
    document.querySelectorAll('.fc.fe').forEach(function(f){f.classList.remove('fe');});
    updateDiscLabel();
}

/* ── VALIDATE ── */
function validate(){
    var ok=true;
    function chk(fid,eid,msg){
        var f=document.getElementById(fid),e=document.getElementById(eid);
        if(msg){f.classList.add('fe');if(e)e.textContent=msg;ok=false;}
        else{f.classList.remove('fe');if(e)e.textContent='';}
    }
    chk('fName', 'eName',  !document.getElementById('fName').value.trim()?'Offer name is required.':'');
    chk('fDVal', 'eDVal',  !document.getElementById('fDVal').value||parseFloat(document.getElementById('fDVal').value)<0?'Enter a valid discount value.':'');
    chk('fStart','eStart', !document.getElementById('fStart').value?'Start date is required.':'');
    chk('fEnd',  'eEnd',   !document.getElementById('fEnd').value?'End date is required.':
                            document.getElementById('fEnd').value<document.getElementById('fStart').value?'End date must be after start date.':'');
    return ok;
}

/* ── ADD MODAL ── */
function openAddModal(){
    resetForm();
    document.getElementById('mOfferHdr').className='mh';
    document.getElementById('mOfferTitle').innerHTML='<i class="fas fa-plus-circle"></i> Add New Offer';
    document.getElementById('fAction').value='create';
    document.getElementById('fId').value='';
    document.getElementById('saveTxt').textContent='Save Offer';
    document.getElementById('fStat2').value='ACTIVE';
    // Set default start date to today
    var today=new Date().toISOString().split('T')[0];
    document.getElementById('fStart').value=today;
    oM('mOffer');
}

/* ── EDIT MODAL ── */
function openEditModal(id){
    var o=OM[id]; if(!o){alert('Offer data not found.');return;}
    resetForm();
    document.getElementById('mOfferHdr').className='mh mh-pri';
    document.getElementById('mOfferTitle').innerHTML='<i class="fas fa-edit"></i> Edit Offer';
    document.getElementById('fAction').value='update';
    document.getElementById('fId').value=o.id;
    document.getElementById('saveTxt').textContent='Update Offer';
    document.getElementById('fName').value=o.name;
    document.getElementById('fDType').value=o.dtype;
    document.getElementById('fDVal').value=o.dval;
    document.getElementById('fStart').value=o.start;
    document.getElementById('fEnd').value=o.end;
    document.getElementById('fMinSt').value=o.minSt>0?o.minSt:'';
    document.getElementById('fMaxUs').value=o.maxUs>0?o.maxUs:'';
    document.getElementById('fPromo').value=o.promo;
    document.getElementById('fStat2').value=o.status;
    document.getElementById('fDesc').value=o.desc;
    updateDiscLabel();
    oM('mOffer');
}

/* ── SUBMIT ── */
function doSubmit(){
    if(validate()) document.getElementById('offerForm').submit();
}

/* ── TOGGLE MODAL ── */
function openToggle(id){
    var o=OM[id]; if(!o){alert('Offer data not found.');return;}
    var newStat=o.status==='ACTIVE'?'INACTIVE':'ACTIVE';
    document.getElementById('tToggleBody').innerHTML=
        '<p><strong>'+o.name+'</strong></p>'+
        '<p style="margin-top:.5rem;color:var(--g600)">This offer is currently <strong>'+o.status+'</strong>.<br>Toggle to <strong>'+newStat+'</strong>?</p>';
    document.getElementById('tToggleId').value=id;
    oM('mToggle');
}

/* ── DELETE MODAL ── */
function openDelete(id){
    var o=OM[id]; if(!o){alert('Offer data not found.');return;}
    document.getElementById('dOfferLbl').textContent='"'+o.name+'"';
    document.getElementById('dOfferId').value=id;
    oM('mDel');
}

/* ── PROMO CODE UPPERCASE ── */
document.getElementById('fPromo').addEventListener('input',function(){
    this.value=this.value.toUpperCase();
});

/* ── INIT ── */
(function(){
    document.getElementById('rCount').textContent=OD.length+' offer(s)';
})();
</script>
</body>
</html>

