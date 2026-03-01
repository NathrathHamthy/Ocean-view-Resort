<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.util.List, java.util.ArrayList, com.oceanview.model.Review, com.oceanview.model.User" %>
<%!
    private String sJ(String s) {
        if (s == null) return "";
        return s.replace("\\","\\\\").replace("\"","\\\"").replace("\r","").replace("\n"," ").replace("'","\\'");
    }
    private String sH(String s) {
        if (s == null) return "";
        return s.replace("&","&amp;").replace("<","&lt;").replace(">","&gt;").replace("\"","&quot;").replace("'","&#39;");
    }
    private String stars(int n) {
        StringBuilder sb = new StringBuilder();
        for (int i = 1; i <= 5; i++) {
            if (i <= n) sb.append("<i class=\"fas fa-star\" style=\"color:#f59e0b\"></i>");
            else        sb.append("<i class=\"far fa-star\" style=\"color:#d1d5db\"></i>");
        }
        return sb.toString();
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
    List<Review> reviews = (List<Review>) request.getAttribute("reviews");
    if (reviews == null) reviews = new ArrayList<>();

    long pendingCount  = 0, approvedCount = 0, rejectedCount = 0, totalCount = 0;
    String avgRating = "0.0";
    Object pO = request.getAttribute("pendingCount");
    Object aO = request.getAttribute("approvedCount");
    Object rO = request.getAttribute("rejectedCount");
    Object tO = request.getAttribute("totalCount");
    Object avgO = request.getAttribute("avgRating");
    if (pO  != null) pendingCount  = ((Number)pO).longValue();
    if (aO  != null) approvedCount = ((Number)aO).longValue();
    if (rO  != null) rejectedCount = ((Number)rO).longValue();
    if (tO  != null) totalCount    = ((Number)tO).longValue();
    if (avgO != null) avgRating    = avgO.toString();

    String flashOk  = request.getAttribute("success") != null ? (String)request.getAttribute("success") : (String)session.getAttribute("success");
    String flashErr = request.getAttribute("error")   != null ? (String)request.getAttribute("error")   : (String)session.getAttribute("error");
    session.removeAttribute("success"); session.removeAttribute("successMessage");
    session.removeAttribute("error");   session.removeAttribute("errorMessage");

    String ctx = request.getContextPath();
    String statusFilter = request.getAttribute("statusFilter") != null ? (String)request.getAttribute("statusFilter") : "";
%>
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Reviews Management - Ocean View Resort</title>
<link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
<link rel="stylesheet" href="<%= ctx %>/assets/css/main.css">
<link rel="stylesheet" href="<%= ctx %>/assets/css/sidebar.css">
<style>
*,*::before,*::after{box-sizing:border-box;margin:0;padding:0}
body{display:block!important;flex-direction:unset!important;font-family:'Segoe UI',system-ui,sans-serif;background:#eef2f7;color:#343a40;min-height:100vh}
/* ── SIDEBAR VARS ── */
:root{
  --ocean-dark:#003d5c;--gold-accent:#D4AF37;--white:#fff;
  --spacing-xs:.25rem;--spacing-sm:.5rem;--spacing-md:1rem;--spacing-lg:1.5rem;
  --radius-sm:.25rem;--radius-md:.5rem;--transition-fast:.15s ease-in-out;
  --danger:#DC3545;--success:#28A745;--warning:#FFC107;
}
/* ── SIDEBAR FULL EMBED ── */
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
  --ok:#28a745;--er:#dc3545;--warn:#ffc107;--inf:#17a2b8;--pur:#6f42c1;--gold:#f59e0b;
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
.ph h1 i{color:var(--gold)}.ph p{color:var(--g600);font-size:.9rem;margin-top:.3rem}
/* ── STATS ── */
.stats{display:grid;grid-template-columns:repeat(4,1fr);gap:1.1rem;margin-bottom:1.75rem}
@media(max-width:1000px){.stats{grid-template-columns:repeat(2,1fr)}}
@media(max-width:480px){.stats{grid-template-columns:1fr}}
.sc{background:#fff;border-radius:var(--r);padding:1.1rem 1.25rem;display:flex;align-items:center;gap:.9rem;box-shadow:var(--sh1);border-left:4px solid transparent;transition:transform var(--tr),box-shadow var(--tr);cursor:pointer}
.sc:hover{transform:translateY(-3px);box-shadow:var(--sh2)}
.sc.sa{border-color:var(--ok)}.sc.sp{border-color:var(--warn)}.sc.sr{border-color:var(--er)}.sc.sg{border-color:var(--gold)}
.sc-ic{width:46px;height:46px;border-radius:var(--r2);display:flex;align-items:center;justify-content:center;font-size:1.25rem;color:#fff;flex-shrink:0}
.sc.sa .sc-ic{background:var(--ok)}.sc.sp .sc-ic{background:var(--warn)}.sc.sr .sc-ic{background:var(--er)}.sc.sg .sc-ic{background:var(--gold)}
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
.b-pend{background:#fff3cd;color:#856404}.b-appr{background:#d4edda;color:#155724}.b-rej{background:#f8d7da;color:#721c24}
/* ── STAR RATING ── */
.stars{display:inline-flex;gap:.1rem;align-items:center}
.stars i{font-size:.85rem}
.rating-num{font-weight:700;color:var(--g800);font-size:.9rem;margin-left:.3rem}
/* ── TABLE ── */
.table-wrap{background:#fff;border-radius:var(--r);box-shadow:var(--sh1);overflow:hidden}
.rtbl{width:100%;border-collapse:collapse;font-size:.875rem}
.rtbl thead{background:linear-gradient(135deg,#006994,#4A90A4)}
.rtbl thead th{padding:.85rem 1rem;text-align:left;font-weight:600;color:#fff;white-space:nowrap;font-size:.8rem;letter-spacing:.03em}
.rtbl thead th:first-child{padding-left:1.4rem}
.rtbl thead th:last-child{padding-right:1.4rem;text-align:center}
.rtbl tbody tr{border-bottom:1px solid var(--g100);transition:background var(--tr)}
.rtbl tbody tr:last-child{border-bottom:none}
.rtbl tbody tr:hover{background:var(--g50)}
.rtbl tbody td{padding:.78rem 1rem;vertical-align:middle}
.rtbl tbody td:first-child{padding-left:1.4rem;color:var(--g500);font-size:.8rem}
.rtbl tbody td:last-child{padding-right:1.4rem;text-align:center}
.guest-av{width:36px;height:36px;border-radius:50%;background:linear-gradient(135deg,var(--pri),var(--acc));display:inline-flex;align-items:center;justify-content:center;font-weight:700;font-size:.8rem;color:#fff;flex-shrink:0;margin-right:.5rem}
.guest-cell{display:flex;align-items:center}
.guest-name{font-weight:600;color:var(--g800);font-size:.88rem}
.guest-sub{font-size:.75rem;color:var(--g600);margin-top:.1rem}
.comment-preview{max-width:200px;white-space:nowrap;overflow:hidden;text-overflow:ellipsis;color:var(--g600);font-size:.82rem;font-style:italic}
.has-response{display:inline-flex;align-items:center;gap:.25rem;font-size:.75rem;color:var(--ok);font-weight:600}
.no-response{font-size:.75rem;color:var(--g400)}
/* ── BUTTONS ── */
.btn{display:inline-flex;align-items:center;justify-content:center;gap:.35rem;padding:.48rem .9rem;border:none;border-radius:var(--r2);font-size:.82rem;font-weight:600;cursor:pointer;text-decoration:none;transition:all var(--tr);white-space:nowrap;line-height:1.2}
.btn-sm{padding:.3rem .6rem;font-size:.76rem}
.btn-pri{background:var(--pri);color:#fff}.btn-pri:hover{background:var(--pri-dk)}
.btn-ok{background:var(--ok);color:#fff}.btn-ok:hover{filter:brightness(.9)}
.btn-warn{background:var(--warn);color:#000}.btn-warn:hover{filter:brightness(.9)}
.btn-er{background:var(--er);color:#fff}.btn-er:hover{filter:brightness(.9)}
.btn-sec{background:var(--g200);color:var(--g800)}.btn-sec:hover{background:var(--g300)}
.btn-inf{background:var(--inf);color:#fff}.btn-inf:hover{filter:brightness(.9)}
.btn-gold{background:var(--gold);color:#000}.btn-gold:hover{filter:brightness(.9)}
.abtns{display:flex;gap:.35rem;justify-content:center;flex-wrap:wrap}
/* ── EMPTY STATE ── */
.es{text-align:center;padding:4rem 2rem;color:var(--g600)}
.es i{font-size:3.5rem;color:var(--g300);display:block;margin-bottom:1rem}
.es h3{font-size:1.2rem;margin-bottom:.5rem;color:var(--g700)}
/* ── MODAL ── */
.mo{position:fixed;inset:0;background:rgba(0,0,0,.52);z-index:2000;display:flex;align-items:center;justify-content:center;padding:1rem;opacity:0;visibility:hidden;transition:opacity .28s ease,visibility .28s ease}
.mo.show{opacity:1;visibility:visible}
.md{background:#fff;border-radius:var(--r);width:100%;max-width:680px;max-height:93vh;display:flex;flex-direction:column;box-shadow:var(--sh3);transform:translateY(-18px) scale(.98);transition:transform .28s ease}
.mo.show .md{transform:translateY(0) scale(1)}
.md-sm{max-width:480px}.md-xs{max-width:420px}
.mh{padding:1.1rem 1.5rem;display:flex;align-items:center;justify-content:space-between;background:linear-gradient(135deg,var(--pri),var(--acc));border-radius:var(--r) var(--r) 0 0;color:#fff}
.mh.mh-er{background:linear-gradient(135deg,var(--er),#c82333)}
.mh.mh-gold{background:linear-gradient(135deg,#d97706,var(--gold))}
.mh h2{font-size:1.1rem;font-weight:700;display:flex;align-items:center;gap:.5rem}
.mx{background:none;border:none;font-size:1.5rem;color:#fff;cursor:pointer;opacity:.75;line-height:1;padding:0;transition:opacity var(--tr)}
.mx:hover{opacity:1}
.mb{padding:1.4rem 1.5rem;overflow-y:auto;flex:1}
.mf{padding:.9rem 1.5rem;border-top:1px solid var(--g200);display:flex;justify-content:flex-end;gap:.65rem;background:var(--g50);border-radius:0 0 var(--r) var(--r)}
/* ── VIEW MODAL DETAIL ROWS ── */
.dg{display:grid;grid-template-columns:1fr 1fr;gap:.7rem}
@media(max-width:520px){.dg{grid-template-columns:1fr}}
.di{display:flex;flex-direction:column;gap:.2rem;padding:.6rem .85rem;background:var(--g50);border-radius:var(--r2);border:1px solid var(--g100)}
.di.fw{grid-column:1/-1}
.di label{font-size:.72rem;font-weight:700;color:var(--g600);text-transform:uppercase;letter-spacing:.05em}
.di span{font-size:.9rem;font-weight:600;color:var(--g800)}
.di .comment-full{font-size:.88rem;font-weight:400;color:var(--g700);line-height:1.6;font-style:italic;white-space:pre-wrap}
/* ── FORM ── */
.fc{padding:.56rem .85rem;border:1.5px solid var(--g300);border-radius:var(--r2);font-size:.88rem;outline:none;transition:border var(--tr),box-shadow var(--tr);width:100%;font-family:inherit;background:#fff;color:var(--g800)}
.fc:focus{border-color:var(--pri);box-shadow:0 0 0 3px rgba(0,105,148,.11)}
textarea.fc{resize:vertical;min-height:100px}
.fl{font-size:.82rem;font-weight:600;color:var(--g700);display:block;margin-bottom:.32rem}
/* ── DELETE CONFIRM ── */
.di-icon{text-align:center;font-size:2.8rem;margin-bottom:1rem}
.di-txt{text-align:center;color:var(--g600);line-height:1.6}
.di-txt strong{color:var(--g800)}
/* ── RATING SUMMARY BAR ── */
.avg-badge{display:inline-flex;align-items:center;gap:.5rem;background:linear-gradient(135deg,var(--gold),#d97706);color:#fff;padding:.5rem 1.1rem;border-radius:var(--r2);font-weight:700;font-size:1rem}
.avg-badge i{font-size:1.1rem}
</style>
</head>
<body>
<div class="pw">
<jsp:include page="../common/sidebar.jsp">
    <jsp:param name="active" value="reviews"/>
</jsp:include>

<div class="mc">

<!-- MOBILE TOPBAR -->
<div class="mtb">
    <button class="mtb-btn" onclick="document.getElementById('sidebar').classList.toggle('open');document.getElementById('sidebarOverlay').classList.toggle('active')">
        <i class="fas fa-bars"></i>
    </button>
    <span class="mtb-title"><i class="fas fa-star"></i> Reviews Management</span>
</div>

<!-- TOASTS -->
<div class="tw">
<% if (flashOk  != null && !flashOk.isEmpty())  { %><div class="toast ok" id="tOk"><i class="fas fa-check-circle"></i><span class="toast-msg"><%= sH(flashOk) %></span><button class="toast-x" onclick="rmT('tOk')">&times;</button></div><% } %>
<% if (flashErr != null && !flashErr.isEmpty()) { %><div class="toast er" id="tEr"><i class="fas fa-exclamation-circle"></i><span class="toast-msg"><%= sH(flashErr) %></span><button class="toast-x" onclick="rmT('tEr')">&times;</button></div><% } %>
</div>

<!-- PAGE HEADER -->
<div class="ph">
    <div>
        <h1><i class="fas fa-star"></i> Reviews Management</h1>
        <p>Moderate guest reviews, approve, reject and respond to feedback</p>
    </div>
    <div class="avg-badge"><i class="fas fa-star"></i> Avg Rating: <%= avgRating %> / 5</div>
</div>

<!-- STATS -->
<div class="stats">
    <div class="sc sa" onclick="applyFilter('APPROVED')" title="Show Approved">
        <div class="sc-ic"><i class="fas fa-check-circle"></i></div>
        <div class="sc-info"><h3><%= approvedCount %></h3><p>Approved</p></div>
    </div>
    <div class="sc sp" onclick="applyFilter('PENDING')" title="Show Pending">
        <div class="sc-ic"><i class="fas fa-clock"></i></div>
        <div class="sc-info"><h3><%= pendingCount %></h3><p>Pending</p></div>
    </div>
    <div class="sc sr" onclick="applyFilter('REJECTED')" title="Show Rejected">
        <div class="sc-ic"><i class="fas fa-times-circle"></i></div>
        <div class="sc-info"><h3><%= rejectedCount %></h3><p>Rejected</p></div>
    </div>
    <div class="sc sg" onclick="applyFilter('')" title="Show All">
        <div class="sc-ic"><i class="fas fa-list"></i></div>
        <div class="sc-info"><h3><%= totalCount %></h3><p>Total Reviews</p></div>
    </div>
</div>

<!-- TOOLBAR -->
<div class="tb">
    <div class="tb-l">
        <div class="sb"><i class="fas fa-search"></i>
            <input type="text" id="srch" placeholder="Search guest, comment..." oninput="doFilter()">
        </div>
        <select class="fs" id="fStat" onchange="doFilter()">
            <option value="">All Status</option>
            <option value="PENDING"  <%= "PENDING".equals(statusFilter)  ? "selected":"" %>>Pending</option>
            <option value="APPROVED" <%= "APPROVED".equals(statusFilter) ? "selected":"" %>>Approved</option>
            <option value="REJECTED" <%= "REJECTED".equals(statusFilter) ? "selected":"" %>>Rejected</option>
        </select>
        <select class="fs" id="fRating" onchange="doFilter()">
            <option value="">All Ratings</option>
            <option value="5">&#9733;&#9733;&#9733;&#9733;&#9733; 5 Stars</option>
            <option value="4">&#9733;&#9733;&#9733;&#9733; 4 Stars</option>
            <option value="3">&#9733;&#9733;&#9733; 3 Stars</option>
            <option value="2">&#9733;&#9733; 2 Stars</option>
            <option value="1">&#9733; 1 Star</option>
        </select>
    </div>
    <div class="tb-r">
        <button class="btn btn-sec btn-sm" onclick="clearFilters()"><i class="fas fa-times"></i> Clear</button>
    </div>
</div>

<!-- SECTION HEADER -->
<div class="sh">
    <h2><i class="fas fa-comments" style="color:var(--gold);margin-right:.4rem"></i>All Reviews</h2>
    <span class="rc" id="rCount"><%= reviews.size() %> review(s)</span>
</div>

<!-- TABLE -->
<% if (reviews.isEmpty()) { %>
<div class="es"><i class="fas fa-star"></i><h3>No Reviews Found</h3><p>No reviews match your current filters.</p></div>
<% } else { %>
<div class="table-wrap">
<table class="rtbl">
    <thead><tr>
        <th>#</th>
        <th>Guest</th>
        <th>Rating</th>
        <th>Cleanliness</th>
        <th>Service</th>
        <th>Value</th>
        <th>Comment</th>
        <th>Response</th>
        <th>Status</th>
        <th>Date</th>
        <th>Actions</th>
    </tr></thead>
    <tbody id="tBody">
    <%
    int rowN = 1;
    for (Review rev : reviews) {
        String statCss = "b-pend", statLbl = "PENDING", statIco = "fa-clock";
        if (rev.isApproved()) { statCss="b-appr"; statLbl="APPROVED"; statIco="fa-check-circle"; }
        else if (rev.isRejected()) { statCss="b-rej"; statLbl="REJECTED"; statIco="fa-times-circle"; }

        int    rid     = rev.getReviewId();
        int    rating  = rev.getRating();
        String comment = rev.getComment() != null ? rev.getComment() : "";
        String resp    = rev.getResponse() != null ? rev.getResponse() : "";
        String statName = rev.getStatus().name();
        String dateStr  = rev.getCreatedAt() != null ? rev.getCreatedAt().toString().substring(0,10) : "-";

        // Guest name from associated guest or fallback
        String guestName = "Guest #" + rev.getGuestId();
        if (rev.getGuest() != null) {
            String fn = rev.getGuest().getFirstName() != null ? rev.getGuest().getFirstName() : "";
            String ln = rev.getGuest().getLastName()  != null ? rev.getGuest().getLastName()  : "";
            if (!fn.isEmpty() || !ln.isEmpty()) guestName = (fn + " " + ln).trim();
        }
        String initials = guestName.length() >= 2
            ? String.valueOf(guestName.charAt(0)).toUpperCase()
            : "G";

        // Sub-ratings
        String clnStr  = rev.getCleanlinessRating() != null ? String.valueOf(rev.getCleanlinessRating()) : "-";
        String svcStr  = rev.getServiceRating()     != null ? String.valueOf(rev.getServiceRating())     : "-";
        String valStr  = rev.getValueRating()       != null ? String.valueOf(rev.getValueRating())       : "-";

        String commentPreview = comment.length() > 60 ? comment.substring(0,60) + "..." : comment;
        boolean hasResp = !resp.isEmpty();
    %>
    <tr data-stat="<%= statName %>" data-rating="<%= rating %>"
        data-search="<%= sH(guestName.toLowerCase()) %> <%= sH(comment.toLowerCase()) %>">
        <td><%= rowN++ %></td>
        <td>
            <div class="guest-cell">
                <div class="guest-av"><%= initials %></div>
                <div>
                    <div class="guest-name"><%= sH(guestName) %></div>
                    <div class="guest-sub">Review #<%= rid %></div>
                </div>
            </div>
        </td>
        <td>
            <div class="stars"><%= stars(rating) %></div>
            <span class="rating-num"><%= rating %>/5</span>
        </td>
        <td style="text-align:center;font-weight:600;color:var(--g700)"><%= clnStr %></td>
        <td style="text-align:center;font-weight:600;color:var(--g700)"><%= svcStr %></td>
        <td style="text-align:center;font-weight:600;color:var(--g700)"><%= valStr %></td>
        <td><div class="comment-preview" title="<%= sH(comment) %>"><i class="fas fa-quote-left" style="color:var(--g400);font-size:.7rem;margin-right:.3rem"></i><%= sH(commentPreview) %></div></td>
        <td style="text-align:center">
            <% if (hasResp) { %>
            <span class="has-response"><i class="fas fa-reply"></i> Replied</span>
            <% } else { %>
            <span class="no-response"><i class="fas fa-minus"></i></span>
            <% } %>
        </td>
        <td><span class="badge <%= statCss %>"><i class="fas <%= statIco %>"></i> <%= statLbl %></span></td>
        <td style="font-size:.8rem;color:var(--g600);white-space:nowrap"><%= dateStr %></td>
        <td>
            <div class="abtns">
                <button class="btn btn-pri btn-sm" onclick="openView(<%= rid %>)" title="View"><i class="fas fa-eye"></i></button>
                <button class="btn btn-gold btn-sm" onclick="openRespond(<%= rid %>)" title="Respond"><i class="fas fa-reply"></i></button>
                <% if (rev.isPending()) { %>
                <button class="btn btn-ok btn-sm" onclick="openAction(<%= rid %>,'approve')" title="Approve"><i class="fas fa-check"></i></button>
                <button class="btn btn-er btn-sm" onclick="openAction(<%= rid %>,'reject')"  title="Reject"><i class="fas fa-times"></i></button>
                <% } else if (rev.isApproved()) { %>
                <button class="btn btn-er btn-sm" onclick="openAction(<%= rid %>,'reject')"  title="Reject"><i class="fas fa-times"></i></button>
                <% } else if (rev.isRejected()) { %>
                <button class="btn btn-ok btn-sm" onclick="openAction(<%= rid %>,'approve')" title="Approve"><i class="fas fa-check"></i></button>
                <% } %>
                <button class="btn btn-er btn-sm" onclick="openDelete(<%= rid %>)" title="Delete"><i class="fas fa-trash-alt"></i></button>
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
for (Review rev : reviews) {
    if (!firstR) out.print(",");
    firstR = false;
    int    rid    = rev.getReviewId();
    int    rating = rev.getRating();
    String comment= rev.getComment()  != null ? rev.getComment()  : "";
    String resp   = rev.getResponse() != null ? rev.getResponse() : "";
    String stat   = rev.getStatus().name();
    String dateS  = rev.getCreatedAt() != null ? rev.getCreatedAt().toString().substring(0,10) : "-";
    String gname  = "Guest #" + rev.getGuestId();
    if (rev.getGuest() != null) {
        String fn = rev.getGuest().getFirstName() != null ? rev.getGuest().getFirstName() : "";
        String ln = rev.getGuest().getLastName()  != null ? rev.getGuest().getLastName()  : "";
        if (!fn.isEmpty() || !ln.isEmpty()) gname = (fn + " " + ln).trim();
    }
    int cln = rev.getCleanlinessRating() != null ? rev.getCleanlinessRating() : 0;
    int svc = rev.getServiceRating()     != null ? rev.getServiceRating()     : 0;
    int val = rev.getValueRating()       != null ? rev.getValueRating()       : 0;
    int resId = rev.getReservationId() != null ? rev.getReservationId() : 0;
%>
{"id":<%= rid %>,"rating":<%= rating %>,"cln":<%= cln %>,"svc":<%= svc %>,"val":<%= val %>,"comment":"<%= sJ(comment) %>","resp":"<%= sJ(resp) %>","status":"<%= stat %>","date":"<%= dateS %>","guest":"<%= sJ(gname) %>","resId":<%= resId %>}
<% } %>
]
</script>

<!-- ══ VIEW MODAL ══ -->
<div class="mo" id="mView">
<div class="md">
    <div class="mh"><h2><i class="fas fa-eye"></i> Review Details</h2><button class="mx" onclick="cM('mView')">&times;</button></div>
    <div class="mb">
        <div class="dg">
            <div class="di"><label>Guest</label><span id="vGuest"></span></div>
            <div class="di"><label>Status</label><span id="vStat"></span></div>
            <div class="di"><label>Overall Rating</label><span id="vRating"></span></div>
            <div class="di"><label>Date Submitted</label><span id="vDate"></span></div>
            <div class="di"><label>Cleanliness</label><span id="vCln"></span></div>
            <div class="di"><label>Service</label><span id="vSvc"></span></div>
            <div class="di"><label>Value for Money</label><span id="vVal"></span></div>
            <div class="di"><label>Reservation ID</label><span id="vResId"></span></div>
            <div class="di fw"><label>Comment</label><span id="vComment" class="comment-full"></span></div>
            <div class="di fw" id="vRespBox" style="display:none"><label><i class="fas fa-reply" style="color:var(--ok)"></i> Management Response</label><span id="vResp" class="comment-full"></span></div>
        </div>
    </div>
    <div class="mf">
        <button type="button" class="btn btn-sec" onclick="cM('mView')"><i class="fas fa-times"></i> Close</button>
        <button type="button" class="btn btn-gold" onclick="openRespondFromView()"><i class="fas fa-reply"></i> Respond</button>
    </div>
</div>
</div>

<!-- ══ RESPOND MODAL ══ -->
<div class="mo" id="mResp">
<div class="md md-sm">
    <div class="mh mh-gold"><h2><i class="fas fa-reply"></i> Respond to Review</h2><button class="mx" onclick="cM('mResp')">&times;</button></div>
    <div class="mb">
        <div style="background:var(--g50);border-radius:var(--r2);padding:1rem;margin-bottom:1rem;border:1px solid var(--g200)">
            <div style="font-size:.78rem;font-weight:700;color:var(--g600);text-transform:uppercase;margin-bottom:.4rem">Guest Comment</div>
            <div id="rComment" style="font-size:.88rem;color:var(--g700);font-style:italic;line-height:1.6"></div>
        </div>
        <div id="rExistingBox" style="display:none;background:#d4edda;border-radius:var(--r2);padding:1rem;margin-bottom:1rem;border:1px solid #c3e6cb">
            <div style="font-size:.78rem;font-weight:700;color:#155724;text-transform:uppercase;margin-bottom:.4rem"><i class="fas fa-info-circle"></i> Existing Response</div>
            <div id="rExisting" style="font-size:.88rem;color:#155724;line-height:1.6"></div>
        </div>
        <form id="respForm" method="post" action="<%= ctx %>/admin/reviews">
            <input type="hidden" name="action" value="respond">
            <input type="hidden" name="id" id="rRevId">
            <label class="fl" for="rText">Your Response <span style="color:var(--er)">*</span></label>
            <textarea class="fc" id="rText" name="response" rows="5" placeholder="Write a professional response to this guest review..."></textarea>
        </form>
    </div>
    <div class="mf">
        <button type="button" class="btn btn-sec" onclick="cM('mResp')"><i class="fas fa-times"></i> Cancel</button>
        <button type="button" class="btn btn-gold" onclick="submitResp()"><i class="fas fa-paper-plane"></i> Send Response</button>
    </div>
</div>
</div>

<!-- ══ ACTION CONFIRM MODAL ══ -->
<div class="mo" id="mAct">
<div class="md md-xs">
    <div class="mh" id="mActHdr"><h2 id="mActTitle"><i class="fas fa-check"></i> Confirm</h2><button class="mx" onclick="cM('mAct')">&times;</button></div>
    <div class="mb" style="padding:2rem 1.5rem;text-align:center">
        <div class="di-icon" id="mActIcon"></div>
        <div class="di-txt" id="mActBody"></div>
    </div>
    <div class="mf">
        <button type="button" class="btn btn-sec" onclick="cM('mAct')"><i class="fas fa-times"></i> Cancel</button>
        <form id="actForm" method="post" action="<%= ctx %>/admin/reviews" style="display:inline">
            <input type="hidden" name="action" id="actAction">
            <input type="hidden" name="id"     id="actId">
            <button type="submit" class="btn" id="actBtn"><i class="fas fa-check"></i> <span id="actBtnTxt">Confirm</span></button>
        </form>
    </div>
</div>
</div>

<!-- ══ DELETE MODAL ══ -->
<div class="mo" id="mDel">
<div class="md md-xs">
    <div class="mh mh-er"><h2><i class="fas fa-trash-alt"></i> Delete Review</h2><button class="mx" onclick="cM('mDel')">&times;</button></div>
    <div class="mb" style="padding:2rem 1.5rem;text-align:center">
        <div class="di-icon"><i class="fas fa-exclamation-triangle" style="color:var(--er)"></i></div>
        <div class="di-txt">
            <p>Are you sure you want to permanently delete <strong id="dRevLbl">this review</strong>?</p>
            <p style="margin-top:.6rem;font-size:.82rem;color:var(--er)"><i class="fas fa-info-circle"></i> This action cannot be undone.</p>
        </div>
    </div>
    <div class="mf">
        <button type="button" class="btn btn-sec" onclick="cM('mDel')"><i class="fas fa-times"></i> Cancel</button>
        <form id="delForm" method="post" action="<%= ctx %>/admin/reviews" style="display:inline">
            <input type="hidden" name="action" value="delete">
            <input type="hidden" name="id" id="dRevId">
            <button type="submit" class="btn btn-er"><i class="fas fa-trash-alt"></i> Yes, Delete</button>
        </form>
    </div>
</div>
</div>

<script>
/* ── DATA ── */
var RD = JSON.parse(document.getElementById('RDS').textContent);
var RM = {}; RD.forEach(function(r){ RM[r.id]=r; });
var CTX = '<%= ctx %>';
var curViewId = null;

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

/* ── STAR HTML ── */
function starHtml(n){
    var h=''; for(var i=1;i<=5;i++) h+='<i class="'+(i<=n?'fas':'far')+' fa-star" style="color:'+(i<=n?'#f59e0b':'#d1d5db')+'"></i>';
    return h;
}
/* ── STATUS BADGE HTML ── */
function statBadge(s){
    var m={'PENDING':'background:#fff3cd;color:#856404','APPROVED':'background:#d4edda;color:#155724','REJECTED':'background:#f8d7da;color:#721c24'};
    return '<span style="'+(m[s]||'')+';padding:.22rem .7rem;border-radius:1rem;font-size:.76rem;font-weight:700;display:inline-block">'+s+'</span>';
}

/* ── FILTER ── */
function doFilter(){
    var s=document.getElementById('srch').value.toLowerCase().trim();
    var st=document.getElementById('fStat').value.toUpperCase();
    var rat=document.getElementById('fRating').value;
    var vis=0;
    document.querySelectorAll('#tBody tr').forEach(function(r){
        var ds=(r.dataset.search||'').toLowerCase();
        var rs=(r.dataset.stat||'').toUpperCase();
        var rr=r.dataset.rating||'';
        var show=(!s||ds.includes(s))&&(!st||rs===st)&&(!rat||rr===rat);
        r.style.display=show?'':'none'; if(show)vis++;
    });
    document.getElementById('rCount').textContent=vis+' review(s)';
}
function applyFilter(s){document.getElementById('fStat').value=s;doFilter();}
function clearFilters(){
    document.getElementById('srch').value='';
    document.getElementById('fStat').value='';
    document.getElementById('fRating').value='';
    doFilter();
}

/* ── VIEW MODAL ── */
function openView(id){
    var r=RM[id]; if(!r){alert('Data not found.');return;}
    curViewId=id;
    document.getElementById('vGuest').textContent=r.guest;
    document.getElementById('vStat').innerHTML=statBadge(r.status);
    document.getElementById('vRating').innerHTML=starHtml(r.rating)+' <strong style="margin-left:.3rem">'+r.rating+'/5</strong>';
    document.getElementById('vDate').textContent=r.date;
    document.getElementById('vCln').textContent=r.cln>0?r.cln+'/5':'-';
    document.getElementById('vSvc').textContent=r.svc>0?r.svc+'/5':'-';
    document.getElementById('vVal').textContent=r.val>0?r.val+'/5':'-';
    document.getElementById('vResId').textContent=r.resId>0?'#'+r.resId:'-';
    document.getElementById('vComment').textContent=r.comment||'No comment provided.';
    var rbox=document.getElementById('vRespBox');
    if(r.resp){rbox.style.display='';document.getElementById('vResp').textContent=r.resp;}
    else{rbox.style.display='none';}
    oM('mView');
}
function openRespondFromView(){cM('mView');setTimeout(function(){openRespond(curViewId);},200);}

/* ── RESPOND MODAL ── */
function openRespond(id){
    var r=RM[id]; if(!r){alert('Data not found.');return;}
    document.getElementById('rRevId').value=id;
    document.getElementById('rComment').textContent=r.comment||'No comment.';
    document.getElementById('rText').value=r.resp||'';
    var eb=document.getElementById('rExistingBox');
    if(r.resp){eb.style.display='';document.getElementById('rExisting').textContent=r.resp;}
    else{eb.style.display='none';}
    oM('mResp');
}
function submitResp(){
    var txt=document.getElementById('rText').value.trim();
    if(!txt){alert('Please write a response before submitting.');return;}
    document.getElementById('respForm').submit();
}

/* ── ACTION MODAL (approve/reject) ── */
var actCfg = {
    approve:{title:'Approve Review',icon:'<i class="fas fa-check-circle" style="color:var(--ok);font-size:3rem"></i>',hdr:'mh',btnCls:'btn-ok',btnTxt:'Yes, Approve',body:'Approve this review? It will become visible to all guests.'},
    reject: {title:'Reject Review', icon:'<i class="fas fa-times-circle" style="color:var(--er);font-size:3rem"></i>',hdr:'mh-er',btnCls:'btn-er',btnTxt:'Yes, Reject', body:'Reject this review? It will be hidden from public view.'}
};
function openAction(id,action){
    var r=RM[id]; if(!r){alert('Data not found.');return;}
    var c=actCfg[action]; if(!c)return;
    document.getElementById('mActHdr').className='mh '+c.hdr;
    document.getElementById('mActTitle').innerHTML='<i class="fas fa-exclamation-triangle"></i> '+c.title;
    document.getElementById('mActIcon').innerHTML=c.icon;
    document.getElementById('mActBody').innerHTML='<p style="margin-bottom:.5rem"><strong>Review #'+id+' by '+r.guest+'</strong></p><p style="color:var(--g600)">'+c.body+'</p>';
    document.getElementById('actAction').value=action;
    document.getElementById('actId').value=id;
    document.getElementById('actBtn').className='btn '+c.btnCls;
    document.getElementById('actBtnTxt').textContent=c.btnTxt;
    oM('mAct');
}

/* ── DELETE MODAL ── */
function openDelete(id){
    var r=RM[id]; if(!r){alert('Data not found.');return;}
    document.getElementById('dRevLbl').textContent='Review #'+id+' by '+r.guest;
    document.getElementById('dRevId').value=id;
    oM('mDel');
}

/* ── INIT ── */
(function(){
    document.getElementById('rCount').textContent=RD.length+' review(s)';
    doFilter();
})();
</script>
</body>
</html>

