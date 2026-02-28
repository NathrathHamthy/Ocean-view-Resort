package com.oceanview.filter;

import com.oceanview.model.User;
import com.oceanview.util.Constants;
import jakarta.servlet.*;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpSession;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.io.IOException;

/**
 * Logging Filter
 * Logs all HTTP requests for monitoring and audit purposes
 * URL Pattern: /* (configured in web.xml)
 * 
 * @author Ocean View Resort Development Team
 * @version 1.0.0
 */
public class LoggingFilter implements Filter {
    
    private static final Logger logger = LoggerFactory.getLogger(LoggingFilter.class);
    
    @Override
    public void init(FilterConfig filterConfig) throws ServletException {
        logger.info("LoggingFilter initialized");
    }
    
    @Override
    public void doFilter(ServletRequest request, ServletResponse response, FilterChain chain)
            throws IOException, ServletException {
        
        HttpServletRequest httpRequest = (HttpServletRequest) request;
        
        // Get request details
        String method = httpRequest.getMethod();
        String uri = httpRequest.getRequestURI();
        String queryString = httpRequest.getQueryString();
        String ipAddress = getClientIP(httpRequest);
        
        // Log request
        long startTime = System.currentTimeMillis();
        logger.info("Request: {} {} from IP: {}", method, uri, ipAddress);
        
        // Process request
        chain.doFilter(request, response);
        
        // Log response time
        long duration = System.currentTimeMillis() - startTime;
        logger.info("Response: {} {} completed in {}ms", method, uri, duration);
        
        // Create audit log for important actions
        if (shouldAudit(uri)) {
            createAuditLog(httpRequest, uri, ipAddress);
        }
    }
    
    /**
     * Get client IP address
     */
    private String getClientIP(HttpServletRequest request) {
        String ip = request.getHeader("X-Forwarded-For");
        if (ip == null || ip.isEmpty() || "unknown".equalsIgnoreCase(ip)) {
            ip = request.getHeader("X-Real-IP");
        }
        if (ip == null || ip.isEmpty() || "unknown".equalsIgnoreCase(ip)) {
            ip = request.getRemoteAddr();
        }
        return ip;
    }
    
    /**
     * Check if URI should be audited
     */
    private boolean shouldAudit(String uri) {
        // Audit important actions
        return uri.contains("/login") || 
               uri.contains("/logout") || 
               uri.contains("/register") ||
               uri.contains("/reservation") ||
               uri.contains("/payment") ||
               uri.contains("/user");
    }
    
    /**
     * Create audit log entry
     * Note: This creates audit logs in database. Currently logs to SLF4J only.
     * Uncomment database code once AuditLogDAO is available.
     */
    private void createAuditLog(HttpServletRequest request, String uri, String ipAddress) {
        try {
            HttpSession session = request.getSession(false);
            User user = null;
            String username = "anonymous";
            
            if (session != null) {
                user = (User) session.getAttribute(Constants.SESSION_USER);
                if (user != null) {
                    username = user.getUsername();
                }
            }
            
            // Determine action from URI
            String action = determineAction(uri);
            
            // Log to SLF4J (file-based logging)
            logger.info("AUDIT: User={}, Action={}, URI={}, Method={}, IP={}", 
                       username, action, uri, request.getMethod(), ipAddress);
            
            // TODO: Enable database audit logging once database is set up
            // Uncomment below to enable database audit logs:
            /*
            AuditLogDAO auditLogDAO = new AuditLogDAO();
            AuditLog log = new AuditLog();
            if (user != null) {
                log.setUserId(user.getUserId());
            }
            log.setAction(action);
            log.setEntityType("HTTP_REQUEST");
            log.setDetails(String.format("URI: %s, Method: %s", uri, request.getMethod()));
            log.setIpAddress(ipAddress);
            auditLogDAO.create(log);
            */
            
        } catch (Exception e) {
            logger.error("Error creating audit log", e);
        }
    }
    
    /**
     * Determine action type from URI
     */
    private String determineAction(String uri) {
        if (uri.contains("/login")) return "LOGIN";
        if (uri.contains("/logout")) return "LOGOUT";
        if (uri.contains("/register")) return "REGISTER";
        if (uri.contains("/reservation")) return "RESERVATION";
        if (uri.contains("/payment")) return "PAYMENT";
        return "ACCESS";
    }
    
    @Override
    public void destroy() {
        logger.info("LoggingFilter destroyed");
    }
}
