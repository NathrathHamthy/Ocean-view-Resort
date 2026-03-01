<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.util.List, java.util.ArrayList, com.oceanview.model.Room, com.oceanview.model.User" %>
<%!
    // Helper: parse amenities from either JSON array ["a","b"] or comma-separated "a,b"
    private String[] parseAmenities(String raw) {
        if (raw == null || raw.trim().isEmpty()) return new String[0];
        raw = raw.trim();
        if (raw.startsWith("[")) {
            // JSON array format
            raw = raw.replaceAll("^\\[|\\]$", "").trim();
            if (raw.isEmpty()) return new String[0];
            String[] parts = raw.split(",");
            java.util.List<String> list = new java.util.ArrayList<>();
            for (String p : parts) {
                String v = p.trim().replaceAll("^\"|\"$|^'|'$", "").trim();
                if (!v.isEmpty()) list.add(v);
            }
            return list.toArray(new String[0]);
        } else {
            // Comma-separated format
            String[] parts = raw.split(",");
            java.util.List<String> list = new java.util.ArrayList<>();
            for (String p : parts) {
                String v = p.trim();
                if (!v.isEmpty()) list.add(v);
            }
            return list.toArray(new String[0]);
        }
    }
    private String escJson(String s) {
        if (s == null) return "";
        return s.replace("\\", "\\\\").replace("\"", "\\\"").replace("\r","").replace("\n"," ");
    }
    private String escHtml(String s) {
        if (s == null) return "";
        return s.replace("&","&amp;").replace("<","&lt;").replace(">","&gt;").replace("\"","&quot;").replace("'","&#39;");
    }
%>
<%
    User currentUser = (User) session.getAttribute("loggedInUser");
    if (currentUser == null || !"ADMIN".equals(currentUser.getRole().toString())) {
        response.sendRedirect(request.getContextPath() + "/login");
        return;
    }
    @SuppressWarnings("unchecked")
    List<Room> rooms = (List<Room>) request.getAttribute("rooms");
    if (rooms == null) rooms = new ArrayList<>();

    int cntAvail = 0, cntOccupied = 0, cntMaint = 0, cntReserved = 0;
    for (Room r : rooms) {
        if      (r.getStatus() == Room.RoomStatus.AVAILABLE)   cntAvail++;
        else if (r.getStatus() == Room.RoomStatus.OCCUPIED)    cntOccupied++;
        else if (r.getStatus() == Room.RoomStatus.MAINTENANCE) cntMaint++;
        else if (r.getStatus() == Room.RoomStatus.RESERVED)    cntReserved++;
    }

    String flashSuccess = session.getAttribute("success") != null
        ? (String)session.getAttribute("success")
        : (String)session.getAttribute("successMessage");
    String flashError = session.getAttribute("error") != null
        ? (String)session.getAttribute("error")
        : (String)session.getAttribute("errorMessage");
    session.removeAttribute("success"); session.removeAttribute("successMessage");
    session.removeAttribute("error");   session.removeAttribute("errorMessage");
    if (flashSuccess == null) flashSuccess = (String)request.getAttribute("success");
    if (flashError   == null) flashError   = (String)request.getAttribute("error");

    String ctx = request.getContextPath();
%>
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Room Management - Ocean View Resort</title>
<link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
<link rel="stylesheet" href="<%= ctx %>/assets/css/main.css">
<link rel="stylesheet" href="<%= ctx %>/assets/css/sidebar.css">
<style>
/* ── RESET & ROOT ── */
*,*::before,*::after{box-sizing:border-box;margin:0;padding:0}

/* ── OVERRIDE main.css body flex ── */
body{display:block !important;flex-direction:unset !important}

/* ── SIDEBAR CSS VARIABLES (required by sidebar.css) ── */
:root{
  --ocean-blue:#006994;--ocean-light:#4A90A4;--ocean-dark:#003d5c;
  --sand-beige:#F5E6D3;--coral-accent:#FF6B6B;--gold-accent:#D4AF37;
  --white:#FFFFFF;--light-gray:#F8F9FA;--gray:#6C757D;--dark-gray:#343A40;--black:#212529;
  --success:#28A745;--warning:#FFC107;--danger:#DC3545;--info:#17A2B8;
  --spacing-xs:.25rem;--spacing-sm:.5rem;--spacing-md:1rem;--spacing-lg:1.5rem;--spacing-xl:2rem;--spacing-xxl:3rem;
  --font-primary:'Segoe UI',Tahoma,Geneva,Verdana,sans-serif;
  --shadow-sm:0 1px 3px rgba(0,0,0,.1);--shadow-md:0 4px 6px rgba(0,0,0,.1);--shadow-lg:0 10px 15px rgba(0,0,0,.1);
  --radius-sm:.25rem;--radius-md:.5rem;--radius-lg:1rem;
  --transition-fast:.15s ease-in-out;--transition-base:.3s ease-in-out;--transition-slow:.5s ease-in-out;
}

/* ── SIDEBAR LAYOUT FIXES ── */
.sidebar{
  position:fixed;left:0;top:0;width:280px;height:100vh;
  background:linear-gradient(180deg,#003d5c 0%,#212529 100%);
  color:#fff;display:flex;flex-direction:column;
  box-shadow:2px 0 15px rgba(0,0,0,.2);z-index:1000;
  overflow-y:auto;overflow-x:hidden;transition:transform .3s ease;
}
.sidebar::-webkit-scrollbar{width:5px}
.sidebar::-webkit-scrollbar-track{background:rgba(255,255,255,.04)}
.sidebar::-webkit-scrollbar-thumb{background:rgba(255,255,255,.18);border-radius:3px}
.sidebar-header{padding:1.25rem 1.5rem;display:flex;align-items:center;justify-content:space-between;border-bottom:1px solid rgba(255,255,255,.1);flex-shrink:0}
.sidebar-brand{display:flex;align-items:center;gap:.75rem}
.sidebar-logo{height:38px;width:auto}
.sidebar-brand-text{font-size:1.2rem;font-weight:700;color:#fff;white-space:nowrap}
.sidebar-toggle-btn{background:none;border:none;color:#fff;font-size:1.2rem;cursor:pointer;padding:.3rem;border-radius:.3rem;transition:background .15s ease;display:none}
.sidebar-toggle-btn:hover{background:rgba(255,255,255,.12)}
.sidebar-user{padding:1rem 1.5rem;display:flex;align-items:center;gap:.75rem;background:rgba(255,255,255,.05);border-bottom:1px solid rgba(255,255,255,.08);flex-shrink:0}
.sidebar-user-avatar{width:46px;height:46px;border-radius:50%;background:linear-gradient(135deg,#006994,#D4AF37);display:flex;align-items:center;justify-content:center;font-weight:700;font-size:1rem;color:#fff;flex-shrink:0;letter-spacing:.05em}
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
.sidebar-link.active{background:linear-gradient(90deg,rgba(212,175,55,.22) 0%,rgba(212,175,55,.05) 100%);color:#D4AF37;font-weight:600}
.sidebar-link.active::before{transform:scaleY(1)}
.sidebar-link i{width:20px;text-align:center;font-size:1rem;flex-shrink:0}
.sidebar-link span{flex:1;white-space:nowrap;overflow:hidden;text-overflow:ellipsis}
.sidebar-footer{border-top:1px solid rgba(255,255,255,.1);padding:.75rem;display:flex;flex-direction:column;gap:.25rem;background:rgba(0,0,0,.25);flex-shrink:0}
.sidebar-footer-link{display:flex;align-items:center;gap:.75rem;padding:.65rem 1rem;color:rgba(255,255,255,.75);text-decoration:none;border-radius:.45rem;transition:all .18s ease;font-size:.88rem}
.sidebar-footer-link:hover{background:rgba(255,255,255,.1);color:#fff}
.sidebar-footer-link i{width:20px;text-align:center}
.sidebar-logout{color:rgba(220,53,69,.85)}
.sidebar-logout:hover{background:rgba(220,53,69,.12) !important;color:#dc3545 !important}
.sidebar-overlay{position:fixed;top:0;left:0;width:100%;height:100%;background:rgba(0,0,0,.5);opacity:0;visibility:hidden;transition:all .25s ease;z-index:999}
.sidebar-overlay.active{opacity:1;visibility:visible}
.sidebar-badge{display:inline-flex;align-items:center;justify-content:center;min-width:20px;height:20px;padding:0 6px;background:var(--danger);color:#fff;border-radius:10px;font-size:.68rem;font-weight:700;margin-left:auto}
@media(max-width:992px){
  .sidebar{transform:translateX(-100%)}
  .sidebar.open{transform:translateX(0)}
  .sidebar-toggle-btn{display:block}
  body.sidebar-open{overflow:hidden}
}
@media(max-width:576px){.sidebar{width:82%;max-width:280px}}

/* ── PAGE ROOMS VARS ── */
:root{
  --pri:#006994;--pri-dk:#004f70;--acc:#4A90A4;
  --ok:#28a745;--err:#dc3545;--warn:#ffc107;--inf:#17a2b8;--pur:#6f42c1;
  --w:#fff;
  --g50:#f8f9fa;--g100:#f1f3f5;--g200:#e9ecef;--g300:#dee2e6;
  --g400:#ced4da;--g500:#adb5bd;--g600:#6c757d;--g700:#495057;--g800:#343a40;
  --sh1:0 1px 4px rgba(0,0,0,.08);
  --sh2:0 4px 14px rgba(0,0,0,.12);
  --sh3:0 8px 30px rgba(0,0,0,.18);
  --r:.75rem;--r2:.4rem;--t:.22s ease;
}
body{font-family:'Segoe UI',system-ui,-apple-system,sans-serif;background:#eef2f7;color:var(--g800);min-height:100vh}

/* ── LAYOUT ── */
.pw{display:flex;min-height:100vh}
.mc{flex:1;margin-left:280px;padding:2rem 2.5rem;transition:margin var(--t)}
@media(max-width:992px){.mc{margin-left:0;padding:1rem}}

/* ── MOBILE TOPBAR ── */
.mobile-topbar{display:none;align-items:center;gap:.75rem;padding:.75rem 1rem;background:#fff;border-bottom:1px solid var(--g200);box-shadow:var(--sh1);position:sticky;top:0;z-index:100;margin-bottom:1rem}
.mobile-menu-btn{background:none;border:none;font-size:1.25rem;color:var(--pri);cursor:pointer;padding:.3rem .5rem;border-radius:.35rem;transition:background var(--t)}
.mobile-menu-btn:hover{background:var(--g100)}
.mobile-title{font-size:1rem;font-weight:700;color:var(--g800)}
.mobile-title i{color:var(--pri);margin-right:.3rem}
@media(max-width:992px){.mobile-topbar{display:flex}}

/* ── TOASTS ── */
.toast-wrap{position:fixed;top:1.5rem;right:1.5rem;z-index:9999;display:flex;flex-direction:column;gap:.5rem;pointer-events:none}
.toast{display:flex;align-items:center;gap:.75rem;padding:.9rem 1.25rem;border-radius:var(--r2);color:#fff;font-size:.9rem;font-weight:500;min-width:300px;max-width:420px;box-shadow:var(--sh2);animation:tIn .35s ease;pointer-events:all;cursor:default}
.toast.ok{background:var(--ok)}.toast.er{background:var(--err)}
.toast i{font-size:1.1rem;flex-shrink:0}
.toast-msg{flex:1}
.toast-x{background:none;border:none;color:#fff;font-size:1.2rem;cursor:pointer;opacity:.75;padding:0;line-height:1;flex-shrink:0}
.toast-x:hover{opacity:1}
@keyframes tIn{from{opacity:0;transform:translateX(110%)}to{opacity:1;transform:translateX(0)}}
@keyframes tOut{from{opacity:1;transform:translateX(0)}to{opacity:0;transform:translateX(110%)}}

/* ── PAGE HEADER ── */
.ph{display:flex;justify-content:space-between;align-items:flex-start;margin-bottom:1.75rem;flex-wrap:wrap;gap:1rem}
.ph-left h1{font-size:1.75rem;font-weight:700;color:var(--g800);display:flex;align-items:center;gap:.6rem}
.ph-left h1 i{color:var(--pri)}
.ph-left p{color:var(--g600);font-size:.9rem;margin-top:.3rem}
.btn-add{display:inline-flex;align-items:center;gap:.5rem;padding:.72rem 1.4rem;background:var(--pri);color:#fff;border:none;border-radius:var(--r2);font-size:.92rem;font-weight:600;cursor:pointer;transition:background var(--t),box-shadow var(--t);box-shadow:0 2px 8px rgba(0,105,148,.3)}
.btn-add:hover{background:var(--pri-dk);box-shadow:0 4px 12px rgba(0,105,148,.4)}

/* ── STATS ── */
.stats{display:grid;grid-template-columns:repeat(4,1fr);gap:1.25rem;margin-bottom:1.75rem}
@media(max-width:860px){.stats{grid-template-columns:repeat(2,1fr)}}
@media(max-width:480px){.stats{grid-template-columns:1fr}}
.sc{background:var(--w);border-radius:var(--r);padding:1.25rem 1.4rem;display:flex;align-items:center;gap:1rem;box-shadow:var(--sh1);border-left:4px solid transparent;transition:transform var(--t),box-shadow var(--t)}
.sc:hover{transform:translateY(-3px);box-shadow:var(--sh2)}
.sc.av{border-color:var(--ok)}.sc.oc{border-color:var(--err)}
.sc.mn{border-color:var(--warn)}.sc.tt{border-color:var(--pri)}
.sc-ic{width:50px;height:50px;border-radius:var(--r2);display:flex;align-items:center;justify-content:center;font-size:1.35rem;color:#fff;flex-shrink:0}
.sc.av .sc-ic{background:var(--ok)}.sc.oc .sc-ic{background:var(--err)}
.sc.mn .sc-ic{background:var(--warn)}.sc.tt .sc-ic{background:var(--pri)}
.sc-inf h3{font-size:1.9rem;font-weight:700;line-height:1;color:var(--g800)}
.sc-inf p{font-size:.8rem;color:var(--g600);margin-top:.2rem}

/* ── TOOLBAR ── */
.tb{background:var(--w);border-radius:var(--r);padding:1rem 1.25rem;margin-bottom:1.25rem;display:flex;align-items:center;gap:.75rem;flex-wrap:wrap;box-shadow:var(--sh1)}
.tb-l{display:flex;align-items:center;gap:.6rem;flex:1;flex-wrap:wrap}
.tb-r{display:flex;align-items:center;gap:.6rem}
.sb{position:relative}
.sb i{position:absolute;left:.8rem;top:50%;transform:translateY(-50%);color:var(--g500);font-size:.85rem;pointer-events:none}
.sb input{padding:.55rem .9rem .55rem 2.2rem;border:1.5px solid var(--g200);border-radius:var(--r2);font-size:.88rem;width:220px;outline:none;transition:border var(--t);background:var(--g50);color:var(--g800)}
.sb input:focus{border-color:var(--pri);background:var(--w)}
.fs{padding:.55rem .9rem;border:1.5px solid var(--g200);border-radius:var(--r2);font-size:.88rem;outline:none;cursor:pointer;background:var(--g50);color:var(--g800);transition:border var(--t)}
.fs:focus{border-color:var(--pri)}
.vt{display:flex;border:1.5px solid var(--g200);border-radius:var(--r2);overflow:hidden}
.vt button{padding:.48rem .85rem;background:var(--w);border:none;cursor:pointer;color:var(--g600);font-size:.88rem;transition:all var(--t)}
.vt button.act{background:var(--pri);color:#fff}

/* ── SECTION TITLE ── */
.sh{display:flex;justify-content:space-between;align-items:center;margin-bottom:1rem}
.sh h2{font-size:1rem;font-weight:700;color:var(--g700)}
.rc{font-size:.82rem;color:var(--g600);background:var(--g100);padding:.25rem .7rem;border-radius:1rem}

/* ── BADGES ── */
.badge{display:inline-flex;align-items:center;gap:.3rem;padding:.22rem .7rem;border-radius:1rem;font-size:.7rem;font-weight:700;text-transform:uppercase;letter-spacing:.05em;white-space:nowrap}
.b-av{background:#d4edda;color:#155724}.b-oc{background:#f8d7da;color:#721c24}
.b-mn{background:#fff3cd;color:#856404}.b-rs{background:#e2d9f3;color:#4a235a}

/* ── CARD VIEW ── */
.grid{display:grid;grid-template-columns:repeat(auto-fill,minmax(290px,1fr));gap:1.4rem}
.rc-card{background:var(--w);border-radius:var(--r);overflow:hidden;box-shadow:var(--sh1);transition:transform var(--t),box-shadow var(--t);display:flex;flex-direction:column}
.rc-card:hover{transform:translateY(-4px);box-shadow:var(--sh2)}
.rc-hdr{padding:1.25rem 1.4rem 1rem;background:linear-gradient(135deg,var(--pri) 0%,var(--acc) 100%);color:#fff;position:relative}
.rc-hdr h3{font-size:1.45rem;font-weight:700;letter-spacing:.02em}
.rc-hdr .rtype{font-size:.82rem;opacity:.88;margin-top:.15rem;display:flex;align-items:center;gap:.35rem}
.rc-hdr .badge{position:absolute;top:.9rem;right:.9rem}
.rc-body{padding:1.1rem 1.4rem;flex:1;display:flex;flex-direction:column;gap:.1rem}
.dr{display:flex;justify-content:space-between;align-items:center;padding:.42rem 0;border-bottom:1px solid var(--g100);font-size:.86rem}
.dr:last-of-type{border-bottom:none}
.dr .lbl{color:var(--g600);display:flex;align-items:center;gap:.4rem}
.dr .val{font-weight:600;color:var(--g800)}
.rp{font-size:1.55rem;font-weight:700;color:var(--pri);text-align:center;padding:.65rem .5rem;background:var(--g50);border-radius:var(--r2);margin:.5rem 0;border:1px solid var(--g100)}
.rp small{font-size:.48em;color:var(--g600);font-weight:400}
.amen-wrap{display:flex;flex-wrap:wrap;gap:.3rem;margin-top:.25rem}
.atag{background:linear-gradient(135deg,rgba(0,105,148,.08),rgba(74,144,164,.08));border:1px solid rgba(0,105,148,.18);color:var(--pri-dk);padding:.18rem .55rem;border-radius:1rem;font-size:.74rem;font-weight:500;display:inline-flex;align-items:center;gap:.25rem}
.atag i{font-size:.65rem;opacity:.7}
.rc-actions{display:flex;gap:.5rem;padding:.9rem 1.4rem;background:var(--g50);border-top:1px solid var(--g100)}
.rc-actions .btn{flex:1;justify-content:center}

/* ── TABLE VIEW ── */
.tw{background:var(--w);border-radius:var(--r);box-shadow:var(--sh1);overflow:hidden}
.rt{width:100%;border-collapse:collapse;font-size:.875rem}
.rt thead{background:linear-gradient(135deg,var(--pri),var(--acc))}
.rt thead th{padding:.9rem 1rem;text-align:left;font-weight:600;color:#fff;white-space:nowrap;font-size:.82rem;letter-spacing:.03em}
.rt thead th:first-child{padding-left:1.4rem}
.rt thead th:last-child{padding-right:1.4rem;text-align:center}
.rt tbody tr{border-bottom:1px solid var(--g100);transition:background var(--t)}
.rt tbody tr:last-child{border-bottom:none}
.rt tbody tr:hover{background:var(--g50)}
.rt tbody td{padding:.8rem 1rem;vertical-align:middle}
.rt tbody td:first-child{padding-left:1.4rem;font-weight:700;color:var(--g500);font-size:.8rem}
.rt tbody td:last-child{padding-right:1.4rem;text-align:center}
.rnum{font-weight:700;color:var(--pri);font-size:.95rem}
.tbadge{display:inline-block;padding:.2rem .65rem;border-radius:var(--r2);font-size:.75rem;font-weight:600;background:var(--g100);color:var(--g700)}
.pc{font-weight:700;color:var(--pri)}
.abtns{display:flex;gap:.4rem;justify-content:center}

/* ── BUTTONS ── */
.btn{display:inline-flex;align-items:center;justify-content:center;gap:.4rem;padding:.5rem 1rem;border:none;border-radius:var(--r2);font-size:.84rem;font-weight:600;cursor:pointer;text-decoration:none;transition:all var(--t);white-space:nowrap;line-height:1.2}
.btn-sm{padding:.35rem .7rem;font-size:.78rem}
.btn-pri{background:var(--pri);color:#fff}.btn-pri:hover{background:var(--pri-dk)}
.btn-ok{background:var(--ok);color:#fff}.btn-ok:hover{filter:brightness(.9)}
.btn-warn{background:var(--warn);color:#000}.btn-warn:hover{filter:brightness(.9)}
.btn-err{background:var(--err);color:#fff}.btn-err:hover{filter:brightness(.9)}
.btn-sec{background:var(--g200);color:var(--g800)}.btn-sec:hover{background:var(--g300)}
.btn-inf{background:var(--inf);color:#fff}.btn-inf:hover{filter:brightness(.9)}

/* ── EMPTY STATE ── */
.es{text-align:center;padding:4rem 2rem;color:var(--g600)}
.es i{font-size:3.5rem;color:var(--g300);display:block;margin-bottom:1rem}
.es h3{font-size:1.2rem;margin-bottom:.5rem;color:var(--g700)}
.es p{font-size:.88rem}

/* ── MODAL ── */
.mo{position:fixed;inset:0;background:rgba(0,0,0,.52);z-index:2000;display:flex;align-items:center;justify-content:center;padding:1rem;opacity:0;visibility:hidden;transition:opacity .28s ease,visibility .28s ease}
.mo.show{opacity:1;visibility:visible}
.md{background:var(--w);border-radius:var(--r);width:100%;max-width:720px;max-height:93vh;display:flex;flex-direction:column;box-shadow:var(--sh3);transform:translateY(-18px) scale(.98);transition:transform .28s ease}
.mo.show .md{transform:translateY(0) scale(1)}
.md-sm{max-width:460px}.md-xs{max-width:420px}
.mh{padding:1.1rem 1.5rem;display:flex;align-items:center;justify-content:space-between;background:linear-gradient(135deg,var(--pri),var(--acc));border-radius:var(--r) var(--r) 0 0;color:#fff}
.mh.mh-err{background:linear-gradient(135deg,var(--err),#c82333)}
.mh h2{font-size:1.1rem;font-weight:700;display:flex;align-items:center;gap:.5rem}
.mx{background:none;border:none;font-size:1.5rem;color:#fff;cursor:pointer;opacity:.75;line-height:1;padding:0;transition:opacity var(--t)}
.mx:hover{opacity:1}
.mb{padding:1.4rem 1.5rem;overflow-y:auto;flex:1}
.mf{padding:.9rem 1.5rem;border-top:1px solid var(--g200);display:flex;justify-content:flex-end;gap:.65rem;background:var(--g50);border-radius:0 0 var(--r) var(--r)}

/* ── FORM ── */
.fg{display:grid;grid-template-columns:1fr 1fr;gap:.9rem}
@media(max-width:560px){.fg{grid-template-columns:1fr}}
.fi{display:flex;flex-direction:column;gap:.32rem}
.fi.fw{grid-column:1/-1}
.fl{font-size:.82rem;font-weight:600;color:var(--g700)}
.fl .rq{color:var(--err);margin-left:.15rem}
.fc{padding:.58rem .85rem;border:1.5px solid var(--g300);border-radius:var(--r2);font-size:.88rem;outline:none;transition:border var(--t),box-shadow var(--t);width:100%;font-family:inherit;background:var(--w);color:var(--g800)}
.fc:focus{border-color:var(--pri);box-shadow:0 0 0 3px rgba(0,105,148,.11)}
.fc.fe{border-color:var(--err)}
.fe-msg{font-size:.76rem;color:var(--err);min-height:.85rem}
textarea.fc{resize:vertical;min-height:75px}

/* ── AMENITY CHECKS ── */
.ag{display:grid;grid-template-columns:repeat(3,1fr);gap:.45rem}
@media(max-width:500px){.ag{grid-template-columns:repeat(2,1fr)}}
.al{display:flex;align-items:center;gap:.4rem;padding:.48rem .6rem;border:1.5px solid var(--g200);border-radius:var(--r2);cursor:pointer;font-size:.81rem;color:var(--g700);transition:all var(--t);user-select:none}
.al:hover{border-color:var(--pri);color:var(--pri-dk);background:rgba(0,105,148,.04)}
.al.ck{border-color:var(--pri);background:rgba(0,105,148,.09);color:var(--pri-dk);font-weight:600}
.al input[type=checkbox]{accent-color:var(--pri);width:13px;height:13px;cursor:pointer;flex-shrink:0}
.al i{font-size:.8rem;opacity:.75;flex-shrink:0}

/* ── STATUS OPTIONS ── */
.so{display:grid;grid-template-columns:1fr 1fr;gap:.7rem;margin-top:.75rem}
.sop{padding:.9rem;border:2px solid var(--g200);border-radius:var(--r2);cursor:pointer;text-align:center;transition:all var(--t)}
.sop:hover{border-color:var(--pri);transform:translateY(-1px)}
.sop.sel{border-color:var(--pri);background:rgba(0,105,148,.07)}
.sop i{font-size:1.4rem;display:block;margin-bottom:.3rem}
.sop span{font-size:.82rem;font-weight:600;color:var(--g700)}
.sop.sav i{color:var(--ok)}.sop.soc i{color:var(--err)}
.sop.smn i{color:var(--warn)}.sop.srs i{color:var(--pur)}

/* ── DELETE ── */
.di{text-align:center;font-size:2.8rem;color:var(--err);margin-bottom:1rem}
.dt{text-align:center;color:var(--g600);line-height:1.6}
.dt strong{color:var(--g800)}
</style>
</head>
<body>
<div class="pw">
<jsp:include page="../common/sidebar.jsp">
    <jsp:param name="active" value="rooms"/>
</jsp:include>

<div class="mc">

<!-- MOBILE TOPBAR -->
<div class="mobile-topbar">
    <button class="mobile-menu-btn" onclick="document.getElementById('sidebar').classList.toggle('open');document.getElementById('sidebarOverlay').classList.toggle('active')">
        <i class="fas fa-bars"></i>
    </button>
    <span class="mobile-title"><i class="fas fa-bed"></i> Room Management</span>
</div>

<!-- TOASTS -->
<div class="toast-wrap">
<% if (flashSuccess != null && !flashSuccess.isEmpty()) { %>
<div class="toast ok" id="tOk"><i class="fas fa-check-circle"></i><span class="toast-msg"><%= escHtml(flashSuccess) %></span><button class="toast-x" onclick="rmToast('tOk')">&times;</button></div>
<% } %>
<% if (flashError != null && !flashError.isEmpty()) { %>
<div class="toast er" id="tEr"><i class="fas fa-exclamation-circle"></i><span class="toast-msg"><%= escHtml(flashError) %></span><button class="toast-x" onclick="rmToast('tEr')">&times;</button></div>
<% } %>
</div>

<!-- PAGE HEADER -->
<div class="ph">
    <div class="ph-left">
        <h1><i class="fas fa-bed"></i> Room Management</h1>
        <p>Manage hotel rooms, pricing, amenities and availability</p>
    </div>
    <button class="btn-add" onclick="openAddModal()"><i class="fas fa-plus"></i> Add New Room</button>
</div>

<!-- STATS -->
<div class="stats">
    <div class="sc av"><div class="sc-ic"><i class="fas fa-door-open"></i></div><div class="sc-inf"><h3><%= cntAvail %></h3><p>Available</p></div></div>
    <div class="sc oc"><div class="sc-ic"><i class="fas fa-door-closed"></i></div><div class="sc-inf"><h3><%= cntOccupied %></h3><p>Occupied</p></div></div>
    <div class="sc mn"><div class="sc-ic"><i class="fas fa-tools"></i></div><div class="sc-inf"><h3><%= cntMaint + cntReserved %></h3><p>Maintenance &amp; Reserved</p></div></div>
    <div class="sc tt"><div class="sc-ic"><i class="fas fa-bed"></i></div><div class="sc-inf"><h3><%= rooms.size() %></h3><p>Total Rooms</p></div></div>
</div>

<!-- TOOLBAR -->
<div class="tb">
    <div class="tb-l">
        <div class="sb"><i class="fas fa-search"></i><input type="text" id="srch" placeholder="Search room number or type..." oninput="doFilter()"></div>
        <select class="fs" id="fType" onchange="doFilter()">
            <option value="">All Types</option>
            <option value="SINGLE">Single</option>
            <option value="DOUBLE">Double</option>
            <option value="DELUXE">Deluxe</option>
            <option value="SUITE">Suite</option>
            <option value="FAMILY">Family</option>
        </select>
        <select class="fs" id="fStat" onchange="doFilter()">
            <option value="">All Status</option>
            <option value="AVAILABLE">Available</option>
            <option value="OCCUPIED">Occupied</option>
            <option value="MAINTENANCE">Maintenance</option>
            <option value="RESERVED">Reserved</option>
        </select>
    </div>
    <div class="tb-r">
        <div class="vt">
            <button id="vCard"  class="act" onclick="setView('card')"  title="Card View"><i class="fas fa-th-large"></i></button>
            <button id="vTable" onclick="setView('table')" title="Table View"><i class="fas fa-list"></i></button>
        </div>
    </div>
</div>

<!-- SECTION HEADING -->
<div class="sh">
    <h2><i class="fas fa-layer-group" style="color:var(--pri);margin-right:.4rem"></i>All Rooms</h2>
    <span class="rc" id="rCount"><%= rooms.size() %> room(s)</span>
</div>

<!-- ══════════════ CARD VIEW ══════════════ -->
<div id="cvView">
<% if (rooms.isEmpty()) { %>
<div class="es"><i class="fas fa-bed"></i><h3>No Rooms Found</h3><p>Click "Add New Room" to create your first room.</p></div>
<% } else { %>
<div class="grid" id="cardGrid">
<%
for (Room room : rooms) {
    // Status meta
    String bc="b-av", bi="fa-check-circle", bLabel="AVAILABLE";
    if      (room.getStatus()==Room.RoomStatus.OCCUPIED)    { bc="b-oc"; bi="fa-door-closed";    bLabel="OCCUPIED";    }
    else if (room.getStatus()==Room.RoomStatus.MAINTENANCE) { bc="b-mn"; bi="fa-tools";           bLabel="MAINTENANCE"; }
    else if (room.getStatus()==Room.RoomStatus.RESERVED)    { bc="b-rs"; bi="fa-calendar-check";  bLabel="RESERVED";    }

    String rType  = room.getRoomType()      != null ? room.getRoomType().name()             : "N/A";
    String rPrice = room.getPricePerNight() != null ? room.getPricePerNight().toPlainString(): "0.00";
    String rFloor = room.getFloor()  != null ? String.valueOf(room.getFloor()) : "N/A";
    String rSize  = room.getSize()   != null ? room.getSize() + " m&#178;" : "N/A";
    int    rId    = room.getRoomId();
    String rNum   = room.getRoomNumber();
    String rStat  = room.getStatus().name();

    // Parse amenities cleanly
    String[] amenArr = parseAmenities(room.getAmenities());
%>
<div class="rc-card" data-num="<%= rNum.toLowerCase() %>" data-type="<%= rType %>" data-stat="<%= rStat %>">
    <div class="rc-hdr">
        <h3>Room <%= escHtml(rNum) %></h3>
        <div class="rtype"><i class="fas fa-tag"></i> <%= rType %></div>
        <span class="badge <%= bc %>"><i class="fas <%= bi %>"></i> <%= bLabel %></span>
    </div>
    <div class="rc-body">
        <div class="dr"><span class="lbl"><i class="fas fa-users"></i> Capacity</span><span class="val"><%= room.getCapacity() %> Guest(s)</span></div>
        <div class="dr"><span class="lbl"><i class="fas fa-building"></i> Floor</span><span class="val"><%= rFloor %></span></div>
        <div class="dr"><span class="lbl"><i class="fas fa-tag"></i> Room Type</span><span class="val"><%= rType %></span></div>
        <div class="rp">Rs. <%= rPrice %> <small>/ night</small></div>
        <% if (amenArr.length > 0) { %>
        <div class="amen-wrap">
        <% for (String a : amenArr) { %><span class="atag"><i class="fas fa-check"></i><%= escHtml(a) %></span><% } %>
        </div>
        <% } %>
    </div>
    <div class="rc-actions">
        <button class="btn btn-pri btn-sm" onclick="openEditModal(<%= rId %>)"><i class="fas fa-edit"></i> Edit</button>
        <button class="btn btn-inf btn-sm" onclick="openStatusModal(<%= rId %>)"><i class="fas fa-sync-alt"></i> Status</button>
        <button class="btn btn-err btn-sm" onclick="openDeleteModal(<%= rId %>)"><i class="fas fa-trash-alt"></i></button>
    </div>
</div>
<% } %>
</div>
<% } %>
</div>

<!-- ══════════════ TABLE VIEW ══════════════ -->
<div id="tbView" style="display:none">
<% if (rooms.isEmpty()) { %>
<div class="es"><i class="fas fa-bed"></i><h3>No Rooms Found</h3><p>Click "Add New Room" to get started.</p></div>
<% } else { %>
<div class="tw">
<table class="rt">
    <thead><tr>
        <th>#</th><th>Room</th><th>Type</th><th>Floor</th>
        <th>Capacity</th><th>Size</th><th>Price / Night</th>
        <th>Amenities</th><th>Status</th><th>Actions</th>
    </tr></thead>
    <tbody id="tBody">
    <%
    int rowN=1;
    for (Room room : rooms) {
        String bc2="b-av", bi2="fa-check-circle", bLbl2="AVAILABLE";
        if      (room.getStatus()==Room.RoomStatus.OCCUPIED)    { bc2="b-oc"; bi2="fa-door-closed";   bLbl2="OCCUPIED";    }
        else if (room.getStatus()==Room.RoomStatus.MAINTENANCE) { bc2="b-mn"; bi2="fa-tools";          bLbl2="MAINTENANCE"; }
        else if (room.getStatus()==Room.RoomStatus.RESERVED)    { bc2="b-rs"; bi2="fa-calendar-check"; bLbl2="RESERVED";    }

        String rType2  = room.getRoomType()      != null ? room.getRoomType().name()              : "N/A";
        String rPrice2 = room.getPricePerNight() != null ? room.getPricePerNight().toPlainString(): "0.00";
        String rFloor2 = room.getFloor() != null ? String.valueOf(room.getFloor()) : "-";
        String rSize2  = room.getSize()  != null ? room.getSize() + " m&#178;" : "-";
        String rNum2   = room.getRoomNumber();
        String rStat2  = room.getStatus().name();
        int    rId2    = room.getRoomId();
        String[] amenArr2 = parseAmenities(room.getAmenities());
    %>
    <tr data-num="<%= rNum2.toLowerCase() %>" data-type="<%= rType2 %>" data-stat="<%= rStat2 %>">
        <td style="color:var(--g500)"><%= rowN++ %></td>
        <td><span class="rnum">Room <%= escHtml(rNum2) %></span></td>
        <td><span class="tbadge"><%= rType2 %></span></td>
        <td><%= rFloor2 %></td>
        <td><i class="fas fa-users" style="color:var(--g500);margin-right:.3rem;font-size:.8rem"></i><%= room.getCapacity() %></td>
        <td><%= rSize2 %></td>
        <td class="pc">Rs. <%= rPrice2 %></td>
        <td>
            <% if (amenArr2.length > 0) { %>
            <span style="font-size:.78rem;color:var(--g600)"><i class="fas fa-check-double" style="color:var(--ok);margin-right:.25rem"></i><%= amenArr2.length %> amenit<%= amenArr2.length==1?"y":"ies" %></span>
            <% } else { %><span style="color:var(--g400);font-size:.8rem">None</span><% } %>
        </td>
        <td><span class="badge <%= bc2 %>"><i class="fas <%= bi2 %>"></i> <%= bLbl2 %></span></td>
        <td>
            <div class="abtns">
                <button class="btn btn-pri btn-sm" onclick="openEditModal(<%= rId2 %>)" title="Edit Room"><i class="fas fa-edit"></i></button>
                <button class="btn btn-inf btn-sm" onclick="openStatusModal(<%= rId2 %>)" title="Change Status"><i class="fas fa-sync-alt"></i></button>
                <button class="btn btn-err btn-sm" onclick="openDeleteModal(<%= rId2 %>)" title="Delete Room"><i class="fas fa-trash-alt"></i></button>
            </div>
        </td>
    </tr>
    <% } %>
    </tbody>
</table>
</div>
<% } %>
</div>

</div><!-- /mc -->
</div><!-- /pw -->
<!-- ══ ROOM DATA STORE (JSON) ══ -->
<script id="RDS" type="application/json">
[<%
boolean first = true;
for (Room room : rooms) {
    if (!first) out.print(",");
    first = false;
    String[] am = parseAmenities(room.getAmenities());
    StringBuilder amJson = new StringBuilder("[");
    for (int i=0;i<am.length;i++) { if(i>0)amJson.append(","); amJson.append("\"").append(escJson(am[i])).append("\""); }
    amJson.append("]");
    String rType  = room.getRoomType()      != null ? room.getRoomType().name()              : "";
    String rPrice = room.getPricePerNight() != null ? room.getPricePerNight().toPlainString(): "0.00";
    String rFloor = room.getFloor() != null ? String.valueOf(room.getFloor()) : "";
    String rSize  = room.getSize()  != null ? String.valueOf(room.getSize())  : "";
    String rStat  = room.getStatus().name();
    String rNum   = escJson(room.getRoomNumber());
    String rDesc  = escJson(room.getDescription());
    String rImg   = escJson(room.getImageUrl());
    int    rId    = room.getRoomId();
    int    rCap   = room.getCapacity();
%>
{"id":<%= rId %>,"num":"<%= rNum %>","type":"<%= rType %>","floor":"<%= rFloor %>","cap":"<%= rCap %>","price":"<%= rPrice %>","size":"<%= rSize %>","stat":"<%= rStat %>","desc":"<%= rDesc %>","img":"<%= rImg %>","amen":<%= amJson %>}
<% } %>
]
</script>

<!-- ══ ADD/EDIT MODAL ══ -->
<div class="mo" id="mRoom">
<div class="md">
    <div class="mh"><h2 id="mRoomTitle"><i class="fas fa-bed"></i> Add New Room</h2><button class="mx" onclick="cModal('mRoom')">&times;</button></div>
    <div class="mb">
        <form id="roomForm" method="post" action="<%= ctx %>/admin/rooms" autocomplete="off">
            <input type="hidden" name="action" id="fAction" value="create">
            <input type="hidden" name="roomId" id="fRoomId">
            <div class="fg">
                <!-- Room Number -->
                <div class="fi">
                    <label class="fl" for="fNum">Room Number <span class="rq">*</span></label>
                    <input type="text" class="fc" id="fNum" name="roomNumber" placeholder="e.g. 101" maxlength="10">
                    <span class="fe-msg" id="eNum"></span>
                </div>
                <!-- Room Type -->
                <div class="fi">
                    <label class="fl" for="fType">Room Type <span class="rq">*</span></label>
                    <select class="fc" id="fType2" name="roomType">
                        <option value="">-- Select Type --</option>
                        <option value="SINGLE">Single</option>
                        <option value="DOUBLE">Double</option>
                        <option value="DELUXE">Deluxe</option>
                        <option value="SUITE">Suite</option>
                        <option value="FAMILY">Family</option>
                    </select>
                    <span class="fe-msg" id="eType"></span>
                </div>
                <!-- Floor -->
                <div class="fi">
                    <label class="fl" for="fFloor">Floor <span class="rq">*</span></label>
                    <input type="number" class="fc" id="fFloor" name="floor" min="0" max="100" placeholder="e.g. 1">
                    <span class="fe-msg" id="eFloor"></span>
                </div>
                <!-- Capacity -->
                <div class="fi">
                    <label class="fl" for="fCap">Capacity (Guests) <span class="rq">*</span></label>
                    <input type="number" class="fc" id="fCap" name="capacity" min="1" max="20" placeholder="e.g. 2">
                    <span class="fe-msg" id="eCap"></span>
                </div>
                <!-- Price -->
                <div class="fi">
                    <label class="fl" for="fPrice">Price / Night (Rs.) <span class="rq">*</span></label>
                    <input type="number" class="fc" id="fPrice" name="pricePerNight" min="0" step="0.01" placeholder="e.g. 5000.00">
                    <span class="fe-msg" id="ePrice"></span>
                </div>
                <!-- Size -->
                <div class="fi">
                    <label class="fl" for="fSize">Size (m&#178;)</label>
                    <input type="number" class="fc" id="fSize" name="size" min="1" max="5000" placeholder="e.g. 35">
                </div>
                <!-- Status -->
                <div class="fi">
                    <label class="fl" for="fStat2">Status <span class="rq">*</span></label>
                    <select class="fc" id="fStat2" name="status">
                        <option value="AVAILABLE">Available</option>
                        <option value="OCCUPIED">Occupied</option>
                        <option value="MAINTENANCE">Maintenance</option>
                        <option value="RESERVED">Reserved</option>
                    </select>
                </div>
                <!-- Image URL -->
                <div class="fi fw">
                    <label class="fl" for="fImg">Image URL <span style="color:var(--g500);font-weight:400">(leave blank to use default for room type)</span></label>
                    <input type="text" class="fc" id="fImg" name="imageUrl" placeholder="https://... or leave blank for auto">
                    <div id="imgPreviewWrap" style="margin-top:.6rem;display:none">
                        <img id="imgPreview" src="" alt="Room Preview"
                             style="width:100%;max-height:180px;object-fit:cover;border-radius:var(--r2);border:1.5px solid var(--g200);"
                             onerror="this.style.display='none'">
                    </div>
                </div>
                <!-- Description -->
                <div class="fi fw">
                    <label class="fl" for="fDesc">Description</label>
                    <textarea class="fc" id="fDesc" name="description" rows="3" placeholder="Describe the room..."></textarea>
                </div>
                <!-- Amenities -->
                <div class="fi fw">
                    <label class="fl">Amenities</label>
                    <div class="ag">
                        <label class="al"><input type="checkbox" value="WiFi"><i class="fas fa-wifi"></i> Free WiFi</label>
                        <label class="al"><input type="checkbox" value="Smart TV"><i class="fas fa-tv"></i> Smart TV</label>
                        <label class="al"><input type="checkbox" value="Air Conditioning"><i class="fas fa-wind"></i> Air Conditioning</label>
                        <label class="al"><input type="checkbox" value="Mini Bar"><i class="fas fa-cocktail"></i> Mini Bar</label>
                        <label class="al"><input type="checkbox" value="Balcony"><i class="fas fa-archway"></i> Balcony</label>
                        <label class="al"><input type="checkbox" value="Ocean View"><i class="fas fa-water"></i> Ocean View</label>
                        <label class="al"><input type="checkbox" value="Safe"><i class="fas fa-lock"></i> In-Room Safe</label>
                        <label class="al"><input type="checkbox" value="Pool Access"><i class="fas fa-swimming-pool"></i> Pool Access</label>
                        <label class="al"><input type="checkbox" value="Spa Access"><i class="fas fa-spa"></i> Spa Access</label>
                        <label class="al"><input type="checkbox" value="Kitchen"><i class="fas fa-utensils"></i> Kitchen</label>
                        <label class="al"><input type="checkbox" value="Jacuzzi"><i class="fas fa-hot-tub"></i> Jacuzzi</label>
                        <label class="al"><input type="checkbox" value="Two Bedrooms"><i class="fas fa-bed"></i> Two Bedrooms</label>
                    </div>
                    <input type="hidden" id="fAmen" name="amenities">
                </div>
            </div>
        </form>
    </div>
    <div class="mf">
        <button type="button" class="btn btn-sec" onclick="cModal('mRoom')"><i class="fas fa-times"></i> Cancel</button>
        <button type="button" class="btn btn-ok"  onclick="doSubmit()"><i class="fas fa-save"></i> <span id="saveTxt">Save Room</span></button>
    </div>
</div>
</div>

<!-- ══ STATUS MODAL ══ -->
<div class="mo" id="mStat">
<div class="md md-sm">
    <div class="mh"><h2><i class="fas fa-sync-alt"></i> Change Room Status</h2><button class="mx" onclick="cModal('mStat')">&times;</button></div>
    <div class="mb">
        <p style="color:var(--g600);margin-bottom:.5rem;font-size:.9rem">Select new status for <strong id="sRoomLbl" style="color:var(--g800)">Room</strong>:</p>
        <div class="so">
            <div class="sop sav" onclick="pickStat('AVAILABLE',this)"><i class="fas fa-door-open"></i><span>Available</span></div>
            <div class="sop soc" onclick="pickStat('OCCUPIED',this)"><i class="fas fa-door-closed"></i><span>Occupied</span></div>
            <div class="sop smn" onclick="pickStat('MAINTENANCE',this)"><i class="fas fa-tools"></i><span>Maintenance</span></div>
            <div class="sop srs" onclick="pickStat('RESERVED',this)"><i class="fas fa-calendar-check"></i><span>Reserved</span></div>
        </div>
        <input type="hidden" id="sSelStat">
        <input type="hidden" id="sRoomId">
    </div>
    <div class="mf">
        <button type="button" class="btn btn-sec" onclick="cModal('mStat')"><i class="fas fa-times"></i> Cancel</button>
        <button type="button" class="btn btn-pri" onclick="doStatUpdate()"><i class="fas fa-check"></i> Update Status</button>
    </div>
</div>
</div>

<!-- ══ DELETE MODAL ══ -->
<div class="mo" id="mDel">
<div class="md md-xs">
    <div class="mh mh-err"><h2><i class="fas fa-trash-alt"></i> Delete Room</h2><button class="mx" onclick="cModal('mDel')">&times;</button></div>
    <div class="mb" style="padding:2rem 1.5rem">
        <div class="di"><i class="fas fa-exclamation-triangle"></i></div>
        <div class="dt">
            <p>Are you sure you want to permanently delete</p>
            <p><strong id="dRoomLbl">this room</strong>?</p>
            <p style="margin-top:.75rem;font-size:.82rem;color:var(--err)"><i class="fas fa-info-circle"></i> This action cannot be undone and will remove all room data.</p>
        </div>
    </div>
    <div class="mf">
        <button type="button" class="btn btn-sec" onclick="cModal('mDel')"><i class="fas fa-times"></i> Cancel</button>
        <a id="dLink" href="#" class="btn btn-err"><i class="fas fa-trash-alt"></i> Yes, Delete</a>
    </div>
</div>
</div>

<script>
/* ── DATA ── */
var RD = JSON.parse(document.getElementById('RDS').textContent);
var RM = {};
RD.forEach(function(r){ RM[r.id] = r; });
var CTX = '<%= ctx %>';

/* ── TOAST ── */
function rmToast(id){
    var t=document.getElementById(id);
    if(!t)return;
    t.style.animation='tOut .3s ease forwards';
    setTimeout(function(){if(t.parentNode)t.parentNode.removeChild(t);},320);
}
document.querySelectorAll('.toast').forEach(function(t){
    setTimeout(function(){ t.style.animation='tOut .3s ease forwards'; setTimeout(function(){if(t.parentNode)t.parentNode.removeChild(t);},320); },5000);
});

/* ── VIEW SWITCH ── */
function setView(v){
    document.getElementById('cvView').style.display  = v==='card'  ? '' : 'none';
    document.getElementById('tbView').style.display  = v==='table' ? '' : 'none';
    document.getElementById('vCard').classList.toggle('act',  v==='card');
    document.getElementById('vTable').classList.toggle('act', v==='table');
    doFilter();
}

/* ── FILTER ── */
function doFilter(){
    var s=document.getElementById('srch').value.toLowerCase().trim();
    var t=document.getElementById('fType').value.toUpperCase();
    var st=document.getElementById('fStat').value.toUpperCase();
    var vis=0;
    document.querySelectorAll('#cardGrid .rc-card').forEach(function(c){
        var show=(!s||c.textContent.toLowerCase().includes(s)||c.dataset.num.includes(s))
               &&(!t||c.dataset.type===t)&&(!st||c.dataset.stat===st);
        c.style.display=show?'':'none'; if(show)vis++;
    });
    document.querySelectorAll('#tBody tr').forEach(function(r){
        var show=(!s||r.textContent.toLowerCase().includes(s)||r.dataset.num.includes(s))
               &&(!t||r.dataset.type===t)&&(!st||r.dataset.stat===st);
        r.style.display=show?'':'none';
    });
    document.getElementById('rCount').textContent=vis+' room(s)';
}

/* ── MODAL HELPERS ── */
function oModal(id){ document.getElementById(id).classList.add('show'); document.body.style.overflow='hidden'; }
function cModal(id){ document.getElementById(id).classList.remove('show'); document.body.style.overflow=''; }
document.querySelectorAll('.mo').forEach(function(o){
    o.addEventListener('click',function(e){ if(e.target===o) cModal(o.id); });
});
document.addEventListener('keydown',function(e){
    if(e.key==='Escape') document.querySelectorAll('.mo.show').forEach(function(m){ cModal(m.id); });
});

/* ── DEFAULT IMAGE URLS BY ROOM TYPE ── */
var DEFAULT_IMAGES = {
    'SINGLE': 'https://images.unsplash.com/photo-1631049307264-da0ec9d70304?w=800&q=80',
    'DOUBLE': 'https://images.unsplash.com/photo-1566665797739-1674de7a421a?w=800&q=80',
    'DELUXE': 'https://images.unsplash.com/photo-1578683010236-d716f9a3f461?w=800&q=80',
    'SUITE':  'https://images.unsplash.com/photo-1631049552057-403cdb8f0658?w=800&q=80',
    'FAMILY': 'https://images.unsplash.com/photo-1591088398332-8a7791972843?w=800&q=80'
};

function updateImgPreview() {
    var url  = document.getElementById('fImg').value.trim();
    var type = document.getElementById('fType2').value;
    var src  = url || DEFAULT_IMAGES[type] || '';
    var wrap = document.getElementById('imgPreviewWrap');
    var img  = document.getElementById('imgPreview');
    if (src) {
        img.src = src;
        img.style.display = 'block';
        wrap.style.display = 'block';
    } else {
        wrap.style.display = 'none';
    }
}

// When room type changes: auto-fill image URL if field is blank, always refresh preview
document.getElementById('fType2').addEventListener('change', function() {
    var imgField = document.getElementById('fImg');
    if (!imgField.value.trim()) {
        imgField.value = DEFAULT_IMAGES[this.value] || '';
    }
    updateImgPreview();
});

// When image URL changes: refresh preview
document.getElementById('fImg').addEventListener('input', updateImgPreview);

/* ── AMENITY HELPERS ── */
function syncAmenUI(list){
    var low=list.map(function(a){return a.trim().toLowerCase();});
    document.querySelectorAll('.al').forEach(function(l){
        var cb=l.querySelector('input[type=checkbox]');
        cb.checked=low.includes(cb.value.toLowerCase());
        l.classList.toggle('ck',cb.checked);
    });
    buildAmen();
}
function buildAmen(){
    var v=[];
    document.querySelectorAll('.al input[type=checkbox]:checked').forEach(function(cb){v.push(cb.value);});
    document.getElementById('fAmen').value=v.join(',');
}
document.querySelectorAll('.al input[type=checkbox]').forEach(function(cb){
    cb.addEventListener('change',function(){
        this.closest('.al').classList.toggle('ck',this.checked); buildAmen();
    });
});

/* ── FORM RESET ── */
function resetForm(){
    document.getElementById('roomForm').reset();
    document.getElementById('fAmen').value='';
    document.querySelectorAll('.al').forEach(function(l){l.classList.remove('ck');});
    document.querySelectorAll('.fe-msg').forEach(function(e){e.textContent='';});
    document.querySelectorAll('.fc.fe').forEach(function(f){f.classList.remove('fe');});
}

/* ── VALIDATE ── */
function validate(){
    var ok=true;
    function chk(fid,eid,msg){
        var f=document.getElementById(fid),e=document.getElementById(eid);
        if(msg){f.classList.add('fe');if(e)e.textContent=msg;ok=false;}
        else{f.classList.remove('fe');if(e)e.textContent='';}
    }
    chk('fNum',  'eNum',  !document.getElementById('fNum').value.trim()?'Room number is required.':'');
    chk('fType2','eType', !document.getElementById('fType2').value?'Please select a room type.':'');
    chk('fFloor','eFloor',document.getElementById('fFloor').value===''||parseInt(document.getElementById('fFloor').value)<0?'Enter a valid floor.':'');
    chk('fCap',  'eCap',  !document.getElementById('fCap').value||parseInt(document.getElementById('fCap').value)<1?'Capacity must be at least 1.':'');
    chk('fPrice','ePrice',!document.getElementById('fPrice').value||parseFloat(document.getElementById('fPrice').value)<0?'Enter a valid price.':'');
    return ok;
}

/* ── ADD MODAL ── */
function openAddModal(){
    resetForm();
    document.getElementById('mRoomTitle').innerHTML='<i class="fas fa-plus-circle"></i> Add New Room';
    document.getElementById('fAction').value='create';
    document.getElementById('fRoomId').value='';
    document.getElementById('saveTxt').textContent='Save Room';
    document.getElementById('fStat2').value='AVAILABLE';
    document.getElementById('imgPreviewWrap').style.display='none';
    oModal('mRoom');
}

/* ── EDIT MODAL ── */
function openEditModal(id){
    var r=RM[id]; if(!r){alert('Room not found.');return;}
    resetForm();
    document.getElementById('mRoomTitle').innerHTML='<i class="fas fa-edit"></i> Edit Room '+r.num;
    document.getElementById('fAction').value='update';
    document.getElementById('fRoomId').value=r.id;
    document.getElementById('saveTxt').textContent='Update Room';
    document.getElementById('fNum').value=r.num;
    document.getElementById('fType2').value=r.type;
    document.getElementById('fFloor').value=r.floor;
    document.getElementById('fCap').value=r.cap;
    document.getElementById('fPrice').value=r.price;
    document.getElementById('fSize').value=r.size;
    document.getElementById('fStat2').value=r.stat;
    document.getElementById('fDesc').value=r.desc;
    document.getElementById('fImg').value=r.img;
    updateImgPreview();
    syncAmenUI(r.amen);
    oModal('mRoom');
}

/* ── SUBMIT ── */
function doSubmit(){
    buildAmen();
    if(validate()) document.getElementById('roomForm').submit();
}

/* ── STATUS MODAL ── */
function openStatusModal(id){
    var r=RM[id]; if(!r){alert('Room not found.');return;}
    document.getElementById('sRoomLbl').textContent='Room '+r.num;
    document.getElementById('sRoomId').value=id;
    document.getElementById('sSelStat').value=r.stat;
    document.querySelectorAll('.sop').forEach(function(o){o.classList.remove('sel');});
    document.querySelectorAll('.sop').forEach(function(o){
        var s=o.querySelector('span').textContent.toUpperCase();
        if(s===r.stat||s.replace(' ','_')===r.stat) o.classList.add('sel');
    });
    oModal('mStat');
}
function pickStat(s,el){
    document.querySelectorAll('.sop').forEach(function(o){o.classList.remove('sel');});
    el.classList.add('sel');
    document.getElementById('sSelStat').value=s;
}
function doStatUpdate(){
    var id=document.getElementById('sRoomId').value;
    var st=document.getElementById('sSelStat').value;
    if(!st){alert('Please select a status.');return;}
    window.location.href=CTX+'/admin/rooms?action=updateStatus&id='+id+'&status='+st;
}

/* ── DELETE MODAL ── */
function openDeleteModal(id){
    var r=RM[id]; if(!r){alert('Room not found.');return;}
    document.getElementById('dRoomLbl').textContent='"Room '+r.num+'"';
    document.getElementById('dLink').href=CTX+'/admin/rooms?action=delete&id='+id;
    oModal('mDel');
}

/* ── INIT ── */
(function(){
    var tot=RD.length;
    document.getElementById('rCount').textContent=tot+' room(s)';
})();
</script>
</body>
</html>
