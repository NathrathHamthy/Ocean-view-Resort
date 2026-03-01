<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.util.*, com.oceanview.model.*, com.oceanview.util.Constants" %>
<%!
    private String sH(String s){ if(s==null)return ""; return s.replace("&","&amp;").replace("<","&lt;").replace(">","&gt;").replace("\"","&quot;"); }
    private String sv(Map<String,String> m, String k, String def){ if(m==null||!m.containsKey(k))return def; String v=m.get(k); return v!=null?v:def; }
    private boolean sb(Map<String,String> m, String k, boolean def){ if(m==null||!m.containsKey(k))return def; return "true".equalsIgnoreCase(m.get(k)); }
%>
<%
    User cu = (User) session.getAttribute(Constants.SESSION_USER);
    if (cu == null) cu = (User) session.getAttribute("loggedInUser");
    if (cu == null || !cu.isAdmin()) { response.sendRedirect(request.getContextPath() + "/login"); return; }

    @SuppressWarnings("unchecked") Map<String,List<HotelSetting>> grouped = (Map<String,List<HotelSetting>>) request.getAttribute("settingsGrouped");
    @SuppressWarnings("unchecked") Map<String,String> sMap = (Map<String,String>) request.getAttribute("settingsMap");
    @SuppressWarnings("unchecked") Map<String,String> sysInfo = (Map<String,String>) request.getAttribute("systemInfo");
    if (grouped  == null) grouped  = new LinkedHashMap<>();
    if (sMap     == null) sMap     = new LinkedHashMap<>();
    if (sysInfo  == null) sysInfo  = new LinkedHashMap<>();

    String flashOk  = (String) session.getAttribute(Constants.ATTR_SUCCESS);
    String flashErr = (String) session.getAttribute(Constants.ATTR_ERROR);
    session.removeAttribute(Constants.ATTR_SUCCESS);
    session.removeAttribute(Constants.ATTR_ERROR);

    String activeTab = request.getParameter("tab") != null ? request.getParameter("tab") : "general";
    String ctx = request.getContextPath();

    // Shortcut values from DB settings
    String appName    = sv(sMap,"app.name","Ocean View Resort");
    String appVer     = sv(sMap,"app.version","1.0.0");
    String appDesc    = sv(sMap,"app.description","Luxury beachfront resort");
    String timezone   = sv(sMap,"app.timezone","Asia/Colombo");
    String sessionTO  = sv(sMap,"session.timeout","30");
    String currency   = sv(sMap,"billing.currency","LKR");
    String currSymbol = sv(sMap,"billing.currency.symbol","Rs.");
    String taxRate    = sv(sMap,"billing.tax.percentage","10.0");
    String svcCharge  = sv(sMap,"billing.service.charge.percentage","5.0");
    String pwdMinLen  = sv(sMap,"security.password.min.length","8");
    String maxLogin   = sv(sMap,"security.max.login.attempts","5");
    String lockout    = sv(sMap,"security.lockout.duration","30");
    boolean reqSpecial= sb(sMap,"security.password.require.special.char",true);
    boolean reqNum    = sb(sMap,"security.password.require.number",true);
    boolean reqUpper  = sb(sMap,"security.password.require.uppercase",true);
    boolean featSMS   = sb(sMap,"features.sms.notifications",false);
    boolean featPDF   = sb(sMap,"features.pdf.generation",true);
    boolean featAudit = sb(sMap,"features.audit.logging",true);
    boolean featRevs  = sb(sMap,"features.reviews.enabled",true);
    boolean featOffs  = sb(sMap,"features.offers.enabled",true);
    String cEmail     = sv(sMap,"contact.email","info@oceanviewresort.com");
    String cPhone     = sv(sMap,"contact.phone","+94 11 234 5678");
    String cAddress   = sv(sMap,"contact.address","123 Beach Road, Colombo, Sri Lanka");
    String cWebsite   = sv(sMap,"contact.website","www.oceanviewresort.com");
    boolean notifBook = sb(sMap,"notification.booking.confirmation",true);
    boolean notifCI   = sb(sMap,"notification.checkin.reminder",true);
    boolean notifCO   = sb(sMap,"notification.checkout.reminder",true);
    int memPct = 0;
    try { memPct = Integer.parseInt(sysInfo.getOrDefault("memoryPct","0")); } catch(Exception e){}
    List<HotelSetting> customSettings = new ArrayList<>();
    for(Map.Entry<String,List<HotelSetting>> e : grouped.entrySet()){
        String cat = e.getKey();
        if(!cat.equals("GENERAL")&&!cat.equals("SESSION")&&!cat.equals("BILLING")&&!cat.equals("SECURITY")&&!cat.equals("FEATURES")&&!cat.equals("CONTACT")&&!cat.equals("NOTIFICATION")&&!cat.equals("UPLOAD")){
            customSettings.addAll(e.getValue());
        }
    }
%>
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Settings - Ocean View Resort Admin</title>
<link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
<link rel="stylesheet" href="<%= ctx %>/assets/css/main.css">
<link rel="stylesheet" href="<%= ctx %>/assets/css/sidebar.css">
<style>
*,*::before,*::after{box-sizing:border-box;margin:0;padding:0}
body{display:block!important;font-family:'Segoe UI',system-ui,sans-serif;background:#eef2f7;color:#343a40;min-height:100vh}
:root{
  --pri:#006994;--pri-dk:#004f70;--acc:#4A90A4;
  --ok:#28a745;--er:#dc3545;--warn:#ffc107;--inf:#17a2b8;--pur:#6f42c1;
  --g50:#f8f9fa;--g100:#f1f3f5;--g200:#e9ecef;--g300:#dee2e6;--g400:#ced4da;
  --g500:#adb5bd;--g600:#6c757d;--g700:#495057;--g800:#343a40;
  --sh1:0 1px 4px rgba(0,0,0,.08);--sh2:0 4px 14px rgba(0,0,0,.12);
  --r:.75rem;--r2:.4rem;--tr:.22s ease;
}
/* SIDEBAR */
.sidebar{position:fixed;left:0;top:0;width:280px;height:100vh;background:linear-gradient(180deg,#003d5c 0%,#212529 100%);color:#fff;display:flex;flex-direction:column;box-shadow:2px 0 15px rgba(0,0,0,.2);z-index:1000;overflow-y:auto;overflow-x:hidden;transition:transform .3s ease}
.sidebar::-webkit-scrollbar{width:5px}.sidebar::-webkit-scrollbar-thumb{background:rgba(255,255,255,.18);border-radius:3px}
.sidebar-header{padding:1.25rem 1.5rem;display:flex;align-items:center;justify-content:space-between;border-bottom:1px solid rgba(255,255,255,.1);flex-shrink:0}
.sidebar-brand{display:flex;align-items:center;gap:.75rem}
.sidebar-brand-text{font-size:1.2rem;font-weight:700;color:#fff}
.sidebar-toggle-btn{background:none;border:none;color:#fff;font-size:1.2rem;cursor:pointer;padding:.3rem;border-radius:.3rem;display:none}
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
@media(max-width:992px){.sidebar{transform:translateX(-100%)}.sidebar.open{transform:translateX(0)}.sidebar-toggle-btn{display:block}body.sidebar-open{overflow:hidden}}
/* LAYOUT */
.pw{display:flex;min-height:100vh}
.mc{flex:1;margin-left:280px;padding:2rem 2.5rem;transition:margin var(--tr)}
@media(max-width:992px){.mc{margin-left:0;padding:1rem}}
/* MOBILE TOPBAR */
.mtb{display:none;align-items:center;gap:.75rem;padding:.75rem 1rem;background:#fff;border-bottom:1px solid var(--g200);box-shadow:var(--sh1);position:sticky;top:0;z-index:100;margin-bottom:1.25rem}
.mtb-btn{background:none;border:none;font-size:1.25rem;color:var(--pri);cursor:pointer;padding:.3rem .5rem;border-radius:.35rem}
.mtb-title{font-size:1rem;font-weight:700;color:var(--g800)}
@media(max-width:992px){.mtb{display:flex}}
/* TOASTS */
.tw{position:fixed;top:1.5rem;right:1.5rem;z-index:9999;display:flex;flex-direction:column;gap:.5rem;pointer-events:none}
.toast{display:flex;align-items:center;gap:.75rem;padding:.9rem 1.25rem;border-radius:var(--r2);color:#fff;font-size:.9rem;font-weight:500;min-width:300px;max-width:420px;box-shadow:var(--sh2);animation:tIn .35s ease;pointer-events:all}
.toast.ok{background:var(--ok)}.toast.er{background:var(--er)}
.toast i{font-size:1.1rem;flex-shrink:0}.toast-msg{flex:1}
.toast-x{background:none;border:none;color:#fff;font-size:1.2rem;cursor:pointer;opacity:.75;padding:0;line-height:1}
@keyframes tIn{from{opacity:0;transform:translateX(110%)}to{opacity:1;transform:translateX(0)}}
@keyframes tOut{from{opacity:1;transform:translateX(0)}to{opacity:0;transform:translateX(110%)}}
/* PAGE HEADER */
.ph{display:flex;justify-content:space-between;align-items:flex-start;margin-bottom:1.75rem;flex-wrap:wrap;gap:1rem}
.ph h1{font-size:1.75rem;font-weight:700;color:var(--g800);display:flex;align-items:center;gap:.6rem}
.ph h1 i{color:var(--pri)}.ph p{color:var(--g600);font-size:.9rem;margin-top:.3rem}
/* SETTINGS LAYOUT */
.sw{display:grid;grid-template-columns:230px 1fr;gap:1.5rem;align-items:start}
@media(max-width:900px){.sw{grid-template-columns:1fr}}
/* TAB NAV */
.tn{background:#fff;border-radius:var(--r);box-shadow:var(--sh1);overflow:hidden;position:sticky;top:1rem}
.tn-hdr{padding:1rem 1.25rem;background:linear-gradient(135deg,var(--pri),var(--acc));color:#fff}
.tn-hdr h3{font-size:.88rem;font-weight:700;display:flex;align-items:center;gap:.5rem}
.tb{display:flex;align-items:center;gap:.65rem;width:100%;padding:.72rem 1.1rem;background:none;border:none;border-left:3px solid transparent;text-align:left;font-size:.86rem;font-weight:500;color:var(--g600);cursor:pointer;transition:all var(--tr);font-family:inherit}
.tb:hover{background:var(--g50);color:var(--pri)}
.tb.act{background:rgba(0,105,148,.08);color:var(--pri);font-weight:700;border-left-color:var(--pri)}
.tb i{width:18px;text-align:center;font-size:.88rem;flex-shrink:0}
.tb-div{height:1px;background:var(--g100);margin:.2rem 0}
/* TAB PANELS */
.tp{display:none}.tp.act{display:block}
/* CARD */
.sc{background:#fff;border-radius:var(--r);box-shadow:var(--sh1);margin-bottom:1.25rem;overflow:hidden}
.sc-hdr{padding:.9rem 1.4rem;border-bottom:1px solid var(--g100);display:flex;align-items:center;justify-content:space-between}
.sc-hdr h3{font-size:.95rem;font-weight:700;color:var(--g700);display:flex;align-items:center;gap:.5rem}
.sc-hdr h3 i{color:var(--pri)}
.sc-body{padding:1.4rem}
/* FORM */
.fg{display:grid;grid-template-columns:1fr 1fr;gap:.85rem}
@media(max-width:700px){.fg{grid-template-columns:1fr}}
.fi{display:flex;flex-direction:column;gap:.3rem}
.fi.fw{grid-column:1/-1}
.fl{font-size:.82rem;font-weight:600;color:var(--g700)}
.fl .rq{color:var(--er);margin-left:.15rem}
.fc{padding:.58rem .85rem;border:1.5px solid var(--g300);border-radius:var(--r2);font-size:.88rem;outline:none;transition:border var(--tr),box-shadow var(--tr);width:100%;font-family:inherit;background:#fff;color:var(--g800)}
.fc:focus{border-color:var(--pri);box-shadow:0 0 0 3px rgba(0,105,148,.11)}
textarea.fc{resize:vertical;min-height:70px}
.fc[readonly]{background:var(--g50);color:var(--g600);cursor:not-allowed}
/* TOGGLE */
.tog-row{display:flex;align-items:center;justify-content:space-between;padding:.65rem 0;border-bottom:1px solid var(--g100)}
.tog-row:last-child{border-bottom:none}
.tog-info{flex:1}
.tog-lbl{font-size:.88rem;font-weight:600;color:var(--g800)}
.tog-desc{font-size:.76rem;color:var(--g600);margin-top:.15rem}
.tog-sw{position:relative;width:44px;height:24px;flex-shrink:0;margin-left:.75rem}
.tog-sw input{opacity:0;width:0;height:0;position:absolute}
.tog-sw .slider{position:absolute;inset:0;background:var(--g300);border-radius:24px;cursor:pointer;transition:background .25s}
.tog-sw .slider::before{content:'';position:absolute;height:18px;width:18px;left:3px;bottom:3px;background:#fff;border-radius:50%;transition:transform .25s;box-shadow:0 1px 3px rgba(0,0,0,.2)}
.tog-sw input:checked + .slider{background:var(--pri)}
.tog-sw input:checked + .slider::before{transform:translateX(20px)}
/* INFO ROWS */
.ir{display:flex;justify-content:space-between;align-items:center;padding:.55rem 0;border-bottom:1px solid var(--g100);font-size:.85rem}
.ir:last-child{border-bottom:none}
.ir .lbl{color:var(--g600);font-weight:500}
.ir .val{font-weight:700;color:var(--g800)}
.ir .val.ok{color:var(--ok)}.ir .val.warn{color:var(--warn)}.ir .val.er{color:var(--er)}
/* MEM BAR */
.mb{height:8px;background:var(--g100);border-radius:4px;overflow:hidden;margin-top:.3rem}
.mb-fill{height:100%;border-radius:4px;transition:width .6s ease}
/* BUTTONS */
.btn{display:inline-flex;align-items:center;justify-content:center;gap:.4rem;padding:.52rem 1.1rem;border:none;border-radius:var(--r2);font-size:.86rem;font-weight:600;cursor:pointer;text-decoration:none;transition:all var(--tr);white-space:nowrap;font-family:inherit}
.btn-pri{background:var(--pri);color:#fff}.btn-pri:hover{background:var(--pri-dk)}
.btn-ok{background:var(--ok);color:#fff}.btn-ok:hover{filter:brightness(.9)}
.btn-er{background:var(--er);color:#fff}.btn-er:hover{filter:brightness(.9)}
.btn-warn{background:var(--warn);color:#000}.btn-warn:hover{filter:brightness(.9)}
.btn-sec{background:var(--g200);color:var(--g800)}.btn-sec:hover{background:var(--g300)}
.btn-sm{padding:.35rem .75rem;font-size:.78rem}
/* PROFILE AVATAR */
.av{width:72px;height:72px;border-radius:50%;background:linear-gradient(135deg,var(--pri),var(--acc));display:flex;align-items:center;justify-content:center;font-size:1.8rem;font-weight:700;color:#fff;margin:0 auto 1rem}
/* PASSWORD STRENGTH */
.ps{margin-top:.4rem}
.ps-bar{height:5px;background:var(--g200);border-radius:3px;overflow:hidden}
.ps-fill{height:100%;border-radius:3px;transition:width .3s,background .3s;width:0}
.ps-txt{font-size:.74rem;margin-top:.2rem;font-weight:600;color:var(--g500)}
/* DANGER ZONE */
.dz{border:2px solid rgba(220,53,69,.25);border-radius:var(--r);padding:1rem 1.25rem;background:rgba(220,53,69,.03);margin-bottom:1rem}
.dz h4{color:var(--er);font-size:.9rem;margin-bottom:.5rem;display:flex;align-items:center;gap:.4rem}
.dz p{font-size:.83rem;color:var(--g600);margin-bottom:.75rem}
/* TABLE */
.tbl{width:100%;border-collapse:collapse;font-size:.85rem}
.tbl thead{background:var(--g50);border-bottom:2px solid var(--g200)}
.tbl th{padding:.65rem 1rem;text-align:left;font-weight:700;color:var(--g600);font-size:.76rem;text-transform:uppercase;letter-spacing:.04em}
.tbl td{padding:.65rem 1rem;border-bottom:1px solid var(--g100);vertical-align:middle}
.tbl tr:last-child td{border-bottom:none}
.tbl tr:hover td{background:var(--g50)}
/* BADGE */
.badge{display:inline-flex;align-items:center;padding:.18rem .55rem;border-radius:1rem;font-size:.7rem;font-weight:700;text-transform:uppercase}
.b-str{background:#d1ecf1;color:#0c5460}
.b-int{background:#d4edda;color:#155724}
.b-dec{background:#fff3cd;color:#856404}
.b-bool{background:#e2d9f3;color:#4a235a}
/* MODAL */
.modal-bg{display:none;position:fixed;inset:0;background:rgba(0,0,0,.5);z-index:5000;align-items:center;justify-content:center}
.modal-bg.open{display:flex}
.modal{background:#fff;border-radius:var(--r);box-shadow:var(--sh2);width:100%;max-width:480px;padding:1.5rem;position:relative}
.modal h3{font-size:1rem;font-weight:700;color:var(--g800);margin-bottom:1rem;display:flex;align-items:center;gap:.5rem}
.modal-close{position:absolute;top:.75rem;right:.75rem;background:none;border:none;font-size:1.25rem;cursor:pointer;color:var(--g500)}
.modal-close:hover{color:var(--er)}
/* FORM FOOTER */
.ff{margin-top:1.25rem;display:flex;justify-content:flex-end;gap:.65rem}
</style>
</head>
<body>
<div class="pw">
<jsp:include page="../common/sidebar.jsp">
    <jsp:param name="active" value="settings"/>
</jsp:include>

<div class="mc">

<!-- MOBILE TOPBAR -->
<div class="mtb">
    <button class="mtb-btn" onclick="document.getElementById('sidebar').classList.toggle('open');document.getElementById('sidebarOverlay').classList.toggle('active')"><i class="fas fa-bars"></i></button>
    <span class="mtb-title" style="display:flex;align-items:center;gap:.4rem"><i class="fas fa-cog" style="color:var(--pri)"></i> Settings</span>
</div>

<!-- TOASTS -->
<div class="tw">
<% if (flashOk  != null && !flashOk.isEmpty())  { %><div class="toast ok" id="tOk"><i class="fas fa-check-circle"></i><span class="toast-msg"><%= sH(flashOk) %></span><button class="toast-x" onclick="rmT('tOk')">&times;</button></div><% } %>
<% if (flashErr != null && !flashErr.isEmpty()) { %><div class="toast er" id="tEr"><i class="fas fa-exclamation-circle"></i><span class="toast-msg"><%= sH(flashErr) %></span><button class="toast-x" onclick="rmT('tEr')">&times;</button></div><% } %>
</div>

<!-- PAGE HEADER -->
<div class="ph">
    <div>
        <h1><i class="fas fa-cog"></i> Settings</h1>
        <p>Manage hotel configuration, profile, security and feature toggles</p>
    </div>
</div>

<div class="sw">

<!-- TAB NAV -->
<div class="tn">
    <div class="tn-hdr"><h3><i class="fas fa-sliders-h"></i> Settings Menu</h3></div>
    <button class="tb <%= "general".equals(activeTab)?"act":"" %>"      onclick="showTab('general')"     ><i class="fas fa-globe"></i> General</button>
    <button class="tb <%= "profile".equals(activeTab)?"act":"" %>"      onclick="showTab('profile')"     ><i class="fas fa-user-circle"></i> My Profile</button>
    <button class="tb <%= "password".equals(activeTab)?"act":"" %>"     onclick="showTab('password')"    ><i class="fas fa-lock"></i> Change Password</button>
    <div class="tb-div"></div>
    <button class="tb <%= "billing".equals(activeTab)?"act":"" %>"      onclick="showTab('billing')"     ><i class="fas fa-rupee-sign"></i> Billing</button>
    <button class="tb <%= "security".equals(activeTab)?"act":"" %>"     onclick="showTab('security')"    ><i class="fas fa-shield-alt"></i> Security</button>
    <button class="tb <%= "features".equals(activeTab)?"act":"" %>"     onclick="showTab('features')"    ><i class="fas fa-toggle-on"></i> Features</button>
    <button class="tb <%= "contact".equals(activeTab)?"act":"" %>"      onclick="showTab('contact')"     ><i class="fas fa-address-book"></i> Contact</button>
    <button class="tb <%= "notification".equals(activeTab)?"act":"" %>" onclick="showTab('notification')" ><i class="fas fa-bell"></i> Notifications</button>
    <div class="tb-div"></div>
    <button class="tb <%= "custom".equals(activeTab)?"act":"" %>"       onclick="showTab('custom')"      ><i class="fas fa-database"></i> Custom Settings</button>
    <button class="tb <%= "system".equals(activeTab)?"act":"" %>"       onclick="showTab('system')"      ><i class="fas fa-server"></i> System Info</button>
    <button class="tb <%= "danger".equals(activeTab)?"act":"" %>"       onclick="showTab('danger')"      ><i class="fas fa-exclamation-triangle" style="color:var(--er)"></i> <span style="color:var(--er)">Danger Zone</span></button>
</div>

<!-- TAB PANELS -->
<div id="tabContent">
<!-- ══ GENERAL TAB ══ -->
<div class="tp <%= "general".equals(activeTab)?"act":"" %>" id="tab-general">
  <div class="sc">
    <div class="sc-hdr"><h3><i class="fas fa-globe"></i> General Settings</h3></div>
    <div class="sc-body">
      <form method="post" action="<%= ctx %>/admin/settings">
        <input type="hidden" name="action" value="updateGeneral">
        <div class="fg">
          <div class="fi">
            <label class="fl">App Name <span class="rq">*</span></label>
            <input type="text" class="fc" name="setting.app.name" value="<%= sH(appName) %>" required>
          </div>
          <div class="fi">
            <label class="fl">Version</label>
            <input type="text" class="fc" value="<%= sH(appVer) %>" readonly>
          </div>
          <div class="fi fw">
            <label class="fl">Description</label>
            <input type="text" class="fc" name="setting.app.description" value="<%= sH(appDesc) %>">
          </div>
          <div class="fi">
            <label class="fl">Timezone</label>
            <select class="fc" name="setting.app.timezone">
              <option value="Asia/Colombo"  <%= "Asia/Colombo".equals(timezone)?"selected":"" %>>Asia/Colombo (UTC+5:30)</option>
              <option value="Asia/Kolkata"  <%= "Asia/Kolkata".equals(timezone)?"selected":"" %>>Asia/Kolkata (UTC+5:30)</option>
              <option value="UTC"           <%= "UTC".equals(timezone)?"selected":"" %>>UTC</option>
              <option value="Asia/Dubai"    <%= "Asia/Dubai".equals(timezone)?"selected":"" %>>Asia/Dubai (UTC+4)</option>
              <option value="Europe/London" <%= "Europe/London".equals(timezone)?"selected":"" %>>Europe/London (UTC+0)</option>
              <option value="America/New_York" <%= "America/New_York".equals(timezone)?"selected":"" %>>America/New York (UTC-5)</option>
            </select>
          </div>
          <div class="fi">
            <label class="fl">Session Timeout (minutes)</label>
            <input type="number" class="fc" name="setting.session.timeout" value="<%= sH(sessionTO) %>" min="5" max="480">
          </div>
        </div>
        <div class="ff"><button type="submit" class="btn btn-pri"><i class="fas fa-save"></i> Save General Settings</button></div>
      </form>
    </div>
  </div>
</div>

<!-- ══ PROFILE TAB ══ -->
<div class="tp <%= "profile".equals(activeTab)?"act":"" %>" id="tab-profile">
  <div class="sc">
    <div class="sc-hdr"><h3><i class="fas fa-user-circle"></i> My Profile</h3></div>
    <div class="sc-body">
      <div class="av"><%= cu.getFullName()!=null&&!cu.getFullName().isEmpty()?String.valueOf(cu.getFullName().charAt(0)).toUpperCase():"A" %></div>
      <form method="post" action="<%= ctx %>/admin/settings">
        <input type="hidden" name="action" value="updateProfile">
        <div class="fg">
          <div class="fi">
            <label class="fl">Username</label>
            <input type="text" class="fc" value="<%= sH(cu.getUsername()) %>" readonly>
          </div>
          <div class="fi">
            <label class="fl">Role</label>
            <input type="text" class="fc" value="<%= sH(cu.getRole().toString()) %>" readonly>
          </div>
          <div class="fi">
            <label class="fl">Full Name <span class="rq">*</span></label>
            <input type="text" class="fc" name="fullName" value="<%= sH(cu.getFullName()!=null?cu.getFullName():"") %>" required>
          </div>
          <div class="fi">
            <label class="fl">Email Address <span class="rq">*</span></label>
            <input type="email" class="fc" name="email" value="<%= sH(cu.getEmail()!=null?cu.getEmail():"") %>" required>
          </div>
          <div class="fi">
            <label class="fl">Phone Number</label>
            <input type="tel" class="fc" name="phone" value="<%= sH(cu.getPhone()!=null?cu.getPhone():"") %>" placeholder="+94 XX XXX XXXX">
          </div>
          <div class="fi">
            <label class="fl">Account Status</label>
            <input type="text" class="fc" value="<%= cu.isActive()?"Active":"Inactive" %>" readonly style="color:<%= cu.isActive()?"var(--ok)":"var(--er)" %>;font-weight:700">
          </div>
        </div>
        <div class="ff">
          <button type="reset" class="btn btn-sec"><i class="fas fa-undo"></i> Reset</button>
          <button type="submit" class="btn btn-pri"><i class="fas fa-save"></i> Update Profile</button>
        </div>
      </form>
    </div>
  </div>
</div>

<!-- ══ PASSWORD TAB ══ -->
<div class="tp <%= "password".equals(activeTab)?"act":"" %>" id="tab-password">
  <div class="sc">
    <div class="sc-hdr"><h3><i class="fas fa-lock"></i> Change Password</h3></div>
    <div class="sc-body">
      <form method="post" action="<%= ctx %>/admin/settings" id="pwdForm" onsubmit="return validatePwd()">
        <input type="hidden" name="action" value="changePassword">
        <div class="fg" style="grid-template-columns:1fr">
          <div class="fi">
            <label class="fl">Current Password <span class="rq">*</span></label>
            <div style="position:relative">
              <input type="password" class="fc" id="cPwd" name="currentPassword" placeholder="Enter current password" style="padding-right:2.5rem">
              <button type="button" onclick="togglePwd('cPwd',this)" style="position:absolute;right:.75rem;top:50%;transform:translateY(-50%);background:none;border:none;cursor:pointer;color:var(--g500)"><i class="fas fa-eye"></i></button>
            </div>
          </div>
          <div class="fi">
            <label class="fl">New Password <span class="rq">*</span></label>
            <div style="position:relative">
              <input type="password" class="fc" id="nPwd" name="newPassword" placeholder="Min 8 characters" oninput="checkStrength(this.value)" style="padding-right:2.5rem">
              <button type="button" onclick="togglePwd('nPwd',this)" style="position:absolute;right:.75rem;top:50%;transform:translateY(-50%);background:none;border:none;cursor:pointer;color:var(--g500)"><i class="fas fa-eye"></i></button>
            </div>
            <div class="ps"><div class="ps-bar"><div class="ps-fill" id="psFill"></div></div><div class="ps-txt" id="psTxt"></div></div>
            <span id="ePwd" style="font-size:.76rem;color:var(--er)"></span>
          </div>
          <div class="fi">
            <label class="fl">Confirm New Password <span class="rq">*</span></label>
            <div style="position:relative">
              <input type="password" class="fc" id="cfPwd" name="confirmPassword" placeholder="Repeat new password" oninput="checkMatch()" style="padding-right:2.5rem">
              <button type="button" onclick="togglePwd('cfPwd',this)" style="position:absolute;right:.75rem;top:50%;transform:translateY(-50%);background:none;border:none;cursor:pointer;color:var(--g500)"><i class="fas fa-eye"></i></button>
            </div>
            <span id="eCfPwd" style="font-size:.76rem;color:var(--er)"></span>
          </div>
        </div>
        <div class="ff"><button type="submit" class="btn btn-ok"><i class="fas fa-key"></i> Change Password</button></div>
      </form>
    </div>
  </div>
</div>

<!-- ══ BILLING TAB ══ -->
<div class="tp <%= "billing".equals(activeTab)?"act":"" %>" id="tab-billing">
  <div class="sc">
    <div class="sc-hdr"><h3><i class="fas fa-rupee-sign"></i> Billing Configuration</h3></div>
    <div class="sc-body">
      <form method="post" action="<%= ctx %>/admin/settings">
        <input type="hidden" name="action" value="updateBilling">
        <div class="fg">
          <div class="fi">
            <label class="fl">Currency Code</label>
            <select class="fc" name="setting.billing.currency">
              <option value="LKR" <%= "LKR".equals(currency)?"selected":"" %>>LKR - Sri Lankan Rupee</option>
              <option value="USD" <%= "USD".equals(currency)?"selected":"" %>>USD - US Dollar</option>
              <option value="EUR" <%= "EUR".equals(currency)?"selected":"" %>>EUR - Euro</option>
              <option value="GBP" <%= "GBP".equals(currency)?"selected":"" %>>GBP - British Pound</option>
              <option value="AUD" <%= "AUD".equals(currency)?"selected":"" %>>AUD - Australian Dollar</option>
            </select>
          </div>
          <div class="fi">
            <label class="fl">Currency Symbol</label>
            <input type="text" class="fc" name="setting.billing.currency.symbol" value="<%= sH(currSymbol) %>" maxlength="5">
          </div>
          <div class="fi">
            <label class="fl">Tax Rate (%)</label>
            <input type="number" class="fc" name="setting.billing.tax.percentage" value="<%= sH(taxRate) %>" min="0" max="100" step="0.1">
          </div>
          <div class="fi">
            <label class="fl">Service Charge (%)</label>
            <input type="number" class="fc" name="setting.billing.service.charge.percentage" value="<%= sH(svcCharge) %>" min="0" max="100" step="0.1">
          </div>
        </div>
        <div class="ff"><button type="submit" class="btn btn-pri"><i class="fas fa-save"></i> Save Billing Settings</button></div>
      </form>
    </div>
  </div>
</div>
<!-- ══ SECURITY TAB ══ -->
<div class="tp <%= "security".equals(activeTab)?"act":"" %>" id="tab-security">
  <div class="sc">
    <div class="sc-hdr"><h3><i class="fas fa-shield-alt"></i> Security Settings</h3></div>
    <div class="sc-body">
      <form method="post" action="<%= ctx %>/admin/settings">
        <input type="hidden" name="action" value="updateSecurity">
        <div class="fg">
          <div class="fi">
            <label class="fl">Min Password Length</label>
            <input type="number" class="fc" name="setting.security.password.min.length" value="<%= sH(pwdMinLen) %>" min="6" max="32">
          </div>
          <div class="fi">
            <label class="fl">Max Login Attempts</label>
            <input type="number" class="fc" name="setting.security.max.login.attempts" value="<%= sH(maxLogin) %>" min="1" max="20">
          </div>
          <div class="fi">
            <label class="fl">Lockout Duration (minutes)</label>
            <input type="number" class="fc" name="setting.security.lockout.duration" value="<%= sH(lockout) %>" min="1" max="1440">
          </div>
        </div>
        <div style="margin-top:1rem">
          <div class="tog-row">
            <div class="tog-info"><div class="tog-lbl">Require Special Character</div><div class="tog-desc">Password must contain !@#$% etc.</div></div>
            <label class="tog-sw"><input type="checkbox" name="setting.security.password.require.special.char" <%= reqSpecial?"checked":"" %>><span class="slider"></span></label>
          </div>
          <div class="tog-row">
            <div class="tog-info"><div class="tog-lbl">Require Number</div><div class="tog-desc">Password must contain at least one digit</div></div>
            <label class="tog-sw"><input type="checkbox" name="setting.security.password.require.number" <%= reqNum?"checked":"" %>><span class="slider"></span></label>
          </div>
          <div class="tog-row">
            <div class="tog-info"><div class="tog-lbl">Require Uppercase Letter</div><div class="tog-desc">Password must contain at least one uppercase letter</div></div>
            <label class="tog-sw"><input type="checkbox" name="setting.security.password.require.uppercase" <%= reqUpper?"checked":"" %>><span class="slider"></span></label>
          </div>
        </div>
        <div class="ff"><button type="submit" class="btn btn-pri"><i class="fas fa-save"></i> Save Security Settings</button></div>
      </form>
    </div>
  </div>
</div>

<!-- ══ FEATURES TAB ══ -->
<div class="tp <%= "features".equals(activeTab)?"act":"" %>" id="tab-features">
  <div class="sc">
    <div class="sc-hdr"><h3><i class="fas fa-toggle-on"></i> Feature Flags</h3></div>
    <div class="sc-body">
      <form method="post" action="<%= ctx %>/admin/settings">
        <input type="hidden" name="action" value="updateFeatures">
        <div class="tog-row">
          <div class="tog-info"><div class="tog-lbl">SMS Notifications</div><div class="tog-desc">Send SMS alerts to guests for reservations and updates</div></div>
          <label class="tog-sw"><input type="checkbox" name="setting.features.sms.notifications" <%= featSMS?"checked":"" %>><span class="slider"></span></label>
        </div>
        <div class="tog-row">
          <div class="tog-info"><div class="tog-lbl">PDF Generation</div><div class="tog-desc">Generate PDF invoices and reservation documents</div></div>
          <label class="tog-sw"><input type="checkbox" name="setting.features.pdf.generation" <%= featPDF?"checked":"" %>><span class="slider"></span></label>
        </div>
        <div class="tog-row">
          <div class="tog-info"><div class="tog-lbl">Audit Logging</div><div class="tog-desc">Track all admin actions for security compliance</div></div>
          <label class="tog-sw"><input type="checkbox" name="setting.features.audit.logging" <%= featAudit?"checked":"" %>><span class="slider"></span></label>
        </div>
        <div class="tog-row">
          <div class="tog-info"><div class="tog-lbl">Guest Reviews</div><div class="tog-desc">Allow guests to submit and view hotel reviews</div></div>
          <label class="tog-sw"><input type="checkbox" name="setting.features.reviews.enabled" <%= featRevs?"checked":"" %>><span class="slider"></span></label>
        </div>
        <div class="tog-row">
          <div class="tog-info"><div class="tog-lbl">Special Offers</div><div class="tog-desc">Enable promotions and discount offer management</div></div>
          <label class="tog-sw"><input type="checkbox" name="setting.features.offers.enabled" <%= featOffs?"checked":"" %>><span class="slider"></span></label>
        </div>
        <div class="ff"><button type="submit" class="btn btn-pri"><i class="fas fa-save"></i> Save Feature Settings</button></div>
      </form>
    </div>
  </div>
</div>

<!-- ══ CONTACT TAB ══ -->
<div class="tp <%= "contact".equals(activeTab)?"act":"" %>" id="tab-contact">
  <div class="sc">
    <div class="sc-hdr"><h3><i class="fas fa-address-book"></i> Contact Information</h3></div>
    <div class="sc-body">
      <form method="post" action="<%= ctx %>/admin/settings">
        <input type="hidden" name="action" value="updateContact">
        <div class="fg">
          <div class="fi">
            <label class="fl">Contact Email</label>
            <input type="email" class="fc" name="setting.contact.email" value="<%= sH(cEmail) %>">
          </div>
          <div class="fi">
            <label class="fl">Contact Phone</label>
            <input type="tel" class="fc" name="setting.contact.phone" value="<%= sH(cPhone) %>">
          </div>
          <div class="fi">
            <label class="fl">Website URL</label>
            <input type="text" class="fc" name="setting.contact.website" value="<%= sH(cWebsite) %>">
          </div>
          <div class="fi fw">
            <label class="fl">Physical Address</label>
            <textarea class="fc" name="setting.contact.address"><%= sH(cAddress) %></textarea>
          </div>
        </div>
        <div class="ff"><button type="submit" class="btn btn-pri"><i class="fas fa-save"></i> Save Contact Info</button></div>
      </form>
    </div>
  </div>
</div>

<!-- ══ NOTIFICATION TAB ══ -->
<div class="tp <%= "notification".equals(activeTab)?"act":"" %>" id="tab-notification">
  <div class="sc">
    <div class="sc-hdr"><h3><i class="fas fa-bell"></i> Notification Settings</h3></div>
    <div class="sc-body">
      <form method="post" action="<%= ctx %>/admin/settings">
        <input type="hidden" name="action" value="updateNotification">
        <div class="tog-row">
          <div class="tog-info"><div class="tog-lbl">Booking Confirmation Email</div><div class="tog-desc">Send confirmation email when a reservation is made</div></div>
          <label class="tog-sw"><input type="checkbox" name="setting.notification.booking.confirmation" <%= notifBook?"checked":"" %>><span class="slider"></span></label>
        </div>
        <div class="tog-row">
          <div class="tog-info"><div class="tog-lbl">Check-In Reminder Email</div><div class="tog-desc">Send reminder email one day before check-in date</div></div>
          <label class="tog-sw"><input type="checkbox" name="setting.notification.checkin.reminder" <%= notifCI?"checked":"" %>><span class="slider"></span></label>
        </div>
        <div class="tog-row">
          <div class="tog-info"><div class="tog-lbl">Check-Out Reminder Email</div><div class="tog-desc">Send reminder email on the day of check-out</div></div>
          <label class="tog-sw"><input type="checkbox" name="setting.notification.checkout.reminder" <%= notifCO?"checked":"" %>><span class="slider"></span></label>
        </div>
        <div class="ff"><button type="submit" class="btn btn-pri"><i class="fas fa-save"></i> Save Notification Settings</button></div>
      </form>
    </div>
  </div>
</div>
<!-- ══ CUSTOM SETTINGS TAB ══ -->
<div class="tp <%= "custom".equals(activeTab)?"act":"" %>" id="tab-custom">
  <div class="sc">
    <div class="sc-hdr">
      <h3><i class="fas fa-database"></i> Custom Settings</h3>
      <button class="btn btn-pri btn-sm" onclick="document.getElementById('addModal').classList.add('open')"><i class="fas fa-plus"></i> Add Setting</button>
    </div>
    <div style="overflow-x:auto">
    <% if (customSettings.isEmpty()) { %>
    <p style="text-align:center;padding:2rem;color:var(--g500);font-size:.88rem"><i class="fas fa-info-circle"></i> No custom settings found. Use the button above to add one.</p>
    <% } else { %>
    <table class="tbl">
      <thead><tr><th>Key</th><th>Value</th><th>Type</th><th>Category</th><th>Description</th><th style="text-align:right">Action</th></tr></thead>
      <tbody>
      <% for (HotelSetting hs : customSettings) { %>
      <tr>
        <td style="font-weight:700;color:var(--pri);font-size:.82rem"><%= sH(hs.getSettingKey()) %></td>
        <td style="max-width:200px;overflow:hidden;text-overflow:ellipsis;white-space:nowrap"><%= sH(hs.getSettingValue()!=null?hs.getSettingValue():"") %></td>
        <td><span class="badge <%= "STRING".equals(hs.getSettingType().name())?"b-str":"INTEGER".equals(hs.getSettingType().name())?"b-int":"DECIMAL".equals(hs.getSettingType().name())?"b-dec":"b-bool" %>"><%= hs.getSettingType().name() %></span></td>
        <td style="font-size:.82rem;color:var(--g600)"><%= sH(hs.getCategory()) %></td>
        <td style="font-size:.82rem;color:var(--g600)"><%= sH(hs.getDescription()!=null?hs.getDescription():"") %></td>
        <td style="text-align:right">
          <a href="<%= ctx %>/admin/settings?action=delete&key=<%= sH(hs.getSettingKey()) %>"
             class="btn btn-er btn-sm"
             onclick="return confirm('Delete setting: <%= sH(hs.getSettingKey()) %>?')">
            <i class="fas fa-trash"></i>
          </a>
        </td>
      </tr>
      <% } %>
      </tbody>
    </table>
    <% } %>
    </div>
  </div>
</div>

<!-- ══ SYSTEM INFO TAB ══ -->
<div class="tp <%= "system".equals(activeTab)?"act":"" %>" id="tab-system">
  <div class="sc">
    <div class="sc-hdr"><h3><i class="fas fa-server"></i> System Information</h3></div>
    <div class="sc-body">
      <div class="ir"><span class="lbl">Java Version</span><span class="val"><%= sH(sysInfo.getOrDefault("javaVersion","N/A")) %></span></div>
      <div class="ir"><span class="lbl">Java Vendor</span><span class="val"><%= sH(sysInfo.getOrDefault("javaVendor","N/A")) %></span></div>
      <div class="ir"><span class="lbl">OS</span><span class="val"><%= sH(sysInfo.getOrDefault("osName","N/A")) %> (<%= sH(sysInfo.getOrDefault("osArch","N/A")) %>)</span></div>
      <div class="ir"><span class="lbl">OS Version</span><span class="val"><%= sH(sysInfo.getOrDefault("osVersion","N/A")) %></span></div>
      <div class="ir"><span class="lbl">CPU Cores</span><span class="val"><%= sH(sysInfo.getOrDefault("processors","N/A")) %></span></div>
      <div class="ir"><span class="lbl">Server</span><span class="val"><%= sH(application.getServerInfo()) %></span></div>
      <div class="ir"><span class="lbl">Servlet API</span><span class="val"><%= application.getMajorVersion() %>.<%= application.getMinorVersion() %></span></div>
      <div class="ir">
        <span class="lbl">Memory Used</span>
        <span class="val <%= memPct>80?"er":memPct>60?"warn":"ok" %>">
          <%= sH(sysInfo.getOrDefault("usedMemoryMB","0")) %> MB / <%= sH(sysInfo.getOrDefault("maxMemoryMB","0")) %> MB (<%= memPct %>%)
        </span>
      </div>
      <div class="mb"><div class="mb-fill" style="width:<%= memPct %>%;background:<%= memPct>80?"var(--er)":memPct>60?"var(--warn)":"var(--pri)" %>"></div></div>
      <div class="ir" style="margin-top:.75rem"><span class="lbl">App Name</span><span class="val"><%= sH(appName) %></span></div>
      <div class="ir"><span class="lbl">App Version</span><span class="val"><%= sH(appVer) %></span></div>
    </div>
  </div>
  <div class="sc">
    <div class="sc-hdr"><h3><i class="fas fa-database"></i> Cache &amp; Maintenance</h3></div>
    <div class="sc-body" style="display:flex;gap:.75rem;flex-wrap:wrap">
      <form method="post" action="<%= ctx %>/admin/settings" style="display:inline">
        <input type="hidden" name="action" value="clearCache">
        <button type="submit" class="btn btn-warn"><i class="fas fa-broom"></i> Clear Cache</button>
      </form>
      <button type="button" class="btn btn-sec" onclick="window.location.reload()"><i class="fas fa-sync-alt"></i> Refresh Info</button>
    </div>
  </div>
</div>

<!-- ══ DANGER ZONE TAB ══ -->
<div class="tp <%= "danger".equals(activeTab)?"act":"" %>" id="tab-danger">
  <div class="sc">
    <div class="sc-hdr"><h3><i class="fas fa-exclamation-triangle" style="color:var(--er)"></i> Danger Zone</h3></div>
    <div class="sc-body">
      <div class="dz">
        <h4><i class="fas fa-broom"></i> Clear Application Cache</h4>
        <p>Clears all server-side cached data. The application may run slightly slower temporarily until caches are rebuilt.</p>
        <form method="post" action="<%= ctx %>/admin/settings">
          <input type="hidden" name="action" value="clearCache">
          <button type="submit" class="btn btn-warn"><i class="fas fa-broom"></i> Clear Cache</button>
        </form>
      </div>
      <div class="dz">
        <h4><i class="fas fa-sign-out-alt"></i> Force Logout All Sessions</h4>
        <p>Invalidates all active user sessions. All users will need to log in again. Use with caution.</p>
        <button type="button" class="btn btn-er" onclick="alert('Force logout: feature requires session manager integration.')"><i class="fas fa-power-off"></i> Force Logout All</button>
      </div>
      <div class="dz">
        <h4><i class="fas fa-redo"></i> Reset Settings to Default</h4>
        <p>Resets all editable settings to their original default values. This cannot be undone.</p>
        <button type="button" class="btn btn-er" onclick="alert('Reset to defaults: feature available via DB migration re-run.')"><i class="fas fa-redo"></i> Reset to Defaults</button>
      </div>
    </div>
  </div>
</div>

</div><!-- /tabContent -->
</div><!-- /sw -->
</div><!-- /mc -->
</div><!-- /pw -->

<!-- ══ ADD SETTING MODAL ══ -->
<div class="modal-bg" id="addModal">
  <div class="modal">
    <button class="modal-close" onclick="document.getElementById('addModal').classList.remove('open')">&times;</button>
    <h3><i class="fas fa-plus-circle" style="color:var(--pri)"></i> Add Custom Setting</h3>
    <form method="post" action="<%= ctx %>/admin/settings">
      <input type="hidden" name="action" value="createSetting">
      <div class="fg" style="grid-template-columns:1fr 1fr">
        <div class="fi">
          <label class="fl">Category <span class="rq">*</span></label>
          <input type="text" class="fc" name="newCategory" placeholder="e.g. CUSTOM" required>
        </div>
        <div class="fi">
          <label class="fl">Type</label>
          <select class="fc" name="newType">
            <option value="STRING">STRING</option>
            <option value="INTEGER">INTEGER</option>
            <option value="DECIMAL">DECIMAL</option>
            <option value="BOOLEAN">BOOLEAN</option>
          </select>
        </div>
        <div class="fi fw">
          <label class="fl">Key <span class="rq">*</span></label>
          <input type="text" class="fc" name="newKey" placeholder="e.g. custom.my.setting" required>
        </div>
        <div class="fi fw">
          <label class="fl">Value</label>
          <input type="text" class="fc" name="newValue" placeholder="Setting value">
        </div>
        <div class="fi fw">
          <label class="fl">Description</label>
          <input type="text" class="fc" name="newDescription" placeholder="Brief description">
        </div>
      </div>
      <div class="ff">
        <button type="button" class="btn btn-sec" onclick="document.getElementById('addModal').classList.remove('open')">Cancel</button>
        <button type="submit" class="btn btn-pri"><i class="fas fa-save"></i> Create Setting</button>
      </div>
    </form>
  </div>
</div>
<script>
/* ── TAB SWITCHING ── */
function showTab(id) {
    document.querySelectorAll('.tp').forEach(function(p){ p.classList.remove('act'); });
    document.querySelectorAll('.tb').forEach(function(b){ b.classList.remove('act'); });
    var panel = document.getElementById('tab-'+id);
    if (panel) panel.classList.add('act');
    document.querySelectorAll('.tb').forEach(function(b){
        if (b.getAttribute('onclick') && b.getAttribute('onclick').indexOf("'"+id+"'") !== -1) b.classList.add('act');
    });
    history.replaceState(null,'',window.location.pathname+'?tab='+id);
}

/* ── TOAST DISMISS ── */
function rmT(id){
    var t=document.getElementById(id); if(!t)return;
    t.style.animation='tOut .3s ease forwards';
    setTimeout(function(){if(t.parentNode)t.parentNode.removeChild(t);},320);
}
document.querySelectorAll('.toast').forEach(function(t){
    setTimeout(function(){
        t.style.animation='tOut .3s ease forwards';
        setTimeout(function(){if(t.parentNode)t.parentNode.removeChild(t);},320);
    },6000);
});

/* ── PASSWORD VISIBILITY TOGGLE ── */
function togglePwd(id, btn) {
    var inp = document.getElementById(id);
    if (!inp) return;
    var isText = inp.type === 'text';
    inp.type = isText ? 'password' : 'text';
    var icon = btn.querySelector('i');
    if (icon) { icon.className = isText ? 'fas fa-eye' : 'fas fa-eye-slash'; }
}

/* ── PASSWORD STRENGTH ── */
function checkStrength(val) {
    var fill = document.getElementById('psFill');
    var txt  = document.getElementById('psTxt');
    if (!fill || !txt) return;
    var score = 0;
    if (val.length >= 8)  score++;
    if (val.length >= 12) score++;
    if (/[A-Z]/.test(val)) score++;
    if (/[0-9]/.test(val)) score++;
    if (/[^A-Za-z0-9]/.test(val)) score++;
    var labels = ['','Weak','Fair','Good','Strong','Very Strong'];
    var colors = ['','#dc3545','#fd7e14','#ffc107','#28a745','#20c997'];
    var pct    = [0,20,40,60,80,100];
    fill.style.width    = pct[score] + '%';
    fill.style.background = colors[score] || '#dc3545';
    txt.textContent     = labels[score] || '';
    txt.style.color     = colors[score] || '#dc3545';
}

/* ── PASSWORD MATCH CHECK ── */
function checkMatch() {
    var np  = document.getElementById('nPwd');
    var cfp = document.getElementById('cfPwd');
    var err = document.getElementById('eCfPwd');
    if (!np || !cfp || !err) return;
    err.textContent = cfp.value && np.value !== cfp.value ? 'Passwords do not match.' : '';
}

/* ── PASSWORD FORM VALIDATION ── */
function validatePwd() {
    var cp  = document.getElementById('cPwd');
    var np  = document.getElementById('nPwd');
    var cfp = document.getElementById('cfPwd');
    var ep  = document.getElementById('ePwd');
    var ecf = document.getElementById('eCfPwd');
    var ok  = true;
    if (!cp.value.trim())  { ok = false; }
    if (np.value.length < 8) {
        if (ep) ep.textContent = 'Password must be at least 8 characters.';
        ok = false;
    } else {
        if (ep) ep.textContent = '';
    }
    if (np.value !== cfp.value) {
        if (ecf) ecf.textContent = 'Passwords do not match.';
        ok = false;
    } else {
        if (ecf) ecf.textContent = '';
    }
    return ok;
}

/* ── MODAL CLOSE ON BACKGROUND CLICK ── */
document.getElementById('addModal').addEventListener('click', function(e){
    if (e.target === this) this.classList.remove('open');
});

/* ── SIDEBAR TOGGLE (mobile) ── */
(function(){
    var sb  = document.getElementById('sidebar');
    var ov  = document.getElementById('sidebarOverlay');
    if (ov && sb) {
        ov.addEventListener('click', function(){
            sb.classList.remove('open');
            ov.classList.remove('active');
            document.body.classList.remove('sidebar-open');
        });
    }
})();
</script>
</body>
</html>
