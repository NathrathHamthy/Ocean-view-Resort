<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" isErrorPage="true"%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>500 - Server Error | Ocean View Resort</title>
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
    <style>
        *{box-sizing:border-box;margin:0;padding:0}
        body{font-family:'Segoe UI',system-ui,sans-serif;background:#F5F7FA;min-height:100vh;display:flex;align-items:center;justify-content:center;}
        .error-box{text-align:center;padding:60px 40px;max-width:500px;}
        .error-code{font-size:7rem;font-weight:900;color:#B7791F;line-height:1;}
        .error-title{font-size:1.5rem;font-weight:700;color:#1A2332;margin:16px 0 8px;}
        .error-msg{color:#718096;font-size:0.95rem;margin-bottom:32px;}
        .btn{display:inline-flex;align-items:center;gap:8px;padding:12px 28px;background:#1A6B8A;color:#fff;border-radius:8px;text-decoration:none;font-weight:600;font-size:0.9rem;transition:background 0.2s;margin:0 6px;}
        .btn:hover{background:#0D2137;}
        .icon{font-size:4rem;color:#CBD5E0;margin-bottom:20px;}
    </style>
</head>
<body>
    <div class="error-box">
        <div class="icon"><i class="fas fa-exclamation-triangle"></i></div>
        <div class="error-code">500</div>
        <div class="error-title">Internal Server Error</div>
        <div class="error-msg">Something went wrong on our end. Our team has been notified. Please try again shortly.</div>
        <a href="javascript:history.back()" class="btn"><i class="fas fa-arrow-left"></i> Go Back</a>
        <a href="<%= request.getContextPath() %>/dashboard" class="btn"><i class="fas fa-home"></i> Dashboard</a>
    </div>
</body>
</html>
